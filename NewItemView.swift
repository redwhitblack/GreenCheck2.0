import SwiftUI

struct NewItemView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Product) -> Void

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var selectedCategory: Product.Category = .other

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item Info")) {
                    TextField("Name", text: $name)
                    TextField("Details", text: $details)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Product.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newProduct = Product(
                            barcode: "manual-\(UUID().uuidString)",
                            name: name,
                            details: details,
                            category: selectedCategory
                        )
                        onCreate(newProduct)
                        dismiss()
                    }
                }
                // ...existing cancel button...
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
