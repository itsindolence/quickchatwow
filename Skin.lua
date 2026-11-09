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
local TAB_OFF = { 0.86, 0.88, 0.93 }
local PAD     = 5
-- Blizzard docks tabs on top of the frame's Background, which sits 3px above the frame;
-- the header strip of our panel covers the tabs so the window reads as one block.
local TAB_BASE = 3
local HEADER   = 28
-- Tabs stay readable instead of fading to 20-40% when the mouse leaves the chat.
local TAB_ALPHA_IDLE = 1
-- Blizzard's GameFontNormalSmall (10px) renders thin and greyish; tabs use the chat font instead.
local TAB_FONT_SIZE = 12

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
  s.line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 6, 0)
  s.line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -6, 0)
  s.line:SetHeight(2)
  -- soft hover, limited to the header strip
  s.hover = tab:CreateTexture(nil, "HIGHLIGHT")
  s.hover:SetColorTexture(1, 1, 1, 0.06)
  s.hover:SetPoint("TOPLEFT", tab, "BOTTOMLEFT", 2, HEADER - 1)
  s.hover:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 1)
  -- Blizzard fades whole tabs to 20-40% when the mouse leaves the chat; label and underline opt
  -- out of that so the header always reads clearly, whatever the client's fade code does.
  if s.line.SetIgnoreParentAlpha then s.line:SetIgnoreParentAlpha(true) end

  -- "new message" glow becomes a thin pulsing line in the underline spot
  local glow = tab.glow or (name and _G[name .. "Glow"])
  if glow then
    glow:SetTexture(nil)
    glow:SetColorTexture(1, 1, 1, 0.9)
    glow:SetBlendMode("BLEND")
    glow:ClearAllPoints()
    glow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 6, 0)
    glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -6, 0)
    glow:SetHeight(2)
  end

  local fs = tab.GetFontString and tab:GetFontString()
  if fs then
    local font = ChatFontNormal and ChatFontNormal:GetFont()
    if font then fs:SetFont(font, TAB_FONT_SIZE, "") end
    fs:SetShadowOffset(1, -1); fs:SetShadowColor(0, 0, 0, 1)
    if fs.SetIgnoreParentAlpha then fs:SetIgnoreParentAlpha(true) end
    -- centre the label in the header strip (Blizzard places it 5px below the 32px tab's middle)
    fs:ClearAllPoints()
    fs:SetPoint("CENTER", tab, "BOTTOM", 0, HEADER / 2)
    if tab.SetPushedTextOffset then tab:SetPushedTextOffset(0, 0) end
  end

  -- Hard stop for tab fading: whichever path the client uses (UIFrameFade, saved alphas, XML
  -- alpha="0.4"), the tab itself stays opaque. Its Blizzard art is gone, so only our label,
  -- underline and alert line are affected.
  tab:SetAlpha(1)
  local forcing
  hooksecurefunc(tab, "SetAlpha", function(self, a)
    if not forcing and a ~= 1 then
      forcing = true
      self:SetAlpha(1)
      forcing = nil
    end
  end)

  skinned[tab] = s
  StyleTab(tab)
end

-- Blizzard keeps per-tab alphas in ChatFrameUtil (read through securecallfunction, so writes from
-- addons are expected there). Older clients keep them on the tab itself.
local settingAlphas
local function TabAlphas(tab)
  local selected = IsSelected(tab)
  return 1, selected and 1 or TAB_ALPHA_IDLE
end

local function FixTabAlpha(cf)
  local tab = cf and cf.GetName and _G[cf:GetName() .. "Tab"]
  if not tab or not skinned[tab] then return end
  local over, idle = TabAlphas(tab)
  if ChatFrameUtil and ChatFrameUtil.SetTabAlphas then
    settingAlphas = true
    ChatFrameUtil.SetTabAlphas(tab, over, idle)
    settingAlphas = nil
  else
    tab.mouseOverAlpha, tab.noMouseAlpha = over, idle
  end
  if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(tab) end
  tab:SetAlpha(cf.hasBeenFaded and over or idle)
end

local function StyleAllTabs()
  for obj in pairs(skinned) do
    if obj.GetFontString and obj.GetID and not obj.AddMessage and _G["ChatFrame" .. obj:GetID() .. "Tab"] == obj then
      StyleTab(obj)
      FixTabAlpha(_G["ChatFrame" .. obj:GetID()])
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

local EB_GAP   = 4   -- space between the chat panel and the input line
local EB_INSET = 4   -- the edit box is 32px tall; our box is drawn 4px inside top and bottom

local function SkinEditBox(eb, cf)
  if not eb or skinned[eb] then return end
  -- Line the input up with the chat panel edges (Blizzard ties its right edge to the scroll bar).
  if cf then
    local y = -(PAD + EB_GAP - EB_INSET)
    eb:ClearAllPoints()
    eb:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -PAD, y)
    eb:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", PAD + 2, y)
  end
  local name = eb:GetName()
  if name then
    for _, k in ipairs({ "Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid" }) do
      Kill(_G[name .. k])
    end
  end
  Kill(eb.focusLeft); Kill(eb.focusRight); Kill(eb.focusMid)

  local s = {}
  s.box = Box(eb, "BACKGROUND", -6)
  s.box:Place(eb, 0, -EB_INSET, 0, -EB_INSET)
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
  -- With the "IM" chat style Blizzard keeps an idle input line at 35% alpha; the channel accent
  -- only makes sense while typing, so it shows on focus.
  local function UpdateFocus(box) s.accent:SetShown(box:HasFocus() and true or false) end
  eb:HookScript("OnEditFocusGained", UpdateFocus)
  eb:HookScript("OnEditFocusLost", UpdateFocus)
  UpdateFocus(eb)
  ColorEditBox(eb)
end

---------------------------------------------------------------------------
-- Scroll bar: a thin flat thumb (perfect-scrollbar style) instead of the
-- Blizzard track with arrows. Blizzard still fades the whole bar in on hover.
---------------------------------------------------------------------------
local THUMB_W = 3

local function SetThumbColor(thumb, hot)
  local s = skinned[thumb]
  if not s then return end
  if hot then
    s.tex:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
  else
    s.tex:SetColorTexture(1, 1, 1, 0.35)
  end
end

local function SkinScrollBar(cf)
  local bar = cf.ScrollBar
  if not bar or skinned[bar] then return end
  skinned[bar] = true

  local track = bar.Track
  if track then
    Kill(track.Begin); Kill(track.Middle); Kill(track.End)
    -- arrows are gone, so the track can use the full height
    track:ClearAllPoints()
    track:SetPoint("TOP", bar, "TOP", 0, -2)
    track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 2)

    local thumb = track.Thumb
    if thumb then
      -- Blizzard swaps atlases on these per mouse state; keeping them transparent is enough.
      for _, k in ipairs({ "Begin", "Middle", "End" }) do
        if thumb[k] then thumb[k]:SetAlpha(0) end
      end
      local t = thumb:CreateTexture(nil, "OVERLAY")
      t:SetPoint("TOP", thumb, "TOP", 0, 0)
      t:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
      t:SetWidth(THUMB_W)
      skinned[thumb] = { tex = t }
      SetThumbColor(thumb, false)
      thumb:HookScript("OnEnter", function(self) SetThumbColor(self, true) end)
      thumb:HookScript("OnLeave", function(self)
        if not IsMouseButtonDown("LeftButton") then SetThumbColor(self, false) end
      end)
      thumb:HookScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then SetThumbColor(self, false) end
      end)
    end
  end

  for _, k in ipairs({ "Back", "Forward" }) do
    local b = bar[k]
    if b then
      if b.Texture then b.Texture:SetAlpha(0) end
      b:SetAlpha(0)
      b:EnableMouse(false)
    end
  end

  -- "jump to newest" arrow: not part of the perfect-scrollbar look. It stays in place (the scroll
  -- bar is anchored to it and Blizzard fades it), but draws nothing and takes no clicks.
  local jump = cf.ScrollToBottomButton
  if jump then
    for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
      Kill(jump[get] and jump[get](jump))
    end
    Kill(jump.Flash)
    jump:EnableMouse(false)
  end
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
  -- The panel lives on its own frame in the BACKGROUND strata: chat frames sit above the tabs
  -- (strata LOW), so textures on the chat frame itself would cover and dim the tab labels.
  s.holder = CreateFrame("Frame", nil, cf)
  s.holder:SetFrameStrata("BACKGROUND")
  s.holder:SetAllPoints(cf)
  s.box = Box(s.holder, "BACKGROUND", -8)
  s.box:Place(cf, PAD, TAB_BASE + HEADER, PAD + 2, PAD)
  -- 1px divider between the tab header and the messages
  s.divider = s.holder:CreateTexture(nil, "BACKGROUND", nil, -7)
  s.divider:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
  s.divider:SetPoint("TOPLEFT", s.box.bg, "TOPLEFT", 1, -HEADER)
  s.divider:SetPoint("TOPRIGHT", s.box.bg, "TOPRIGHT", -1, -HEADER)
  s.divider:SetHeight(1)
  skinned[cf] = s
  ApplyAlpha(cf)

  if DB.hideButtons then Park(cf.buttonFrame or _G[name .. "ButtonFrame"]) end
  local rb = cf.ResizeButton or _G[name .. "ResizeButton"]
  if rb and rb.SetAlpha then rb:SetAlpha(0.35) end

  SkinScrollBar(cf)
  SkinTab(_G[name .. "Tab"])
  FixTabAlpha(cf)
  SkinEditBox(cf.editBox or _G[name .. "EditBox"], cf)
end

local function SkinAll()
  for _, frameName in ipairs(CHAT_FRAMES or {}) do SkinFrame(_G[frameName]) end
  for i = 1, (NUM_CHAT_WINDOWS or 10) do SkinFrame(_G["ChatFrame" .. i]) end
end

-- /qchat debug: what the client actually does with the tabs (for tuning on new clients).
function Skin.Debug(out)
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local tab = _G["ChatFrame" .. i .. "Tab"]
    if tab and tab:IsShown() then
      local fs = tab:GetFontString()
      local r, g, b, a = fs:GetTextColor()
      local p = tab:GetParent()
      out(("tab%d sel=%s alpha=%.2f eff=%.2f | text a=%.2f eff=%.2f ignore=%s rgb=%.2f,%.2f,%.2f,%.2f | parent=%s eff=%.2f | skinned=%s"):format(
        i, tostring(IsSelected(tab)), tab:GetAlpha(), tab:GetEffectiveAlpha(),
        fs:GetAlpha(), fs.GetEffectiveAlpha and fs:GetEffectiveAlpha() or -1,
        tostring(fs.IsIgnoringParentAlpha and fs:IsIgnoringParentAlpha()),
        r or -1, g or -1, b or -1, a or -1,
        p and (p:GetName() or tostring(p)) or "nil", p and p:GetEffectiveAlpha() or -1,
        tostring(skinned[tab] ~= nil)))
    end
  end
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
  if FCFTab_UpdateAlpha then hooksecurefunc("FCFTab_UpdateAlpha", FixTabAlpha) end
  -- tab widths were measured with Blizzard's smaller font; let the dock re-measure them
  if FCF_DockUpdate then FCF_DockUpdate() end
  if ChatFrameUtil and ChatFrameUtil.SetTabAlphas then
    hooksecurefunc(ChatFrameUtil, "SetTabAlphas", function(tab)
      if not settingAlphas and tab and tab.GetID and skinned[tab] then
        local over, idle = TabAlphas(tab)
        settingAlphas = true
        ChatFrameUtil.SetTabAlphas(tab, over, idle)
        settingAlphas = nil
      end
    end)
  end
end
