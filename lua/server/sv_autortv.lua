hook.Add("Initialize", "AutoMapVoteCheck", function()
  if GAMEMODE_NAME == "jailbreak" then
    local hoursForRunRTV = 1
    local function initTimer()
      SetGlobalInt("mapvote_next", CurTime() + (hoursForRunRTV * 3600))
      timer.Create("RTV.StartVote", hoursForRunRTV * 3600, 1, function() RTV.StartVoting() end)
    end

    hook.Add("RTVResumeMap", "retryMapVote", function()
      if timer.Exists("RTV.StartVote") then timer.Remove("RTV.StartVote") end
      initTimer()
    end)

    hook.Add("RTV.ChangeMap", "RTV.RemoveTimerOnSuccess", function()
      if not timer.Exists("RTV.StartVote") then return end
      timer.Remove("RTV.StartVote")
    end)

    initTimer()
  end
end)