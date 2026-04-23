-- node.lua
-- Portrait signage package for info-beamer
gl.setup(1080, 1920)

local json = require("json")

local SCREEN_W, SCREEN_H = 1080, 1920

-- Utilities
local function file_exists(path)
    local f = io.open(path, "rb")
    if f then f:close(); return true end
    return false
end

local function safe_load_image(path)
    if not file_exists(path) then return nil end
    local ok, img = pcall(resource.load_image, path)
    if ok then return img end
    return nil
end

local function safe_load_video(path)
    if not file_exists(path) then return nil end
    local ok, vid = pcall(resource.load_video, path)
    if ok then return vid end
    return nil
end

local function read_text_file(path)
    if not file_exists(path) then return nil end
    local f = io.open(path, "r")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

-- Load font (fallback if missing)
local font = nil
if file_exists("font.ttf") then
    font = resource.load_font("font.ttf")
else
    pcall(function() font = resource.load_font("DejaVuSans.ttf") end)
end

-- Layout configuration (edit this table to change fields/zones)
local layout = {
    background = { type = "image", src = "background.jpg", color = {0,0,0,1} },
    fields = {
        { name = "top_slideshow", type = "slideshow", rect = { x=0.05, y=0.05, w=0.9, h=0.35 }, sources = {"slide1.png","slide2.png"}, interval = 8, z = 1 },
        { name = "left_text", type = "text", rect = { x=0.05, y=0.45, w=0.45, h=0.4 }, src = "info.psf", z = 2 },
        { name = "right_video", type = "video", rect = { x=0.53, y=0.45, w=0.42, h=0.4 }, src = "", z = 2 }
    },
    overlays = {
        { name = "ticker", type = "ticker", position = "bottom", height = 0.06, speed = 200, z = 100, src = "ticker.txt" }
    }
}

-- State
local state = { fields = {}, overlays = {}, last_time = sys.now() }

-- Preload field resources
for _, cfg in ipairs(layout.fields) do
    local s = { _config = cfg }
    if cfg.type == "image" then
        s.image = safe_load_image(cfg.src)
    elseif cfg.type == "slideshow" then
        s.images = {}
        for _, p in ipairs(cfg.sources or {}) do
            local img = safe_load_image(p)
            if img then table.insert(s.images, img) end
        end
        s.idx = 1
        s.last_switch = sys.now()
    elseif cfg.type == "video" then
        s.video = safe_load_video(cfg.src)
        if s.video and s.video.play then pcall(s.video.play, s.video) end
    elseif cfg.type == "text" then
        s.text = read_text_file(cfg.src) or ""
        s.last_read = sys.now()
    end
    state.fields[cfg.name] = s
end

-- Preload overlays
for _, cfg in ipairs(layout.overlays) do
    local s = { _config = cfg }
    if cfg.type == "ticker" then
        s.text = read_text_file(cfg.src) or "Välkommen"
        s.x = SCREEN_W
        s.speed = cfg.speed or 150
        s.height = cfg.height or 0.06
    end
    state.overlays[cfg.name] = s
end

-- Helpers
local function rect_px(rect)
    local x = math.floor(rect.x * SCREEN_W + 0.5)
    local y = math.floor(rect.y * SCREEN_H + 0.5)
    local w = math.floor(rect.w * SCREEN_W + 0.5)
    local h = math.floor(rect.h * SCREEN_H + 0.5)
    return x, y, w, h
end

local function draw_text_in_rect(fstate, rect)
    local x,y,w,h = rect_px(rect)
    local txt = fstate.text or ""
    if not font then return end
    local size = math.max(12, math.floor(h * 0.08))
    local lines = {}
    for line in txt:gmatch("[^\r\n]+") do table.insert(lines, line) end
    local line_h = size * 1.15
    local start_y = y + h - line_h
    for i, line in ipairs(lines) do
        local yy = start_y - (i-1) * line_h
        if yy < y then break end
        font:write(x + 5, yy, line, size, 1,1,1,1)
    end
end

local function draw_field(f)
    local cfg = f._config
    local rect = cfg.rect
    if cfg.type == "image" then
        if f.image then
            local x,y,w,h = rect_px(rect)
            f.image:draw(x, y, x+w, y+h)
        end
    elseif cfg.type == "slideshow" then
        local img = f.images and f.images[f.idx]
        if img then
            local x,y,w,h = rect_px(rect)
            img:draw(x, y, x+w, y+h)
        end
    elseif cfg.type == "video" then
        if f.video then
            local x,y,w,h = rect_px(rect)
            f.video:draw(x, y, x+w, y+h)
        end
    elseif cfg.type == "text" then
        draw_text_in_rect(f, rect)
    end
end

local function draw_ticker(s)
    if not font then return end
    local cfg = s._config
    local height_px = math.floor((s.height or 0.06) * SCREEN_H + 0.5)
    local y = 0
    if cfg.position == "top" then
        y = SCREEN_H - height_px - 10
    else
        y = 10
    end
    local size = math.floor(height_px * 0.6)
    local text = s.text or ""
    font:write(s.x, y + (height_px - size)/2, text, size, 1,1,1,1)
end

-- External data updates (e.g. via node.event)
node.event("data", function(data)
    if type(data) == "string" then
        local t = state.overlays["ticker"]
        if t then
            t.text = data
            t.x = SCREEN_W
        end
    end
end)

function node.render()
    local now = sys.now()
    local dt = now - state.last_time
    if dt <= 0 then dt = 0 end
    state.last_time = now

    -- Background
    local bgimg = nil
    if layout.background and layout.background.src and file_exists(layout.background.src) then
        bgimg = safe_load_image(layout.background.src)
    end
    if bgimg then
        bgimg:draw(0, 0, SCREEN_W, SCREEN_H)
    else
        local c = layout.background.color or {0,0,0,1}
        gl.clear(c[1], c[2], c[3], c[4] or 1)
    end

    -- Update fields (slideshows and text reload)
    for name, f in pairs(state.fields) do
        local cfg = f._config
        if cfg.type == "slideshow" and f.images and #f.images > 1 then
            if now - f.last_switch >= (cfg.interval or 8) then
                f.idx = (f.idx % #f.images) + 1
                f.last_switch = now
            end
        elseif cfg.type == "text" then
            if now - (f.last_read or 0) > 10 then
                f.text = read_text_file(cfg.src) or f.text
                f.last_read = now
            end
        end
    end

    -- Draw fields ordered by z
    local drawlist = {}
    for _, cfg in ipairs(layout.fields) do table.insert(drawlist, cfg) end
    table.sort(drawlist, function(a,b) return (a.z or 0) < (b.z or 0) end)
    for _, cfg in ipairs(drawlist) do
        local f = state.fields[cfg.name]
        if f then draw_field(f) end
    end

    -- Update overlays (ticker x position)
    for _, o in pairs(state.overlays) do
        if o._config.type == "ticker" then
            local size = math.floor((o.height or 0.06) * SCREEN_H * 0.6 + 0.5)
            local tw = font and font:width(o.text or "", size) or 0
            o.x = o.x - (o.speed or 150) * dt
            if o.x < -tw - 50 then o.x = SCREEN_W + 50 end
        end
    end

    -- Draw overlays by z
    local olist = {}
    for _, cfg in ipairs(layout.overlays) do table.insert(olist, cfg) end
    table.sort(olist, function(a,b) return (a.z or 0) < (b.z or 0) end)
    for _, cfg in ipairs(olist) do
        local o = state.overlays[cfg.name]
        if o and cfg.type == "ticker" then
            if font then
                -- shadow for readability
                font:write(o.x+2, (cfg.position=="top") and (SCREEN_H - math.floor(cfg.height*SCREEN_H) - 8) or 12, o.text or "", math.floor(cfg.height*SCREEN_H*0.6), 0,0,0,0.7)
            end
            draw_ticker(o)
        end
    end
end
