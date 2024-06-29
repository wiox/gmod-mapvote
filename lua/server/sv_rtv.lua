RTV.ChatCommands = {"!rtv", "/rtv", "rtv"}
RTV.Votes = RTV.Votes or 0
do
    local TimeoutAfterMapChange = 60
    local WaitTime = CurTime() + TimeoutAfterMapChange
    local PlayerMinCount = RTV.Config.MinVotesCount or 3
    local function MustVoted()
        return math.max(math.Round(#player.GetHumans() * RTV.Config.PercentVoters), PlayerMinCount)
    end

    local function ShouldStartChange()
        return RTV.Votes >= MustVoted()
    end

    local function callbackAction(func)
        -- if GAMEMODE:GetRound() == Round_Wait then return func(true) end
        -- hook.Add("OnRoundEnd", "RTV.ChangeMapOnEndRound", function() return func(true) end)
        func(true)
    end

    function RTV.DecreaseVote()
        RTV.Votes = math.Clamp(RTV.Votes - 1, 0, math.huge)
    end

    function RTV.StartVoting()
        PrintMessage(HUD_PRINTTALK, "Voting to change the map...")
        timer.Simple(3, function() RTV.RunVote(nil, nil, true, false, nil, nil, callbackAction) end)
    end

    local function AddVote(ply)
        ply.RTV_Voted = true
        RTV.Votes = RTV.Votes + 1
        MsgN(ply:Nick() .. " voted in favor of changing the map.")
        PrintMessage(HUD_PRINTTALK, ply:Nick() .. " voted in favor of changing the map. (" .. RTV.Votes .. "/" .. MustVoted() .. ")")
        if ShouldStartChange() then RTV.StartVoting() end
    end

    function RTV.VoteForChange(ply)
        local can, err = hook.Run("RTV.CanVote", ply)
        if not can then
            ply:PrintMessage(HUD_PRINTTALK, err)
            return
        end

        AddVote(ply)
    end

    function RTV.ClearVotes()
        if RTV.Votes == 0 then return false end
        RTV.Votes = 0
        for _, v in pairs(player.GetHumans()) do
            v.RTV_Voted = false
        end
    end

    local function ReOpenForm(ply)
        net.Start("RTV_StartVote")
        net.Send(ply)
    end

    hook.Add("RTV.CanVote", "RTV.CanVote.BaseLogic", function(ply)
        local plyCount = table.Count(player.GetHumans())
        if WaitTime >= CurTime() then return false, "Wait a bit after the map change!" end
        if RTV.MapMustChange then return false, "Voting has ended, the map will be changed!" end
        if RTV.Runned then
            ReOpenForm(ply)
            return false, "Voting is already in progress, back to choosing...."
        end

        if ply.RTV_Voted then return false, "You wrote '!rtv' before. (" .. RTV.Votes .. "/" .. MustVoted() .. ")" end --  | (AutoRTV: " .. RTV.TimeFormat(math.Round(RTV.GetNext() - CurTime())) .. ") for JailBreak RTV
        if plyCount < PlayerMinCount then return false, "Not enough players to write '!rtv'." end
        return true
    end)

    hook.Add("PlayerDisconnected", "RTV.RemoveVote", function(ply)
        if ply.RTV_Voted then RTV.DecreaseVote() end
        if ply.Nominate_Map then RTV.DecreaseNominate(ply) end
        timer.Simple(0.1, function() if ShouldStartChange() then RTV.StartVoting() end end)
    end)
end

do
    local NominateMaps = {}
    local cooldown = 60
    local findMaps = file.Find("maps/*.bsp", "GAME")
    local function nommap(ply, map)
        ply.Nominate_Map = map
        ply.Nominate_Next = CurTime() + cooldown
        NominateMaps[map] = (NominateMaps[map] or 0) + 1
        MsgN(ply:Nick() .. " nominates " .. map .. ".")
        PrintMessage(HUD_PRINTTALK, ply:Nick() .. " nominates " .. map .. ". (" .. NominateMaps[map] .. ")")
    end

    function RTV.DecreaseNominate(ply)
        if not ply:IsValid() then return end
        local map = ply.Nominate_Map
        if not map then return end
        if NominateMaps[map] then NominateMaps[map] = math.Clamp(NominateMaps[map] - 1, 0, math.huge) end
        ply.Nominate_Next = nil
        ply.Nominate_Map = nil
    end

    function RTV.NominateMap(ply, map)
        local can, err = hook.Run("RTV.CanNominate", ply, map)
        if not can then
            ply:PrintMessage(HUD_PRINTTALK, err)
            return
        end

        nommap(ply, map)
    end

    function RTV.GetSortedMapsNames(latestprior, lowprior)
        local maps = table.GetKeys(RTV.MapInfo)
        local impact = RTV.Config.ImpactNomination
        local playercount = #player.GetHumans()
        local time = os.time()
        if #maps == 0 then return {} end
        local state, error = pcall(function()
            table.sort(maps, function(a, b)
                local score1, score2, mapinfo1, mapinfo2 = 0, 0, RTV.MapInfo[a], RTV.MapInfo[b]
                if playercount >= mapinfo1.players and playercount <= mapinfo1.players + 5 then score1 = score1 + 1 end
                if playercount >= mapinfo2.players and playercount <= mapinfo2.players + 5 then score2 = score2 + 1 end
                if latestprior then
                    score1 = score1 + ((time - (mapinfo1.last or 0)) / 604800)
                    score2 = score2 + ((time - (mapinfo2.last or 0)) / 604800)
                end

                local a_rate, b_rate = mapinfo1.picks or 0, mapinfo2.picks or 0
                if a_rate < b_rate then
                    if not lowprior then
                        score2 = score2 + 1
                    else
                        score1 = score1 + 1
                    end
                elseif a_rate > b_rate then
                    if not lowprior then
                        score1 = score1 + 1
                    else
                        score2 = score2 + 1
                    end
                end

                score1 = score1 + (NominateMaps[a] or 0) * impact
                score2 = score2 + (NominateMaps[b] or 0) * impact
                return score2 < score1
            end)
        end)

        if not state then ErrorNoHalt("Ошибка сортировки...\n" .. error .. "\n") end
        return maps
    end

    hook.Add("RTV.CanNominate", "RTV.CanNominate.BaseLogic", function(ply, map)
        if ply.Nominate_Next and ply.Nominate_Next >= CurTime() then return false, "Wait another " .. math.Round(ply.Nominate_Next - CurTime()) .. " seconds." end
        if ply.Nominate_Map and ply.Nominate_Map == map then return false, "You've already nominated this map." end
        if RTV.Config.EnableCooldown and RTV.isRecentMap(map) then return false, "This map was already there, you can't nominate." end
        if not table.HasValue(findMaps, map .. ".bsp") then return false, "This map doesn't exist" end
        if RTV.Runned then return false, "Nominations are not possible during the voting period!" end
        if RTV.MapMustChange then return false, "Voting is over!" end
        return true
    end)
end

if not sam or not ulx then
    concommand.Add("rtv_start", RTV.VoteForChange)
    concommand.Add("rtv_nominate", function(ply, _, args)
        if #args == 0 then return end
        RTV.NominateMap(ply, string.lower(args[1]))
    end)

    hook.Add("PlayerSay", "RTV.ChatHandler", function(ply, text)
        text = string.Split(text, " ")
        if table.HasValue(RTV.ChatCommands, string.lower(text[1])) then
            RTV.VoteForChange(ply)
            return ""
        end

        if string.lower(text[1]) == "!nominate" then
            RTV.NominateMap(ply, string.lower(text[2]))
            return ""
        end
    end)

    hook.Add("SAM.Loaded", "RTV.RemoveBaseHandler", function()
        hook.Remove("PlayerSay", "RTV.ChatHandler")
        hook.Remove("SAM.Loaded", "RTV.RemoveBaseHandler")
        hook.Remove("ULXLoaded", "RTV.RemoveBaseHandler")
    end)

    hook.Add("ULXLoaded", "RTV.RemoveBaseHandler", function()
        hook.Remove("PlayerSay", "RTV.ChatHandler")
        hook.Remove("SAM.Loaded", "RTV.RemoveBaseHandler")
        hook.Remove("ULXLoaded", "RTV.RemoveBaseHandler")
    end)
end

hook.Add("Initialize", "RTV.SetMapLastTime", function() RTV.ChangeMapInfo(game.GetMap(), nil, os.time(), nil) end)