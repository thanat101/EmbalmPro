import SwiftUI

struct UserGuideView: View {
    @State private var selectedSection: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("EmbalmPro User Guide")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 10)
                    
                    // Table of Contents
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                        Text("Table of Contents")
                            .font(AppStyle.Typography.largeTitle)
                            .foregroundColor(AppStyle.textColor)
                        
                        NavigationLink("1. Getting Started") {
                            GettingStartedSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("2. Navigation") {
                            NavigationSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("3. Search and Filter") {
                            SearchAndFilterSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("4. Fluid Details") {
                            FluidDetailsSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("5. Case Analysis") {
                            CaseAnalysisSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("6. CH2O Calculator") {
                            CH2OCalculatorSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("7. SDS (Safety Data Sheets)") {
                            SDSSectionGuideView()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("8. Favorites") {
                            FavoritesSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("9. Tips and Tricks") {
                            TipsAndTricksSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("10. Edit Feature") {
                            EditFeatureSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        NavigationLink("11. Database Reset") {
                            DatabaseResetSection()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.primaryColor)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        NavigationLink("Settings") {
                            SettingsView()
                        }
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
            }
            .navigationTitle("User Guide")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppStyle.primaryColor)
                }
            }
        }
    }
}

// MARK: - Getting Started Section
struct GettingStartedSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Welcome Screen")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("When you first open the app, you'll see a welcome screen. This screen provides quick access to common features and recent searches. You can dismiss this screen by tapping the 'X' on top right of Screen or by clicking the 'Getting Started' button on bottom of page.")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("To bring the welcome screen back:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Tap the 'About' button in the top left corner")
                        Text("2. The 'About' button will also take you back to the 'User Guide'")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Keyboard Management")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("To dismiss the keyboard:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Tap anywhere slightly above or below the text input area - be careful not to tap a result because that will take you to more details")
                        Text("• Press the 'Return' key after entering text")
                        Text("• Scroll the screen up or down to dismiss the keyboard")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Getting Started")
    }
}

// MARK: - Navigation Section
struct NavigationSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Main Navigation")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The app is organized into several main sections:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Fluids List: Browse all available fluids")
                        Text("• Case Analysis: View and manage condition strengths")
                        Text("• CH2O Calculator: Access formaldehyde calculations")
                        Text("• SDS: View Safety Data Sheets by section or the entire data sheet")
                        Text("• Favorites: Quick access to your most frequently used fluids")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Navigation")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("When viewing a tab's details, you can:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Swipe back button on page top to return to previous view")
                        Text("• Tap the icon on the navigation bar; one time to return to previous view or twice to go to the main tab view")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Navigation")
    }
}

// MARK: - Search and Filter Section
struct SearchAndFilterSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Search Functionality")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The search bar at the top of the Fluids List allows you to search across all fluid properties. You can search by:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Fluid name")
                        Text("• Manufacturer")
                        Text("• Type")
                        Text("• Index number")
                        Text("• Any other property in the database")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Filtering Options")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("Use the 'Filter by' button to access filtering options:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Fluid Type Filter:")
                        Text("   • Filter by fluid type (e.g., Vascular, Cavity, Supplements)")
                        Text("   • Select 'All' to show all types")
                        
                        Text("2. Manufacturer Filter:")
                        Text("   • Filter fluids by specific manufacturers")
                        Text("   • Select 'All' to show all manufacturers")
                        
                        Text("3. Fluid Use Filter:")
                        Text("   • Filter fluids by a specific use (e.g., Arterial, Coinjection, High Index Fluids)")
                        Text("   • Select 'All' to show all manufacturers")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("Tips for Effective Filtering:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Filters can be used in combination with search")
                        Text("• Use 'Clear Filters' to reset all filters")
                        Text("• Filters persist until cleared or app restart")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Search and Filter")
    }
}

// MARK: - Fluid Details Section
struct FluidDetailsSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Viewing Fluid Details")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("When you select a fluid, you'll see detailed information about its properties and usage.")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Basic information (name, manufacturer, type)")
                        Text("• Technical specifications")
                        Text("• Usage recommendations")
                        Text("• Safety information")
                        Text("• Links to related SDS")
                        Text("• Dilution calculator for precise solution preparation")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Dilution Calculator")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("The fluid details view includes a built-in dilution calculator that helps you:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Calculate precise dilution ratios for any volume")
                        Text("• Determine exact amounts of fluid and water needed")
                        Text("• Save common dilution settings for quick access")
                        Text("• View recommended dilution ranges for different applications")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Editing Fluid Details")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("You can modify fluid information directly in the app:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Open the fluid detail view")
                        Text("2. Tap the 'Edit' button")
                        Text("3. Modify the desired fields")
                        Text("4. Tap 'Save' to keep your changes")
                        Text("5. Changes will be saved and visible throughout the app; after hitting 'reset' from the fluids tab")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Fluid Details")
    }
}

// MARK: - Case Analysis Section
struct CaseAnalysisSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Case Analysis Features")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The Case Analysis section provides tools for managing embalming analysis:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Search and filter through Case types")
                        Text("• View detailed case analysis information")
                        Text("• View and access 'Suggested Use Fluids' based on solution strength and fluid index")
                        Text("• Calculate total solution requirements")
                        Text("• View strength percentages")
                        Text("• Manage condition-specific treatments")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Suggested Use Fluids")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("THIS IS THE MOST POWERFUL PART OF THE APP")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Takes you directly to the formaldehyde calculator and pre-fills the index and solution strength for the selected embalming fluid")
                        Text("• For each condition, the app suggests appropriate fluids based on:")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• CH2O INDEX range matching")
                            Text("• Firming speed compatibility")
                            Text("• Humectant properties")
                            Text("• Special treatment capabilities")
                            Text("• Manufacturer recommendations")
                        }
                        .padding(.leading)
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Case Analysis")
    }
}

// MARK: - CH2O Calculator Section
struct CH2OCalculatorSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Calculation Features")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The CH2O Calculator provides comprehensive calculation tools:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Weight-based calculations (pounds/kilograms)")
                        Text("• Automatic unit conversion")
                        Text("• Body type adjustments (high BMI/average/muscular)")
                        Text("• Calculations:")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Yields two types of results:")
                            Text("  - Industry Standard")
                            Text("  - Scientific Approach based on cross-linking proteins by body type and weight")
                        }
                        .padding(.leading)
                        
                        Text("• Formaldehyde demand calculations")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Results Display")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("The calculator shows detailed results including:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Embalming fluid needed per gallon")
                        Text("• Total solution requirements")
                        Text("• Formaldehyde content per bottle")
                        Text("• Industry standard calculations")
                        Text("• Scientific approach calculations")
                        Text("• Step-by-step calculation breakdown")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("CH2O Calculator")
    }
}

// MARK: - SDS Section Guide
struct SDSSectionGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Safety Data Sheets")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The SDS section provides detailed safety information for all fluids.")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• View complete safety data sheets")
                        Text("• Access individual sections")
                        Text("• Search for specific information")
                        Text("• Link directly from fluid details")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Editing SDS Information")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("You can update SDS information as needed:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Open the SDS detail view")
                        Text("2. Tap the 'Edit' button")
                        Text("3. Modify the desired sections")
                        Text("4. Tap 'Save' to preserve your changes")
                        Text("5. Updated information will be immediately available after you hit 'reset' on the fluids tab")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Viewing All Sections")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("To view and edit all SDS sections at once:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Tap 'View All Sections'")
                        Text("2. Use the edit button to make changes")
                        Text("3. All sections will be visible for context")
                        Text("4. Save changes when finished")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("SDS")
    }
}

// MARK: - Favorites Section
struct FavoritesSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Managing Favorites")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The Favorites tab provides quick access to your most frequently used fluids.")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("Adding Favorites:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Navigate to any fluid in the Fluids tab")
                        Text("2. Tap the star icon to add it to your favorites")
                        Text("3. The star will turn yellow to indicate it's a favorite")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Removing Favorites")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    Text("You can remove items from your favorites in two ways:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. From the Favorites tab:")
                        Text("   • Tap the yellow star icon next to any fluid")
                        Text("   • The item will be immediately removed")
                        Text("\n2. From the Fluids tab:")
                        Text("   • Find the fluid you want to remove")
                        Text("   • Tap the yellow star to remove it from favorites")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Using the Favorites Tab")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• View all your favorite fluids in one place")
                        Text("• Search within your favorites using the search bar")
                        Text("• Tap any fluid to view its details")
                        Text("• Remove items directly from the favorites list")
                        Text("• Access all fluid features from the favorites view")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Favorites")
    }
}

// MARK: - Tips and Tricks Section
struct TipsAndTricksSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Efficient Navigation")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Use the search bar to quickly find fluids")
                        Text("• Bookmark frequently used fluids")
                        Text("• Use the filter options to narrow down results")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
                
                Group {
                    Text("Keyboard Tips")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Quickly dismiss the keyboard by scrolling the screen")
                        Text("• Press the Return key to dismiss the keyboard after entering text")
                        Text("• Tap outside the search bar or text field to dismiss the keyboard")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Tips and Tricks")
    }
}

// MARK: - Edit Feature Section
struct EditFeatureSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Edit Feature")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The Edit feature allows you to modify fluid information and SDS details throughout the app.")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("How to Edit:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Navigate to the item you want to edit")
                        Text("2. Tap the 'Edit' button")
                        Text("3. Make your desired changes")
                        Text("4. Tap 'Save' to store your changes")
                        Text("5. Important: Return to the Fluids tab and tap 'Reset' to see your changes take effect")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("What Can Be Edited:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Fluid information")
                        Text("• Safety Data Sheet (SDS) details")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("Adding New Fluids:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• The app does not support adding completely new fluids")
                        Text("• To add a new fluid, use the provided sample fluids:")
                        Text("  - 'Sample One' and 'Sample Two' are included for this purpose")
                        Text("  - Edit these samples to create your custom fluid")
                        Text("  - Once a fluid has been edited, the change cannot be undone, but can only be re-edited")
                        Text("  - To revert back to original database, the app must be deleted and then reinstalled")
                        Text("  - Note: Reinstalling will cause you to lose all edits made to other fluids")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("Important Notes:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Changes are saved immediately but require a reset from the Fluids tab to be visible")
                        Text("• Once a fluid is edited, changes cannot be undone, but can be re-edited")
                        Text("• To restore original database, you must delete and reinstall the app")
                        Text("• Warning: Reinstalling will cause you to lose all edits made to other fluids")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Edit Feature")
    }
}

// MARK: - Database Reset Section
struct DatabaseResetSection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Group {
                    Text("Database Reset")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("The app provides two types of reset functionality:")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("1. Cache Reset (Circular Button)")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Located in the Fluids tab")
                        Text("• Appears as a circular arrow button")
                        Text("• Refreshes the app's cache")
                        Text("• Updates the view with latest data")
                        Text("• Required after making edits to see changes")
                        Text("• Does not affect the actual database")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("2. Database Reset (Settings)")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Access through Settings in User Guide")
                        Text("• Completely resets ALL database tables to original state")
                        Text("• Affects both Fluids and Conditions tables")
                        Text("• Removes all edits and changes to any table")
                        Text("• Gets fresh copy of entire database from app bundle")
                        Text("• Requires multiple confirmations")
                        Text("• Cannot be undone")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("Important Reset Process:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. To reset the database:")
                        Text("   • Go to Settings in User Guide")
                        Text("   • Tap 'Reset Database'")
                        Text("   • Confirm the warnings")
                        Text("   • Wait for reset to complete")
                        Text("   • All tables (Fluids, Conditions, etc.) will be reset")
                        Text("   • Return to Fluids tab")
                        Text("   • Tap circular reset button to refresh view")
                        
                        Text("\n2. After making edits:")
                        Text("   • Changes are saved automatically")
                        Text("   • Return to Fluids tab")
                        Text("   • Tap circular reset button to see changes")
                        
                        Text("\n3. To see fresh data:")
                        Text("   • Always use circular reset button")
                        Text("   • This ensures view matches database")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                    
                    Text("Warning:")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(.red)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Database reset is permanent")
                        Text("• All edits will be lost")
                        Text("• Cannot be undone")
                        Text("• Always use circular reset for normal updates")
                        Text("• Only use database reset when necessary")
                    }
                    .font(AppStyle.Typography.body)
                    .foregroundColor(AppStyle.textColor)
                }
            }
            .padding()
        }
        .navigationTitle("Database Reset")
    }
}

#Preview {
    UserGuideView()
}

