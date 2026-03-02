import SwiftUI
import AudioToolbox
import UIKit

// Minimal UIKit text field for calculator inputs to avoid SwiftUI UITextInteraction / TapAndAHalfRecognizer lag on device
private struct CH2ODecimalField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onEditingChanged: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.text = text
        tf.keyboardType = .decimalPad
        tf.delegate = context.coordinator
        tf.font = .preferredFont(forTextStyle: .body)
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.textColor = .label
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        tf.leftView = padding
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.placeholder = placeholder
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: CH2ODecimalField
        init(_ parent: CH2ODecimalField) { self.parent = parent }
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.onEditingChanged?()
        }
    }
}

struct CH2OView: View {
    @StateObject private var viewModel: CH2OViewModel
    @FocusState private var focusedField: Field?
    @State private var shouldResetNavigation = false
    @State private var showCaseLogSheet = false

    enum Field: Hashable {
        case weight
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
         initialFluidManufacturer: String = "",
         initialConditionName: String = "") {
        _viewModel = StateObject(wrappedValue: CH2OViewModel(
            initialStrengthPercent: initialStrengthPercent,
            initialFluidIndex: initialFluidIndex,
            initialFluidName: initialFluidName,
            initialFluidManufacturer: initialFluidManufacturer,
            initialConditionName: initialConditionName))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BodyInfoSection(viewModel: viewModel, focusedField: $focusedField)

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

                    HStack(spacing: AppStyle.Spacing.medium) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Strength (%)")
                                .font(AppStyle.Typography.caption)
                                .foregroundColor(AppStyle.secondaryTextColor)
                            CH2ODecimalField(placeholder: "2%", text: $viewModel.desiredStrength) {
                                viewModel.calculationPerformed = false
                            }
                            .frame(height: 40)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Volume (oz)")
                                .font(AppStyle.Typography.caption)
                                .foregroundColor(AppStyle.secondaryTextColor)
                            CH2ODecimalField(
                                placeholder: "128",
                                text: Binding(
                                    get: { viewModel.totalVolume },
                                    set: { viewModel.totalVolume = $0.isEmpty ? "128" : $0; viewModel.calculationPerformed = false }
                                )
                            )
                            .frame(height: 40)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Index")
                                .font(AppStyle.Typography.caption)
                                .foregroundColor(AppStyle.secondaryTextColor)
                            CH2ODecimalField(placeholder: "25", text: $viewModel.fluidIndex) {
                                viewModel.calculationPerformed = false
                            }
                            .frame(height: 40)
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
                .padding(.vertical, 8)
                .cardStyle()

                if viewModel.calculationPerformed {
                    ResultsSection(viewModel: viewModel)
                    FormaldehydeCalculationsSection(viewModel: viewModel)
                }

                FootnotesSection()
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            if !viewModel.conditionName.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCaseLogSheet = true
                    } label: {
                        Label("Start Case Log", systemImage: "doc.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCaseLogSheet) {
            NavigationStack {
                CaseLogDetailView(
                    report: nil,
                    prefill: caseLogPrefillFromViewModel
                ) {
                    showCaseLogSheet = false
                }
            }
        }
        .onAppear {
            viewModel.bodyWeight = String(format: "%.0f", viewModel.sliderValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetNavigation"))) { _ in
            shouldResetNavigation = true
        }
        .id(shouldResetNavigation)
    }

    /// Prefill for Case Log when opened from Case Analysis → Suggested Fluids → Fluid Needed.
    /// Condition = case type (e.g. Alcoholism). Fluids used = manufacturer's fluid at X bottles, total Y gallons.
    /// Notes = index, strength, oz/gal, method, weight, body type.
    private var caseLogPrefillFromViewModel: CaseLogPrefill {
        let bottleOz: Double = 11.6
        // Fluids used: "DODGE CHROMATECH, 3.0 bottles, Total injected 3.2 gallons" (no 's on manufacturer)
        var fluidsLine = ""
        if !viewModel.fluidName.isEmpty {
            let fluidLabel = viewModel.fluidManufacturer.isEmpty
                ? viewModel.fluidName
                : "\(viewModel.fluidManufacturer) \(viewModel.fluidName)"
            if viewModel.calculationPerformed {
                let standardGallons = viewModel.sliderValue / 50.0
                let totalFluidOz = standardGallons * viewModel.fluidAmount
                let bottles = totalFluidOz / bottleOz
                fluidsLine = "\(fluidLabel) at \(String(format: "%.1f", bottles)) bottles, Total injected \(String(format: "%.1f", standardGallons)) gallons"
            } else {
                fluidsLine = fluidLabel
            }
        }
        // Solution details (under Condition & fluids): Fluid Index, strength, oz per gallon, Standard Method, volume.
        var solutionLines: [String] = []
        if !viewModel.fluidIndex.isEmpty { solutionLines.append("Fluid Index \(viewModel.fluidIndex)") }
        if !viewModel.desiredStrength.isEmpty { solutionLines.append("\(viewModel.desiredStrength)% strength") }
        if viewModel.calculationPerformed && viewModel.fluidAmount > 0 {
            solutionLines.append("\(String(format: "%.1f", viewModel.fluidAmount)) oz per gallon")
            solutionLines.append("Standard Method")
        }
        if !viewModel.totalVolume.isEmpty {
            solutionLines.append("Volume per gallon: \(viewModel.totalVolume) oz")
        }
        let solutionDetails = solutionLines.joined(separator: ". ")
        let bodyType: String = switch viewModel.bodyPercentage {
        case 15.0: "High BMI"
        case 20.0: "All Muscle"
        default: "Average"
        }
        return CaseLogPrefill(
            conditionSummary: viewModel.conditionName,
            arterialFluidUsed: fluidsLine.trimmingCharacters(in: .whitespaces),
            solutionDetails: solutionDetails,
            notes: "",
            bodyWeight: "\(String(format: "%.0f", viewModel.sliderValue)) \(viewModel.weightUnit)",
            bodyType: bodyType
        )
    }
}

// MARK: - Supporting View Components

// Body Info Section Component
struct BodyInfoSection: View {
    @ObservedObject var viewModel: CH2OViewModel
    var focusedField: FocusState<CH2OView.Field?>.Binding

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
                    .multilineTextAlignment(.trailing)
                    .padding(8)
                    .frame(minWidth: 60, maxWidth: 90, idealHeight: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppStyle.CornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.CornerRadius.small)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: viewModel.sliderValue) { newValue in
                        viewModel.bodyWeight = String(format: "%.0f", newValue)
                        viewModel.calculateTotalSolution()
                    }
                    .focused(focusedField, equals: CH2OView.Field.weight)
                
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
