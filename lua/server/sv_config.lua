RTV.Config = RTV.Config or {}
RTV.MapInfo = RTV.MapInfo or {}
do
    local dir = "rtv"
    local cfg = "config.json"
    local recent = "recentMaps.json"
    local mapinfo = "mapsrate.json"
    local recentMaps = {}
    --
    local base = {
        MapLimit = 8,
        TimeChange = 60,
        UseExludeMapsFromAdminModules = true,
        AllowCurrentMap = true,
        EnableCooldown = true,
        MapsBeforeRevote = 3,
        MinVotesCount = 3,
        PercentVoters = 0.66,
        PercentForNominate = 0.5,
        ImpactNomination = 0.75,
        MapRepeats = 2,
        Prefixies = {"jb_", "ba_"},
        AutoGM = false
    }

    --
    function RTV.AddMapInfo(map, playercount)
        map = string.Replace(map, ".bsp", "")
        if RTV.MapInfo[map] then return false, "Map " .. map .. " exists" end
        RTV.MapInfo[map] = {
            players = playercount
        }

        hook.Run("RTVMapInfoAdded", map, RTV.MapInfo[map])
        return true
    end

    function RTV.ChangeMapInfo(map, playercount, lastplayed, picks)
        map = string.Replace(map, ".bsp", "")
        if not RTV.MapInfo[map] then return false, "Map " .. map .. " not exists" end
        local curdata = table.Copy(RTV.MapInfo[map])
        if playercount and playercount > 0 then RTV.MapInfo[map].players = playercount end
        if lastplayed and isnumber(lastplayed) then RTV.MapInfo[map].last = lastplayed end
        if picks and isnumber(picks) then RTV.MapInfo[map].picks = picks end
        if curdata == RTV.MapInfo[map] then return false, "Nothing changed..." end
        hook.Run("RTVMapInfoChanged", map, RTV.MapInfo[map])
        return true
    end

    function RTV.ViewMapInfo(map)
        map = string.Replace(map, ".bsp", "")
        if not RTV.MapInfo[map] then return false, "Map " .. map .. " not exists" end
        return true, RTV.MapInfo[map]
    end

    function RTV.DeleteMapInfo(map)
        map = string.Replace(map, ".bsp", "")
        if not RTV.MapInfo[map] then return false, "Map " .. map .. " not exists" end
        RTV.MapInfo[map] = nil
        hook.Run("RTVMapInfoChanged", map, RTV.MapInfo[map])
    end

    --
    function RTV.RecentMapPush(map)
        map = string.Replace(map, ".bsp", "")
        table.insert(recentMaps, 1, map)
        hook.Run("RTVRecentAdded", map)
    end

    function RTV.ClearRecentMaps()
        recentMaps = {}
        hook.Run("RTVRecentCleared")
    end

    function RTV.ViewRecentMapList()
        return recentMaps
    end

    function RTV.RecentMapPop()
        recentMaps = table.remove(recentMaps)
        hook.Run("RTVRecentChanged", map)
    end

    function RTV.isRecentMap(map)
        map = string.Replace(map, ".bsp", "")
        return table.HasValue(recentMaps, map)
    end

    --
    function RTV.ChangeConfigVar(key, value)
        if table.Count(RTV.Config) == 0 then return false, "Config is empty, please use instead RTV.ReplaceConfig" end
        if not RTV.Config[key] then return false, "No current variable" end
        RTV.Config[key] = value
        hook.Run("RTVChangeVariable", key, value)
        return true
    end

    function RTV.ReplaceConfig(newcfg)
        RTV.Config = newcfg
        hook.Run("RTVConfigReplaced")
    end

    function RTV.GetConfigKeys()
        return table.GetKeys(RTV.Config)
    end

    function RTV.isAllowedPrefix(map_or_prefix)
        local allowed = false
        local pref = RTV.Config.Prefixies
        if pref and type(pref) ~= "table" then pref = {pref} end
        if pref == nil then return false end -- заглушка
        for _, v in pairs(pref) do
            if string.find(map_or_prefix, "^" .. v) then
                allowed = true
                break
            end
        end
        return allowed
    end

    do
        local rewrite = false
        local function write()
            if not rewrite then
                hook.Add("ShutDown", "RTVWriteConfigOnShutDown", function()
                    local data = util.TableToJSON(RTV.Config)
                    file.Write(dir .. "/" .. cfg, data)
                end)

                rewrite = true
            end
        end

        hook.Add("RTVChangeVariable", "RTVCheckVarBeforeWriteFile", write)
        hook.Add("RTVConfigReplaced", "RTVCheckCfgBeforeWriteFile", write)
    end

    do
        local rewrite = false
        local function write()
            if not rewrite then
                hook.Add("ShutDown", "RTVWriteMapInfoOnShutDown", function()
                    local data = util.TableToJSON(RTV.MapInfo)
                    file.Write(dir .. "/" .. mapinfo, data)
                end)

                rewrite = true
            end
        end

        hook.Add("RTVMapInfoAdded", "RTVCheckMapAddedBeforeWriteFile", write)
        hook.Add("RTVMapInfoChanged", "RTVCheckMapChangedBeforeWriteFile", write)
    end

    do
        local rewrite = false
        local function write()
            if not rewrite then
                hook.Add("ShutDown", "RTVWriteRecentMapsOnShutDown", function()
                    local data = util.TableToJSON(recentMaps)
                    file.Write(dir .. "/" .. recent, data)
                end)

                rewrite = true
            end
        end

        hook.Add("RTVRecentAdded", "RTVCheckRecentAddedBeforeWriteFile", write)
        hook.Add("RTVRecentChanged", "RTVCheckRecentChangedBeforeWriteFile", write)
        hook.Add("RTVRecentCleared", "RTVCheckRecentClearedBeforeWriteFile", write)
    end

    do
        local maps = {}
        local function isExcludedMap(map)
            map = string.Replace(map, ".bsp", "")
            local mode = ConVarExists("ulx_votemapMapmode") and GetConVar("ulx_votemapMapmode"):GetInt() or 1
            return mode == 1 and maps[map] or maps[map] ~= nil and not maps[map] or false
        end

        local function loadMaps()
            RTV.MapInfo = {}
            if file.Exists(dir .. "/" .. mapinfo, "DATA") then RTV.MapInfo = util.JSONToTable(file.Read(dir .. "/" .. mapinfo, "DATA")) end
            for _, v in pairs(file.Find("maps/*.bsp", "GAME")) do
                if RTV.Config.UseExludeMapsFromAdminModules and isExcludedMap(v) then
                    if RTV.ViewMapInfo(v) then RTV.DeleteMapInfo(v) end
                    continue
                end

                if RTV.isAllowedPrefix(v) and not RTV.ViewMapInfo(v) then RTV.AddMapInfo(v, 0) end
            end
        end

        hook.Add("ULXLoaded", "RTV.ulx.LoadMaps", function()
            if file.Exists("ulx/votemaps.txt", "DATA") then
                for _, v in pairs(string.Split(ULib.stripComments(ULib.fileRead("data/ulx/votemaps.txt", true), ";"):Trim(), "\n")) do
                    maps[v] = true
                end
            end

            loadMaps()
            hook.Remove("ULXLoaded", "RTV.ulx.LoadMaps")
        end)

        hook.Add("SAM.Loaded", "RTV.sam.LoadMaps", function()
            maps = sam.get_global("Votemap.Excluded")
            loadMaps()
            hook.Remove("SAM.Loaded", "RTV.sam.LoadMaps")
        end)

        hook.Add("Initialize", "CheckConfigs", function()
            if not file.Exists(dir, "DATA") then file.CreateDir(dir) end
            if not file.Exists(dir .. "/" .. cfg, "DATA") then
                RTV.ReplaceConfig(base)
            else
                RTV.Config = util.JSONToTable(file.Read(dir .. "/" .. cfg, "DATA"))
            end

            loadMaps()
            if file.Exists(dir .. "/" .. recent, "DATA") then
                recentMaps = util.JSONToTable(file.Read(dir .. "/" .. recent, "DATA"))
                if #recentMaps >= 3 then recentMaps = table.move(recentMaps, 1, 3, 1, {}) end
            end
        end)
    end
end