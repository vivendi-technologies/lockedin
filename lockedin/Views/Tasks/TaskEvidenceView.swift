//
//  TaskEvidenceView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//
import SwiftUI
import PhotosUI
import UIKit

/// A view for submitting or editing evidence for a task
struct TaskEvidenceView: View {
    /// The task manager to update when evidence is submitted
    @ObservedObject var taskManager: TaskManager
    
    /// The task to be completed or edited
    let task: Task
    
    /// Used to dismiss the view
    @Environment(\.presentationMode) var presentationMode
    
    /// Text evidence provided by the user
    @State private var textEvidence: String = ""
    
    /// Image evidence selected by the user
    @State private var imageEvidence: UIImage?
    
    /// Controls the display of the image picker
    @State private var showingImagePicker = false
    
    /// Controls the display of the image source picker (camera/library)
    @State private var showingImageSourcePicker = false
    
    /// Controls the display of validation alerts
    @State private var showAlert = false
    
    /// Message to display in the alert
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    /// Flag to determine if we're editing existing evidence
    @State private var isEditing: Bool = false
    
    /// Flag to track if view has completed initialization
    @State private var isViewReady: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    /// Initialize the view with proper state for new or existing evidence
    init(taskManager: TaskManager, task: Task) {
        self.taskManager = taskManager
        self.task = task
        
        let isEditingTask = task.status != .pending && task.evidence != nil
        self._isEditing = State(initialValue: isEditingTask)
        
        if let existingText = task.evidence?.textDescription {
            self._textEvidence = State(initialValue: existingText)
        } else {
            self._textEvidence = State(initialValue: "")
        }
    }
    
    var body: some View {
        Group {
            if isViewReady {
                content
            } else {
                // Show a loading view until initialization is complete
                ProgressView()
                    .onAppear {
                        // Delay to ensure view is fully loaded before showing content
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isViewReady = true
                        }
                    }
            }
        }
    }
    
    private var content: some View {
        NavigationView {
            Form {
                // Task information section
                Section(header: Text("Task to Complete")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.headline)
                        
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if task.status != .pending {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Add supportive text about sharing progress
                    Text("Share how you completed this task using text, photo, or both!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // Text evidence section
                Section(header: Text("Tell us about it")) {
                    TextEditor(text: $textEvidence)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if textEvidence.isEmpty {
                                    Text("Enter text...")
                                        .foregroundColor(Color.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                // Photo evidence section
                Section(header: Text("Pics or it didn't happen!")) {
                    if let image = imageEvidence {
                        // Display the selected image
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                            Spacer()
                        }
                        
                        // Option to remove the selected image
                        Button(action: {
                            imageEvidence = nil
                        }) {
                            Label("Remove Image", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } else {
                        // Button to show the image source picker (camera or library)
                        Button(action: {
                            showingImageSourcePicker = true
                        }) {
                            Label("Add a Photo", systemImage: "camera.fill")
                        }
                    }
                }
                
                // Complete/Update task button
                Section {
                    Button(isEditing ? "Update Submission" : "Confirm Completion") {
                        if textEvidence.isEmpty && imageEvidence == nil {
                            alertMessage = "Please share how you completed this task - a quick note or a photo would be great!"
                            showAlert = true
                        } else {
                            saveEvidence()
                            // Delay dismissal slightly to ensure state is updated
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(isEditing ? .blue : .green)
                }
            }
            .navigationTitle(isEditing ? "Update Submission" : "Complete Task")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Input Required"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                // Use the ImagePicker component for photo library
                ImagePicker(image: $imageEvidence)
            }
            .actionSheet(isPresented: $showingImageSourcePicker) {
                // Use the utility struct to create the action sheet
                ImageSourcePickerOptions.makeActionSheet(
                    image: $imageEvidence,
                    isPresented: $showingImageSourcePicker
                )
            }
        }
        .onAppear {
            // Load existing image if available
            loadExistingData()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Helper function to check camera permission
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted, show camera
            sourceType = .camera
            showingImagePicker = true
            
        case .notDetermined:
            // Permission not determined yet, request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        sourceType = .camera
                        showingImagePicker = true
                    } else {
                        showCameraPermissionAlert()
                    }
                }
            }
            
        case .denied, .restricted:
            // Permission previously denied, show alert
            showCameraPermissionAlert()
            
        @unknown default:
            // Handle future cases
            showCameraPermissionAlert()
        }
    }
    
    // Helper function to show camera permission alert
    private func showCameraPermissionAlert() {
        alertTitle = "Camera Access"
        alertMessage = "Please allow camera access in Settings to take photos. Would you like to choose from your photo library instead?"
        showAlert = true
        
        // After alert is dismissed, show photo library picker
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sourceType = .photoLibrary
            showingImagePicker = true
        }
    }
    
    /// Loads existing task data if available
    private func loadExistingData() {
        // Determine if we're editing
        isEditing = task.status != .pending && task.evidence != nil
        
        // Load existing image if available using the getImage() method
        if let image = task.evidence?.getImage() {
            imageEvidence = image
        }
    }
    
    /// Saves the evidence and updates the task status
    private func saveEvidence() {
        var imageData: UIImage? = nil
        if let image = imageEvidence {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
        
        let textInput = textEvidence.isEmpty ? nil : textEvidence
        
        if isEditing {
            // Just update the evidence
            taskManager.updateTaskEvidence(id: task.id, textDescription: textInput, imageData: imageData)
        } else {
            // Complete the task with the new evidence
            taskManager.completeTask(id: task.id, textDescription: textInput, imageData: imageData)
        }
    }
}

// MARK: - Preview
struct TaskEvidenceView_Previews: PreviewProvider {
    static var previews: some View {
        let taskManager = TaskManager()
        let task = Task.predefined(title: "Morning Meditation", description: "Complete a 10-minute meditation session")
        
        return TaskEvidenceView(taskManager: taskManager, task: task)
    }
}
