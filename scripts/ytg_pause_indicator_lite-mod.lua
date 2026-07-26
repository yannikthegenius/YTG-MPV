--[[

   A simple script that shows a pause indicator, on pause
   https://github.com/Samillion/ModernZ/tree/main/extras/pause-indicator-lite
   https://github.com/Keith94/ModernZ/blob/pause-indicator-animated/extras/pause-indicator-lite/pause_indicator_lite.lua

--]]

local options = {
    -- indicator icon type
    indicator_icon = "pause",             -- indicator icon type. "pause", "play"
    indicator_stay = false,                -- keep indicator visibile during pause
    indicator_timeout = 0.7,              -- timeout (seconds) if indicator doesn't stay
    indicator_pos = "middle_center",      -- position of indicator. top_left, top_right, top_center
                                          -- also: middle_*, bottom_* same as top_* (ie: bottom_right)
    -- keybind
    keybind_allow = false,                -- allow keybind to toggle pause
    keybind_set = "ctrl+mbtn_left",       -- the used keybind to toggle pause
    keybind_mode = "onpause",             -- mode to activate keybind. "onpause", "always"
    keybind_eof_disable = true,           -- disable keybind on eof (end of file)

    -- icon colors & opacity
    icon_color = "#FF883D",               -- icon fill color
    icon_border_color = "#111111",        -- icon border color
    icon_border_width = 1.5,              -- icon border width
    icon_opacity = 100,                    -- icon opacity (0-100)

    -- pause icon
    rectangles_width = 20,                -- width of rectangles
    rectangles_height = 60,               -- height of rectangles
    rectangles_spacing = 12,              -- spacing between the two rectangles

    -- play icon
    triangle_width = 60,                  -- width of triangle
    triangle_height = 60,                 -- height of triangle

    -- best with pause icon
    flash_play_icon = true,               -- flash play icon on unpause
    flash_icon_timeout = 0.7,             -- timeout (seconds) for flash icon

    -- icon style used in ModernZ osc
    icon_theme = "fluent",                -- set icon theme. accepts "fluent" or "material"
    theme_style = "filled",              -- set theme style. accepts "outline" or "filled"
    themed_icons = false,                 -- requires fonts/modernz-icons.ttf
    themed_icon_size = 80,                -- themed icon size

    -- animation options
    anim_enabled = true,                  -- enable fade/scale animations
    anim_in_duration = 0.15,              -- fade/scale-in duration (seconds)
    anim_out_duration = 0.15,             -- fade-out duration (seconds)
    anim_scale_from = 70,                 -- starting scale % for the scale-in

    -- circle background (behind pause/play icon)
    circle_enabled = true,               -- show a circle behind the icon
    circle_radius = 60,                  -- radius of the circle
    circle_color = "#111111",            -- circle fill color

    -- mute options
    mute_indicator = false,               -- show a mute indicator
    mute_indicator_pos = "middle_left",     -- position of mute indicator. top_left, top_right, top_center
                                          -- also: middle_*, bottom_* same as top_* (ie: bottom_right)

    mute_icon_size = 40,                  -- size of the mute speaker icon
}

local msg = require "mp.msg"
local assdraw = require "mp.assdraw"
require 'mp.options'.read_options(options, "pause_indicator_lite")

local state = {
    indicator_overlay = mp.create_osd_overlay("ass-events"),
    flash_overlay = mp.create_osd_overlay("ass-events"),
    mute_overlay = mp.create_osd_overlay("ass-events"),
    virt_w = 0,
    indicator_visible = false,
    mute_visible = false,
    paused = false,
    toggled = false,
    eof = false,
    keybinds_registered = false,
}

local icon_theme = {
    fluent = {
        filled = {
            pause_icon = "fluent_pause_filled",
            play_icon  = "fluent_play_arrow_filled",
            mute_icon  = "fluent_no_sound_filled"
        },
        outline = {
            pause_icon = "fluent_pause",
            play_icon  = "fluent_play_arrow",
            mute_icon  = "fluent_no_sound"
        }
    },
    material = {
        filled = {
            pause_icon = "material_pause_filled",
            play_icon  = "material_play_arrow_filled",
            mute_icon  = "material_volume_off_filled"
        },
        outline = {
            pause_icon = "material_pause",
            play_icon  = "material_play_arrow",
            mute_icon  = "material_volume_off"
        }
    },
    font = "modernz-icons"
}

-- convert color from hex (adjusted from mpv/osc.lua)
local function convert_color(color)
    if color:find("^#%x%x%x%x%x%x$") == nil then
        msg.warn("'" .. color .. "' is not a valid color, using default '#FFFFFF'")
        return "FFFFFF"  -- color fallback
    end
    return color:sub(6,7) .. color:sub(4,5) .. color:sub(2,3)
end

-- convert percentage opacity (0-100) to ASS alpha values
local function convert_opacity(value)
    value = math.max(0, math.min(100, value))
    return string.format("%02X", math.floor(255 - (value * 2.55)))
end

local icon_style = {
    color = convert_color(options.icon_color),
    border_color = convert_color(options.icon_border_color),
    opacity = convert_opacity(options.icon_opacity),
    theme = icon_theme[options.icon_theme] and icon_theme[options.icon_theme][options.theme_style] or icon_theme["fluent"]["outline"],
    font = icon_theme.font,
}

local VIRT_H = 720  -- fixed virtual ASS coordinate height (mpv overlay default)

-- lock overlay canvas to virtual coordinate system so slot_center coords are accurate
for _, ov in ipairs({state.indicator_overlay, state.flash_overlay, state.mute_overlay}) do
    ov.res_y = VIRT_H
end

-- {xi, yi}: xi 1=left 2=center 3=right, yi 1=bottom 2=middle 3=top
local pos_slots = {
    top_left    = {1, 3}, top_center    = {2, 3}, top_right    = {3, 3},
    middle_left = {1, 2}, middle_center = {2, 2}, middle_right = {3, 2},
    bottom_left = {1, 1}, bottom_center = {2, 1}, bottom_right = {3, 1},
}
state.indicator_pos = pos_slots[(options.indicator_pos or ""):lower()] or pos_slots["middle_center"]
state.mute_pos      = pos_slots[(options.mute_indicator_pos or ""):lower()] or pos_slots["top_right"]

-- prevent duplicate positions
if state.indicator_pos == state.mute_pos then
    state.mute_pos = pos_slots["top_left"]
end

local function slot_center(slot, margin)
    margin = margin or (options.circle_enabled and (options.circle_radius + 10) or 40)
    local x_vals = {margin, math.floor(state.virt_w / 2), state.virt_w - margin}
    local y_vals = {VIRT_H - margin, math.floor(VIRT_H / 2), margin}
    return x_vals[slot[1]], y_vals[slot[2]]
end

-- append a scaled circle background event to an ass object, centered at cx,cy
local function append_circle(ass, cx, cy, alpha, sc)
    local r_sc = math.floor(options.circle_radius * sc)
    local k    = r_sc * 0.5523
    ass:new_event()
    ass:append(string.format("{\\rDefault\\an7\\pos(%d,%d)\\1a&H%s&\\3a&H%s&\\bord0\\1c&H%s&}",
        cx-r_sc, cy-r_sc, alpha, alpha, convert_color(options.circle_color)))
    ass:draw_start()
    ass:move_to(r_sc, 0)
    ass:bezier_curve(r_sc+k, 0,      r_sc*2, r_sc-k,  r_sc*2, r_sc)
    ass:bezier_curve(r_sc*2, r_sc+k, r_sc+k, r_sc*2,  r_sc,   r_sc*2)
    ass:bezier_curve(r_sc-k, r_sc*2, 0,      r_sc+k,  0,      r_sc)
    ass:bezier_curve(0,      r_sc-k, r_sc-k, 0,       r_sc,   0)
    ass:draw_stop()
end

-- draw an indicator icon (themed font glyph or drawn shape) with optional circle background.
local function draw_indicator(glyph, draw_shape, sc, alpha)
    sc = sc or 1.0
    alpha = alpha or icon_style.opacity

    local cx, cy
    if options.themed_icons then
        local half_icon   = math.floor(options.themed_icon_size / 2)
        local half_circle = options.circle_enabled and options.circle_radius or 0
        cx, cy = slot_center(state.indicator_pos, math.max(half_icon, half_circle) + 10)
    else
        cx, cy = slot_center(state.indicator_pos)
    end

    local ass = assdraw.ass_new()
    ass.scale = 1
    if options.circle_enabled then append_circle(ass, cx, cy, alpha, sc) end
    ass:new_event()

    if options.themed_icons then
        ass:append(string.format([[{\\rDefault\\an5\\pos(%d,%d)\\1a&H%s&\\3a&H%s&\\bord%s\\1c&H%s&\\3c&H%s&\\fs%s\\fn%s}%s]],
            cx, cy, alpha, alpha, options.icon_border_width, icon_style.color, icon_style.border_color,
            math.floor(options.themed_icon_size * sc), icon_style.font, glyph))
    else
        draw_shape(ass, cx, cy, sc, alpha)
    end

    return ass.text
end

-- pause or play icon (type = "pause" or "play", sc = scale 0.0-1.0, alpha = ASS hex string e.g. "B2")
local function draw_icon(type, sc, alpha)
    local is_pause = (type == "pause")
    local glyph    = is_pause and icon_style.theme.pause_icon or icon_style.theme.play_icon
    local hw = is_pause and math.floor((options.rectangles_width * 2 + options.rectangles_spacing) / 2 * (sc or 1.0))
                        or  math.floor(options.triangle_width / 2 * (sc or 1.0))
    local hh = is_pause and math.floor(options.rectangles_height / 2 * (sc or 1.0))
                        or  math.floor(options.triangle_height / 2 * (sc or 1.0))
    return draw_indicator(glyph, function(ass, cx, cy, sc, alpha)
        ass:append(string.format("{\\rDefault\\an7\\pos(%d,%d)\\1a&H%s&\\3a&H%s&\\bord%s\\1c&H%s&\\3c&H%s&}",
            cx-hw, cy-hh, alpha, alpha, options.icon_border_width, icon_style.color, icon_style.border_color))
        ass:draw_start()
        if is_pause then
            local rw = math.floor(options.rectangles_width * sc)
            local sp = math.floor(options.rectangles_spacing * sc)
            ass:rect_cw(0, 0, rw, hh*2)
            ass:rect_cw(rw+sp, 0, hw*2, hh*2)
        else
            ass:move_to(0, 0)
            ass:line_to(hw*2, hh)
            ass:line_to(0, hh*2)
        end
        ass:draw_stop()
    end, sc, alpha)
end


-- mute icon
local function draw_mute(sc, alpha)
    alpha = alpha or icon_style.opacity
    local cx, cy = slot_center(state.mute_pos, math.floor(options.mute_icon_size / 2) + 15)
    if options.themed_icons then
        return string.format([[{\\rDefault\\an5\\pos(%d,%d)\\1a&H%s&\\3a&H%s&\\bord%s\\1c&H%s&\\3c&H%s&\\fs%s\\fn%s}%s]], cx, cy, alpha, alpha, options.icon_border_width, icon_style.color, icon_style.border_color, options.mute_icon_size, icon_style.font, icon_style.theme.mute_icon)
    end

    -- path drawn on a 509.47x430.82 canvas
    -- fscx/fscy are %, so (target / 509.47 * 100) scales to mute_icon_size
    local scale = math.floor(options.mute_icon_size / 509.47 * 100 + 0.5)
    local icon_w = math.floor(509.47 * scale / 100 + 0.5)
    local icon_h = math.floor(430.82 * scale / 100 + 0.5)
    local px = cx - math.floor(icon_w / 2)
    local py = cy - math.floor(icon_h / 2)

    -- from Fticons - MIT License
    -- https://github.com/Financial-Times/fticons
    local vol_mute = "{\\p1}" ..
        -- bounding box
        "m 0 0 m 509.47 430.82 " ..
        -- speaker shape
        "m 287.33 0 " .. "l 106.77 135.6 " .. "l 104.06 138.85 " .. "l 0 138.85 " ..
        "l 0 292.05 " .. "l 104.06 292.05 " .. "l 106.77 295.3 " .. "l 287.33 430.82 " ..
        "l 304.67 422.16 " .. "l 304.67 8.66 " .. "l 287.33 0 " ..
        -- X mark
        "m 487.07 305.01 " .. "l 509.47 282.6 " .. "l 442.27 215.4 " .. "l 509.47 148.2 " ..
        "l 487.07 125.8 " .. "l 419.87 193 " .. "l 352.67 125.8 " .. "l 330.27 148.2 " ..
        "l 397.47 215.4 " .. "l 330.27 282.6 " .. "l 352.67 305 " .. "l 419.87 237.8 " ..
        "l 487.07 305 " .. "{\\p0}"

    return string.format([[{\\rDefault\\an7\\pos(%d,%d)\\1a&H%s&\\3a&H%s&\\bord%s\\1c&H%s&\\3c&H%s&\\fscx%s\\fscy%s}%s]],
        px, py, alpha, alpha, options.icon_border_width,
        icon_style.color, icon_style.border_color, scale, scale, vol_mute)
end

local alpha_opaque = tonumber(convert_opacity(options.icon_opacity), 16)

local function kill_timer(key)
    if state[key] then
        state[key]:kill()
        state[key] = nil
    end
end

-- fade an overlay in or out, with optional scale-in; calls on_done when finished
local function fade(overlay, draw_fn, fade_in, scale, timer_key, on_done)
    kill_timer(timer_key)
    local a0 = fade_in and 255 or alpha_opaque
    local a1 = fade_in and alpha_opaque or 255
    local s0 = (fade_in and scale) and (options.anim_scale_from / 100) or 1.0
    local duration = fade_in and options.anim_in_duration or options.anim_out_duration
    local steps = math.max(2, math.floor(duration / 0.016))
    local step = 0
    local function tick()
        local t = step / (steps - 1)
        local a = string.format("%02X", math.floor(a0 + (a1 - a0) * t + 0.5))
        local sc = s0 + (1.0 - s0) * t
        -- pass alpha and scale directly into draw_fn — no gsub needed,
        -- guarantees circle and icon always get the exact same alpha value
        overlay.data = draw_fn(sc, a)
        overlay:update()
        step = step + 1
        if step >= steps then
            kill_timer(timer_key)
            if on_done then on_done() end
        end
    end
    tick()
    if steps > 1 then
        state[timer_key] = mp.add_periodic_timer(duration / steps, tick)
    end
end

-- show or hide an overlay immediately or via animation
local function set_overlay(overlay, draw_fn, timer_key, show, scale, on_done)
    if options.anim_enabled then
        fade(overlay, draw_fn, show, show and scale or false, timer_key, on_done)
    elseif show then
        overlay.data = draw_fn()
        overlay:update()
    else
        overlay:remove()
        if on_done then on_done() end
    end
end

local function update_indicator(force)
    if state.virt_w == 0 then return end
    if not force and state.indicator_visible then return end
    local draw_fn = (options.indicator_icon == "play") and function(sc, a) return draw_icon("play",  sc, a) end
                                                        or  function(sc, a) return draw_icon("pause", sc, a) end
    set_overlay(state.indicator_overlay, draw_fn, "anim_timer", true, true)
    state.indicator_visible = true
    if not options.indicator_stay then
        kill_timer("indicator_timer")
        state.indicator_timer = mp.add_timeout(options.indicator_timeout, function()
            set_overlay(state.indicator_overlay, draw_fn, "anim_timer", false, nil, function()
                state.indicator_overlay:remove()
                state.indicator_visible = false
            end)
        end)
    end
end

local function update_flash_icon()
    if state.virt_w == 0 or not options.flash_play_icon then return end
    kill_timer("flash_timer")
    local flash_fn = function(sc, a) return draw_icon("play", sc, a) end
    set_overlay(state.flash_overlay, flash_fn, "anim_timer", true, true)
    state.flash_timer = mp.add_timeout(options.flash_icon_timeout, function()
        set_overlay(state.flash_overlay, flash_fn, "anim_timer", false, nil,
            function() state.flash_overlay:remove() end)
    end)
end

local function update_mute_icon()
    if state.virt_w == 0 then return end
    set_overlay(state.mute_overlay, draw_mute, "mute_anim_timer", true, false)
end

local function is_video()
    local t = mp.get_property_native("current-tracks/video")
    return t ~= nil and not t.image and not t.albumart
end

local function keybind_should_enable()
    if options.keybind_eof_disable and state.eof then return false end
    return options.keybind_mode == "always" or (options.keybind_mode == "onpause" and state.paused)
end

local function setup_keybinds()
    if state.keybinds_registered then return end
    mp.set_key_bindings({
        {options.keybind_set, function()
            mp.commandv("cycle", "pause")
        end}
    }, "pause-indicator", "force")
    state.keybinds_registered = true
end

local pause_observer = function(_, paused)
    state.paused = paused
    if paused then
        update_indicator()
        state.toggled = true
        kill_timer("flash_timer")
        state.flash_overlay:remove()
        if options.keybind_allow and options.keybind_mode == "onpause" then
            if keybind_should_enable() then
                mp.enable_key_bindings("pause-indicator", "allow-vo-dragging+allow-hide-cursor")
            end
        end
    else
        kill_timer("indicator_timer")
        state.indicator_overlay:remove()
        state.indicator_visible = false
        if state.toggled then
            update_flash_icon()
            state.toggled = false
        end
        if options.keybind_allow and options.keybind_mode == "onpause" then
            mp.disable_key_bindings("pause-indicator")
        end
    end
end

local function update_virt_w()
    local w, h, aspect = mp.get_osd_size()
    state.virt_w = aspect > 0 and math.floor(VIRT_H * aspect + 0.5) or (h > 0 and math.floor(VIRT_H * (w / h) + 0.5) or 1280)
    for _, ov in ipairs({state.indicator_overlay, state.flash_overlay, state.mute_overlay}) do
        ov.res_x = state.virt_w
    end
end

local dimensions_observer = function()
    update_virt_w()
    local _, _, aspect = mp.get_osd_size()
    state.aspect = aspect
    if state.paused and not state.indicator_visible then
        update_indicator(true)
        state.toggled = true
    elseif state.indicator_visible then
        update_indicator(true)
    end
    if state.mute_visible then
        update_mute_icon()
    end
end

local mute_observer = function(_, val)
    if val then
        update_mute_icon()
        state.mute_visible = true
    elseif state.mute_visible then
        set_overlay(state.mute_overlay, draw_mute, "mute_anim_timer", false, nil, function()
            state.mute_overlay:remove()
            state.mute_visible = false
        end)
    end
end

local eof_observer = function(_, val)
    state.eof = val
    if val and options.keybind_eof_disable then
        mp.disable_key_bindings("pause-indicator")
    end
end

local function unobserve()
    mp.unobserve_property(pause_observer)
    mp.unobserve_property(dimensions_observer)
    mp.unobserve_property(mute_observer)
    mp.unobserve_property(eof_observer)
end

local function shutdown()
    kill_timer("indicator_timer")
    kill_timer("flash_timer")
    kill_timer("anim_timer")
    kill_timer("mute_anim_timer")

    state.flash_overlay:remove()
    state.indicator_overlay:remove()
    state.mute_overlay:remove()

    state.indicator_visible = false
    state.mute_visible = false
    state.toggled = false

    mp.disable_key_bindings("pause-indicator")
    unobserve()
end

mp.register_event("shutdown", shutdown)

mp.register_event("file-loaded", function()
    unobserve()
    state.indicator_overlay:remove()
    state.flash_overlay:remove()
    state.mute_overlay:remove()
    state.indicator_visible = false
    state.mute_visible = false
    if is_video() then
        update_virt_w()
        state.eof = false
        state.paused = false
        mp.observe_property("pause", "bool", pause_observer)
        mp.observe_property("osd-dimensions", "native", dimensions_observer)
        if options.mute_indicator then
            mp.observe_property("mute", "bool", mute_observer)
        end
        if options.keybind_allow then
            mp.observe_property("eof-reached", "bool", eof_observer)
            setup_keybinds()
            if keybind_should_enable() then
                mp.enable_key_bindings("pause-indicator", "allow-vo-dragging+allow-hide-cursor")
            else
                mp.disable_key_bindings("pause-indicator")
            end
        end
    else
        shutdown()
    end
end)
