local mp = require 'mp'
local utils = require 'mp.utils'

local messages = {
    "🛈 Gute Wahl, Stinker.",
}

local video_exts = {
    mkv=true, mp4=true, avi=true, webm=true, mov=true, flv=true,
    wmv=true, m4v=true, ts=true, mpg=true, mpeg=true, ogv=true
}

local function norm(p)
    -- mpv-normalisierter Pfad, falls die Datei lesbar ist
    local full = utils.join_path(".", p)
    local info = utils.file_info(full)
    if info and info.is_dir == false then
        return mp.get_property("working-directory") .. "/" .. full
    end
    return full
end

local function clipboard_load()
    local text = mp.get_property("clipboard/text")
    if not text or text == "" then
        mp.osd_message("🛈 Im Clipboard ist keine File, Stinker.")
        return
    end
    text = text:gsub("[\r\n]+$", ""):gsub("^%s+", ""):gsub("%s+$", "")

    local dir = select(1, utils.split_path(text))
    local idle = mp.get_property_bool("idle-active")
    local count = mp.get_property_number("playlist-count", 0)

    if idle or count == 0 then
        mp.commandv("loadfile", text, "replace")
        mp.osd_message(messages[math.random(#messages)], 2)
        return
    end

    -- eingefügte Datei zuerst anhängen (liegt dann bei Index = count)
    mp.commandv("loadfile", text, "append")

    -- Rest des Ordners anhängen (Duplikate überspringen)
    local existing = {}
    for i = 0, mp.get_property_number("playlist-count", 1) - 1 do
        local p = mp.get_property("playlist/" .. i .. "/filename")
        if p then existing[p] = true end
    end

    local files = utils.readdir(dir, "files") or {}
    table.sort(files)
    for _, f in ipairs(files) do
        local ext = f:match("%.(%w+)$")
        if ext and video_exts[ext:lower()] then
            local full = utils.join_path(dir, f)
            if not existing[full] then
                mp.commandv("loadfile", full, "append")
            end
        end
    end

    -- Ziel-Index suchen; Fallback: Datei steckt bei Index = count
    local target = norm(text)
    local newcount = mp.get_property_number("playlist-count", 1)
    local idx = nil
    for i = 0, newcount - 1 do
        local p = mp.get_property("playlist/" .. i .. "/filename")
        if p == text or norm(p) == target then
            idx = i
            break
        end
    end
    mp.commandv("playlist-play-index", idx or count)

    mp.osd_message(messages[math.random(#messages)], 2)
end

mp.add_key_binding("ctrl+v", "clipboard-load", clipboard_load)
