-- node.lua – STEG 2: röd bakgrund + font + rullande text
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local W = NATIVE_WIDTH
local H = NATIVE_HEIGHT

local font        = resource.load_font("font.ttf")
local ticker_text = "Testar ticker..."
local ticker_x    = W
local last_time   = sys.now()

local f = io.open("ticker.txt", "r")
if f then
    local t = f:read("*a"):match("^%s*(.-)%s*$")
    f:close()
    if t ~= "" then ticker_text = t end
end

function node.render()
    local now = sys.now()
    local dt  = math.max(0, now - last_time)
    last_time = now

    gl.clear(1, 0, 0, 1)  -- röd bakgrund (tas bort i nästa steg)

    local size = math.floor(H * 0.05)
    local ty   = math.floor((H - size) / 2)
    font:write(ticker_x, ty, ticker_text, size, 1, 1, 1, 1)

    ticker_x = ticker_x - 200 * dt
    if ticker_x < -(font:width(ticker_text, size) + 50) then
        ticker_x = W + 50
    end
end

