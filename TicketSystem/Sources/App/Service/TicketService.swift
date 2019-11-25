//
//  TicketService.swift
//  App
//
//  Created by Jiří Zdvomka on 25/11/2019.
//

import Vapor

final class TicketService: Service {
    func makeOrder(_ order: OrderRequest, on req: Request) throws -> Future<OrderResponse> {
        let lockQuery = "LOCK \"AvailableTickets\""
        
        return req.transaction(on: .psql) { conn in
            // First lock the table
            conn.raw(lockQuery).run().flatMap { _ in
                    // Get tickets count and decrease its value (aka reserve those tickets
                    AvailableTickets.query(on: conn).first().flatMap(to: Int.self) { availableTickets in
                        guard let tickets = availableTickets, tickets.count > order.ticketCount else {
                            throw Abort(.custom(code: 410, reasonPhrase: "No tickets available"))
                        }
                        
                        tickets.count -= order.ticketCount
                        return tickets.update(on: conn).map { _ in tickets.count }
                }
            }
        }
        .flatMap(to: Void.self) { _ in
            sleep(1) // Check the card balance
            let sufficentAmount = Double.random(in: 0...1)
            
            if sufficentAmount > 0.1 {
                sleep(1) // Make payment requests - mock it by waiting for some time
                return req.future(())
            } else {
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
        .map(to: OrderResponse.self) { _ in
            // Generate tickets
            sleep(1)
            var tickets = [String]()
            
            for _ in 0...order.ticketCount {
                tickets.append(String.random(length: 16))
            }
            return OrderResponse(tickets: tickets)
        }
    }
}

extension TicketService: ServiceType {
    static func makeService(for container: Container) throws -> TicketService {
        return TicketService()
    }
}
