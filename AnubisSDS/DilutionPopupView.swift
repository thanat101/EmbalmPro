import SwiftUI

struct DilutionPopupView: View {
    let fluidIndex: String
    let conditionStrength: String?
    let fluidName: String
    @Environment(\.dismiss) private var dismiss
    
    // Predefined solution strengths
    let strengths = [
        ("Mild", "1.7"),
        ("Normal", "2.0"),
        ("Strong", "2.5"),
        ("High", "3.0"),
        ("Very High", "3.5")
    ]
    
    // Calculate dilution for a given strength
    func calculateDilution(strength: String) -> (primary: Double, water: Double, total: Double)? {
        guard let index = Double(fluidIndex),
              let strengthValue = Double(strength) else {
            return nil
        }
        
        let total = 128.0 // Total solution is now 128 ounces
        let primary = (strengthValue * total) / index
        let water = total - primary
        
        return (primary, water, total)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(fluidName) Dilution Calculations")
                        .font(.title2)
                        .bold()
                        .foregroundColor(AppStyle.primaryColor)
                    
                    Text("Fluid Index: \(fluidIndex)")
                        .font(.headline)
                    
                    if let conditionStrength = conditionStrength {
                        Text("Condition Strength: \(conditionStrength)%")
                            .font(.headline)
                    }
                    
                    ForEach(strengths, id: \.0) { strength in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(strength.0) (\(strength.1)%)")
                                .font(.headline)
                            
                            if let dilution = calculateDilution(strength: strength.1) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Vascular Fluid:")
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(String(format: "%.1f", dilution.primary)) oz")
                                            .bold()
                                    }
                                    
                                    HStack {
                                        Text("Supplemental/Accessory Fluids and Water:")
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(String(format: "%.1f", dilution.water)) oz")
                                            .bold()
                                    }
                                    
                                    HStack {
                                        Text("Total Solution (1 gallon):")
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(String(format: "%.1f", dilution.total)) oz")
                                            .bold()
                                    }
                                }
                            } else {
                                Text("Unable to calculate")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DilutionPopupView(
        fluidIndex: "2.5",
        conditionStrength: "2.5",
        fluidName: "Test Fluid"
    )
}
