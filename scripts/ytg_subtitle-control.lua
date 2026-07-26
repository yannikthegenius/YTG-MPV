-- Font-Liste
local fonts = {"Adwaita Mono", "Arial", "DejaVu Serif", "Futura BT Pro Medium", "Futura BT Pro Heavy", "Futura BT Pro Light", "Roboto Regular", "Roboto Bold", "Roboto Light"}
local current_font = 9

-- Farb-Liste (BBGGRR wie von libass erwartet)
local colors = {
  "FFFFFF",  -- Weiß
  "FFFF00",  -- Gelb
  "00FFFF",  -- Cyan
  "FF4D4D",  -- Rot
  "00FF00",  -- Grün
  "99FF99",  -- Pastell
  "9B7FFF",  -- Lila
  "A0A0A0",  -- Grau
  "FB8C00"   -- Orange
}

local color_names = {
  "Weiß", "Gelb", "Cyan", "Rot", "Grün", "Pastell", "Lila", "Grau", "Orange"
}

local current_color = 1

-- Outline-Stufen
local outline_sizes = {0, 1.5, 2, 3, 5.0}
local current_outline_idx = 2

-- Sub-Scale
local subtitle_scale = 1.0

-- Idle-Timer (verwendet add_timeout statt periodischer Timer)
local idle_timer = nil
local IDLE_TIMEOUT = 3

-- Helper
local function next_index(current, max)
    if current >= max then return 1 else return current + 1 end
end

local function prev_index(current, max)
    if current <= 1 then return max else return current - 1 end
end

-- Zeige Idle-Nachricht nach 3 Sekunden ohne Eingabe
local function show_idle_message()
    mp.osd_message("Oh, gute Wahl.", 3)
end

-- Reset: Löscht alten Timer und erstellt neuen für 3 Sekunden
local function reset_idle()
    if idle_timer then
        idle_timer:kill()
    end
    idle_timer = mp.add_timeout(IDLE_TIMEOUT, show_idle_message)
    idle_timer.repeatable = false
end

-- Factory: Wraps jede Action mit reset_idle()
local function make_binding(callback)
    return function()
        reset_idle()
        callback()
    end
end

-- Reset-Funktion: Setzt alle Einstellungen auf Standardwerte
local function reset_to_defaults()
    current_font = 9
    mp.set_property("sub-font", fonts[current_font])

    current_color = 1
    mp.set_property("sub-color", "#" .. colors[current_color])

    current_outline_idx = 2
    local outline_size = outline_sizes[current_outline_idx]
    mp.set_property_number("sub-outline-size", outline_size)

    subtitle_scale = 1.0
    mp.set_property_number("sub-scale", subtitle_scale)

    mp.osd_message("🛈 Alle Font-Einstellungen wurden zurückgesetzt, du Stinker.", 2)
end

mp.add_key_binding("F1", "switch_font_next", make_binding(function()
    current_font = next_index(current_font, #fonts)
    mp.set_property("sub-font", fonts[current_font])
    mp.osd_message(string.format("Subtitle Font %d/%d: %s", current_font, #fonts, fonts[current_font]), 2)
end))

mp.add_key_binding("Shift+F1", "switch_font_prev", make_binding(function()
    current_font = prev_index(current_font, #fonts)
    mp.set_property("sub-font", fonts[current_font])
    mp.osd_message(string.format("Font %d/%d: %s", current_font, #fonts, fonts[current_font]), 2)
end))

mp.add_key_binding("F2", "switch_color", make_binding(function()
    current_color = next_index(current_color, #colors)
    mp.set_property("sub-color", "#" .. colors[current_color])
    mp.osd_message(string.format("Subtitle Color %d/%d: %s", current_color, #colors, color_names[current_color]), 2)
end))

mp.add_key_binding("Shift+F2", "switch_color_prev", make_binding(function()
    current_color = prev_index(current_color, #colors)
    mp.set_property("sub-color", "#" .. colors[current_color])
    mp.osd_message(string.format("Farbe %d/%d: %s", current_color, #colors, color_names[current_color]), 2)
end))

mp.add_key_binding("F3", "increase_outline", make_binding(function()
    current_outline_idx = next_index(current_outline_idx, #outline_sizes)
    local size = outline_sizes[current_outline_idx]
    mp.set_property_number("sub-outline-size", size)
    if size == 0 then
        mp.osd_message("Subtitle Outline: Aus", 2)
    else
        mp.osd_message("Subtitle Outline: " .. string.format("%.1f", size), 2)
    end
end))

mp.add_key_binding("Shift+F3", "decrease_outline", make_binding(function()
    current_outline_idx = prev_index(current_outline_idx, #outline_sizes)
    local size = outline_sizes[current_outline_idx]
    mp.set_property_number("sub-outline-size", size)
    if size == 0 then
        mp.osd_message("Subtitle Outline: Aus", 2)
    else
        mp.osd_message("Subtitle Outline: " .. string.format("%.1f", size), 2)
    end
end))

mp.add_key_binding("F4", "font_size_info", make_binding(function()
    mp.osd_message("Du möchtest die Subtitle Font Size ändern, du Stinker?\nSHIFT+F & SHIFT+G.", 3)
end))

mp.add_key_binding("Shift+F", "increase_font_size", make_binding(function()
    subtitle_scale = math.min(2.0, subtitle_scale + 0.1)
    mp.set_property_number("sub-scale", subtitle_scale)
    mp.osd_message(string.format("Sub Scale: %.2f", subtitle_scale), 2)
end))

mp.add_key_binding("Shift+G", "decrease_font_size", make_binding(function()
    subtitle_scale = math.max(0.5, subtitle_scale - 0.1)
    mp.set_property_number("sub-scale", subtitle_scale)
    mp.osd_message(string.format("Sub Scale: %.2f", subtitle_scale), 2)
end))

mp.add_forced_key_binding("F8", "reset_to_defaults", make_binding(reset_to_defaults))