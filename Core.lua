-- QuickChat: settings, slash commands and start-up.

local ADDON, ns = ...
local L = ns.L

local DEFAULTS = {
  enabled = true,
  alpha = 0.6,
  hideButtons = true,
  arrowHistory = true,
}

local DB
local category

local function Print(msg)
  print("|cffaaaaffQuickChat|r " .. msg)
end

local function CopyDefaults(src, dst)
  for k, v in pairs(src) do
    if dst[k] == nil then dst[k] = v end
  end
end

---------------------------------------------------------------------------
-- Reload prompt
---------------------------------------------------------------------------
StaticPopupDialogs["QUICKCHAT_RELOAD"] = {
  text = L.reloadText,
  button1 = L.reload,
  button2 = L.later,
  OnAccept = function() ReloadUI() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function AskReload()
  StaticPopup_Show("QUICKCHAT_RELOAD")
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
local function SetEnabled(v)
  DB.enabled = v and true or false
  if DB.enabled then ns.Skin.Enable(DB) else AskReload() end
end

local function SetHideButtons(v)
  DB.hideButtons = v and true or false
  AskReload()
end

local function SetArrowHistory(v)
  DB.arrowHistory = v and true or false
  ns.Input.Apply(DB)
end

local function SetAlpha(a)
  a = math.max(0, math.min(1, a))
  if ns.Skin.enabled then ns.Skin.SetAlpha(a) else DB.alpha = a end
end

-- Settings panel (Options > AddOns > QuickChat). Guarded: the Settings API differs between clients,
-- and the slash commands keep working even if the panel can't be built.
local function RegisterSettings()
  if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting
          and Settings.RegisterAddOnCategory) then return end
  local VT = Settings.VarType or {}
  local BOOL, NUM = VT.Boolean or "boolean", VT.Number or "number"

  local cat = Settings.RegisterVerticalLayoutCategory("QuickChat")

  local s = Settings.RegisterProxySetting(cat, "QUICKCHAT_ENABLED", BOOL, L.enable, DEFAULTS.enabled,
    function() return DB.enabled end, SetEnabled)
  Settings.CreateCheckbox(cat, s, L.enableTip)

  s = Settings.RegisterProxySetting(cat, "QUICKCHAT_ALPHA", NUM, L.alpha, DEFAULTS.alpha * 100,
    function() return math.floor((DB.alpha or 0) * 100 + 0.5) end,
    function(v) SetAlpha(v / 100) end)
  local opts = Settings.CreateSliderOptions(0, 100, 5)
  if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
    opts:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(v) return v .. "%" end)
  end
  Settings.CreateSlider(cat, s, opts, L.alphaTip)

  s = Settings.RegisterProxySetting(cat, "QUICKCHAT_BUTTONS", BOOL, L.buttons, DEFAULTS.hideButtons,
    function() return DB.hideButtons end, SetHideButtons)
  Settings.CreateCheckbox(cat, s, L.buttonsTip)

  s = Settings.RegisterProxySetting(cat, "QUICKCHAT_ARROWS", BOOL, L.arrows, DEFAULTS.arrowHistory,
    function() return DB.arrowHistory end, SetArrowHistory)
  Settings.CreateCheckbox(cat, s, L.arrowsTip)

  Settings.RegisterAddOnCategory(cat)
  category = cat
end

local function OpenSettings()
  if category and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(category:GetID())
    return true
  end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function Status()
  Print(L.status:format(DB.enabled and L.on or L.off, math.floor(DB.alpha * 100 + 0.5),
    DB.hideButtons and L.hidden or L.shown, DB.arrowHistory and L.on or L.off))
end

SLASH_QUICKCHAT1 = "/qchat"
SLASH_QUICKCHAT2 = "/quickchat"
SlashCmdList.QUICKCHAT = function(msg)
  local cmd, arg = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")
  local n = tonumber(arg)
  if cmd == "" or cmd == "config" or cmd == "options" then
    if not OpenSettings() then Status(); Print(L.help) end
  elseif cmd == "on" then SetEnabled(true); Status()
  elseif cmd == "off" then SetEnabled(false)
  elseif cmd == "alpha" and n then SetAlpha(n > 1 and n / 100 or n); Status()
  elseif cmd == "buttons" then SetHideButtons(not DB.hideButtons)
  elseif cmd == "arrows" then SetArrowHistory(not DB.arrowHistory); Status()
  elseif cmd == "status" then Status()
  elseif cmd == "debug" then ns.Skin.Debug(Print)
  else Print(L.help)
  end
end

---------------------------------------------------------------------------
-- Start-up
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    QuickChatDB = QuickChatDB or {}
    DB = QuickChatDB
    CopyDefaults(DEFAULTS, DB)
    local ok, err = pcall(RegisterSettings)
    if not ok then category = nil; geterrorhandler()(err) end
  elseif event == "PLAYER_LOGIN" then
    if DB.enabled then ns.Skin.Enable(DB) end
    ns.Input.Enable(DB)
    self:UnregisterAllEvents()
  end
end)
