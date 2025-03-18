//
//  TaskEvidenceView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//


import SwiftUI

/// A view for submitting evidence to complete a task
struct TaskEvidenceView: View {
    /// The task manager to update when evidence is submitted
    @ObservedObject var taskManager: TaskManager
    
    /// The task to be completed
    let task: Task
    
    /// Used to dismiss the view
    @Environment(\.presentationMode) var presentationMode
    
    /// Text evidence provided by the user
    @State private var textEvidence = ""
    
    /// Image evidence selected by the user
    @State private var imageEvidence: UIImage?
    
    /// Controls the display of the image picker
    @State private var showingImagePicker = false
    
    /// Controls the display of validation alerts
    @State private var showAlert = false
    
    /// Message to display in the alert
    @State private var alertMessage = ""
    
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
                    }
                    .padding(.vertical, 8)
                }
                
                // Text evidence section
                Section(header: Text("Text Evidence (Optional)")) {
                    TextEditor(text: $textEvidence)
                        .frame(minHeight: 100)
                        .overlay(
                            // Show placeholder text when input is empty
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
                Section(header: Text("Photo Evidence (Optional)")) {
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
                            Label("Add Photo Evidence", systemImage: "photo")
                        }
                    }
                }
                
                // Complete task button
                Section {
                    Button("Mark as Completed") {
                        if textEvidence.isEmpty && imageEvidence == nil {
                            alertMessage = "Please provide either text or photo evidence to mark this task as completed."
                            showAlert = true
                        } else {
                            completeTask()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.green)
                }
            }
            .navigationTitle("Complete Task")
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
        }
    }
    
    /// Completes the task with the provided evidence
    private func completeTask() {
        var imageData: Data? = nil
        if let image = imageEvidence {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
        
        let textInput = textEvidence.isEmpty ? nil : textEvidence
        
        taskManager.completeTask(id: task.id, textDescription: textInput, imageData: imageData)
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
