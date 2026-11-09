-- QuickChat: plain arrow keys in the chat input line.
-- The edit box already keeps a history of the last 32 sent lines, but Blizzard sets it to
-- "alt arrow key mode", so browsing needs Alt+Up/Down. This turns that off (or back on).
-- Works whether or not the chat restyle is enabled.

local _, ns = ...

local Input = {}
ns.Input = Input

local DB
local hooked = {}

local function ApplyTo(eb)
  if not (eb and eb.SetAltArrowKeyMode) then return end
  eb:SetAltArrowKeyMode(not DB.arrowHistory)
  -- re-assert on every focus, in case something switched the mode back while the box was closed
  if not hooked[eb] then
    hooked[eb] = true
    eb:HookScript("OnEditFocusGained", function(self)
      if DB then self:SetAltArrowKeyMode(not DB.arrowHistory) end
    end)
  end
end

function Input.Debug(out)
  local eb = ChatFrame1EditBox
  if not eb then out("input: no ChatFrame1EditBox"); return end
  out(("input: option=%s altArrowMode=%s historyLines=%s shown=%s focus=%s"):format(
    tostring(DB and DB.arrowHistory), tostring(eb.GetAltArrowKeyMode and eb:GetAltArrowKeyMode()),
    tostring(eb.GetHistoryLines and eb:GetHistoryLines()), tostring(eb:IsShown()), tostring(eb:HasFocus())))
end

function Input.Apply(db)
  DB = db or DB
  if not DB then return end
  for _, frameName in ipairs(CHAT_FRAMES or {}) do
    local cf = _G[frameName]
    ApplyTo(cf and (cf.editBox or _G[frameName .. "EditBox"]))
  end
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    ApplyTo(_G["ChatFrame" .. i .. "EditBox"])
  end
end

function Input.Enable(db)
  DB = db
  Input.Apply()
  if Input.hooked then return end
  Input.hooked = true
  -- whisper and other temporary windows get their own edit box
  if FCF_OpenTemporaryWindow then hooksecurefunc("FCF_OpenTemporaryWindow", function() Input.Apply() end) end
  if FCF_OpenNewWindow then hooksecurefunc("FCF_OpenNewWindow", function() Input.Apply() end) end
end
