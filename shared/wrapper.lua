Wrapper = {}

-- [ Emotes ]
function Wrapper.PlayEmote(name)
    local emoteSystem = Config.EmoteSystem or "rpemotes-reborn"
    if emoteSystem == "rpemotes-reborn" then
        if GetResourceState("rpemotes-reborn") == "started" then
            exports["rpemotes-reborn"]:EmoteCommandStart(name)
        else
            print("^1[ng_event] Error: rpemotes-reborn is not started but selected in config.^7")
        end
    elseif emoteSystem == "scully_emotemenu" then
        if GetResourceState("scully_emotemenu") == "started" then
            exports["scully_emotemenu"]:playEmoteByCommand(name)
        else
            print("^1[ng_event] Error: scully_emotemenu is not started but selected in config.^7")
        end
    end
end

function Wrapper.CancelEmote()
    local emoteSystem = Config.EmoteSystem or "rpemotes-reborn"
    if emoteSystem == "rpemotes-reborn" then
        if GetResourceState("rpemotes-reborn") == "started" then
            exports["rpemotes-reborn"]:EmoteCancel()
        end
    elseif emoteSystem == "scully_emotemenu" then
        if GetResourceState("scully_emotemenu") == "started" then
            exports["scully_emotemenu"]:cancelEmote()
        end
    end
end
