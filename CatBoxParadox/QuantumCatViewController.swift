import UIKit
import ARKit
import AudioToolbox

class QuantumCatViewController: UIViewController {

    // MARK: - Quantum UI Components
    private let quantumContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let quantumBoxLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "📦"
        label.font = .systemFont(ofSize: 160)
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.systemTeal.cgColor
        label.layer.shadowRadius = 15
        label.layer.shadowOpacity = 0.7
        label.layer.shadowOffset = .zero
        return label
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

    private let superpositionLabel: UILabel = {
        let label = UILabel()
        label.text = """
        슈뢰딩거의 고양이 사고실험 (1935)
        관측 전까지 고양이는 살아있음과 죽음의
        양자 중첩 상태에 있습니다
        """
        label.font = UIFont(name: "DungGeunMo", size: 22) // 폰트 사이즈 조정
        label.textColor = .systemTeal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0.9
        return label
    }()

    private let quantumStateLabel: GradientLabel = {
        let label = GradientLabel()
        label.font = UIFont(name: "DungGeunMo", size: 32)
        label.textAlignment = .center
        label.gradientColors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        return label
    }()

    private let observerEffectLabel: UILabel = {
        let label = UILabel()
        label.text = """
        관측자 효과: 3초 응시 시
        파동함수 붕괴로 상태 결정
        (코펜하겐 해석)
        """
        label.font = UIFont(name: "DungGeunMo", size: 18)
        label.textColor = .systemTeal // 색상 변경
        label.textAlignment = .center
        label.numberOfLines = 0 // 다중 라인 허용
        return label
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("🔮 실험 다시하기", for: .normal)
        button.titleLabel?.font = UIFont(name: "DungGeunMo", size: 20)
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
        cell.contents = UIImage(systemName: "sparkle")?.cgImage
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
        label.font = UIFont(name: "DungGeunMo", size: 14)
        label.textColor = .systemGreen
        label.numberOfLines = 0
        label.alpha = 0.7
        return label
    }()

    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "DungGeunMo", size: 24)
        label.textColor = .systemRed
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureQuantumUI()
        setupARKit()
        resetQuantumExperiment()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        quantumGlowLayer.frame = quantumContainer.bounds
        particleEmitter.emitterPosition = quantumBoxLabel.center
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
        quantumContainer.addSubview(quantumBoxLabel)
        view.addSubview(quantumContainer)

        let hologramOverlay = HologramView()
        hologramOverlay.frame = quantumContainer.frame
        view.addSubview(hologramOverlay)

        let stackView = UIStackView(arrangedSubviews: [
            superpositionLabel,
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
            quantumContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            quantumContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quantumContainer.widthAnchor.constraint(equalToConstant: 250),
            quantumContainer.heightAnchor.constraint(equalToConstant: 250),

            quantumBoxLabel.centerXAnchor.constraint(equalTo: quantumContainer.centerXAnchor),
            quantumBoxLabel.centerYAnchor.constraint(equalTo: quantumContainer.centerYAnchor),
            quantumBoxLabel.widthAnchor.constraint(equalToConstant: 160),
            quantumBoxLabel.heightAnchor.constraint(equalToConstant: 160),

            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),

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

        quantumContainer.layer.addSublayer(particleEmitter)
        startBoxIdleAnimation()
    }

    private func startBoxIdleAnimation() {
        let shake = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        shake.values = [-0.05, 0.05, -0.03, 0.03, 0]
        shake.keyTimes = [0, 0.25, 0.5, 0.75, 1]
        shake.duration = 2
        shake.repeatCount = .infinity
        quantumBoxLabel.layer.add(shake, forKey: "boxShake")

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
        // 세션 정지 및 재시작 로직 보강
        arSceneView.session.pause()
        let configuration = ARFaceTrackingConfiguration()
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // 상태 값 초기화 추가
        isUserLooking = false
        lastDetectionTime = Date()
        observationTimer?.invalidate()

        quantumBoxLabel.text = "📦"
        quantumStateLabel.text = ""
        observerEffectLabel.text = "3초 응시 시 상태 결정"
        countdownLabel.text = ""
        debugInfoLabel.text = ""
        startBoxIdleAnimation()
    }

    @objc private func showQuantumTutorial() {
        let alert = UIAlertController(
            title: "양자 역학 튜토리얼",
            message: "1. 3초 후 자동으로 결과가 결정됩니다\n2. 결과는 무작위 양자 붕괴 현상입니다",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func playSoundEffect(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    // 결과 팝업 메시지 개선안
    private func showResultPopup(isAlive: Bool) {
        let message = isAlive ?
        """
        살아있는 상태 관측 성공!
        (양자 중첩 상태 붕괴)
        """ :
        """
        사망 상태 확인됨
        (파동함수 최종 수렴)
        """

        let alert = UIAlertController(
            title: isAlive ? "🐱 생존!" : "💀 사망",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Quantum Interaction Logic
    private func collapseWaveFunction() {
        let isAlive = Bool.random()
        playSoundEffect(name: "quantum_collapse")

        // ARKit 세션 일시 정지 추가
        arSceneView.session.pause()

        boxOpenAnimator?.stopAnimation(true)
        boxOpenAnimator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.6) {
            self.quantumBoxLabel.transform = CGAffineTransform(scaleX: 1.8, y: 0.2)
            self.quantumBoxLabel.alpha = 0.5
        }

        boxOpenAnimator?.addCompletion { _ in
            self.quantumBoxLabel.text = isAlive ? "🐈‍⬛✨" : "💀☠️"
            self.quantumBoxLabel.transform = .identity
            self.quantumBoxLabel.alpha = 1.0

            UIView.transition(with: self.quantumStateLabel, duration: 0.8, options: .transitionCrossDissolve) {
                self.quantumStateLabel.text = isAlive ? "Alive 🟢" : "Dead 🔴"
                self.quantumStateLabel.gradientColors = isAlive ?
                [UIColor.systemGreen.cgColor, UIColor(hex: "#00ff88").cgColor] :
                [UIColor.systemRed.cgColor, UIColor(hex: "#ff0066").cgColor]
            }

            self.showResultPopup(isAlive: isAlive)
            self.triggerConfetti(isAlive: isAlive)

            // 타이머 및 상태 초기화 추가
            self.observationTimer?.invalidate()
            self.isUserLooking = false
        }

        boxOpenAnimator?.startAnimation()
    }

    private func triggerConfetti(isAlive: Bool) {
        let confetti = CAEmitterLayer()
        confetti.emitterPosition = CGPoint(x: view.center.x, y: -50)
        confetti.emitterShape = .line
        confetti.emitterSize = CGSize(width: view.frame.width, height: 1)

        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: isAlive ? "leaf.fill" : "flame.fill")?.cgImage
        cell.birthRate = 100
        cell.lifetime = 5
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        cell.spin = 2
        cell.spinRange = 3
        cell.scale = 0.2
        cell.scaleRange = 0.1
        cell.color = isAlive ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor

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
        mask = UILabel(frame: bounds)
        (mask as? UILabel)?.text = text
        (mask as? UILabel)?.font = font
        (mask as? UILabel)?.textAlignment = textAlignment
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
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
