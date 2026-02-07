//
//  MirrorManager.swift
//  Droppy
//

import SwiftUI
import Combine
@preconcurrency import AVFoundation

@MainActor
final class MirrorManager: ObservableObject {
    static let shared = MirrorManager()

    enum MirrorState: Equatable {
        case idle
        case requestingPermission
        case running
        case denied
        case unavailable
        case failed(String)
    }

    @Published private(set) var state: MirrorState = .idle
    @Published private(set) var isVisible = false

    @AppStorage(AppPreferenceKey.mirrorInstalled) var isInstalled = PreferenceDefault.mirrorInstalled

    private var startAttemptID: UInt64 = 0
    private let permissionProvider: MirrorCameraPermissionProviding

    nonisolated(unsafe) private let captureSession = AVCaptureSession()
    nonisolated private let sessionQueue = DispatchQueue(label: "app.getdroppy.mirror.session")

    nonisolated var session: AVCaptureSession { captureSession }

    init(permissionProvider: MirrorCameraPermissionProviding) {
        self.permissionProvider = permissionProvider
    }

    convenience init() {
        self.init(permissionProvider: MirrorCameraPermissionService.shared)
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        isVisible = true

        if case .running = state {
            return
        }

        requestPermissionAndStart()
    }

    func hide() {
        isVisible = false
        invalidateStartAttempts()
        stopSession()
        if case .denied = state {
            return
        }
        state = .idle
    }

    func requestPermissionAndStart() {
        let attemptID = beginStartAttempt()

        if permissionProvider.isGranted() {
            startSession(for: attemptID)
            return
        }

        switch permissionProvider.authorizationStatus {
        case .authorized:
            startSession(for: attemptID)
        case .notDetermined:
            state = .requestingPermission
            permissionProvider.request { granted in
                Task { @MainActor in
                    guard self.isAttemptCurrent(attemptID), self.isVisible else { return }
                    if granted {
                        self.startSession(for: attemptID)
                    } else {
                        self.state = .denied
                    }
                }
            }
        case .denied, .restricted:
            guard isAttemptCurrent(attemptID), isVisible else { return }
            state = .denied
        @unknown default:
            guard isAttemptCurrent(attemptID), isVisible else { return }
            state = .failed("Unknown camera authorization status.")
        }
    }

    func configurePreviewConnection(_ connection: AVCaptureConnection?) {
        guard let connection else { return }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    func cleanup() {
        hide()
        isInstalled = false
    }

    func openCameraSettings() {
        permissionProvider.openSettings()
    }

    private func startSession(for attemptID: UInt64) {
        guard isAttemptCurrent(attemptID), isVisible else { return }

        guard permissionProvider.isGranted() else {
            guard isAttemptCurrent(attemptID), isVisible else { return }
            state = .denied
            return
        }

        state = .requestingPermission

        sessionQueue.async { [weak self] in
            guard let self else { return }

            do {
                try self.configureSessionIfNeeded()
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }

                DispatchQueue.main.async {
                    guard self.isAttemptCurrent(attemptID), self.isVisible else { return }
                    guard self.captureSession.isRunning else { return }
                    self.state = .running
                }
            } catch {
                DispatchQueue.main.async {
                    guard self.isAttemptCurrent(attemptID), self.isVisible else { return }
                    if let mirrorError = error as? MirrorSessionError {
                        switch mirrorError {
                        case .noCamera:
                            self.state = .unavailable
                        case .failed(let message):
                            self.state = .failed(message)
                        }
                    } else {
                        self.state = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func beginStartAttempt() -> UInt64 {
        startAttemptID &+= 1
        return startAttemptID
    }

    private func invalidateStartAttempts() {
        startAttemptID &+= 1
    }

    private func isAttemptCurrent(_ attemptID: UInt64) -> Bool {
        attemptID == startAttemptID
    }

    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            // Tear down graph to avoid stale CMIO state across repeated open/close cycles.
            self.captureSession.beginConfiguration()
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            self.captureSession.commitConfiguration()
        }
    }

    nonisolated private func configureSessionIfNeeded() throws {
        guard let device = preferredVideoDevice() else {
            throw MirrorSessionError.noCamera
        }
        print("MirrorManager: Using camera '\(device.localizedName)' type=\(device.deviceType.rawValue) connected=\(device.isConnected) suspended=\(device.isSuspended) inUse=\(device.isInUseByAnotherApplication)")

        if device.isInUseByAnotherApplication {
            throw MirrorSessionError.failed("Camera is currently in use by another application.")
        }

        if !device.isConnected || device.isSuspended {
            throw MirrorSessionError.failed("Selected camera is not available right now.")
        }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high

        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw MirrorSessionError.failed("Unable to connect to camera input.")
        }

        captureSession.addInput(input)
    }

    nonisolated private func preferredVideoDevice() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .externalUnknown
            ],
            mediaType: .video,
            position: .unspecified
        )

        let connectedDevices = discovery.devices.filter { device in
            device.isConnected && !device.isSuspended
        }

        if let frontAvailable = connectedDevices.first(where: { $0.position == .front && !$0.isInUseByAnotherApplication }) {
            return frontAvailable
        }

        if let anyAvailable = connectedDevices.first(where: { !$0.isInUseByAnotherApplication }) {
            return anyAvailable
        }

        if let frontBusy = connectedDevices.first(where: { $0.position == .front }) {
            return frontBusy
        }

        return connectedDevices.first
    }
}

private enum MirrorSessionError: Error {
    case noCamera
    case failed(String)
}
