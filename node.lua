gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local screen_transform = util.screen_transform(0)

local ok, font = pcall(resource.load_font, "font.ttf")
if not ok then font = nil end

local ok, bg_fallback = pcall(resource.load_image, "background.jpg")
if not ok then bg_fallback = nil end

local backgrounds = {}
for i = 0, 2 do
    local ok, img = pcall(resource.load_image, "background_" .. i .. ".jpg")
    backgrounds[i] = ok and img or bg_fallback
end
local ticker_speed  = 200
local ticker_count  = 1
local ticker_text   = "J26 Signage"
local ticker2_text  = "J26 Signage"
local ticker_x      = NATIVE_WIDTH
local ticker2_x     = NATIVE_WIDTH / 2  -- börjar fasförskjutet
local rot_value    = 0
local vw           = NATIVE_WIDTH
local vh           = NATIVE_HEIGHT
local grid_rows    = 1
local grid_cols    = 1
local bg_color     = {0, 0, 0, 1}

local grid_texts = {}
for r = 1, 3 do
    grid_texts[r] = {}
    for c = 1, 3 do grid_texts[r][c] = "" end
end

local cell_images = {}
for r = 1, 3 do
    cell_images[r] = {}
    for c = 1, 3 do cell_images[r][c] = nil end
end

util.json_watch("config.json", function(config)
    if config.background_color then
        bg_color = config.background_color
    end

    ticker_speed = math.max(0, tonumber(config.ticker_speed) or 200)
    ticker_count = tonumber(config.ticker_count) or 1
    local rot = tonumber(config.rotation) or 0
    screen_transform = util.screen_transform(rot)
    vw = NATIVE_HEIGHT
    vh = NATIVE_HEIGHT * (1.5)
    ticker_x  = vw
    ticker2_x = math.floor(vw / 2)
    grid_rows = math.max(1, math.min(3, tonumber(config.grid_rows) or 1))
    grid_cols = math.max(1, math.min(3, tonumber(config.grid_cols) or 1))
    for r = 1, 3 do
        for c = 1, 3 do
            local key = "text_r" .. r .. "c" .. c
            grid_texts[r][c] = config[key] or ""
        end
    end
    for r = 1, 3 do
        for c = 1, 3 do
            local key = "image_r" .. r .. "c" .. c
            local asset = config[key]
            cell_images[r][c] = nil
            local filename = type(asset) == "string" and asset or (type(asset) == "table" and asset.asset_name)
            if filename and filename ~= "" and filename ~= "empty.png" then
                local ok, img = pcall(resource.load_image, filename)
                if ok then cell_images[r][c] = img end
            end
        end
    end
    if config.ticker_text and config.ticker_text ~= "" then
        ticker_text = config.ticker_text
    end
    ticker2_text = (config.ticker2_text and config.ticker2_text ~= "") and config.ticker2_text or ticker_text
end)

util.file_watch("ticker.txt", function(content)
    local trimmed = content:gsub("%s+$", ""):gsub("\n", "   |   ")
    if trimmed ~= "" then ticker_text = trimmed end
end)

local function draw_cell(text, image, x1, y1, x2, y2)
    if text == "" and image == nil then return end
    local cw = x2 - x1
    local ch = y2 - y1
    if image then
        pcall(image.draw, image, math.floor(x1 + 2), math.floor(y1 + 2), math.floor(x2 - 2), math.floor(y2 - 2))
    end
    if text ~= "" then
        local text_str = tostring(text)
        local size = ch * 0.35
        local tw = font and font:width(text_str, size) or 0
        while font and tw > cw * 0.9 and size > 10 do
            size = math.max(10, size * 0.9)
            tw = font:width(text_str, size)
        end
        local tr, tg, tb = 0.5, 0.5, 0.5
        if image then tr, tg, tb = 1, 1, 1 end
        if font then
            font:write(math.floor(x1 + (cw - tw) / 2), math.floor(y1 + (ch - size) / 2), text_str, size, tr, tg, tb, 1)
        end
    end
end

local function draw_row(row, cols, x_off, y_off, zone_w, zone_h)
    local cell_w = zone_w / cols
    for c = 1, cols do
        local x1 = x_off + (c - 1) * cell_w
        draw_cell(grid_texts[row][c], cell_images[row][c], x1, y_off, x1 + cell_w, y_off + zone_h)
    end
end

local function draw_ticker_line(tx, ty, text_size, th, txt)
    if font and text_size > 0 then
        font:write(math.floor(tx), math.floor(ty + (th - text_size) / 2), tostring(txt), text_size, 1, 1, 1, 1)
    end
end

local last_time = sys.now()

function node.render()
    local now = sys.now()
    local dt  = math.min(now - last_time, 0.05)
    last_time = now

    local r = bg_color[1] or bg_color.r or 0
    local g = bg_color[2] or bg_color.g or 0
    local b = bg_color[3] or bg_color.b or 0
    local a = bg_color[4] or bg_color.a or 1

    gl.clear(r, g, b, a)
    screen_transform()

    local t1_str = tostring(ticker_text)
    local t2_str = tostring(ticker2_text)

    local ticker_h  = math.max(10, math.floor(vh / 10))
    local text_size = ticker_h * 0.7
    local tw1       = (font and text_size > 0) and font:width(t1_str, text_size) or 0
    local tw2       = (font and text_size > 0) and font:width(t2_str, text_size) or 0

    if backgrounds[ticker_count] then
        backgrounds[ticker_count]:draw(0, 0, vw, vh)
    end

    if ticker_count == 0 then
        -- Ingen ticker – hela skärmen används för celler
        local cell_w = vw / grid_cols
        local cell_h = vh / grid_rows
        for r = 1, grid_rows do
            for c = 1, grid_cols do
                local x1 = (c - 1) * cell_w
                local y1 = (r - 1) * cell_h
                draw_cell(grid_texts[r][c], cell_images[r][c], x1, y1, x1 + cell_w, y1 + cell_h)
            end
        end

    elseif ticker_count == 1 then
        -- En ticker längst ner
        local content_h = vh - ticker_h
        local cell_w = vw / grid_cols
        local cell_h = content_h / grid_rows
        for r = 1, grid_rows do
            for c = 1, grid_cols do
                local x1 = (c - 1) * cell_w
                local y1 = (r - 1) * cell_h
                draw_cell(grid_texts[r][c], cell_images[r][c], x1, y1, x1 + cell_w, y1 + cell_h)
            end
        end
        ticker_x = ticker_x - ticker_speed * dt
        if ticker_x < -tw1 then ticker_x = vw end
        draw_ticker_line(ticker_x, content_h, text_size, ticker_h, t1_str)

    elseif ticker_count == 2 then
        -- Två tickers: en mitt på skärmen, en längst ner
        -- Rad 1 = övre sektion (topp → mellanticker)
        -- Rad 2 = nedre sektion (mellanticker → nedreticker)
        local section_h       = math.floor((vh - 2 * ticker_h) / 2)
        local mid_ticker_y    = section_h
        local bottom_start    = section_h + ticker_h
        local bottom_ticker_y = vh - ticker_h

        draw_row(1, grid_cols, 0, 0, vw, section_h)

        ticker2_x = ticker2_x - ticker_speed * dt
        if ticker2_x < -tw2 then ticker2_x = vw end
        draw_ticker_line(ticker2_x, mid_ticker_y, text_size, ticker_h, t2_str)

        draw_row(2, grid_cols, 0, bottom_start, vw, bottom_ticker_y - bottom_start)

        ticker_x = ticker_x - ticker_speed * dt
        if ticker_x < -tw1 then ticker_x = vw end
        draw_ticker_line(ticker_x, bottom_ticker_y, text_size, ticker_h, t1_str)
    end
end
