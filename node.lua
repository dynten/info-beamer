-- node.lua
-- Portrait signage: bakgrundsbild + rullande ticker, roterad 90° CW
-- Fysisk skärm är liggande (landscape); innehållet roteras 90° CW i Lua
-- för att visas som stående (portrait).

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

-- Porträttmått efter rotation
local PW = NATIVE_HEIGHT  -- porträttbredd  (t.ex. 1080 vid 1920x1080-skärm)
local PH = NATIVE_WIDTH   -- portätthöjd    (t.ex. 1920 vid 1920x1080-skärm)

-- ── Resurser (laddas en gång vid start) ───────────────────────────────────
local background = resource.load_image("background.jpg")
local font       = resource.load_font("font.ttf")

-- ── Config från info-beamer hosted (config.json) ──────────────────────────
local config = { ticker_speed = 200 }
util.json_watch("config.json", function(c)
    config = c
end)

-- ── Ticker-state ──────────────────────────────────────────────────────────
local ticker_text  = "Välkommen"
local ticker_x     = PW
local last_time    = sys.now()
local last_reload  = 0

local function reload_ticker()
    local f = io.open("ticker.txt", "r")
    if f then
        local t = f:read("*a")
        f:close()
        -- Trimma radbrytningar/blanksteg
        t = t:match("^%s*(.-)%s*$") or t
        if t ~= "" then ticker_text = t end
    end
end
reload_ticker()

-- Live-uppdatering via node.event (t.ex. från en service)
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

    -- Ladda om ticker.txt var 10:e sekund
    if now - last_reload > 10 then
        reload_ticker()
        last_reload = now
    end

    -- 90° CW-rotation: landscape-skärm → porträttinnehåll
    -- Matematiskt: translate(NATIVE_WIDTH, 0) sedan rotate(90° CCW)
    -- ger: portrait(x,y) → screen(NATIVE_WIDTH - y, x)
    gl.pushMatrix()
    gl.translate(NATIVE_WIDTH, 0)
    gl.rotate(90, 0, 0, 1)

    -- Bakgrund (täcker hela portättytan)
    background:draw(0, 0, PW, PH)

    -- Ticker längst ner på skärmen
    local ticker_h = math.floor(PH * 0.05)       -- 5 % av höjden
    local size     = math.floor(ticker_h * 0.75)
    local ty       = PH - ticker_h                -- y för tickerns överkant
    local speed    = config.ticker_speed or 200

    -- Skugga för läsbarhet
    font:write(ticker_x + 2, ty + 2, ticker_text, size, 0, 0, 0, 0.75)
    -- Text
    font:write(ticker_x,     ty,     ticker_text, size, 1, 1, 1, 1)

    -- Flytta ticker åt vänster
    local tw = font:width(ticker_text, size)
    ticker_x = ticker_x - speed * dt
    if ticker_x < -(tw + 50) then
        ticker_x = PW + 50
    end

    gl.popMatrix()
end
