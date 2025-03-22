import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var appRestrictionManager: AppRestrictionManager
    @EnvironmentObject var dailyResetManager: DailyResetManager
    
    @State private var showingAppSettings = false
    @State private var authorizationRequested = false
    @State private var showingResetBanner = false
    @State private var showingDebugView = false
    
    // For unlock banner
    @State private var showingUnlockBanner = false
    @State private var wasRestrictionActive = false
    @State private var justCompletedAllTasks = false // Track when all tasks just completed
    
    // For task completion banner
    @State private var showingCompletionBanner = false
    @State private var completedTaskTitle = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // App restriction banner now appears below the navigation title
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
                        .padding(.top, 4)
                        .shadow(radius: 2)
                    }
                    
                    // Main task list view
                    TaskListView(taskManager: taskManager)
                        .onAppear {
                            // Inject the manager into taskManager
                            taskManager.appRestrictionManager = appRestrictionManager
                        }
                }
                .navigationTitle("Today's Tasks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button(action: {
                                showingAppSettings = true
                            }) {
                                Label("App Restrictions", systemImage: "lock.shield")
                            }
                            
                            NavigationLink(destination:
                                DailyResetSettingsView(dailyResetManager: dailyResetManager)
                            ) {
                                Label("Daily Reset", systemImage: "clock.arrow.circlepath")
                            }
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
                
                // Top reset banner overlay
                VStack {
                    if showingResetBanner {
                        TaskResetBanner(isVisible: $showingResetBanner)
                    }
                    
                    Spacer()
                }
                
                // Middle unlock banner overlay
                ZStack {
                    if showingUnlockBanner {
                        AppUnlockBanner(isVisible: $showingUnlockBanner)
                    }
                }
                
                // Bottom task completion banner overlay
                VStack {
                    Spacer()
                    
                    if showingCompletionBanner {
                        TaskCompletionBanner(isVisible: $showingCompletionBanner, taskTitle: completedTaskTitle)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 16) // Add extra padding at the bottom
                    }
                }
            }
            
            // Debug button overlay
            .overlay(
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingDebugView = true
                        }) {
                            Text("Debug")
                                .font(.caption)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding()
                        .opacity(0.7)
                    }
                }
            )
            .onAppear {
                requestAuthorizationIfNeeded()
                wasRestrictionActive = appRestrictionManager.isRestrictionActive
                
                // Reset the justCompletedAllTasks flag when tasks change
                if !taskManager.tasks.isEmpty && taskManager.tasks.contains(where: { $0.status == .pending }) {
                    justCompletedAllTasks = false
                    
                    // ADDED: Ensure restrictions are enabled if pending tasks exist
                    if !appRestrictionManager.isRestrictionActive {
                        appRestrictionManager.enableRestrictions()
                    }
                }
            }
            // Monitor for app unlock events
            .onReceive(appRestrictionManager.$isRestrictionActive) { isActive in
                // Only show banner when restrictions change from active to inactive
                if wasRestrictionActive && !isActive && !taskManager.tasks.isEmpty && justCompletedAllTasks {
                    withAnimation {
                        showingUnlockBanner = true
                        // Reset flag so banner doesn't show again until next completion cycle
                        justCompletedAllTasks = false
                    }
                }
                // Update tracking state
                wasRestrictionActive = isActive
            }
            // Monitor for pending task changes
            .onReceive(taskManager.$tasks) { tasks in
                // Reset our "just completed" flag when new tasks are added
                let pendingTasks = tasks.filter { $0.status == .pending }
                if !pendingTasks.isEmpty {
                    justCompletedAllTasks = false
                }
            }
            // Monitor for daily resets
            .onReceive(dailyResetManager.$didResetToday) { didReset in
                if didReset {
                    withAnimation {
                        showingResetBanner = true
                    }
                }
            }
            // Monitor for task completion
            .onReceive(taskManager.completionNotifier.$shouldShow) { shouldShow in
                if shouldShow, let completedTask = taskManager.completionNotifier.lastCompletedTask {
                    // Check if this is the last task being completed
                    let pendingTasks = taskManager.tasks.filter { $0.status == .pending }
                    
                    if pendingTasks.isEmpty {
                        // This was the last task - show unlock banner instead of completion banner
                        justCompletedAllTasks = true
                        // Don't show completion banner
                    } else {
                        // Not the last task - show the regular completion banner
                        completedTaskTitle = completedTask.title
                        withAnimation {
                            showingCompletionBanner = true
                        }
                    }
                    
                    // Reset the notifier
                    taskManager.completionNotifier.reset()
                }
            }
            .sheet(isPresented: $showingAppSettings) {
                // Use the shared restriction manager
                AppSelectionView(restrictionManager: appRestrictionManager)
            }
            .sheet(isPresented: $showingDebugView) {
                DebugViewController(dailyResetManager: dailyResetManager, taskManager: taskManager)
            }
        }
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
