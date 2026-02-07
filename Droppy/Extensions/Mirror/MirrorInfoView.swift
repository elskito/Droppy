//
//  MirrorInfoView.swift
//  Droppy
//

import SwiftUI
@preconcurrency import AVFoundation

struct MirrorInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPreferenceKey.useTransparentBackground) private var useTransparentBackground = PreferenceDefault.useTransparentBackground
    @AppStorage(AppPreferenceKey.mirrorInstalled) private var isInstalled = PreferenceDefault.mirrorInstalled
    @AppStorage(AppPreferenceKey.mirrorEnabled) private var isEnabled = PreferenceDefault.mirrorEnabled
    @ObservedObject private var manager = MirrorManager.shared

    var installCount: Int?
    var rating: AnalyticsService.ExtensionRating?

    private var cameraStatusText: String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return "Granted"
        case .notDetermined:
            return "Not requested"
        case .denied, .restricted:
            return "Denied"
        @unknown default:
            return "Unknown"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .padding(.horizontal, 24)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    featuresSection
                    statusSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(maxHeight: 500)

            Divider()
                .padding(.horizontal, 24)

            footerSection
        }
        .frame(width: 450)
        .fixedSize(horizontal: true, vertical: true)
        .background(useTransparentBackground ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.black))
        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xl, style: .continuous))
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: DroppyRadius.large, style: .continuous)
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: "camera.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.cyan)
            }
            .shadow(color: .cyan.opacity(0.35), radius: 8, y: 4)

            Text("Mirror")
                .font(.title2.bold())

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12))
                    Text("\(installCount ?? 0)")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(.system(size: 12))
                    Text("Camera")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.secondary)

                Text("Productivity")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
            }

            Text("Live camera mirror in your notch")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "camera.fill", text: "Open your camera directly in the notch")
            featureRow(icon: "rectangle.portrait.rotate", text: "Mirrored front-camera view")
            featureRow(icon: "hand.tap", text: "Quick toggle from shelf actions")
            featureRow(icon: "lock.shield", text: "No recording or snapshots in v1")

            RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous)
                .fill(Color.black.opacity(0.75))
                .frame(height: 130)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.cyan.opacity(0.9))
                        Text("Mirror Preview")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Status")
                    .font(.headline)
                Spacer()
                Text(cameraStatusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AdaptiveColors.buttonBackgroundAuto)
                    .clipShape(Capsule())
            }

            if isInstalled {
                Toggle(isOn: $isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Mirror")
                        Text("Show the mirror action icon in expanded notch shelf")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Install Mirror to add the camera icon in the expanded notch actions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(DroppySpacing.lg)
        .background(AdaptiveColors.buttonBackgroundAuto.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.ml, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DroppyRadius.ml, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var footerSection: some View {
        HStack(spacing: 10) {
            Button("Close") {
                dismiss()
            }
            .buttonStyle(DroppyPillButtonStyle(size: .small))

            Spacer()

            if isInstalled {
                DisableExtensionButton(extensionType: .mirror)
            } else {
                Button("Install") {
                    installExtension()
                }
                .buttonStyle(DroppyAccentButtonStyle(color: .cyan, size: .small))
            }
        }
        .padding(DroppySpacing.lg)
    }

    private func installExtension() {
        isInstalled = true
        isEnabled = true
        manager.isInstalled = true
        ExtensionType.mirror.setRemoved(false)

        Task {
            AnalyticsService.shared.trackExtensionActivation(extensionId: "mirror")
        }

        NotificationCenter.default.post(name: .extensionStateChanged, object: ExtensionType.mirror)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.cyan)
                .frame(width: 24)
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    MirrorInfoView()
}
