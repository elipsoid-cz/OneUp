import SwiftUI
import FinderSync

struct ContentView: View {
    @State private var isExtensionEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 80, height: 80)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 36)

                Text("OneUp for Finder")
                    .font(.title.bold())

                Text("Adds a **Go Up** button to the Finder toolbar so you can navigate\nto the parent folder with a single click — just like ⌘↑.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)

            Divider()
                .padding(.vertical, 28)

            // Setup steps
            VStack(alignment: .leading, spacing: 20) {
                SetupStep(
                    number: 1,
                    title: "Enable the extension",
                    detail: "Click below to open System Settings, then enable OneUp under\nGeneral → Login Items & Extensions → Finder Extensions.",
                    isDone: isExtensionEnabled
                )

                SetupStep(
                    number: 2,
                    title: "Add the button to the Finder toolbar",
                    detail: "In Finder, choose View → Customize Toolbar… and drag the\n\"Go Up\" button to the desired position.\n\nTip: You can also rearrange toolbar buttons anytime\nby ⌘-dragging them.",
                    isDone: false
                )
            }
            .padding(.horizontal, 40)

            Spacer(minLength: 28)

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
                        Text("Quit OneUp")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .controlSize(.large)

                    Label("Extension is enabled — you can safely quit this app.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else {
                    Text("You can quit this app after enabling the extension.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
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
