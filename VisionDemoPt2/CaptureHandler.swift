//
//  CaptureHandler.swift
//  CameraVisonFX
//
//

import Foundation
import SwiftUI
import AVFoundation
import Vision

@Observable
class CaptureHandler: NSObject {
    
    let session = AVCaptureSession()
    var preview: Preview?
    var landmarkResults: DetectFaceLandmarksRequest.Result = []
    
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var currentCaptureDevice: AVCaptureDevice?
    private var videoOutput = AVCaptureVideoDataOutput()
    var faceResults: [FaceObservation] = []
    
    
    private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var videoRotationAngleForHorizonLevelPreviewObservation: NSKeyValueObservation?
    var canvasFrame: CGRect = CGRect(x: 0, y: 0, width: 402, height: 536)
    
    var discovery: AVCaptureDevice.DiscoverySession?
    
    var photoCoordinator = PhotoCoordinator()
    
    var barcodeResults: [BarcodeObservation] = []
    private let barcodeDetector = BarcodeDetector()
//    @Published var scannedPayload: String?
    var onScannedPayloadUpdated: ((String?) -> Void)?
    var scannedPayload: String? = nil {
            didSet {
                onScannedPayloadUpdated?(scannedPayload)
            }
        }
    
    override init() {
        super.init() // NSObject init
        Task {
            await checkCameraPermission()
            configure()
        }
    }
    
    func start() {
        session.startRunning()
    }
    
    func stop() {
        session.stopRunning()
    }
    
    // Check to see if that app has permission to use the camera.
    // If it hasn't been determined, call requestPermission to ask the user.
    private func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // User has granted access to the camera.
            print("authorized to use camera")
            
        case .notDetermined:
            // The user has not yet been asked for camera access.
            await AVCaptureDevice.requestAccess(for: .video)
                
        // Combine the two other cases into the default case
        default:
            print("not yet authorized...")
        }
    }
    
    
    // Configure the Capture Session, setup the inputs and outputs.
    private func configure() {
        var readyToRun = false
        defer {
            session.commitConfiguration()
            if readyToRun {
                session.startRunning()
            }
        }
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        discoverCaptureDevices()
        
        preview = Preview(session: session, gravity: .resizeAspect)
        
        discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .unspecified)
        //guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if session.canAddInput(captureDeviceInput) {
            session.addInput(captureDeviceInput)
            videoDeviceInput = captureDeviceInput
            currentCaptureDevice = videoDevice
            
            //DispatchQueue.main.async { [self] in
                createDeviceRotationCoordinator()
                if let previewLayer = preview?.previewLayer {
                    let frame = previewLayer.frame
                    if frame.width < frame.height {
                        checkPreviewSize(orientation: .portrait)
                    }
                    else {
                        checkPreviewSize(orientation: .landscapeLeft)
                    }
                }
            //}
        }
        else {
            print("unable to add input to session")
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        session.addOutput(videoOutput)
        
        photoCoordinator.addPhotoOutputToSession(session: session, input: videoDeviceInput, rotationCoordinator: videoDeviceRotationCoordinator)
        
        //readyToRun = true
    }
    
    func changeCameraInput(device: AVCaptureDevice) {
        if let captureInput = session.inputs.first {
            session.removeInput(captureInput)
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: device) else {
            print("AVCaptureDeviceInput failed.")
            return
        }
        guard session.canAddInput(videoDeviceInput) else {
            print("canAddInput failed.")
            return
        }
        currentCaptureDevice = device
        session.addInput(videoDeviceInput)
        session.commitConfiguration()
        faceResults = []
    }
    
    func isCurrentInput(device: AVCaptureDevice) -> Bool{
        //
        return device.uniqueID == currentCaptureDevice?.uniqueID
    }
    
    private func createDeviceRotationCoordinator() {
        videoDeviceRotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDeviceInput.device, previewLayer: preview?.previewLayer)
        preview?.previewLayer.connection?.videoRotationAngle = videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelPreview
        
        videoRotationAngleForHorizonLevelPreviewObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { _, change in
            
            guard let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }
            self.preview?.previewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
        }
    }
    
    func checkPreviewSize(orientation: UIDeviceOrientation) {
        guard let activeFormat = currentCaptureDevice?.activeFormat else { return }
        print("videoDevice dimensions: \(activeFormat.formatDescription.dimensions)")
        guard let previewLayer = preview?.previewLayer else { return }
        let frame = previewLayer.frame
        print("frame: \(frame)")
        
        let captureW = Double(activeFormat.formatDescription.dimensions.width)
        let captureH = Double(activeFormat.formatDescription.dimensions.height)
        let aspectRatio = captureW / captureH
        
        if orientation == .portrait || orientation == .portraitUpsideDown {
            let w = min(frame.width, frame.height)
            let frameH = max(frame.width, frame.height)
            let h = w * aspectRatio
            let x = 0.0
            let y = (frameH - h) / 2.0
            canvasFrame = CGRect(x: x, y: y, width: w, height: h)
        }
        else {
            let h = min(frame.width, frame.height)
            let frameW = max(frame.width, frame.height)
            let w = h * aspectRatio
            let x = (frameW - w) / 2.0
            let y = 0.0
            canvasFrame = CGRect(x: x, y: y, width: w, height: h)
        }
        
        print("canvasFrame = \(canvasFrame)")
    }
    
}


extension CaptureHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // delegate method for capture, this method recieves the pixels for one frame.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        Task {
            try await detectFace(sampleBuffer: sampleBuffer)
            //            try await detectBarcodes(sampleBuffer: sampleBuffer)
        }
        
    }
    
    
    func detectFace(sampleBuffer: CMSampleBuffer) async throws {
        let detectFacesRequest = DetectFaceRectanglesRequest()
        var landmarksRequest = DetectFaceLandmarksRequest()
        
        let handler = ImageRequestHandler(sampleBuffer)
        let faceObservations = try await handler.perform(detectFacesRequest)
        
        landmarksRequest.inputFaceObservations = faceObservations
        let landmarksResults = try await handler.perform(landmarksRequest)
        
        if landmarksResults.count > 0 {
            self.landmarkResults = landmarksResults
        }
        faceResults = landmarksResults
    }
    
    func detectBarcodes(sampleBuffer: CMSampleBuffer) async throws {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }
        let results = try await barcodeDetector.detectBarcodes(in: pixelBuffer)
        
        DispatchQueue.main.async {
            self.barcodeResults = results
            if !results.isEmpty {
                if let bestResult = results.first, let payload = bestResult.payloadString {
                    self.scannedPayload = payload
                }
                else {
                    self.scannedPayload = "Unable to extract information from data."
                    //          }
                }
            }
        }
    }
}

