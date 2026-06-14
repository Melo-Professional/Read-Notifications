#Requires AutoHotkey v2.0

SelectProgramsGUI() {
    MyGuiTitle := "Selected Programs Only"
    MyGuiOptions := "+LastFound -MinimizeBox"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    MyGui.MarginX := 20
    MyGui.MarginY := 20
    MyGui.Add("Text", "", "Select programs to monitor for notifications:")

    LB := MyGui.AddListBox("vProgramList w340 h240 Multi", ProgramsList)

    MyGui.AddButton("w80 x+10", "&Add...").OnEvent("Click", (*) => AddProgram(LB))
    MyGui.AddButton("w80 y+10", "&Remove").OnEvent("Click", (*) => RemoveProgram(LB))
    ;MyGui.AddButton("Default w80 y+185", "&OK").OnEvent("Click", (*) => MyGui.Destroy())
    MyGui.AddButton("Default w80 y+185", "&OK").OnEvent("Click", CleanDestroy)

    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)
    MyGui.Show()
    CleanDestroy(*) {
            RemoveGuiFromArray(MyGui)
            MyGui.Destroy()
        }
}

RemoveProgram(LB) {
    indexes := LB.Value
    try {
        if (indexes.Length == 0)
            return
        i := indexes.Length
        while (i > 0) {
            idx := indexes[i]
            ProgramsList.RemoveAt(idx)
            LB.Delete(idx)
            i--
        }
    }
    SettingsSaveProgramsList()
}

AddProgram(LB) {
    IB := CustomInputBox("Enter a program name (ex Chrome)`nOr multiple programs (ex Chrome, Brave, Telegram):", "Add Programs")

    if !(IB.Result = "OK" && IB.Value != "")
        return

    raw := IB.Value
    raw := StrReplace(raw, "|", ",")
    parts := StrSplit(raw, ",")

    added := []

    for part in parts {
        prog := Trim(part)
        if (prog = "")
            continue

        exists := false
        for item in ProgramsList {
            if (item = prog) {
                exists := true
                break
            }
        }

        if !exists {
            ProgramsList.Push(prog)
            LB.Add([prog])
            added.Push(prog)
        }
    }

    if (added.Length > 0)
        SettingsSaveProgramsList()
}



CustomInputBox(prompt, MyGuiTitle := "") {
    MyGuiOptions := "+AlwaysOnTop -SysMenu"
    result := {Result: "Cancel", Value: ""}
    MyGui := Gui(MyGuiOptions, MyGuiTitle)

    guiW                    := 300
    MyGui.MarginX           := 30
    MyGui.MarginY           := 20
    contentW                := guiW + (MyGui.MarginX * 2)
    rightEdge               := contentW - MyGui.MarginX
    btnW                    := 80
    btnGap                  := 10

    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    MyGui.AddText("y30 w300", prompt)
    editprog := MyGui.AddEdit("w300")

    btnOK_X := rightEdge - btnGap - (btnW * 2)
    btnOK := MyGui.AddButton("w80 x" btnOK_X " y+30 Default","OK")
    btnCancel := MyGui.AddButton("x+10 w80", "Cancel")

    btnOK.OnEvent("Click", (*) => Submit())
    btnCancel.OnEvent("Click", (*) => CleanDestroy())
    MyGui.OnEvent("Close", (*) => CleanDestroy())
    MyGui.OnEvent("Escape", (*) => CleanDestroy())

   ApplyThemeToGui(MyGui)
   WatchedGUIs.Push(MyGui)


    MyGui.Show()
    editprog.Focus()

    done := false

    Submit() {
        result.Value := editprog.Value
        result.Result := "OK"
        done := true
        RemoveGuiFromArray(MyGui)
        MyGui.Destroy()
    }

    CleanDestroy(*) {
        result.Result := "Cancel"
        done := true
        RemoveGuiFromArray(MyGui)
        MyGui.Destroy()
    }

    while !done
        Sleep(100)

        return result
}