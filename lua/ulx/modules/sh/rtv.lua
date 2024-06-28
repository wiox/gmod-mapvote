local CATEGORY_NAME = "MapVote"
------------------------------ VoteMap ------------------------------
function ulx.mapvote(calling_ply, votetime, should_cancel)
	if not should_cancel then
		RTV.RunVote(votetime)
		ulx.fancyLogAdmin( calling_ply, "#A called a votemap!" )
	else
		RTV.Cancel()
		ulx.fancyLogAdmin( calling_ply, "#A canceled the votemap" )
	end
end

local mapvotecmd = ulx.command(CATEGORY_NAME, "mapvote", ulx.mapvote, "!mapvote")
mapvotecmd:addParam{type = ULib.cmds.NumArg,min = 15,default = 25,hint = "time",ULib.cmds.optional,ULib.cmds.round}
mapvotecmd:addParam{type = ULib.cmds.BoolArg,invisible = true}
mapvotecmd:defaultAccess(ULib.ACCESS_ADMIN)
mapvotecmd:help("Invokes the map vote logic")
mapvotecmd:setOpposite("unmapvote", {_, _, true}, "!unmapvote")

function ulx.vote_rtv(calling_ply)
	RTV.VoteForChange(calling_ply)
end
local votertvcmd = ulx.command(CATEGORY_NAME, "rtv", ulx.vote_rtv, "!rtv")
votertvcmd:defaultAccess(ULib.ACCESS_ALL)
votertvcmd:help("Vote to change the map")

function ulx.nominate_rtv(calling_ply, map)
	-- From original ulx.votemap
	if not map or map == "" then
		ULib.tsay( calling_ply, "Map list printed to console", true )
		ULib.console( calling_ply, "Use \"votemap <id>\" to vote for a map. Map list:" )
		for id, map in ipairs( ulx.votemaps ) do
			ULib.console( calling_ply, "  " .. id .. " -\t" .. map )
		end
		return
	end
	local mapid
	if tonumber( map ) then
		mapid = tonumber( map )
		if not ulx.votemaps[ mapid ] then
			ULib.tsayError( calling_ply, "Invalid map id!", true )
			return
		end
	else
		if string.sub( map, -4 ) == ".bsp" then
			map = string.sub( map, 1, -5 ) -- Take off the .bsp
		end

		mapid = ULib.findInTable( ulx.votemaps, map )
		if not mapid then
			ULib.tsayError( calling_ply, "Invalid map!", true )
			return
		end
	end
	--
	RTV.NominateMap(calling_ply, ulx.votemaps[ mapid ])
end

local nominatecmd = ulx.command(CATEGORY_NAME, "nominate", ulx.nominate_rtv, "!nominate")
nominatecmd:addParam{ type = ULib.cmds.StringArg, completes = ulx.votemaps, hint = "map", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
nominatecmd:defaultAccess( ULib.ACCESS_ALL )
nominatecmd:help("Nominate map")


if SERVER then
	hook.Add("ULX.Votemap.Success", "RTV.UpdateMapInfo", function(map)
		local _, c_data = RTV.ViewMapInfo(map)
		RTV.ChangeMapInfo(map, nil, os.time(), c_data.picks or 0 + 1)
	end)
end