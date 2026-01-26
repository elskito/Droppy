//
//  DroppyBarPanel.swift
//  Droppy
//
//  A beautiful floating panel using native Droppy liquid glass styling.
//

import Cocoa
import SwiftUI

/// A floating panel that displays overflow menu bar icons below the main menu bar.
@MainActor
final class DroppyBarPanel: NSPanel {
    
    // MARK: - Properties
    
    /// The height of the Droppy Bar
    private let barHeight: CGFloat = 36
    
    /// Padding from the right edge of the screen
    private let rightPadding: CGFloat = 12
    
    /// Whether the panel should auto-hide when mouse leaves (disabled by default)
    var autoHideEnabled: Bool = false
    
    // MARK: - Initialization
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: barHeight),
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
        hasShadow = false  // We use SwiftUI shadows instead
        
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
    
    /// Show the panel on the specified screen (or screen with mouse)
    func show(on screen: NSScreen? = nil) {
        // Find the screen with the mouse cursor if not specified
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = screen ?? NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first
        
        guard let targetScreen = targetScreen else { return }
        
        updatePosition(for: targetScreen)
        orderFrontRegardless()
        
        print("[DroppyBar] Shown on screen: \(targetScreen.localizedName)")
    }
    
    /// Update the panel position for the given screen
    func updatePosition(for screen: NSScreen) {
        let menuBarHeight: CGFloat = 24
        
        // Calculate width based on content, min 200, max 500
        let panelWidth = min(max(200, screen.frame.width * 0.25), 500)
        
        // Position: right side of screen, just below menu bar
        let x = screen.frame.maxX - panelWidth - rightPadding
        let y = screen.frame.maxY - menuBarHeight - barHeight - 6
        
        setFrame(NSRect(x: x, y: y, width: panelWidth, height: barHeight), display: true)
    }
}

// MARK: - DroppyBarContentView

/// SwiftUI content view for the Droppy Bar - using native Droppy liquid glass styling
struct DroppyBarContentView: View {
    @AppStorage(AppPreferenceKey.useTransparentBackground) private var useTransparentBackground = PreferenceDefault.useTransparentBackground
    @StateObject private var scanner = MenuBarItemScanner()
    @State private var hoveredItemID: Int?
    @State private var isHoveringRefresh = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Menu bar items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    if scanner.menuBarItems.isEmpty && !scanner.isScanning {
                        Text("No items found")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                    } else if scanner.isScanning {
                        ProgressView()
                            .scaleEffect(0.6)
                            .padding(.horizontal, 8)
                    } else {
                        ForEach(scanner.menuBarItems) { item in
                            DroppyBarIconButton(
                                item: item,
                                isHovered: hoveredItemID == item.id,
                                onHover: { isHovered in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        hoveredItemID = isHovered ? item.id : nil
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer(minLength: 4)
            
            // Refresh button
            Button(action: performScan) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isHoveringRefresh ? .primary : .secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringRefresh = $0 }
            .help("Refresh menu bar icons")
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
        // Use native Droppy liquid glass styling
        .liquidGlass(radius: 12, depth: 0.8, isConcave: false)
        .onAppear(perform: performScan)
    }
    
    private func performScan() {
        if scanner.hasScreenCapturePermission {
            scanner.scanWithCapture()
        } else {
            scanner.scan()
        }
    }
}

// MARK: - DroppyBarIconButton

/// A button that displays a menu bar item icon
struct DroppyBarIconButton: View {
    let item: MenuBarItemScanner.ScannedMenuItem
    let isHovered: Bool
    let onHover: (Bool) -> Void
    
    var body: some View {
        Button(action: activateMenuItem) {
            Group {
                if let icon = item.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                } else {
                    // Fallback: app initial
                    Text(String(item.ownerName.prefix(1)).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(width: 16, height: 16)
                }
            }
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.white.opacity(isHovered ? 0.15 : 0))
            )
            .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .help(item.ownerName)
        .onHover(perform: onHover)
    }
    
    private func activateMenuItem() {
        if let app = NSRunningApplication(processIdentifier: pid_t(item.ownerPID)) {
            app.activate()
            print("[DroppyBar] Activated: \(item.ownerName)")
        }
    }
}
