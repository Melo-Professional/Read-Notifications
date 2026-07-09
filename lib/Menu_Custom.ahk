/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/06
 * @version 1.3.2
 ***********************************************************************/

#Requires AutoHotkey v2.0

Menu_Custom() {

    TrayMenu := A_TrayMenu
    MoreMenu := TrayMenu.HasProp("MoreMenu") ? TrayMenu.MoreMenu : ""


    ; RN Reload fix
    TrayMenu.Delete("Restart")
    TrayMenu.Insert("Exit", "Restart", (*) => Reload())



    ModeMenu := Menu()
    ModeMenu.Add("Read Any Notification", MenuReadAnyHandler)
    ModeMenu.Add("Selected Programs...", MenuSelectProgramsHandler)
    TrayMenu.Insert("More", "Mode", ModeMenu)
    TrayMenu.Insert("More", "Read Content", MenuReadContentHandler)
    TrayMenu.Insert("More", "Respect DND", MenuDNDHandler)
    TrayMenu.Insert("More", "Voice Settings...", (*) => VoiceSettings())

    if !A_IsCompiled {
        TrayMenu.Insert("More", "Test Notification...", (*) => TrayTip("This is the sub-text.", "Hello, world!", 1))
    }

    TrayMenu.Insert("More")

    SettingsLoadReadContent() ? TrayMenu.Check("Read Content") : ""
    SettingsLoadRespectDND() ? TrayMenu.Check("Respect DND") : ""
    SettingsLoadReadAny() ? ModeMenu.Check("Read Any Notification") : ModeMenu.Check("Selected Programs...")

    MenuReadContentHandler(ItemName, ItemPos, MyMenu) {
        global ReadContent
        ReadContent := !ReadContent
        SettingsSaveReadContent()
        ReadContent ? MyMenu.Check(ItemName) : MyMenu.Uncheck(ItemName)
    }

    MenuReadAnyHandler(ItemName, ItemPos, MyMenu) {
        global ReadAny
        ReadAny := true
        SettingsSaveReadAny()
        MyMenu.Check(ItemName)
        MyMenu.Uncheck("Selected Programs...")
    }

    MenuSelectProgramsHandler(ItemName, ItemPos, MyMenu) {
        global ReadAny
        ReadAny := false
        SettingsSaveReadAny()
        MyMenu.Check(ItemName)
        MyMenu.Uncheck("Read Any Notification")
        SelectProgramsGUI()
    }

    MenuDNDHandler(ItemName, ItemPos, MyMenu) {
        global RespectDND
        RespectDND := !RespectDND
        SettingsSaveRespectDND()
        RespectDND ? MyMenu.Check(ItemName) : MyMenu.Uncheck(ItemName)
    }


    ; Custom items
/*
    ; INSERT AT POSITION
    TrayMenu.Insert("3&", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Insert("4&", "Volume Mixer", (*) => Run("sndvol.exe"))
    TrayMenu.Insert("5&")
 */

    ; INSERT OVER 'More'
;    TrayMenu.Insert("More", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
;    TrayMenu.Insert("More", "Volume Mixer", (*) => Run("sndvol.exe"))
;    TrayMenu.Insert("More")

    ; Clean up Suspend and Pause
;    if (MoreMenu != "") {
;    try MoreMenu.Delete("4&")
;    try MoreMenu.Delete("Suspend")
;    try MoreMenu.Delete("Pause")
;    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

;A_TrayMenu.Delete()

