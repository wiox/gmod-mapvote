function RTV.GetNext()
    if GAMEMODE_NAME == "jailbreak" then return GetGlobalInt("mapvote_next", -1) end
    return 0
end