import SwiftUI

// MARK: - Case filter persistence (one of Core Category or Risk Model at a time; sticks until reset)
enum CaseFilterStorage {
    private static let coreCategoryKey = "CaseView.selectedCoreCategory"
    private static let riskModelKey = "CaseView.selectedRiskModel"
    
    static func load() -> (coreCategory: String, riskModel: String) {
        let cc = UserDefaults.standard.string(forKey: coreCategoryKey) ?? "All"
        let rm = UserDefaults.standard.string(forKey: riskModelKey) ?? "All"
        // Ensure at most one is non-All (prefer core category if both were set)
        if cc != "All" && rm != "All" {
            return (cc, "All")
        }
        return (cc, rm)
    }
    
    static func save(coreCategory: String, riskModel: String) {
        UserDefaults.standard.set(coreCategory, forKey: coreCategoryKey)
        UserDefaults.standard.set(riskModel, forKey: riskModelKey)
    }
}

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
    
    /// Filter: only one of these is non-"All" at a time; persisted until reset.
    @Published var selectedCoreCategory: String = "All" {
        didSet {
            if selectedCoreCategory != "All" { selectedRiskModel = "All" }
            CaseFilterStorage.save(coreCategory: selectedCoreCategory, riskModel: selectedRiskModel)
        }
    }
    @Published var selectedRiskModel: String = "All" {
        didSet {
            if selectedRiskModel != "All" { selectedCoreCategory = "All" }
            CaseFilterStorage.save(coreCategory: selectedCoreCategory, riskModel: selectedRiskModel)
        }
    }
    @Published var coreCategories: [String] = ["All"]
    @Published var riskModels: [String] = ["All"]
    
    init() {
        let (cc, rm) = CaseFilterStorage.load()
        selectedCoreCategory = cc
        selectedRiskModel = rm
    }
    
    func resetFilters() {
        selectedCoreCategory = "All"
        selectedRiskModel = "All"
        CaseFilterStorage.save(coreCategory: "All", riskModel: "All")
    }
    
    private func uniqueValues(forHeader header: String) -> [String] {
        guard !conditionsData.isEmpty,
              let idx = headers.firstIndex(of: header), idx < conditionsData[0].count else { return [] }
        let set = Set(conditionsData.map { row in row[idx].trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return Array(set).sorted()
    }
    
    func loadData() {
        print("\n=== Loading Conditions Data ===")
        isLoading = true
        errorMessage = nil
        
        // First, let's check what tables are available
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
        
        // Now try to load the conditions data with the correct column name
        let query = """
            SELECT "CASE TYPE", "SOLUTION STRENGTH", "CH2O INDEX", "STRENGTH (%)", 
                   "SPECIAL TREATMENT", "SUGGESTED ACCESSORY/SUPPLIMENTAL", 
                   "HUMECTANT", "INSTRUCTIONS", "CORECATEGORY", "RISK MODEL"
            FROM CONDITIONS 
            ORDER BY "CASE TYPE" ASC
        """
        
        print("\nTrying query: \(query)")
        if let results = DatabaseManager.shared.executeQuery(query) {
            print("Raw query returned \(results.count) results")
            
            if results.isEmpty {
                print("WARNING: No conditions found in database")
                errorMessage = "No conditions found in database"
            } else {
                // Get headers from the first result
                headers = Array(results[0].keys).sorted()
                print("Available headers: \(headers.joined(separator: ", "))")
                
                // Convert results to rows
                conditionsData = results.map { dict in
                    headers.map { header in
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
                
                // Build filter options from CORECATEGORY and RISK MODEL (unique, non-empty)
                coreCategories = ["All"] + uniqueValues(forHeader: "CORECATEGORY")
                riskModels = ["All"] + uniqueValues(forHeader: "RISK MODEL")
                
                print("\nSuccessfully loaded \(conditionsData.count) rows")
                
                // Print first few conditions for verification
                print("\nFirst 5 conditions:")
                for (index, row) in conditionsData.prefix(5).enumerated() {
                    if let caseTypeIndex = headers.firstIndex(of: "CASE TYPE") {
                        print("\(index + 1). \(row[caseTypeIndex])")
                    }
                }
            }
        } else {
            print("❌ Query failed to return data")
            errorMessage = "Failed to load conditions from database"
        }
        
        isLoading = false
        print("=== Finished Loading Conditions ===\n")
    }
}

// MARK: - Main View
public struct CaseView: View {
    @StateObject private var viewModel = CaseViewModel()
    @State private var searchText = ""
    @State private var shouldResetNavigation = false
    
    var filteredRows: [[String]] {
        var rows = viewModel.conditionsData
        // Search (CASE TYPE)
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            rows = rows.filter { row in
                if let idx = viewModel.headers.firstIndex(of: "CASE TYPE"), idx < row.count {
                    return row[idx].lowercased().contains(q)
                }
                return false
            }
        }
        // Filter: only one of Core Category or Risk Model (never both)
        if viewModel.selectedCoreCategory != "All" {
            if let idx = viewModel.headers.firstIndex(of: "CORECATEGORY"), idx < (rows.first?.count ?? 0) {
                rows = rows.filter { $0[idx].trimmingCharacters(in: .whitespacesAndNewlines) == viewModel.selectedCoreCategory }
            }
        } else if viewModel.selectedRiskModel != "All" {
            if let idx = viewModel.headers.firstIndex(of: "RISK MODEL"), idx < (rows.first?.count ?? 0) {
                rows = rows.filter { $0[idx].trimmingCharacters(in: .whitespacesAndNewlines) == viewModel.selectedRiskModel }
            }
        }
        return rows
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
                
                // Filters: Core Category or Risk Model (one at a time; persisted until reset)
                VStack(spacing: AppStyle.Spacing.small) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppStyle.Spacing.small) {
                            FilterButton(title: "Core Category", selection: $viewModel.selectedCoreCategory, options: viewModel.coreCategories)
                            FilterButton(title: "Risk Model", selection: $viewModel.selectedRiskModel, options: viewModel.riskModels)
                        }
                        .padding(.horizontal)
                    }
                    if !searchText.isEmpty || viewModel.selectedCoreCategory != "All" || viewModel.selectedRiskModel != "All" {
                        Button(action: {
                            searchText = ""
                            viewModel.resetFilters()
                        }) {
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
