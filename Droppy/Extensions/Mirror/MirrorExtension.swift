//
//  MirrorExtension.swift
//  Droppy
//

import SwiftUI

struct MirrorExtension: ExtensionDefinition {
    static let id = "mirror"
    static let title = "Mirror"
    static let subtitle = "Live camera mirror in your notch"
    static let category: ExtensionGroup = .productivity
    static let categoryColor: Color = .cyan

    static let description = "Use your notch as a quick live mirror. Open a front-camera preview instantly, right from the expanded shelf."

    static let features: [(icon: String, text: String)] = [
        ("camera.fill", "Live front camera preview"),
        ("rectangle.portrait.rotate", "Horizontally mirrored view"),
        ("bolt.fill", "Fast open/close from notch actions"),
        ("lock.shield", "No recording or snapshots")
    ]

    static let screenshotURL: URL? = nil
    static let iconURL: URL? = nil
    static let iconPlaceholder = "camera.fill"
    static let iconPlaceholderColor: Color = .cyan

    static func cleanup() {
        MirrorManager.shared.cleanup()
    }
}
