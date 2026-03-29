import SwiftUI
import FinderSync

struct ContentView: View {
    @State private var isExtensionEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 6) {
                Text("OneUp")
                    .font(.title.bold())
                Text("Go Up button for Finder toolbar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            // Setup steps
            VStack(alignment: .leading, spacing: 20) {
                SetupStep(
                    number: 1,
                    title: "Enable the extension",
                    detail: "System Settings → General → Login Items\n& Extensions → Finder Extensions",
                    isDone: isExtensionEnabled
                )

                SetupStep(
                    number: 2,
                    title: "Add to the Finder toolbar",
                    detail: "In Finder, choose View → Customize Toolbar…\nand drag \"Go Up\" to the toolbar.",
                    isDone: false
                )
            }
            .padding(.horizontal, 40)

            // CTA
            VStack(spacing: 12) {
                Button(action: openExtensionSettings) {
                    Label("Open Extensions Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if isExtensionEnabled {
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Text("Finish Setup")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .controlSize(.large)

                    Label("Extension is enabled — the button works without this app running.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .frame(width: 520)
        .onAppear { refreshStatus() }
        // Re-check when the app comes back to the foreground (user may have
        // just toggled the extension in System Settings).
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in refreshStatus() }
    }

    // MARK: - Helpers

    private func refreshStatus() {
        isExtensionEnabled = FIFinderSyncController.isExtensionEnabled
    }

    private func openExtensionSettings() {
        // macOS 13+: opens General > Login Items & Extensions
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Setup Step View

private struct SetupStep: View {
    let number: Int
    let title: String
    let detail: String
    let isDone: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.green : Color.accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ContentView()
}
