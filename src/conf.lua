function love.conf(t)
    t.version = "11.0"                -- The LÖVE version this game was made for (string)

    t.window.title = "Bullets!"         -- The window title (string)
    t.window.width = 1220               -- The window width (number)
    t.window.height = 600               -- The window height (number)
    t.window.borderless = false         -- Remove all border visuals from the window (boolean)
    t.window.resizable = false          -- Let the window be user-resizable (boolean)
    t.window.vsync = 1
end