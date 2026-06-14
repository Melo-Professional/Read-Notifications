#Requires AutoHotkey v2.0

VoiceSettings() {
    global VoiceNumber, VoiceRate, voices, VoiceVolume
    
    MyGuiTitle := "Voice Settings"
    MyGuiOptions := "+LastFound"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)

    ;SettingsGui := Gui("+LastFound -SysMenu", "Voice Settings")
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    ;GuiWidth := 382
    GuiWidth := 450
    SliderWidth := 342
    BtnWidth := 80
    ;SettingsGui.MarginX := 59
    MyGui.MarginX := (GuiWidth - SliderWidth) // 2
    MyGui.MarginY := 20

    ; --- Voice Selection ---
    MyGui.Add("Text", "x" MyGui.MarginX " y+30 w" SliderWidth, "Select Voice")
    VoiceNames := []
    Loop voices.Count {
        VoiceNames.Push(voices.Item(A_Index - 1).GetDescription())
    }
    ;DDL_Voice := SettingsGui.Add("DropDownList", "vVoiceChoice y+10 w" SliderWidth " Choose" VoiceNumber, VoiceNames)
    DDL_Voice := MyGui.AddDDL( "vVoiceChoice y+10 w" SliderWidth " Choose" VoiceNumber, VoiceNames)

    ; --- Rate Selection ---
    MyGui.Add("Text", "y+40", "Voice Rate")
    
    Slider_Rate := MyGui.Add("Slider", "vRateChoice y+10 w" SliderWidth " Range-10-10 TickInterval10", VoiceRate)

    ; --- Legend ---
    SliderThird := Round(SliderWidth // 3)
    MyGui.SetFont("s" Settings.GuiFontSizeSmall, Settings.GuiFontName)
    MyGui.Add("Text", "x" MyGui.MarginX " y+0 w" SliderThird " Left", "Slow")
    ;SettingsGui.Add("Text", "xp+" (SliderThird +1) " yp w" SliderThird " Center", "|")
    MyGui.Add("Text", "xp+" (SliderThird * 2 + 1) " yp w" SliderThird " Right", "Fast")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; --- Volume Selection ---
    MyGui.Add("Text", "x" MyGui.MarginX " y+40", "Voice Volume")
    SliderWidth := 342
    Slider_Volume := MyGui.Add("Slider", "vVolumeChoice y+10 w" SliderWidth " Range0-100 TickInterval50", VoiceVolume)

    ; --- Legend ---
    MyGui.SetFont("s" Settings.GuiFontSizeSmall, Settings.GuiFontName)
    MyGui.Add("Text", "x" MyGui.MarginX " y+0 w" SliderThird " Left", "Low")
    ;SettingsGui.Add("Text", "xp+" (SliderThird +1) " yp w" SliderThird " Center", "|")
    MyGui.Add("Text", "xp+" (SliderThird * 2 + 1) " yp w" SliderThird " Right", "High")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; --- OK Button ---
    btnX := GuiWidth - MyGui.MarginY - BtnWidth
    ;Btn := SettingsGui.Add("Button", "x" btnX " y+60 w" BtnWidth " h30 Default", "&OK")
    Btn := MyGui.AddButton("x" btnX " y+60 w" BtnWidth " h30 Default", "&OK")
    ;Btn.OnEvent("Click", (*) => MyGui.Destroy())
    Btn.OnEvent("Click", CleanDestroy)

    ; --- Debounce Control ---
    lastTrigger := 0
    delay := 300 ; ms

    HandleChange(*) {
        global VoiceNumber := DDL_Voice.Value
        global VoiceRate := Slider_Rate.Value
        global VoiceVolume := Slider_Volume.Value
        SettingsSaveVoiceSettings()

        now := A_TickCount
        if (now - lastTrigger < delay)
            return
        lastTrigger := now

        SetTimer(() => SpeakPreview(), -delay)
    }

    SpeakPreview() {
        phrases := (ReadAny || !ProgramsList.Length) ? BaseProgramsList : ProgramsList
        Speak(phrases[Random(1, phrases.Length)], VoiceNumber, VoiceRate, VoiceVolume, true)
    }

    ; Events
    DDL_Voice.OnEvent("Change", HandleChange)
    Slider_Rate.OnEvent("Change", HandleChange)
    Slider_Volume.OnEvent("Change", HandleChange)

    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)
    MyGui.Show("w" GuiWidth)
    CleanDestroy(*) {
            RemoveGuiFromArray(MyGui)
            MyGui.Destroy()
    }
}