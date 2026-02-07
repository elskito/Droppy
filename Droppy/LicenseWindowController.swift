import AppKit
import SwiftUI

final class LicenseWindowController: NSObject, NSWindowDelegate {
    static let shared = LicenseWindowController()

    private var window: NSWindow?

    var isVisible: Bool {
        window?.isVisible == true
    }

    private override init() {
        super.init()
    }

    func show() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // If already visible, bring it to front.
            if let window = self.window, window.isVisible {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                return
            }

            let view = LicenseActivationView(
                onRequestQuit: {
                    NSApplication.shared.terminate(nil)
                },
                onActivationCompleted: { [weak self] in
                    self?.close()
                    if !UserDefaults.standard.bool(forKey: AppPreferenceKey.hasCompletedOnboarding) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            OnboardingWindowController.shared.show()
                        }
                    }
                }
            )
            .preferredColorScheme(.dark)

            let hostingView = NSHostingView(rootView: view)

            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 430, height: 520),
                styleMask: [.titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            newWindow.title = "Activate License"
            newWindow.center()
            newWindow.level = .modalPanel
            newWindow.titlebarAppearsTransparent = true
            newWindow.titleVisibility = .hidden
            newWindow.standardWindowButton(.closeButton)?.isHidden = true
            newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
            newWindow.standardWindowButton(.zoomButton)?.isHidden = true
            newWindow.isMovableByWindowBackground = true
            newWindow.backgroundColor = .clear
            newWindow.isOpaque = false
            newWindow.hasShadow = true
            newWindow.isReleasedWhenClosed = false
            newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            newWindow.contentView = hostingView
            newWindow.delegate = self

            self.window = newWindow

            newWindow.alphaValue = 0
            if let layer = newWindow.contentView?.layer {
                layer.transform = CATransform3DMakeScale(0.85, 0.85, 1.0)
                layer.opacity = 0
            } else {
                newWindow.contentView?.wantsLayer = true
                newWindow.contentView?.layer?.transform = CATransform3DMakeScale(0.85, 0.85, 1.0)
                newWindow.contentView?.layer?.opacity = 0
            }

            newWindow.orderFront(nil)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                newWindow.makeKeyAndOrderFront(nil)
            }

            if let layer = newWindow.contentView?.layer {
                let fadeAnim = CABasicAnimation(keyPath: "opacity")
                fadeAnim.fromValue = 0
                fadeAnim.toValue = 1
                fadeAnim.duration = 0.25
                fadeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
                fadeAnim.fillMode = .forwards
                fadeAnim.isRemovedOnCompletion = false
                layer.add(fadeAnim, forKey: "fadeIn")
                layer.opacity = 1

                let scaleAnim = CASpringAnimation(keyPath: "transform.scale")
                scaleAnim.fromValue = 0.85
                scaleAnim.toValue = 1.0
                scaleAnim.mass = 1.0
                scaleAnim.stiffness = 250
                scaleAnim.damping = 22
                scaleAnim.initialVelocity = 6
                scaleAnim.duration = scaleAnim.settlingDuration
                scaleAnim.fillMode = .forwards
                scaleAnim.isRemovedOnCompletion = false
                layer.add(scaleAnim, forKey: "scaleSpring")
                layer.transform = CATransform3DIdentity
            }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                newWindow.animator().alphaValue = 1
            })

            HapticFeedback.expand()
        }
    }

    func close() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.close()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let manager = LicenseManager.shared
        let canClose = !manager.requiresLicenseEnforcement || manager.isActivated
        if !canClose {
            HapticFeedback.error()
        }
        return canClose
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
