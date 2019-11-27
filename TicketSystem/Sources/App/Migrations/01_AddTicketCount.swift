import FluentPostgreSQL
import Vapor

struct AddTicketCount: Migration {
    typealias Database = PostgreSQLDatabase
    
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        let count = AvailableTickets(count: 2000000)
        return count.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return AvailableTickets.query(on: conn).first().flatMap { count in
            if let count = count {
                return count.delete(on: conn)
            }
            return conn.future()
        }
    }
}
