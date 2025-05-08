//
//  VisionHelpers.swift
//  CameraVisonFX
//
//

import Foundation
import SwiftUI
import Vision


struct BoundingBox2: Shape {
    private let normalizedRect: NormalizedRect
    private let canvasRect: CGRect
    
    init(observation: any BoundingBoxProviding, canvasFrame: CGRect, orientation: UIDeviceOrientation) {
        normalizedRect = observation.boundingBox
        canvasRect = rectOnCanvas(rect: normalizedRect, canvasFrame: canvasFrame, orientation: orientation)
    }
    
    func path(in rect: CGRect) -> Path {
        return Path(canvasRect)
    }
}

struct FaceLandmark: Shape {
    let region: FaceObservation.Landmarks2D.Region
    let points: [CGPoint]
    
    init(region: FaceObservation.Landmarks2D.Region, boundingBox: NormalizedRect, canvasFrame: CGRect, orientation: UIDeviceOrientation) {
        self.region = region
        self.points = pointsOnCanvas(region: region, boundingBox: boundingBox, canvasFrame: canvasFrame, orientation: orientation)
    }
    
    
    func path(in rect: CGRect) -> Path {
        let path = CGMutablePath()
        
        path.move(to: points[0])
        
        for index in 1..<points.count {
            path.addLine(to: points[index])
        }
        
        if region.pointsClassification == .closedPath {
            path.closeSubpath()
        }
        
        return Path(path)
    }
}


func rectOnCanvas(rect: NormalizedRect, canvasFrame: CGRect, orientation: UIDeviceOrientation) -> CGRect {
    if orientation == .portrait || orientation == .portraitUpsideDown {
        let maxY = 1.0 - rect.cgRect.minY
        let minY = 1.0 - rect.cgRect.maxY
        let newH = maxY - minY
        let x = canvasFrame.minX + minY * canvasFrame.width
        let y = canvasFrame.minY + rect.cgRect.minX * canvasFrame.height
        let w = newH * canvasFrame.width
        let h = rect.width * canvasFrame.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
    else if orientation == .landscapeLeft {
        let maxY = 1.0 - rect.cgRect.minY
        let minY = 1.0 - rect.cgRect.maxY
        let newH = maxY - minY
        let x = canvasFrame.maxX - (1.0 - rect.cgRect.minX) * canvasFrame.width
        let y = canvasFrame.minY + (1.0 - maxY) * canvasFrame.height
        let w = rect.width * canvasFrame.width
        let h = newH * canvasFrame.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
    else {
        // landscapeRight
        let x = canvasFrame.maxX - rect.cgRect.maxX * canvasFrame.width
        let y = canvasFrame.minY + (1.0 - rect.cgRect.maxY) * canvasFrame.height
        let w = rect.width * canvasFrame.width
        let h = rect.height * canvasFrame.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}


func pointsOnCanvas(region: FaceObservation.Landmarks2D.Region, boundingBox: NormalizedRect, canvasFrame: CGRect, orientation: UIDeviceOrientation) -> [CGPoint] {
    let frame = rectOnCanvas(rect: boundingBox, canvasFrame: canvasFrame, orientation: orientation)
    if orientation == .portrait || orientation == .portraitUpsideDown {
        return region.points.map { point in
            let x = frame.minX + (1.0 - point.y) * frame.width
            let y = frame.minY + point.x * frame.height
            return CGPoint(x: x, y: y)
        }
    }
    else if orientation == .landscapeLeft {
        return region.points.map { point in
            let x = frame.minX + point.x * frame.width
            let y = frame.minY + point.y * frame.height
            return CGPoint(x: x, y: y)
        }
    }
    else {
        // landscapeRight
        return region.points.map { point in
            let x = frame.minX + (1.0 - point.x) * frame.width
            let y = frame.minY + (1.0 - point.y) * frame.height
            return CGPoint(x: x, y: y)
        }
    }
}

