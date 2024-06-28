hook.Add("Initialize", "AutoMapVoteCheck", function()
  if GAMEMODE_NAME == "jailbreak" then
    SetGlobalInt("jb_mapvote_started", CurTime())
    local hoursForRunRTV = 1
    local function initTimer()
      timer.Create("RTV.StartVote", hoursForRunRTV * 3600, 1, function() RTV.StartVoting() end)
    end

    hook.Add("RTVResumeMap", "retryMapVote", function()
      if timer.Exists("RTV.StartVote") then timer.Remove("RTV.StartVote") end
      initTimer()
      SetGlobalInt("jb_mapvote_started", CurTime())
    end)

    initTimer()
  end
end)