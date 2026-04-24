gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font       = resource.load_font("font.ttf")
local background = resource.load_image("background.jpg")

local ticker_speed = 200
local ticker_text  = "J26 Signage"
local ticker_x     = NATIVE_WIDTH
local ticker_h     = 70
local st           = util.screen_transform(0)
local vw           = NATIVE_WIDTH
local vh           = NATIVE_HEIGHT

util.json_watch("config.json", function(config)
    ticker_speed = config.ticker_speed or 200
    local rot = config.rotation or 0
    st = util.screen_transform(rot)
    if rot == 90 then
        vw = NATIVE_HEIGHT
        vh = NATIVE_WIDTH
    elseif rot == 270 then
        vw = NATIVE_WIDTH
        vh = NATIVE_HEIGHT
    else
        vw = NATIVE_WIDTH
        vh = NATIVE_HEIGHT
    end
    if config.ticker_text and config.ticker_text ~= "" then
        ticker_text = config.ticker_text
    end
end)

util.file_watch("ticker.txt", function(content)
    -- Används som fallback om ticker_text ej är satt i settings
    local trimmed = content:gsub("%s+$", ""):gsub("\n", "   |   ")
    if trimmed ~= "" then ticker_text = trimmed end
end)

local last_time = sys.now()

function node.render()
    local now = sys.now()
    local dt  = now - last_time
    last_time = now

    -- Bakgrund
    gl.clear(0, 0, 0, 1)
    st()
    background:draw(0, 0, vw, vh)

    -- Flytta tickern
    ticker_x = ticker_x - ticker_speed * dt
    local text_w = font:width(ticker_text, ticker_h)
    if ticker_x < -text_w then
        ticker_x = vw
    end

    -- Ritad tickertext (vit) längst ner
    font:write(ticker_x, vh - ticker_h - 10, ticker_text, ticker_h, 1, 1, 1, 1)
end
