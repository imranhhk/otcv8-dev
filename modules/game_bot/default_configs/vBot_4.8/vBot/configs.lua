--[[ 
    Configs for modules
    Based on Kondrah storage method  
--]]
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
local characterName = g_game.getCharacterName()
local characterKey = characterName:lower():gsub("[^%w%-_]", "_")

-- make vBot config dir
local charactersPath = "/bot/" .. configName .. "/characters/"
if not g_resources.directoryExists(charactersPath) then
  g_resources.makeDir(charactersPath)
end

local characterPath = charactersPath .. characterKey .. "/"
if not g_resources.directoryExists(characterPath) then
  g_resources.makeDir(characterPath)
end

local configsPath = characterPath .. "vBot_configs/"
if not g_resources.directoryExists(configsPath) then
  g_resources.makeDir(configsPath)
end

-- make profile dirs
for i=1,10 do
  local path = configsPath .. "profile_" .. i
  if not g_resources.directoryExists(path) then
    g_resources.makeDir(path)
  end
end

local profile = g_settings.getNumber('profile')
local profilePath = configsPath .. "profile_" .. profile .. "/"
local legacyProfilePath = "/bot/" .. configName .. "/vBot_configs/profile_" .. profile .. "/"

HealBotConfig = {}
local healBotFile = profilePath .. "HealBot.json"
local legacyHealBotFile = legacyProfilePath .. "HealBot.json"
AttackBotConfig = {}
local attackBotFile = profilePath .. "AttackBot.json"
local legacyAttackBotFile = legacyProfilePath .. "AttackBot.json"
SuppliesConfig = {}
local suppliesFile = profilePath .. "Supplies.json"
local legacySuppliesFile = legacyProfilePath .. "Supplies.json"

local function loadConfig(configFile, legacyFile, label)
  local file = g_resources.fileExists(configFile) and configFile or legacyFile
  if not g_resources.fileExists(file) then
    return {}, false
  end

  local status, result = pcall(function()
    return json.decode(g_resources.readFileContents(file))
  end)
  if not status then
    onError("Error while reading config file (" .. file .. "). To fix this problem you can delete " .. label .. ".json. Details: " .. result)
    return {}, false
  end

  return result, file == legacyFile
end

local migrateHealBot
local migrateAttackBot
local migrateSupplies
HealBotConfig, migrateHealBot = loadConfig(healBotFile, legacyHealBotFile, "HealBot")
AttackBotConfig, migrateAttackBot = loadConfig(attackBotFile, legacyAttackBotFile, "AttackBot")
SuppliesConfig, migrateSupplies = loadConfig(suppliesFile, legacySuppliesFile, "Supplies")

function vBotConfigSave(file)
  -- file can be either
  --- heal
  --- atk
  --- supply
  local configFile 
  local configTable
  if not file then return end
  file = file:lower()
  if file == "heal" then
      configFile = healBotFile
      configTable = HealBotConfig
  elseif file == "atk" then
      configFile = attackBotFile
      configTable = AttackBotConfig
  elseif file == "supply" then
      configFile = suppliesFile
      configTable = SuppliesConfig
  else
    return
  end

  local status, result = pcall(function() 
    return json.encode(configTable, 2) 
  end)
  if not status then
    return onError("Error while saving config. it won't be saved. Details: " .. result)
  end
  
  if result:len() > 100 * 1024 * 1024 then
    return onError("config file is too big, above 100MB, it won't be saved")
  end

  g_resources.writeFileContents(configFile, result)
end

-- Preserve existing shared profiles by copying them on the character's first load.
if migrateHealBot then vBotConfigSave("heal") end
if migrateAttackBot then vBotConfigSave("atk") end
if migrateSupplies then vBotConfigSave("supply") end
