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
        
        let lockQuery = "LOCK \"AvailableTickets\""
        let logger = try req.make(PrintLogger.self)
        let userId = try user.requireID()
        
        return req.transaction(on: .psql) { conn in
            // First lock the table
            conn.raw(lockQuery).run().flatMap { _ in
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
        }
        .flatMap(to: Void.self) { _ in
            logger.info("Checking balance for user \(userId) with provider \(user.paymentCardType)")
            usleep(500000) // Check the card balance
            let sufficentAmount = Double.random(in: 0...1)
            
            if sufficentAmount > 0.1 {
                logger.info("Sufficcent balance for user \(userId). Paying...")
                usleep(5000000) // Make payment requests - mock it by waiting for some time
                logger.info("Successfuly paid for user \(userId)")
                return req.future(())
            } else {
                logger.info("Insuficcent balance for user \(userId). Canceling ticket reservation.")
                // Increase back tickets count
                return req.transaction(on: .psql) { conn in
                    conn.raw(lockQuery).run().flatMap { _ in
                        // Get tickets count and decrease its value (aka reserve those tickets
                        AvailableTickets.query(on: conn).first().flatMap(to: Void.self) { availableTickets in
                            availableTickets!.count += order.ticketCount
                            return availableTickets!.update(on: conn).map { _ in () }
                        }
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
                
                return tickets.map { $0.save(on: req) }.flatten(on: req)
            }
        }
    }
}

extension TicketService: ServiceType {
    static func makeService(for container: Container) throws -> TicketService {
        return TicketService()
    }
}
