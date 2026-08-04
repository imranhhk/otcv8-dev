-- Solace is a small, conservative assistant for everyday play.
-- Every action that can affect gameplay starts disabled so the player remains
-- in control when selecting this profile for the first time.

setDefaultTab("Solace")

UI.Label("SOLACE 1.0 - everyday player assistant")
UI.Label("Configure a feature, then click its switch to enable it.")
UI.Label("All features are OFF on first use.")
UI.Separator()

if type(storage.solace) ~= "table" then
  storage.solace = {}
end

local config = storage.solace

UI.Label("HEALING SPELL")
UI.Label("Casts only while your health is inside the selected range.")
if type(config.heal) ~= "table" then
  config.heal = {on = false, title = "HP", text = "exura", min = 1, max = 70}
end

local healMacro = macro(250, "Solace: healing spell", function()
  local health = hppercent()
  if health >= config.heal.min and health <= config.heal.max then
    saySpell(config.heal.text, 1000)
  end
end)
healMacro.setOn(config.heal.on)

UI.DualScrollPanel(config.heal, function(widget, values)
  config.heal = values
  healMacro.setOn(values.on and values.text:len() > 0)
end)

UI.Separator()
UI.Label("MANA POTION")
UI.Label("Drop your server's potion on the item slot below.")
if type(config.manaPotion) ~= "table" then
  config.manaPotion = {on = false, title = "MP", item = 0, min = 1, max = 45}
end

local manaMacro = macro(500, function()
  local manaPercent = manapercent()
  if config.manaPotion.item > 100 and manaPercent >= config.manaPotion.min and manaPercent <= config.manaPotion.max then
    usewith(config.manaPotion.item, player, config.manaPotion.subType)
  end
end)
manaMacro.setOn(config.manaPotion.on and config.manaPotion.item > 100)

UI.DualScrollItemPanel(config.manaPotion, function(widget, values)
  config.manaPotion = values
  manaMacro.setOn(values.on and values.item > 100)
end)

UI.Separator()
UI.Label("FOOD")
UI.Label("Add one or more foods. Solace checks open backpacks.")
if type(config.food) ~= "table" then
  config.food = {}
end

local foodItems = UI.Container(function(widget, items)
  config.food = items
end, true)
foodItems:setHeight(35)
foodItems:setItems(config.food)

macro(15000, "Solace: eat food", function()
  for _, container in pairs(g_game.getContainers()) do
    for _, item in ipairs(container:getItems()) do
      for _, food in ipairs(config.food) do
        if item:getId() == food.id then
          return use(item)
        end
      end
    end
  end
end)

UI.Separator()
UI.Label("SAFETY WATCH")
UI.Label("Sounds an alarm for low health or a newly visible player.")
UI.Label("The alarm has a 10 second cooldown to avoid noise spam.")
if type(config.safety) ~= "table" then
  config.safety = {health = 30, players = true}
end

UI.Label("Low-health alarm threshold:")
UI.TextEdit(tostring(config.safety.health), function(widget, text)
  local value = tonumber(text)
  if value then
    config.safety.health = math.max(1, math.min(99, math.floor(value)))
  end
end)

local playerWatchButton = UI.Button("")
local function updatePlayerWatchButton()
  playerWatchButton:setText("Visible-player alert: " .. (config.safety.players and "YES" or "NO"))
  playerWatchButton:setOn(config.safety.players)
end
playerWatchButton.onClick = function()
  config.safety.players = not config.safety.players
  updatePlayerWatchButton()
end
updatePlayerWatchButton()

local lastAlarm = 0
local visiblePlayers = {}
macro(500, "Solace: safety watch", function()
  local reason = nil
  local seenNow = {}

  if hppercent() <= config.safety.health then
    reason = "health is at " .. hppercent() .. "%"
  end

  if config.safety.players then
    for _, creature in ipairs(getSpectators(false)) do
      if creature:isPlayer() and creature:getId() ~= player:getId() then
        local id = creature:getId()
        seenNow[id] = true
        if not visiblePlayers[id] then
          reason = "player nearby: " .. creature:getName()
        end
      end
    end
  end
  visiblePlayers = seenNow

  if reason and lastAlarm + 10000 <= now then
    lastAlarm = now
    playAlarm()
    warn("Solace alert - " .. reason)
    if g_window then
      g_window.flash()
    end
  end
end)

UI.Separator()
UI.Label("Tip: switches and settings are saved per OTClient profile.")
UI.Label("Use only automation permitted by your game server's rules.")
