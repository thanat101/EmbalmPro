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
    
    func loadData() {
        print("\n=== Loading Fluids ===")
        isLoading = true
        error = nil
        
        // Try to get from cache first
        if let cached = DatabaseManager.shared.getCachedFluids() {
            print("Using cached fluids data")
            fluids = cached.fluids
            headers = cached.headers
            rows = cached.rows
            isLoading = false
            print("=== Finished Loading Fluids (from cache) ===\n")
            return
        }
        
        // If not in cache, load from database and update cache
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            fluids = cached.fluids
            headers = cached.headers
            rows = cached.rows
        } else {
            error = "Failed to load fluids from database"
        }
        
        isLoading = false
        print("=== Finished Loading Fluids ===\n")
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
        // Reload data
        viewModel.loadData()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: AppStyle.Spacing.small) {
                    HStack {
                        Text("Fluid Database")
                            .font(AppStyle.Typography.subheadline)
                            .foregroundColor(AppStyle.textColor)
                        
                        Spacer()
                        
                        // Reload button
                        Button(action: {
                            print("Force reloading fluids cache...")
                            DatabaseManager.shared.updateFluidsCache()
                            viewModel.loadData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppStyle.accentColor)
                        }
                        
                        Button(action: {
                            showWelcomeView = true
                        }) {
                            Text("About")
                                .font(AppStyle.Typography.subheadline)
                                .foregroundColor(AppStyle.accentColor)
                        }
                    }
                    .padding(.horizontal, AppStyle.Spacing.medium)
                }
                .padding(.top, AppStyle.Spacing.small)
                .sheet(isPresented: $showWelcomeView) {
                    WelcomeView(isPresented: $showWelcomeView)
                }
                
                // Total count
                HStack {
                    Text("Total Fluids: \(viewModel.fluids.count)")
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.secondaryTextColor)
                    Spacer()
                }
                .padding(.horizontal, AppStyle.Spacing.medium)
                .padding(.top, AppStyle.Spacing.small)
                .padding(.bottom, AppStyle.Spacing.medium)
                
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search fluids...")
                    .padding(.horizontal)
                
                // Filter controls
                HStack {
                    // Filter by button
                    Button(action: {
                        showFilters.toggle()
                    }) {
                        HStack {
                            Text("Filter by")
                                .font(AppStyle.Typography.body)
                                .foregroundColor(AppStyle.primaryColor)
                            Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                                .foregroundColor(AppStyle.primaryColor)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                    
                    // Clear filters button
                    if selectedManufacturer != "All" || selectedType != "All" || selectedUse != "All" {
                        Button(action: {
                            selectedManufacturer = "All"
                            selectedType = "All"
                            selectedUse = "All"
                        }) {
                            Text("Clear Filters")
                                .font(AppStyle.Typography.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Filter section
                if showFilters {
                    VStack(spacing: AppStyle.Spacing.small) {
                        HStack(spacing: AppStyle.Spacing.small) {
                            // Type filter
                            VStack(alignment: .leading) {
                                Text("Type")
                                    .font(AppStyle.Typography.caption)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                                Picker("Type", selection: $selectedType) {
                                    ForEach(types, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Use filter
                            VStack(alignment: .leading) {
                                Text("Use")
                                    .font(AppStyle.Typography.caption)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                                Picker("Use", selection: $selectedUse) {
                                    ForEach(uses, id: \.self) { use in
                                        Text(use).tag(use)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Manufacturer filter
                            VStack(alignment: .leading) {
                                Text("Manufacturer")
                                    .font(AppStyle.Typography.caption)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                                Picker("Manufacturer", selection: $selectedManufacturer) {
                                    ForEach(manufacturers, id: \.self) { manufacturer in
                                        Text(manufacturer).tag(manufacturer)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, AppStyle.Spacing.medium)
                    }
                    .padding(.vertical, AppStyle.Spacing.small)
                    .background(Color(.systemBackground))
                }
                
                if showError {
                    Text(errorMessage)
                        .font(AppStyle.Typography.body)
                        .foregroundColor(.red)
                        .padding(AppStyle.Spacing.medium)
                        .cardStyle()
                        .padding(.horizontal, AppStyle.Spacing.medium)
                        .padding(.top, AppStyle.Spacing.small)
                } else if viewModel.fluids.isEmpty {
                    Text("No data available")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.secondaryTextColor)
                        .padding(AppStyle.Spacing.medium)
                        .cardStyle()
                        .padding(.horizontal, AppStyle.Spacing.medium)
                        .padding(.top, AppStyle.Spacing.small)
                } else {
                    // Data list
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
                }
            }
            .navigationBarHidden(true)
            .background(AppStyle.backgroundColor)
        }
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
 