import Foundation

/// Our data model for products.
struct GCProduct {
    var id: Int64?              // nil if not yet in the DB
    var barcode: String
    var name: String
    var details: String
    
    /// We'll store dates as strings in the DB for simplicity.
    /// Converting to/from `Date` with a DateFormatter is manual.
    var createdAt: Date
    
    /// Category is an enum backed by a raw string (e.g., "produce", "dairy").
    var category: Category
    
    /// We'll store booleans as "true"/"false" strings in the DB.
    var isFavorite: Bool
    
    enum Category: String {
        case produce
        case dairy
        case meat
        case other
    }
}
