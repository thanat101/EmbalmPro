import SwiftUI

// MARK: - Persisted manufacturer filter (shared with Case Analysis suggested fluids)
enum ManufacturerFilterStorage {
    static let key = "FluidsView.selectedManufacturers"
    
    static func load() -> Set<String> {
        guard let arr = UserDefaults.standard.stringArray(forKey: key) else { return [] }
        return Set(arr)
    }
    
    static func save(_ set: Set<String>) {
        UserDefaults.standard.set(Array(set).sorted(), forKey: key)
    }
    
    /// Returns nil = no filter (show all), else the set of allowed manufacturer names for Case Analysis.
    static func allowedManufacturersForCaseAnalysis() -> Set<String>? {
        let s = load()
        if s.isEmpty { return nil }
        return s
    }
}

// MARK: - Fluids View Model
@MainActor
class FluidsViewModel: ObservableObject {
    @Published var fluids: [Fluid] = []
    @Published var rows: [[String]] = []
    @Published var headers: [String] = []
    @Published var searchText: String = ""
    /// Multi-select: empty = show all manufacturers. Persisted so filter survives navigation.
    @Published var selectedManufacturers: Set<String> = [] {
        didSet { ManufacturerFilterStorage.save(selectedManufacturers) }
    }
    @Published var selectedType: String = "All"
    @Published var selectedUse: String = "All"
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Cached filter results - updated only when fluids or filters change, not on every body evaluation
    @Published var filteredFluids: [Fluid] = []
    @Published var manufacturers: [String] = ["All"]
    @Published var types: [String] = ["All"]
    @Published var uses: [String] = ["All"]
    
    init() {
        selectedManufacturers = ManufacturerFilterStorage.load()
    }
    
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
            updateFilteredData()
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
            updateFilteredData()
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
    
    /// Updates cached filter results. Call when fluids or filter state changes.
    /// Keeps expensive filtering off the main thread during layout/focus changes.
    func updateFilteredData() {
        var filtered = fluids
        if !selectedManufacturers.isEmpty {
            filtered = filtered.filter { selectedManufacturers.contains($0.manufacturer) }
        }
        if selectedType != "All" {
            filtered = filtered.filter { $0.type?.lowercased() == selectedType.lowercased() }
        }
        if selectedUse != "All" {
            filtered = filtered.filter { $0.use?.lowercased() == selectedUse.lowercased() }
        }
        if !searchText.isEmpty {
            let searchTextLower = searchText.lowercased()
            filtered = filtered.filter { fluid in
                let searchableText = "\(fluid.name) \(fluid.manufacturer) \(fluid.use ?? "") \(fluid.type ?? "") \(fluid.formattedIndex)".lowercased()
                return searchableText.contains(searchTextLower)
            }
        }
        filteredFluids = filtered
        manufacturers = ["All"] + Array(Set(fluids.map { $0.manufacturer })).sorted()
        types = ["All"] + Array(Set(fluids.compactMap { $0.type })).sorted()
        uses = ["All"] + Array(Set(fluids.compactMap { $0.use })).sorted()
    }
}

// MARK: - Multi-select manufacturer filter (persisted; "All" = empty set)
struct ManufacturerFilterButton: View {
    @Binding var selected: Set<String>
    let options: [String]
    
    private var manufacturerOptions: [String] {
        options.filter { $0 != "All" }
    }
    
    private var labelText: String {
        if selected.isEmpty { return "All" }
        if selected.count <= 2 { return selected.sorted().joined(separator: ", ") }
        return "\(selected.count) manufacturers"
    }
    
    var body: some View {
        Menu {
            Button(action: { selected = [] }) {
                HStack {
                    Text("All")
                    if selected.isEmpty { Image(systemName: "checkmark") }
                }
            }
            ForEach(manufacturerOptions, id: \.self) { option in
                Button(action: {
                    var next = selected
                    if next.contains(option) {
                        next.remove(option)
                    } else {
                        next.insert(option)
                    }
                    selected = next
                }) {
                    HStack {
                        Text(option)
                        if selected.contains(option) { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack {
                Text("Manufacturer")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.textColor)
                Text(labelText)
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.accentColor)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(AppStyle.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Main Fluids View
struct FluidsView: View {
    @StateObject private var viewModel = FluidsViewModel()
    @State private var showFilters = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var shouldResetNavigation = false
    @State private var showWelcomeView = false
    
    private func resetView() {
        // Clear all filters (manufacturer multi-select → empty = show all)
        viewModel.selectedManufacturers = []
        viewModel.selectedType = "All"
        viewModel.selectedUse = "All"
        viewModel.searchText = ""
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
                SearchBar(text: $viewModel.searchText, placeholder: "Search fluids...")
                    .padding(.horizontal)
                
            // Filter buttons with reset
            VStack(spacing: AppStyle.Spacing.small) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppStyle.Spacing.small) {
                        ManufacturerFilterButton(selected: $viewModel.selectedManufacturers, options: viewModel.manufacturers)
                        FilterButton(title: "Type", selection: $viewModel.selectedType, options: viewModel.types)
                        FilterButton(title: "Use", selection: $viewModel.selectedUse, options: viewModel.uses)
                    }
                    .padding(.horizontal)
                            }
                            
                // Reset filters button
                if !viewModel.selectedManufacturers.isEmpty || viewModel.selectedType != "All" || viewModel.selectedUse != "All" || !viewModel.searchText.isEmpty {
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
            } else if viewModel.filteredFluids.isEmpty {
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
                    List(viewModel.filteredFluids) { fluid in
                        NavigationLink(value: fluid) {
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
                    .navigationDestination(for: Fluid.self) { fluid in
                        if let details = viewModel.getFluidDetails(for: fluid) {
                            FluidDetailView(row: details.row, headers: details.headers)
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
        .onChange(of: viewModel.searchText) { _ in viewModel.updateFilteredData() }
        .onChange(of: viewModel.selectedManufacturers) { _ in viewModel.updateFilteredData() }
        .onChange(of: viewModel.selectedType) { _ in viewModel.updateFilteredData() }
        .onChange(of: viewModel.selectedUse) { _ in viewModel.updateFilteredData() }
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
