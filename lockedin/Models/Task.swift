//
//  TaskType.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//
import Foundation
import SwiftUI

// Enum to represent the type of task
enum TaskType: String, Codable {
    case predefined
    case custom
}

// Enum to represent the completion status of a task
enum TaskStatus: String, Codable {
    case pending
    case completed
    case verified
}

// Struct to represent evidence for task completion
struct TaskEvidence: Identifiable, Codable {
    var id = UUID()
    var textDescription: String?
    var imageFilename: String?  // Store filename instead of raw image data
    var dateSubmitted: Date
    
    init(textDescription: String? = nil, imageFilename: String? = nil) {
        self.textDescription = textDescription
        self.imageFilename = imageFilename
        self.dateSubmitted = Date()
    }
    
    // Function to get the image if available
    func getImage() -> UIImage? {
        guard let filename = imageFilename else { return nil }
        return FileUtility.loadImage(filename: filename)
    }
}

// Main Task model
struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var type: TaskType
    var status: TaskStatus = .pending
    var evidence: TaskEvidence?
    var creationDate: Date
    var completionDate: Date?
    
    // Predefined task constructor
    static func predefined(title: String, description: String) -> Task {
        Task(title: title, description: description, type: .predefined, creationDate: Date())
    }
    
    // Custom task constructor
    static func custom(title: String, description: String) -> Task {
        Task(title: title, description: description, type: .custom, creationDate: Date())
    }
    
    // Method to submit evidence and mark task as completed
    // Note: This is for backwards compatibility - actual handling is in TaskManager
    mutating func complete(textDescription: String? = nil, imageData: Data? = nil) {
        self.evidence = TaskEvidence(textDescription: textDescription)
        self.status = .completed
        self.completionDate = Date()
    }
    
    // Method to verify task completion (to be used with SLM verification)
    mutating func verify() {
        self.status = .verified
    }
}
