if SAM_LOADED then return end
local sam, command, language = sam, sam.command, sam.language
command.set_category("Votemap")
do
    command.new("rtv"):SetPermission("rtv", "user"):GetRestArgs():Help("rtv_help"):OnExecute(function(ply) RTV.VoteForChange(ply) end):End()
    command.new("nominate"):SetPermission("nominate", "user"):AddArg("votemap", {
        optional = true,
    }):GetRestArgs():Help("nominate_help"):OnExecute(function(ply, map) RTV.NominateMap(ply, map) end):End()

    command.new("startrtv"):SetPermission("startrtv", "superadmin"):GetRestArgs():Help("startrtv_help"):OnExecute(function(ply)
        sam.player.send_message(nil, "{A} запустил{S} голосование на смену карты", {
            A = ply,
            S = ply:IsFemale("а", "")
        })

        RTV.StartVoting()
    end):End()

    command.new("stoprtv"):SetPermission("stoprtv", "superadmin"):GetRestArgs():Help("stoprtv_help"):OnExecute(function(ply)
        sam.player.send_message(nil, "{A} остановил{S} голосование", {
            A = ply,
            S = ply:IsFemale("а", "")
        })

        RTV.Cancel()
    end):End()

    command.new("rtvavgplayers"):SetPermission("rtvavgplayers", "superadmin"):AddArg( "length", { optional = true, default = 0, min = 0, max = game.MaxPlayers() } ):GetRestArgs():Help("rtvavgplayers_help")
    :OnExecute(function(ply, count)
        local state, err = RTV.ChangeMapInfo(game.GetMap(), count, nil, nil)
        if state then
            sam.player.send_message(nil, "{A} изменил{S} количество игроков для текущей карты на {V}", {
                A = ply,
                S = ply:IsFemale("а", ""),
                V = count
            })
        else
            sam.player.send_message(ply, "Ошибка: ${S}", {
                S = err
            })
        end
    end):End()

    if SERVER then
        hook.Add("SAM.Votemap.Success", "RTV.UpdateMapInfo", function(map)
            local _, c_data = RTV.ViewMapInfo(map)
            RTV.ChangeMapInfo(map, nil, os.time(), c_data.picks or 0 + 1)
        end)
    end
end