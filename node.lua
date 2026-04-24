-- node.lua – minimal diagnostik
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local W = NATIVE_WIDTH
local H = NATIVE_HEIGHT

local font = resource.load_font("font.ttf")

local ticker_text = "Testar..."
local ticker_x    = W
local last_time   = sys.now()

-- Läs ticker.txt om den finns
local f = io.open("ticker.txt", "r")
if f then
    local t = f:read("*a"):match("^%s*(.-)%s*$")
    f:close()
    if t and t ~= "" then ticker_text = t end
end

function node.render()
    local now = sys.now()
    local dt  = math.max(0, now - last_time)
    last_time = now

    -- Mörkblå bakgrund
    gl.clear(0.05, 0.10, 0.25, 1)

    -- Rullande text
    local size = math.floor(H * 0.05)
    local ty   = math.floor((H - size) / 2)
    font:write(ticker_x, ty, ticker_text, size, 1, 1, 1, 1)

    ticker_x = ticker_x - 200 * dt
    if ticker_x < -(font:width(ticker_text, size) + 50) then
        ticker_x = W + 50
    end
end

