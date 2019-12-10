//
//  Ticket.swift
//  App
//
//  Created by Jiří Zdvomka on 25/11/2019.
//

import FluentPostgreSQL
import Vapor

final class Ticket: PostgreSQLUUIDModel, Migration, Content {
    var id: UUID?
    var userId: String
    var intUserId: Int {
        return Int(userId)!
    }
    
    init(userId: Int) {
        self.userId = String(userId)
    }
    
    func encrypt(on req: Request) throws -> Ticket {
        let crypto = try req.make(Crypto.self)
        userId = try crypto.encrypt(String(userId))
        return self
    }
    
    func decrypt(on req: Request) throws -> Ticket {
        let crypto = try req.make(Crypto.self)
        let stringUserId = try crypto.decrypt(String(self.userId))
        self.userId = stringUserId
        return self
    }
}
