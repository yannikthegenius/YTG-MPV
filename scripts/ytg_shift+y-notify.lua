local msg = "🛈 Hallo, Yannik. Du hast gerade SHIFT+Y gedrückt...\nDas hier hat keine Funktion... Ich wollte dich nur darauf hinweisen..."

mp.add_key_binding("SHIFT+Y", "show-custom-text", function()
    mp.commandv("show-text", msg, 5000)
end)

