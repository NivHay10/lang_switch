# lang_switch

# EN↔HE Layout Flip (AutoHotkey v2)

Flip the **currently selected text** between US-English and Hebrew keyboard layouts and type it back **in place**. Smartly fixes **CapsLock** for Hebrew and switches Windows input language via **Win+Space** **only when needed**. Works anywhere on Windows that accepts typed text.

---

## Features

* **Selection-only & safe**: Cuts selection, converts it, types it back, and restores your clipboard.
* **Auto direction**: Detects whether to convert EN→HE or HE→EN using simple heuristics.
* **CapsLock fix**: Turns off CapsLock when the target text is Hebrew.
* **Language switch**: Triggers Win+Space only if the current OS layout doesn’t match the converted text.
* **Hotkeys**: `Ctrl+1` and `Ctrl+T`.
* **Explicit maps**: Uses deterministic character maps (includes uppercase handling and Hebrew final forms).

---

## How It Works (high level)

1. **Cut** the currently selected text to the clipboard.
2. **Decide direction** by counting Latin vs. Hebrew letters (with a small layout-hint fallback).
3. **Convert** characters using EN↔HE maps (one way per source).
4. **Type back** the converted text at the caret (clipboard is restored later).
5. **Fix CapsLock** when typing Hebrew.
6. **Switch OS layout** via Win+Space **only if** the target layout differs from the current one.
7. **Restore** the original clipboard contents.

---

## Requirements

* **Windows 10/11**
* **AutoHotkey v2** (for running from source or building an EXE)

> Compiled EXEs run on any Windows machine **without** AutoHotkey installed.

---

## Quick Start (run from source)

1. **Install AutoHotkey v2**
   Download and install from the official website.

2. **Clone or download** this repository.

3. **Run the script**
   Double-click the `.ahk` file (ensure it’s a v2 script).
   A tray icon should appear.

4. **Use it**

   * Select any text.
   * Press **Ctrl+1** or **Ctrl+T**.
   * The text is flipped and re-typed in place.

---

## Build a Standalone EXE (no AHK required)

### Option A — Ahk2Exe (GUI)

1. Install **AutoHotkey v2** (includes **Ahk2Exe**).
2. Open **Ahk2Exe** (search for “Ahk2Exe” in Start Menu).
3. Set:

   * **Source (Script file):** your `.ahk` script.
   * **Base file:** choose a **v2** base matching your target (e.g., `AutoHotkey64.exe (v2)`).
   * **Custom icon (optional):** pick an `.ico` file.
4. Click **Convert**.
   You’ll get `YourTool.exe` that runs on any Windows machine.

### Option B — Ahk2Exe (CLI)

Run a command like the following (adjust paths as needed):

```bat
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" ^
  /in "C:\path\to\layout_flip.ahk" ^
  /out "C:\path\to\LayoutFlip.exe" ^
  /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ^
  /icon "C:\path\to\icon.ico"
```

**Notes**

* Use the **v2** base (`AutoHotkey64.exe` or `AutoHotkey32.exe` under the v2 folder).
* The resulting **EXE is portable** and does **not** require AutoHotkey on target PCs.

---

## (Optional) Create an Installer

If you want a traditional installer/uninstaller:

* Use **Inno Setup** or **NSIS** to package the compiled EXE.
* Include:

  * Copy to `C:\Program Files\<YourApp>\`
  * Create Start Menu & Desktop shortcuts
  * (Optional) Add a **Startup** shortcut
  * Uninstaller entry in **Apps & Features**

This is optional; the compiled EXE is already portable.

---

## Run at Startup (recommended)

**Method 1 — Startup folder**

1. Press `Win+R`, type:

   ```
   shell:startup
   ```
2. Place a **shortcut** to your EXE in that folder.

**Method 2 — Task Scheduler**

* Create a new **Task** → **At log on** → point to your EXE.
* Useful if you want it to run elevated or with specific conditions.

---

## Hotkeys & Customization

* **Default hotkeys:** `Ctrl+1` and `Ctrl+T`.
* To change them, edit these lines in the script:

  ```ahk
  ^1::FlipSelection()
  ^t::FlipSelection()
  ```

  Examples:

  * `#q::` → `Win+Q`
  * `!f::` → `Alt+F`
  * `+t::` → `Shift+T`

> Keep them unique to avoid conflicts with app shortcuts.

---

## Scope & Limitations

* **Layouts:** Designed for **US English (QWERTY)** ↔ **Hebrew standard**.
* **Selection-only:** You must **select text** first.
* **Password fields:** Many apps block scripted input in protected fields.
* **Clipboard restrictions:** Some apps disallow cutting text (Ctrl+X).
* **Multiple layouts installed:** The script toggles with **Win+Space** once; if you keep more than two layouts, Windows may land on an unintended layout. Prefer keeping exactly **two layouts** (EN & HE) or see the advanced note below.

---

## Advanced: Directly Switch to a Specific Layout (optional)

By default the script uses **Win+Space** (simple and robust).
For setups with **more than two** input languages, consider replacing `SwitchLayout()` with an HKL-based switch (example below). You’ll need the correct **HKL** strings for your system.

```ahk
; Example: direct switch by HKL (advanced)
SwitchToHKL(hklStr) {
    ; hklStr example: "0000040D" for Hebrew, "00000409" for US English
    hkl := DllCall("LoadKeyboardLayout", "str", hklStr, "uint", 1, "uptr")
    if (hkl)
        DllCall("ActivateKeyboardLayout", "uptr", hkl, "uint", 0)
}

; Usage:
; SwitchToHKL("0000040D") ; Hebrew
; SwitchToHKL("00000409") ; US English
```

> This is optional and not required for most users.

---

## Troubleshooting

* **Nothing happens on hotkey press**

  * Ensure the script/EXE is running (tray icon present).
  * Verify you’re using **AutoHotkey v2** if running from source.
  * Some apps require focus; click the text area and try again.

* **“No text captured” message or text isn’t replaced**

  * Ensure text is **selected**.
  * Some controls ignore `Ctrl+X`. Try in another app (e.g., Notepad) to confirm.
  * Increase clipboard wait time in the script (e.g., `ClipWait(1.2)`).

* **Wrong OS layout after conversion**

  * Keep only **two layouts** installed (EN & HE), or implement the **HKL** switch (advanced).

* **SmartScreen/AV warning on EXE**

  * Portable EXEs from small projects often trigger reputation warnings.
  * Optional: **Code-sign** your EXE with a valid certificate to reduce prompts.

---

## Security & Privacy

* Clipboard contents are **saved and restored** within the same action.
* The script does **not** send data anywhere.
* Review the source before use, as with any automation tool.

---

## Development

* Language: **AutoHotkey v2**
* Key parts:

  * `FlipSelection()` – main flow
  * `FlipLayout(text)` – character-by-character conversion
  * `IsMostlyHebrew(text)` / `WantHebrew(text)` – direction heuristics
  * `SwitchLayout()` – OS layout toggle (Win+Space)

---

## License

MIT (recommended). Replace with your preferred license if needed.

---

## Acknowledgements

* AutoHotkey community and documentation for v2.
* Everyone who builds quality text-editing utilities for multilingual users.

---

## FAQ

**Q: Will the EXE run on PCs without AutoHotkey installed?**
A: Yes. The compiled EXE bundles the AHK runtime.

**Q: Can I use different hotkeys?**
A: Yes. Edit the hotkey lines in the script.

**Q: Does it support non-US English layouts?**
A: No. The maps are for **US English (QWERTY)** ↔ **Hebrew**. PRs are welcome.

**Q: Can it auto-flip without selection (whole paragraph)?**
A: This version is **selection-only** by design for safety. You can extend it to work on paragraph scope if needed.
