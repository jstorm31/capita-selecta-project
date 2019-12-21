//
//  TicketService.swift
//  App
//
//  Created by Jiří Zdvomka on 25/11/2019.
//

import Vapor
import GameKit

final class TicketService: Service {
    private let maxTicketCount = 4
    private var soldTickets = 0
    
    func makeOrder(_ order: OrderRequest, user: User, on req: Request) throws -> Future<[Ticket]> {
        guard order.ticketCount <= maxTicketCount else {
            throw Abort(.custom(code: 412, reasonPhrase: "Maximum number of ordered tickets can be \(maxTicketCount)"))
        }
        
        let lockQuery = "LOCK \"AvailableTickets\""
        let logger = try req.make(PrintLogger.self)
        let userId = try user.requireID()
        
        // Shared DB transaction
        return req.transaction(on: .psql) { conn -> EventLoopFuture<Int> in
            #if DEBUG
            self.dbLatency()
            #endif
            
            return conn.raw(lockQuery).run().flatMap { _ in
                // Get tickets count and decrease its value (aka reserve those tickets)
                return AvailableTickets.query(on: conn).first().flatMap(to: Int.self) { availableTickets in
                    logger.info("🎫 Available tickets: \(availableTickets!.count)")
                    guard let tickets = availableTickets, tickets.count >= order.ticketCount else {
                        throw Abort(.custom(code: 410, reasonPhrase: "No tickets available"))
                    }
                    
                    tickets.count -= order.ticketCount
                    logger.info("Reserved \(order.ticketCount) tickets for user \(userId)")
                    return tickets.update(on: conn).map { _ in tickets.count }
                }
                
            }
        }
            
            // Payment transaction
            .flatMap(to: Void.self) { _ in
                logger.info("Checking balance for user \(userId) with provider \(user.paymentCardType)")
                self.sleepPaymentResponse()
                
                let sufficentAmount = Double.random(in: 0...1)
                if sufficentAmount > 0.0005 {
                    logger.info("Sufficcent balance for user \(userId). Paying...")
                    self.sleepPaymentResponse() // Check the card balance
                    // Make payment requests - mock it by waiting for some time
                    logger.info("Successfuly paid for user \(userId)")
                    self.soldTickets += order.ticketCount
                    logger.info("💰 Sold tickets: \(self.soldTickets)")
                    return req.future(())
                } else {
                    logger.info("Insuficcent balance for user \(userId). Cancelling ticket reservation.")
                    // Increase back tickets count
                    return req.transaction(on: .psql) { conn in
                        return conn.raw(lockQuery).run().flatMap { _ in
                            // Get tickets count and decrease its value (aka reserve those tickets
                            AvailableTickets.query(on: conn).first().flatMap(to: Void.self) { availableTickets in
                                availableTickets!.count += order.ticketCount
                                return availableTickets!.update(on: conn).map { _ in () }
                            }
                        }
                        .map { _ in
                            throw Abort(.custom(code: 411, reasonPhrase: "Insuficcent amount on the card"))
                        }
                    }
                }
        }
            
            // Generate tickets
            .flatMap(to: [Ticket].self) { _ in
                logger.info("Generating tickets for user \(userId)")
                
                #if DEBUG
                self.dbLatency()
                #endif
                
                return req.transaction(on: .psql) { conn in
                    var tickets = [Ticket]()
                    
                    for _ in 0...order.ticketCount - 1 {
                        tickets.append(Ticket(userId: userId))
                    }
                    
                    return try tickets.map { ticket in
                        try ticket.encrypt(on: req).save(on: req).map { try $0.decrypt(on: req) }
                    }
                    .flatten(on: req)
                }
        }
    }
    
    private func sleepPaymentResponse() {
        let x = Float.random(in: 0...1)
        var latency: Int
        var paymentCardType: PaymentCardType
        
        if x < 0.333 {
            paymentCardType = .visa
        } else if x < 0.666 {
            paymentCardType = .maestro
        } else {
            paymentCardType = .mastercard
        }
        
        latency = PaymentCardType.delay(paymentCardType)
        print("📈 Payment provider latency: \(latency)ms")
        usleep(UInt32(1000 * latency))
    }
    
    private func dbLatency() {
        let responseTime = Int.random(in: 35...400)
        usleep(UInt32(1000 * responseTime + 50))
    }
}

extension TicketService: ServiceType {
    static func makeService(for container: Container) throws -> TicketService {
        return TicketService()
    }
}
