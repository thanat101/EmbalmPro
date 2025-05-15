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
                   "HUMECTANT", "INSTRUCTIONS"
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