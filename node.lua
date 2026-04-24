-- node.lua – DIAGNOSTIK: bara en röd skärm, inga resurser
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

function node.render()
    gl.clear(1, 0, 0, 1)  -- helt röd skärm
end

