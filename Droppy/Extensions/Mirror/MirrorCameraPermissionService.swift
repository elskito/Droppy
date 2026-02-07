//
//  MirrorCameraPermissionService.swift
//  Droppy
//

import Foundation
import AppKit
@preconcurrency import AVFoundation

/// Camera permission belongs to Mirror unless another camera feature needs shared logic.
protocol MirrorCameraPermissionProviding {
    var authorizationStatus: AVAuthorizationStatus { get }
    func isGranted() -> Bool
    func request(completion: @escaping (Bool) -> Void)
    func openSettings()
}

final class MirrorCameraPermissionService: MirrorCameraPermissionProviding {
    static let shared = MirrorCameraPermissionService()

    private init() {}

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func isGranted() -> Bool {
        authorizationStatus == .authorized
    }

    func request(completion: @escaping (Bool) -> Void) {
        switch authorizationStatus {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                completion(false)
            }
        case .notDetermined:
            let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
            let bundlePath = Bundle.main.bundlePath
            print("MirrorCameraPermissionService: Requesting camera permission... bundleID=\(bundleID) bundlePath=\(bundlePath)")

            // LSUIElement apps can fail to surface TCC prompts when not frontmost.
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)

                AVCaptureDevice.requestAccess(for: .video) { granted in
                    let statusAfterPrompt = AVCaptureDevice.authorizationStatus(for: .video)
                    print("MirrorCameraPermissionService: Camera request completed granted=\(granted) status=\(statusAfterPrompt.rawValue)")
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            }
        @unknown default:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

    func openSettings() {
        print("MirrorCameraPermissionService: Opening Camera settings...")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }
}
