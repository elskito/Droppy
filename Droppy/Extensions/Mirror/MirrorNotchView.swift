//
//  MirrorNotchView.swift
//  Droppy
//

import SwiftUI
@preconcurrency import AVFoundation

struct MirrorNotchView: View {
    @ObservedObject var manager: MirrorManager
    var notchHeight: CGFloat = 0
    var isExternalWithNotchStyle: Bool = false

    private var contentPadding: EdgeInsets {
        NotchLayoutConstants.contentEdgeInsets(
            notchHeight: notchHeight,
            isExternalWithNotchStyle: isExternalWithNotchStyle
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow

            switch manager.state {
            case .running:
                MirrorCameraPreviewView(manager: manager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.large, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DroppyRadius.large, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            case .requestingPermission:
                progressState(
                    title: "Opening camera...",
                    subtitle: "Allow camera access if prompted."
                )
            case .denied:
                guidanceState(
                    icon: "exclamationmark.triangle.fill",
                    title: "Camera access denied",
                    subtitle: "Enable camera access for Droppy in System Settings.",
                    buttonTitle: "Open Camera Settings",
                    action: openCameraSettings
                )
            case .unavailable:
                guidanceState(
                    icon: "camera.slash.fill",
                    title: "No camera available",
                    subtitle: "Connect a camera and open Mirror again.",
                    buttonTitle: "Retry",
                    action: manager.requestPermissionAndStart
                )
            case .failed(let message):
                guidanceState(
                    icon: "exclamationmark.triangle.fill",
                    title: "Mirror failed to start",
                    subtitle: message,
                    buttonTitle: "Retry",
                    action: manager.requestPermissionAndStart
                )
            case .idle:
                guidanceState(
                    icon: "camera.fill",
                    title: "Mirror is ready",
                    subtitle: "Open your live front camera mirror.",
                    buttonTitle: "Start Mirror",
                    action: manager.requestPermissionAndStart
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(contentPadding)
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.cyan.opacity(0.18)))

            VStack(alignment: .leading, spacing: 1) {
                Text("Mirror")
                    .font(.system(size: 13, weight: .semibold))
                Text("Live front camera preview")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private func progressState(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.9)
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DroppyRadius.large, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func guidanceState(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.cyan)

            Text(title)
                .font(.system(size: 13, weight: .semibold))

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Button(buttonTitle, action: action)
                .buttonStyle(DroppyAccentButtonStyle(color: .cyan, size: .small))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DroppyRadius.large, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DroppyRadius.large, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func openCameraSettings() {
        manager.openCameraSettings()
    }
}

#Preview {
    ZStack {
        Color.black
        MirrorNotchView(manager: MirrorManager.shared, notchHeight: 32)
            .frame(width: 420, height: 180)
    }
}
