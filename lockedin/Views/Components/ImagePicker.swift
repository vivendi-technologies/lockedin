//
//  ImagePicker.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//


import SwiftUI
import PhotosUI

/// A SwiftUI view that wraps UIKit's PHPickerViewController to select images from the photo library
struct ImagePicker: UIViewControllerRepresentable {
    /// The selected image binding
    @Binding var image: UIImage?
    
    /// Used to dismiss the picker
    @Environment(\.presentationMode) var presentationMode
    
    /// Creates the PHPickerViewController with appropriate configuration
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    /// Updates the view controller (not needed in this implementation)
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    /// Creates a coordinator to handle the delegate callbacks
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class that acts as the PHPickerViewControllerDelegate
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        /// Reference to the parent ImagePicker
        let parent: ImagePicker
        
        /// Initializes the coordinator with a reference to the parent
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        /// Called when the user finishes picking an image
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker
            parent.presentationMode.wrappedValue.dismiss()
            
            // Return if no selection was made
            guard let provider = results.first?.itemProvider else { return }
            
            // Load the image if possible
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    // Update the image on the main thread
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        // ImagePicker requires a binding, so we can't easily preview it directly
        Text("ImagePicker cannot be previewed directly")
    }
}