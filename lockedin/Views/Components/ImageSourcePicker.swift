//
//  ImageSourcePicker.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//

import SwiftUI
import UIKit

/// A utility struct that creates photo source options and handles camera/photo library access
struct ImageSourcePickerOptions {
    /// Creates an ActionSheet configuration for selecting photo source
    static func makeActionSheet(image: Binding<UIImage?>, isPresented: Binding<Bool>) -> ActionSheet {
        // Check if camera is available on this device
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        var buttons: [ActionSheet.Button] = []
        
        // Only add the camera button if the camera is available
        if cameraAvailable {
            buttons.append(.default(Text("Take Photo")) {
                CameraPicker.shared.takePhoto { resultImage in
                    if let resultImage = resultImage {
                        image.wrappedValue = resultImage
                    }
                    isPresented.wrappedValue = false
                }
            })
        }
        
        // Always add the photo library option
        buttons.append(.default(Text("Photo Library")) {
            CameraPicker.shared.chooseFromLibrary { resultImage in
                if let resultImage = resultImage {
                    image.wrappedValue = resultImage
                }
                isPresented.wrappedValue = false
            }
        })
        
        // Always add cancel button
        buttons.append(.cancel() {
            isPresented.wrappedValue = false
        })
        
        return ActionSheet(
            title: Text("Select Photo Source"),
            message: Text("Choose where to get your photo from"),
            buttons: buttons
        )
    }
}

/// A class to handle camera and photo library interactions
class CameraPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Singleton instance
    static let shared = CameraPicker()
    
    // The active callback for when an image is selected
    private var completion: ((UIImage?) -> Void)?
    
    // Ensure it's only created once
    private override init() {
        super.init()
    }
    
    /// Present the camera to take a photo
    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        presentImagePicker(sourceType: .camera)
    }
    
    /// Present the photo library to select a photo
    func chooseFromLibrary(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        presentImagePicker(sourceType: .photoLibrary)
    }
    
    /// Present the appropriate UIImagePickerController
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            picker.allowsEditing = true
            
            // Get the root view controller using the newer UIWindowScene API
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(picker, animated: true)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        // Use the edited image if available, otherwise use the original
        if let editedImage = info[.editedImage] as? UIImage {
            completion?(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            completion?(originalImage)
        } else {
            completion?(nil)
        }
        
        // Clear the completion handler
        completion = nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        completion?(nil)
        completion = nil
    }
}
