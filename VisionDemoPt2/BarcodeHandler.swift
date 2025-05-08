//
//  BarcodeHandler.swift
//  VisionDemoPt2
//
//  Created by student on 4/9/25.
//

import SwiftUI
import AVFoundation

// only barcode detection, no face detection.
class BarcodeHandler: CaptureHandler {
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        Task {
            try await detectBarcodes(sampleBuffer: sampleBuffer)
        }
    }
}
