import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    // MARK: - Table Definition with correct types
    private let products = Table("products")
    private let id = Expression<Int64>("id")
    private let barcode = Expression<String>("barcode")
    private let name = Expression<String>("name")
    private let details = Expression<String>("details")
    private let createdAt = Expression<Double>("created_at")  // Store as timestamp
    private let category = Expression<String>("category")
    private let isFavorite = Expression<Bool>("is_favorite")  // Store as proper bool

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!

        do {
            db = try Connection("\(path)/db.sqlite3")
            try createTables()
        } catch {
            print("DatabaseManager: Failed to connect: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(
            products.create(ifNotExists: true) { table in
                table.column(id, primaryKey: .autoincrement)
                table.column(barcode)
                table.column(name)
                table.column(details)
                table.column(createdAt)
                table.column(category)
                table.column(isFavorite, defaultValue: false)
            })
    }

    // MARK: - CRUD Operations

    func saveProduct(_ product: Product) throws -> Product {
        guard let db = db else { throw DatabaseError.notConnected }

        let insert = products.insert(
            barcode <- product.barcode,
            name <- product.name,
            details <- product.details,
            createdAt <- product.createdAt.timeIntervalSince1970,
            category <- product.category.rawValue,
            isFavorite <- product.isFavorite
        )

        let rowid = try db.run(insert)

        return Product(
            id: UUID(),  // Create new UUID for the product
            barcode: product.barcode,
            name: product.name,
            details: product.details,
            createdAt: product.createdAt,
            category: product.category,
            isFavorite: product.isFavorite
        )
    }

    func getAllProducts() throws -> [Product] {
        guard let db = db else { throw DatabaseError.notConnected }

        return try db.prepare(products).map { row in
            guard let category = Product.Category(rawValue: row[category]) else {
                throw DatabaseError.invalidCategory
            }

            return Product(
                id: UUID(),  // Create new UUID for each product
                barcode: row[barcode],
                name: row[name],
                details: row[details],
                createdAt: Date(timeIntervalSince1970: row[createdAt]),
                category: category,
                isFavorite: row[isFavorite]
            )
        }
    }

    func deleteProduct(id productId: Int64) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try db.run(products.filter(id == productId).delete())
    }

    enum DatabaseError: Error {
        case notConnected
        case invalidId
        case invalidCategory
    }
}
