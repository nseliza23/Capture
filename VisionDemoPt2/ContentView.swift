//
//  ContentView.swift
//  VisionDemo
//
//  Created by student on 3/19/25.
//

import SwiftUI
import Vision

struct ContentView: View {
    @State var hero: Image?
    @State var captureImage: UIImage?
    
    let backgroundGradient = LinearGradient(
        colors: [Color.blue, Color.green],
        startPoint: .top, endPoint: .bottom) // from apple documentation
    
    var body: some View {
        ZStack {
//            Color.teal
//                .ignoresSafeArea()
//            Image("backgroundImage.webp")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .ignoresSafeArea()
            NavigationStack {
//                Color.teal
//                .ignoresSafeArea()
                VStack {
                    if let hero = hero {
                        hero
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    Text("Welcome to")
                    Text("Capture!")
                        .font(.custom("Helvetica", size: 34).weight(.black))
                        .padding(.bottom, 20)
                    NavigationLink(destination: {
                        CaptureView(captureImage: $captureImage)
                    }, label: {
                        Text("Face Detection")
                    })
                    //                .background(Color.green)
                    .tint(.green)
                    .padding(.bottom, 10)
                    .buttonStyle(.borderedProminent)
                    NavigationLink(destination: {
                        BarcodeDetectionView(captureImage: $captureImage)
                    }, label: {
                        Text("Barcode Scan")
                    })
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundGradient.ignoresSafeArea())
            }
            .onChange(of: captureImage) { _, newValue in
                if let newValue {
                    hero = Image(uiImage: newValue)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
