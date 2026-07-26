function open_in_file_manager()
    local path = mp.get_property("path")
    if not path then
        mp.osd_message("No file loaded")
        return
    end

    os.execute(string.format('nautilus "%s" &', path))
    -- mp.osd_message("Opened in file manager:\n" .. path)
end

mp.add_key_binding("ctrl+e", "open_in_file_manager", open_in_file_manager)
