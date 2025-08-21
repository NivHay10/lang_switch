; EN↔HE layout flip — selection only + smart Win+Space + CapsLock fix
; Hotkeys: Ctrl+1 / Ctrl+T
; Flow: Cut (^x) → convert → type back (SendText) → CapsFix → Switch layout only if needed → restore Clipboard

#SingleInstance Force
#Requires AutoHotkey v2.0
A_ClipboardTimeout := 1000

; --------- Language IDs (low word of HKL) ---------
; Note: LANGID is the lower 16 bits of the HKL returned by GetKeyboardLayout.
LANG_HE := 0x040D  ; Hebrew

GetCurrentLangId() {
    hWnd := WinGetID("A")
    threadID := DllCall("GetWindowThreadProcessId", "ptr", hWnd, "uint*", 0, "uint")
    hkl := DllCall("GetKeyboardLayout", "uint", threadID, "uptr")
    return (hkl & 0xFFFF) ; LANGID = lower 16 bits
}

IsCurrentHebrew() {
    return GetCurrentLangId() = LANG_HE
}

SwitchLayout() {
    ; Toggle OS keyboard layout via Win+Space (Windows 10/11 default)
    Send("{LWin down}{Space}{LWin up}")
}

; --------- Mappings (US QWERTY ↔ Hebrew standard) ---------
ENG_TO_HE := Map()
ENG_TO_HE["q"] := "/", ENG_TO_HE["w"] := "'", ENG_TO_HE["e"] := "ק", ENG_TO_HE["r"] := "ר"
ENG_TO_HE["t"] := "א", ENG_TO_HE["y"] := "ט", ENG_TO_HE["u"] := "ו", ENG_TO_HE["i"] := "ן"
ENG_TO_HE["o"] := "ם", ENG_TO_HE["p"] := "פ", ENG_TO_HE["["] := "[", ENG_TO_HE["]"] := "]"
ENG_TO_HE["\\"] := "\\", ENG_TO_HE["a"] := "ש", ENG_TO_HE["s"] := "ד", ENG_TO_HE["d"] := "ג"
ENG_TO_HE["f"] := "כ", ENG_TO_HE["g"] := "ע", ENG_TO_HE["h"] := "י", ENG_TO_HE["j"] := "ח"
ENG_TO_HE["k"] := "ל", ENG_TO_HE["l"] := "ך", ENG_TO_HE[";"] := "ף", ENG_TO_HE["'"] := ","
ENG_TO_HE["z"] := "ז", ENG_TO_HE["x"] := "ס", ENG_TO_HE["c"] := "ב", ENG_TO_HE["v"] := "ה"
ENG_TO_HE["b"] := "נ", ENG_TO_HE["n"] := "מ", ENG_TO_HE["m"] := "צ", ENG_TO_HE[","] := "ת"
ENG_TO_HE["."] := "ץ", ENG_TO_HE["/"] := "/"

; Uppercase A–Z map to the same Hebrew letters as their lowercase counterparts
for k, v in ENG_TO_HE {
    if RegExMatch(k, "^[a-z]$")
        ENG_TO_HE[StrUpper(k)] := v
}

; --------- Inverse map: Hebrew-layout → English (includes final forms + Q/W hints) ---------
HE_TO_ENG := Map()
for ek, hv in ENG_TO_HE {
    if RegExMatch(hv, "^[\x{0590}-\x{05FF}]$")
        HE_TO_ENG[hv] := ek
}
; Final forms and related fallbacks
HE_TO_ENG["כ"] := "f", HE_TO_ENG["ך"] := "l", HE_TO_ENG["מ"] := "n", HE_TO_ENG["ם"] := "o"
HE_TO_ENG["נ"] := "b", HE_TO_ENG["ן"] := "i", HE_TO_ENG["צ"] := "m", HE_TO_ENG["ץ"] := "."
HE_TO_ENG["פ"] := "p", HE_TO_ENG["ף"] := ";"
; Layout hints for the Q/W keys when source text is Hebrew:
HE_TO_ENG["/"] := "q"   ; The key that produces '/' on Hebrew layout corresponds to 'q' on US
HE_TO_ENG["'"] := "w"   ; The key that produces ''' on Hebrew layout corresponds to 'w' on US

; --------- Hotkeys ---------
^1::FlipSelection()
^t::FlipSelection()

FlipSelection() {
    saved := ClipboardAll()  ; Save full clipboard (all formats)
    try {
        A_Clipboard := ""
        Send("^x")  ; Cut selection
        if !ClipWait(0.8) {
            ; No text captured—restore and exit
            try Send("^v")
            return
        }

        src := A_Clipboard
        if (src = "") {
            Send("^v")
            return
        }

        converted := FlipLayout(src)
        SendText(converted)
        Sleep(40)  ; Small delay to avoid swallowing subsequent keystrokes

        if (converted != src) {
            ; Decide target keyboard layout based on the converted text
            targetHeb := WantHebrew(converted)

            ; CapsLock fix: if target is Hebrew and CapsLock is toggled → turn it off
            if (targetHeb && GetKeyState("CapsLock", "T"))
                SetCapsLockState("Off")

            currentHeb := IsCurrentHebrew()

            ; Switch layout only if it differs from the desired target
            if (targetHeb && !currentHeb) || (!targetHeb && currentHeb)
                SwitchLayout()
        }
    } finally {
        ; Always restore the original clipboard
        try A_Clipboard := saved
    }
}

; --------- Heuristics ---------
; Decide if the SOURCE text is mostly Hebrew (to select the conversion direction)
IsMostlyHebrew(text) {
    he := StrLen(RegExReplace(text, "[^\x{0590}-\x{05FF}]", ""))
    en := StrLen(RegExReplace(text, "[^A-Za-z]", ""))
    if (he = 0 && en = 0) {
        ; No letters at all: look for layout-hint characters that are typical on Hebrew layout
        return RegExMatch(text, "['/]")
    }
    return he > en
}

; Decide if the TARGET layout should be Hebrew based on the converted text
WantHebrew(text) {
    heCount := StrLen(RegExReplace(text, "[^\x{0590}-\x{05FF}]", ""))
    enCount := StrLen(RegExReplace(text, "[^A-Za-z]", ""))
    return heCount >= enCount && heCount > 0
}

; --------- Core conversion (one-way per source) ---------
FlipLayout(text) {
    fromHeb := IsMostlyHebrew(text)
    out := ""
    for ch in StrSplit(text) {
        if fromHeb {
            ; Hebrew → English: use inverse map only (includes '/'→q and '''→w hints)
            if HE_TO_ENG.Has(ch)
                out .= HE_TO_ENG[ch]
            else
                out .= ch
        } else {
            ; English → Hebrew: use direct map only
            if ENG_TO_HE.Has(ch)
                out .= ENG_TO_HE[ch]
            else
                out .= ch
        }
    }
    return out
}
