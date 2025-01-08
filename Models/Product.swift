import Foundation

struct Product: Identifiable {
    let id: UUID
    var barcode: String
    var name: String
    var details: String
    var createdAt: Date
    var category: Category
    var isFavorite: Bool

    init(
        id: UUID = UUID(), barcode: String, name: String, details: String, createdAt: Date = Date(),
        category: Category = .other, isFavorite: Bool = false
    ) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.details = details
        self.createdAt = createdAt
        self.category = category
        self.isFavorite = isFavorite
    }

    enum Category: String, CaseIterable {
        case food = "Food"
        case beverage = "Beverage"
        case snack = "Snack"
        case other = "Other"

        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .beverage: return "cup.and.saucer"
            case .snack: return "bag.circle"
            case .other: return "square.grid.2x2"
            }
        }
    }
}
