//
//  IceBarPanel.swift
//  Droppy
//
//  Secondary bar below menu bar that shows hidden menu bar items
//  Similar to Ice's "Ice Bar" feature
//

import SwiftUI
import AppKit
import Combine

// MARK: - IceBar Panel

/// Panel window that appears below the menu bar to show hidden items
@MainActor
final class IceBarPanel: NSPanel {
    
    // MARK: - Properties
    
    private var hostingView: NSHostingView<AnyView>?
    private var items: [MenuBarItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 32),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        configurePanel()
    }
    
    private func configurePanel() {
        title = "Ice Bar"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        allowsToolTipsWhenApplicationIsInactive = true
        isFloatingPanel = true
        animationBehavior = .none
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar + 1
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isOpaque = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        
        configureCancellables()
    }
    
    private func configureCancellables() {
        // Close on space change
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.hide()
            }
            .store(in: &cancellables)
        
        // Close on screen parameter change
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.hide()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Show the IceBar with the given items
    func show(items: [MenuBarItem], anchorFrame: CGRect, screen: NSScreen) {
        self.items = items
        
        // Create content view
        let contentView = IceBarContentView(
            items: items,
            onItemClick: { [weak self] item in
                self?.activateItem(item)
            },
            onClose: { [weak self] in
                self?.hide()
            }
        )
        
        hostingView = NSHostingView(rootView: AnyView(contentView))
        self.contentView = hostingView
        
        // Size to fit content
        let itemWidth: CGFloat = 32
        let padding: CGFloat = 16
        let spacing: CGFloat = 8
        let width = CGFloat(items.count) * (itemWidth + spacing) + padding * 2
        let height: CGFloat = 36
        
        // Position below menu bar, centered on anchor
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let y = screen.frame.maxY - menuBarHeight - height - 4
        let x = (anchorFrame.midX - width / 2).clamped(to: screen.frame.minX...(screen.frame.maxX - width))
        
        setFrame(NSRect(x: x, y: y, width: max(width, 100), height: height), display: true)
        orderFrontRegardless()
        
        print("[IceBar] Showing with \(items.count) items")
    }
    
    /// Hide the IceBar
    func hide() {
        orderOut(nil)
        contentView = nil
        items = []
    }
    
    /// Toggle visibility
    func toggle(items: [MenuBarItem], anchorFrame: CGRect, screen: NSScreen) {
        if isVisible {
            hide()
        } else {
            show(items: items, anchorFrame: anchorFrame, screen: screen)
        }
    }
    
    // MARK: - Item Activation
    
    private func activateItem(_ item: MenuBarItem) {
        // Click the original menu bar item
        // Position in center of item frame
        let clickPoint = CGPoint(x: item.frame.midX, y: item.frame.midY)
        
        // Create click event
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )
        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )
        
        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
        
        hide()
        
        print("[IceBar] Activated item: \(item.displayName)")
    }
}

// MARK: - Comparable Extension

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - IceBar Content View

struct IceBarContentView: View {
    let items: [MenuBarItem]
    let onItemClick: (MenuBarItem) -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if items.isEmpty {
                Text("No hidden items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    IceBarItemButton(item: item) {
                        onItemClick(item)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - IceBar Item Button

struct IceBarItemButton: View {
    let item: MenuBarItem
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Group {
                if let image = item.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let icon = item.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "app")
                        .font(.system(size: 14))
                }
            }
            .frame(width: 20, height: 20)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Color.white.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(item.displayName)
    }
}

// MARK: - Preview

#Preview {
    IceBarContentView(
        items: [],
        onItemClick: { _ in },
        onClose: {}
    )
    .padding()
    .background(Color.black)
}
