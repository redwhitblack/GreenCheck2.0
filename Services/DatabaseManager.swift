//
//  DatabaseManager.swift
//  GreenCheck2
//

import Foundation
import SQLite  // Stephen Celis's SQLite.swift

enum DatabaseError: Error {
    case notConnected
    case insertionFailed
    case unknown
}

// Rename if you already have a "Product" struct
struct DBProduct {
    var id: Int64?
    var barcode: String
    var name: String
    var details: String
    var createdAt: String
    var productCategory: String
    var isFavorite: Bool
}

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    // MARK: - Table Definition
    private let products = Table("products")
    private let id = Expression<Int64>("id")
    private let barcode = Expression<String>("barcode")
    private let name = Expression<String>("name")
    private let details = Expression<String>("details")
    private let createdAt = Expression<String>("created_at")
    private let productCategory = Expression<String>("category")
    private let isFavorite = Expression<Bool>("is_favorite")

    // MARK: - Init
    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentsPath = paths.first {
            do {
                // Connect to a local db.sqlite3 file
                db = try Connection("\(documentsPath)/db.sqlite3")
                try createTables()
                print("Database connected at: \(documentsPath)/db.sqlite3")
            } catch {
                print("DatabaseManager: Failed to connect: \(error)")
            }
        }
    }

    private func createTables() throws {
        guard let db = db else { return }
        try db.run(products.create(ifNotExists: true) { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(barcode)
            table.column(name)
            table.column(details)
            table.column(createdAt)
            table.column(productCategory)
            table.column(isFavorite, defaultValue: false)
        })
    }

    // MARK: - CRUD Methods

    // Create
    func saveProduct(_ product: DBProduct) throws -> DBProduct {
        guard let db = db else { throw DatabaseError.notConnected }

        let insert = products.insert(
            barcode <- product.barcode,
            name <- product.name,
            details <- product.details,
            createdAt <- product.createdAt,
            productCategory <- product.productCategory,
            isFavorite <- product.isFavorite
        )

        do {
            let rowid = try db.run(insert)
            var saved = product
            saved.id = rowid
            return saved
        } catch {
            print("Insertion failed: \(error)")
            throw DatabaseError.insertionFailed
        }
    }

    // Read
    func getAllProducts() throws -> [DBProduct] {
        guard let db = db else { throw DatabaseError.notConnected }
        var items = [DBProduct]()

        for row in try db.prepare(products) {
            let product = DBProduct(
                id: row[id],
                barcode: row[barcode],
                name: row[name],
                details: row[details],
                createdAt: row[createdAt],
                productCategory: row[productCategory],
                isFavorite: row[isFavorite]
            )
            items.append(product)
        }
        return items
    }

    // Update
    func updateProduct(_ product: DBProduct) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let productID = product.id else { return }

        let item = products.filter(id == productID)
        let update = item.update(
            barcode <- product.barcode,
            name <- product.name,
            details <- product.details,
            createdAt <- product.createdAt,
            productCategory <- product.productCategory,
            isFavorite <- product.isFavorite
        )
        try db.run(update)
    }

    // Delete
    func deleteProduct(_ product: DBProduct) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let productID = product.id else { return }

        let item = products.filter(id == productID)
        try db.run(item.delete())
    }
}
