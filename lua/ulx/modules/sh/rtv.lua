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
mapvotecmd:addParam{
	type = ULib.cmds.NumArg,
	min = 15,
	default = 25,
	hint = "time",
	ULib.cmds.optional,
	ULib.cmds.round
}

mapvotecmd:addParam{
	type = ULib.cmds.BoolArg,
	invisible = true
}

mapvotecmd:defaultAccess(ULib.ACCESS_ADMIN)
mapvotecmd:help("Invokes the map vote logic")
mapvotecmd:setOpposite("unmapvote", {_, _, true}, "!unmapvote")
function ulx.vote_rtv(calling_ply)
	RTV.VoteForChange(calling_ply)
end

local votertvcmd = ulx.command(CATEGORY_NAME, "rtv", ulx.vote_rtv, "!rtv")
votertvcmd:defaultAccess(ULib.ACCESS_ADMIN)
votertvcmd:help("Invokes the map vote logic")
-- function ulx.nominate_rtv(calling_ply)
-- 	RTV.NominateMap(ply, map)
-- end

-- local nominatecmd = ulx.command(CATEGORY_NAME, "rtv", ulx.nominate_rtv, "!rtv")
-- nominatecmd:addParam{
-- 	type = ULib.cmds.NumArg,
-- 	min = 15,
-- 	default = 25,
-- 	hint = "time",
-- 	ULib.cmds.optional,
-- 	ULib.cmds.round
-- }

-- nominatecmd:defaultAccess(ULib.ACCESS_ADMIN)
-- nominatecmd:help("Invokes the map vote logic")


if SERVER then
	hook.Add("ULX.Votemap.Success", "RTV.UpdateMapInfo", function(map)
		local _, c_data = RTV.ViewMapInfo(map)
		RTV.ChangeMapInfo(map, nil, os.time(), c_data.picks or 0 + 1)
	end)
end