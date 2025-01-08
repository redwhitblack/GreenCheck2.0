import BarcodeScanner
import SwiftUI

// A wrapper so we can store the scanned code for alerts or debugging if needed.
struct ScannedBarcode: Identifiable {
    let id = UUID()
    let value: String
}

struct ContentView: View {
    // MARK: - State
    @State private var products: [Product] = []
    @State private var isPresentingNewItemSheet = false
    @State private var showHyperScanner = false
    @State private var scannedCode: ScannedBarcode? = nil
    @State private var isLookingUpProduct = false
    @State private var lookupErrorMessage: String?
    @State private var showingErrorAlert = false
    @State private var searchText = ""
    @State private var selectedCategory: Product.Category?

    var filteredProducts: [Product] {
        let searchFiltered = products.filter { product in
            searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
        }

        guard let category = selectedCategory else {
            return searchFiltered
        }

        return searchFiltered.filter { $0.category == category }
    }

    // Add this helper function
    private func countProducts(in category: Product.Category) -> Int {
        products.filter { $0.category == category }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filters with counts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            title: "All",
                            count: products.count,
                            icon: "square.grid.2x2",
                            isSelected: selectedCategory == nil
                        ) {
                            withAnimation { selectedCategory = nil }
                        }

                        ForEach(Product.Category.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                count: countProducts(in: category),
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation { selectedCategory = category }
                            }
                        }
                    }
                    .padding()
                }

                // Main content
                if filteredProducts.isEmpty {
                    EmptyStateView(
                        title: "No Items Yet",
                        message: "Tap the + button or Scan to add new items.",
                        systemImage: "tray"
                    )
                } else {
                    List {
                        ForEach(filteredProducts) { product in
                            NavigationLink(destination: DetailView(product: product)) {
                                ProductRowView(product: product)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }

                // MARK: - Floating Buttons
                VStack {
                    Spacer()
                    HStack {
                        // 1) Manual "New Item" button if you still want to add items by hand
                        Button {
                            isPresentingNewItemSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                        }
                        .padding(.trailing, 8)

                        // 2) HyperOslo scanner button
                        Button {
                            showHyperScanner = true
                        } label: {
                            Text("Scan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .cornerRadius(24)
                        }
                    }
                    .padding(.bottom, 32)
                    .padding(.trailing, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Items")
                        .font(.headline.bold())
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }

            // MARK: - HyperOslo Scanner
            .fullScreenCover(isPresented: $showHyperScanner) {
                HyperScannerScreen { codeValue in
                    // 1) we have a code
                    self.scannedCode = ScannedBarcode(value: codeValue)

                    // 2) start product lookup
                    self.isLookingUpProduct = true
                    lookupProduct(by: codeValue)
                }
            }

            // MARK: - New Item Sheet
            .sheet(isPresented: $isPresentingNewItemSheet) {
                NewItemView { product in
                    products.append(product)
                }
            }

            // Show raw code if you want
            .alert(item: $scannedCode) { code in
                Alert(
                    title: Text("Scanned Code"),
                    message: Text("\(code.value)"),
                    dismissButton: .default(Text("OK"))
                )
            }

            // Show errors from the product lookup
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Lookup Error"),
                    message: Text(lookupErrorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }

            // If you want a spinner overlay for "Loading..."
            .overlay {
                if isLookingUpProduct {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView("Looking up product…")
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search products...")
            .refreshable {
                await loadProductsAsync()
            }
        }
        .onAppear {
            loadProducts()
        }
    }

    // MARK: - Delete Items
    private func deleteItems(offsets: IndexSet) {
        products.remove(atOffsets: offsets)
    }

    private func loadProducts() {
        // No-op since we're using in-memory storage
    }

    private func loadProductsAsync() async {
        // No-op since we're using in-memory storage
    }
}

// MARK: - Product Lookup with Open Food Facts
extension ContentView {
    private func lookupProduct(by barcode: String) {
        guard
            let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")
        else {
            finishLookupWithError("Invalid URL.")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            // done with network, hide spinner
            defer { DispatchQueue.main.async { self.isLookingUpProduct = false } }

            if let error = error {
                finishLookupWithError("Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                finishLookupWithError("No data received.")
                return
            }

            do {
                // Parse JSON
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let status = json["status"] as? Int
                {

                    if status == 1,
                        let product = json["product"] as? [String: Any]
                    {

                        // We'll parse product_name, brand, and some nutriments
                        let productName = product["product_name"] as? String ?? "Unnamed Product"
                        let brandName = product["brands"] as? String ?? "Unknown Brand"

                        // Parse nutriments
                        let nutritionDetails = self.parseNutritionDetails(
                            nutriments: product["nutriments"] as? [String: Any],
                            brandName: brandName
                        )

                        // Create and add new product
                        DispatchQueue.main.async {
                            let product = Product(
                                barcode: barcode,
                                name: productName,
                                details: nutritionDetails,
                                category: .food  // You might want to infer category from the API response
                            )
                            self.products.append(product)
                        }

                    } else {
                        finishLookupWithError("Not found in Open Food Facts.")
                    }
                }
            } catch {
                finishLookupWithError("JSON parse error: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func parseNutritionDetails(nutriments: [String: Any]?, brandName: String) -> String {
        guard let nutriments = nutriments else {
            return "Brand: \(brandName)\nNo nutriments info."
        }

        let sugar = nutriments["sugars_100g"] as? Double
        let carbs = nutriments["carbohydrates_100g"] as? Double
        let protein = nutriments["proteins_100g"] as? Double

        return """
            Brand: \(brandName)
            Sugar (per 100g): \(sugar?.description ?? "-")
            Carbs (per 100g): \(carbs?.description ?? "-")
            Protein (per 100g): \(protein?.description ?? "-")
            """
    }

    private func finishLookupWithError(_ message: String) {
        DispatchQueue.main.async {
            self.lookupErrorMessage = message
            self.showingErrorAlert = true
        }
    }
}

// MARK: - Supporting Views
struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let count: Int
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.3) : .gray.opacity(0.2))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? .blue : .gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .animation(.spring(duration: 0.2), value: isSelected)
        }
    }
}
