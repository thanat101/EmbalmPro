import SwiftUI
import AudioToolbox

struct CH2OView: View {
    @StateObject private var viewModel: CH2OViewModel
    @FocusState private var focusedField: Field?
    @State private var isKeyboardVisible = false
    @State private var shouldResetNavigation = false
    
    enum Field: Hashable {
        case strength
        case volume
        case index
    }
    
    private func playFeedback() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            AudioServicesPlaySystemSound(1104)
        }
    }
    
    // Simplify the initializers by delegating to the view model
    init() {
        _viewModel = StateObject(wrappedValue: CH2OViewModel())
    }
    
    init(initialStrengthPercent: String = "") {
        _viewModel = StateObject(wrappedValue: CH2OViewModel(initialStrengthPercent: initialStrengthPercent))
    }
    
    init(initialFluidIndex: String = "") {
        _viewModel = StateObject(wrappedValue: CH2OViewModel(initialFluidIndex: initialFluidIndex))
    }
    
    init(initialStrengthPercent: String = "", initialFluidIndex: String = "", initialFluidName: String = "") {
        _viewModel = StateObject(wrappedValue: CH2OViewModel(
            initialStrengthPercent: initialStrengthPercent,
            initialFluidIndex: initialFluidIndex,
            initialFluidName: initialFluidName))
    }
    
    init(initialShowAdvanced: Bool = false,
         initialStrengthPercent: String = "",
         initialFluidIndex: String = "",
         initialFluidName: String = "",
         initialConditionName: String = "") {
        _viewModel = StateObject(wrappedValue: CH2OViewModel(
            initialStrengthPercent: initialStrengthPercent,
            initialFluidIndex: initialFluidIndex,
            initialFluidName: initialFluidName,
            initialConditionName: initialConditionName))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Body Info Section
                BodyInfoSection(viewModel: viewModel)
                
                // Calculator Input Section
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    Text("Calculate Required Fluid")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                    
                    if !viewModel.conditionName.isEmpty {
                        Text("Case Type: \(viewModel.conditionName)")
                            .font(AppStyle.Typography.subheadline)
                            .foregroundColor(AppStyle.secondaryTextColor)
                            .padding(.bottom, 4)
                    }
                    
                    if !viewModel.fluidName.isEmpty {
                        Text("Selected Fluid: \(viewModel.fluidName)")
                            .font(AppStyle.Typography.subheadline)
                            .foregroundColor(AppStyle.secondaryTextColor)
                            .padding(.bottom, 8)
                    }
                    
                    // Place all three inputs in one horizontal row
                    HStack(spacing: AppStyle.Spacing.medium) {
                        // Strength input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Strength (%)")
                                .font(AppStyle.Typography.caption)
                                .foregroundColor(AppStyle.secondaryTextColor)
                            
                            TextField("2%", text: $viewModel.desiredStrength)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(height: 40)
                                .background(Color(.systemGray6))
                                .cornerRadius(AppStyle.CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.CornerRadius.small)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: viewModel.desiredStrength) { newValue in
                                    viewModel.calculationPerformed = false
                                }
                                .focused($focusedField, equals: .strength)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Volume input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Volume (oz)")
                                .font(AppStyle.Typography.caption)
                                .foregroundColor(AppStyle.secondaryTextColor)
                            
                            TextField("128", text: $viewModel.totalVolume)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(height: 40)
                                .background(Color(.systemGray6))
                                .cornerRadius(AppStyle.CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.CornerRadius.small)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: viewModel.totalVolume) { newValue in
                                    viewModel.calculationPerformed = false
                                    // If the field is cleared, restore the default value
                                    if newValue.isEmpty {
                                        viewModel.totalVolume = "128"
                                    }
                                }
                                .focused($focusedField, equals: .volume)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Fluid index input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Index")
                                .font(AppStyle.Typography.caption)
                                .foregroundColor(AppStyle.secondaryTextColor)
                            
                            TextField("25", text: $viewModel.fluidIndex)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(height: 40)
                                .background(Color(.systemGray6))
                                .cornerRadius(AppStyle.CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.CornerRadius.small)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: viewModel.fluidIndex) { newValue in
                                    viewModel.calculationPerformed = false
                                }
                                .focused($focusedField, equals: .index)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    if viewModel.showError {
                        Text(viewModel.errorMessage)
                            .font(AppStyle.Typography.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    Button(action: {
                        playFeedback()
                        DispatchQueue.main.async {
                            viewModel.calculateAll()
                            focusedField = nil
                            // Dismiss keyboard using UIKit
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }) {
                        Text("Calculate")
                            .font(AppStyle.Typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.calculationPerformed ? Color.gray : AppStyle.primaryColor)
                            .cornerRadius(AppStyle.CornerRadius.medium)
                            .scaleEffect(viewModel.calculationPerformed ? 1.0 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.calculationPerformed)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.top, AppStyle.Spacing.small)
                }
                .padding()
                .cardStyle()
                
                // Results Section (only show when calculation is performed)
                if viewModel.calculationPerformed {
                    ResultsSection(viewModel: viewModel)
                    
                    // New Formaldehyde Calculations Section
                    FormaldehydeCalculationsSection(viewModel: viewModel)
                }
                
                // Footnotes Section
                FootnotesSection()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                // Initialize weight on appear
                viewModel.bodyWeight = String(format: "%.0f", viewModel.sliderValue)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CH₂O Calculator")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetNavigation"))) { _ in
            shouldResetNavigation = true
        }
        .id(shouldResetNavigation)
    }
}

// MARK: - Supporting View Components

// Body Info Section Component
struct BodyInfoSection: View {
    @ObservedObject var viewModel: CH2OViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack {
                Text("Body")
                    .font(AppStyle.Typography.headline)
                    .foregroundColor(AppStyle.textColor)
                
                Spacer()
                
                Text("Type:")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Picker("Body Type", selection: $viewModel.bodyPercentage) {
                    Text("High BMI").tag(15.0)
                    Text("Average").tag(16.5)
                    Text("All Muscle").tag(20.0)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.bodyPercentage) { newValue in
                    viewModel.calculateTotalSolution()
                }
            }
            
            // Weight Slider
            HStack(spacing: AppStyle.Spacing.medium) {
                Text("Weight")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Slider(value: $viewModel.sliderValue, in: 50...700, step: 1)
                    .onChange(of: viewModel.sliderValue) { newValue in
                        viewModel.bodyWeight = String(format: "%.0f", newValue)
                        viewModel.calculateTotalSolution()
                    }
                
                TextField("Enter weight", value: $viewModel.sliderValue, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: viewModel.sliderValue) { newValue in
                        viewModel.bodyWeight = String(format: "%.0f", newValue)
                        viewModel.calculateTotalSolution()
                    }
                
                Text(viewModel.weightUnit == "lb" ? "lbs" : "kg")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
            }
            
            if viewModel.weightUnit == "lb" {
                let kgValue = max(0, viewModel.sliderValue / 2.20462)
                Text("\(String(format: "%.0f", kgValue)) kg")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
            } else {
                let lbValue = max(0, viewModel.sliderValue * 2.20462)
                Text("\(String(format: "%.0f", lbValue)) lbs")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

// Results Section
struct ResultsSection: View {
    @ObservedObject var viewModel: CH2OViewModel
    
    var body: some View {
        VStack {
            // Add fluid name display
            if !viewModel.fluidName.isEmpty {
                HStack {
                    Text("Selected Fluid:")
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.secondaryTextColor)
                    Text(viewModel.fluidName)
                        .font(AppStyle.Typography.subheadline)
                        .foregroundColor(AppStyle.primaryColor)
                        .bold()
                }
                .padding(.bottom, 4)
            }
            
            // Results columns
            HStack(spacing: 0) {
                // Left Column - Industry Standard
                IndustryStandardColumn(viewModel: viewModel)
                
                // Vertical Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, AppStyle.Spacing.medium)
                
                // Right Column - Scientific Approach
                ScientificApproachColumn(viewModel: viewModel)
            }
            .padding(.top, AppStyle.Spacing.medium)
        }
        .padding(.vertical, 8)
        .cardStyle()
    }
}

// Industry Standard Column
struct IndustryStandardColumn: View {
    @ObservedObject var viewModel: CH2OViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("STD Method")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppStyle.textColor)
                .padding(.bottom, 0)
            
            // Fluid Amount Result
            VStack(alignment: .leading, spacing: 4) {
                Text("Embalming Fluid Needed per Gallon")
                    .font(.system(size: 16))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(String(format: "%.1f", viewModel.fluidAmount))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                    Text("oz")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                }
                
                if let volumeVal = Double(viewModel.totalVolume) {
                    Text("to make \(String(format: "%.0f", volumeVal)) ounces of solution")
                        .font(.system(size: 14))
                        .foregroundColor(AppStyle.secondaryTextColor)
                }
                
                // Add bottle calculation
                if viewModel.fluidAmount > 0 {
                    let bottleSize = 16.0 // 16 oz bottles
                    let bottleCount = viewModel.fluidAmount / bottleSize
                    Text("(approximately \(String(format: "%.1f", bottleCount)) 16-oz bottles)")
                        .font(.system(size: 14))
                        .foregroundColor(AppStyle.secondaryTextColor)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
            
            // Gallons Needed Calculation
            VStack(alignment: .leading, spacing: 4) {
                Text("Gallons Needed")
                    .font(.system(size: 16))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(String(format: "%.1f", viewModel.sliderValue / 50))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                    Text("gal")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                }
                
                Text("Based on standard practice of 1 gallon per 50 pounds")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.top, 2)
                
                Text("Provides baseline for solution volume requirements")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.top, 2)
                
                Text("Adjust based on case conditions and fluid characteristics")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.top, 2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.trailing, AppStyle.Spacing.medium)
    }
}

// Update Scientific Approach Column
struct ScientificApproachColumn: View {
    @ObservedObject var viewModel: CH2OViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SCI Method")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppStyle.textColor)
                .padding(.bottom, 0)
            
            // Embalming Fluid Needed per Gallon (Scientific Method)
            VStack(alignment: .leading, spacing: 4) {
                Text("Embalming Fluid Needed per Gallon (avg)")
                    .font(.system(size: 16))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                if let indexValue = Double(viewModel.fluidIndex), indexValue > 0 {
                    let formaldehydePerBottle = ((indexValue / 100) * 473.18) * 1.1
                    let bottlesNeeded = max(0, viewModel.formaldehydeDemand / formaldehydePerBottle)
                    let standardGallons = viewModel.solutionAmountStandard / 3.785  // Convert L to gallons
                    let extendedGallons = viewModel.solutionAmountExtended / 3.785  // Convert L to gallons
                    
                    // Calculate oz per gallon for both methods
                    let extendedOzPerGallon = (bottlesNeeded * 16) / extendedGallons
                    let standardOzPerGallon = (bottlesNeeded * 16) / standardGallons
                    
                    // Calculate the average
                    let averageOzPerGallon = (extendedOzPerGallon + standardOzPerGallon) / 2
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(String(format: "%.1f", averageOzPerGallon))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppStyle.primaryColor)
                        Text("oz")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppStyle.primaryColor)
                    }
                    
                    if let volumeVal = Double(viewModel.totalVolume) {
                        Text("to make \(String(format: "%.0f", volumeVal)) ounces of solution")
                            .font(.system(size: 14))
                            .foregroundColor(AppStyle.secondaryTextColor)
                    }
                    
                    // Add bottle calculation
                    if averageOzPerGallon > 0 {
                        let bottleSize = 16.0 // 16 oz bottles
                        let bottleCount = averageOzPerGallon / bottleSize
                        Text("(approximately \(String(format: "%.1f", bottleCount)) 16-oz bottles)")
                            .font(.system(size: 14))
                            .foregroundColor(AppStyle.secondaryTextColor)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
            
            // Gallons Needed
            VStack(alignment: .leading, spacing: 4) {
                Text("Gallons Needed")
                    .font(.system(size: 16))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                let averageGallons = ((viewModel.solutionAmountStandard + viewModel.solutionAmountExtended) / 2) / 3.785
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(String(format: "%.1f", averageGallons))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                    Text("gal")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                }
                
                Text("Based on SCI method of AMT 2.5 times the amount of blood (avg)")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.top, 2)
                
                Text("Provides baseline for solution volume requirements")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.top, 2)
                
                Text("Adjust based on case conditions and fluid characteristics")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.top, 2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, AppStyle.Spacing.medium)
    }
}

// New Formaldehyde Calculations Section
struct FormaldehydeCalculationsSection: View {
    @ObservedObject var viewModel: CH2OViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Formaldehyde Calculations")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppStyle.textColor)
                .padding(.bottom, 0)
            
            // Combined Fluid per Gallon and Total Solution
            VStack(alignment: .leading, spacing: 1) {
                Text("Solution Requirements")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                if let indexValue = Double(viewModel.fluidIndex), indexValue > 0 {
                    let formaldehydePerBottle = ((indexValue / 100) * 473.18) * 1.1
                    let bottlesNeeded = max(0, viewModel.formaldehydeDemand / formaldehydePerBottle)
                    let standardGallons = viewModel.solutionAmountStandard / 3.785
                    let extendedGallons = viewModel.solutionAmountExtended / 3.785
                    let standardOzPerGallon = (bottlesNeeded * 16) / standardGallons
                    let extendedOzPerGallon = (bottlesNeeded * 16) / extendedGallons
                    
                    // Extended (3×)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Extended (3×)")
                            .font(.system(size: 14))
                            .foregroundColor(AppStyle.secondaryTextColor)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(String(format: "%.1f", extendedOzPerGallon))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                                Text("oz/gal")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                            }
                            
                            Text("×")
                                .font(.system(size: 18))
                                .foregroundColor(AppStyle.secondaryTextColor)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(String(format: "%.1f", extendedGallons))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                                Text("gal")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                            }
                        }
                    }
                    
                    // Standard (2×)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Standard (2×)")
                            .font(.system(size: 14))
                            .foregroundColor(AppStyle.secondaryTextColor)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(String(format: "%.1f", standardOzPerGallon))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                                Text("oz/gal")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                            }
                            
                            Text("×")
                                .font(.system(size: 18))
                                .foregroundColor(AppStyle.secondaryTextColor)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(String(format: "%.1f", standardGallons))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                                Text("gal")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppStyle.primaryColor)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
            
            // Formaldehyde Demand
            VStack(alignment: .leading, spacing: 1) {
                Text("Formaldehyde Demand")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(String(format: "%.1f", max(0, viewModel.formaldehydeDemand)))")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                    Text("g")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppStyle.primaryColor)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
            
            // Formaldehyde per Bottle
            VStack(alignment: .leading, spacing: 1) {
                Text("Formaldehyde per Bottle")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                if let indexValue = Double(viewModel.fluidIndex), indexValue > 0 {
                    let formaldehydePerBottle = max(0, ((indexValue / 100) * 473.18) * 1.1)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(String(format: "%.1f", formaldehydePerBottle))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppStyle.primaryColor)
                        Text("g")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppStyle.primaryColor)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
            
            // Bottles Needed
            VStack(alignment: .leading, spacing: 1) {
                Text("Bottles Needed")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                if let indexValue = Double(viewModel.fluidIndex), indexValue > 0 {
                    let formaldehydePerBottle = ((indexValue / 100) * 473.18) * 1.1
                    let bottlesNeeded = max(0, viewModel.formaldehydeDemand / formaldehydePerBottle)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(String(format: "%.1f", bottlesNeeded))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppStyle.primaryColor)
                        Text("bottles")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppStyle.primaryColor)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
        }
        .padding()
        .cardStyle()
    }
}

// Footnotes Section
struct FootnotesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            Text("Calculation Notes")
                .font(AppStyle.Typography.headline)
                .foregroundColor(AppStyle.textColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Body Type Selection")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("High BMI (15%): Lower percentage of protein relative to total body weight")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                Text("Average (16.5%): Standard percentage of protein relative to total body weight")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                Text("All Muscle (20%): Higher percentage of protein relative to total body weight")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                Text("Higher protein content requires more preservation fluid due to increased formaldehyde demand")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .padding(.bottom, 4)

                Text("1. Primary Dilution")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Formula: Strength (%) × Volume = Index × Fluid Amount")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Text("2. Total Solution")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Standard (2×): Body Weight (kg) × 7% × 2")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                Text("Extended (3×): Body Weight (kg) × 7% × 3")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Text("3. Formaldehyde Demand")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Formula: ((Weight in kg × Body Type % × 1000) ÷ 100) × 4.4")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Text("4. Formaldehyde per Bottle")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Formula: ((Index ÷ 100) × 473.18 ml) × 1.1")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Text("5. Bottles Needed")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Formula: Formaldehyde Demand ÷ Formaldehyde per Bottle")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Text("6. Gallons Needed (STD)")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Formula: Body Weight (lbs) ÷ 50")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                
                Text("7. Gallons Needed (SCI)")
                    .font(AppStyle.Typography.subheadline)
                    .foregroundColor(AppStyle.textColor)
                Text("Standard (2×): (Body Weight (kg) × 0.07 × 2) ÷ 3.785")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
                Text("Extended (3×): (Body Weight (kg) × 0.07 × 3) ÷ 3.785")
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.secondaryTextColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(AppStyle.CornerRadius.medium)
        }
        .padding()
        .cardStyle()
    }
}

// Button style for animation
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Add this extension at the end of the file, before the Preview
extension View {
    func dismissKeyboardOnScroll() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func withHapticFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        )
    }
}

#Preview {
    NavigationView {
        CH2OView()
    }
} 