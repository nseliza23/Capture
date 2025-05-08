//
//  PhotoCatcher.swift
//  VisionDemo
//
//  Created by student on 4/2/25.
//

import Foundation
import AVFoundation
import Photos
import UIKit

class PhotoCatcher: NSObject, AVCapturePhotoCaptureDelegate {
    var settings: AVCapturePhotoSettings
    var photoData: Data?
    var photo: UIImage?
    var photoOrientation: UIImage.Orientation
    
    init(settings: AVCapturePhotoSettings, photoData: Data? = nil) {
        self.settings = settings
        self.photoData = nil
        self.photoOrientation = .up
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        print("didFinishProcessingPhoto")
        if let error = error {
            print(error.localizedDescription)
            return
        }
        photoOrientation = imageOrientation(from: photo.metadata)
        photoData = photo.fileDataRepresentation()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        print("save to photo library now!")
        Task {
//            await savePhotoDataToPhotoLibrary(resolvedSettings: resolvedSettings)
            saveAsUIImage()
        }
    }
    
    func saveAsUIImage() {
        guard let data = photoData else {
            print("data is nil?")
            return
        }
        
        guard let capturedData = UIImage(data: data) else {
            print("problem with UIImage init?")
            return
        }
        
        if let cgPhoto = capturedData.cgImage {
            photo = UIImage(cgImage: cgPhoto, scale: 1.0, orientation: photoOrientation)
        }
    }
    
    func savePhotoDataToPhotoLibrary(resolvedSettings: AVCaptureResolvedPhotoSettings) async {
        guard let data = photoData else {
            print("data is nil?")
            return
        }
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        if status == .authorized || status == .limited {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let options = PHAssetResourceCreationOptions()
                    options.uniformTypeIdentifier = self.settings.processedFileType.map { $0.rawValue }
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    var resourceType = PHAssetResourceType.photo
                    if (resolvedSettings.deferredPhotoProxyDimensions.width > 0) &&
                        (resolvedSettings.deferredPhotoProxyDimensions.height > 0) {
                        resourceType = PHAssetResourceType.photoProxy
                    }
                    creationRequest.addResource(with: resourceType, data: data, options: options)
                }
            }
            catch {
                print(error)
                return
            }
        }
        else {
            print("not authorized to access photo library")
        }
    }
}

