RTV = RTV or {}
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
    AddCSLuaFile("shared/sh_utils.lua")
    AddCSLuaFile("shared/sh_rtv.lua")
    AddCSLuaFile("client/cl_rtv_vote.lua")
    include("shared/sh_utils.lua")
    include("server/sv_config.lua")
    include("server/sv_rtv.lua")
    include("server/sv_rtv_vote.lua")
    include("server/sv_autortv.lua")
    include("shared/sh_rtv.lua")
else
    include("shared/sh_utils.lua")
    include("client/cl_rtv_vote.lua")
    include("shared/sh_rtv.lua")
end