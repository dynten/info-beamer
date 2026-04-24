-- node.lua -- STEG 5: isolera bildladdning
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
local font = resource.load_font("font.ttf")
local img_ok = false
pcall(function()
    local img = resource.load_image("background.jpg")
    if img then img_ok = true end
end)

function node.render()
    if img_ok then
        gl.clear(0, 1, 0, 1)   -- GRON  = background.jpg laddades OK
    else
        gl.clear(1, 0.5, 0, 1) -- ORANGE = background.jpg misslyckades
    end
end
