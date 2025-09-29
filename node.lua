gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local util = require "util"
local images = {}
local current_index = 1
local last_switch = sys.now()
local interval = 5

-- Titta på node.json för att ladda inställningar
util.json_watch("node.json", function(config)
    interval = config.interval or 5
    print("Uppdaterat intervall:", interval)
end)

-- Ladda alla bilder från /images-mappen
local function load_images()
    local files = sys.ls("images")
    table.sort(files)
    images = {}
    for _, file in ipairs(files) do
        if file:match("%.png$") or file:match("%.jpg$") then
            table.insert(images, resource.load_image("images/" .. file))
        end
    end
    print("Laddade bilder:", #images)
end

-- Kör vid start
load_images()

-- Hot reload: återladda bilder om någon ändras
node.event("file_updated", function(filename)
    if filename:match("^images/") then
        print("Bild uppdaterad:", filename)
        load_images()
    end
end)

function node.render()
    if #images == 0 then return end

    if sys.now() - last_switch > interval then
        current_index = current_index % #images + 1
        last_switch = sys.now()
    end

    local img = images[current_index]
    if img then
        img:draw(0, 0, WIDTH, HEIGHT)
    end
end
