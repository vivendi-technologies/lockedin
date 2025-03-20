import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

class AppRestrictionManager: ObservableObject {
    @Published var isRestrictionActive = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var restrictionMode: RestrictionMode = .automatic
    
    private let store = ManagedSettingsStore()
    
    // Restriction modes
    enum RestrictionMode: String, Codable, CaseIterable, Identifiable {
        case automatic = "Automatic"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .automatic:
                return "Automatically restrict all apps except system apps"
            case .custom:
                return "Choose which apps to restrict"
            }
        }
    }
    
    init() {
        loadSettings()
    }
    
    // Enable restrictions based on the selected mode
    func enableRestrictions() {
        switch restrictionMode {
        case .automatic:
            applyAutomaticRestrictions()
        case .custom:
            applyCustomRestrictions()
        }
        
        isRestrictionActive = true
        saveSettings()
    }
    
    // Disable all restrictions
    func disableRestrictions() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        
        isRestrictionActive = false
        saveSettings()
    }
    
    // Apply automatic restrictions to block most apps
    private func applyAutomaticRestrictions() {
        //store.shield.applications = . (except: [])
        store.shield.applicationCategories = .all(except: [])
        store.shield.webDomainCategories = .all(except: [])
    }
    
    // Apply custom restrictions based on user selection
    private func applyCustomRestrictions() {
        if !selectedApps.applicationTokens.isEmpty {
            store.shield.applications = .specific(
                tokens: selectedApps.applicationTokens,
                except: []
            )
        }
        
        if !selectedApps.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(
                selectedApps.categoryTokens,
                except: []
            )
        }
        
        if !selectedApps.webDomainTokens.isEmpty {
            store.shield.webDomains = .specific (
                tokens: selectedApps.webDomainTokens,
                except: []
            )
        }
        
        if !selectedApps.webDomainCategoryTokens.isEmpty {
            store.shield.webDomainCategories = .specific(
                selectedApps.webDomainCategoryTokens,
                except: []
            )
        }
    }
    
    // Check if all tasks are completed and unlock if needed
    func checkTaskCompletion(tasks: [Task]) {
        let allTasksCompleted = !tasks.isEmpty && tasks.allSatisfy { $0.status != .pending }
        
        if allTasksCompleted && isRestrictionActive {
            disableRestrictions()
        } else if !allTasksCompleted && !isRestrictionActive && !tasks.isEmpty {
            enableRestrictions()
        }
    }
    
    // Save settings to UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(isRestrictionActive, forKey: "isRestrictionActive")
        UserDefaults.standard.set(restrictionMode.rawValue, forKey: "restrictionMode")
        
        // We can't directly save the selection, so we'll just save a flag indicating
        // that the user has made a selection
        UserDefaults.standard.set(!selectedApps.applicationTokens.isEmpty, forKey: "hasCustomSelection")
    }
    
    // Load settings from UserDefaults
    private func loadSettings() {
        isRestrictionActive = UserDefaults.standard.bool(forKey: "isRestrictionActive")
        
        if let modeString = UserDefaults.standard.string(forKey: "restrictionMode"),
           let mode = RestrictionMode(rawValue: modeString) {
            restrictionMode = mode
        }
        
        // If restrictions should be active, reapply them (in case of app restart)
        if isRestrictionActive {
            enableRestrictions()
        }
    }
    
    // Request authorization to access Screen Time API
    func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            return true
        } catch {
            print("Failed to request authorization: \(error.localizedDescription)")
            return false
        }
    }
}
