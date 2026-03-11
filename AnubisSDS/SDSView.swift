import SwiftUI

struct SDSView: View {
    @State private var fluids: [Fluid] = []
    @State private var searchText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var shouldResetNavigation = false
    
    /// SDS search: fluid name and manufacturer only (fuzzy substring match).
    var filteredFluids: [Fluid] {
        if searchText.isEmpty {
            return fluids
        }
        let q = searchText.lowercased()
        return fluids.filter { fluid in
            fluid.name.lowercased().contains(q) || fluid.manufacturer.lowercased().contains(q)
        }
    }
    
    var body: some View {
            VStack(spacing: 0) {
            // Header section - keep only reload button
                VStack(spacing: AppStyle.Spacing.small) {
                    HStack {
                        Spacer()
                        
                        // Reload button
                        Button(action: {
                            print("Force reloading SDS data...")
                            DatabaseManager.shared.updateFluidsCache(force: true)
                            loadFluidsData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppStyle.accentColor)
                        }
                    }
                    .padding(.horizontal, AppStyle.Spacing.medium)
                }
                .padding(.top, AppStyle.Spacing.small)
                
                // Search bar (same component as Fluids / Case / Favorites)
                SearchBar(text: $searchText, placeholder: "Search fluids...")
                    .padding(.horizontal)
                    .padding(.top, AppStyle.Spacing.small)
                
                // List of fluids
                if fluids.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Fluids Found")
                            .font(.headline)
                        Text("Try adjusting your search or check back later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppStyle.backgroundColor)
                } else {
                    List(filteredFluids) { fluid in
                        NavigationLink(destination: SDSDetailView(fluid: fluid)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fluid.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(fluid.manufacturer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let emergencyContact = fluid.emergencyContact {
                                    Text(emergencyContact)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(AppStyle.backgroundColor)
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
            loadFluidsData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetNavigation"))) { _ in
            shouldResetNavigation = true
        }
        .id(shouldResetNavigation)
    }
    
    private func loadFluidsData() {
        print("Starting to load SDS data from database...")
        
        // Try to get from cache first
        if let cached = DatabaseManager.shared.getCachedFluids() {
            print("Using cached fluids data")
            fluids = cached.fluids
            return
        }
        
        // If not in cache, load from database and update cache
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            fluids = cached.fluids
        } else {
            print("Failed to load fluids")
            showError = true
            errorMessage = "Failed to load fluids from database"
        }
    }
}

#Preview {
    SDSView()
}

#Preview("Dark Mode") {
    SDSView()
        .preferredColorScheme(.dark)
}
