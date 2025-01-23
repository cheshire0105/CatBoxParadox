//import UIKit
//import AVFoundation
//import Vision
//
//class ViewController: UIViewController {
//
//    // MARK: - UI Components
//    private let boxLabel = UILabel()
//    private let catStateLabel = UILabel()
//    private let resetButton = UIButton()
//    private let instructionLabel = UILabel()
//
//    // MARK: - Properties
//    private let captureSession = AVCaptureSession()
//    private var isCatAlive: Bool?
//    private var isUserLooking = false
//    private var lastDetectionTime = Date()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCamera()
//        resetExperiment()
//    }
//
//    // MARK: - UI Setup
//    private func setupUI() {
//        view.backgroundColor = .black
//
//        // Box Label
//        boxLabel.text = "📦"
//        boxLabel.font = UIFont.systemFont(ofSize: 100)
//        boxLabel.textAlignment = .center
//
//        // Cat State Label
//        catStateLabel.font = UIFont.boldSystemFont(ofSize: 40)
//        catStateLabel.textAlignment = .center
//        catStateLabel.textColor = .white
//
//        // Reset Button
//        resetButton.setTitle("RESET", for: .normal)
//        resetButton.backgroundColor = .systemBlue
//        resetButton.layer.cornerRadius = 8
//        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
//
//        // Instruction Label
//        instructionLabel.text = "화면을 응시해 고양이의 운명을 확인하세요!"
//        instructionLabel.textColor = .white
//        instructionLabel.textAlignment = .center
//
//        // Stack View
//        let stackView = UIStackView(arrangedSubviews: [boxLabel, catStateLabel, instructionLabel, resetButton])
//        stackView.axis = .vertical
//        stackView.spacing = 20
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            resetButton.widthAnchor.constraint(equalToConstant: 120),
//            resetButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//
//    // MARK: - Actions
//    @objc private func resetButtonTapped() {
//        resetExperiment()
//    }
//}
//
//// MARK: - Camera & Vision Setup
//extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//    private func setupCamera() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
//                    throw NSError(domain: "CameraError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No front camera"])
//                }
//
//                let input = try AVCaptureDeviceInput(device: device)
//                if self.captureSession.canAddInput(input) {
//                    self.captureSession.addInput(input)
//                }
//
//                let output = AVCaptureVideoDataOutput()
//                if self.captureSession.canAddOutput(output) {
//                    self.captureSession.addOutput(output)
//                }
//
//                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//                self.captureSession.startRunning()
//
//            } catch {
//                DispatchQueue.main.async {
//                    self.instructionLabel.text = "카메라 초기화 실패 😢"
//                }
//                print("Camera setup error: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            print("Failed to get pixel buffer")
//            return
//        }
//
//        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
//            if let error = error {
//                print("Face detection failed: \(error.localizedDescription)")
//                return
//            }
//
//            guard let results = request.results as? [VNFaceObservation] else {
//                print("No face results")
//                return
//            }
//
//            print("Detected \(results.count) faces")
//
//            // Safely handle optional results.first
//            guard let firstFace = results.first else {
//                self?.handleNoFaceDetected()
//                return
//            }
//
//            self?.checkEyes(for: firstFace)
//        }
//
//        do {
//            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
//            try handler.perform([request])
//        } catch {
//            print("Vision request failed: \(error)")
//        }
//    }
//}
//
//// MARK: - Eye Detection Logic
//extension ViewController {
//    private func checkEyes(for face: VNFaceObservation) {
//        guard let leftEye = face.landmarks?.leftEye,
//              let rightEye = face.landmarks?.rightEye else {
//            handleNoFaceDetected()
//            return
//        }
//
//        let leftEyePoints = leftEye.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
//        let rightEyePoints = rightEye.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
//
//        let leftEyeOpen = leftEyePoints.isEyeOpen
//        let rightEyeOpen = rightEyePoints.isEyeOpen
//
//        DispatchQueue.main.async {
//            if leftEyeOpen && rightEyeOpen {
//                self.handleUserLooking()
//            } else {
//                self.handleUserNotLooking()
//            }
//        }
//    }
//
//    private func handleUserLooking() {
//        guard !isUserLooking, Date().timeIntervalSince(lastDetectionTime) > 3 else { return }
//
//        isUserLooking = true
//        lastDetectionTime = Date()
//        openBoxWithQuantumEffect()
//    }
//
//    private func handleUserNotLooking() {
//        isUserLooking = false
//    }
//
//    private func handleNoFaceDetected() {
//        DispatchQueue.main.async {
//            self.instructionLabel.text = "👀 얼굴을 찾을 수 없어요!"
//        }
//    }
//}
//
//
//
//// MARK: - Animation & Effects
//extension ViewController {
//    private func openBoxWithQuantumEffect() {
//        let isAlive = Bool.random()
//        isCatAlive = isAlive
//
//        UIView.animate(withDuration: 0.5, animations: {
//            self.boxLabel.transform = CGAffineTransform(scaleX: 1.2, y: 0.8)
//        }) { _ in
//            UIView.animate(withDuration: 0.5) {
//                self.boxLabel.transform = .identity
//                self.boxLabel.text = "🎁"
//                self.catStateLabel.text = isAlive ? "🐈 살아있다!" : "💀 죽었다..."
//                self.instructionLabel.text = isAlive ? "고양이가 살아있어요! 😻" : "유감이에요... 😿"
//
//                // 상태 초기화 추가
//                self.isUserLooking = false
//                self.lastDetectionTime = Date()
//            }
//        }
//    }
//
//    private func resetExperiment() {
//        UIView.animate(withDuration: 0.3) {
//            self.boxLabel.text = "📦"
//            self.catStateLabel.text = ""
//            self.instructionLabel.text = "화면을 응시해 고양이의 운명을 확인하세요!"
//        }
//        // 상태 변수 초기화 추가
//        isCatAlive = nil
//        isUserLooking = false
//        lastDetectionTime = Date()
//
//        // 카메라 세션 재시작 보장
//        if !captureSession.isRunning {
//            DispatchQueue.global(qos: .userInitiated).async {
//                self.captureSession.startRunning()
//            }
//        }
//    }
//}
//// MARK: - Eye Open Detection Extension
//extension Array where Element == CGPoint {
//    var isEyeOpen: Bool {
//        guard count >= 6 else {
//            print("Invalid eye points count: \(count)")
//            return false
//        }
//
//        let upperLidY = self[1].y
//        let lowerLidY = self[4].y // 5번 인덱스 → 4번으로 수정
//        let eyeHeight = abs(upperLidY - lowerLidY)
//
//        print("Eye height: \(eyeHeight)")
//        return eyeHeight > 0.025 // 값 조정 (0.03 → 0.025)
//    }
//}
//
