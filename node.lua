-- node.lua
-- Bakgrundsbild + rullande ticker
-- Rotation hanteras via info-beamer device-inställningar (Dashboard → Device → Rotation)
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local W = NATIVE_WIDTH
local H = NATIVE_HEIGHT

-- ── Resurser (laddas en gång vid start) ──────────────────────────────────
local background = nil
pcall(function() background = resource.load_image("background.jpg") end)

local font = nil
pcall(function() font = resource.load_font("font.ttf") end)

-- ── Config från info-beamer hosted ────────────────────────────────────────
local config = { ticker_speed = 200 }
util.json_watch("config.json", function(c)
    config = c
end)

-- ── Ticker ────────────────────────────────────────────────────────────────
local ticker_text = "Välkommen"
local ticker_x    = W
local last_time   = sys.now()
local last_reload = 0

local function reload_ticker()
    local f = io.open("ticker.txt", "r")
    if f then
        local t = f:read("*a")
        f:close()
        t = t:match("^%s*(.-)%s*$") or t
        if t ~= "" then ticker_text = t end
    end
end
reload_ticker()

node.event("data", function(data)
    if type(data) == "string" and data ~= "" then
        ticker_text = data
        ticker_x    = W
    end
end)

-- ── Render ────────────────────────────────────────────────────────────────
function node.render()
    local now = sys.now()
    local dt  = math.max(0, now - last_time)
    last_time = now

    -- Ladda om ticker.txt var 10:e sekund
    if now - last_reload > 10 then
        reload_ticker()
        last_reload = now
    end

    -- Bakgrund (mörkblå fallback om background.jpg saknas)
    if background then
        background:draw(0, 0, W, H)
    else
        gl.clear(0.05, 0.05, 0.2, 1)
    end

    -- Rullande ticker längst ner
    if font then
        local size  = math.max(20, math.floor(H * 0.04))
        local ty    = H - math.floor(size * 1.8)
        local speed = config.ticker_speed or 200

        -- Skugga + vit text
        font:write(ticker_x + 2, ty + 2, ticker_text, size, 0, 0, 0, 0.8)
        font:write(ticker_x,     ty,     ticker_text, size, 1, 1, 1, 1)

        local tw = font:width(ticker_text, size)
        ticker_x = ticker_x - speed * dt
        if ticker_x < -(tw + 50) then
            ticker_x = W + 50
        end
    end
end

