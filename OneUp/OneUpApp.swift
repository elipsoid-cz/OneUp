import SwiftUI

@main
struct OneUpApp: App {

    init() {
        Self.installExtensionScript()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 340)
    }

    private static func installExtensionScript() {
        let scriptDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Scripts/io.github.oneup-app.OneUp.Extension")
        let scriptURL = scriptDir.appendingPathComponent("GoUp.applescript")
        let content = """
        tell application "Finder"
            try
                set frontWindow to the front Finder window
                set currentFolder to (target of frontWindow) as alias
                set parentPath to container of currentFolder as alias
                set target of frontWindow to parentPath
            end try
        end tell
        """
        do {
            try FileManager.default.createDirectory(at: scriptDir, withIntermediateDirectories: true)
            try content.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            NSLog("OneUp: Failed to install GoUp script: \(error)")
        }
    }
}
