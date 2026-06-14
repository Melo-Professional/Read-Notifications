#Requires AutoHotkey v2.0

SettingsLoadReadContent() {
    global ReadContent
    try {
        ReadContent := RegRead(RegistryAppSettings, "ReadContent")
    } catch {
        SettingsSaveReadContent()
    }
    return ReadContent
}

SettingsSaveReadContent() {
    RegWrite(ReadContent, "REG_SZ", RegistryAppSettings, "ReadContent")
}

SettingsLoadReadAny() {
    global ReadAny
    try {
        ReadAny := RegRead(RegistryAppSettings, "ReadAny")
    } catch {
        SettingsSaveReadAny()
    }
    return ReadAny
}

SettingsSaveReadAny() {
    RegWrite(ReadAny, "REG_SZ", RegistryAppSettings, "ReadAny")
}

SettingsLoadRespectDND() {
    global RespectDND
    try {
        RespectDND := RegRead(RegistryAppSettings, "RespectDND")
    } catch {
        SettingsSaveRespectDND()
    }
    return RespectDND
}

SettingsSaveRespectDND() {
    RegWrite(RespectDND, "REG_SZ", RegistryAppSettings, "RespectDND")
}

SettingsLoadVoiceSettings() {
    global VoiceNumber, VoiceRate, VoiceVolume
    try {
        VoiceNumber     := RegRead(RegistryAppSettings, "VoiceNumber")
        VoiceRate       := RegRead(RegistryAppSettings, "VoiceRate")
        VoiceVolume     := RegRead(RegistryAppSettings, "VoiceVolume")
    } catch {
        SettingsSaveVoiceSettings()
    }
}

SettingsSaveVoiceSettings() {
    RegWrite(VoiceNumber, "REG_SZ", RegistryAppSettings, "VoiceNumber")
    RegWrite(VoiceRate, "REG_SZ", RegistryAppSettings, "VoiceRate")
    RegWrite(VoiceVolume, "REG_SZ", RegistryAppSettings, "VoiceVolume")
}

SettingsLoadProgramsList() {
    global ProgramsList
    try {
        regContent := RegRead(RegistryAppSettings, "ProgramsList")
        ProgramsList := StrSplit(regContent, "|")
    } catch {
        ProgramsList := BaseProgramsList
        SettingsSaveProgramsList()
    }
}

SettingsSaveProgramsList() {
    listStr := ""
    for item in ProgramsList
        listStr .= (A_Index == 1 ? "" : "|") item
    RegWrite(listStr, "REG_SZ", RegistryAppSettings, "ProgramsList")
}
