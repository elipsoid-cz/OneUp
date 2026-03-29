# OneUp

macOS Finder Sync Extension — toolbar tlačítko „Go Up" pro navigaci do nadřazeného adresáře ve stejném okně (ekvivalent ⌘↑).

## Architektura

- **Main app** (`OneUp/`) — SwiftUI onboarding UI + instalace AppleScriptu při spuštění
- **Finder Sync Extension** (`OneUpExtension/`) — toolbar tlačítko, spouští AppleScript přes `NSUserAppleScriptTask`

## Jak funguje navigace

Extension nemůže přímo ovládat Finder (sandbox blokuje NSAppleScript i CGEvent). Řešení:

1. **Main app** při startu nainstaluje `GoUp.applescript` do `~/Library/Application Scripts/io.github.oneup-app.OneUp.Extension/`
2. **Extension** při kliknutí na tlačítko spustí skript přes `NSUserAppleScriptTask` — ten běží mimo sandbox
3. Skript řekne Finderu: `set target of front window to container of target`

Main app musí být **bez sandboxu** (nemá `com.apple.security.app-sandbox`), protože potřebuje zapisovat do extension Application Scripts adresáře. Extension je sandboxovaná (povinné pro Finder Sync).

## Oprávnění

- **Automation** (Finder) — systém se zeptá automaticky při prvním kliknutí na tlačítko
- Accessibility **není potřeba**

## Vyzkoušené a nefunkční přístupy

Všechny selhávají kvůli sandboxu Finder Sync Extension:
- `NSWorkspace.selectFile` → otevírá nové okno
- `NSWorkspace.open` → sandbox permission error
- `NSAppleScript` přímo z extension → tiše blokován, dialog se neobjeví
- `CGEvent` (⌘↑ injection) → nespolehlivé/nefunkční z XPC procesu

## Build a deploy

```bash
xcodebuild -project OneUp.xcodeproj -scheme OneUp -configuration Debug build
pluginkit -e use -i io.github.oneup-app.OneUp.Extension
killall Finder
```

Main app je nutné spustit alespoň jednou (nainstaluje skript). Poté může být zavřená.

## Prostředí

- macOS 15 (Sequoia), Apple Silicon
- Xcode 16, Swift 5.9
- Deployment target: macOS 13.0
