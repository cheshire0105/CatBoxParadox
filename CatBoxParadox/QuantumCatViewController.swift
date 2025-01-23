import UIKit
import ARKit
import AudioToolbox
import Lottie

class QuantumCatViewController: UIViewController {

    // MARK: - Quantum UI Components
    private let quantumContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    // 기존 UILabel 코드 삭제 후 UIImageView로 교체
    private let quantumBoxImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "box") // Assets에 box 이미지 추가
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.systemTeal.cgColor
        imageView.layer.shadowRadius = 15
        imageView.layer.shadowOpacity = 0.7
        imageView.layer.shadowOffset = .zero
        return imageView
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

    // Lottie 애니메이션 뷰
    private let catAnimationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "cat-box") // cat-box.json 파일 필요
        view.loopMode = .playOnce
        view.animationSpeed = 0.8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let emptyBoxAnimationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "empty-box") // empty-box.json 파일 필요
        view.loopMode = .playOnce
        view.animationSpeed = 0.8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let superpositionLabel: UILabel = {
        let label = UILabel()
        label.text = """
        🪄 양자 마법 상자!
        상자를 열기 전까지는
        고양이는 [둘 다] 상태예요!
        (여기와 다른 차원을 동시에 여행 중!)
        """
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium) // 폰트 사이즈 조정
        label.textColor = .systemTeal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0.9
        return label
    }()

    private let quantumStateLabel: GradientLabel = {
        let label = GradientLabel()
        label.text = """
           📦 신기한 마법 상자!
           (고양이는 동시에 여러 곳에 있을 수 있어요)
           """
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0 // 여러 줄 허용
        label.lineBreakMode = .byWordWrapping // 단어 단위 줄바꿈
        label.adjustsFontSizeToFitWidth = true // 폰트 크기 자동 조절
        label.minimumScaleFactor = 0.7 // 최소 축소 비율
        label.gradientColors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        return label
    }()

    private let observerEffectLabel: UILabel = {
        let label = UILabel()
        label.text = """
        👀 3초 동안 상자를 바라보면
        고양이가 여기 있거나,
        없던 상태에서 한 곳으로 확정돼요!
        
        이걸 '관찰자 효과'라고 해요.
        우리가 지켜보는 것만으로도
        고양이의 상태가 바뀌는 거예요!
        """
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemTeal // 색상 변경
        label.textAlignment = .center
        label.numberOfLines = 0 // 다중 라인 허용
        return label
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("🔮 다시 시도하기", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.systemTeal.cgColor
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.systemTeal.cgColor
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.addTarget(self, action: #selector(resetQuantumExperiment), for: .touchUpInside)
        return button
    }()

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        button.tintColor = .systemTeal
        button.backgroundColor = .black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.5
        button.addTarget(self, action: #selector(showQuantumTutorial), for: .touchUpInside)
        return button
    }()

    private let particleEmitter: CAEmitterLayer = {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .sphere
        emitter.emitterSize = CGSize(width: 50, height: 50)
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        //        cell.contents = UIImage(systemName: "sparkle")?.cgImage
        cell.birthRate = 50
        cell.lifetime = 3
        cell.velocity = 50
        cell.scale = 0.1
        cell.scaleSpeed = -0.2
        cell.alphaSpeed = -0.2
        cell.spin = 2
        cell.spinRange = 3
        cell.emissionRange = .pi * 2

        emitter.emitterCells = [cell]
        return emitter
    }()

    // MARK: - ARKit Properties
    private let arSceneView = ARSCNView()
    private var isUserLooking = false
    private var lastDetectionTime = Date()
    private var observationTimer: Timer?
    private var boxOpenAnimator: UIViewPropertyAnimator?

    // Debug UI
    private let debugInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = .systemGreen
        label.numberOfLines = 0
        label.alpha = 0.7
        return label
    }()

    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = .systemRed
        label.textAlignment = .center
        return label
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBoxIdleAnimation()
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureQuantumUI()
        setupARKit()
        resetQuantumExperiment()

        // Lottie 애니메이션 사전 로드
        catAnimationView.contentMode = .scaleAspectFit
        emptyBoxAnimationView.contentMode = .scaleAspectFit
        quantumBoxImageView.isHidden = false // 상자 다시 보이기
        startBoxIdleAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        quantumGlowLayer.frame = quantumContainer.bounds
        particleEmitter.emitterPosition = quantumBoxImageView.center
    }

    // MARK: - UI Configuration
    private func configureQuantumUI() {
        view.backgroundColor = .black

        let backgroundView = GradientView()
        backgroundView.colors = [UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
                                 UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1).cgColor]
        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)

        quantumContainer.layer.addSublayer(quantumGlowLayer)
        quantumContainer.addSubview(quantumBoxImageView)
        view.addSubview(quantumContainer)
        quantumContainer.addSubview(catAnimationView)
        quantumContainer.addSubview(emptyBoxAnimationView)

        let hologramOverlay = HologramView()
        hologramOverlay.frame = quantumContainer.frame
        view.addSubview(hologramOverlay)

        // 스택뷰에서 superpositionLabel 제거
        let stackView = UIStackView(arrangedSubviews: [
            quantumStateLabel,
            observerEffectLabel,
            resetButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        quantumContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quantumContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quantumContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150), // ▼ 중앙에서 -150포인트 위로
            quantumContainer.widthAnchor.constraint(equalToConstant: 250),
            quantumContainer.heightAnchor.constraint(equalToConstant: 250),

            quantumBoxImageView.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            quantumBoxImageView.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor, constant: 40),
            quantumBoxImageView.widthAnchor.constraint(equalToConstant: 400),
            quantumBoxImageView.heightAnchor.constraint(equalToConstant: 400),

            stackView.topAnchor.constraint(equalTo: quantumContainer.bottomAnchor, constant: 30), // ▼ 상자 아래 30포인트
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), // ▼ 최대 하단 제한

            resetButton.heightAnchor.constraint(equalToConstant: 50),
            resetButton.widthAnchor.constraint(equalToConstant: 250)
        ])

        view.addSubview(infoButton)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            infoButton.widthAnchor.constraint(equalToConstant: 40),
            infoButton.heightAnchor.constraint(equalToConstant: 40)
        ])


        NSLayoutConstraint.activate([
            catAnimationView.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            catAnimationView.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor, constant: 40), // ▼ 40포인트 아래로
            catAnimationView.widthAnchor.constraint(equalToConstant: 400),
            catAnimationView.heightAnchor.constraint(equalToConstant: 400),

            emptyBoxAnimationView.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            emptyBoxAnimationView.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor, constant: 40), // ▼ 동일하게 적용
            emptyBoxAnimationView.widthAnchor.constraint(equalToConstant: 400),
            emptyBoxAnimationView.heightAnchor.constraint(equalToConstant: 400)
        ])


        quantumContainer.layer.addSublayer(particleEmitter)
        startBoxIdleAnimation()
    }

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

    // MARK: - ARKit Setup
    private func setupARKit() {
        arSceneView.delegate = self
        arSceneView.frame = view.bounds
        view.insertSubview(arSceneView, at: 0)

        guard ARFaceTrackingConfiguration.isSupported else {
            debugInfoLabel.text = "⚠️ TrueDepth 카메라 미지원"
            return
        }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isWorldTrackingEnabled = true
        arSceneView.session.run(configuration)

        //        setupDebugUI()
    }

    // MARK: - Face Tracking Logic
    private func processFaceAnchor(_ anchor: ARFaceAnchor) {
        let blendShapes = anchor.blendShapes

        guard let leftEyeBlink = blendShapes[.eyeBlinkLeft]?.floatValue,
              let rightEyeBlink = blendShapes[.eyeBlinkRight]?.floatValue else {
            return
        }

        let isLeftEyeOpen = leftEyeBlink < 0.3
        let isRightEyeOpen = rightEyeBlink < 0.3

        DispatchQueue.main.async {
            let eyeState = (isLeftEyeOpen && isRightEyeOpen) ? "👁️👁️" : "➖➖"
            let debugText = """
            \(eyeState)
            Left Eye: \(isLeftEyeOpen ? "OPEN" : "CLOSED")
            Right Eye: \(isRightEyeOpen ? "OPEN" : "CLOSED")
            """

            self.updateDebugInfo(debugText)

            if isLeftEyeOpen && isRightEyeOpen {
                self.handleUserLooking()
            } else {
                self.handleUserNotLooking()
            }
        }
    }

    private func handleUserLooking() {
        let currentTime = Date()
        let elapsed = currentTime.timeIntervalSince(lastDetectionTime)

        if !isUserLooking {
            lastDetectionTime = currentTime
            isUserLooking = true
            startObservationCountdown()
        }

        let remaining = 3 - Int(elapsed)
        updateCountdown(remaining > 0 ? "\(remaining)" : "")

        if elapsed >= 3 {
            observationTimer?.invalidate()
            collapseWaveFunction()
        }
    }

    private func handleUserNotLooking() {
        isUserLooking = false
        observationTimer?.invalidate()
        updateCountdown("")
    }

    private func startObservationCountdown() {
        observationTimer?.invalidate()
        observationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Int(Date().timeIntervalSince(self.lastDetectionTime))
            self.updateCountdown("\(3 - elapsed)")
        }
    }

    // MARK: - UI Updates
    private func setupDebugUI() {
        view.addSubview(debugInfoLabel)
        view.addSubview(countdownLabel)

        debugInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            debugInfoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            debugInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),

            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.bottomAnchor.constraint(equalTo: quantumContainer.topAnchor, constant: -20)
        ])
    }

    private func updateDebugInfo(_ text: String) {
        DispatchQueue.main.async {
            self.debugInfoLabel.text = text
        }
    }

    private func updateCountdown(_ text: String) {
        DispatchQueue.main.async {
            self.countdownLabel.text = text
            self.countdownLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)

            UIView.animate(withDuration: 0.3) {
                self.countdownLabel.transform = .identity
            }
        }
    }

    // MARK: - Quantum Interaction Logic
    @objc private func resetQuantumExperiment() {
        // 1. 진행 중인 모든 애니메이션 강제 종료
        boxOpenAnimator?.stopAnimation(true)
        boxOpenAnimator?.finishAnimation(at: .current)
        boxOpenAnimator = nil

        // 2. 상자 UI 상태 완전 초기화
        quantumBoxImageView.layer.removeAllAnimations()
        quantumBoxImageView.transform = .identity // ⭐️ 트랜스폼 초기화
        quantumBoxImageView.alpha = 1.0 // ⭐️ 알파값 복원
        quantumBoxImageView.isHidden = false

        // 3. ARKit 트래킹 관련 상태 초기화
        isUserLooking = false
        observationTimer?.invalidate()
        observationTimer = nil
        lastDetectionTime = Date()

        // 4. AR 세션 재시작 (트래킹 유지)
        arSceneView.session.pause()
        let configuration = ARFaceTrackingConfiguration()
        arSceneView.session.run(configuration, options: [.removeExistingAnchors])

        // 5. Lottie 애니메이션 초기화
        [catAnimationView, emptyBoxAnimationView].forEach {
            $0.stop()
            $0.isHidden = true
        }

        // 6. 상자 기본 애니메이션 재시작
        startBoxIdleAnimation()

        // 7. 라벨 상태 초기화
        quantumStateLabel.text = """
           📦 신기한 마법 상자!
           (고양이는 동시에 여러 곳에 있을 수 있어요)
           """
        countdownLabel.text = ""
    }

    // QuantumCatViewController 내부에 추가할 코드

    @objc private func showQuantumTutorial() {
        let tutorialVC = TutorialViewController()
        tutorialVC.modalPresentationStyle = .overCurrentContext
        tutorialVC.modalTransitionStyle = .crossDissolve
        present(tutorialVC, animated: true)
    }


    private func playSoundEffect(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    // 결과 팝업 메시지 개선안
    private func showResultPopup(isPresent: Bool) {
        let message = isPresent
        ? """
               🐾 박스 안에서 고양이 발견!
               지금은 휴식을 취하고 있대요!
               
               우리 시선이 고양이를
               이곳으로 불러냈나봐요!
               """
        : """
               🌌 고양이는 우주 여행 중!
               이번엔 다른 차원에 있나 봐요!
               
               우리가 보기 전에는
               여러 곳에 있을 수도 있대요!
               """
        let alert = UIAlertController(
            title: isPresent ? "상자 안에 있어요!" : "여행 중이에요!",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Quantum Interaction Logic
    private func collapseWaveFunction() {
        let isPresent = Bool.random()
        playSoundEffect(name: "quantum_collapse")

        // ARKit 세션 일시 정지
        arSceneView.session.pause()

        boxOpenAnimator?.stopAnimation(true)
        boxOpenAnimator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.6) {
            self.quantumBoxImageView.transform = CGAffineTransform(scaleX: 1.8, y: 0.2)
            self.quantumBoxImageView.alpha = 0.5
        }

        boxOpenAnimator?.addCompletion { _ in
            self.quantumBoxImageView.isHidden = true // 기존 상자 숨기기

            // 애니메이션 초기화
            self.catAnimationView.stop()
            self.emptyBoxAnimationView.stop()
            self.catAnimationView.isHidden = true
            self.emptyBoxAnimationView.isHidden = true

            if isPresent {
                self.catAnimationView.isHidden = false
                self.catAnimationView.play()

            } else {
                self.emptyBoxAnimationView.isHidden = false
                self.emptyBoxAnimationView.play()
            }

            UIView.transition(with: self.quantumStateLabel, duration: 0.8, options: .transitionCrossDissolve) {
                self.quantumStateLabel.text = isPresent
                ? "고양이는 상자 속에 있어요! 🐾"
                : "고양이는 다른 차원으로 놀러갔어요! 🌟"
                self.quantumStateLabel.gradientColors = isPresent ?
                [UIColor.systemBlue.cgColor, UIColor(hex: "#00ff88").cgColor] :
                [UIColor.systemPurple.cgColor, UIColor(hex: "#ff99cc").cgColor]
            }

            self.showResultPopup(isPresent: isPresent)
            self.observationTimer?.invalidate()
            self.isUserLooking = false
        }

        boxOpenAnimator?.startAnimation()
    }

    private func triggerConfetti(isPresent: Bool) {
        let confetti = CAEmitterLayer()
        confetti.emitterPosition = CGPoint(x: view.center.x, y: -50)
        confetti.emitterShape = .line
        confetti.emitterSize = CGSize(width: view.frame.width, height: 1)

        let cell = CAEmitterCell()
        //        cell.contents = UIImage(systemName: isPresent ? "pawprint.fill" : "sparkles")?.cgImage
        cell.birthRate = 100
        cell.lifetime = 5
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        cell.spin = 2
        cell.spinRange = 3
        cell.scale = 0.2
        cell.scaleRange = 0.1
        cell.color = isPresent ? UIColor.systemBlue.cgColor : UIColor.systemPurple.cgColor

        confetti.emitterCells = [cell]
        view.layer.addSublayer(confetti)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            confetti.removeFromSuperlayer()
        }
    }
}

// MARK: - ARSCNViewDelegate
extension QuantumCatViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        processFaceAnchor(faceAnchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor else { return nil }
        return SCNNode()
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
        let label = UILabel()
        label.text = """
            🌌 양자 세계에 온 걸 환영해요!
            
            이 앱에서는 귀여운 고양이와 함께
            신기한 양자 세계를 탐험할 거예요.
            
            양자 세계에선 한 가지가
            동시에 여러 곳에 있을 수도 있어요!
            우리가 보기 전까지는 알 수 없죠.
            
            버튼을 눌러서
            고양이와 함께 모험을 떠나봐요!
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
        button.setTitle("상자 바라보러 가기", for: .normal)
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
        label.text = "🔍 마법상자 사용법"
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = .systemTeal
        label.textAlignment = .center
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

        let attributedString = NSMutableAttributedString(
            string: """
                    상자를 3초 동안 바라보면, 고양이가 여기저기 있던 상태에서 한 곳에 나타나요.  
                    이걸 '관찰자 효과'라고 해요.  
                    우리가 고양이를 바라보는 순간, 고양이의 상태가 정해지는 거예요.  
                    신기하죠? 우리의 '관찰'이 고양이의 세계에 영향을 미친다니요!

                    이건 사실, 아주 작은 미시세계에서 일어나는 특별한 일이에요.  
                    고양이가 들어 있는 상자는 '양자 세계'를 보여주는 마법 같은 도구라고 할 수 있어요.  

                    양자의 세계에서는, 어떤 물체가 동시에 여러 곳에 있을 수도 있고, 여러 가지 상태를 동시에 가질 수도 있어요.  
                    하지만 누군가가 그것을 '관찰'하는 순간, 그 상태는 하나로 정해져 버리죠.  

                    그래서 상자를 바라보면 고양이의 상태가 결정되는 거고,  
                    상자를 보지 않으면 고양이는 여전히 여러 곳을 동시에 여행하고 있을지도 몰라요.  

                    이런 놀라운 현상은 우리가 살고 있는 큰 세계가 아니라,  
                    아주 작은 미시세계에서만 일어나는 일이에요.  
                    고양이는 이 작은 세계의 비밀을 알려주는 역할을 하고 있답니다!
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
        button.setTitle("닫기", for: .normal)
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
