import SwiftUI

// MARK: - Fluids View Model
@MainActor
class FluidsViewModel: ObservableObject {
    @Published var fluids: [Fluid] = []
    @Published var rows: [[String]] = []
    @Published var headers: [String] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    func loadData(forceRefresh: Bool = false) {
        print("\n=== Loading Fluids ===")
        print("🔄 Starting data load process...")
        isLoading = true
        error = nil
        
        // If forcing refresh, update cache first
        if forceRefresh {
            print("🔄 Force refreshing cache...")
            DatabaseManager.shared.updateFluidsCache(force: true)
        }
        
        // Try to get from cache first
        if let cached = DatabaseManager.shared.getCachedFluids() {
            print("📦 Using cached fluids data")
            print("📊 Cache contains \(cached.fluids.count) fluids")
            fluids = cached.fluids
            headers = cached.headers
            rows = cached.rows
            isLoading = false
            print("✅ Finished Loading Fluids (from cache)")
            print("=== Cache Load Complete ===\n")
            return
        }
        
        print("🔄 Cache not available, loading from database...")
        // If not in cache, load from database and update cache
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            print("📦 Successfully loaded from database")
            print("📊 Loaded \(cached.fluids.count) fluids")
            fluids = cached.fluids
            headers = cached.headers
            rows = cached.rows
        } else {
            print("❌ Failed to load fluids from database")
            error = "Failed to load fluids from database"
        }
        
        isLoading = false
        print("=== Database Load Complete ===\n")
    }
    
    func getFluidDetails(for fluid: Fluid) -> (row: [String], headers: [String])? {
        if let index = fluids.firstIndex(where: { $0.id == fluid.id }) {
            return (rows[index], headers)
        }
        return nil
    }
}

// MARK: - Main Fluids View
struct FluidsView: View {
    @StateObject private var viewModel = FluidsViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedManufacturer = "All"
    @State private var selectedType = "All"
    @State private var selectedUse = "All"
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var shouldResetNavigation = false
    @State private var showWelcomeView = false
    
    // Define which fields to search in
    private let searchableFields = ["FLUID", "MANUFACTURER", "USE", "INDEX", "COLOR", "TYPE"]
    
    var filteredFluids: [Fluid] {
        var filtered = viewModel.fluids
        
        // Apply manufacturer filter
        if selectedManufacturer != "All" {
            filtered = filtered.filter { $0.manufacturer.lowercased() == selectedManufacturer.lowercased() }
        }
        
        // Apply type filter
        if selectedType != "All" {
            filtered = filtered.filter { $0.type?.lowercased() == selectedType.lowercased() }
        }
        
        // Apply use filter
        if selectedUse != "All" {
            filtered = filtered.filter { $0.use?.lowercased() == selectedUse.lowercased() }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchTextLower = searchText.lowercased()
            filtered = filtered.filter { fluid in
                let searchableText = "\(fluid.name) \(fluid.manufacturer) \(fluid.use ?? "") \(fluid.type ?? "") \(fluid.formattedIndex)".lowercased()
                return searchableText.contains(searchTextLower)
            }
        }
        
        return filtered
    }
    
    var manufacturers: [String] {
        ["All"] + Array(Set(viewModel.fluids.map { $0.manufacturer })).sorted()
    }
    
    var types: [String] {
        ["All"] + Array(Set(viewModel.fluids.compactMap { $0.type })).sorted()
    }
    
    var uses: [String] {
        ["All"] + Array(Set(viewModel.fluids.compactMap { $0.use })).sorted()
    }
    
    private func resetView() {
        // Clear all filters
        selectedManufacturer = "All"
        selectedType = "All"
        selectedUse = "All"
        // Clear search text
        searchText = ""
        // Force cache refresh and reload data
        print("Force reloading fluids cache for reset...")
        viewModel.loadData(forceRefresh: true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section - keep only About and reload buttons
            VStack(spacing: AppStyle.Spacing.small) {
                HStack {
                    Spacer()
                    
                    // About button
                    Button(action: {
                        showWelcomeView = true
                    }) {
                        Text("About")
                            .font(AppStyle.Typography.subheadline)
                            .foregroundColor(AppStyle.primaryColor)
                    }
                    .fullScreenCover(isPresented: $showWelcomeView) {
                        NavigationStack {
                            WelcomeView(isPresented: Binding(
                                get: { showWelcomeView },
                                set: { showWelcomeView = $0 }
                            ))
                        }
                    }
                    
                    // Reload button
                    Button(action: {
                        print("Force reloading fluids data...")
                        DatabaseManager.shared.updateFluidsCache(force: true)
                        viewModel.loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
                .padding(.horizontal, AppStyle.Spacing.medium)
            }
            .padding(.top, AppStyle.Spacing.small)
            
            // Total count
            HStack {
                Text("Total Chemicals: \(viewModel.fluids.count)")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.secondaryTextColor)
                Spacer()
            }
            .padding(.horizontal, AppStyle.Spacing.medium)
            .padding(.top, AppStyle.Spacing.small)
            
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search fluids...")
                .padding(.horizontal)
            
            // Filter buttons with reset
            VStack(spacing: AppStyle.Spacing.small) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppStyle.Spacing.small) {
                        FilterButton(title: "Manufacturer", selection: $selectedManufacturer, options: manufacturers)
                        FilterButton(title: "Type", selection: $selectedType, options: types)
                        FilterButton(title: "Use", selection: $selectedUse, options: uses)
                    }
                    .padding(.horizontal)
                }
                
                // Reset filters button
                if selectedManufacturer != "All" || selectedType != "All" || selectedUse != "All" || !searchText.isEmpty {
                    Button(action: resetView) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reset Filters")
                        }
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.primaryColor)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, AppStyle.Spacing.small)
            
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
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(AppStyle.secondaryTextColor)
                    Text("No Fluids Found")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.secondaryTextColor)
                    Text("Try adjusting your search or filters")
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
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .background(AppStyle.backgroundColor)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .onAppear {
            viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetNavigation"))) { _ in
            shouldResetNavigation = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FluidsChanged"))) { _ in
            print("Received FluidsChanged notification, reloading data")
            viewModel.loadData()
        }
        .id(shouldResetNavigation)
    }
}

// Add AboutView
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            Text("About Fluid Database")
                .font(AppStyle.Typography.headline)
            
            Text("This database contains information about various fluids used in industrial applications. The data includes manufacturer details, intended use, and fluid type.")
                .font(AppStyle.Typography.body)
                .foregroundColor(AppStyle.secondaryTextColor)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    FluidsView()
} 
 