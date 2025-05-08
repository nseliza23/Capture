//
//  BarcodeDetector.swift
//  VisionDemoPt2
//
//  Created by student on 4/7/25.
//

import SwiftUI
import Foundation
import Vision
import AVFoundation

class BarcodeDetector {
    var symbologies: [BarcodeSymbology] = [.qr, .ean13, .code128]
    
    func detectBarcodes(in pixelBuffer: CVPixelBuffer) async throws -> [BarcodeObservation] {
        var request = DetectBarcodesRequest()
        request.symbologies = symbologies
        return try await request.perform(on: pixelBuffer)
    }
}

//#Preview {
//    BarcodeDetector()
//}
