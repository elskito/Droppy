//
//  MirrorCameraPreviewView.swift
//  Droppy
//

import SwiftUI
import AppKit
@preconcurrency import AVFoundation

@MainActor
struct MirrorCameraPreviewView: NSViewRepresentable {
    @ObservedObject var manager: MirrorManager

    func makeNSView(context: Context) -> MirrorPreviewContainerView {
        let view = MirrorPreviewContainerView()
        // Fill the entire rounded preview frame (no pillarboxing/side bars).
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = manager.session
        manager.configurePreviewConnection(view.previewLayer.connection)
        return view
    }

    func updateNSView(_ nsView: MirrorPreviewContainerView, context: Context) {
        nsView.previewLayer.videoGravity = .resizeAspectFill
        if nsView.previewLayer.session !== manager.session {
            nsView.previewLayer.session = manager.session
        }
        manager.configurePreviewConnection(nsView.previewLayer.connection)
    }
}

final class MirrorPreviewContainerView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true
        layer?.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
    }
}
