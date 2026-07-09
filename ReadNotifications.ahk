;@region Setup
;@region Description
/************************************************************************
 * @description Read Notifications turns Windows notifications into instant voice alerts using Text-to-Speech.
 * @author Melo (melo@meloprofessional.com)
 * @credits @Malcev https://www.autohotkey.com/boards/viewtopic.php?f=76&t=76103
 * @date 2026/07/07
 * @releasedate 2025/03/25
 * @version 2.8.1.0
 ***********************************************************************/

AppName := "Read Notifications"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "2.8.1.0"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Read Notifications turns Windows notifications into instant voice alerts using Text-to-Speech."
;@endregion

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
A_MenuMaskKey := "vkFF"
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
; --- Optimization Settings ---
;ProcessSetPriority("High")
ListLines(False)
KeyHistory(0)
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_Theme>
;#Include *i <_OSDCustom>
;#Include *i <_Color_Picker_Dialog_>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <SettingsFuncs>
#Include <GuiPrograms>
#Include <GuiVoiceSettings>
;@endregion

;@region Startup
; SPLASHSCREEN
if IsSet(SplashScreen){
;    SplashScreen("Banner", false)       ; show banner and wait
;    sleep(5000)
;    SplashScreen()                      ; shows default / destroys
;    SplashScreen("Icon")                ; show icon and destroys
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
SplashScreen()
;@endregion

SettingsLoadProgramsList()

;@region Hotkeys
;^+r::Reload()
;@endregion


;@region HelperFunctions
; HELPER FUNCTIONS
Speak(phrase, voiceNum := VoiceNumber, rate := VoiceRate, vol := VoiceVolume, ignoreDND := false) {
    oVoice.Volume   := vol
    oVoice.Rate     := rate
    oVoice.Voice    := voices.Item(voiceNum - 1)
    if (ignoreDND || !SystemStateDND() || (SystemStateDND() && !RespectDND)) ; Check DND clearance
        SetTimer(() => oVoice.Speak(phrase, 1), -1)
}

CreateClass(className, interfaceGuid) {
    hString := CreateHString(className)
    memBuf := Buffer(16)
    DllCall("ole32\CLSIDFromString", "wstr", interfaceGuid, "ptr", memBuf)

    pClass := 0
    result := DllCall("Combase.dll\RoGetActivationFactory", "ptr", hString, "ptr", memBuf, "ptr*", &pClass, "uint")

    if (result != 0) {
        DeleteHString(hString)
        MsgBoxCustom("Error creating class: " result, , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
    }
    DeleteHString(hString)
    return pClass
}

CreateHString(str) {
    hString := 0
    DllCall("Combase.dll\WindowsCreateString", "wstr", str, "uint", StrLen(str), "ptr*", &hString)
    return hString
}

DeleteHString(hString) {
    DllCall("Combase.dll\WindowsDeleteString", "ptr", hString)
}

WaitForAsync(&obj) {
    AsyncInfo := ComObjQuery(obj, "{00000036-0000-0000-C000-000000000046}")
    Loop {
        status := 0
        ComCall(7, AsyncInfo, "uint*", &status)
        if (status != 0) {
            if (status != 1) {
                errorCode := 0
                ComCall(8, AsyncInfo, "uint*", &errorCode)
                MsgBoxCustom("Async Error: " errorCode, , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
            }
            break
        }
        Sleep(10)
    }
    results := 0
    ComCall(8, obj, "ptr*", &results)
    ObjRelease(obj)
    obj := results
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

;@region Main
; FIRST RUN CHECK


; WinRT NOTIFICATION LISTENER
IUserNotificationListenerStatics    := "{FF6123CF-4386-4AA3-B73D-B804E5B63B23}"
UserNotificationListenerStatics     := CreateClass("Windows.UI.Notifications.Management.UserNotificationListener", IUserNotificationListenerStatics)

listener        := 0
accessStatus    := 0
ComCall(6, UserNotificationListenerStatics, "ptr*", &listener)
ComCall(6, listener, "int*", &accessStatus)
WaitForAsync(&accessStatus)

if (accessStatus != 1) {
    MsgBoxCustom("AccessStatus Denied", , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
}

SetTimer(MainLoop, sleepDuration)

MainLoop() {
    global idList, starting, ReadContent

    UserNotificationReadOnlyList := 0
    ComCall(10, listener, "int", 1, "ptr*", &UserNotificationReadOnlyList)
    WaitForAsync(&UserNotificationReadOnlyList)

    count := 0
    ComCall(7, UserNotificationReadOnlyList, "int*", &count)

    Loop count {
        UserNotification := 0
        try {
            ComCall(6, UserNotificationReadOnlyList, "int", A_Index - 1, "ptr*", &UserNotification)

            id := 0
            ComCall(8, UserNotification, "uint*", &id)

            if !InStr(idList, "|" id "|") {
                idList .= "|" id "|"

                if (!starting && !ScriptPaused) {
                    AppInfo := 0
                    hr := ComCall(7, UserNotification, "ptr*", &AppInfo)
                    if (hr == 0) {
                        AppDisplayInfo := 0
                        ComCall(8, AppInfo, "ptr*", &AppDisplayInfo)

                        hText := 0
                        ComCall(6, AppDisplayInfo, "ptr*", &hText)

                        length := 0
                        bufferPtr := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", &length, "ptr")
                        appNameText := StrGet(bufferPtr, "UTF-16")

                        DeleteHString(hText)
                        ObjRelease(AppDisplayInfo)
                        ObjRelease(AppInfo)

                        ; Determine if we should process this app's notification
                        shouldRead := false
                        if !ReadAny && !Debug{
                            for newapp in ProgramsList {
                                if (appNameText = newapp) {
                                    shouldRead := true
                                    break
                                }
                            }
                        } else {
                            shouldRead := true
                        }

                        if (shouldRead) {
                            if (ReadContent) {
                                ; --- EXTRACT NOTIFICATION CONTENT ---
                                notificationText := ""
                                Notification := 0
                                
                                ; get_Notification (Index 6)
                                ComCall(6, UserNotification, "ptr*", &Notification)
                                if (Notification) {
                                    NotificationVisual := 0
                                    ; get_Visual (Index 8)
                                    ComCall(8, Notification, "ptr*", &NotificationVisual)
                                    
                                    if (NotificationVisual) {
                                        NotificationBindingList := 0
                                        ; get_Bindings (Index 8)
                                        ComCall(8, NotificationVisual, "ptr*", &NotificationBindingList)
                                        
                                        if (NotificationBindingList) {
                                            bindingCount := 0
                                            ComCall(7, NotificationBindingList, "int*", &bindingCount)
                                            
                                            Loop bindingCount {
                                                NotificationBinding := 0
                                                ComCall(6, NotificationBindingList, "int", A_Index - 1, "ptr*", &NotificationBinding)
                                                
                                                if (NotificationBinding) {
                                                    AdaptiveNotificationTextReadOnlyList := 0
                                                    ; GetTextElements (Index 11)
                                                    ComCall(11, NotificationBinding, "ptr*", &AdaptiveNotificationTextReadOnlyList)
                                                    
                                                    if (AdaptiveNotificationTextReadOnlyList) {
                                                        textCount := 0
                                                        ComCall(7, AdaptiveNotificationTextReadOnlyList, "int*", &textCount)
                                                        
                                                        Loop textCount {
                                                            AdaptiveNotificationText := 0
                                                            ComCall(6, AdaptiveNotificationTextReadOnlyList, "int", A_Index - 1, "ptr*", &AdaptiveNotificationText)
                                                            
                                                            if (AdaptiveNotificationText) {
                                                                hContentText := 0
                                                                ; get_Text (Index 6)
                                                                ComCall(6, AdaptiveNotificationText, "ptr*", &hContentText)
                                                                
                                                                if (hContentText) {
                                                                    cBuffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hContentText, "uint*", &length, "ptr")
                                                                    currentLine := StrGet(cBuffer, "UTF-16")
                                                                    
                                                                    if (notificationText == "")
                                                                        notificationText := currentLine
                                                                    else
                                                                        notificationText .= "`n" currentLine
                                                                        
                                                                    DeleteHString(hContentText)
                                                                }
                                                                ObjRelease(AdaptiveNotificationText)
                                                            }
                                                        }
                                                        ObjRelease(AdaptiveNotificationTextReadOnlyList)
                                                    }
                                                    ObjRelease(NotificationBinding)
                                                }
                                            }
                                            ObjRelease(NotificationBindingList)
                                        }
                                        ObjRelease(NotificationVisual)
                                    }
                                    ObjRelease(Notification)
                                }
                                
                                ; If text was successfully fetched, speak it. Otherwise fallback to App Name.
                                if (notificationText != "")
                                    Speak(appNameText ". " notificationText)
                                else
                                    Speak(appNameText)
                            } else {
                                ; Fallback behavior: Just read the app name
                                Speak(appNameText)
                            }
                            if Debug {
                                try {
                                    MsgBoxCustom("`nbufferPtr: " bufferPtr
                                    "`nappNameText: " appNameText
                                    "`nhText: " hText
                                    "`nAppDisplayInfo: " AppDisplayInfo
                                    "`nAppInfo: " AppInfo
                                    "`nUserNotificationReadOnlyList: " UserNotificationReadOnlyList
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        if (UserNotification != 0)
            ObjRelease(UserNotification)
    }

    starting := false
    if (UserNotificationReadOnlyList != 0)
        ObjRelease(UserNotificationReadOnlyList)
    DllCall("psapi.dll\EmptyWorkingSet", "ptr", -1)
}
;@endregion