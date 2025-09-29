gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local util = require "util"
local images = {}
local current_index = 1
local last_switch = sys.now()
local interval = 5

-- Ladda inställningar
util.json_watch("node.json", function(config)
    interval = config.interval or 5
end)

-- Ladda alla bilder från /images
local function load_images()
    local files = sys.ls("images")
    table.sort(files)  -- Sortera i ordning: page1.png, page2.png, ...
    images = {}
    for _, file in ipairs(files) do
        if file:match("%.png$") or file:match("%.jpg$") then
            table.insert(images, resource.load_image("images/" .. file))
        end
    end
end

-- Kör en gång vid start
load_images()

-- Övervaka images-mappen om du vill stödja hot-reload
node.event("file_updated", function(filename)
    if filename:match("^images/") then
        print("Filer ändrade, laddar om bilder")
        load_images()
    end
end)

function node.render()
    if #images == 0 then
        return
    end

    -- Byt bild efter 'interval' sekunder
    if sys.now() - last_switch > interval then
        current_index = current_index % #images + 1
        last_switch = sys.now()
    end

    -- Rita bilden centrerat
    local img = images[current_index]
    if img then
        img:draw(0, 0, WIDTH, HEIGHT)
    end
end
