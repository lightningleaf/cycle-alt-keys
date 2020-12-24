#SingleInstance Force
#InstallKeybdHook ; Needs to be here!
SendMode("Input")
#Warn All, Off

; https://www.autohotkey.com/boards/viewtopic.php?t=69611#p300004
global CYCLE_KEYS := ""
global SHIFTED_KEYS := []
global INPUT_HOOK := InputHook()
INPUT_HOOK.KeyOpt("{All}", "NV")
INPUT_HOOK.OnKeyDown := Func("keyDownHandler")
INPUT_HOOK.OnKeyUp := Func("keyUpHandler")
INPUT_HOOK.BackspaceIsUndo := false
INPUT_HOOK.Start()
global ON_SHIFT := false
global PRIORKEY_SHIFTED := true
; global SHIFT_VKS := [GetKeyVK("LShift"), GetKeyVK("RShift"), GetKeyVK("Shift")]

; INPUT_HOOK.KeyOpt("``", "NV-")
isShift(keyName) {
	return keyName = "LShift" or keyName = "RShift" or keyName = "Shift"
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
	; MsgBox(PRIORKEY_SHIFTED)
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
; global altKeys2 := ComObjCreate("Scripting.Dictionary")

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

; CycleAltKeys2(hotkeyName) {
; 	Hotkey(A_ThisHotkey, , "Off")


; 	cycleKeys := altKeys2.Item[A_ThisHotkey].Keys()

; 	hook := InputHook("L1", invisibleKeys)
; 	hook.Start()
; 	hook.Wait()
; 	; if hook.Input in cycleKeys
; }

CycleAltKeys(hotkeyName) { ; The heart of this script.
	; KeyHistory
	; Turn off the hotkey for the duration of this function.
	; That lets us Send() and recognize it as a typical keystroke.
	Hotkey(A_ThisHotkey, , "Off")
	priorKey := A_PriorKey
	global PRIORKEY_SHIFTED
	; MsgBox(PRIORKEY_SHIFTED)
	if PRIORKEY_SHIFTED {
		priorKey := StrUpper(priorKey)
	}
	; MsgBox(priorKey)
	; Check altKeys to see if the key pressed before the cycle key actually does have alternative keys.
	; If not, Send() the cycle key.o
	;MsgBox, , PriorKey, %A_PriorKey%
	;MsgBox, , PriorHotkey, %A_PriorHotkey%
	;MsgBox, , Shift, %GetKeyState("Shift", "P")%
	; MsgBox(PRIORKEY_SHIFTED) ; A_PriorKey changes after MsgBox...
	; MsgBox(A_ThisHotkey priorKey)
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
	; MsgBox(LastKey A_ThisHotkey)
	while (LastKey = A_ThisHotkey) { ; Now cycling.
		Send("{Backspace " . StrLen(Keys[count+1]) . "}")
		ModIncrement(count, Keys.Length)
		Send(Keys[count+1])
		hook := InputHook("L1", invisibleKeys) ; https://lexikos.github.io/v2/docs/commands/InputHook.htm#comparison
		hook.Start()
		hook.Wait()
		; hook.BackspaceIsUndo := false
		; ErrorLevel := hook.EndReason
		; if (ErrorLevel = "EndKey") {
		; 	ErrorLevel .= ":" hook.EndKey
		; }
		LastKey := hook.Input
	}


	{ ; Sends the last key press when it isn't for cycling.
		; ExitKey := InStr(ErrorLevel, ":") ? StrSplit(ErrorLevel, ":")[2] : ErrorLevel
		; if ExitKey == "Max"
		; {	Send(LastKey)
		; } else if InStr(downKeys, ExitKey)
		; {	Send("{" . ExitKey . " Down}")
		; } else if ExitKey == "Backspace"
		; {	Send("{Backspace}")
		; } else if ExitKey = "Timeout"
		; { throw Exception("Shouldn't go here: " ErrorLevel)
		; } else ; other special chars, like the directional keys
		; { Send("{" . ExitKey . "}")
		; }
		switch (hook.EndReason) {
			case "Max" : Send(LastKey)
			case "EndKey" : 
				if InStr(downKeys, hook.EndKey) {
					Send("{" . hook.EndKey . " Down}")
				}
				; else if hook.EndKey == "Backspace" {
				; 	Send("{Backspace}")
				; }
				else if hook.EndKey != "Backspace" {
					Send("{" . hook.EndKey . "}")
				}

			default: throw Exception("Shouldn't go here: " hook.EndReason)
		}
	}
	Hotkey(A_ThisHotkey, , "On")
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
	
	; lst := "abcdefg"
	; for altKey in altKeys {
		; lst .= altKey "`n"
		; for Key in altKeys.Item[altKey] {
		; 	lst .= Key " "
		; 	; MsgBox("", Key)
		; 	for char in altKeys.Item[altKey].Item[Key] {
		; 		lst .= char " "
		; 	}
		; 	lst .= "`n"
		; }
	; }
	; MsgBox(lst, "Enumerated Keys")
	;MsgBox, , Test, %altKeys.Item["``"].Item["k"][1]%
	;MsgBox, , Test, %altKeys.Item["``"].Item["K"][1]%
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

F9:: {
	global KEY_HISTORY
	str := ""
	for i,key in KEY_HISTORY {
		str .= key " "
	}
	MsgBox(str)
	ExitApp()
}
;~ MsgBox(altKeys["``"]["a"][1])
;~ MsgBox(altKeys["``"]["b"][1])
;~ MsgBox(altKeys["``"]["="][2])