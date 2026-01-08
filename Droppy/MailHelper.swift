//
//  MailHelper.swift
//  Droppy
//
//  Provides AppleScript-based email export functionality for Mail.app
//

import Foundation
import AppKit

/// Helper for exporting emails from Mail.app using AppleScript
class MailHelper {
    static let shared = MailHelper()
    
    private init() {}
    
    /// Exports the currently selected email(s) from Mail.app to .eml files
    /// - Parameter destinationDirectory: Where to save the .eml files
    /// - Returns: Array of URLs to the saved .eml files
    func exportSelectedEmails(to destinationDirectory: URL) async -> [URL] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let savedFiles = self.exportEmailsSync(to: destinationDirectory)
                continuation.resume(returning: savedFiles)
            }
        }
    }
    
    private func exportEmailsSync(to destinationDirectory: URL) -> [URL] {
        // Ensure destination exists
        try? FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        
        let destPath = destinationDirectory.path
        
        // AppleScript to save selected messages as .eml files
        // Mail.app's "source" property returns the raw RFC 822 message source
        let script = """
        tell application "Mail"
            set selectedMessages to selection
            if (count of selectedMessages) = 0 then
                return ""
            end if
            
            set savedFiles to {}
            repeat with msg in selectedMessages
                try
                    set msgSubject to subject of msg
                    set msgSource to source of msg
                    
                    -- Sanitize filename
                    set sanitizedName to my sanitizeFilename(msgSubject)
                    set filePath to "\(destPath)/" & sanitizedName & ".eml"
                    
                    -- Write the source to file
                    set fileRef to open for access POSIX file filePath with write permission
                    write msgSource to fileRef as «class utf8»
                    close access fileRef
                    
                    set end of savedFiles to filePath
                on error errMsg
                    -- Continue with next email
                end try
            end repeat
            
            return savedFiles as text
        end tell
        
        on sanitizeFilename(theText)
            set illegalChars to {"/", ":", "\\\\", "*", "?", "\\"", "<", ">", "|"}
            set sanitized to theText
            repeat with c in illegalChars
                set AppleScript's text item delimiters to c
                set textItems to text items of sanitized
                set AppleScript's text item delimiters to "-"
                set sanitized to textItems as text
            end repeat
            set AppleScript's text item delimiters to ""
            
            -- Truncate to reasonable length
            if length of sanitized > 100 then
                set sanitized to text 1 thru 100 of sanitized
            end if
            
            return sanitized
        end sanitizeFilename
        """
        
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            print("📧 MailHelper: Failed to create AppleScript")
            return []
        }
        
        let result = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            print("📧 MailHelper: AppleScript error: \(error)")
            return []
        }
        
        // Parse the result - it's a comma-separated list of file paths
        guard let resultString = result.stringValue, !resultString.isEmpty else {
            print("📧 MailHelper: No messages exported")
            return []
        }
        
        let filePaths = resultString.components(separatedBy: ", ")
        let fileURLs = filePaths.compactMap { path -> URL? in
            let trimmed = path.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            return URL(fileURLWithPath: trimmed)
        }
        
        print("📧 MailHelper: Exported \(fileURLs.count) email(s)")
        return fileURLs
    }
}
