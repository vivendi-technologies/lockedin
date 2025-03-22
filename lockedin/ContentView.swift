import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var appRestrictionManager = AppRestrictionManager()
    @State private var showingAppSettings = false
    @State private var authorizationRequested = false
    /*
    @State private var showingTaskCompletedBanner = false
    @State private var showingAppUnlockBanner = false
    @State private var showingCongratulations = false
    @State private var completedTask: Task? = nil
    */
    
    var body: some View {
        ZStack {
            // Main app content
            TaskListView(taskManager: taskManager)
                .onAppear {
                    // Inject the manager into taskManager
                    taskManager.appRestrictionManager = appRestrictionManager
                }
                .overlay(
                    VStack {
                        Spacer()
                        
                        // Show task completed banner
//                        if showingTaskCompletedBanner, let lastCompletedTask = appRestrictionManager.lastCompletedTask {
//                            TaskCompletedBanner(task: lastCompletedTask) {
//                                withAnimation {
//                                    showingTaskCompletedBanner = false
//                                }
//                                // Reset the last completed task
//                                appRestrictionManager.lastCompletedTask = nil
//                            }
//                            .transition(.move(edge: .bottom))
//                        }
                        
                        // App restriction status banner - use the shared instance
                        if appRestrictionManager.isRestrictionActive {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white)
                                
                                Text("Apps restricted until tasks are completed")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAppSettings = true
                                }) {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .shadow(radius: 2)
                        }
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingAppSettings = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
        }
        .onAppear {
            requestAuthorizationIfNeeded()
        }
        // Monitor for lastCompletedTask changes
//        .onReceive(appRestrictionManager.$lastCompletedTask) { task in
//            if let task = task {
//                print("Detected task completion: \(task.title)")
//                self.completedTask = task
//                self.showingCongratulations = true
//                
//                // Auto-hide after delay
//                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                    self.showingCongratulations = false
//                    appRestrictionManager.lastCompletedTask = nil
//                }
//            }
//        }
        .sheet(isPresented: $showingAppSettings) {
            // Use the shared restriction manager
            AppSelectionView(restrictionManager: appRestrictionManager)
        }
        // Make the restriction manager available to child views
        .environmentObject(appRestrictionManager)
        
        // Show app unlock banner when all tasks are completed
//        .overlay(
//            ZStack {
//                if showingAppUnlockBanner {
//                    AppUnlockBanner(isVisible: $showingAppUnlockBanner)
//                }
//            }
//        )
    }
    
    // Request Screen Time authorization when the app first launches
    func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        
        _Concurrency.Task {
            // Mark as requested to prevent multiple attempts
            authorizationRequested = true
            
            // Request authorization (doesn't return a boolean)
            await appRestrictionManager.requestAuthorization()
            
            // Check authorization status after the request
            if appRestrictionManager.isAuthorized {
                // Apply default restrictions if it's the first launch
                if taskManager.tasks.isEmpty {
                    // Add some default tasks for first-time users
                    taskManager.addTask(.predefined(title: "Morning Meditation", description: "Complete a 10-minute meditation session"))
                    taskManager.addTask(.predefined(title: "Read", description: "Read at least 10 pages of a book"))
                    
                    // Enable restrictions using the shared instance
                    appRestrictionManager.enableRestrictions()
                }
            }
        }
    }
}

// Banner that shows when a task is completed
/*
struct TaskCompletedBanner: View {
    let task: Task
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Task Completed!")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(5)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
*/
