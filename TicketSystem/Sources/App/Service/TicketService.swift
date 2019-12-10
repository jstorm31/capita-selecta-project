//
//  TicketService.swift
//  App
//
//  Created by Jiří Zdvomka on 25/11/2019.
//

import Vapor

final class TicketService: Service {
    private let maxTicketCount = 4
    
    func makeOrder(_ order: OrderRequest, user: User, on req: Request) throws -> Future<[Ticket]> {
        guard order.ticketCount <= maxTicketCount else {
            throw Abort(.custom(code: 412, reasonPhrase: "Maximum number of ordered tickets can be \(maxTicketCount)"))
        }
        
        let logger = try req.make(PrintLogger.self)
        let userId = try user.requireID()
        
        return req.transaction(on: .psql) { conn in
            // Get tickets count and decrease its value (aka reserve those tickets
            AvailableTickets.query(on: conn).first().flatMap(to: Int.self) { availableTickets in
                guard let tickets = availableTickets, tickets.count > order.ticketCount else {
                    throw Abort(.custom(code: 410, reasonPhrase: "No tickets available"))
                }
                
                tickets.count -= order.ticketCount
                logger.info("Reserved \(order.ticketCount) tickets for user \(userId)")
                return tickets.update(on: conn).map { _ in tickets.count }
            }
        }
        .flatMap(to: Void.self) { _ in
            logger.info("Checking balance for user \(userId) with provider \(user.paymentCardType)")
            self.sleepPaymentResponse()
            
            let sufficentAmount = Double.random(in: 0...1)
            if sufficentAmount > 0.0005 {
                logger.info("Sufficcent balance for user \(userId). Paying...")
                self.sleepPaymentResponse() // Check the card balance
                // Make payment requests - mock it by waiting for some time
                logger.info("Successfuly paid for user \(userId)")
                return req.future(())
            } else {
                logger.info("Insuficcent balance for user \(userId). Cancelling ticket reservation.")
                // Increase back tickets count
                return req.transaction(on: .psql) { conn in
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
        .flatMap(to: [Ticket].self) { _ in
            logger.info("Generating tickets for user \(userId)")

            // Generate tickets
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
        
        // Assumption bounded by SLA with payemtn provider - response time max. 1500 ms with 98% probability
        // Distribution of the latency is exponentional (based on https://www.moesif.com/blog/reports/api-report/Summer-2018-State-of-API-Usage-Report/)
        if x < 0.4 {
            latency = Int.random(in: 25...500)
        } else if x < 0.9 {
            latency = Int.random(in: 501...2000)
        } else if x < 0.98 {
            latency = Int.random(in: 2001...2500)
        } else {
            latency = Int.random(in: 2501...5000)
        }

        print("📈 Payment provider latency: \(latency)ms")
        usleep(UInt32(1000 * latency))
    }
}

extension TicketService: ServiceType {
    static func makeService(for container: Container) throws -> TicketService {
        return TicketService()
    }
}
