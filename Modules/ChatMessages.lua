ChatMessages = {}

local NullRoll = { name = "", min = 0, max = 0, val = 0 }

-- Attempts to parse a roll from a system message.
function ChatMessages:ParseRoll(msg, ...)
    if msg then
        local name, value, minRoll, maxRoll = msg:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")
        local roll = {
            name = name,
            min = tonumber(minRoll),
            max = tonumber(maxRoll),
            val = tonumber(value)
        }
        if roll.name and roll.val >= roll.min and roll.val <= roll.max then
            return true, roll
        end
    end
    return false, NullRoll
end

-- Attempts to derive the first item link out of a chat message.
function ChatMessages:ParseItemLink(msg, ...)
    if msg then
        local link = msg:match("|%x+|Hitem:.-|h.-|h|r")
        return not (link == nil), link 
    end
    return false, ""
end
