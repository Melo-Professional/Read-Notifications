;@region Setup
;@region Description
/************************************************************************
 * @description Read Notifications turns Windows notifications into instant voice alerts using Text-to-Speech.
 * @author Melo (melo@meloprofessional.com)
 * @credits @Malcev https://www.autohotkey.com/boards/viewtopic.php?f=76&t=76103
 * @date 2026/06/13
 * @releasedate 2025/03/25
 * @version 2.76.1.0
 ***********************************************************************/

AppName := "Read Notifications"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "2.76.1.0"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Read Notifications turns Windows notifications into instant voice alerts using Text-to-Speech."
;@endregion

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
; --- Optimization Settings ---
ListLines(False)
KeyHistory(0)
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_Theme>
#Include *i <_SplashScreen>
#Include *i <_About>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <SettingsFuncs>
#Include <GuiPrograms>
#Include <GuiVoiceSettings>
;@endregion

;@region Startup
if IsSet(SplashScreen){
    SplashScreen()
}

; TRAY ICON + MENU
StartMenu()
Menu_Custom()

; TTS INITIALIZATION
SettingsLoadVoiceSettings()
global oVoice   := ComObject("SAPI.SpVoice")
global voices   := oVoice.GetVoices()

; FIRST SPEAK
Speak(App.Name)

;@endregion

SettingsLoadProgramsList()


;@region HelperFunctions
Speak(phrase, voiceNum := VoiceNumber, rate := VoiceRate, vol := VoiceVolume, ignoreDND := false) {
    oVoice.Volume   := vol
    oVoice.Rate     := rate
    oVoice.Voice    := voices.Item(voiceNum - 1)
    if (ignoreDND || !SystemStateDND() || (SystemStateDND() && !RespectDND)) ; Check DND clearance
        SetTimer(() => oVoice.Speak(phrase, 1), -1)
}

SystemStateDND() {
    try {
        val := RegRead(DNDRegistryKeyName, DNDRegistryValueName)
        if (StrLen(val) < 10)
            return false
        state := SubStr(val, 9, 2)
        return (state = "01")
    } catch as err {
        MsgBoxCustom(
            "Could not read DND (Do Not Disturb) value from:`n`n" DNDRegistryKeyName "\" DNDRegistryValueName "`n`n"
            "Error: " err.Message "`n"
            "File: " err.File "`n"
            "Line: " err.Line "`n"
            "Extra: " err.Extra
        )
    }
}
;@endregion


;@region Main Core Initialization
; WinRT NOTIFICATION LISTENER
DllCall("Combase.dll\WindowsCreateString", "WStr", "Windows.UI.Notifications.Management.UserNotificationListener", "UInt", 60, "Ptr*", &hString := 0)
GUID_ListenerStatics := Buffer(16)
DllCall("ole32\CLSIDFromString", "WStr", "{FF6123CF-4386-4AA3-B73D-B804E5B63B23}", "Ptr", GUID_ListenerStatics)

UserNotificationListenerStatics := 0
result := DllCall("Combase.dll\RoGetActivationFactory", "Ptr", hString, "Ptr", GUID_ListenerStatics, "Ptr*", &UserNotificationListenerStatics, "UInt")
DllCall("Combase.dll\WindowsDeleteString", "Ptr", hString)

if (result != 0) {
    MsgBoxCustom("Error initializing WinRT Activation Factory: " result, , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
}

listener := 0
ComCall(6, UserNotificationListenerStatics, "Ptr*", &listener)

accessStatusObj := 0
ComCall(6, listener, "Ptr*", &accessStatusObj)

AsyncInfo_Init := ComObjQuery(accessStatusObj, "{00000036-0000-0000-C000-000000000046}")
Loop {
    status_init := 0
    ComCall(7, AsyncInfo_Init, "UInt*", &status_init)
    if (status_init != 0) {
        if (status_init != 1) {
            errorCode := 0
            ComCall(8, AsyncInfo_Init, "UInt*", &errorCode)
            MsgBoxCustom("Async Access Error: " errorCode, , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
        }
        break
    }
    Sleep(10)
}
;ObjRelease(AsyncInfo_Init)

accessStatus := 0
ComCall(8, accessStatusObj, "Int*", &accessStatus)
ObjRelease(accessStatusObj)

if (accessStatus != 1) {
    MsgBoxCustom("AccessStatus Denied", , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
}

global idList := ""
global starting := true

; Establish initial baseline tracking of active notifications
MainLoop()

; Activate loop pooling ticker via your variable settings duration
SetTimer(MainLoop, sleepDuration)


; ======================================================================
; UPGRADED ENGINE CORE: FLAT STREAM PARSING
; ======================================================================

MainLoop() {
    global idList, starting, ReadContent, ScriptPaused, ReadAny, ProgramsList, Debug

    ; Early exit guard clause if script processing is suspended
    if (ScriptPaused)
        return

    UserNotificationReadOnlyListObj := 0
    if ComCall(10, listener, "Int", 1, "Ptr*", &UserNotificationReadOnlyListObj) != 0
        return
    
    LocalAsyncInfo := ComObjQuery(UserNotificationReadOnlyListObj, "{00000036-0000-0000-C000-000000000046}")
    if (!LocalAsyncInfo) {
        ObjRelease(UserNotificationReadOnlyListObj)
        return
    }

    Loop {
        asyncStatus := 0 
        ComCall(7, LocalAsyncInfo, "UInt*", &asyncStatus)
        if (asyncStatus != 0)
            break
        Sleep(10)
    }
    ;ObjRelease(LocalAsyncInfo)
    
    UserNotificationReadOnlyList := 0
    ComCall(8, UserNotificationReadOnlyListObj, "Ptr*", &UserNotificationReadOnlyList)
    ObjRelease(UserNotificationReadOnlyListObj)

    if (!UserNotificationReadOnlyList)
        return

    count := 0
    ComCall(7, UserNotificationReadOnlyList, "Int*", &count)

    Loop count {
        UserNotification := 0
        try {
            if ComCall(6, UserNotificationReadOnlyList, "Int", A_Index - 1, "Ptr*", &UserNotification) != 0 || !UserNotification
                continue

            id := 0
            ComCall(8, UserNotification, "UInt*", &id)

            ; Process only unseen notifications
            if InStr(idList, "|" id "|")
                continue
            
            idList .= "|" id "|"

            ; If initializing the script baseline, don't read out past history
            if (starting)
                continue

            AppInfo := 0
            if ComCall(7, UserNotification, "Ptr*", &AppInfo) != 0 || !AppInfo
                continue

            AppDisplayInfo := 0
            ComCall(8, AppInfo, "Ptr*", &AppDisplayInfo)
            ObjRelease(AppInfo)
            
            if (!AppDisplayInfo)
                continue

            hText := 0
            ComCall(6, AppDisplayInfo, "Ptr*", &hText)
            ObjRelease(AppDisplayInfo)

            if (!hText)
                continue

            length := 0
            bufferPtr := DllCall("Combase.dll\WindowsGetStringRawBuffer", "Ptr", hText, "UInt*", &length, "Ptr")
            appNameText := StrGet(bufferPtr, "UTF-16")
            DllCall("Combase.dll\WindowsDeleteString", "Ptr", hText)

            ; Determine application filter clearance via early validation drops
            shouldRead := false
            if (!ReadAny && !Debug) {
                for newapp in ProgramsList {
                    if (appNameText = newapp) {
                        shouldRead := true
                        break
                    }
                }
            } else {
                shouldRead := true
            }

            if (!shouldRead)
                continue

            notificationText := ""

            if (ReadContent) {
                NotificationObj := 0
                ComCall(6, UserNotification, "Ptr*", &NotificationObj)
                if (NotificationObj) {
                    NotificationVisual := 0
                    ComCall(8, NotificationObj, "Ptr*", &NotificationVisual)
                    ObjRelease(NotificationObj)
                    
                    if (NotificationVisual) {
                        NotificationBindingList := 0
                        ComCall(8, NotificationVisual, "Ptr*", &NotificationBindingList)
                        ObjRelease(NotificationVisual)
                        
                        if (NotificationBindingList) {
                            bindingCount := 0
                            ComCall(7, NotificationBindingList, "Int*", &bindingCount)
                            
                            Loop bindingCount {
                                NotificationBinding := 0
                                ComCall(6, NotificationBindingList, "Int", A_Index - 1, "Ptr*", &NotificationBinding)
                                
                                if (NotificationBinding) {
                                    AdaptiveNotificationTextReadOnlyList := 0
                                    ComCall(11, NotificationBinding, "Ptr*", &AdaptiveNotificationTextReadOnlyList)
                                    ObjRelease(NotificationBinding)
                                    
                                    if (AdaptiveNotificationTextReadOnlyList) {
                                        textCount := 0
                                        ComCall(7, AdaptiveNotificationTextReadOnlyList, "Int*", &textCount)
                                        
                                        Loop textCount {
                                            AdaptiveNotificationText := 0
                                            ComCall(6, AdaptiveNotificationTextReadOnlyList, "Int", A_Index - 1, "Ptr*", &AdaptiveNotificationText)
                                            
                                            if (AdaptiveNotificationText) {
                                                hContentText := 0
                                                ComCall(6, AdaptiveNotificationText, "Ptr*", &hContentText)
                                                ObjRelease(AdaptiveNotificationText)
                                                
                                                if (hContentText) {
                                                    cBuffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "Ptr", hContentText, "UInt*", &length, "Ptr")
                                                    currentLine := StrGet(cBuffer, "UTF-16")
                                                    
                                                    if (notificationText == "")
                                                        notificationText := currentLine
                                                    else
                                                        notificationText .= "`n" currentLine
                                                        
                                                    DllCall("Combase.dll\WindowsDeleteString", "Ptr", hContentText)
                                                }
                                            }
                                        }
                                        ObjRelease(AdaptiveNotificationTextReadOnlyList)
                                    }
                                }
                            }
                            ObjRelease(NotificationBindingList)
                        }
                    }
                }
            }

            ; Route final structured output to TTS engine
            if (notificationText != "")
                Speak(appNameText ". " notificationText)
            else
                Speak(appNameText)

            if Debug {
                try {
                    MsgBoxCustom("`nbufferPtr: " bufferPtr
                    "`nappNameText: " appNameText
                    "`nUserNotificationReadOnlyList: " UserNotificationReadOnlyList
                    )
                }
            }
        }
        if (UserNotification != 0)
            ObjRelease(UserNotification)
    }

    starting := false
    if (UserNotificationReadOnlyList != 0)
        ObjRelease(UserNotificationReadOnlyList)
}
;@endregion