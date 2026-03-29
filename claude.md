# OneUp – stav projektu a debug log

## Co je hotovo

Plně funkční Xcode projekt s:
- **Main app** (`OneUp/`) — SwiftUI onboarding, detekce stavu extension
- **Finder Sync Extension** (`OneUpExtension/`) — toolbar tlačítko „Go Up" v Finderu
- App icon (7 velikostí, generovaný přes `scripts/generate_icon.py`)
- GitHub Actions CI (`.github/workflows/release.yml`)
- README, MIT licence, .gitignore

Build: `xcodebuild` hlásí BUILD SUCCEEDED bez errorů.
Extension je registrovaná: `pluginkit -mAvvv -p com.apple.FinderSync | grep oneup` → OK.
Tlačítko v toolbaru Finderu **se zobrazuje** správně.

---

## Problém: navigace nefunguje spolehlivě

Cíl: klik na tlačítko = přechod do nadřazeného adresáře ve **stejném okně** (identické s ⌘↑).

### Co bylo vyzkoušeno

#### 1. NSWorkspace.shared.selectFile (odstraněno)
```swift
NSWorkspace.shared.selectFile(current.path, inFileViewerRootedAtPath: parent.path)
```
**Výsledek:** Otevírá parent folder v **novém okně**. Nevyhovuje.

#### 2. NSWorkspace.shared.open(parentURL) (odstraněno)
```swift
NSWorkspace.shared.open(parent)
```
**Výsledek:** Sandbox error: *„The application OneUp Extension does not have permission to open [složka]"*. Nevyhovuje.

#### 3. NSAppleScript – synchronní i asynchronní (odstraněno)
```swift
let script = "tell application \"Finder\" to tell front window to set target to (parent of target) as alias"
NSAppleScript(source: script)?.executeAndReturnError(nil)
```
**Entitlement:** `com.apple.security.automation.apple-events` → `com.apple.finder`
**Výsledek:** Sandbox **tiše blokuje** bez permission dialogu. Ani `NSAppleEventsUsageDescription` v extension Info.plist nepomohl. Nevyhovuje.

#### 4. CGEvent – synchronní volání uvnitř menu(for:)
```swift
// přímo v menu(for:), bez async
down.post(tap: .cgAnnotatedSessionEventTap)
```
**Výsledek:** Nikdy nefunguje. XPC thread je blokovaný, event se ztratí. Nevyhovuje.

#### 5. CGEvent – async bez zpoždění (původní verze)
```swift
DispatchQueue.global(qos: .userInitiated).async {
    self.postCmdUpEvent() // .cgAnnotatedSessionEventTap
}
```
**Výsledek:** Funguje **nespolehlivě** — někdy až na 3.–4. klik. Finder musí být frontmost ve chvíli doručení eventu.

#### 6. CGEvent – async + 50ms zpoždění
```swift
DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.05) {
    self.postCmdUpEvent()
}
```
**Výsledek:** Nefunguje. 50ms nestačí nebo jiný problém.

#### 7. CGEvent – explicitní aktivace Finderu + 80ms sleep + .cghidEventTap (aktuální stav)
```swift
finder.activate(options: .activateIgnoringOtherApps)
Thread.sleep(forTimeInterval: 0.08)
down.post(tap: .cghidEventTap)
```
**Výsledek:** Nefunguje vůbec. Accessibility permission je udělena (viditelné v System Settings → Accessibility).

---

## Aktuální stav kódu (FinderSync.swift)

```swift
override func menu(for menuKind: FIMenuKind) -> NSMenu {
    if menuKind == .toolbarItemMenu {
        DispatchQueue.global(qos: .userInitiated).async {
            self.goUp()
        }
    }
    return NSMenu() // prázdné menu = přímý klik bez dropdownu
}

private func goUp() {
    if let finder = NSRunningApplication
        .runningApplications(withBundleIdentifier: "com.apple.finder").first {
        finder.activate(options: .activateIgnoringOtherApps)
    }
    Thread.sleep(forTimeInterval: 0.08)

    guard let src = CGEventSource(stateID: .hidSystemState) else { return }
    let upArrow: CGKeyCode = 0x7E
    guard let down = CGEvent(keyboardEventSource: src, virtualKey: upArrow, keyDown: true),
          let up   = CGEvent(keyboardEventSource: src, virtualKey: upArrow, keyDown: false)
    else { return }
    down.flags = .maskCommand
    up.flags   = .maskCommand
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
}
```

---

## Hypotézy pro další session

### A) Sandbox blokuje .cghidEventTap
Možné. `cghidEventTap` vyžaduje vyšší privilegia než `cgAnnotatedSessionEventTap`. Zkusit:
- `.cgSessionEventTap`
- `.cgAnnotatedSessionEventTap` (vrátit se k původnímu)
- Přidat Input Monitoring entitlement?

### B) CGEvent z extension procesu nedorazí do Finderu
Extension běží jako XPC service. Event sice jde do session streamu, ale možná není doručen správně při absenci run loopu na background threadu.
Zkusit: `DispatchQueue.main.asyncAfter(...)` místo `global`.

### C) Zásadně jiný přístup: XPC bridge
Main app (mimo sandbox extension) + Accessibility. Extension → XPC → main app → CGEvent.
Main app potřebuje Accessibility permission, ne extension. Tím se obejde sandbox extension.

### D) Zásadně jiný přístup: AXUIElement
S Accessibility permission manipulovat přímo Finder oknem přes AXUIElement API:
```swift
let app = AXUIElementCreateApplication(finderPID)
// najít front window → nastavit AXDocument/AXURL na parent
AXUIElementSetAttributeValue(window, kAXURLAttribute as CFString, parentURL as CFURL)
```
Možná nejspolehlivější — obejde keyboard event routing úplně.

### E) Zásadně jiný přístup: Jiná architektura
Místo Finder Sync Extension použít **Login Item + Accessibility** bez extension sandboxu.
Nevýhoda: složitější instalace, nutný background process.

---

## Oprávnění udělená uživatelem
- ✅ **Accessibility** — OneUp Extension (System Settings → Privacy & Security → Accessibility)
- ❌ **Automation** — nebylo uděleno (permission dialog se nikdy neobjevil)

## Prostředí
- macOS 15 (Sequoia), Apple Silicon Mac (x86_64 build přes Rosetta nebo nativní — ověřit)
- Xcode 16, Swift 5.9
- Extension běží z DerivedData (ne z /Applications) — ověřit vliv na sandbox
- `pluginkit -e use -i io.github.oneup-app.OneUp.Extension` nutný po každém buildu

## Příkazy pro novou session
```bash
cd /Users/marekcais/Documents/OneUp
pluginkit -mAvvv -p com.apple.FinderSync | grep -A3 oneup  # ověřit registraci
xcodebuild -project OneUp.xcodeproj -scheme OneUp -configuration Debug build  # rebuild
pluginkit -e use -i io.github.oneup-app.OneUp.Extension    # aktivovat po buildu
killall Finder                                              # restartovat Finder
```
