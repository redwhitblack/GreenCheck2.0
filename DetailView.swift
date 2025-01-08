import SwiftUI

struct DetailView: View {
    @Binding var product: Product
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.title)
                            .bold()
                        Text(product.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(product.isFavorite ? .red : .gray)
                    }
                }

                // Barcode section
                VStack(alignment: .leading) {
                    Label {
                        Text("Barcode")
                    } icon: {
                        Image(systemName: "barcode")
                    }
                    .font(.headline)
                    Text(product.barcode)
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Details section
                VStack(alignment: .leading) {
                    Label {
                        Text("Details")
                    } icon: {
                        Image(systemName: "list.bullet")
                    }
                    .font(.headline)
                    Text(product.details)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: product.name) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func toggleFavorite() {
        product.isFavorite.toggle()
    }
}
