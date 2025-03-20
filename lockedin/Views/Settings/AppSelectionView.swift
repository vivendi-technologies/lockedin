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
                        if restrictionManager.isRestrictionActive {
                            // Re-apply restrictions with new settings
                            restrictionManager.enableRestrictions()
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Settings")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("App Restrictions")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $isShowingActivityPicker) {
                FamilyActivityPicker(selection: $restrictionManager.selectedApps)
                    .ignoresSafeArea()
            }
        }
    }
}
