#SingleInstance Force
#InstallKeybdHook ; Needs to be here!
SendMode Input

; Storage for CycleAltKeys().
global altKeys := {}

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

ReadCycleKeysFromFile(fileDir := "") {
	for oldCycleKey in altKeys {
		Hotkey(oldCycleKey, "Off")
	}
	
	altKeys := {}
	
	; Take advantage of the fact that "or" is short-circuiting
	; This will call FileSelect only if fileDir is not "" (evaluates to false)
	fileDir := fileDir or FileSelect(, , READ_CYCLE_KEYS_PROMPT)
	temp := {}
	LoopRead(fileDir) {
		arr := StrSplit(A_LoopReadLine, A_Tab)
		if (arr[1] = "CYCLE_KEY") {
			altKeys[arr[2]] := temp.Clone()
			temp := {}
			break
		}
		temp[arr.RemoveAt(1)] := arr
	}
	for cycleKey in altKeys {
		Hotkey(cycleKey, "CycleAltKeys")
		Hotkey(cycleKey, "On")
		Hotkey("^+" . cycleKey, "readCycleKeysFromFile")
	}
}



CycleAltKeys() { ; The heart of this script.
	; Turn off the hotkey for the duration of this function.
	; That lets us Send() and recognize it as a typical keystroke.
	Hotkey(A_ThisHotkey, "Off")
	; Check altKeys to see if the key pressed before the cycle key actually does have alternative keys.
	; If not, Send() the cycle key.
	if (altKeys[A_ThisHotkey].HasKey(A_PriorKey)) {
		Keys := altKeys[A_ThisHotkey][A_PriorKey].Clone()
	}
	else {
		Send(A_ThisHotkey)
		Hotkey(A_ThisHotkey, "On")	
		return
	}
	Keys.InsertAt(1, A_PriorKey)
	count := 0
	LastKey := A_ThisHotkey
	while (LastKey = A_ThisHotkey) { ; Now cycling.
		Send("{Backspace " . StrLen(Keys[count+1]) . "}")
		ModIncrement(count, Keys.MaxIndex())
		Send(Keys[count+1])
		LastKey := Input("L1", invisibleKeys)
	}

	{ ; Sends the last key press when it isn't for cycling.
		ExitKey := InStr(ErrorLevel, ":") ? StrSplit(ErrorLevel, ":")[2] : ErrorLevel
		if ExitKey == "Max"
		{	Send(LastKey)
		} else if InStr(downKeys, ExitKey)
		{	Send("{" . ExitKey . " Down}")
		} else if ExitKey == "Backspace"
		{	Send("{Backspace}")
		} else if ExitKey = "Timeout"
		{ throw Exception("Shouldn't go here: " ErrorLevel)
		} else ; other special chars, like the directional keys
		{ Send("{" . ExitKey . "}")
		}
	}
	Hotkey %A_ThisHotkey%, On
}

ModIncrement(ByRef Num, Modulus) { ; Performs modular incrementation on Num.
	Num := Mod(Num + 1, Modulus)
}

F10::
	Suspend ; Any hotkey/hotstring subroutine whose very first line is Suspend (except "Suspend On") will be exempt from suspension.
	if (WinActive("ahk_class PX_WINDOW_CLASS") or WinActive("ahk_class SciTEWindow")) {
		Send {Ctrl Down}{s}{Ctrl Up}
	}
	ToolTip, %A_ScriptName% reloaded.
	Reload
	return

;~ MsgBox(altKeys["``"]["a"][1])
;~ MsgBox(altKeys["``"]["b"][1])
;~ MsgBox(altKeys["``"]["="][2])