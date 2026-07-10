import AppKit
import QuartzCore

/// Drives the reveal/hide motion of the sidebar card.
///
/// Design intent: the card glides in on a gentle spring with a whisper of
/// scale, while opacity resolves slightly ahead of position so the motion
/// reads as "arriving" rather than "appearing". Hide is a touch quicker and
/// perfectly damped — leaving should feel lighter than arriving.
@MainActor
final class SidebarAnimator {
    enum Direction {
        case fromLeft
        case fromRight
    }

    private weak var card: SidebarCardView?

    /// Non-nil while an animation is in flight; called on natural completion.
    private var completion: (() -> Void)?

    init(card: SidebarCardView) {
        self.card = card
    }

    /// Distance the card travels while off screen, including shadow spill.
    private func travel(_ direction: Direction) -> CGFloat {
        guard let card else { return 0 }
        let spill: CGFloat = 40 // shadow + margin allowance
        let dx = card.bounds.width + spill
        return direction == .fromLeft ? -dx : dx
    }

    func prepareHidden(direction: Direction) {
        guard let card, let layer = card.layer else { return }
        layer.removeAllAnimations()
        layer.opacity = 0
        layer.transform = CATransform3DMakeTranslation(travel(direction), 0, 0)
    }

    func reveal(direction: Direction, speed: Double, completion: (() -> Void)? = nil) {
        guard let card, let layer = card.layer else { completion?(); return }
        cancelInFlight()
        self.completion = completion

        // Anchor scale to the card center for a natural settle.
        ensureCenterAnchor(layer, in: card)

        let dx = travel(direction)

        let slide = CASpringAnimation(perceptualDuration: 0.62 * speed, bounce: 0.14)
        slide.keyPath = "transform.translation.x"
        slide.fromValue = currentTranslationX(layer, fallback: dx)
        slide.toValue = 0
        slide.delegate = AnimationDelegate { [weak self] finished in
            guard finished else { return }
            self?.finish()
        }

        let scale = CASpringAnimation(perceptualDuration: 0.62 * speed, bounce: 0.10)
        scale.keyPath = "transform.scale"
        scale.fromValue = 0.975
        scale.toValue = 1.0

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = layer.presentation()?.opacity ?? 0
        fade.toValue = 1
        fade.duration = 0.30 * speed
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.transform = CATransform3DIdentity
        layer.opacity = 1

        layer.add(slide, forKey: "reveal.slide")
        layer.add(scale, forKey: "reveal.scale")
        layer.add(fade, forKey: "reveal.fade")
    }

    func hide(direction: Direction, speed: Double, completion: (() -> Void)? = nil) {
        guard let card, let layer = card.layer else { completion?(); return }
        cancelInFlight()
        self.completion = completion

        ensureCenterAnchor(layer, in: card)

        let dx = travel(direction)

        let slide = CASpringAnimation(perceptualDuration: 0.34 * speed, bounce: 0) // perfectly damped exit
        slide.keyPath = "transform.translation.x"
        slide.fromValue = currentTranslationX(layer, fallback: 0)
        slide.toValue = dx
        slide.delegate = AnimationDelegate { [weak self] finished in
            guard finished else { return }
            self?.finish()
        }

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = layer.presentation()?.opacity ?? 1
        fade.toValue = 0
        fade.duration = 0.30 * speed
        fade.timingFunction = CAMediaTimingFunction(name: .easeIn)

        layer.transform = CATransform3DMakeTranslation(dx, 0, 0)
        layer.opacity = 0

        layer.add(slide, forKey: "hide.slide")
        layer.add(fade, forKey: "hide.fade")
    }

    /// Read the in-flight translation so a reversal continues from where the
    /// card visually is — reversing mid-animation must never jump.
    private func currentTranslationX(_ layer: CALayer, fallback: CGFloat) -> CGFloat {
        guard let presentation = layer.presentation() else { return fallback }
        return presentation.value(forKeyPath: "transform.translation.x") as? CGFloat ?? fallback
    }

    private func ensureCenterAnchor(_ layer: CALayer, in view: NSView) {
        guard layer.anchorPoint != CGPoint(x: 0.5, y: 0.5) else { return }
        let bounds = view.bounds
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private func cancelInFlight() {
        completion = nil
        card?.layer?.removeAllAnimations()
    }

    private func finish() {
        let cb = completion
        completion = nil
        cb?()
    }
}

/// Tiny block-based CAAnimationDelegate.
private final class AnimationDelegate: NSObject, CAAnimationDelegate {
    private let done: (Bool) -> Void
    init(_ done: @escaping (Bool) -> Void) { self.done = done }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        done(flag)
    }
}
