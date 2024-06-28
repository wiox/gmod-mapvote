RTV = RTV or {}
--RTV.Runned = false
RTV.UPDATE_VOTE = 1
RTV.UPDATE_WIN = 3

if engine.ActiveGamemode() ~= "jailbreak" then
    hook.Add(
        "PlayerInitialSpawn",
        "PlayerCheckLoad",
        function(ply)
            hook.Add(
                "SetupMove",
                ply,
                function(self, player, _, cmd)
                    if self == player and not cmd:IsForced() then
                        hook.Remove("SetupMove", self)
                        hook.Run("PlayerFullLoad", self)
                    end
                end
            )
        end
    )
end

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("client/cl_rtv_vote.lua")
    include("server/sv_config.lua")
    include("server/sv_rtv.lua")
    include("server/sv_rtv_vote.lua")
    include("server/sv_autortv.lua")
else
    include("client/cl_rtv_vote.lua")
end

-- hook.Add("SAM.Loading", "SAM.RTV_Init", function(load)
--     load("sam/")
-- end)