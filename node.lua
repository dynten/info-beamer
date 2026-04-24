gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font       = resource.load_font("font.ttf")
local background = resource.load_image("background.jpg")
local ticker_bg  = resource.create_colored_texture(0, 0, 0, 0.6)

local ticker_speed = 200
local ticker_text  = "J26 Signage"
local ticker_x     = NATIVE_WIDTH
local st           = util.screen_transform(0)
local vw           = NATIVE_WIDTH
local vh           = NATIVE_HEIGHT
local grid_rows    = 1
local grid_cols    = 1

-- Initialisera grid-texter med tomma strängar
local grid_texts = {}
for r = 1, 3 do
    grid_texts[r] = {}
    for c = 1, 3 do grid_texts[r][c] = "" end
end

util.json_watch("config.json", function(config)
    ticker_speed = config.ticker_speed or 200
    local rot = config.rotation or 0
    st = util.screen_transform(rot)
    if rot == 90 or rot == 270 then
        vw = NATIVE_HEIGHT
        vh = NATIVE_WIDTH
    else
        vw = NATIVE_WIDTH
        vh = NATIVE_HEIGHT
    end
    ticker_x = vw
    grid_rows = config.grid_rows or 1
    grid_cols = config.grid_cols or 1
    for r = 1, 3 do
        for c = 1, 3 do
            local key = "text_r" .. r .. "c" .. c
            grid_texts[r][c] = config[key] or ""
        end
    end
    if config.ticker_text and config.ticker_text ~= "" then
        ticker_text = config.ticker_text
    end
end)

util.file_watch("ticker.txt", function(content)
    local trimmed = content:gsub("%s+$", ""):gsub("\n", "   |   ")
    if trimmed ~= "" then ticker_text = trimmed end
end)

local function draw_cell(text, x1, y1, x2, y2)
    if text == "" then return end
    local cw = x2 - x1
    local ch = y2 - y1
    local size = ch * 0.35
    local tw = font:width(text, size)
    while tw > cw * 0.88 and size > 8 do
        size = size * 0.92
        tw = font:width(text, size)
    end
    font:write(x1 + (cw - tw) / 2, y1 + (ch - size) / 2, text, size, 1, 1, 1, 1)
end

local last_time = sys.now()

function node.render()
    local now = sys.now()
    local dt  = now - last_time
    last_time = now

    local ticker_h   = math.floor(vh / 10)
    local content_h  = vh - ticker_h

    gl.clear(0, 0, 0, 1)
    st()

    -- Bakgrundsbild
    background:draw(0, 0, vw, vh)

    -- Rutnät med text
    local cell_w = vw / grid_cols
    local cell_h = content_h / grid_rows
    for r = 1, grid_rows do
        for c = 1, grid_cols do
            local x1 = (c - 1) * cell_w
            local y1 = (r - 1) * cell_h
            draw_cell(grid_texts[r][c], x1, y1, x1 + cell_w, y1 + cell_h)
        end
    end

    -- Ticker-bakgrund och text
    -- ticker_bg:draw(0, content_h, vw, vh)
    ticker_x = ticker_x - ticker_speed * dt
    local text_size = ticker_h * 0.7
    local text_w = font:width(ticker_text, text_size)
    if ticker_x < -text_w then ticker_x = vw end
    font:write(ticker_x, content_h + (ticker_h - text_size) / 2, ticker_text, text_size, 1, 1, 1, 1)
end
