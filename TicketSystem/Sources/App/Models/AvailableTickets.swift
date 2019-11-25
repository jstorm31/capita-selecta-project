//
//  AvailableTickets.swift
//  App
//
//  Created by Jiří Zdvomka on 25/11/2019.
//

import Vapor
import FluentPostgreSQL

final class AvailableTickets: PostgreSQLModel, Content, Migration {
    var id: Int?
    var count: Int
    
    init(count: Int) {
        self.count = count
    }
}
