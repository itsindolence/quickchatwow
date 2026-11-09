-- QuickChat localization.
-- Strings follow the game client language (GetLocale()); missing keys fall back to English.
-- Corrections and new languages from native speakers are welcome.

local _, ns = ...

local LOCALES = {}

LOCALES.enUS = {
  enable      = "Modern chat look",
  enableTip   = "Restyle the chat windows, tabs and input line. Turning it off needs a UI reload.",
  alpha       = "Background opacity",
  alphaTip    = "How dark the chat window background is.",
  buttons     = "Hide side buttons",
  buttonsTip  = "Hide the chat menu, channels, social and voice buttons next to the chat. Needs a UI reload to bring them back.",
  reloadText  = "QuickChat: reload the UI to apply this change?",
  reload      = "Reload",
  later       = "Later",
  on          = "on",
  off         = "off",
  status      = "chat style: %s, background %d%%, side buttons %s",
  hidden      = "hidden",
  shown       = "shown",
  help        = "commands: /qchat (settings), on, off, alpha <0-100>, buttons, status",
}

LOCALES.ruRU = {
  enable      = "Современный вид чата",
  enableTip   = "Новое оформление окон чата, вкладок и строки ввода. Для отключения нужна перезагрузка интерфейса.",
  alpha       = "Прозрачность фона",
  alphaTip    = "Насколько тёмный фон окна чата.",
  buttons     = "Скрыть боковые кнопки",
  buttonsTip  = "Скрыть кнопки меню чата, каналов, друзей и голосового чата рядом с чатом. Чтобы вернуть их, нужна перезагрузка интерфейса.",
  reloadText  = "QuickChat: перезагрузить интерфейс, чтобы применить изменение?",
  reload      = "Перезагрузить",
  later       = "Позже",
  on          = "вкл",
  off         = "выкл",
  status      = "стиль чата: %s, фон %d%%, боковые кнопки %s",
  hidden      = "скрыты",
  shown       = "видны",
  help        = "команды: /qchat (настройки), on, off, alpha <0-100>, buttons, status",
}

local en = LOCALES.enUS
local cur = LOCALES[GetLocale()] or en
if cur ~= en then setmetatable(cur, { __index = en }) end

ns.L = cur
