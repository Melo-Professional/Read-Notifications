/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.0.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES

VoiceNumber                 := 1        ; 0 ~ 4
VoiceRate                   := 0        ; -10 ~ 10
VoiceVolume                 := 100      ; 0 ~ 100

sleepDuration               := 500
DNDRegistryKeyName          := "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Notifications\Data"
DNDRegistryValueName        := "0D83063EA3BF1C75"
RegistryAppSettings         := "HKEY_CURRENT_USER\Software\" App.Name

global ProgramsList         := []
global BaseProgramsList     := ["Calendar", "Chrome", "Discord", "Outlook", "Telegram", "Vivaldi", "Whatsapp"]
global ReadAny              := true
global starting             := true
global RespectDND           := true
global ScriptPaused         := false
global idList               := ""
global ReadContent          := true


;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

;App.NameCutted := "Template`nBigName"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion


;@region INI
;SaveToINI.Push("Settings.SplashScreen")     ; add more to INI file
;RegisterArrayItems(SaveToINI)
;LoadINI()
;@endregion