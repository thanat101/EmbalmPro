import SwiftUI
import SafariServices

// MARK: - Helper Functions
private func getValue(for field: String, in row: [String], headers: [String]) -> String {
    if let index = headers.firstIndex(of: field), index < row.count {
        return row[index]
    }
    return ""
}

// MARK: - Header Section View
private struct FluidHeaderView: View {
    let row: [String]
    let headers: [String]
    let isEditing: Bool
    var editedValues: [String: String]
    var onValueChanged: (String, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
            // Fluid Name Section
            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                Text("Fluid Name")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .textCase(.uppercase)
                
                if isEditing {
                    TextField("Fluid Name", text: Binding(
                        get: { editedValues["FLUID"] ?? getValue(for: "FLUID", in: row, headers: headers) },
                        set: { onValueChanged("FLUID", $0) }
                    ))
                    .font(AppStyle.Typography.title)
                    .foregroundColor(AppStyle.textColor)
                } else {
                    Text(getValue(for: "FLUID", in: row, headers: headers))
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                }
            }
            
            // Index and Manufacturer Section
            HStack(alignment: .top, spacing: AppStyle.Spacing.large) {
                // Index
                VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                    Text("Index")
                        .font(AppStyle.Typography.caption)
                        .foregroundColor(AppStyle.secondaryTextColor)
                        .textCase(.uppercase)
                    
                    if isEditing {
                        TextField("Index", text: Binding(
                            get: { editedValues["INDEX"] ?? getValue(for: "INDEX", in: row, headers: headers) },
                            set: { onValueChanged("INDEX", $0) }
                        ))
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .keyboardType(.decimalPad)
                    } else {
                        Text(getValue(for: "INDEX", in: row, headers: headers))
                            .font(AppStyle.Typography.headline)
                            .foregroundColor(AppStyle.textColor)
                    }
                }
                
                Spacer()
                
                // Manufacturer
                VStack(alignment: .trailing, spacing: AppStyle.Spacing.small) {
                    Text("Manufacturer")
                        .font(AppStyle.Typography.caption)
                        .foregroundColor(AppStyle.secondaryTextColor)
                        .textCase(.uppercase)
                    
                    if isEditing {
                        TextField("Manufacturer", text: Binding(
                            get: { editedValues["MANUFACTURER"] ?? getValue(for: "MANUFACTURER", in: row, headers: headers) },
                            set: { onValueChanged("MANUFACTURER", $0) }
                        ))
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .multilineTextAlignment(.trailing)
                    } else {
                        Text(getValue(for: "MANUFACTURER", in: row, headers: headers))
                            .font(AppStyle.Typography.headline)
                            .foregroundColor(AppStyle.textColor)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(AppStyle.Spacing.large)
        .background(Color(.systemBackground))
        .cornerRadius(AppStyle.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Details Section View
private struct FluidDetailsView: View {
    let row: [String]
    let headers: [String]
    let isEditing: Bool
    var editedValues: [String: String]
    var onValueChanged: (String, String) -> Void
    let fluid: Fluid?
    @State private var debugStatus: String = ""
    
    private func updateDebugStatus(_ message: String) {
        print(message)
        debugStatus = message
    }
    
    // Group fields into logical categories
    private let fieldGroups: [(String, [String])] = [
        ("Fluid Properties", ["COSMETIC", "COLOR", "FIRMING_SPEED", "HUMECTANT", "TYPE"]),
        ("Usage Information", ["USE", "SECOND_USE", "GLUT"]),
        ("Manufacturer Details", ["MANUFACTURER", "SELLER_INFO", "MANUFACTURER_INSTRUCTIONS"]),
        ("Contact Information", ["COMPANY_ADDRESS", "COMPANY_PHONE", "EMERGENCY_CONTACT"]),
        ("Additional Details", ["DATE", "FILENAME"])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
            // Section Header
            Text("Additional Information")
                .font(AppStyle.Typography.headline)
                .foregroundColor(AppStyle.textColor)
                .padding(.bottom, AppStyle.Spacing.small)
            
            // Grouped Fields
            ForEach(fieldGroups, id: \.0) { group in
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    // Group Header
                    Text(group.0)
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.primaryColor)
                        .padding(.bottom, 4)
                    
                    // Fields in this group
                    ForEach(group.1, id: \.self) { field in
                        if headers.contains(field) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(field.replacingOccurrences(of: "_", with: " "))
                                    .font(AppStyle.Typography.caption)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                                    .textCase(.uppercase)
                                
                                if isEditing {
                                    TextField(field, text: Binding(
                                        get: { editedValues[field] ?? getValue(for: field, in: row, headers: headers) },
                                        set: { onValueChanged(field, $0) }
                                    ))
                                    .font(AppStyle.Typography.body)
                                    .foregroundColor(AppStyle.textColor)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    Text(getValue(for: field, in: row, headers: headers))
                                        .font(AppStyle.Typography.body)
                                        .foregroundColor(AppStyle.textColor)
                                }
                            }
                            .padding(.vertical, 2)
                            
                            // Add divider between fields, but not after the last one
                            if field != group.1.last {
                                Divider()
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding(AppStyle.Spacing.small)
                .background(Color(.systemBackground))
                .cornerRadius(AppStyle.CornerRadius.medium)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            // SDS Link Card
            VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                if let fluid = fluid {
                    NavigationLink(destination: SDSDetailView(fluid: fluid)) {
                        HStack {
                            Text("View Safety Data Sheet")
                                .font(AppStyle.Typography.body)
                                .foregroundColor(AppStyle.primaryColor)
                            Spacer()
                            Image(systemName: "doc.text.fill")
                                .font(AppStyle.Typography.body)
                                .foregroundColor(AppStyle.primaryColor)
                        }
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        updateDebugStatus("📄 Rendering SDS link for fluid: \(fluid.name)")
                    }
                } else {
                    Text("Safety Data Sheet not available")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.secondaryTextColor)
                        .padding(.vertical, 8)
                        .onAppear {
                            updateDebugStatus("⚠️ No fluid object available for SDS link")
                        }
                }
            }
            .padding(AppStyle.Spacing.small)
            .background(Color(.systemBackground))
            .cornerRadius(AppStyle.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(AppStyle.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(AppStyle.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            updateDebugStatus("🔍 FluidDetailsView appeared with fluid: \(fluid != nil ? "available" : "nil")")
        }
    }
}

// MARK: - Main View
struct FluidDetailView: View {
    let row: [String]
    let headers: [String]
    let conditionStrength: String?
    @State private var showDilutionPopup = false
    @State private var isEditing = false
    @State private var editedValues: [String: String] = [:]
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isFavorite = false
    @State private var fluid: Fluid?
    @State private var debugStatus: String = ""
    @State private var hasAttemptedLoad = false
    
    private func updateDebugStatus(_ message: String) {
        #if DEBUG
        print(message)
        debugStatus = message
        #endif
    }
    
    init(row: [String], headers: [String], conditionStrength: String? = nil) {
        self.row = row
        self.headers = headers
        self.conditionStrength = conditionStrength
        
        // Initialize isFavorite state
        let fluidName = getValue(for: "FLUID", in: row, headers: headers)
        #if DEBUG
        print("🔍 Initializing FluidDetailView for fluid: \(fluidName)")
        #endif
        
        if !fluidName.isEmpty {
            _isFavorite = State(initialValue: FavoritesManager.shared.isFavorite(fluidName: fluidName))
        }
    }
    
    private func tryLoadFluid() {
        // Only try to load if we haven't already and haven't attempted before
        guard fluid == nil && !hasAttemptedLoad else { return }
        
        let fluidName = getValue(for: "FLUID", in: row, headers: headers)
        if !fluidName.isEmpty {
            hasAttemptedLoad = true  // Mark that we've attempted to load
            // Try to get from cache first
            if let cachedFluid = DatabaseManager.shared.getCachedFluid(name: fluidName) {
                updateDebugStatus("📦 Using cached fluid object for: \(fluidName)")
                self.fluid = cachedFluid
            } else if let newFluid = DatabaseManager.shared.getFluid(name: fluidName) {
                updateDebugStatus("📦 Created new fluid object for: \(fluidName)")
                self.fluid = newFluid
            } else {
                updateDebugStatus("❌ Failed to create fluid object for: \(fluidName)")
            }
        }
    }
    
    private var fluidName: String {
        getValue(for: "FLUID", in: row, headers: headers)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppStyle.Spacing.large) {
                // Header section with basic info
                FluidHeaderView(
                    row: row,
                    headers: headers,
                    isEditing: isEditing,
                    editedValues: editedValues,
                    onValueChanged: { header, value in
                        editedValues[header] = value
                    }
                )
                .padding(.horizontal)
                
                // Calculate Primary Dilution button
                if getValue(for: "TYPE", in: row, headers: headers).lowercased().contains("vascular") {
                    let index = getValue(for: "INDEX", in: row, headers: headers)
                    if !index.isEmpty {
                        Button(action: {
                            showDilutionPopup = true
                        }) {
                            HStack {
                                Image(systemName: "function")
                                    .font(AppStyle.Typography.title)
                                Text("Calculate Primary Dilution")
                                    .font(AppStyle.Typography.headline)
                            }
                            .foregroundColor(AppStyle.primaryColor)
                            .padding(AppStyle.Spacing.medium)
                            .frame(maxWidth: .infinity)
                            .background(AppStyle.primaryColor.opacity(0.1))
                            .cornerRadius(AppStyle.CornerRadius.medium)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showDilutionPopup) {
                            DilutionPopupView(
                                fluidIndex: index,
                                conditionStrength: conditionStrength,
                                fluidName: fluidName
                            )
                        }
                    }
                }
                
                // Details section with additional information
                FluidDetailsView(
                    row: row,
                    headers: headers,
                    isEditing: isEditing,
                    editedValues: editedValues,
                    onValueChanged: { header, value in
                        editedValues[header] = value
                    },
                    fluid: fluid
                )
                .padding(.horizontal)
                .onAppear {
                    updateDebugStatus("🔍 Main view appeared with fluid: \(fluid != nil ? "available" : "nil")")
                    tryLoadFluid()
                }
            }
            .padding(.vertical, AppStyle.Spacing.medium)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Fluid Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Favorite button
                    Button(action: {
                        let fluidName = getValue(for: "FLUID", in: row, headers: headers)
                        if !fluidName.isEmpty {
                            if isFavorite {
                                FavoritesManager.shared.removeFavorite(fluidName: fluidName)
                            } else {
                                FavoritesManager.shared.addFavorite(fluidName: fluidName)
                            }
                            isFavorite.toggle()
                        }
                    }) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .gray)
                    }
                    
                    // Edit button
                    Button(action: {
                        if isEditing {
                            print("💾 Save button pressed")
                            saveChanges()
                            if !showError {
                                isEditing = false
                            }
                        } else {
                            print("✏️ Edit button pressed")
                            isEditing = true
                        }
                    }) {
                        Text(isEditing ? "save" : "edit")
                            .font(.subheadline)
                            .foregroundColor(AppStyle.primaryColor)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveChanges() {
        print("\n=== Starting Save Process ===")
        print("💾 Attempting to save changes for fluid...")
        
        // Get the fluid name (this is our unique identifier)
        let fluidName = getValue(for: "FLUID", in: row, headers: headers)
        print("📝 Fluid Name: \(fluidName)")
        
        // Convert edited values to database updates
        var updates: [String: Any] = [:]
        for (field, value) in editedValues {
            // Skip empty values to avoid overwriting with empty strings
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                updates[field] = value
                print("📝 Field to update: \(field) = \(value)")
            }
        }
        
        if updates.isEmpty {
            print("⚠️ No changes to save - updates dictionary is empty")
            isEditing = false
            return
        }
        
        print("💾 Attempting database update with \(updates.count) fields...")
        
        // Attempt to save the changes
        if DatabaseManager.shared.updateFluid(fluidName: fluidName, updates: updates) {
            print("✅ Save successful")
            print("📢 Posting FluidsChanged notification")
            isEditing = false
            editedValues.removeAll()
            
            // Post notification to refresh the fluids list
            NotificationCenter.default.post(name: NSNotification.Name("FluidsChanged"), object: nil)
            
            // Force cache update
            print("🔄 Forcing cache update...")
            DatabaseManager.shared.updateFluidsCache(force: true)
            
            print("=== Save Process Complete ===\n")
        } else {
            print("❌ Save failed")
            print("⚠️ Database update returned false")
            errorMessage = "Failed to save changes to database"
            showError = true
            print("=== Save Process Failed ===\n")
        }
    }
}

#Preview {
    NavigationView {
        FluidDetailView(
            row: ["Test Fluid", "123", "Test Manufacturer", "Detail 1", "Detail 2", "Detail 3", "Detail 4", "Detail 5", "Detail 6", "Detail 7", "Detail 8", "Detail 9", "Detail 10", "Detail 11", "Detail 12", "Detail 13", "Detail 14", "Detail 15", "Detail 16", "Last Detail", "Second Last"],
            headers: ["FLUID", "INDEX", "MANUFACTURER", "Detail1", "Detail2", "Detail3", "Detail4", "Detail5", "Detail6", "Detail7", "Detail8", "Detail9", "Detail10", "Detail11", "Detail12", "Detail13", "Detail14", "Detail15", "Detail16", "LastDetail", "SecondLast"],
            conditionStrength: "2.5"
        )
    }
}
