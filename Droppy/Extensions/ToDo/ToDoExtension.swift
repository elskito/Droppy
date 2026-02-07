//
//  ToDoExtension.swift
//  Droppy
//
//  Self-contained definition for Reminders extension
//

import SwiftUI

struct ToDoExtension: ExtensionDefinition {
    static let id = "todo"
    static let title = "Reminders"
    static let subtitle = "Tasks & Notes"
    static let category: ExtensionGroup = .productivity
    static let categoryColor: Color = .blue
    
    static let description = "A lightweight task capture bar and checklist. Supports priorities and auto-cleanup of completed tasks."
    
    static let features: [(icon: String, text: String)] = [
        ("checkmark.circle.fill", "Quick task capture"),
        ("list.bullet", "Priority levels with color coding"),
        ("timer", "Auto-cleanup of completed tasks"),
        ("keyboard", "Keyboard shortcuts for power users")
    ]
    
    static let screenshotURL: URL? = URL(string: "https://getdroppy.app/assets/images/reminders-screenshot.gif")
    static let previewView: AnyView? = AnyView(ToDoPreviewView())
    
    static let iconURL: URL? = URL(string: "https://getdroppy.app/assets/icons/todo.svg")
    static let iconPlaceholder: String = "checklist"
    static let iconPlaceholderColor: Color = .blue
    
    // MARK: - Community Extension
    
    static let isCommunity = true
    static let creatorName: String? = "Valetivivek"
    static let creatorURL: URL? = URL(string: "https://github.com/valetivivek")
    
    static func cleanup() {
        ToDoManager.shared.hide()
    }
}
