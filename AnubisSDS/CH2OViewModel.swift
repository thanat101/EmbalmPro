import SwiftUI
import Combine

class CH2OViewModel: ObservableObject {
    // Outputs
    @Published var fluidAmount: Double = 0.0
    @Published var solutionAmountStandard: Double = 0.0
    @Published var solutionAmountExtended: Double = 0.0
    @Published var formaldehydeDemand: Double = 0.0
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var calculationPerformed: Bool = false
    
    // Inputs
    @Published var desiredStrength: String = ""
    @Published var totalVolume: String = "128"
    @Published var fluidIndex: String = ""
    @Published var bodyWeight: String = "200"
    @Published var weightUnit: String = "lb"
    @Published var bodyPercentage: Double = 16.5
    @Published var sliderValue: Double = 200
    
    // Helper data
    @Published var fluidName: String = ""
    @Published var conditionName: String = ""
    
    init(initialStrengthPercent: String = "", 
         initialFluidIndex: String = "", 
         initialFluidName: String = "",
         initialConditionName: String = "") {
        self.desiredStrength = initialStrengthPercent
        self.fluidIndex = initialFluidIndex
        self.fluidName = initialFluidName
        self.conditionName = initialConditionName
    }
    
    func calculateDilution() {
        // Clear any previous errors
        showError = false
        errorMessage = ""
        
        // Validate inputs
        guard let strengthValue = Double(desiredStrength), strengthValue > 0 else {
            showError = true
            errorMessage = "Please enter a valid solution strength"
            return
        }
        
        guard let volumeValue = Double(totalVolume), volumeValue > 0 else {
            showError = true
            errorMessage = "Please enter a valid total volume"
            return
        }
        
        guard let indexValue = Double(fluidIndex), indexValue > 0 else {
            showError = true
            errorMessage = "Please enter a valid fluid index"
            return
        }
        
        // Formula: Strength * TotalVolume = Index * FluidAmount
        // FluidAmount = (Strength * TotalVolume) / Index
        fluidAmount = (strengthValue * volumeValue) / indexValue
        calculationPerformed = true
    }
    
    func calculateTotalSolution() {
        // Reset error state
        showError = false
        errorMessage = ""
        
        // Validate inputs
        guard let strength = Double(desiredStrength), strength > 0 else {
            return
        }
        
        guard let volume = Double(totalVolume), volume > 0 else {
            return
        }
        
        guard let index = Double(fluidIndex), index > 0 else {
            return
        }
        
        // Calculate fluid amount using the correct formula:
        // Solution Strength * Total Volume = Index * Fluid Amount
        // Therefore: Fluid Amount = (Solution Strength * Total Volume) / Index
        fluidAmount = (strength * volume) / index
        
        // Calculate solution amounts using fixed 7% instead of bodyPercentage
        let weightInKg = weightUnit == "lb" ? sliderValue / 2.20462 : sliderValue
        let standardMultiplier = 2.0
        let extendedMultiplier = 3.0
        
        // Standard (2×): Body Weight (kg) × 7% × 2
        solutionAmountStandard = max(0, weightInKg * 0.07 * standardMultiplier)
        // Extended (3×): Body Weight (kg) × 7% × 3
        solutionAmountExtended = max(0, weightInKg * 0.07 * extendedMultiplier)
        
        // Calculate formaldehyde demand
        let formaldehydeDemandValue = ((weightInKg * (bodyPercentage / 100) * 1000) / 100) * 4.4
        formaldehydeDemand = max(0, formaldehydeDemandValue)
    }
    
    func calculateAll() {
        // Reset error state
        showError = false
        errorMessage = ""
        
        // Validate inputs
        guard let strength = Double(desiredStrength), strength > 0 else {
            showError = true
            errorMessage = "Please enter a valid strength percentage"
            return
        }
        
        guard let volume = Double(totalVolume), volume > 0 else {
            showError = true
            errorMessage = "Please enter a valid volume"
            return
        }
        
        guard let index = Double(fluidIndex), index > 0 else {
            showError = true
            errorMessage = "Please enter a valid fluid index"
            return
        }
        
        // Calculate fluid amount using the correct formula:
        // Solution Strength * Total Volume = Index * Fluid Amount
        // Therefore: Fluid Amount = (Solution Strength * Total Volume) / Index
        fluidAmount = (strength * volume) / index
        
        // Calculate solution amounts using fixed 7% instead of bodyPercentage
        let weightInKg = weightUnit == "lb" ? sliderValue / 2.20462 : sliderValue
        let standardMultiplier = 2.0
        let extendedMultiplier = 3.0
        
        // Standard (2×): Body Weight (kg) × 7% × 2
        solutionAmountStandard = max(0, weightInKg * 0.07 * standardMultiplier)
        // Extended (3×): Body Weight (kg) × 7% × 3
        solutionAmountExtended = max(0, weightInKg * 0.07 * extendedMultiplier)
        
        // Calculate formaldehyde demand
        let formaldehydeDemandValue = ((weightInKg * (bodyPercentage / 100) * 1000) / 100) * 4.4
        formaldehydeDemand = max(0, formaldehydeDemandValue)
        
        // Mark calculation as performed
        calculationPerformed = true
    }
    
    func resetCalculator() {
        // Reset all fields
        desiredStrength = ""
        totalVolume = "128"
        fluidIndex = ""
        bodyWeight = "200"
        weightUnit = "lb"
        sliderValue = 200
        
        // Reset results
        fluidAmount = 0.0
        solutionAmountStandard = 0.0
        solutionAmountExtended = 0.0
        
        // Reset UI state
        calculationPerformed = false
        showError = false
        errorMessage = ""
    }
} 