-- node.lua
-- Portrait signage: bakgrundsbild + rullande ticker, roterad 90° CW
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

-- Porträttmått efter rotation (landscape-skärm körs roterad 90°)
local PW = NATIVE_HEIGHT  -- t.ex. 1080 på en 1920×1080-skärm
local PH = NATIVE_WIDTH   -- t.ex. 1920

-- ── Resurser ──────────────────────────────────────────────────────────────
local ok_bg,   background = pcall(resource.load_image, "background.jpg")
local ok_font, font       = pcall(resource.load_font,  "font.ttf")
if not ok_bg   then background = nil end
if not ok_font then font       = nil end

-- ── Config (uppdateras via config.json när användaren ändrar inställningar) 
local config = { ticker_speed = 200 }
util.json_watch("config.json", function(c)
    config = c
end)

-- ── Ticker-state ──────────────────────────────────────────────────────────
local ticker_text = "Välkommen"
local ticker_x    = PW
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
        ticker_x    = PW
    end
end)

-- ── Render ────────────────────────────────────────────────────────────────
function node.render()
    local now = sys.now()
    local dt  = math.max(0, now - last_time)
    last_time = now

    -- Ladda om ticker var 10:e sekund
    if now - last_reload > 10 then
        reload_ticker()
        last_reload = now
    end

    -- Alltid rensa skärmen svart som fallback
    gl.clear(0, 0, 0, 1)

    -- 90° CW-rotation: portrait-koordinater ritas på landscape-skärm
    util.screen_transform(90)

    -- Bakgrund
    if background then
        background:draw(0, 0, PW, PH)
    end

    -- Ticker längst ner
    if font then
        local ticker_h = math.floor(PH * 0.05)
        local size     = math.floor(ticker_h * 0.75)
        local ty       = PH - ticker_h
        local speed    = config.ticker_speed or 200

        -- Skugga + text
        font:write(ticker_x + 2, ty + 2, ticker_text, size, 0, 0, 0, 0.75)
        font:write(ticker_x,     ty,     ticker_text, size, 1, 1, 1, 1)

        local tw = font:width(ticker_text, size)
        ticker_x = ticker_x - speed * dt
        if ticker_x < -(tw + 50) then
            ticker_x = PW + 50
        end
    end
end
