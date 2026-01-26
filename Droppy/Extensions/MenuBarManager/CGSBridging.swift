//
//  CGSBridging.swift
//  Droppy
//
//  Swift wrapper for private CGS (CoreGraphics Server) APIs
//  Used for menu bar item discovery and frame calculation
//

import Foundation
import CoreGraphics
import AppKit

// MARK: - CGS Error Extension

extension Int32 {
    /// Check if CGS result was successful (0 = success)
    var isSuccess: Bool { self == 0 }
}

// MARK: - CGS Bridging

/// Namespace for bridged CGS functionality
enum CGSBridging { }

// MARK: - Connection

extension CGSBridging {
    /// The main connection ID to the window server
    static var mainConnectionID: CGSConnectionID {
        CGSMainConnectionID()
    }
}

// MARK: - Window Frame

extension CGSBridging {
    /// Returns the frame for the window with the specified ID
    /// - Parameter windowID: The window ID
    /// - Returns: The window frame in screen coordinates, or nil if failed
    static func getWindowFrame(for windowID: CGWindowID) -> CGRect? {
        var rect = CGRect.zero
        let result = CGSGetScreenRectForWindow(mainConnectionID, windowID, &rect)
        guard result.isSuccess else {
            print("[CGSBridging] CGSGetScreenRectForWindow failed with error \(result)")
            return nil
        }
        return rect
    }
}

// MARK: - Window Lists

extension CGSBridging {
    /// Get total window count
    private static func getWindowCount() -> Int {
        var count: Int32 = 0
        let result = CGSGetWindowCount(mainConnectionID, 0, &count)
        if !result.isSuccess {
            print("[CGSBridging] CGSGetWindowCount failed with error \(result)")
        }
        return Int(count)
    }
    
    /// Get on-screen window count
    private static func getOnScreenWindowCount() -> Int {
        var count: Int32 = 0
        let result = CGSGetOnScreenWindowCount(mainConnectionID, 0, &count)
        if !result.isSuccess {
            print("[CGSBridging] CGSGetOnScreenWindowCount failed with error \(result)")
        }
        return Int(count)
    }
    
    /// Get all window IDs
    private static func getWindowList() -> [CGWindowID] {
        let count = getWindowCount()
        guard count > 0 else { return [] }
        
        var list = [CGWindowID](repeating: 0, count: count)
        var realCount: Int32 = 0
        let result = CGSGetWindowList(mainConnectionID, 0, Int32(count), &list, &realCount)
        
        guard result.isSuccess else {
            print("[CGSBridging] CGSGetWindowList failed with error \(result)")
            return []
        }
        
        return Array(list[..<Int(realCount)])
    }
    
    /// Get on-screen window IDs
    private static func getOnScreenWindowList() -> [CGWindowID] {
        let count = getOnScreenWindowCount()
        guard count > 0 else { return [] }
        
        var list = [CGWindowID](repeating: 0, count: count)
        var realCount: Int32 = 0
        let result = CGSGetOnScreenWindowList(mainConnectionID, 0, Int32(count), &list, &realCount)
        
        guard result.isSuccess else {
            print("[CGSBridging] CGSGetOnScreenWindowList failed with error \(result)")
            return []
        }
        
        return Array(list[..<Int(realCount)])
    }
    
    /// Get menu bar window IDs
    static func getMenuBarWindowList() -> [CGWindowID] {
        let count = getWindowCount()
        guard count > 0 else { return [] }
        
        var list = [CGWindowID](repeating: 0, count: count)
        var realCount: Int32 = 0
        let result = CGSGetProcessMenuBarWindowList(mainConnectionID, 0, Int32(count), &list, &realCount)
        
        guard result.isSuccess else {
            print("[CGSBridging] CGSGetProcessMenuBarWindowList failed with error \(result)")
            return []
        }
        
        return Array(list[..<Int(realCount)])
    }
    
    /// Get on-screen menu bar window IDs
    static func getOnScreenMenuBarWindowList() -> [CGWindowID] {
        let onScreenSet = Set(getOnScreenWindowList())
        return getMenuBarWindowList().filter { onScreenSet.contains($0) }
    }
}

// MARK: - Spaces

extension CGSBridging {
    /// The active space ID
    static var activeSpaceID: CGSSpaceID {
        CGSGetActiveSpace(mainConnectionID)
    }
    
    /// Check if a window is on the active space
    static func isWindowOnActiveSpace(_ windowID: CGWindowID) -> Bool {
        guard let spaces = CGSCopySpacesForWindows(mainConnectionID, kCGSSpaceAll, [windowID] as CFArray) else {
            return false
        }
        
        guard let spaceIDs = spaces.takeRetainedValue() as? [CGSSpaceID] else {
            return false
        }
        
        return spaceIDs.contains(activeSpaceID)
    }
}

// MARK: - Menu Bar Item Discovery

extension CGSBridging {
    /// Discovered menu bar item info
    struct MenuBarWindowInfo {
        let windowID: CGWindowID
        let frame: CGRect
        let ownerPID: pid_t
        let ownerName: String?
        let windowName: String?
    }
    
    /// Discover all menu bar items using both CGS and CGWindow APIs
    static func discoverMenuBarItems() -> [MenuBarWindowInfo] {
        // Get menu bar windows from CGS
        let menuBarWindowIDs = getMenuBarWindowList()
        
        // Also get window info from CGWindowListCopyWindowInfo for owner details
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else {
            print("[CGSBridging] Failed to get window list")
            return []
        }
        
        // Build lookup dictionary
        var windowInfoMap: [CGWindowID: [String: Any]] = [:]
        for info in windowInfoList {
            if let windowID = info[kCGWindowNumber as String] as? CGWindowID {
                windowInfoMap[windowID] = info
            }
        }
        
        // Convert to MenuBarWindowInfo
        var results: [MenuBarWindowInfo] = []
        
        for windowID in menuBarWindowIDs {
            guard let frame = getWindowFrame(for: windowID) else { continue }
            
            let info = windowInfoMap[windowID]
            let ownerPID = info?[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let ownerName = info?[kCGWindowOwnerName as String] as? String
            let windowName = info?[kCGWindowName as String] as? String
            
            results.append(MenuBarWindowInfo(
                windowID: windowID,
                frame: frame,
                ownerPID: ownerPID,
                ownerName: ownerName,
                windowName: windowName
            ))
        }
        
        // Sort by X position (left to right in menu bar)
        results.sort { $0.frame.minX < $1.frame.minX }
        
        print("[CGSBridging] Discovered \(results.count) menu bar items")
        return results
    }
}
