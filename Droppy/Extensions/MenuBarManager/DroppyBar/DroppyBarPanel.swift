//
//  DroppyBarPanel.swift
//  Droppy
//
//  A floating panel that appears below the menu bar to display overflow icons.
//

import Cocoa
import SwiftUI

/// A floating panel that displays overflow menu bar icons below the main menu bar.
@MainActor
final class DroppyBarPanel: NSPanel {
    
    // MARK: - Properties
    
    /// The height of the Droppy Bar
    private let barHeight: CGFloat = 28
    
    /// Padding from the right edge of the screen
    private let rightPadding: CGFloat = 8
    
    /// Timer for auto-hide delay
    private var hideTimer: Timer?
    
    /// Delay before auto-hiding (seconds)
    private let hideDelay: TimeInterval = 0.5
    
    /// Whether the panel should auto-hide when mouse leaves
    var autoHideEnabled: Bool = true
    
    /// Mouse tracking for auto-hide
    private var trackingArea: NSTrackingArea?
    
    // MARK: - Initialization
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: barHeight),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupPanel()
        setupContentView()
    }
    
    private func setupPanel() {
        // Panel appearance
        title = "Droppy Bar"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        backgroundColor = .clear
        hasShadow = true
        
        // Floating behavior
        level = .statusBar + 1
        isFloatingPanel = true
        hidesOnDeactivate = false
        
        // Collection behavior
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        // Don't become key window
        becomesKeyOnlyIfNeeded = true
    }
    
    private func setupContentView() {
        let hostingView = NSHostingView(rootView: DroppyBarContentView())
        hostingView.frame = contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView
    }
    
    // MARK: - Positioning
    
    /// Show the panel on the specified screen
    func show(on screen: NSScreen? = nil) {
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let targetScreen = targetScreen else { return }
        
        updatePosition(for: targetScreen)
        orderFrontRegardless()
        
        print("[DroppyBar] Shown on screen: \(targetScreen.localizedName)")
    }
    
    /// Update the panel position for the given screen
    func updatePosition(for screen: NSScreen) {
        let menuBarHeight: CGFloat = 24
        
        // Calculate width - about 1/3 of screen width, max 400px
        let panelWidth = min(screen.frame.width * 0.33, 400)
        
        // Position: right side of screen, just below menu bar
        let x = screen.frame.maxX - panelWidth - rightPadding
        let y = screen.frame.maxY - menuBarHeight - barHeight - 4 // 4px gap below menu bar
        
        setFrame(NSRect(x: x, y: y, width: panelWidth, height: barHeight), display: true)
    }
    
    // MARK: - Auto-Hide
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        cancelHideTimer()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        scheduleHide()
    }
    
    private func scheduleHide() {
        guard autoHideEnabled else { return }
        
        cancelHideTimer()
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.orderOut(nil)
                print("[DroppyBar] Auto-hidden")
            }
        }
    }
    
    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        hideTimer?.invalidate()
    }
}

// MARK: - DroppyBarContentView

/// SwiftUI content view for the Droppy Bar
struct DroppyBarContentView: View {
    
    var body: some View {
        HStack(spacing: 4) {
            // Placeholder content - will be replaced with actual icons
            Text("Droppy Bar")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Close button
            Button(action: {
                // Will close the panel
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Glassmorphism background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - VisualEffectBlur

/// NSVisualEffectView wrapper for SwiftUI
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
