import SwiftUI

// MARK: - SDS Section Detail View
struct SDSSectionDetailView: View {
    let title: String
    let content: String?
    @State private var isEditing = false
    @State private var editedContent: String
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void
    
    init(title: String, content: String?, onSave: @escaping (String) -> Void) {
        self.title = title
        self.content = content
        self.onSave = onSave
        self._editedContent = State(initialValue: content ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    if let content = content, !content.isEmpty {
                        Text(content)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("No information available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            editedContent = content ?? ""
                            isEditing = false
                        }
                        .foregroundColor(.red)
                        
                        Button("Save") {
                            showSaveConfirmation = true
                        }
                        .foregroundColor(AppStyle.primaryColor)
                    }
                } else {
                    Button("Edit") {
                        editedContent = content ?? ""
                        isEditing = true
                    }
                    .foregroundColor(AppStyle.primaryColor)
                }
            }
        }
        .alert("Save Changes", isPresented: $showSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                // Validate content before saving
                let trimmedContent = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedContent.isEmpty {
                    errorMessage = "Cannot save empty content"
                    showError = true
                } else {
                    onSave(editedContent)
                    isEditing = false
                }
            }
        } message: {
            Text("Are you sure you want to save these changes?")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - SDS Detail View Model
@MainActor
class SDSDetailViewModel: ObservableObject {
    @Published var fluid: Fluid
    @Published var editedValues: [String: String] = [:]
    @Published var editingSection: String? = nil
    @Published var showError = false
    @Published var errorMessage = ""
    
    init(fluid: Fluid) {
        self.fluid = fluid
        print("🔍 Initializing SDSDetailView for fluid: \(fluid.name)")
    }
    
    func updateFluid(_ newFluid: Fluid) {
        self.fluid = newFluid
    }
    
    func getValueForField(_ field: String) -> String? {
        switch field {
        case "name": return fluid.name
        case "manufacturer": return fluid.manufacturer
        case "emergencyContact": return fluid.emergencyContact
        case "date": return fluid.date
        case "filename": return fluid.filename
        case "identification": return fluid.identification
        case "hazards": return fluid.hazards
        case "composition": return fluid.composition
        case "firstAid": return fluid.firstAid
        case "fire": return fluid.fire
        case "accident": return fluid.accident
        case "handling": return fluid.handling
        case "exposure": return fluid.exposure
        case "properties": return fluid.properties
        case "stability": return fluid.stability
        case "toxicology": return fluid.toxicology
        case "ecology": return fluid.ecology
        case "disposal": return fluid.disposal
        case "transport": return fluid.transport
        case "regulation": return fluid.regulation
        case "other": return fluid.other
        default: return nil
        }
    }
    
    func getContentForSection(_ section: SDSSection) -> String? {
        switch section.id {
        case "1": return fluid.identification
        case "2": return fluid.hazards
        case "3": return fluid.composition
        case "4": return fluid.firstAid
        case "5": return fluid.fire
        case "6": return fluid.accident
        case "7": return fluid.handling
        case "8": return fluid.exposure
        case "9": return fluid.properties
        case "10": return fluid.stability
        case "11": return fluid.toxicology
        case "12": return fluid.ecology
        case "13": return fluid.disposal
        case "14": return fluid.transport
        case "15": return fluid.regulation
        case "16": return fluid.other
        default: return nil
        }
    }
    
    func getSectionsWithContent() -> [(section: SDSSection, content: String?)] {
        SDSSection.allSections.map { section in
            (section: section, content: getContentForSection(section))
        }
    }
    
    func getDatabaseField(for sectionTitle: String) -> String? {
        SDSSection.databaseFields[sectionTitle]
    }
    
    func saveSectionChanges(section: String) {
        print("💾 Starting save process for section: \(section)")
        
        guard let field = SDSSection.databaseFields[section],
              let newValue = editedValues[field] else {
            print("❌ No changes to save or invalid field")
            return
        }
        
        // Skip empty values to avoid overwriting with empty strings
        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️ Empty value, skipping save")
            editingSection = nil
            editedValues.removeAll()
            return
        }
        
        // Create updates dictionary
        let updates = [field: newValue]
        
        // Attempt to save the changes
        if DatabaseManager.shared.updateFluid(fluidName: fluid.name, updates: updates) {
            print("✅ Save successful for section: \(section)")
            editingSection = nil
            editedValues.removeAll()
            
            // Post notification to refresh the fluids list
            NotificationCenter.default.post(name: NSNotification.Name("FluidsChanged"), object: nil)
            // Force cache update
            print("🔄 Forcing cache update after SDS section save...")
            DatabaseManager.shared.updateFluidsCache(force: true)
        } else {
            print("❌ Save failed for section: \(section)")
            errorMessage = "Failed to save changes to database"
            showError = true
        }
    }
    
    // Add a computed property for full SDS sections
    var fullSDSSections: [(title: String, content: String?, icon: String)] {
        [
            ("1. Identification", fluid.identification, "doc.text.fill"),
            ("2. Hazards Identification", fluid.hazards, "exclamationmark.triangle.fill"),
            ("3. Composition/Information on Ingredients", fluid.composition, "list.bullet.clipboard.fill"),
            ("4. First-Aid Measures", fluid.firstAid, "cross.case.fill"),
            ("5. Fire-Fighting Measures", fluid.fire, "flame.fill"),
            ("6. Accidental Release Measures", fluid.accident, "exclamationmark.triangle.fill"),
            ("7. Handling and Storage", fluid.handling, "hand.raised.fill"),
            ("8. Exposure Controls/Personal Protection", fluid.exposure, "person.fill.checkmark"),
            ("9. Physical and Chemical Properties", fluid.properties, "atom"),
            ("10. Stability and Reactivity", fluid.stability, "bolt.shield.fill"),
            ("11. Toxicological Information", fluid.toxicology, "pills.fill"),
            ("12. Ecological Information", fluid.ecology, "leaf.fill"),
            ("13. Disposal Considerations", fluid.disposal, "trash.fill"),
            ("14. Transport Information", fluid.transport, "truck.box.fill"),
            ("15. Regulatory Information", fluid.regulation, "checkmark.seal.fill"),
            ("16. Other Information", fluid.other, "ellipsis.circle.fill")
        ]
    }
    
    func getPropertyNameForSection(_ section: SDSSection) -> String {
        switch section.id {
        case "1": return "identification"
        case "2": return "hazards"
        case "3": return "composition"
        case "4": return "firstAid"
        case "5": return "fire"
        case "6": return "accident"
        case "7": return "handling"
        case "8": return "exposure"
        case "9": return "properties"
        case "10": return "stability"
        case "11": return "toxicology"
        case "12": return "ecology"
        case "13": return "disposal"
        case "14": return "transport"
        case "15": return "regulation"
        case "16": return "other"
        default: return ""
        }
    }
}

// MARK: - Full SDS Sheet View
private struct FullSDSSheetView: View {
    let viewModel: SDSDetailViewModel
    @Binding var isPresented: Bool
    
    private func getHazardSymbols() -> [String] {
        var symbols: [String] = []
        let query = "SELECT HAZARD_GHS02, HAZARD_GHS05, HAZARD_GHS06, HAZARD_GHS07, HAZARD_GHS08, HAZARD_STOT, HAZARD_ASP FROM FLUID WHERE FLUID = '\(viewModel.fluid.name)'"
        if let result = DatabaseManager.shared.executeQuery(query) {
            if let row = result.first {
                let ghs02 = (row["HAZARD_GHS02"] as? NSNumber)?.intValue ?? 0
                let ghs05 = (row["HAZARD_GHS05"] as? NSNumber)?.intValue ?? 0
                let ghs06 = (row["HAZARD_GHS06"] as? NSNumber)?.intValue ?? 0
                let ghs07 = (row["HAZARD_GHS07"] as? NSNumber)?.intValue ?? 0
                let ghs08 = (row["HAZARD_GHS08"] as? NSNumber)?.intValue ?? 0
                let stot = (row["HAZARD_STOT"] as? NSNumber)?.intValue ?? 0
                let asp = (row["HAZARD_ASP"] as? NSNumber)?.intValue ?? 0
                
                if ghs02 == 1 { symbols.append("GHS02") }
                if ghs05 == 1 { symbols.append("GHS05") }
                if ghs06 == 1 { symbols.append("GHS06") }
                if ghs07 == 1 { symbols.append("GHS07") }
                if ghs08 == 1 { symbols.append("GHS08") }
                if stot == 1 { symbols.append("GHS08") }
                if asp == 1 { symbols.append("GHS08") }
            }
        }
        return symbols
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                // Header
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    Text("SAFETY DATA SHEET")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppStyle.textColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                    
                    // Product Info Card
                    ProductInfoCard(fluid: viewModel.fluid)
                }
                .padding(.horizontal)
                
                // All Sections with Hazard Symbols between 1 and 2
                ForEach(Array(viewModel.fullSDSSections.enumerated()), id: \.element.title) { index, section in
                    VStack(spacing: AppStyle.Spacing.medium) {
                        // Show the section
                        SDSSectionCard(title: section.title, content: section.content, icon: section.icon)
                        
                        // Add hazard symbols after section 1
                        if index == 0 {
                            let symbols = getHazardSymbols()
                            if !symbols.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Hazard Symbols")
                                        .font(.headline)
                                        .foregroundColor(AppStyle.textColor)
                                        .padding(.horizontal)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(symbols, id: \.self) { symbol in
                                            Image(symbol)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                // Footer
                FooterCard(fluid: viewModel.fluid)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Views
private struct ProductInfoCard: View {
    let fluid: Fluid
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fluid.name)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(AppStyle.textColor)
            
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Manufacturer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "building.2")
                            .foregroundColor(AppStyle.primaryColor)
                    }
                    
                    Text(fluid.manufacturer)
                        .font(.body)
                        .foregroundColor(AppStyle.textColor)
                }
                
                if let emergencyContact = fluid.emergencyContact {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Emergency")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "phone.circle.fill")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            if let url = URL(string: "tel:\(emergencyContact.replacingOccurrences(of: "-", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(emergencyContact)
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

private struct SDSSectionCard: View {
    let title: String
    let content: String?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppStyle.primaryColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppStyle.textColor)
            }
            .padding(.bottom, 4)
            
            // Section Content
            if let content = content, !content.isEmpty {
                Text(content)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(AppStyle.textColor)
                    .lineSpacing(4)
            } else {
                Text("No information available")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
}

private struct FooterCard: View {
    let fluid: Fluid
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppStyle.primaryColor)
                
                Text("Additional Information")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppStyle.textColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let date = fluid.date {
                    Label {
                        Text(date)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(AppStyle.textColor)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(AppStyle.primaryColor)
                    }
                }
                
                if let filename = fluid.filename {
                    Label {
                        Text(filename)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(AppStyle.textColor)
                    } icon: {
                        Image(systemName: "doc.fill")
                            .foregroundColor(AppStyle.primaryColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// MARK: - SDS Header View
private struct SDSHeaderView: View {
    let fluid: Fluid
    let onViewFullSDSTapped: () -> Void
    
    private func getHazardSymbols() -> [String] {
        var symbols: [String] = []
        let query = "SELECT HAZARD_GHS02, HAZARD_GHS05, HAZARD_GHS06, HAZARD_GHS07, HAZARD_GHS08, HAZARD_STOT, HAZARD_ASP FROM FLUID WHERE FLUID = '\(fluid.name)'"
        if let result = DatabaseManager.shared.executeQuery(query) {
            if let row = result.first {
                let ghs02 = (row["HAZARD_GHS02"] as? NSNumber)?.intValue ?? 0
                let ghs05 = (row["HAZARD_GHS05"] as? NSNumber)?.intValue ?? 0
                let ghs06 = (row["HAZARD_GHS06"] as? NSNumber)?.intValue ?? 0
                let ghs07 = (row["HAZARD_GHS07"] as? NSNumber)?.intValue ?? 0
                let ghs08 = (row["HAZARD_GHS08"] as? NSNumber)?.intValue ?? 0
                let stot = (row["HAZARD_STOT"] as? NSNumber)?.intValue ?? 0
                let asp = (row["HAZARD_ASP"] as? NSNumber)?.intValue ?? 0
                
                if ghs02 == 1 { symbols.append("GHS02") }
                if ghs05 == 1 { symbols.append("GHS05") }
                if ghs06 == 1 { symbols.append("GHS06") }
                if ghs07 == 1 { symbols.append("GHS07") }
                if ghs08 == 1 { symbols.append("GHS08") }
                if stot == 1 { symbols.append("GHS08") }
                if asp == 1 { symbols.append("GHS08") }
            }
        }
        return symbols
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SAFETY DATA SHEET")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2)
            
            // Product Info Section
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "Product Name", value: fluid.name)
                InfoRow(label: "Manufacturer", value: fluid.manufacturer)
            }
            .padding(.bottom, 4)
            
            // Hazard Symbols
            let symbols = getHazardSymbols()
            if !symbols.isEmpty {
                HStack(spacing: 8) {
                    ForEach(symbols, id: \.self) { symbol in
                        Image(symbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)
            }
            
            // Emergency Contact Section
            if let emergencyContact = fluid.emergencyContact {
                EmergencyContactButton(contact: emergencyContact)
            }
            
            // View Full SDS Button
            ViewFullSDSButton(action: onViewFullSDSTapped)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .cardStyle()
    }
}

private struct EmergencyContactButton: View {
    let contact: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "tel:\(contact.replacingOccurrences(of: "-", with: ""))") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: "phone.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Emergency Contact")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(contact)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: "phone.arrow.up.right")
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ViewFullSDSButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(AppStyle.primaryColor)
                Text("View Entire SDS")
                    .font(.headline)
                    .foregroundColor(AppStyle.primaryColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppStyle.primaryColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
    }
}

// MARK: - SDS Footer View
private struct SDSFooterView: View {
    let fluid: Fluid
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            InfoRow(label: "Date", value: fluid.date)
            InfoRow(label: "File Name", value: fluid.filename)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .cardStyle()
    }
}

// MARK: - SDS Sections List View
private struct SDSSectionsListView: View {
    let sections: [(section: SDSSection, content: String?)]
    let onSave: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(sections, id: \.section.id) { item in
                SDSSectionView(
                    section: item.section,
                    content: item.content,
                    onSave: { newContent in
                        onSave(item.section.title, newContent)
                    }
                )
            }
        }
    }
}

// MARK: - Main SDS Detail View
struct SDSDetailView: View {
    @StateObject private var viewModel: SDSDetailViewModel
    @State private var showFullSDS = false
    @State private var selectedSection: (title: String, content: String?)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(fluid: Fluid) {
        _viewModel = StateObject(wrappedValue: SDSDetailViewModel(fluid: fluid))
        print("🔍 Initializing SDSDetailView for fluid: \(fluid.name)")
    }
    
    private func refreshData() {
        print("🔄 Refreshing SDS detail view data...")
        // Force a cache update first to ensure we have the latest data
        DatabaseManager.shared.updateFluidsCache(force: true)
        
        // Get fresh data from the database
        if let cached = DatabaseManager.shared.getCachedFluids() {
            if let updatedFluid = cached.fluids.first(where: { $0.name == viewModel.fluid.name }) {
                print("📦 Updating view model with fresh data for fluid: \(updatedFluid.name)")
                // Update the view model with the fresh data
                viewModel.updateFluid(updatedFluid)
            } else {
                print("⚠️ Could not find updated fluid in cache: \(viewModel.fluid.name)")
            }
        } else {
            print("❌ Failed to get cached fluids during refresh")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // Header Section
                SDSHeaderView(
                    fluid: viewModel.fluid,
                    onViewFullSDSTapped: { showFullSDS = true }
                )
                
                // Required SDS Sections
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.getSectionsWithContent(), id: \.section.id) { item in
                        Button {
                            selectedSection = (item.section.title, item.content)
                        } label: {
                            HStack {
                                Image(systemName: item.section.icon)
                                    .foregroundColor(AppStyle.primaryColor)
                                Text(item.section.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                
                // Footer Section with Hazard Symbols
                FooterCard(fluid: viewModel.fluid)
                    .onAppear {
                        print("📱 FooterCard appeared for fluid: \(viewModel.fluid.name)")
                    }
            }
            .padding(.vertical, 4)
        }
        .navigationBarTitle("SDS Details", displayMode: .inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .fullScreenCover(isPresented: $showFullSDS) {
            NavigationStack {
                FullSDSSheetView(viewModel: viewModel, isPresented: $showFullSDS)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showFullSDS = false
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(AppStyle.primaryColor)
                            }
                        }
                    }
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedSection.map { SectionItem(title: $0.title, content: $0.content) } },
            set: { selectedSection = $0.map { ($0.title, $0.content) } }
        )) { section in
            NavigationStack {
                SDSSectionDetailView(
                    title: section.title,
                    content: section.content,
                    onSave: { newContent in
                        // Get the section ID from the title
                        if let sectionId = section.title.split(separator: ".").first?.trimmingCharacters(in: .whitespaces),
                           let section = SDSSection.allSections.first(where: { $0.id == sectionId }) {
                            // Get the Fluid property name for this section
                            let propertyName = viewModel.getPropertyNameForSection(section)
                            // Get the database field name
                            if let dbField = SDSSection.databaseFields[propertyName] {
                                // Create updates dictionary
                                let updates = [dbField: newContent]
                                
                                // Attempt to save the changes
                                if DatabaseManager.shared.updateFluid(fluidName: viewModel.fluid.name, updates: updates) {
                                    // Post notification to refresh the fluids list
                                    NotificationCenter.default.post(name: NSNotification.Name("FluidsChanged"), object: nil)
                                    // Force cache update
                                    DatabaseManager.shared.updateFluidsCache(force: true)
                                } else {
                                    viewModel.errorMessage = "Failed to save changes. Please try again."
                                    viewModel.showError = true
                                }
                            }
                        }
                        selectedSection = nil
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            selectedSection = nil
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(AppStyle.primaryColor)
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FluidsChanged"))) { _ in
            print("📢 Received FluidsChanged notification in SDS detail view")
            refreshData()
        }
    }
}

// Add a struct to conform to Identifiable for the fullScreenCover
private struct SectionItem: Identifiable {
    let id = UUID()
    let title: String
    let content: String?
}

// MARK: - SDS Section Components
private struct SDSSectionHeader: View {
    let section: SDSSection
    let isEditing: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    let onEditTapped: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundColor(AppStyle.primaryColor)
            Text(section.title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            
            if isEditing {
                HStack(spacing: 16) {
                    Button("Save") {
                        onSave()
                    }
                    .foregroundColor(AppStyle.primaryColor)
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                }
            } else {
                Button(action: onEditTapped) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppStyle.primaryColor)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - SDS Section Content Components
private struct SDSSectionEditor: View {
    let editedValue: String
    let onEdit: (String) -> Void
    
    var body: some View {
        TextEditor(text: Binding(
            get: { editedValue },
            set: { onEdit($0) }
        ))
        .frame(minHeight: 200)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - SDS Section Viewer
private struct SDSSectionViewer: View {
    let section: SDSSection
    let content: String?
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationLink(destination: SDSSectionDetailView(
            title: section.title,
            content: content,
            onSave: onSave
        )) {
            HStack {
                Text(section.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SDS Section View
private struct SDSSectionView: View {
    let section: SDSSection
    let content: String?
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationLink {
            SDSSectionDetailView(
                title: section.title,
                content: content,
                onSave: onSave
            )
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack {
                Image(systemName: section.icon)
                    .foregroundColor(AppStyle.primaryColor)
                Text(section.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// Helper view for displaying info rows
private struct InfoRow: View {
    let label: String
    let value: String?
    
    var body: some View {
        if let value = value, !value.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    NavigationView {
        SDSDetailView(
            fluid: Fluid(from: [
                "UNIQUE_ID": Int64(1),
                "FLUID": "Example Fluid",
                "MANUFACTURER": "Example Manufacturer",
                "EMERGENCY_CONTACT": "1-800-EMERGENCY",
                "DATE": "2024-03-20",
                "FILENAME": "example_fluid_sds.pdf",
                "IDENTIFICATION": "Product identification information...",
                "HAZARDS": "Hazard identification information...",
                "COMPOSITION": "Composition information...",
                "FIRSTAID": "First aid measures...",
                "FIRE": "Fire fighting measures...",
                "ACCIDENT": "Accidental release measures...",
                "HANDLING": "Handling and storage information...",
                "EXPOSURE": "Exposure controls and personal protection...",
                "PROPERTIES": "Physical and chemical properties...",
                "STABILITY": "Stability and reactivity information...",
                "TOXICOLOGY": "Toxicological information...",
                "ECOLOGY": "Ecological information...",
                "DISPOSAL": "Disposal considerations...",
                "TRANSPORT": "Transport information...",
                "REGULATION": "Regulatory information...",
                "OTHER": "Other information...",
                "INDEX": 28.0,
                "USE": "General Purpose",
                "TYPE": "Vascular"
            ])!
        )
    }
}

