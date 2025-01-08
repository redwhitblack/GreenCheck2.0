import SwiftUI

struct ProductRowView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            Image(systemName: product.category.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.headline)
                    if product.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Text(product.details.components(separatedBy: "\n").first ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    private var categoryColor: Color {
        switch product.category {
        case .food: return .green
        case .beverage: return .blue
        case .snack: return .orange
        case .other: return .gray
        }
    }
}
