local version = "4.8"
local currentVersion
local available = false

-- Keep vBot's runtime settings separate without changing the game bot's
-- shared storage implementation.
local characterName = g_game.getCharacterName()
local characterKey = characterName:lower():gsub("[^%w%-_]", "_")
local characterProfiles = storage._characterProfiles
if not characterProfiles then
    characterProfiles = {}
    storage._characterProfiles = characterProfiles
end

if not characterProfiles[characterKey] then
    local characterStorage = {}
    -- Start the first character profile with the existing shared settings.
    for key, value in pairs(storage) do
        if key ~= "_characterProfiles" then
            characterStorage[key] = value
        end
    end
    characterProfiles[characterKey] = characterStorage
end

storage = characterProfiles[characterKey]

storage.checkVersion = storage.checkVersion or 0

-- check max once per 12hours
if os.time() > storage.checkVersion + (12 * 60 * 60) then

    storage.checkVersion = os.time()
    
    HTTP.get("https://raw.githubusercontent.com/Vithrax/vBot/main/vBot/version.txt", function(data, err)
        if err then
          warn("[vBot updater]: Unable to check version:\n" .. err)
          return
        end

        currentVersion = data
        available = true
    end)

end

UI.Label("vBot v".. version .." \n Vithrax#5814")
UI.Button("Official OTCv8 Discord!", function() g_platform.openUrl("https://discord.gg/yhqBE4A") end)
UI.Separator()

schedule(5000, function()

    if not available then return end
    if currentVersion ~= version then
        
        UI.Separator()
        UI.Label("New vBot is available for download! v"..currentVersion)
        UI.Button("Go to vBot GitHub Page", function() g_platform.openUrl("https://github.com/Vithrax/vBot") end)
        UI.Separator()
        
    end

end)
