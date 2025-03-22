//
//  TaskEvidenceView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//
import SwiftUI
import PhotosUI
import AVFoundation

struct TaskEvidenceView: View {
    @ObservedObject var taskManager: TaskManager
    let task: Task
    
    @Environment(\.presentationMode) var presentationMode
    
    // State variables with proper initialization
    @State private var textEvidence: String
    @State private var imageEvidence: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageSourcePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isEditing: Bool
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // Use an explicit initializer to properly set up all state
    init(taskManager: TaskManager, task: Task) {
        self.taskManager = taskManager
        self.task = task
        
        // Determine if we're editing an existing task
        _isEditing = State(initialValue: task.status != .pending && task.evidence != nil)
        
        // Set up textEvidence
        _textEvidence = State(initialValue: task.evidence?.textDescription ?? "")
        
        // Initialize image evidence directly
        var initialImage: UIImage? = nil
        if let evidence = task.evidence, let filename = evidence.imageFilename {
            initialImage = FileUtility.loadImage(filename: filename)
        }
        _imageEvidence = State(initialValue: initialImage)
    }
    
    var body: some View {
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
                    // Button to show camera/photo library options
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
                        alertTitle = "Input Required"
                        alertMessage = "Please share how you completed this task - a quick note or a photo would be great!"
                        showAlert = true
                    } else {
                        saveEvidence()
                        // Return to task list
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(isEditing ? .blue : .green)
            }
        }
        .navigationTitle(isEditing ? "Update Submission" : "Complete Task")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $imageEvidence, sourceType: sourceType)
        }
        .actionSheet(isPresented: $showingImageSourcePicker) {
            // Action sheet for choosing camera or photo library
            ActionSheet(
                title: Text("Select Photo Source"),
                message: Text("Choose where to get your photo from"),
                buttons: [
                    .default(Text("Take Photo")) {
                        checkCameraPermission()
                    },
                    .default(Text("Photo Library")) {
                        sourceType = .photoLibrary
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
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
    
    // Saves the evidence and updates the task status
    private func saveEvidence() {
        let textInput = textEvidence.isEmpty ? nil : textEvidence
        
        if isEditing {
            // Just update the evidence
            taskManager.updateTaskEvidence(id: task.id, textDescription: textInput, imageData: imageEvidence)
        } else {
            // Complete the task with the new evidence
            taskManager.completeTask(id: task.id, textDescription: textInput, imageData: imageEvidence)
        }
        
        // Always dismiss this view
        presentationMode.wrappedValue.dismiss()
    }
}
