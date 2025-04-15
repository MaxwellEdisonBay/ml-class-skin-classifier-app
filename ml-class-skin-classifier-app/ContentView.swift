import SwiftUI
import UIKit
import AVFoundation
import ConfettiSwiftUI

struct ContentView: View {
    @State private var selectedImage: Image? = nil
    @State private var uiImage: UIImage? = nil
    @State private var predictionResult: String = "Select an image"
    @State private var showCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var cameraError: Error? = nil
    @State private var showingCameraErrorAlert = false
    @State private var isShowingImagePicker = false
    @State private var showFullCamera = false
    @State private var isPredicting = false
    @State private var confettiTrigger: Int = 0 // Use ConfettiSwiftUI's trigger
    @State private var sadConfettiTrigger: Int = 0
    @State private var resultTextScale: CGFloat = 1.0
    @State private var resultTextOpacity: Double = 1.0
    
    // Backend URL
    let backendURL = URL(string: "http://142.93.66.195:5000/api/predict")!
    
    // Custom colors
    let primaryColor = Color(red: 0.56, green: 0.78, blue: 0.92)
    let secondaryColor = Color(red: 0.91, green: 0.67, blue: 0.63)
    let accentColor = Color(red: 0.94, green: 0.80, blue: 0.61)
    
    // Threshold for malignancy
    let malignancyThreshold = 0.3
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [primaryColor, secondaryColor]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Image Display
                if let selectedImage = selectedImage {
                    selectedImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .animation(.easeInOut(duration: 0.5), value: selectedImage)
                } else {
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                        .frame(width: 200, height: 200)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                
                // Prediction Result Text
                Text(predictionResult)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding()
                    .multilineTextAlignment(.center)
                    .scaleEffect(resultTextScale)
                    .opacity(resultTextOpacity)
                    .animation(.easeInOut(duration: 1), value: resultTextScale) // Apply animation here
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.7))
                            .shadow(color: Color.gray.opacity(0.1), radius: 3, x: 0, y: 2)
                    )
                
                // Button HStack
                HStack {
                    Button(action: {
                        sourceType = .photoLibrary
                        isShowingImagePicker = true
                    }) {
                        Text("Select Image")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(accentColor)
                                    .shadow(color: accentColor.opacity(0.5), radius: 5, x: 0, y: 3)
                            )
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        sourceType = .camera
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showFullCamera = true
                        } else {
                            cameraError = NSError(domain: "CameraError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Camera not available."])
                            showingCameraErrorAlert = true
                        }
                    }) {
                        Text("Take Photo")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(accentColor)
                                    .shadow(color: accentColor.opacity(0.5), radius: 5, x: 0, y: 3)
                            )
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showingCameraErrorAlert) {
                        Alert(
                            title: Text("Camera Error"),
                            message: Text(cameraError?.localizedDescription ?? "An unknown error occurred."),
                            dismissButton: .default(Text("OK")) {
                                showingCameraErrorAlert = false
                                cameraError = nil
                            }
                        )
                    }
                }
                .padding(.top, 10)
                
                // Show Activity Indicator
                if isPredicting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 3)
                }
            }
            .padding()
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePickerView(selectedImage: $uiImage, sourceType: $sourceType, cameraError: $cameraError, showingCameraErrorAlert: $showingCameraErrorAlert) { image in
                    if let image = image {
                        self.uiImage = image
                        self.selectedImage = Image(uiImage: image)
                        predictImage(image: image)
                    }
                    isShowingImagePicker = false
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showFullCamera) {
                FullCameraView(
                    selectedImage: $uiImage,
                    cameraError: $cameraError,
                    showingCameraErrorAlert: $showingCameraErrorAlert,
                    onImageTaken: { image in
                        if let image = image {
                            self.uiImage = image
                            self.selectedImage = Image(uiImage: image)
                            predictImage(image: image)
                        }
                        showFullCamera = false
                    }
                )
                .ignoresSafeArea()
            }
        }
        .confettiCannon(trigger: $confettiTrigger,  // Attach to the trigger
                        confettis: [.shape(.circle), .shape(.triangle), .shape(.square), .text("🎉"), .text("🥳"), .text("🤩")], // Use an array of Confetti
                        colors: [.red, .green, .blue, .yellow, .purple, .orange, .pink, .white],
                        confettiSize: 20,
                        repetitions: 15,
                        repetitionInterval: 0.05
                       )
        .confettiCannon(trigger: $sadConfettiTrigger,
                        confettis: [.text("😢"), .text("😥"), .text("😓")],
                        colors: [.gray, .black, .brown],
                        confettiSize: 30,
                        repetitions: 1,
                        repetitionInterval: 0.5
                       )
    }
    
    // Define a struct to represent the JSON response
    struct PredictionResponse: Codable {
        let status: String
        let message: String
        let probability: Double?
    }
    
    func predictImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            predictionResult = "Error: Could not convert image to JPEG."
            return
        }
        
        isPredicting = true
        predictionResult = "Predicting..."
        
        // Create a multipart/form-data request
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add the image data to the body
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add the closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isPredicting = false
                if let error = error {
                    print("Error: \(error)")
                    self.predictionResult = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Invalid response: \(String(describing: response))")
                    self.predictionResult = "Error: Invalid server response (\(statusCode))."
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    self.predictionResult = "Error: No data received from server."
                    return
                }
                
                do {
                    // Decode the JSON response
                    let decoder = JSONDecoder()
                    let predictionResponse = try decoder.decode(PredictionResponse.self, from: data)
                    
                    // Handle the response based on the status and probability
                    if predictionResponse.status == "success" {
                        if let probability = predictionResponse.probability {
                            if probability > self.malignancyThreshold {
                                self.predictionResult = "High probability of malignancy.  See a doctor."
                                self.sadConfettiTrigger += 1
                            } else {
                                self.predictionResult = "You have no cancer! Your skin is healthy!"
                                // Trigger confetti and animate text
                                withAnimation(.easeInOut(duration: 0.7)) {
                                    self.resultTextScale = 1.3
                                    self.resultTextOpacity = 0.0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    self.confettiTrigger += 1
                                    withAnimation(.easeInOut(duration: 0.7)) {
                                        self.resultTextScale = 1.0
                                        self.resultTextOpacity = 1.0
                                    }
                                }
                            }
                        } else {
                            self.predictionResult = predictionResponse.message
                        }
                    } else if predictionResponse.status == "error" {
                        self.predictionResult = "Error: \(predictionResponse.message)"
                        self.sadConfettiTrigger += 1
                    } else {
                        self.predictionResult = "Error: Unexpected status: \(predictionResponse.status)"
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                    self.predictionResult = "Error decoding server response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct FullCameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var cameraError: Error?
    @Binding var showingCameraErrorAlert: Bool
    var onImageTaken: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update the view controller.  In this case, there's nothing specific to update.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onImageTaken: onImageTaken)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: FullCameraView
        let onImageTaken: (UIImage?) -> Void
        
        init(_ parent: FullCameraView, onImageTaken: @escaping (UIImage?) -> Void) {
            self.parent = parent
            self.onImageTaken = onImageTaken
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageTaken(image)
            } else {
                parent.onImageTaken(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.onImageTaken(nil)
            }
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFailWithError error: Error) {
            parent.cameraError = error
            parent.showingCameraErrorAlert = true
            picker.dismiss(animated: true) {
                self.onImageTaken(nil)
            }
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var sourceType: UIImagePickerController.SourceType
    @Binding var cameraError: Error?
    @Binding var showingCameraErrorAlert: Bool
    var completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        //Update the view controller.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, completion: completion)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        let completion: (UIImage?) -> Void
        
        init(_ parent: ImagePickerView, completion: @escaping (UIImage?) -> Void) {
            self.parent = parent
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                completion(image)
            } else {
                completion(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            completion(nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFailWithError error: Error) {
            parent.cameraError = error
            parent.showingCameraErrorAlert = true
            picker.dismiss(animated: true) {
                self.completion(nil)
            }
        }
    }
}
