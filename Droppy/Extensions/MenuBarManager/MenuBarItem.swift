//
//  MenuBarItem.swift
//  Droppy
//
//  Model representing a discovered menu bar item
//

import Foundation
import AppKit

// MARK: - Menu Bar Section

/// Which section an item belongs to
enum MenuBarSection: String, Codable, CaseIterable, Identifiable {
    case visible       // Always visible in menu bar
    case hidden        // Hidden, shown in IceBar or when expanded
    case alwaysHidden  // Always hidden, only shown when explicitly revealed
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .visible: return "Visible"
        case .hidden: return "Hidden"
        case .alwaysHidden: return "Always Hidden"
        }
    }
    
    var icon: String {
        switch self {
        case .visible: return "eye"
        case .hidden: return "eye.slash"
        case .alwaysHidden: return "eye.slash.fill"
        }
    }
}

// MARK: - Menu Bar Item

/// A discovered menu bar item
struct MenuBarItem: Identifiable, Hashable {
    /// Unique identifier (window ID as string)
    let id: String
    
    /// The window ID from the window server
    let windowID: CGWindowID
    
    /// Name of the owning application
    let ownerName: String
    
    /// PID of the owning process
    let ownerPID: pid_t
    
    /// The window/item name (e.g., "Clock", "Battery")
    let windowName: String?
    
    /// Current frame in screen coordinates
    var frame: CGRect
    
    /// Screenshot of the item
    var image: NSImage?
    
    /// Which section this item belongs to
    var section: MenuBarSection = .visible
    
    /// Whether currently visible on screen
    var isOnScreen: Bool = true
    
    /// Display name for UI
    var displayName: String {
        windowName ?? ownerName
    }
    
    /// App icon for the owning app
    var appIcon: NSImage? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "")
            .first(where: { $0.processIdentifier == ownerPID })?.icon
        ?? NSRunningApplication(processIdentifier: ownerPID)?.icon
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MenuBarItem, rhs: MenuBarItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Factory
    
    /// Create from CGSBridging discovery result
    static func from(_ info: CGSBridging.MenuBarWindowInfo) -> MenuBarItem {
        MenuBarItem(
            id: String(info.windowID),
            windowID: info.windowID,
            ownerName: info.ownerName ?? "Unknown",
            ownerPID: info.ownerPID,
            windowName: info.windowName,
            frame: info.frame
        )
    }
}

// MARK: - Item Assignment Persistence

extension MenuBarItem {
    private static let assignmentsKey = "menuBarItemAssignments"
    
    /// Load saved section assignments
    static func loadAssignments() -> [String: MenuBarSection] {
        guard let data = UserDefaults.standard.data(forKey: assignmentsKey),
              let decoded = try? JSONDecoder().decode([String: MenuBarSection].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    /// Save section assignments
    static func saveAssignments(_ assignments: [String: MenuBarSection]) {
        if let data = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(data, forKey: assignmentsKey)
        }
    }
}
