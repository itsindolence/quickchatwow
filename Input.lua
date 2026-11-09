-- QuickChat: Up/Down in the chat input line browse the messages you sent, without holding Alt.
-- The edit box keeps its own history, but on current clients it only answers to Alt+Up/Down even
-- with "alt arrow key mode" off. So QuickChat keeps a copy of exactly the lines Blizzard adds to
-- that history (AddHistoryLine, e.g. "/s hello") and walks it on plain Up/Down.
-- Only your own sent lines are stored; incoming chat is never read.
-- Works whether or not the chat restyle is enabled.

local _, ns = ...

local Input = {}
ns.Input = Input

local MAX_LINES = 50

local DB
local hooked = {}
local pos, draft      -- position while browsing (nil = not browsing) and the text typed before it

local function Lines()
  DB.history = DB.history or {}
  return DB.history
end

local function Record(_, text)
  if not DB or not DB.arrowHistory or type(text) ~= "string" or text == "" then return end
  local lines = Lines()
  if lines[#lines] ~= text then
    lines[#lines + 1] = text
    while #lines > MAX_LINES do table.remove(lines, 1) end
  end
  pos, draft = nil, nil
end

local function Show(eb, text)
  eb:SetText(text or "")
  eb:SetCursorPosition(#(text or ""))
end

local function OnArrow(eb, key)
  if not DB or not DB.arrowHistory or IsAltKeyDown() then return end
  if key ~= "UP" and key ~= "DOWN" then return end
  -- the name auto-complete list uses Up/Down too
  if AutoCompleteBox and AutoCompleteBox:IsShown() and AutoCompleteBox.parent == eb then return end
  local lines = Lines()
  if #lines == 0 then return end

  if key == "UP" then
    if not pos then
      draft = eb:GetText()
      pos = #lines
    elseif pos > 1 then
      pos = pos - 1
    else
      return
    end
    Show(eb, lines[pos])
  elseif pos then
    if pos < #lines then
      pos = pos + 1
      Show(eb, lines[pos])
    else
      pos = nil
      Show(eb, draft)
      draft = nil
    end
  end
end

local function ApplyTo(eb)
  if not (eb and eb.SetAltArrowKeyMode) then return end
  eb:SetAltArrowKeyMode(not DB.arrowHistory)
  if hooked[eb] then return end
  hooked[eb] = true
  if eb.AddHistoryLine then hooksecurefunc(eb, "AddHistoryLine", Record) end
  eb:HookScript("OnArrowPressed", OnArrow)
  eb:HookScript("OnEditFocusGained", function(self)
    pos, draft = nil, nil
    if DB then self:SetAltArrowKeyMode(not DB.arrowHistory) end
  end)
end

function Input.Debug(out)
  local eb = ChatFrame1EditBox
  if not eb then out("input: no ChatFrame1EditBox"); return end
  out(("input: option=%s altArrowMode=%s saved=%d hooked=%s"):format(
    tostring(DB and DB.arrowHistory), tostring(eb.GetAltArrowKeyMode and eb:GetAltArrowKeyMode()),
    DB and DB.history and #DB.history or 0, tostring(hooked[eb] == true)))
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
