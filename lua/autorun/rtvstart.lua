RTV = RTV or {}
--RTV.Runned = false
RTV.UPDATE_VOTE = 1
RTV.UPDATE_WIN = 3

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("client/cl_rtv_vote.lua")
    include("server/sv_config.lua")
    include("server/sv_rtv.lua")
    include("server/sv_rtv_vote.lua")
else
    include("client/cl_rtv_vote.lua")
end

-- hook.Add("SAM.Loading", "SAM.RTV_Init", function(load)
--     load("sam/")
-- end)