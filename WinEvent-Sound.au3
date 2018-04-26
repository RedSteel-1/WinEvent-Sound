
#include <Date.au3>
#include <File.au3>
#include <GuiConstants.au3>
#include <TrayConstants.au3>



Global $PROGRAM_NAME_SHORT = "Win-Event Sound"
Global $PROGRAM_VERSION = "1.0"
Global $PROGRAM_NAME_LONG = $PROGRAM_NAME_SHORT & " v" & $PROGRAM_VERSION & ", "
Global $PROGRAM_FILE_FULLNAME = @ScriptName
Global $PROGRAM_FILE_NAME = StringSplit($PROGRAM_FILE_FULLNAME, ".", 2)[0]
Global $PROGRAM_DIR = @ScriptDir
Global $PROGRAM_LOG_FILE_NAME = $PROGRAM_FILE_NAME & ".log"
Global $PROGRAM_ICON_FILE = "icons\_program_icon.ico"
Global $PROGRAM_SETTINGS_ICON = "icons\w98_monitor_tweakui.ico"
Global $PROGRAM_INFO_ICON = "icons\w98_msg_information.ico"
Global $PROGRAM_WARNING_ICON = "icons\w98_msg_warning.ico"
Global $PROGRAM_ERROR_ICON = "icons\w98_msg_error.ico"

Global $CONFIG_PATH = $PROGRAM_FILE_NAME & ".cfg"
Global $CONFIG_SETTINGS_SOUND_COUNT = 4
Global $CONFIG_SETTINGS_EXTRA_COUNT = 2
Global $CONFIG_INPUTS[$CONFIG_SETTINGS_SOUND_COUNT * 2 + $CONFIG_SETTINGS_EXTRA_COUNT] = _
										[ _
											"sounds\1998 - Windows 98\The Microsoft Sound.wav", _
											"sounds\1998 - Windows 98\LOGOFF.WAV", _
											"sounds\2001 - Windows XP\Windows XP Logon Sound.wav", _
											"sounds\2001 - Windows XP\Windows XP Logoff Sound.wav", _
											100, 100, 100, 100, _
											200, _
											1 _
										]
Global $CONFIG_LABELS[$CONFIG_SETTINGS_SOUND_COUNT + $CONFIG_SETTINGS_EXTRA_COUNT] = _
										[ _
											"Startup/Logon", _
											"Shutdown/Logoff", _
											"Lock/Sleep", _
											"Unlock", _
											"Loop Iteration Time (ms)", _
											"Low Priority Process" _
										]

Global $SETTINGS_STARTUP_SOUND
Global $SETTINGS_SHUTDOWN_SOUND
Global $SETTINGS_LOCK_SOUND
Global $SETTINGS_UNLOCK_SOUND
Global $SETTINGS_STARTUP_VOLUME
Global $SETTINGS_SHUTDOWN_VOLUME
Global $SETTINGS_LOCK_VOLUME
Global $SETTINGS_UNLOCK_VOLUME
Global $SETTINGS_ITERATION_TIME
Global $SETTINGS_PRIORITY_IS_LOW

Global $CURRENT_PROGRAM_LOCK
Global $CURRENT_CONFIG_DATA
Global $CURRENT_WINDOWS_SESSION_LOCKED
Global $CURRENT_LAST_WINDOWS_SESSION_LOCKED



_Main()



Func _Main()
	_Init()
	_Infinite_Function()
	While 1
		Sleep(100500)
	WEnd
	Exit
EndFunc

Func _Infinite_Function()
	If Not $CURRENT_PROGRAM_LOCK Then
		$CURRENT_PROGRAM_LOCK = True
		AdlibRegister('_Infinite_Function', $SETTINGS_ITERATION_TIME)
		$CURRENT_WINDOWS_SESSION_LOCKED = _IsWorkstationLocked()
		If $CURRENT_LAST_WINDOWS_SESSION_LOCKED <> $CURRENT_WINDOWS_SESSION_LOCKED Then
			If $CURRENT_WINDOWS_SESSION_LOCKED Then
				_Sound_Play($SETTINGS_LOCK_SOUND, $SETTINGS_LOCK_VOLUME)
			Else
				_Sound_Play($SETTINGS_UNLOCK_SOUND, $SETTINGS_UNLOCK_VOLUME)
			EndIf
		EndIf
		$CURRENT_LAST_WINDOWS_SESSION_LOCKED = $CURRENT_WINDOWS_SESSION_LOCKED
		$CURRENT_PROGRAM_LOCK = False
	EndIf
EndFunc

Func _Init()
	AutoItWinSetTitle($PROGRAM_NAME_SHORT)
	$CURRENT_PROGRAM_LOCK = False
	_Init_Config()
	OnAutoItExitRegister('_Exit')
	_Init_Tray()
	_Sound_Play($SETTINGS_STARTUP_SOUND, $SETTINGS_STARTUP_VOLUME, 0)
EndFunc

Func _Exit()
    AdlibUnRegister('_Infinite_Function')
	SoundSetWaveVolume(100)
	_Sound_Play($SETTINGS_SHUTDOWN_SOUND, $SETTINGS_SHUTDOWN_VOLUME)
EndFunc



Func _Sound_Play($file, $volume = 100, $wait = 1)
	SoundSetWaveVolume($volume)
	SoundPlay($file, $wait)
	If $wait = 1 Then SoundSetWaveVolume(100)
EndFunc
Func _Sound_Play__($file, $wait = 1)
	SoundPlay($file, $wait)
EndFunc

Func _Init_Tray()
	Opt("TrayAutoPause", 0)
	Opt("TrayOnEventMode", 1)
	Opt("TrayMenuMode", 2)
	Local $traySettings = TrayCreateItem("Settings")
	Local $trayAbout = TrayCreateItem("About")
	TrayCreateItem("")
	Local $trayReload = TrayCreateItem("Reload")
	TrayItemSetText($TRAY_ITEM_PAUSE, "Suspend")
	TrayItemSetOnEvent($traySettings, "_Configure")
	TrayItemSetOnEvent($trayAbout, "_About")
	TrayItemSetOnEvent($trayReload, "_Restart")
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "_Configure")
	GUISetIcon($PROGRAM_ICON_FILE)
	TraySetIcon($PROGRAM_ICON_FILE)
	_Tray_Text_Set()
EndFunc

Func _Init_Config()
	_FileReadToArray($CONFIG_PATH, $CURRENT_CONFIG_DATA, 0)
	If @error Then
		$CURRENT_CONFIG_DATA = $CONFIG_INPUTS
		_FileWriteFromArray($CONFIG_PATH, $CURRENT_CONFIG_DATA)
		_MessageBox_Create($PROGRAM_WARNING_ICON, "New Config generated", _
			"Config file was invalid or not found. New Config file was generated." & @CRLF & _
			"Don't forget to set it up.")
	EndIf
	$SETTINGS_STARTUP_SOUND = 		$CURRENT_CONFIG_DATA[0]
	$SETTINGS_SHUTDOWN_SOUND =		$CURRENT_CONFIG_DATA[1]
	$SETTINGS_LOCK_SOUND = 			$CURRENT_CONFIG_DATA[2]
	$SETTINGS_UNLOCK_SOUND = 			$CURRENT_CONFIG_DATA[3]
	$SETTINGS_STARTUP_VOLUME = 		$CURRENT_CONFIG_DATA[4]
	$SETTINGS_SHUTDOWN_VOLUME =		$CURRENT_CONFIG_DATA[5]
	$SETTINGS_LOCK_VOLUME = 			$CURRENT_CONFIG_DATA[6]
	$SETTINGS_UNLOCK_VOLUME = 			$CURRENT_CONFIG_DATA[7]
	$SETTINGS_ITERATION_TIME = 	$CURRENT_CONFIG_DATA[8]
	$SETTINGS_PRIORITY_IS_LOW = $CURRENT_CONFIG_DATA[9]
	_Config_Data_Validate()
	If $SETTINGS_PRIORITY_IS_LOW = '1' Then
		ProcessSetPriority(@AutoItPID, $PROCESS_LOW)
	Else
		ProcessSetPriority(@AutoItPID, $PROCESS_NORMAL)
	EndIf
EndFunc

Func _Config_Data_Validate()
	Local $isValid = True
	$isValid = $isValid And FileExists($SETTINGS_STARTUP_SOUND) And FileExists($SETTINGS_SHUTDOWN_SOUND)
	$isValid = $isValid And FileExists($SETTINGS_LOCK_SOUND) And FileExists($SETTINGS_UNLOCK_SOUND)
	$isValid = $isValid And StringIsDigit($SETTINGS_ITERATION_TIME) And $SETTINGS_ITERATION_TIME > 0
	$isValid = $isValid And StringIsDigit($SETTINGS_STARTUP_VOLUME) And $SETTINGS_STARTUP_VOLUME >= 0 And $SETTINGS_STARTUP_VOLUME <= 100
	$isValid = $isValid And StringIsDigit($SETTINGS_SHUTDOWN_VOLUME) And $SETTINGS_SHUTDOWN_VOLUME >= 0 And $SETTINGS_SHUTDOWN_VOLUME <= 100
	$isValid = $isValid And StringIsDigit($SETTINGS_LOCK_VOLUME) And $SETTINGS_LOCK_VOLUME >= 0 And $SETTINGS_LOCK_VOLUME <= 100
	$isValid = $isValid And StringIsDigit($SETTINGS_UNLOCK_VOLUME) And $SETTINGS_UNLOCK_VOLUME >= 0 And $SETTINGS_UNLOCK_VOLUME <= 100
	$isValid = $isValid And StringIsDigit($SETTINGS_PRIORITY_IS_LOW) And ($SETTINGS_PRIORITY_IS_LOW = '0' Or $SETTINGS_PRIORITY_IS_LOW = '1')
	If Not $isValid Then
		_Config_Error()
	EndIf
EndFunc

Func _Config_Error()
	_MessageBox_Create($PROGRAM_ERROR_ICON, "Config Is Invalid!", _
		"The Config file is invalid!" & @CRLF & _
		"The program execution is suspended until the Config is fixed."  & @CRLF & _
		"Alternatively delete the current Config, then restart, and then configure via 'Settings'.")
	_Configure()
EndFunc

Func _Configure()
	TraySetIcon($PROGRAM_SETTINGS_ICON)
	_Tray_Text_Set("SETTINGS")
	SoundSetWaveVolume(100)
	Local $buttonsBrowse[$CONFIG_SETTINGS_SOUND_COUNT]
	Local $buttonsPlay[$CONFIG_SETTINGS_SOUND_COUNT]
	Local $numSettings = $CONFIG_SETTINGS_SOUND_COUNT
	Local $padding = 10
	Local $labelsHeight = 20
	Local $labelsStartY = 15
	Local $labelsNameWidth = 85
	Local $labelsNameStartX = 7
	Local $inputsHeight = $labelsHeight
	Local $inputsStartY = $labelsStartY - 2
	Local $inputsFileWidth = 400
	Local $inputsFileStartX = 7 + $labelsNameStartX + $labelsNameWidth
	Local $buttonsWidth = 50
	Local $buttonsHeight = $labelsHeight
	Local $buttonsBrowseStartX = 7 + $inputsFileStartX + $inputsFileWidth
	Local $buttonsBrowseStartY = $labelsStartY - 3
	Local $labelsVolWidth = 35
	Local $labelsVolStartX = 7 + $buttonsBrowseStartX + $buttonsWidth
	Local $inputsVolWidth = 35
	Local $inputsVolStartX = 7 + $labelsVolStartX + $labelsVolWidth
	Local $buttonsPlayStartX = 7 + $inputsVolStartX + $inputsVolWidth
	Local $buttonsPlayStartY = $buttonsBrowseStartY
	Local $guiWidth = $buttonsPlayStartX + $buttonsWidth + 15
	Local $guiHeight = $labelsStartY + ($numSettings + 1) * ($labelsHeight + $padding)
	Local $extraInputsWidth = 50
	Local $extraInputsStartX1 = $guiWidth / 2 - $extraInputsWidth - $padding * 4
	Local $extraLabelsWidth = 115
	Local $extraLabelsStartX1 = $extraInputsStartX1 - $extraLabelsWidth - $padding
	Local $extraLabelsStartX2 = $guiWidth / 2 + $padding * 4
	Local $extraLabelsStartY = $labelsStartY + ($labelsHeight + $padding) * $numSettings
	Local $extraInputsStartX2 = $extraLabelsStartX2 + $extraLabelsWidth + $padding
	Local $extraInputsStartY = $extraLabelsStartY - 2
	
	Local $gui = GUICreate(StringUpper($PROGRAM_NAME_SHORT) & ": Settings", $guiWidth, $guiHeight, -1, -1, -1, -1, WinGetHandle(AutoItWinGetTitle()))
	For $i = 0 To ($numSettings - 1)
		GUICtrlCreateLabel($CONFIG_LABELS[$i], $labelsNameStartX, $labelsStartY + ($labelsHeight + $padding) * $i, $labelsNameWidth, $labelsHeight, $SS_RIGHT)
		$CONFIG_INPUTS[$i] = GUICtrlCreateInput($CURRENT_CONFIG_DATA[$i], $inputsFileStartX, $inputsStartY + ($inputsHeight + $padding) * $i, $inputsFileWidth, $inputsHeight)
		$buttonsBrowse[$i] = GUICtrlCreateButton("Browse", $buttonsBrowseStartX, $buttonsBrowseStartY + ($buttonsHeight + $padding) * $i, $buttonsWidth, $buttonsHeight)
		GUICtrlCreateLabel("Volume", $labelsVolStartX, $labelsStartY + ($labelsHeight + $padding) * $i, $labelsVolWidth, $labelsHeight, $SS_RIGHT)
		$CONFIG_INPUTS[$i + $numSettings] = _
				GUICtrlCreateInput($CURRENT_CONFIG_DATA[$i + $numSettings], $inputsVolStartX, $inputsStartY + ($inputsHeight + $padding) * $i, $inputsVolWidth, $inputsHeight)
		$buttonsPlay[$i] = GUICtrlCreateButton("Play", $buttonsPlayStartX, $buttonsPlayStartY + ($buttonsHeight + $padding) * $i, $buttonsWidth, $buttonsHeight)
	Next
	GUICtrlCreateLabel($CONFIG_LABELS[$numSettings], $extraLabelsStartX1, $extraLabelsStartY, $extraLabelsWidth, $labelsHeight, $SS_RIGHT)
	$CONFIG_INPUTS[$numSettings * 2] = GUICtrlCreateInput($CURRENT_CONFIG_DATA[$numSettings * 2], $extraInputsStartX1, $extraInputsStartY, $extraInputsWidth, $inputsHeight)
	GUICtrlCreateLabel($CONFIG_LABELS[$numSettings + 1], $extraLabelsStartX2, $extraLabelsStartY, $extraLabelsWidth, $labelsHeight, $SS_RIGHT)
	$CONFIG_INPUTS[$numSettings * 2 + 1] = GUICtrlCreateInput($CURRENT_CONFIG_DATA[$numSettings * 2 + 1], $extraInputsStartX2, $extraInputsStartY, $extraInputsWidth, $inputsHeight)
	GUISetState(@SW_SHOW, $gui)
	While 1
		Switch GUIGetMsg()
			Case $buttonsBrowse[0]
				_Config_Button_Browse(0)
			Case $buttonsBrowse[1]
				_Config_Button_Browse(1)
			Case $buttonsBrowse[2]
				_Config_Button_Browse(2)
			Case $buttonsBrowse[3]
				_Config_Button_Browse(3)
			Case $buttonsPlay[0]
				_Config_Button_Play(0)
			Case $buttonsPlay[1]
				_Config_Button_Play(1)
			Case $buttonsPlay[2]
				_Config_Button_Play(2)
			Case $buttonsPlay[3]
				_Config_Button_Play(3)
            Case $GUI_EVENT_CLOSE
				_Config_Read_Inputs()
				ExitLoop
			Case $GUI_EVENT_MINIMIZE
				_Config_Read_Inputs()
				ExitLoop
        EndSwitch
	WEnd
	GUIDelete($gui)
	_Sound_Play("", 0, 0)
	SoundSetWaveVolume(100)
	FileChangeDir($PROGRAM_DIR)
	_FileWriteFromArray($CONFIG_PATH, $CURRENT_CONFIG_DATA)
	TraySetIcon($PROGRAM_ICON_FILE)
	_Tray_Text_Set()
	_Init_Config()
EndFunc

Func _Config_Read_Inputs()
	For $i = 0 To ($CONFIG_SETTINGS_SOUND_COUNT - 1)
		$CURRENT_CONFIG_DATA[$i] = StringReplace(GUICtrlRead($CONFIG_INPUTS[$i]), $PROGRAM_DIR & "\", "")
	Next
	For $i = $CONFIG_SETTINGS_SOUND_COUNT To ($CONFIG_SETTINGS_SOUND_COUNT * 2 + $CONFIG_SETTINGS_EXTRA_COUNT - 1)
		$CURRENT_CONFIG_DATA[$i] = GUICtrlRead($CONFIG_INPUTS[$i])
	Next
EndFunc

Func _Config_Button_Browse($index)
	Local $last = $CURRENT_CONFIG_DATA[$index]
	Local $dir = StringLeft($CURRENT_CONFIG_DATA[$index], StringInStr($CURRENT_CONFIG_DATA[$index], "\", 0, -1))
	If Not StringInStr($dir, ":\") Then $dir = $PROGRAM_DIR & "\" & $dir
	FileChangeDir($dir)
	$CURRENT_CONFIG_DATA[$index] = FileOpenDialog("Choose " & $CONFIG_LABELS[$index] & " Sound File", $dir, "Sounds (*.wav;*.mp3)", $FD_FILEMUSTEXIST)
	If $CURRENT_CONFIG_DATA[$index] = "" Then
		$CURRENT_CONFIG_DATA[$index] = $last
	Else
		GUICtrlSetData($CONFIG_INPUTS[$index], StringReplace($CURRENT_CONFIG_DATA[$index], $PROGRAM_DIR & "\", ""))
	EndIf
	FileChangeDir($PROGRAM_DIR)
EndFunc

Func _Config_Button_Play($index)
	For $i = $CONFIG_SETTINGS_SOUND_COUNT To ($CONFIG_SETTINGS_SOUND_COUNT * 2 - 1)
		$CURRENT_CONFIG_DATA[$i] = GUICtrlRead($CONFIG_INPUTS[$i])
	Next
	_Sound_Play($CURRENT_CONFIG_DATA[$index], $CURRENT_CONFIG_DATA[$index + $CONFIG_SETTINGS_SOUND_COUNT], 0)
EndFunc

Func _About()
	TraySetIcon($PROGRAM_INFO_ICON)
	_Tray_Text_Set("ABOUT")
	_MessageBox_Create($PROGRAM_INFO_ICON, "About", _
				$PROGRAM_NAME_SHORT & " v" & $PROGRAM_VERSION & @CRLF & _
				@CRLF & _
				"by Alexander Agafonov" & @CRLF & _
				@CRLF & _
				"<Je ferais une fête folle, mais je suis juste un programme.../>")
	TraySetIcon($PROGRAM_ICON_FILE)
	_Tray_Text_Set()
EndFunc

Func _Restart()
	If @Compiled = 1 Then
        Run($PROGRAM_FILE_FULLNAME)
    Else
        Run(FileGetShortName(@AutoItExe) & " " & $PROGRAM_FILE_FULLNAME)
    EndIf
    Exit
EndFunc



Func _MessageBox_Create($icon, $title, $text)
	Switch $icon
		Case $PROGRAM_INFO_ICON
			$icon = $MB_ICONINFORMATION
		Case $PROGRAM_WARNING_ICON
			$icon = $MB_ICONWARNING
		Case $PROGRAM_ERROR_ICON
			$icon = $MB_ICONERROR
	EndSwitch
	Return MsgBox($icon, StringUpper($PROGRAM_NAME_SHORT) & ": " & $title, $text, 0, WinGetHandle(AutoItWinGetTitle()))
EndFunc

Func _Tray_Text_Set($firstLine = "")
	Local $currentTrayText = $PROGRAM_NAME_SHORT
	If Not ($firstLine = "") Then $currentTrayText = $currentTrayText & ": " & $firstLine
	TraySetToolTip($currentTrayText)
	; https://www.autoitscript.com/forum/topic/146910-how-to-refresh-traytooltip-display/#comment-1219352
	Local $tooltipsArray = WinList("[CLASS:tooltips_class32]")
    For $i = 1 To $tooltipsArray[0][0]
        If WinGetTitle($tooltipsArray[$i][1]) == $currentTrayText Then
			DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $tooltipsArray[$i][1], "uint", 0x41D, "wparam", 0, "lparam", 0)
		EndIf
    Next
	Return $currentTrayText
EndFunc

Func _IsWorkstationLocked()
    Local Const $WTS_CURRENT_SERVER_HANDLE = 0
    Local Const $WTS_CURRENT_SESSION = -1
    Local Const $WTS_SESSION_INFO_EX = 25
    Local $hWtsapi32dll = DllOpen("Wtsapi32.dll")
    Local $result = DllCall($hWtsapi32dll, "int", "WTSQuerySessionInformation", "int", $WTS_CURRENT_SERVER_HANDLE, "int", _
							$WTS_CURRENT_SESSION, "int", $WTS_SESSION_INFO_EX, "ptr*", 0, "dword*", 0)
    If ((@error) OR ($result[0] == 0)) Then
        Return SetError(1, 0, False)
    EndIf
    Local $buffer_ptr = $result[4]
    Local $buffer_size = $result[5]
    Local $buffer = DllStructCreate("uint64 SessionId;uint64 SessionState;int SessionFlags;byte[" & $buffer_size - 20 & "]", $buffer_ptr)
    Local $isLocked = (DllStructGetData($buffer, "SessionFlags") == 0)
    $buffer = 0
    DllCall($hWtsapi32dll, "int", "WTSFreeMemory", "ptr", $buffer_ptr)
    DllClose($hWtsapi32dll)
    Return $isLocked
EndFunc



Func _Log_WriteLnSimple($text)
	_Log_WriteLnAdv($text, True)
EndFunc
Func _Log_WriteLnAdv($text, $includeTime)
	_Log_WriteAdv($text & @CRLF, $includeTime)
EndFunc
Func _Log_WriteSimple($text)
	_Log_WriteAdv($text, True)
EndFunc
Func _Log_WriteAdv($text, $includeTime)
	If $includeTime Then
		FileWrite($PROGRAM_LOG_FILE_NAME, "[" & _Now() & "] " & StringReplace($text, "\n", @CRLF))
	Else
		FileWrite($PROGRAM_LOG_FILE_NAME, StringReplace($text, "\n", @CRLF))
	EndIf
EndFunc




