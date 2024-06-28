util.AddNetworkString("RTV_StartVote")
util.AddNetworkString("RTV_UpdateVote")
util.AddNetworkString("RTV_ClosePanel")
-- util.AddNetworkString("RTV_Delay")
RTV.Runned = false
local mapsQueue = {}
local Votes = {}
local Repeats = 0
--[[ Net Send to Clinets]]
net.Receive("RTV_UpdateVote", function(len, ply)
    if RTV.Runned and IsValid(ply) then
        local update_type = net.ReadUInt(3)
        if update_type == RTV.UPDATE_VOTE then
            local map_id = net.ReadUInt(32)
            if mapsQueue[map_id] then
                Votes[ply:SteamID()] = map_id
                net.Start("RTV_UpdateVote")
                net.WriteUInt(RTV.UPDATE_VOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(map_id, 32)
                net.Broadcast()
            end
        end
    end
end)

local function getCurrentMap()
    return game.GetMap():lower()
end

local function isCurrentMap(map)
    return getCurrentMap() == string.Replace(map, ".bsp", "")
end

function RTV.RunVote(timelength, allowcurrentmap, latestwas, lowrating, limitmaps, maprepeats, cb)
    timelength = timelength or RTV.Config.TimeChange
    allowcurrentmap = allowcurrentmap or RTV.Config.AllowCurrentMap
    limitmaps = limitmaps or RTV.Config.MapLimit
    maprepeats = maprepeats or RTV.Config.MapRepeats
    latestwas = latestwas or latestwas == nil and false
    lowrating = lowrating or lowrating == nil and false
    local cooldown = RTV.Config.EnableCooldown or RTV.Config.EnableCooldown == nil and false
    local autoGM = RTV.Config.AutoGM or RTV.Config.AutoGM == nil and false
    --
    local maps = RTV.GetSortedMapsNames(latestwas, lowrating)
    mapsQueue = {}
    for _, map in pairs(maps) do
        if isCurrentMap(map) then continue end
        if cooldown and RTV.isRecentMap(map) then continue end
        table.insert(mapsQueue, map)
        if limitmaps and #mapsQueue >= limitmaps then break end
    end

    if allowcurrentmap and Repeats < maprepeats then
        table.insert(mapsQueue, getCurrentMap())
        Repeats = Repeats + 1
    end

    if #mapsQueue < 1 then
        PrintMessage(HUD_PRINTTALK, "Ошибка, недостаточно карт для запуска голосования.")
        return
    end

    --[[ Net Send to Clinets]]
    net.Start("RTV_StartVote")
    net.WriteUInt(#mapsQueue, 32)
    for i = 1, #mapsQueue do
        net.WriteString(mapsQueue[i])
    end

    net.WriteUInt(timelength, 32)
    net.Broadcast()
    RTV.Runned = true
    Votes = {}
    timer.Create("RTV.VoteHandler", timelength, 1, function()
        RTV.Runned = false
        local results = {}
        local _pl = {}
        for _, v in pairs(player.GetHumans()) do
            _pl[v:SteamID()] = v
        end

        for ply, map in pairs(Votes) do
            local weightVote = hook.Run("MapVoteExtra", _pl[ply]) or 1
            results[map] = (results[map] or 0) + weightVote
        end

        local winner = table.GetWinningKey(results) or 1
        --[[ Net Send to Clinets]]
        net.Start("RTV_UpdateVote")
        net.WriteUInt(RTV.UPDATE_WIN, 3)
        net.WriteUInt(winner, 32)
        net.Broadcast()
        local map = mapsQueue[winner]
        local gamemode = nil
        -- Zalupa
        if autoGM then
            -- check if map matches a gamemode's map pattern
            for k, gm in pairs(engine.GetGamemodes()) do
                -- ignore empty patterns
                if gm.maps and gm.maps ~= "" then
                    -- patterns are separated by "|"
                    for k2, pattern in pairs(string.Split(gm.maps, "|")) do
                        if string.match(map, pattern) then
                            gamemode = gm.name
                            break
                        end
                    end
                end
            end
        else
            print("AutoGamemode not enabled")
        end

        if isCurrentMap(map) then
            RTV.ClearVotes()
            PrintMessage(HUD_PRINTTALK, "Карта продлена.")
            hook.Run("RTVResumeMap")
            return
        end

        local function changeMap()
            RTV.RecentMapPush(map)
            RTV.MapMustChange = true
            local _, c_data = RTV.ViewMapInfo(map)
            RTV.ChangeMapInfo(map, nil, os.time(), c_data.picks or 0 + 1)
            timer.Simple(2, function()
                if gamemode and gamemode ~= engine.ActiveGamemode() then RunConsoleCommand("gamemode", gamemode) end
                RunConsoleCommand("changelevel", map)
            end)
        end

        if cb then
            cb(function(defaultaction) if defaultaction then changeMap() end end)
            return
        end

        changeMap()
    end)
end

function RTV.Cancel()
    if not RTV.Runned then return end
    RTV.Runned = false
    RTV.ClearVotes()
    --[[ Net Send to Clinets]]
    net.Start("RTV_ClosePanel")
    net.Broadcast()
    timer.Stop("RTV.VoteHandler")
end