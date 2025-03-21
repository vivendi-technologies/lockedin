import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

class AppRestrictionManager: ObservableObject {
    @Published var isRestrictionActive = false
    @Published var selectedApps = FamilyActivitySelection() //{
//        willSet {
//            let applications = newValue.applicationTokens
//            let categories = newValue.categoryTokens
//            let webCategories = newValue.webDomainTokens
//        }
//    }
    @Published var restrictionMode: RestrictionMode = .automatic
    @Published var isAuthorized = false
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    
    func requestAuthorization() async {
            do {
                try await center.requestAuthorization(for: .individual)
                DispatchQueue.main.async {
                    self.isAuthorized = self.center.authorizationStatus == .approved
                }
            } catch {
                print("Failed to request authorization: \(error.localizedDescription)")
            }
        }
    
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
        guard isAuthorized else { return }
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
        guard isAuthorized else { return }
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
        // For applications
        if !selectedApps.applicationTokens.isEmpty {
            // Shield applications based on the selection
            store.shield.applications = .init(
                Set(selectedApps.applicationTokens)
            )
        }
        
        // For application categories
//        if !selectedApps.categoryTokens.isEmpty {
//            // Shield application categories based on the selection
//            store.shield.applicationCategories = .init(
//                blockedCategories: Set(selectedApps.categoryTokens)
//            )
//        }
        
        // For web domains
        if !selectedApps.webDomainTokens.isEmpty {
            // Shield web domains based on the selection
            store.shield.webDomains = .init(
                Set(selectedApps.webDomainTokens)
            )
        }
        
        // For web domain categories, just block all
        //store.shield.webDomainCategories = Optional.none
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
}
