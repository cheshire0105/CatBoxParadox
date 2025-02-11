import UIKit
import SwiftUI
import ARKit
import AudioToolbox
import AVFoundation

// MARK: - QuizQuestion 모델 (퀴즈 문제 데이터)
struct QuizQuestion {
    let question: String
    let choices: [String]
    let correctAnswerIndex: Int
    let explanation: String
}

class QuantumCatViewController: UIViewController {

    // MARK: - UI Components (기존 디자인 유지)
    private let quantumContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let quantumBoxImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "box")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.systemTeal.cgColor
        imageView.layer.shadowRadius = 15
        imageView.layer.shadowOpacity = 0.7
        imageView.layer.shadowOffset = .zero
        return imageView
    }()

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false // 이 줄 추가!!!
        button.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        button.tintColor = .systemTeal
        button.backgroundColor = .black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 20
        button.layer.borderColor = UIColor.systemTeal.cgColor
        button.layer.borderWidth = 1
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.5
        button.addTarget(self, action: #selector(showQuantumTutorial), for: .touchUpInside)
        return button
    }()

    private let quantumGlowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.systemTeal.withAlphaComponent(0.3).cgColor,
                        UIColor.clear.cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.type = .radial
        return layer
    }()

    private let catImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "cat-box")
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let emptyBoxImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "empty-box")
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let quantumStateLabel: GradientLabel = {
        let label = GradientLabel()
        label.text = """
            📦 Mysterious Quantum Box!
            (Cats can exist in multiple places at once)
            """
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.gradientColors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        return label
    }()

    private let observerEffectLabel: UILabel = {
        let label = UILabel()
        label.text = """
          👀 Stare at the box for 3 seconds to
          collapse the cat's quantum state!
          
          This is called the 'Observer Effect' -
          our mere observation determines
          the cat's final state!
          """
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemTeal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("🔮 Reset Experiment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.systemTeal.cgColor
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(resetQuantumExperiment), for: .touchUpInside)
        return button
    }()

    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 80, weight: .bold)
        label.textColor = .systemTeal
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    // MARK: - Face Detection Properties
    private let captureSession = AVCaptureSession()
    private var faceDetectionTimer: Timer?
    private var detectionStartTime: Date?
    private var boxOpenAnimator: UIViewPropertyAnimator?

    // MARK: - Quiz Properties
    private var quizQuestions: [QuizQuestion] = []
    private var currentQuizIndex: Int = 0

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBoxIdleAnimation()
        setupCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureQuantumUI()
        resetQuantumExperiment()
    }

    // MARK: - UI Configuration (기존 디자인 유지)
    private func configureQuantumUI() {
        view.backgroundColor = .black

        let backgroundView = GradientView()
        backgroundView.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1).cgColor
        ]
        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)
        view.addSubview(infoButton)
        view.bringSubviewToFront(infoButton)

        quantumContainer.layer.addSublayer(quantumGlowLayer)
        quantumContainer.addSubview(quantumBoxImageView)
        view.addSubview(quantumContainer)
        quantumContainer.addSubview(catImageView)
        quantumContainer.addSubview(emptyBoxImageView)

        let stackView = UIStackView(arrangedSubviews: [
            quantumStateLabel,
            observerEffectLabel,
            resetButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        view.addSubview(countdownLabel)

        NSLayoutConstraint.activate([
            quantumContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quantumContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            quantumContainer.widthAnchor.constraint(equalToConstant: 250),
            quantumContainer.heightAnchor.constraint(equalToConstant: 250),

            quantumBoxImageView.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            quantumBoxImageView.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor, constant: 40),
            quantumBoxImageView.widthAnchor.constraint(equalToConstant: 400),
            quantumBoxImageView.heightAnchor.constraint(equalToConstant: 400),

            stackView.topAnchor.constraint(equalTo: quantumContainer.bottomAnchor, constant: 30),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            resetButton.heightAnchor.constraint(equalToConstant: 50),
            resetButton.widthAnchor.constraint(equalToConstant: 250),

            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -200),

            catImageView.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            catImageView.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor, constant: 40),
            catImageView.widthAnchor.constraint(equalToConstant: 400),
            catImageView.heightAnchor.constraint(equalToConstant: 400),

            emptyBoxImageView.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            emptyBoxImageView.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor, constant: 40),
            emptyBoxImageView.widthAnchor.constraint(equalToConstant: 400),
            emptyBoxImageView.heightAnchor.constraint(equalToConstant: 400),

            infoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            infoButton.widthAnchor.constraint(equalToConstant: 40),
            infoButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Camera Setup
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showAlert(message: "This device does not support camera")
            return
        }

        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: .main)

        if captureSession.canAddInput(input) && captureSession.canAddOutput(output) {
            captureSession.addInput(input)
            captureSession.addOutput(output)
            output.metadataObjectTypes = [.face]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)

        captureSession.startRunning()
    }

    // MARK: - Animation
    private func startBoxIdleAnimation() {
        let shake = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        shake.values = [-0.05, 0.05, -0.03, 0.03, 0]
        shake.keyTimes = [0, 0.25, 0.5, 0.75, 1]
        shake.duration = 2
        shake.repeatCount = .infinity
        quantumBoxImageView.layer.add(shake, forKey: "boxShake")

        let glow = CABasicAnimation(keyPath: "opacity")
        glow.fromValue = 0.3
        glow.toValue = 0.8
        glow.duration = 1.5
        glow.autoreverses = true
        glow.repeatCount = .infinity
        quantumGlowLayer.add(glow, forKey: "glowPulse")
    }

    // MARK: - Face Detection Handling
    private func startCountdown() {
        detectionStartTime = Date()

        faceDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let startTime = self.detectionStartTime else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, 3 - Int(elapsed))
                self.countdownLabel.text = remaining > 0 ? "\(remaining)" : ""
                if elapsed >= 3 {
                    self.faceDetectionTimer?.invalidate()
                    self.collapseWaveFunction()
                }
            }
        }
        RunLoop.main.add(faceDetectionTimer!, forMode: .common)
    }

    // MARK: - Quantum Interaction Logic
    @objc private func resetQuantumExperiment() {
        boxOpenAnimator?.stopAnimation(true)
        quantumBoxImageView.layer.removeAllAnimations()
        quantumBoxImageView.transform = .identity
        quantumBoxImageView.alpha = 1.0
        quantumBoxImageView.isHidden = false

        [catImageView, emptyBoxImageView].forEach {
            $0.isHidden = true
            $0.alpha = 0.0
        }

        quantumStateLabel.text = """
            📦 Mysterious Quantum Box!
            (Cats can exist in multiple places at once)
            """
        countdownLabel.text = ""
        startBoxIdleAnimation()
        captureSession.startRunning()

        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    private func collapseWaveFunction() {
        let isPresent = Bool.random()
        playSoundEffect(name: "quantum_collapse")
        boxOpenAnimator?.stopAnimation(true)
        boxOpenAnimator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.6) {
            self.quantumBoxImageView.transform = CGAffineTransform(scaleX: 1.8, y: 0.2)
            self.quantumBoxImageView.alpha = 0.5
        }
        boxOpenAnimator?.addCompletion { _ in
            self.quantumBoxImageView.isHidden = true
            self.captureSession.stopRunning()
            self.faceDetectionTimer?.invalidate()
            self.detectionStartTime = nil

            if isPresent {
                self.catImageView.isHidden = false
                UIView.animate(withDuration: 0.5) { self.catImageView.alpha = 1.0 }
            } else {
                self.emptyBoxImageView.isHidden = false
                UIView.animate(withDuration: 0.5) { self.emptyBoxImageView.alpha = 1.0 }
            }

            UIView.transition(with: self.quantumStateLabel, duration: 0.8, options: .transitionCrossDissolve) {
                self.quantumStateLabel.text = isPresent ? "The cat is in the box! 🐾" :
                    "The cat has quantum-leaped to another dimension! 🌟"
                self.quantumStateLabel.gradientColors = isPresent ?
                    [UIColor.systemBlue.cgColor, UIColor(hex: "#00ff88").cgColor] :
                    [UIColor.systemPurple.cgColor, UIColor(hex: "#ff99cc").cgColor]
            }

            self.showResultPopup(isPresent: isPresent)
        }
        boxOpenAnimator?.startAnimation()
    }

    // MARK: - Sound & Alert Utilities
    private func playSoundEffect(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    // 기존 결과 얼럿 수정 → OK 선택 시 퀴즈 시작 (아래 startQuiz() 호출)
    private func showResultPopup(isPresent: Bool) {
        let message = isPresent ? "🐾 Cat detected in the box!" : "🌌 Cat is quantum-leaping!"
        let alert = UIAlertController(
            title: isPresent ? "Cat Detected!" : "Exploring the Quantum Realm!",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.showQuizPrompt()
        }))
        present(alert, animated: true)
    }

    // 퀴즈 응시 여부 확인
    private func showQuizPrompt() {
        let prompt = UIAlertController(
            title: "Quiz Time!",
            message: "Would you like to test your knowledge on quantum concepts?",
            preferredStyle: .alert
        )
        prompt.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.startQuiz()
        }))
        prompt.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(prompt, animated: true)
    }

    // MARK: - Quiz Logic

    // 퀴즈 시작: 전체 질문 풀에서 3개를 랜덤 선택
    private func startQuiz() {
        let allQuestions: [QuizQuestion] = [
            QuizQuestion(
                question: "What phenomenon does the experiment demonstrate?",
                choices: ["Observer Effect", "Quantum Tunneling", "Superposition"],
                correctAnswerIndex: 0,
                explanation: "Observation collapses the quantum state – this is known as the Observer Effect."
            ),
            QuizQuestion(
                question: "What happens to the quantum state when observed?",
                choices: ["It remains superposed", "It collapses", "It becomes entangled"],
                correctAnswerIndex: 1,
                explanation: "When observed, the quantum state collapses into a definite state."
            ),
            QuizQuestion(
                question: "Before observation, how can the cat be described?",
                choices: ["Definitely alive", "Definitely dead", "Both alive and dead"],
                correctAnswerIndex: 2,
                explanation: "According to quantum theory, before observation, the cat exists in a superposition – both alive and dead."
            )
        ]
        // 랜덤하게 3문제를 선택
        quizQuestions = Array(allQuestions.shuffled().prefix(3))
        currentQuizIndex = 0
        showNextQuizQuestion()
    }

    // 다음 퀴즈 문제 표시 (퀴즈가 모두 끝나면 종료 메시지)
    private func showNextQuizQuestion() {
        guard currentQuizIndex < quizQuestions.count else {
            let alert = UIAlertController(title: "Quiz Completed", message: "Thanks for taking the quiz!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        let currentQuestion = quizQuestions[currentQuizIndex]
        let quizAlert = UIAlertController(title: "Quiz", message: currentQuestion.question, preferredStyle: .alert)
        for (index, choice) in currentQuestion.choices.enumerated() {
            quizAlert.addAction(UIAlertAction(title: choice, style: .default, handler: { _ in
                let isCorrect = (index == currentQuestion.correctAnswerIndex)
                self.showQuizAnswer(isCorrect: isCorrect, explanation: currentQuestion.explanation)
            }))
        }
        present(quizAlert, animated: true)
    }

    // 퀴즈 정답 확인 및 해설 표시 후 다음 문제 진행
    private func showQuizAnswer(isCorrect: Bool, explanation: String) {
        let title = isCorrect ? "Correct!" : "Incorrect"
        let message = isCorrect ? "Yes! That's correct." : "Incorrect. \(explanation)"
        let answerAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        answerAlert.addAction(UIAlertAction(title: "Next", style: .default, handler: { _ in
            self.currentQuizIndex += 1
            self.showNextQuizQuestion()
        }))
        present(answerAlert, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// MARK: - Face Detection Delegate (변경된 부분)
extension QuantumCatViewController: @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        // 세션이 실행 중일 때만 얼굴 인식 수행
           guard captureSession.isRunning else { return }

        let faceObjects = metadataObjects.compactMap { $0 as? AVMetadataFaceObject }

        if !faceObjects.isEmpty {
            if detectionStartTime == nil {
                startCountdown()
            }
        } else {
            detectionStartTime = nil
            faceDetectionTimer?.invalidate()
            countdownLabel.text = ""
        }
    }
}

// MARK: - Tutorial Presentation
extension QuantumCatViewController {
    @objc private func showQuantumTutorial() {
        let tutorialVC = TutorialViewController()
        tutorialVC.modalPresentationStyle = .overCurrentContext
        tutorialVC.modalTransitionStyle = .crossDissolve
        present(tutorialVC, animated: true)
    }

    private func addPresentationEffects() {
        // 배경 진동 효과
        let vibrationGenerator = UIImpactFeedbackGenerator(style: .heavy)
        vibrationGenerator.impactOccurred()

        // 현재 뷰 흐림 효과
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        view.addSubview(blurView)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension QuantumCatViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TutorialDismissAnimator()
    }


}

// MARK: - Custom Transition Classes
class TutorialDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.3,
                       options: .curveEaseInOut) {
            fromVC.view.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
            fromVC.view.alpha = 0
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class TutorialDismissInteractionController: UIPercentDrivenInteractiveTransition {
    private weak var viewController: UIViewController?
    private var shouldComplete = false

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        setupGestureRecognizer(in: viewController.view)
    }

    private func setupGestureRecognizer(in view: UIView) {
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .bottom
        view.addGestureRecognizer(edgePan)
    }

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard let view = gesture.view else { return }

        let translation = gesture.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let progress = fminf(downwardMovement, 1.0)

        switch gesture.state {
        case .began:
            viewController?.dismiss(animated: true)
        case .changed:
            update(CGFloat(progress))
        case .cancelled:
            cancel()
        case .ended:
            progress > 0.3 ? finish() : cancel()
        default:
            break
        }
    }
}

// MARK: - Custom Views
class GradientLabel: UILabel {
    var gradientColors: [CGColor] = [] {
        didSet { updateGradient() }
    }

    private let gradientLayer = CAGradientLayer()

    private func updateGradient() {
        gradientLayer.frame = bounds
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)

        let maskLabel = UILabel(frame: bounds)
        maskLabel.text = text
        maskLabel.font = font
        maskLabel.textAlignment = textAlignment
        maskLabel.numberOfLines = numberOfLines // 추가
        maskLabel.lineBreakMode = lineBreakMode // 추가
        mask = maskLabel
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
        setNeedsDisplay() // 레이아웃 변경 시 리프레시
    }
}

class HologramView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHologram()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHologram()
    }

    private func setupHologram() {
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [
            UIColor.systemTeal.withAlphaComponent(0.1).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradient.colors
        animation.toValue = [
            UIColor.systemPurple.withAlphaComponent(0.1).cgColor,
            UIColor.systemTeal.withAlphaComponent(0.1).cgColor
        ]
        animation.duration = 5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "hologramEffect")
    }
}

class GradientView: UIView {
    var colors: [CGColor] = [] {
        didSet { updateGradient() }
    }

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
    }
}

// MARK: - Helper Extensions
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)

        let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000ff) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

import UIKit

class IntroViewController: UIViewController {

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        //        let label = UILabel()
        //        label.text = """
        //            🌌 양자 세계에 온 걸 환영해요!
        //
        //            이 앱에서는 귀여운 고양이와 함께
        //            신기한 양자 세계를 탐험할 거예요.
        //
        //            양자 세계에선 한 가지가
        //            동시에 여러 곳에 있을 수도 있어요!
        //            우리가 보기 전까지는 알 수 없죠.
        //
        //            버튼을 눌러서
        //            고양이와 함께 모험을 떠나봐요!
        //            """
        let label = UILabel()
        label.text = """
             🌌 Welcome to the Quantum Realm!
             
             You're about to explore the mysterious
             quantum world with a special cat.
             
             In this realm, objects can exist in
             multiple states simultaneously -
             until someone observes them!
             
             Ready to see how your observation
             affects reality?
             """

        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemTeal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0.9
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let startButton: UIButton = {
        let button = UIButton()
        //        button.setTitle("상자 바라보러 가기", for: .normal)
        button.setTitle("Open Quantum Box", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        button.backgroundColor = .systemTeal
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.systemTeal.cgColor
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goToMain), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .black

        let backgroundView = GradientView()
        backgroundView.colors = [UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
                                 UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1).cgColor]
        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)

        let container = UIStackView(arrangedSubviews: [titleLabel, startButton])
        container.axis = .vertical
        container.spacing = 40
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),

            startButton.heightAnchor.constraint(equalToConstant: 60),
            startButton.widthAnchor.constraint(equalToConstant: 260)
        ])
    }

    @objc private func goToMain() {
        let mainVC = QuantumCatViewController()

        // 백 버튼 아이템 커스텀 설정
        let backItem = UIBarButtonItem()
        backItem.title = "" // 백 버튼 텍스트 공백
        backItem.tintColor = .systemTeal // 색상은 선택사항
        navigationItem.backBarButtonItem = backItem

        navigationController?.pushViewController(mainVC, animated: true)
    }
}

// 새로 추가할 TutorialViewController 클래스
class TutorialViewController: UIViewController {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1)
        view.layer.cornerRadius = 20
        view.layer.borderColor = UIColor.systemTeal.cgColor
        view.layer.borderWidth = 2
        view.layer.shadowColor = UIColor.systemTeal.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.5
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        //        label.text = "🔍 마법상자 사용법"
        label.text = "🔍 How to Use the Quantum Box"
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = .systemTeal
        label.textAlignment = .center
        // 추가: 동적 폰트 사이즈 조절
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7 // 최대 30%까지 축소
        return label
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.backgroundColor = .clear
        tv.textColor = .systemTeal

        // 행간 및 단어 단위 줄바꿈 설정
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.paragraphSpacing = 8

        //        let attributedString = NSMutableAttributedString(
        //            string: """
        //                    상자를 3초 동안 바라보면, 고양이가 여기저기 있던 상태에서 한 곳에 나타나요.
        //                    이걸 '관찰자 효과'라고 해요.
        //                    우리가 고양이를 바라보는 순간, 고양이의 상태가 정해지는 거예요.
        //                    신기하죠? 우리의 '관찰'이 고양이의 세계에 영향을 미친다니요!
        //
        //                    이건 사실, 아주 작은 미시세계에서 일어나는 특별한 일이에요.
        //                    고양이가 들어 있는 상자는 '양자 세계'를 보여주는 마법 같은 도구라고 할 수 있어요.
        //
        //                    양자의 세계에서는, 어떤 물체가 동시에 여러 곳에 있을 수도 있고, 여러 가지 상태를 동시에 가질 수도 있어요.
        //                    하지만 누군가가 그것을 '관찰'하는 순간, 그 상태는 하나로 정해져 버리죠.
        //
        //                    그래서 상자를 바라보면 고양이의 상태가 결정되는 거고,
        //                    상자를 보지 않으면 고양이는 여전히 여러 곳을 동시에 여행하고 있을지도 몰라요.
        //
        //                    이런 놀라운 현상은 우리가 살고 있는 큰 세계가 아니라,
        //                    아주 작은 미시세계에서만 일어나는 일이에요.
        //                    고양이는 이 작은 세계의 비밀을 알려주는 역할을 하고 있답니다!
        //                    """,
        let attributedString = NSMutableAttributedString(
            string: """
                        Staring at the box for 3 seconds collapses the cat's quantum state.  
                        This demonstrates the 'Observer Effect' - reality isn't fixed until observed.  
                        Our observation literally shapes the cat's quantum reality!
                        
                        This mirrors phenomena in the microscopic quantum world.  
                        The box represents a 'quantum system' where normal rules don't apply.  
                        
                        In quantum physics, particles can:
                        • Exist in multiple states
                        • Be in multiple places
                        • Tunnel through barriers
                        ...all simultaneously!
                        
                        But when measured, they pick one concrete state.  
                        By opening the box, you're essentially 
                        making a quantum measurement!
                        
                        While our macro-world doesn't work this way,  
                        this experiment helps visualize one of  
                        quantum physics' most fascinating aspects!
                        """,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.systemTeal,
                .font: UIFont.systemFont(ofSize: 20, weight: .medium) // 폰트 속성 추가
            ]
        )

        tv.attributedText = attributedString
        tv.textAlignment = .left
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // 패딩 추가
        return tv
    }()

    private let closeButton: UIButton = {
        let button = UIButton()
        //        button.setTitle("닫기", for: .normal)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.systemTeal.cgColor
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(closeTutorial), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addHologramEffect()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(textView)
        containerView.addSubview(closeButton)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            textView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -15),

            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func addHologramEffect() {
        let hologram = HologramView()
        hologram.frame = containerView.bounds
        hologram.layer.cornerRadius = 20
        containerView.insertSubview(hologram, at: 0)
    }

    @objc private func closeTutorial() {
        dismiss(animated: true)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        IntroViewWrapper()
    }
}
