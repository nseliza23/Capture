//
//  PhotoCoordinator.swift
//  VisionDemo
//
//  Created by student on 4/2/25.
//

import Foundation
import AVFoundation

class PhotoCoordinator {
    var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var activePhotoSettings = AVCapturePhotoSettings()
    private let photoQueue = DispatchQueue(label: "photoQueue")
    var catcher: PhotoCatcher! = PhotoCatcher(settings: AVCapturePhotoSettings())
    
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings(from: activePhotoSettings)
        let videoRotationAngle = videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelCapture
        
        photoQueue.async { [self] in
            if let photoOutputConnection = photoOutput.connection(with: .video) {
                photoOutputConnection.videoRotationAngle = videoRotationAngle
                
                catcher = PhotoCatcher(settings: photoSettings)
                photoOutput.capturePhoto(with: photoSettings, delegate: catcher)
            }
        }
    }
    
    func addPhotoOutputToSession(session: AVCaptureSession, input: AVCaptureDeviceInput, rotationCoordinator: AVCaptureDevice.RotationCoordinator) {
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            videoDeviceInput = input
            videoDeviceRotationCoordinator = rotationCoordinator
            configurePhotoOutput()
        }
        else {
            print("unable to add PhotoOutput to AVCaptureSession")
        }
    }
    
    func configurePhotoOutput() {
        photoOutput.maxPhotoQualityPrioritization = .quality
        photoOutput.isResponsiveCaptureEnabled = photoOutput.isResponsiveCaptureSupported
        photoOutput.isFastCapturePrioritizationEnabled = photoOutput.isFastCapturePrioritizationSupported
//        photoOutput.isAutoDeferredPhotoDeliveryEnabled = photoOutput.isAutoDeferredPhotoDeliverySupported
        
        activePhotoSettings = resetPhotoSettings()
    }
    
    func resetPhotoSettings() -> AVCapturePhotoSettings {
        var photoSettings = AVCapturePhotoSettings()
        // capture HEIF photos when supported
        if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        
        return photoSettings
    }
    
}
