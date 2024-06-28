RTV.ChatCommands = {"!rtv", "/rtv", "rtv"}
RTV.Votes = 0
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
        PrintMessage(HUD_PRINTTALK, "Голосование на смену карты запущено...")
        timer.Simple(3, function() RTV.RunVote(nil, nil, true, false, nil, nil, callbackAction) end)
    end

    local function AddVote(ply)
        ply.RTV_Voted = true
        RTV.Votes = RTV.Votes + 1
        MsgN(ply:Nick() .. " проголовал за смену карты.")
        PrintMessage(HUD_PRINTTALK, ply:Nick() .. " проголосовал за смену карты. (" .. RTV.Votes .. "/" .. MustVoted() .. ")")
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

    if not sam or not ulx then
        concommand.Add("rtv_start", RTV.VoteForChange)
        hook.Add("PlayerSay", "RTV.ChatHandler", function(ply, text)
            text = string.Split(text, " ")
            if table.HasValue(RTV.ChatCommands, string.lower(text[1])) then
                RTV.VoteForChange(ply)
                return ""
            end

            if string.lower(text[1]) == "!nominate" then
                RTV.NominateMap(ply, text[2])
                return ""
            end
        end)

        hook.Add("SAM.Loaded", "RTV.RemoveBaseHandler", function()
            hook.Remove("PlayerSay", "RTV.ChatHandler")
            hook.Remove("SAM.Loaded", "RTV.RemoveBaseHandler")
        end)
    end

    --[[ Блоки условий ]]
    hook.Add("RTV.CanVote", "RTV.CanVote.BaseLogic", function(ply)
        local plyCount = table.Count(player.GetHumans())
        if WaitTime >= CurTime() then return false, "Подожди немного после смены карты!" end
        if RTV.Runned then return false, "Голосование уже идет!" end
        if ply.RTV_Voted then return false, "Вы уже писали '!rtv'" end
        if RTV.MapMustChange then return false, "Голосование завершилось, будет изменена карта!" end
        if plyCount < PlayerMinCount then return false, "Недостаточно игроков для написания '!rtv'" end
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
    -- local function isAllowedPrefixMap(map)
    --     local found = false
    --     for _,v in pairs(RTV.Config.Prefixies) do
    --         if string.find(map, "^" .. v) then
    --             found = true
    --         end
    --     end
    --     return found
    -- end
    local function nommap(ply, map)
        ply.Nominate_Map = map
        ply.Nominate_Next = CurTime() + cooldown
        NominateMaps[map] = (NominateMaps[map] or 0) + 1
        MsgN(ply:Nick() .. " номинирует карту " .. map .. ".")
        PrintMessage(HUD_PRINTTALK, ply:Nick() .. " номинирует карту " .. map .. ". (" .. NominateMaps[map] .. ")")
    end

    function RTV.DecreaseNominate(ply)
        if not ply:IsValid() then return end
        local map = ply.Nominate_Map
        NominateMaps[map] = math.Clamp(NominateMaps[map] - 1, 0, math.huge)
        ply.Nominate_Next = nil
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

        if not state then ErrorNoHalt("Error sorting, current sequence...\n" .. error .. "\n") end
        return maps
    end

    hook.Add("RTV.CanNominate", "RTV.CanNominate.BaseLogic", function(ply, map)
        if ply.Nominate_Next >= CurTime() then return false, "Подожди еще " .. math.Round(ply.Nominate_Next - CurTime()) .. " секунд." end
        if ply.Nominate_Map == map then return false, "Вы уже номинировали эту карту" end
        --if not isAllowedPrefixMap(map) then return false, "Некорректный префикс карты" end
        if not table.HasValue(findMaps, map .. ".bsp") then return false, "Карты не существует" end
        if RTV.Runned then return false, "Во время голосования номинирование не возможно!" end
        if RTV.MapMustChange then return false, "Голосование завершилось!" end
        return true
    end)
end