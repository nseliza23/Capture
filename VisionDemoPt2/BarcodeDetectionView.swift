//
//  BarcodeDetectionView.swift
//  VisionDemoPt2
//
//  Created by student on 4/9/25.
//

import SwiftUI
import Vision

struct BarcodeDetectionView: View { // make changes to CaptureView so that it is for barcode detection
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var capture = BarcodeHandler()
    @Environment(\.dismiss) private var dismiss
    @Binding var captureImage: UIImage?
    @State private var displayedPayload: String? = nil
    
    var body: some View {
        ZStack {
            Color.black
            if let preview = capture.preview {
                preview.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .overlay {
                        ForEach(capture.barcodeResults, id: \.self) { barcode in
                            BoundingBox2(observation: barcode as! BoundingBoxProviding, canvasFrame: capture.canvasFrame, orientation: orientation)
                                    .stroke(.green, lineWidth: 2)
                        }
                    }
            }
            if let payload = displayedPayload {
                VStack {
                    Spacer()
                    Text(payload)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            orientation = UIDevice.current.orientation
            capture.onScannedPayloadUpdated = { newPayload in
                    displayedPayload = newPayload
            }
            DispatchQueue.global().async {
                capture.start()
                capture.checkPreviewSize(orientation: orientation)
            }
        }
        .onRotate { newOrientation in
            orientation = newOrientation
            capture.checkPreviewSize(orientation: orientation)
        }
        .onChange(of: capture.photoCoordinator.catcher.photo) { _, newValue in
            captureImage = newValue
            dismiss()
        }
        .alert("Scanned Info", isPresented: Binding<Bool> (
            get: { capture.scannedPayload != nil },
            set: { _ in capture.scannedPayload = nil }
        )) {
            Button("OK", role: .cancel) { } // when ok is clicked, the message goes away - should implement a version where it takes to the url
        } message: {
            if let payload = capture.scannedPayload {
                Text(payload)
            }
        }
        .toolbar(.hidden, for: .tabBar, .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar, content: {
                Button(action: {
                    capture.stop()
                    dismiss()
                }, label: {
                    Text("Cancel")
                })
                Spacer()
                Button(action: {
                    // take a picture
                    capture.photoCoordinator.capturePhoto()
                }, label: {
                    Image(systemName: "camera.circle")
                        .font(.largeTitle)
                })
                Spacer()
                Menu(content: {
                    ForEach(capture.discovery?.devices ?? [], id: \.uniqueID) { device in
                        Button(action: {
                            capture.changeCameraInput(device: device)
                        }, label: {
                            if capture.isCurrentInput(device: device) {
                                Label(device.localizedName, systemImage: "camera.fill")
                            }
                            else {
                                Label(device.localizedName, systemImage: "camera")
                            }
                        })
                    }
                }, label: {
                    Label("Camera Menu", systemImage: "arrow.triangle.2.circlepath.camera")
                })
                
            })
        }
    }
}

//#Preview {
//    BarcodeDetectionView()
//}
