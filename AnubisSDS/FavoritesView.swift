import SwiftUI

// MARK: - Favorites View Model
@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var fluids: [Fluid] = []
    @Published var rows: [[String]] = []
    @Published var headers: [String] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    func loadData() {
        print("\n=== Loading Favorite Fluids ===")
        isLoading = true
        error = nil
        
        // Get the list of favorite fluid names
        let favorites = FavoritesManager.shared.getFavorites()
        
        if favorites.isEmpty {
            print("No favorites found")
            fluids = []
            rows = []
            headers = []
            isLoading = false
            return
        }
        
        // Try to get from cache first
        if let cached = DatabaseManager.shared.getCachedFluids() {
            print("Using cached fluids data")
            // Filter cached fluids to only include favorites
            fluids = cached.fluids.filter { favorites.contains($0.name) }
            headers = cached.headers
            rows = cached.rows.filter { row in
                if let fluidNameIndex = headers.firstIndex(of: "FLUID"),
                   fluidNameIndex < row.count {
                    return favorites.contains(row[fluidNameIndex])
                }
                return false
            }
            isLoading = false
            print("=== Finished Loading Favorite Fluids (from cache) ===\n")
            return
        }
        
        // If not in cache, load from database and update cache
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            // Filter cached fluids to only include favorites
            fluids = cached.fluids.filter { favorites.contains($0.name) }
            headers = cached.headers
            rows = cached.rows.filter { row in
                if let fluidNameIndex = headers.firstIndex(of: "FLUID"),
                   fluidNameIndex < row.count {
                    return favorites.contains(row[fluidNameIndex])
                }
                return false
            }
        } else {
            error = "Failed to load favorite fluids from database"
        }
        
        isLoading = false
        print("=== Finished Loading Favorite Fluids ===\n")
    }
    
    func getFluidDetails(for fluid: Fluid) -> (row: [String], headers: [String])? {
        if let index = fluids.firstIndex(where: { $0.id == fluid.id }) {
            return (rows[index], headers)
        }
        return nil
    }
}

// MARK: - Main Favorites View
struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var searchText = ""
    @State private var shouldResetNavigation = false
    
    var filteredFluids: [Fluid] {
        if searchText.isEmpty {
            return viewModel.fluids
        }
        return viewModel.fluids.filter { fluid in
            fluid.name.localizedCaseInsensitiveContains(searchText) ||
            fluid.manufacturer.localizedCaseInsensitiveContains(searchText) ||
            (fluid.use?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                HStack {
                    Text("Favorite Fluids: \(filteredFluids.count)")
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.secondaryTextColor)
                    
                    Spacer()
                    
                    // Reload button
                    Button(action: {
                        print("Force reloading favorites data...")
                        DatabaseManager.shared.updateFluidsCache()
                        viewModel.loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
                .padding(.horizontal, AppStyle.Spacing.medium)
                .padding(.top, AppStyle.Spacing.small)
                .padding(.bottom, AppStyle.Spacing.medium)
                
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search favorites...")
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    Text(error)
                        .font(AppStyle.Typography.body)
                        .foregroundColor(.red)
                        .padding(AppStyle.Spacing.medium)
                        .cardStyle()
                        .padding(.horizontal, AppStyle.Spacing.medium)
                        .padding(.top, AppStyle.Spacing.small)
                } else if filteredFluids.isEmpty {
                    VStack(spacing: AppStyle.Spacing.medium) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 50))
                            .foregroundColor(AppStyle.secondaryTextColor)
                        Text("No Favorite Fluids")
                            .font(AppStyle.Typography.headline)
                            .foregroundColor(AppStyle.secondaryTextColor)
                        Text("Add fluids to your favorites by tapping the star icon on any fluid card")
                            .font(AppStyle.Typography.body)
                            .foregroundColor(AppStyle.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppStyle.backgroundColor)
                } else {
                    List(filteredFluids) { fluid in
                        NavigationLink {
                            if let details = viewModel.getFluidDetails(for: fluid) {
                                FluidDetailView(row: details.row, headers: details.headers)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fluid.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(fluid.manufacturer)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if let use = fluid.use {
                                        Text(use)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                Spacer()
                                
                                // Favorite button
                                Button(action: {
                                    FavoritesManager.shared.removeFavorite(fluidName: fluid.name)
                                    viewModel.loadData() // Reload the list
                                }) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 20))
                                        .padding(.trailing, 8)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(AppStyle.backgroundColor)
                }
            }
            .navigationBarHidden(true)
            .background(AppStyle.backgroundColor)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
        }
        .onAppear {
            viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetNavigation"))) { _ in
            shouldResetNavigation = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FavoritesChanged"))) { _ in
            viewModel.loadData()
        }
        .id(shouldResetNavigation)
    }
}

#Preview {
    FavoritesView()
}

