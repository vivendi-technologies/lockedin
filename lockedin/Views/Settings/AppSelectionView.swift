//
//  AppSelectionView.swift
//  lockedin
//
//  Created by Kevin Le on 3/20/25.
//


// AppSelectionView.swift
import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @ObservedObject var restrictionManager: AppRestrictionManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingActivityPicker = false
    // Create a temporary selection that we only save when the user confirms
    @State private var tempSelection = FamilyActivitySelection()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Restriction Mode")) {
                    ForEach(AppRestrictionManager.RestrictionMode.allCases) { mode in
                        Button(action: {
                            restrictionManager.restrictionMode = mode
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(mode.rawValue)
                                        .font(.headline)
                                    
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if restrictionManager.restrictionMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if restrictionManager.restrictionMode == .custom {
                    Section(header: Text("Select Apps to Restrict")) {
                        Button(action: {
                            // Initialize temp selection with current selection
                            tempSelection = restrictionManager.selectedApps
                            isShowingActivityPicker = true
                        }) {
                            HStack {
                                Text("Choose Apps")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if !restrictionManager.selectedApps.applicationTokens.isEmpty {
                            Text("\(restrictionManager.selectedApps.applicationTokens.count) apps selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Save settings and dismiss
                        if restrictionManager.isRestrictionActive {
                            // Re-apply restrictions with new settings
                            restrictionManager.enableRestrictions()
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Settings")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("App Restrictions")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            // Use a full screen cover for better control of dismissal
            .fullScreenCover(isPresented: $isShowingActivityPicker) {
                AppSelectionPickerView(selection: $tempSelection, onSave: { newSelection in
                    // Update the real selection when user saves
                    restrictionManager.selectedApps = newSelection
                    isShowingActivityPicker = false
                }, onCancel: {
                    // Discard changes and dismiss
                    isShowingActivityPicker = false
                })
            }
        }
    }
}

// New view to wrap the FamilyActivityPicker with custom navigation
struct AppSelectionPickerView: View {
    @Binding var selection: FamilyActivitySelection
    var onSave: (FamilyActivitySelection) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        onCancel()
                    },
                    trailing: Button("Save") {
                        onSave(selection)
                    }
                )
        }
    }
}
