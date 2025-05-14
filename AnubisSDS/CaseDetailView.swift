import SwiftUI

// MARK: - Case Detail View
struct CaseDetailView: View {
    let condition: [String]
    let headers: [String]
    @State private var relatedFluids: [(fluid: [String], reasons: [String])] = []
    @State private var selectedIndex: Double?
    @Environment(\.dismiss) private var dismiss
    
    // Cache the fluids data
    private static var cachedFluidsData: [[String]] = []
    private static var cachedFluidsHeaders: [String] = []
    
    // Predefined index options
    let indexOptions: [Double] = [18, 20, 25, 28, 30, 35]
    
    // Calculate dilution for a given index
    func calculateDilution(index: Double) -> (primary: Double, water: Double, total: Double)? {
        guard let strengthPercentIndex = headers.firstIndex(of: "STRENGTH (%)"),
              let strengthValue = Double(condition[safe: strengthPercentIndex] ?? "") else {
            return nil
        }
        
        let total = 128.0 // Fixed total volume of 128 ounces
        let primary = (strengthValue * total) / index
        let water = total - primary
        
        return (primary, water, total)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                // Condition name header
                VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                    Text("CASE ANALYSIS")
                        .font(AppStyle.Typography.caption)
                        .foregroundColor(AppStyle.secondaryTextColor)
                    Text(getValue(for: "CASE TYPE"))
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                }
                .padding(.bottom, AppStyle.Spacing.medium)
                .cardStyle()
                
                // Condition details
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    Text("Case Analysis Details")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.bottom, AppStyle.Spacing.small)
                    
                    ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                        if index < condition.count {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(header)
                                    .font(AppStyle.Typography.subheadline)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                                
                                Text(condition[index])
                                    .font(AppStyle.Typography.body)
                                    .foregroundColor(AppStyle.textColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Dilution section integrated into condition details
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CALCULATE DILUTION")
                            .font(AppStyle.Typography.subheadline)
                            .foregroundColor(AppStyle.secondaryTextColor)
                        
                        Text("Select Index")
                            .font(AppStyle.Typography.caption)
                            .foregroundColor(AppStyle.secondaryTextColor)
                            .padding(.bottom, 4)
                        
                        // Compact index selection
                        HStack(spacing: 8) {
                            ForEach(indexOptions, id: \.self) { index in
                                Text("\(Int(index))")
                                    .font(AppStyle.Typography.body)
                                    .foregroundColor(selectedIndex == index ? .white : AppStyle.textColor)
                                    .frame(width: 32, height: 32)
                                    .background(selectedIndex == index ? AppStyle.primaryColor : Color(.systemGray5))
                                    .cornerRadius(16)
                                    .onTapGesture {
                                        selectedIndex = index
                                    }
                            }
                        }
                        
                        // Results section
                        if let index = selectedIndex,
                           let dilution = calculateDilution(index: index) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Vascular Fluid:")
                                        .foregroundColor(AppStyle.secondaryTextColor)
                                    Spacer()
                                    Text("\(String(format: "%.1f", dilution.primary)) oz")
                                        .bold()
                                }
                                
                                HStack {
                                    Text("Water/Supplemental Fluids:")
                                        .foregroundColor(AppStyle.secondaryTextColor)
                                    Spacer()
                                    Text("\(String(format: "%.1f", dilution.water)) oz")
                                        .bold()
                                }
                                
                                HStack {
                                    Text("Total Solution (1 Gallon):")
                                        .foregroundColor(AppStyle.secondaryTextColor)
                                    Spacer()
                                    Text("\(String(format: "%.1f", dilution.total)) oz")
                                        .bold()
                                }
                                
                                Text("If the Suggested Use Fluids (below) is used to calculate dilution, it will also determine total amount of embalming solution needed based on a person's weight.")
                                    .font(AppStyle.Typography.caption)
                                    .foregroundColor(AppStyle.secondaryTextColor)
                                    .padding(.top, 4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .cardStyle()
                
                // Suggested Use Fluids section
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    Text("Suggested Use Fluids")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.bottom, AppStyle.Spacing.small)
                    
                    if relatedFluids.isEmpty {
                        Text("No suggested fluids found")
                            .font(AppStyle.Typography.body)
                            .foregroundColor(AppStyle.secondaryTextColor)
                            .padding(.top, AppStyle.Spacing.small)
                    } else {
                        let conditionStrengthPercentIndex = headers.firstIndex(of: "STRENGTH (%)") ?? 0
                        let strengthPercentValue = condition[safe: conditionStrengthPercentIndex]?.trimmingCharacters(in: .whitespaces) ?? ""
                        let fluidNameIndex = Self.cachedFluidsHeaders.firstIndex(of: "FLUID") ?? 0
                        let fluidIndexIndex = Self.cachedFluidsHeaders.firstIndex(of: "INDEX") ?? 0
                        
                        ForEach(relatedFluids, id: \.fluid) { fluidData in
                            let fluidName = fluidData.fluid[safe: fluidNameIndex] ?? "Unknown Fluid"
                            let fluidIndex = fluidData.fluid[safe: fluidIndexIndex] ?? ""
                            VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                                HStack {
                                    Text(fluidName)
                                        .font(AppStyle.Typography.headline)
                                        .foregroundColor(AppStyle.primaryColor)
                                        
                                    Spacer()
                                    
                                    // Direct calculation button
                                    NavigationLink {
                                        CH2OView(
                                            initialStrengthPercent: strengthPercentValue,
                                            initialFluidIndex: fluidIndex,
                                            initialFluidName: fluidName,
                                            initialConditionName: getValue(for: "CASE TYPE")
                                        )
                                        .navigationBarTitleDisplayMode(.inline)
                                        .navigationTitle("CH₂O Calculator")
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "drop.fill")
                                                .font(.system(size: 16))
                                            Text("Fluid Needed")
                                                .font(AppStyle.Typography.body)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppStyle.primaryColor)
                                        .cornerRadius(AppStyle.CornerRadius.medium)
                                    }
                                    
                                    // Simple arrow link to FluidDetailView
                                    NavigationLink(destination: FluidDetailView(
                                        row: fluidData.fluid,
                                        headers: Self.cachedFluidsHeaders,
                                        conditionStrength: strengthPercentValue
                                    )) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppStyle.secondaryTextColor)
                                    }
                                }
                                
                                // Matching reasons
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Matches:")
                                        .font(AppStyle.Typography.subheadline)
                                        .foregroundColor(AppStyle.secondaryTextColor)
                                    
                                    ForEach(fluidData.reasons, id: \.self) { reason in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppStyle.primaryColor)
                                                .font(.system(size: 12))
                                            Text(reason)
                                                .font(AppStyle.Typography.caption)
                                                .foregroundColor(AppStyle.textColor)
                                        }
                                    }
                                }
                                .padding(.leading, AppStyle.Spacing.medium)
                            }
                            .padding(.vertical, AppStyle.Spacing.small)
                            .cardStyle()
                        }
                    }
                }
                .cardStyle()
            }
            .padding(AppStyle.Spacing.medium)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Case Details")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("ResetNavigation"), object: nil)
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(AppStyle.primaryColor)
                }
            }
        }
        .onAppear {
            loadFluidsData()
            findMatchingFluids()
        }
    }
    
    // Helper function to get value from condition array
    private func getValue(for field: String) -> String {
        if let index = headers.firstIndex(of: field), index < condition.count {
            return condition[index]
        }
        return ""
    }
    
    // Load fluids data from database
    private func loadFluidsData() {
        if Self.cachedFluidsData.isEmpty {
            print("\nLoading fluids data from database...")
            let query = """
                SELECT * FROM FLUID 
                ORDER BY FLUID ASC
            """
            
            if let results = DatabaseManager.shared.executeQuery(query) {
                print("Raw query returned \(results.count) results")
                
                if !results.isEmpty {
                    // Get headers from the first result
                    Self.cachedFluidsHeaders = Array(results[0].keys).sorted()
                    print("Fluid headers: \(Self.cachedFluidsHeaders.joined(separator: ", "))")
                    
                    // Convert results to rows
                    Self.cachedFluidsData = results.map { dict in
                        Self.cachedFluidsHeaders.map { header in
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
                    
                    print("Loaded \(Self.cachedFluidsData.count) fluid rows")
                    // Print first few fluid names for debugging
                    print("\nFirst 5 fluid names:")
                    for (index, row) in Self.cachedFluidsData.prefix(5).enumerated() {
                        if let nameIndex = Self.cachedFluidsHeaders.firstIndex(of: "FLUID") {
                            print("\(index + 1). \(row[nameIndex])")
                        }
                    }
                }
            }
        }
    }
    
    // Find matching fluids based on condition criteria
    private func findMatchingFluids() {
        print("\nFinding matching fluids...")
        print("Condition headers: \(headers.joined(separator: ", "))")
        
        // Pre-compute indices for better performance
        let fluidIndexIndex = Self.cachedFluidsHeaders.firstIndex(of: "INDEX") ?? 0
        let conditionIndexIndex = headers.firstIndex(of: "CH2O INDEX") ?? 0
        
        // Fluid field indices
        let fluidFirmingSpeedIndex = Self.cachedFluidsHeaders.firstIndex(of: "FIRMING_SPEED") ?? 0
        let fluidHumectantIndex = Self.cachedFluidsHeaders.firstIndex(of: "HUMECTANT") ?? 0
        let fluidTypeIndex = Self.cachedFluidsHeaders.firstIndex(of: "TYPE") ?? 0
        let fluidUseIndex = Self.cachedFluidsHeaders.firstIndex(of: "SPECIAL_TREATMENT") ?? 0
        let fluidSecondUseIndex = Self.cachedFluidsHeaders.firstIndex(of: "SECOND_USE") ?? 0
        
        // Condition field indices
        let conditionCaseTypeIndex = headers.firstIndex(of: "CASE TYPE") ?? 0
        let conditionStrengthIndex = headers.firstIndex(of: "SOLUTION STRENGTH") ?? 0
        let conditionStrengthPercentIndex = headers.firstIndex(of: "STRENGTH (%)") ?? 0
        let conditionUseIndex = headers.firstIndex(of: "SPECIAL TREATMENT") ?? 0
        let conditionOtherUseIndex = headers.firstIndex(of: "SUGGESTED ACCESSORY/SUPPLIMENTAL") ?? 0
        
        // Get condition values once
        let conditionIndex = condition[safe: conditionIndexIndex]
        let conditionCaseType = condition[safe: conditionCaseTypeIndex]?.trimmingCharacters(in: .whitespaces)
        let conditionStrength = condition[safe: conditionStrengthIndex]?.trimmingCharacters(in: .whitespaces)
        let conditionStrengthPercent = condition[safe: conditionStrengthPercentIndex]?.trimmingCharacters(in: .whitespaces)
        let conditionUse = condition[safe: conditionUseIndex]?.trimmingCharacters(in: .whitespaces)
        let conditionOtherUse = condition[safe: conditionOtherUseIndex]?.trimmingCharacters(in: .whitespaces)
        
        print("\nDebug - Condition Values:")
        print("Condition Index: \(conditionIndex ?? "nil")")
        print("Case Type: \(conditionCaseType ?? "nil")")
        print("Solution Strength: \(conditionStrength ?? "nil")")
        print("Strength %: \(conditionStrengthPercent ?? "nil")")
        print("SPECIAL TREATMENT: \(conditionUse ?? "nil")")
        print("Suggested Accessory/Supplimental: \(conditionOtherUse ?? "nil")")
        
        // Helper function to check if any fluid field contains the condition value
        func containsMatch(fluidValue: String?, conditionValue: String?, fieldName: String) -> (Bool, String?) {
            guard let rawFluidValue = fluidValue,
                  let rawConditionValue = conditionValue,
                  !rawFluidValue.isEmpty,
                  !rawConditionValue.isEmpty else {
                return (false, nil)
            }
            
            let processedFluidValue = rawFluidValue.trimmingCharacters(in: .whitespaces).lowercased()
            let processedConditionValue = rawConditionValue.trimmingCharacters(in: .whitespaces).lowercased()
            
            guard !processedFluidValue.isEmpty, !processedConditionValue.isEmpty else {
                return (false, nil)
            }
            
            print("Comparing for \(fieldName):")
            print("- Fluid: '\(processedFluidValue)'")
            print("- Condition: '\(processedConditionValue)'")
            
            if processedFluidValue == processedConditionValue {
                return (true, "Exact match for \(fieldName)")
            }
            
            if processedFluidValue.contains(processedConditionValue) {
                return (true, "\(fieldName) contains condition value")
            }
            
            if processedConditionValue.contains(processedFluidValue) {
                return (true, "Condition contains \(fieldName) value")
            }
            
            return (false, nil)
        }
        
        // Helper function to parse range and check if value falls within it
        func isValueInRange(_ value: String?, range: String?) -> (Bool, String?) {
            guard let value = value?.trimmingCharacters(in: .whitespaces),
                  let range = range?.trimmingCharacters(in: .whitespaces) else {
                return (false, nil)
            }
            
            let numbers = range.components(separatedBy: CharacterSet(charactersIn: "<>"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .compactMap { Double($0) }
            
            guard numbers.count == 2,
                  let valueNum = Double(value) else {
                return (false, nil)
            }
            
            let minValue = numbers[0]
            let maxValue = numbers[1]
            
            if valueNum >= minValue && valueNum <= maxValue {
                return (true, "CH2O INDEX (\(value)) is within range (\(minValue) - \(maxValue))")
            }
            
            return (false, nil)
        }
        
        // Filter fluids more efficiently
        var manufacturerCounts: [String: Int] = [:]
        relatedFluids = Self.cachedFluidsData.compactMap { fluid in
            guard fluid.count >= max(fluidIndexIndex, fluidFirmingSpeedIndex, fluidHumectantIndex, fluidTypeIndex, fluidUseIndex, fluidSecondUseIndex) else {
                print("Warning: Fluid data row has insufficient columns")
                return nil
            }
            
            let fluidIndex = fluid[safe: fluidIndexIndex]
            let fluidFirmingSpeed = fluid[safe: fluidFirmingSpeedIndex]
            let fluidHumectant = fluid[safe: fluidHumectantIndex]
            let fluidType = fluid[safe: fluidTypeIndex]
            let fluidUse = fluid[safe: fluidUseIndex]
            let fluidSecondUse = fluid[safe: fluidSecondUseIndex]
            let fluidManufacturer = fluid[safe: Self.cachedFluidsHeaders.firstIndex(of: "MANUFACTURER") ?? 0]?.trimmingCharacters(in: .whitespaces)
            
            guard let type = fluidType?.trimmingCharacters(in: .whitespaces),
                  !type.isEmpty else {
                print("Warning: Fluid has no type specified")
                return nil
            }
            
            let isVascularFluid = type.lowercased().contains("vascular")
            guard isVascularFluid else {
                return nil
            }
            
            if let manufacturer = fluidManufacturer {
                let count = manufacturerCounts[manufacturer] ?? 0
                if count >= 3 {
                    return nil
                }
            }
            
            var matchReasons: [String] = []
            
            let (indexMatch, indexReason) = isValueInRange(fluidIndex, range: conditionIndex)
            if indexMatch, let reason = indexReason {
                matchReasons.append(reason)
            }
            
            let fieldMatches = [
                (fluidFirmingSpeed, conditionCaseType, "Firming Speed"),
                (fluidHumectant, conditionStrength, "Humectant"),
                (fluidUse, conditionUse, "SPECIAL TREATMENT"),
                (fluidSecondUse, conditionOtherUse, "Second Use")
            ]
            
            for (value1, value2, fieldName) in fieldMatches {
                let (matched, reason) = containsMatch(fluidValue: value1, conditionValue: value2, fieldName: fieldName)
                if matched, let matchReason = reason {
                    matchReasons.append(matchReason)
                }
            }
            
            if !matchReasons.isEmpty {
                matchReasons.append("Contains Vascular in fluid type")
                if let manufacturer = fluidManufacturer {
                    manufacturerCounts[manufacturer, default: 0] += 1
                }
                return (fluid, matchReasons)
            }
            
            return nil
        }
        
        print("\nFound \(relatedFluids.count) matching fluids")
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationView {
        CaseDetailView(
            condition: ["Test Condition", "Detail 1", "Detail 2", "Detail 3"],
            headers: ["CASE TYPE", "DETAIL1", "DETAIL2", "DETAIL3"]
        )
    }
} 