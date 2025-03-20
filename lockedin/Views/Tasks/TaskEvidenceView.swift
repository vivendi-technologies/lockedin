//
//  TaskEvidenceView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//


import SwiftUI
import Foundation

/// A view for submitting or editing evidence for a task
struct TaskEvidenceView: View {
    /// The task manager to update when evidence is submitted
    @ObservedObject var taskManager: TaskManager
    
    /// The task to be completed or edited
    let task: Task
    
    /// Used to dismiss the view
    @Environment(\.presentationMode) var presentationMode
    
    /// Text evidence provided by the user
    @State private var textEvidence: String
    
    /// Image evidence selected by the user
    @State private var imageEvidence: UIImage?
    
    /// Controls the display of the image picker
    @State private var showingImagePicker = false
    
    /// Controls the display of validation alerts
    @State private var showAlert = false
    
    /// Message to display in the alert
    @State private var alertMessage = ""
    
    /// Flag to determine if we're editing existing evidence
    @State private var isEditing: Bool
    
    /// Initialize the view with proper state for new or existing evidence
    init(taskManager: TaskManager, task: Task) {
        self.taskManager = taskManager
        self.task = task
        
        // Check if we're editing an existing task with evidence
        let isEditingTask = task.status != .pending && task.evidence != nil
        self._isEditing = State(initialValue: isEditingTask)
        
        // Initialize text evidence from existing data if available
        if let existingText = task.evidence?.textDescription {
            self._textEvidence = State(initialValue: existingText)
        } else {
            self._textEvidence = State(initialValue: "")
        }
        
        // Image will be loaded in onAppear
    }
    
    var body: some View {
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
                                    Text("Describe how you completed this task...")
                                        .foregroundColor(Color.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                // Photo evidence section
                Section(header: Text("Show us a photo")) {
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
                        // Button to show the image picker
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Label("Upload Photo", systemImage: "photo")
                        }
                    }
                }
                
                // Complete/Update task button
                Section {
                    Button(isEditing ? "Update Task" : "Confirm Completion") {
                        if textEvidence.isEmpty && imageEvidence == nil {
                            alertMessage = "Please share how you completed this task - a quick note or a photo would be great!"
                            showAlert = true
                        } else {
                            saveEvidence()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(isEditing ? .blue : .green)
                }
            }
            .navigationTitle(isEditing ? "Your Completed Task" : "Complete Task")
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
                // Use the ImagePicker component
                ImagePicker(image: $imageEvidence)
            }
            .onAppear {
                // Load existing image if available
                if let imageData = task.evidence?.imageData,
                   let uiImage = UIImage(data: imageData) {
                    imageEvidence = uiImage
                }
            }
        }
    }
    
    /// Saves the evidence and updates the task status
    private func saveEvidence() {
        var imageData: Data? = nil
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
