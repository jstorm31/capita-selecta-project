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
    var userId: Int
    
    init(userId: Int) {
        self.userId = userId
    }
}
