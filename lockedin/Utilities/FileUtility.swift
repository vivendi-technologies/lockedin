//
//  FileUtilities.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//

import Foundation
import UIKit

// Create a FileUtility class instead of FileManager extension
class FileUtility {
    
    /// Get the documents directory URL
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// Save image to documents directory and return the file URL
    static func saveImage(_ image: UIImage, id: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let filename = id.uuidString + ".jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    /// Load image from documents directory
    static func loadImage(filename: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    
    /// Delete image from documents directory
    static func deleteImage(filename: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Error deleting image: \(error)")
        }
    }
}
