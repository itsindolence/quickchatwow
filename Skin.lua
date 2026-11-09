-- QuickChat: visual restyle of the default Blizzard chat windows.
-- Touches only frames and textures: backgrounds, borders, tabs, the input line and side buttons.
-- It never reads, filters or rewrites chat messages, so it stays clear of Midnight-era secret
-- values and of the secure paths used when slash commands are sent from the edit box.

local _, ns = ...

local Skin = {}
ns.Skin = Skin

local BG      = { 0.051, 0.055, 0.071 }   -- #0D0E12, same as the QuickChannels bar
local BORDER  = { 1, 1, 1, 0.08 }
local ACCENT  = { 0.667, 0.667, 1 }       -- #AAAAFF
local TAB_ON  = { 1, 1, 1 }
local TAB_OFF = { 0.62, 0.65, 0.72 }
local PAD     = 5

local skinned = {}       -- [blizzard frame] = our own textures (kept off Blizzard tables)
local DB

-- Parking frame for buttons we hide: reparenting is sturdier than fighting Show() calls.
local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local function Kill(tex)
  if tex and tex.SetTexture then
    tex:SetTexture(nil)
    tex:SetAlpha(0)
  end
end

local function Box(parent, layer, sub)
  local t = {}
  layer, sub = layer or "BACKGROUND", sub or -8
  t.bg = parent:CreateTexture(nil, layer, nil, sub)
  t.bg:SetColorTexture(1, 1, 1, 1)
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    local b = parent:CreateTexture(nil, layer, nil, sub + 1)
    b:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
    t[side] = b
  end
  function t:Place(anchor, l, top, r, bottom)
    local bg = self.bg
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", anchor, "TOPLEFT", -l, top)
    bg:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", r, -bottom)
    self.top:SetPoint("TOPLEFT", bg, "TOPLEFT");          self.top:SetPoint("TOPRIGHT", bg, "TOPRIGHT");          self.top:SetHeight(1)
    self.bottom:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT");  self.bottom:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT");  self.bottom:SetHeight(1)
    self.left:SetPoint("TOPLEFT", bg, "TOPLEFT");         self.left:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT");      self.left:SetWidth(1)
    self.right:SetPoint("TOPRIGHT", bg, "TOPRIGHT");      self.right:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT");   self.right:SetWidth(1)
  end
  function t:SetColor(r, g, b, a) self.bg:SetVertexColor(r, g, b, a) end
  return t
end

---------------------------------------------------------------------------
-- Tabs
---------------------------------------------------------------------------
local function IsSelected(tab)
  local cf = _G["ChatFrame" .. tab:GetID()]
  if not cf then return false end
  if not cf.isDocked then return true end
  return FCFDock_GetSelectedWindow and GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) == cf
end

local function StyleTab(tab, selected)
  local s = skinned[tab]
  if not s then return end
  if selected == nil then selected = IsSelected(tab) end
  local fs = tab.GetFontString and tab:GetFontString()
  local c = selected and TAB_ON or TAB_OFF
  if fs then fs:SetTextColor(c[1], c[2], c[3]) end
  s.line:SetShown(selected and true or false)
  -- Blizzard tints the "new message" glow with the tab colour; keep ours in the accent colour.
  if tab.glow then tab.glow:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3]) end
end

local TAB_KEYS = { "Left", "Middle", "Right", "ActiveLeft", "ActiveMiddle", "ActiveRight",
                   "HighlightLeft", "HighlightMiddle", "HighlightRight" }
local TAB_NAMED = { "Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle", "SelectedRight",
                    "HighlightLeft", "HighlightMiddle", "HighlightRight" }

local function SkinTab(tab)
  if not tab or skinned[tab] then return end
  for _, k in ipairs(TAB_KEYS) do Kill(tab[k]) end
  local name = tab:GetName()
  if name then
    for _, k in ipairs(TAB_NAMED) do Kill(_G[name .. k]) end
  end

  local s = {}
  -- accent underline for the selected tab
  s.line = tab:CreateTexture(nil, "ARTWORK")
  s.line:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
  s.line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 8, 2)
  s.line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -8, 2)
  s.line:SetHeight(2)
  -- soft hover
  s.hover = tab:CreateTexture(nil, "HIGHLIGHT")
  s.hover:SetColorTexture(1, 1, 1, 0.06)
  s.hover:SetPoint("TOPLEFT", tab, "TOPLEFT", 4, -6)
  s.hover:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -4, 0)

  -- "new message" glow becomes a thin pulsing line in the underline spot
  local glow = tab.glow or (name and _G[name .. "Glow"])
  if glow then
    glow:SetTexture(nil)
    glow:SetColorTexture(1, 1, 1, 0.9)
    glow:SetBlendMode("BLEND")
    glow:ClearAllPoints()
    glow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 8, 2)
    glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -8, 2)
    glow:SetHeight(2)
  end

  local fs = tab.GetFontString and tab:GetFontString()
  if fs then fs:SetShadowOffset(1, -1); fs:SetShadowColor(0, 0, 0, 1) end

  skinned[tab] = s
  StyleTab(tab)
end

local function StyleAllTabs()
  for obj in pairs(skinned) do
    if obj.GetFontString and obj.GetID and not obj.AddMessage and _G["ChatFrame" .. obj:GetID() .. "Tab"] == obj then
      StyleTab(obj)
    end
  end
end

---------------------------------------------------------------------------
-- Edit box (input line)
---------------------------------------------------------------------------
local function ColorEditBox(eb)
  local s = skinned[eb]
  if not s then return end
  local ct = eb.GetAttribute and eb:GetAttribute("chatType") or "SAY"
  if ct == "CHANNEL" then
    local target = eb:GetAttribute("channelTarget")
    local id = target and (tonumber(target) or (GetChannelName and GetChannelName(target)))
    if id and id ~= 0 then ct = "CHANNEL" .. id end
  end
  local info = ChatTypeInfo and (ChatTypeInfo[ct] or ChatTypeInfo.SAY)
  if info then s.accent:SetColorTexture(info.r or 1, info.g or 1, info.b or 1, 1) end
end

local function SkinEditBox(eb)
  if not eb or skinned[eb] then return end
  local name = eb:GetName()
  if name then
    for _, k in ipairs({ "Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid" }) do
      Kill(_G[name .. k])
    end
  end
  Kill(eb.focusLeft); Kill(eb.focusRight); Kill(eb.focusMid)

  local s = {}
  s.box = Box(eb, "BACKGROUND", -6)
  s.box:Place(eb, -5, -4, -5, -4)
  s.box:SetColor(0.02, 0.025, 0.035, 0.92)
  s.accent = eb:CreateTexture(nil, "BORDER")
  s.accent:SetPoint("TOPLEFT", s.box.bg, "TOPLEFT", 1, -1)
  s.accent:SetPoint("BOTTOMLEFT", s.box.bg, "BOTTOMLEFT", 1, 1)
  s.accent:SetWidth(3)
  skinned[eb] = s

  eb:HookScript("OnAttributeChanged", function(box, attr)
    attr = attr and attr:lower()
    if attr == "chattype" or attr == "channeltarget" then ColorEditBox(box) end
  end)
  eb:HookScript("OnShow", ColorEditBox)
  ColorEditBox(eb)
end

---------------------------------------------------------------------------
-- Chat window
---------------------------------------------------------------------------
local BORDER_TEXTURES = {
  "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture",
  "LeftTexture", "RightTexture", "BottomTexture", "TopTexture",
  "ButtonFrameBackground", "ButtonFrameTopLeftTexture", "ButtonFrameBottomLeftTexture",
  "ButtonFrameTopRightTexture", "ButtonFrameBottomRightTexture", "ButtonFrameLeftTexture",
  "ButtonFrameRightTexture", "ButtonFrameBottomTexture", "ButtonFrameTopTexture",
}

local function ApplyAlpha(cf)
  local s = skinned[cf]
  if s then s.box:SetColor(BG[1], BG[2], BG[3], DB.alpha or 0.6) end
end

local function Park(f)
  if f and f.SetParent and f:GetParent() ~= hiddenParent then
    f:SetParent(hiddenParent)
  end
end

-- Buttons that float next to ChatFrame1 but are not children of its button frame.
local SHARED_BUTTONS = { "ChatFrameMenuButton", "ChatFrameChannelButton", "QuickJoinToastButton",
                         "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton",
                         "TextToSpeechButtonFrame", "FriendsMicroButton" }

local function HideSharedButtons()
  for _, n in ipairs(SHARED_BUTTONS) do Park(_G[n]) end
end

local function SkinFrame(cf)
  if not cf or skinned[cf] then return end
  local name = cf:GetName()
  if not name then return end
  -- Blizzard's own background and border stay invisible; ours does not fade on hover.
  Kill(cf.Background or _G[name .. "Background"])
  for _, k in ipairs(BORDER_TEXTURES) do Kill(_G[name .. k]) end

  local s = {}
  s.box = Box(cf, "BACKGROUND", -8)
  s.box:Place(cf, PAD, PAD, PAD + 2, PAD)
  skinned[cf] = s
  ApplyAlpha(cf)

  if DB.hideButtons then Park(cf.buttonFrame or _G[name .. "ButtonFrame"]) end
  local rb = cf.ResizeButton or _G[name .. "ResizeButton"]
  if rb and rb.SetAlpha then rb:SetAlpha(0.35) end

  SkinTab(_G[name .. "Tab"])
  SkinEditBox(cf.editBox or _G[name .. "EditBox"])
end

local function SkinAll()
  for _, frameName in ipairs(CHAT_FRAMES or {}) do SkinFrame(_G[frameName]) end
  for i = 1, (NUM_CHAT_WINDOWS or 10) do SkinFrame(_G["ChatFrame" .. i]) end
end

function Skin.SetAlpha(a)
  DB.alpha = a
  for obj in pairs(skinned) do
    if obj.AddMessage then ApplyAlpha(obj) end
  end
end

function Skin.Enable(db)
  DB = db
  if Skin.enabled then return end
  Skin.enabled = true
  SkinAll()
  if DB.hideButtons then HideSharedButtons() end

  -- whisper / pet battle / new windows created later
  if FCF_OpenTemporaryWindow then hooksecurefunc("FCF_OpenTemporaryWindow", SkinAll) end
  if FCF_OpenNewWindow then hooksecurefunc("FCF_OpenNewWindow", SkinAll) end
  if FCFTab_UpdateColors then
    hooksecurefunc("FCFTab_UpdateColors", function(tab, selected) StyleTab(tab, selected) end)
  end
  if FCF_DockUpdate then hooksecurefunc("FCF_DockUpdate", StyleAllTabs) end
  if FCFDock_SelectWindow then hooksecurefunc("FCFDock_SelectWindow", StyleAllTabs) end
end
