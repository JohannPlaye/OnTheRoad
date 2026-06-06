import SwiftUI

/// Full-screen native CAEmitterLayer fireworks animation
struct FireworksView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Self.launch(in: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    // MARK: - Fireworks

    static func launch(in view: UIView) {
        let bounds = view.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: 390, height: 844)  // fallback iPhone size
            : view.bounds
        let positions: [CGPoint] = [
            CGPoint(x: bounds.width * 0.25, y: bounds.height * 0.28),
            CGPoint(x: bounds.width * 0.75, y: bounds.height * 0.22),
            CGPoint(x: bounds.width * 0.50, y: bounds.height * 0.38),
            CGPoint(x: bounds.width * 0.20, y: bounds.height * 0.50),
            CGPoint(x: bounds.width * 0.80, y: bounds.height * 0.45),
        ]
        let colors: [UIColor] = [
            UIColor(red: 192/255, green: 132/255, blue: 252/255, alpha: 1), // purple
            UIColor(red: 74/255,  green: 222/255, blue: 128/255, alpha: 1), // green
            UIColor(red: 34/255,  green: 211/255, blue: 238/255, alpha: 1), // cyan
            .white,
            UIColor(red: 251/255, green: 191/255, blue: 36/255,  alpha: 1), // amber
        ]

        for (i, pos) in positions.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.28) {
                burst(in: view, at: pos, color: colors[i % colors.count])
            }
        }
    }

    private static func burst(in view: UIView, at position: CGPoint, color: UIColor) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = position
        emitter.emitterShape    = .point
        emitter.renderMode      = .additive

        let cell = CAEmitterCell()
        cell.birthRate          = 600
        cell.lifetime           = 1.4
        cell.lifetimeRange      = 0.5
        cell.velocity           = 280
        cell.velocityRange      = 140
        cell.emissionRange      = .pi * 2
        cell.spin               = 4
        cell.spinRange          = 8
        cell.scale              = 0.05
        cell.scaleRange         = 0.025
        cell.alphaSpeed         = -0.65
        cell.color              = color.cgColor
        cell.contents           = makeParticleImage()

        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5)  { emitter.removeFromSuperlayer() }
    }

    private static func makeParticleImage() -> CGImage? {
        let size = CGSize(width: 12, height: 12)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.cgImage
    }
}
