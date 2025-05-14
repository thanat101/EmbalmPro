import Foundation

/// Represents a section in a Safety Data Sheet (SDS)
public struct SDSSection: Identifiable {
    /// Unique identifier for the section
    public let id: String
    
    /// Title of the section (e.g., "1. Identification")
    public let title: String
    
    /// Content of the section, if any
    public let content: String?
    
    /// SF Symbol name for the section's icon
    public let icon: String
    
    /// Database field mappings for all SDS sections
    public static let databaseFields: [String: String] = [
        // Identification Header
        "name": "FLUID",
        "manufacturer": "MANUFACTURER",
        "emergencyContact": "EMERGENCY_CONTACT",
        "date": "DATE",
        "filename": "FILENAME",
        
        // Required SDS Sections
        "identification": "IDENTIFICATION",
        "hazards": "HAZARDS",
        "composition": "COMPOSITION",
        "firstAid": "FIRSTAID",
        "fire": "FIRE",
        "accident": "ACCIDENT",
        "handling": "HANDLING",
        "exposure": "EXPOSURE",
        "properties": "PROPERTIES",
        "stability": "STABILITY",
        "toxicology": "TOXICOLOGY",
        "ecology": "ECOLOGY",
        "disposal": "DISPOSAL",
        "transport": "TRANSPORT",
        "regulation": "REGULATION",
        "other": "OTHER"
    ]
    
    /// Creates a new SDS section
    /// - Parameters:
    ///   - id: Unique identifier for the section
    ///   - title: Title of the section
    ///   - content: Content of the section, if any
    ///   - icon: SF Symbol name for the section's icon
    public init(id: String, title: String, content: String?, icon: String) {
        self.id = id
        self.title = title
        self.content = content
        self.icon = icon
    }
    
    /// All available SDS sections in order
    public static let allSections: [SDSSection] = [
        SDSSection(id: "1", title: "1. Identification", content: nil, icon: "doc.text.fill"),
        SDSSection(id: "2", title: "2. Hazards Identification", content: nil, icon: "exclamationmark.triangle.fill"),
        SDSSection(id: "3", title: "3. Composition/Information on Ingredients", content: nil, icon: "list.bullet.clipboard.fill"),
        SDSSection(id: "4", title: "4. First-Aid Measures", content: nil, icon: "cross.case.fill"),
        SDSSection(id: "5", title: "5. Fire-Fighting Measures", content: nil, icon: "flame.fill"),
        SDSSection(id: "6", title: "6. Accidental Release Measures", content: nil, icon: "exclamationmark.triangle.fill"),
        SDSSection(id: "7", title: "7. Handling and Storage", content: nil, icon: "hand.raised.fill"),
        SDSSection(id: "8", title: "8. Exposure Controls/Personal Protection", content: nil, icon: "person.fill.checkmark"),
        SDSSection(id: "9", title: "9. Physical and Chemical Properties", content: nil, icon: "atom"),
        SDSSection(id: "10", title: "10. Stability and Reactivity", content: nil, icon: "bolt.shield.fill"),
        SDSSection(id: "11", title: "11. Toxicological Information", content: nil, icon: "pills.fill"),
        SDSSection(id: "12", title: "12. Ecological Information", content: nil, icon: "leaf.fill"),
        SDSSection(id: "13", title: "13. Disposal Considerations", content: nil, icon: "trash.fill"),
        SDSSection(id: "14", title: "14. Transport Information", content: nil, icon: "truck.box.fill"),
        SDSSection(id: "15", title: "15. Regulatory Information", content: nil, icon: "checkmark.seal.fill"),
        SDSSection(id: "16", title: "16. Other Information", content: nil, icon: "ellipsis.circle.fill")
    ]
} 