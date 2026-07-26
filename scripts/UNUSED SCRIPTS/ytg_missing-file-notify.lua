-- missing_file_osd.lua
-- Zeigt eine OSD‑Meldung, wenn eine Datei nicht gefunden werden kann.

local function on_end_file(event)
    -- Nur reagieren, wenn ein Lade‑Fehler aufgetreten ist
    if event.reason == "error" then
        -- Prüfen, ob es sich um „file not found“ handelt
        if event.error == "File not found." or event.error == "Cannot open file." then
            -- OSD‑Nachricht 3 Sekunden lang anzeigen
            mp.osd_message("⚠️", 12)
        else
            -- Optional: andere Fehlertypen ebenfalls melden
            mp.osd_message(string.format("⚠️  Diese Datei existiert nicht mehr, du Stinker. Der Pfad hat sich geändert, oder du hast die NAS nicht gemounted. %s", event.error), 12)
        end
    end
end

mp.register_event("end-file", on_end_file)
