-- QuickChat: plain arrow keys in the chat input line.
-- The edit box already keeps a history of the last 32 sent lines, but Blizzard sets it to
-- "alt arrow key mode", so browsing needs Alt+Up/Down. This turns that off (or back on).
-- Works whether or not the chat restyle is enabled.

local _, ns = ...

local Input = {}
ns.Input = Input

local DB

local function ApplyTo(eb)
  if eb and eb.SetAltArrowKeyMode then
    eb:SetAltArrowKeyMode(not DB.arrowHistory)
  end
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
