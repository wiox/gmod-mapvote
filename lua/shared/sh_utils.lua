local RTV = RTV
local floor, format, rep = math.floor, string.format, string.rep
do
    local times = {31536000, 2628000, 604800, 86400, 3600, 60, 1,}
    function RTV.TimeFormat(seconds)
        if seconds <= 0 then return "00:00" end
        local str, ends = ""
        for k, v in pairs(times) do
            local n1, n2 = v
            n2, seconds = floor(seconds / n1), seconds % n1
            if n2 > 0 then str = str .. (str == "" and n2 or (":" .. format("%02i", n2))) end
            if seconds == 0 then
                ends = k
                break
            end
        end
        return str .. (ends == #times and "" or (":" .. rep("00", #times - ends, ":")))
    end
end