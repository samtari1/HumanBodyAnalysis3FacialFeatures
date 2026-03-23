//
//  ContentView.swift
//  HumanBodyAnalysis3FacialFeatures
//
//  Created by Quanpeng Yang on 3/22/26.
//
import SwiftUI
import Vision

struct ContentView: View {
    @State private var observations: [FaceObservation] = []
    let imageName = "faceup"
    
    // Default to a safe starting height
    @State private var calculatedHeight: CGFloat = 500

    var body: some View {
        VStack(spacing: 20) {
            Button("Detect Eyes") {
                Task {
                    await detectEyes()
                }
            }
            .buttonStyle(.borderedProminent)

            // 1. Wrap the Canvas in a ScrollView so it doesn't push the button away
            ScrollView {
                GeometryReader { geometry in
                    Canvas { context, size in
                        guard let uiImage = UIImage(named: imageName) else { return }
                        
                        let imageSize = uiImage.size
                        let screenWidth = geometry.size.width
                        
                        // 2. Calculate the correct height to maintain aspect ratio
                        let scale = screenWidth / imageSize.width
                        let height = imageSize.height * scale
                        
                        // Update the frame height on the main thread
                        Task { @MainActor in
                            if self.calculatedHeight != height {
                                self.calculatedHeight = height
                            }
                        }

                        let imageFrame = CGRect(origin: .zero, size: CGSize(width: screenWidth, height: height))
                        
                        // Draw Image
                        context.draw(Image(uiImage: uiImage), in: imageFrame)
                        
                        // Draw Dots
                        for observation in observations {
                            if let landmarks = observation.landmarks {
                                let eyeRegions = [landmarks.leftEyebrow, landmarks.rightEye]
                                for region in eyeRegions {
                                    let points = region.pointsInImageCoordinates(imageFrame.size, origin: .upperLeft)
                                    for point in points {
                                        let dotSize: CGFloat = 4
                                        let circleFrame = CGRect(x: point.x - 2, y: point.y - 2, width: dotSize, height: dotSize)
                                        context.fill(Circle().path(in: circleFrame), with: .color(.green))
                                    }
                                }
                            }
                        }
                    }
                }
                // 3. This height expands the scrollable area
                .frame(height: calculatedHeight)
            }
            .background(Color(.systemGray6)) // Optional: makes the image area distinct
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }

    func detectEyes() async {
        guard let uiImage = UIImage(named: imageName),
              let cgImage = uiImage.cgImage else { return }
        
        do {
            let request = DetectFaceLandmarksRequest()
            let results = try await request.perform(on: cgImage, orientation: .up)
            self.observations = results
        } catch {
            print("Error: \(error)")
        }
    }
}
