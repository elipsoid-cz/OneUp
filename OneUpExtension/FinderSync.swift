import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    private static let scriptDirectoryURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Scripts/io.github.oneup-app.OneUp.Extension")
    }()

    private static let scriptURL: URL = {
        scriptDirectoryURL.appendingPathComponent("GoUp.applescript")
    }()

    private static let scriptContent = """
    tell application "Finder"
        try
            set frontWindow to the front Finder window
            set currentFolder to (target of frontWindow) as alias
            set parentPath to container of currentFolder as alias
            set target of frontWindow to parentPath
        end try
    end tell
    """

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        installScript()
    }

    // MARK: - Script Installation

    private func installScript() {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: Self.scriptDirectoryURL, withIntermediateDirectories: true)
            try Self.scriptContent.write(to: Self.scriptURL, atomically: true, encoding: .utf8)
        } catch {
            NSLog("OneUp: Failed to install GoUp script: \(error)")
        }
    }

    // MARK: - Toolbar Item

    override var toolbarItemName: String { "Go Up" }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "arrow.up", accessibilityDescription: "Go to parent folder")
            ?? NSImage(named: NSImage.goRightTemplateName)!
    }

    override var toolbarItemToolTip: String { "Go to Parent Folder (⌘↑)" }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        if menuKind == .toolbarItemMenu {
            DispatchQueue.global(qos: .userInitiated).async {
                self.goUp()
            }
        }
        return NSMenu()
    }

    // MARK: - Navigation

    private func goUp() {
        guard FileManager.default.fileExists(atPath: Self.scriptURL.path) else {
            NSLog("OneUp: GoUp.applescript not found")
            return
        }
        do {
            let task = try NSUserAppleScriptTask(url: Self.scriptURL)
            let semaphore = DispatchSemaphore(value: 0)
            task.execute(withAppleEvent: nil) { result, error in
                if let error = error {
                    NSLog("OneUp: AppleScript error: \(error)")
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 5.0)
        } catch {
            NSLog("OneUp: Failed to load script task: \(error)")
        }
    }
}
