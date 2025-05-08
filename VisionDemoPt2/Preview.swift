//
//  Preview.swift
//  CameraVisonFX
//
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation


struct Preview: UIViewControllerRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    let gravity: AVLayerVideoGravity
    
    init(session: AVCaptureSession, gravity: AVLayerVideoGravity) {
        self.gravity = gravity
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = PreviewViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        previewLayer.videoGravity = gravity
        uiViewController.view.layer.addSublayer(previewLayer)
        previewLayer.frame = uiViewController.view.bounds
        print("contentsRect = \(previewLayer.contentsRect)")
        print("contentsScale \(previewLayer.contentsScale)")
        print("bounds = \(previewLayer.bounds)")
        print("frame = \(previewLayer.frame)")
    }
    
    static func dismantleUIViewController(_ uiViewController: UIViewControllerType, coordinator: ()) {
        if let pLayer = uiViewController.view.layer.sublayers?.first {
            pLayer.removeFromSuperlayer()
        }
    }
    
    
}

class PreviewViewController: UIViewController {
    override func viewDidLayoutSubviews() {
        // ugly, but this is working
        // when a rotation happens, we need to reset the preview layer frame.
        // this works on the assumption that the preview layer is the first sublayer on the view.
        if let pLayer = view.layer.sublayers?.first {
            pLayer.frame = self.view.frame
        }
    }
}
