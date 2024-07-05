if SAM_LOADED then return end
local sam, command, language = sam, sam.command, sam.language
command.set_category("RTV")
do
    command.new("rtv"):SetPermission("rtv", "user"):Help("rtv_help"):OnExecute(function(ply) RTV.VoteForChange(ply) end):End()
    command.new("nominate"):SetPermission("nominate", "user"):AddArg("votemap", {
        optional = false,
    }):GetRestArgs():Help("nominate_help"):OnExecute(function(ply, map)
        if isnumber(map) then map = sam.get_global("Votemap.Allowed")[map] end
        RTV.NominateMap(ply, map)
    end):End()

    command.new("startrtv"):SetPermission("startrtv", "superadmin"):Help("startrtv_help"):OnExecute(function(ply)
        sam.player.send_message(ply, "rtv_start", {
            A = ply
        })

        RTV.StartVoting()
    end):End()

    command.new("stoprtv"):SetPermission("stoprtv", "superadmin"):Help("stoprtv_help"):OnExecute(function(ply)
        sam.player.send_message(ply, "rtv_stop", {
            A = ply,
        })

        RTV.Cancel()
    end):End()

    command.new("rtvavgplayers"):SetPermission("rtvavgplayers", "superadmin"):AddArg("length", {
        optional = true,
        default = 0,
        min = 0,
        max = game.MaxPlayers()
    }):GetRestArgs():Help("rtvavgplayers_help"):OnExecute(function(ply, count)
        local state, err = RTV.ChangeMapInfo(game.GetMap(), count, nil, nil)
        if state then
            sam.player.send_message(nil, "rtv_avg_changed", {
                A = ply,
                V = count
            })
        else
            sam.player.send_message(ply, "rtv_avg_error", {
                S = err
            })
        end
    end):End()

    if SERVER then
        hook.Add("SAM.Votemap.Success", "RTV.UpdateMapInfo", function(map)
            local _, c_data = RTV.ViewMapInfo(map)
            RTV.ChangeMapInfo(map, nil, nil, (c_data.picks or 0) + 1)
        end)
    end
end