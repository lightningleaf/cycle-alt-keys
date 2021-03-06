#SingleInstance Force
#InstallKeybdHook ; Needs to be here!
SendMode("Input")
#Warn All, Off

; https://www.autohotkey.com/boards/viewtopic.php?t=69611#p300004
global CYCLE_KEYS := "" ; String of loaded cycle keys.
global INPUT_HOOK := InputHook()
INPUT_HOOK.KeyOpt("{All}", "NV") ; Enable handlers and don't suppress typing.
INPUT_HOOK.OnKeyDown := Func("keyDownHandler")
INPUT_HOOK.OnKeyUp := Func("keyUpHandler")
INPUT_HOOK.BackspaceIsUndo := false ; ?
INPUT_HOOK.Start()
global ON_SHIFT := false ; flag for shift held down
global PRIORKEY_SHIFTED := true ; flag if shift was held during A_PriorKey.

isShift(keyName) {
	return keyName = "LShift" or keyName = "RShift" or keyName = "Shift"
}

; https://www.autohotkey.com/boards/viewtopic.php?t=22036
; Returns number of backspaces needed to clear str.
StrLenUnicode(str) {
	i := 0
	while str {
		str := SubStr(str, (Ord(str) > 65535) ? 3 : 2)
		i++
	}
	return i
}

keyDownHandler(inputHook, vk, sc) {
	key := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
	if InStr(key, CYCLE_KEYS) {
		return
	}

	global ON_SHIFT
	if isShift(key) {
		ON_SHIFT := true
		return
	}

	global PRIORKEY_SHIFTED 
	PRIORKEY_SHIFTED := ON_SHIFT

	; inputHook.Input := "" ; Don't actually need to store any input.
}

keyUpHandler(inputHook, vk, sc) {
	key := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
	if isShift(key) {
		global ON_SHIFT
		ON_SHIFT := false
	}
}

; Storage for CycleAltKeys().
global altKeys := ComObjCreate("Scripting.Dictionary")

; Some constants.
global READ_CYCLE_KEYS_PROMPT := "Choose a file to read cycle keys from..."
global DEFAULT_DEFINITIONS := "definitions\math.txt" ; TODO - move to subdir definitions

; find out how to get absolute path from defaults.txt
; find out how to concat. global strings? didn't seem to work for DEFINITONS_DIR . DEFAULT DEFINITIONS  

; For keys that have no text representing them.
global invisibleKeys := "{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{Backspace}{CapsLock}{NumLock}{PrintScreen}"

; For keys that can be indefinitely held down without effect.
global downKeys := "{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}"

if FileExist(DEFAULT_DEFINITIONS) != "" {
	ReadCycleKeysFromFile(DEFAULT_DEFINITIONS)
}

ModIncrement(ByRef Num, Modulus) { ; Performs modular incrementation on Num.
	Num := Mod(Num + 1, Modulus)
}

CycleAltKeys(hotkeyName) { ; The heart of this script.
	; Turn off the hotkey for the duration of this function.
	; That lets us Send() and recognize it as a typical keystroke.
	Hotkey(A_ThisHotkey, , "Off")
	; A_PriorKey changes after MsgBox for some reason, so we record the "real" priorKey.
	priorKey := A_PriorKey
	; Case sensitivity for priorKey.
	global PRIORKEY_SHIFTED
	if PRIORKEY_SHIFTED {
		priorKey := StrUpper(priorKey)
	}
	; Check altKeys to see if the key pressed before the cycle key actually does have alternative keys.
	; If not, Send() the cycle key.
	if (altKeys.Item[A_ThisHotkey].Exists(priorKey)) {
		Keys := altKeys.Item[A_ThisHotkey].Item[priorKey].Clone()
	}
	else {
		Send(A_ThisHotkey)
		Hotkey(A_ThisHotkey, , "On")	
		return
	}

	Keys.InsertAt(1, priorKey)
	count := 0
	LastKey := A_ThisHotkey
	while (LastKey = A_ThisHotkey) { ; Now cycling.
		Send("{Backspace " . StrLenUnicode(Keys[count+1]) . "}") 
		; MsgBox(StrLen(Keys[count+1])) ; hmmmmm
		; Send ("{Backspace}")
		ModIncrement(count, Keys.Length)
		Send(Keys[count+1])
		hook := InputHook("L1", invisibleKeys) ; https://lexikos.github.io/v2/docs/commands/InputHook.htm#comparison
		; hook.KeyOpt("{All}", "N")
		; hook.OnKeyDown := Func("keyDownHandler")
		; hook.OnKeyUp := Func("keyUpHandler")
		hook.Start()
		hook.Wait()
		LastKey := hook.Input
		; hmmmmmmmmmmmmmm
		keyDownHandler(hook, GetKeyVK(LastKey), GetKeySC(LastKey))
		keyUpHandler(hook, GetKeyVK(LastKey), GetKeySC(LastKey))
		; MsgBox(INPUT_HOOK.Input)
	}


	{ ; Send the last key press when it isn't for cycling.
		switch (hook.EndReason) {
			case "Max" : Send(LastKey)
			case "EndKey" : 
				if InStr(downKeys, hook.EndKey) {
					Send("{" . hook.EndKey . " Down}")
				}
				else if hook.EndKey != "Backspace" { ; Will double backspace without this check.
					Send("{" . hook.EndKey . "}")
				}

			default: throw Exception("Shouldn't go here: " hook.EndReason)
		}
	}
	Hotkey(A_ThisHotkey, , "On")
	; MsgBox(PRIORKEY_SHIFTED)
}

ReadCycleKeysFromFile(fileDir := "") {

	global CYCLE_KEYS := ""

	for oldCycleKey in altKeys {
		Hotkey(oldCycleKey, "Off")
	}
	
	altKeys.RemoveAll()
	
	; Take advantage of the fact that "or" is short-circuiting
	; This will call FileSelect only if fileDir is not "" (evaluates to false)
	fileDir := fileDir or FileSelect(, , READ_CYCLE_KEYS_PROMPT)
	temp := ComObjCreate("Scripting.Dictionary")
	Loop read, fileDir {
		arr := StrSplit(A_LoopReadLine, A_Tab)

		if (arr[1] = "CYCLE_KEY") {
			altKeys.Item[arr[2]] := temp ; .Clone()
			temp := ComObjCreate("Scripting.Dictionary")
		}
		else {
			temp.Item[arr.RemoveAt(1)] := arr
		}
	}
	
	for cycleKey in altKeys {
		CYCLE_KEYS .= cycleKey
		Hotkey(cycleKey, "CycleAltKeys")
		Hotkey(cycleKey, , "On")
		Hotkey("^+" . cycleKey, "readCycleKeysFromFile")
	}
}

F10:: {
	Suspend() ; Any hotkey/hotstring subroutine whose very first line is Suspend (except "Suspend On") will be exempt from suspension.
	if (WinActive("ahk_class PX_WINDOW_CLASS") or WinActive("ahk_class SciTEWindow")) {
		Send("{Ctrl Down}s{Ctrl Up}")
	}
	ToolTip(A_ScriptName " reloaded")
	Reload()
	return
}