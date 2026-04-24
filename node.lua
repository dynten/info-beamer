gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font       = resource.load_font("font.ttf")
local background = resource.load_image("background.jpg")

local ticker_speed = 200
local ticker_text  = "J26 Signage"
local ticker_x     = NATIVE_WIDTH
local ticker_h     = 70

util.json_watch("config.json", function(config)
    ticker_speed = config.ticker_speed or 200
end)

util.file_watch("ticker.txt", function(content)
    ticker_text = content:gsub("%s+$", ""):gsub("\n", "   |   ")
end)

local last_time = sys.now()

function node.render()
    local now = sys.now()
    local dt  = now - last_time
    last_time = now

    -- Bakgrund
    gl.clear(0, 0, 0, 1)
    background:draw(0, 0, NATIVE_WIDTH, NATIVE_HEIGHT)

    -- Flytta tickern
    ticker_x = ticker_x - ticker_speed * dt
    local text_w = font:width(ticker_text, ticker_h)
    if ticker_x < -text_w then
        ticker_x = NATIVE_WIDTH
    end

    -- Ritad tickertext (vit) längst ner
    font:write(ticker_x, NATIVE_HEIGHT - ticker_h - 10, ticker_text, ticker_h, 1, 1, 1, 1)
end
