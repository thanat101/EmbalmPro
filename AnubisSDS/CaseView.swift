import SwiftUI

// MARK: - Case Row View
private struct CaseRowView: View {
    let row: [String]
    let headers: [String]
    
    private func getValue(for field: String) -> String {
        if let index = headers.firstIndex(of: field), index < row.count {
            return row[index]
        }
        return ""
    }
    
    var body: some View {
        NavigationLink(destination: CaseDetailView(condition: row, headers: headers)) {
            VStack(alignment: .leading, spacing: 8) {
                // Case Type
                Text(getValue(for: "CASE TYPE"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                    // Solution Strength
                    HStack(spacing: 4) {
                    Text("Needed Solution Strength:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(getValue(for: "SOLUTION STRENGTH"))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    // CH2O Index
                    HStack(spacing: 4) {
                    Text("Embalming Fluid Index:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(getValue(for: "CH2O INDEX"))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                }
            }
            .padding(.vertical, AppStyle.Spacing.small)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.vertical, 4)
    }
}

// MARK: - Case View Model
@MainActor
class CaseViewModel: ObservableObject {
    @Published var conditionsData: [[String]] = []
    @Published var headers: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    func loadData() {
        print("\n=== Loading Conditions Data ===")
        isLoading = true
        errorMessage = nil

        // Try cache first to avoid re-querying and speed up perceived performance
        if DatabaseManager.shared.getCachedFluids() != nil {
            // Reconstruct headers and rows for conditions if present in cache (best-effort)
            // If your cache doesn't carry conditions, we'll fall back to DB query below.
            // We keep this branch lightweight and non-blocking.
            
            // Best-effort: attempt to hydrate conditions from a lightweight cache to improve perceived performance
            if let cached = UserDefaults.standard.object(forKey: "CachedConditionsPayload") as? [String: Any],
               let cachedHeaders = cached["headers"] as? [String],
               let cachedRows = cached["rows"] as? [[String]],
               !cachedHeaders.isEmpty,
               !cachedRows.isEmpty {
                // Apply on main actor synchronously since we're already on main here
                self.headers = cachedHeaders
                self.conditionsData = cachedRows
                print("Hydrated conditions from UserDefaults cache: \(cachedRows.count) rows")
            }
        }

        // Perform heavy DB work off the main thread
        Task.detached {
            // First, list tables (debug aid). This is safe off-main as it uses DB directly.
            let tableQuery = """
                SELECT name FROM sqlite_master 
                WHERE type='table' 
                AND name NOT LIKE 'sqlite_%'
            """

            if let tables = DatabaseManager.shared.executeQuery(tableQuery) {
                print("\nAvailable tables in database:")
                for table in tables {
                    if let tableName = table["name"] as? String {
                        print("- \(tableName)")
                    }
                }
            }

            // Main conditions query
            let query = """
                SELECT "CASE TYPE", "SOLUTION STRENGTH", "CH2O INDEX", "STRENGTH (%)", 
                       "SPECIAL TREATMENT", "SUGGESTED ACCESSORY/SUPPLIMENTAL", 
                       "HUMECTANT", "INSTRUCTIONS"
                FROM CONDITIONS 
                ORDER BY "CASE TYPE" ASC
            """

            print("\nTrying query: \(query)")
            let results = DatabaseManager.shared.executeQuery(query)

            await MainActor.run {
                defer {
                    self.isLoading = false
                    print("=== Finished Loading Conditions ===\n")
                }

                guard let results else {
                    print("❌ Query failed to return data")
                    self.errorMessage = "Failed to load conditions from database"
                    self.conditionsData = []
                    self.headers = []
                    return
                }

                print("Raw query returned \(results.count) results")

                if results.isEmpty {
                    print("WARNING: No conditions found in database")
                    self.errorMessage = "No conditions found in database"
                    self.conditionsData = []
                    self.headers = []
                    return
                }

                // Compute headers deterministically off returned keys
                let computedHeaders = Array(results[0].keys).sorted()
                self.headers = computedHeaders
                print("Available headers: \(computedHeaders.joined(separator: ", "))")

                // Map results to string rows
                self.conditionsData = results.map { dict in
                    computedHeaders.map { header in
                        if let value = dict[header] {
                            if let stringValue = value as? String {
                                return stringValue
                            } else if let doubleValue = value as? Double {
                                return String(doubleValue)
                            } else if let intValue = value as? Int64 {
                                return String(intValue)
                            }
                        }
                        return ""
                    }
                }

                print("\nSuccessfully loaded \(self.conditionsData.count) rows")
                print("\nFirst 5 conditions:")
                for (index, row) in self.conditionsData.prefix(5).enumerated() {
                    if let caseTypeIndex = self.headers.firstIndex(of: "CASE TYPE"), caseTypeIndex < row.count {
                        print("\(index + 1). \(row[caseTypeIndex])")
                    }
                }
                
                // Persist a lightweight cache for faster warm-starts
                let payload: [String: Any] = [
                    "headers": self.headers,
                    "rows": self.conditionsData
                ]
                UserDefaults.standard.set(payload, forKey: "CachedConditionsPayload")
                UserDefaults.standard.synchronize()
                print("Cached conditions to UserDefaults: \(self.conditionsData.count) rows")
            }
        }
    }
}

// MARK: - Main View
public struct CaseView: View {
    @StateObject private var viewModel = CaseViewModel()
    @State private var searchText = ""
    @State private var shouldResetNavigation = false
    
    var filteredRows: [[String]] {
        if searchText.isEmpty {
            return viewModel.conditionsData
        }
        
        return viewModel.conditionsData.filter { row in
            if let caseTypeIndex = viewModel.headers.firstIndex(of: "CASE TYPE"),
               caseTypeIndex < row.count {
                return row[caseTypeIndex].lowercased().contains(searchText.lowercased())
            }
            return false
        }
    }
    
    public var body: some View {
            VStack(spacing: 0) {
            // Header section - remove title, keep spacing for consistency
                VStack(spacing: AppStyle.Spacing.small) {
                // Empty VStack for consistent spacing
                }
                .padding(.top, AppStyle.Spacing.small)
                
                // Total count
                HStack {
                    Text("Total Cases: \(viewModel.conditionsData.count)")
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.secondaryTextColor)
                    Spacer()
                }
                .padding(.horizontal, AppStyle.Spacing.medium)
                .padding(.top, AppStyle.Spacing.small)
                
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search cases...")
                    .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppStyle.Typography.body)
                        .foregroundColor(.red)
                        .padding(AppStyle.Spacing.medium)
                        .cardStyle()
                        .padding(.horizontal, AppStyle.Spacing.medium)
                        .padding(.top, AppStyle.Spacing.small)
                } else if viewModel.conditionsData.isEmpty {
                    Text("No cases available")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.secondaryTextColor)
                        .padding(AppStyle.Spacing.medium)
                        .cardStyle()
                        .padding(.horizontal, AppStyle.Spacing.medium)
                        .padding(.top, AppStyle.Spacing.small)
                } else {
                    List {
                        ForEach(filteredRows, id: \.self) { row in
                            CaseRowView(row: row, headers: viewModel.headers)
                        }
                    }
                    .listStyle(PlainListStyle())
                .scrollDismissesKeyboard(.immediately)
                    .background(AppStyle.backgroundColor)
                }
                
                Spacer()
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
        .id(shouldResetNavigation)
    }
}

#Preview {
    CaseView()
} 
