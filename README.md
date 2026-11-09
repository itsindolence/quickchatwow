# QuickChat

Чистый, плоский и современный вид стандартных окон чата WoW. Только внешний вид: аддон не читает,
не фильтрует и не меняет сообщения чата, поэтому не мешает «секретным» значениям Midnight и
защищённым слэш-командам.

Работает отдельно, без каких-либо наборов аддонов. Хорошо сочетается с панелью каналов QuickChannels.

## Что меняется
- Тёмный полупрозрачный фон окна с тонкой рамкой вместо стандартной рамки, фон не мерцает при наведении.
- Вкладки без «пузырей»: выбранная вкладка подсвечена белым текстом и сиреневой линией, новые сообщения
  на неактивной вкладке мигают линией.
- Строка ввода: плоское поле с цветной полоской слева в цвет текущего канала (сказать, группа, гильдия…).
- Боковые кнопки чата (меню, каналы, друзья, голосовой чат) скрыты (можно вернуть в настройках).
- Тонкая плоская полоса прокрутки без стрелок.
- В строке ввода стрелки ↑/↓ листают ваши последние 50 отправленных сообщений без зажатого Alt; история
  сохраняется между сессиями (только ваши сообщения, в `QuickChatDB`). Работает и с выключенным оформлением,
  отключается в настройках.

## Установка
**WoW Forever:** `World of Warcraft\_forever_\Interface\AddOns\QuickChat\`. После установки нового
аддона перезапустите игру полностью (не `/reload`).

Другие версии игры: `_classic_era_`, `_classic_`, `_anniversary_`, `_retail_` — та же папка `Interface\AddOns`.

## Настройки
**Esc → Настройки → Модификации → QuickChat** или команда `/qchat`:

| Команда | Что делает |
|---|---|
| `/qchat` | открыть настройки |
| `/qchat on` / `off` | включить / выключить оформление (выключение — после перезагрузки UI) |
| `/qchat alpha 0-100` | прозрачность фона чата |
| `/qchat buttons` | скрыть / показать боковые кнопки (после перезагрузки UI) |
| `/qchat arrows` | стрелки листают историю сообщений без Alt / вернуть как было |
| `/qchat status` | текущие настройки |

## Языки
Тексты настроек выбираются по языку клиента: английский и русский, остальные языки — английский.
Исправления и переводы приветствуются.

## Лицензия
MIT, см. [LICENSE](LICENSE).

---

# QuickChat (English)

A clean, flat, modern look for the default chat windows. Visual only: it never reads, filters or rewrites
chat messages. Standalone, no addon suite needed.

- Dark translucent background with a 1px border, no hover flicker.
- Flat tabs with an accent underline on the selected tab; new-message alerts pulse as a thin line.
- Flat input line with a channel-coloured accent bar.
- Chat side buttons hidden (optional).
- Thin flat scroll bar.
- Up/Down in the input line browse your last 50 sent messages without holding Alt, kept between sessions (optional).

Settings: **Options → AddOns → QuickChat** or `/qchat` (`on`, `off`, `alpha <0-100>`, `buttons`, `arrows`, `status`).
