import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

class AppRestrictionManager: ObservableObject {
    @Published var isRestrictionActive = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var restrictionMode: RestrictionMode = .automatic
    @Published var isAuthorized = false
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private var deviceActivityMonitor: DeviceActivityEventMonitor?
    
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            DispatchQueue.main.async {
                self.isAuthorized = self.center.authorizationStatus == .approved
                
                // When authorization is granted, start the background monitoring
                if self.isAuthorized {
                    self.setupDeviceActivityMonitoring()
                }
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
        
        // Check authorization status immediately
        if center.authorizationStatus == .approved {
            isAuthorized = true
        }
    }
    
    func setTaskManager(_ taskManager: TaskManager) {
        // Create the device activity monitor with the task manager reference
        deviceActivityMonitor = DeviceActivityEventMonitor(
            taskManager: taskManager,
            appRestrictionManager: self
        )
        
        // Start device activity monitoring if authorized
        if isAuthorized {
            setupDeviceActivityMonitoring()
        }
        
        // Do not set up any regular checks - we'll only check at specific events
    }
    
    // Set up device activity monitoring for background restrictions
    func setupDeviceActivityMonitoring() {
        // Start the background monitoring when the app launches
        DeviceActivityMonitorCenter.shared.startMonitoring()
    }
    
    // Enable restrictions based on the selected mode
    func enableRestrictions(preserveSelection: Bool = false) {
        guard isAuthorized else { return }
        
        // Apply the actual shield restrictions
        switch restrictionMode {
        case .automatic:
            applyAutomaticRestrictions()
        case .custom:
            // Only apply custom restrictions if we have a selection
            if !selectedApps.applicationTokens.isEmpty || preserveSelection {
                applyCustomRestrictions()
            } else {
                // Fall back to automatic restrictions if no selection and not preserving
                applyAutomaticRestrictions()
            }
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
        store.shield.applicationCategories = .all(except: [])
        store.shield.webDomainCategories = .all(except: [])
    }
    
    // Apply custom restrictions based on user selection
    // Apply custom restrictions based on user selection
        private func applyCustomRestrictions() {
            // Clear any existing application categories restriction
            // This is critical when switching from automatic to custom mode
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
            
            // For applications
            if !selectedApps.applicationTokens.isEmpty {
                // Shield applications based on the selection
                store.shield.applications = .init(
                    Set(selectedApps.applicationTokens)
                )
            } else {
                // If no apps are selected, clear the application shield
                store.shield.applications = nil
            }
            
            // For web domains
            if !selectedApps.webDomainTokens.isEmpty {
                // Shield web domains based on the selection
                store.shield.webDomains = .init(
                    Set(selectedApps.webDomainTokens)
                )
            } else {
                // If no web domains are selected, clear the web domain shield
                store.shield.webDomains = nil
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
            enableRestrictions(preserveSelection: true)
        }
    }
}
