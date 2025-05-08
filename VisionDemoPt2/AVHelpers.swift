//
//  AVHelpers.swift
//  CameraVisonFX
//
//


import Foundation
import SwiftUI
import AVFoundation

let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInTripleCamera, .builtInDualWideCamera, .builtInTrueDepthCamera, .builtInLiDARDepthCamera]


// Find out what cameras exist on the current device.
func discoverCaptureDevices() -> AVCaptureDevice.DiscoverySession {
    let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .unspecified)
    print("DiscoverySession found \(discovery.devices.count) cameras")
    for device in discovery.devices {
        print("-------------------")
        print("uniqueID: \(device.uniqueID)")
        print("modelID: \(device.modelID)")
        print("name: \(device.localizedName)")
        print("manufacturer: \(device.manufacturer)")
        print("device type: \(device.deviceType.rawValue)")
        switch device.position {
            case .front:
                print("device position: front")
            case .back:
                print("device position: back")
            case .unspecified:
                print("device position: unspecified")
            default:
                print("device position: unknown")
        }
    }
    return discovery
}


func imageOrientation(from metadata: [String: Any]) -> UIImage.Orientation {
    if let orientationValue = metadata[kCGImagePropertyOrientation as String] as? UInt32 {
        return imageOrientation(fromEXIFOrientation: orientationValue)
    }
    return .right
}


func imageOrientation(fromEXIFOrientation exifOrientation: UInt32) -> UIImage.Orientation {
    switch exifOrientation {
    case 1: return .up
    case 3: return .down
    case 8: return .left
    case 6: return .right
    case 2: return .upMirrored
    case 4: return .downMirrored
    case 5: return .leftMirrored
    case 7: return .rightMirrored
    default: return .up
    }
}
