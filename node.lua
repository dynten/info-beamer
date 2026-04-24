-- node.lua – STEG 4: isolera font-laddning
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font_ok = false
pcall(function()
    local f = resource.load_font("font.ttf")
    if f then font_ok = true end
end)

function node.render()
    if font_ok then
        gl.clear(0, 1, 0, 1)   -- GRÖN  = font.ttf laddades OK
    else
        gl.clear(1, 0.5, 0, 1) -- ORANGE = font.ttf misslyckades
    end
end

