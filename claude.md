# OneUp

macOS Finder Sync Extension — toolbar tlačítko „Go Up" pro navigaci do nadřazeného adresáře ve stejném okně (ekvivalent ⌘↑).

## Architektura

- **Main app** (`OneUp/`) — SwiftUI onboarding UI + instalace AppleScriptu při spuštění
- **Finder Sync Extension** (`OneUpExtension/`) — toolbar tlačítko, spouští AppleScript přes `NSUserAppleScriptTask`
- **GitHub Pages** (`docs/`) — landing page (HTML/CSS, Clean design system)

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

## Release a distribuce

App je distribuována **bez Apple Developer certifikátu** (ad-hoc signing). Uživatelé musí při prvním spuštění obejít Gatekeeper: pravý klik → Open → Open Anyway, nebo `xattr -cr /Applications/OneUp.app`.

Release workflow (`.github/workflows/release.yml`) se spustí při push tagu `v*`:
1. Build & archive s ad-hoc signing (`CODE_SIGN_IDENTITY="-"`)
2. Vytvoření DMG (`create-dmg`)
3. Upload DMG do GitHub Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

Žádné GitHub Secrets nejsou potřeba — workflow nevyžaduje certifikát ani Apple ID.

### GitHub Pages

Landing page v `docs/index.html` — nasadit přes GitHub repo → Settings → Pages → Source: branch `master`, folder `/docs`.

Dev server lokálně:
```bash
python3 -m http.server 3000 --directory docs
```
(nebo přes `.claude/launch.json` + `preview_start`)

### Homebrew (budoucnost)

Až bude první release: vytvořit repo `elipsoid-cz/homebrew-oneup` s `Casks/oneup.rb`.
```
brew tap elipsoid-cz/oneup && brew install --cask oneup
```

## Odinstalace

Žádný automatický uninstall mechanismus zatím neexistuje. Manuální postup:

1. Zavřít OneUp a odebrat z Login Items (System Settings → General → Login Items)
2. Zakázat extension — System Settings → Privacy & Security → Extensions → Finder Extensions
3. Smazat `OneUp.app` z `/Applications`
4. Smazat AppleScript: `~/Library/Application Scripts/io.github.oneup-app.OneUp.Extension/GoUp.applescript`
5. Restartovat Finder: `killall Finder`

Do budoucna: přidat tlačítko "Uninstall" přímo do appky.

## Prostředí

- macOS 15 (Sequoia), Apple Silicon
- Xcode 16, Swift 5.9
- Deployment target: macOS 13.0
