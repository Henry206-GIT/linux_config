-- Webcam Spiegel-Toggle Button fuer mpv
-- Input: Mausklick oben links im Fenster (30x18px Bereich)
-- Output: hflip-Filter wird gesetzt oder entfernt

local flipped = true

local osd = mp.create_osd_overlay("ass-events")
osd.z = 100

-- Zeichnet den Toggle-Button oben links
-- Input: flipped bool
-- Output: OSD aktualisiert
local function draw_button()
    local label = flipped and "↔ AN" or "↔ AUS"
    osd.data =
        "{\\an7\\pos(4,4)\\bord0\\shad0\\1c&HCC000000&\\p1}m 0 0 l 48 0 48 18 0 18{\\p0}" ..
        "{\\an7\\pos(7,6)\\1c&HFFFFFF&\\fs11\\b1\\bord0.5\\shad0\\3c&H000000&}" .. label
    osd:update()
end

-- Setzt oder entfernt den hflip-Filter
-- Input: flipped bool
-- Output: mpv vf-Kommando
local function update_filter()
    if flipped then
        mp.commandv("vf", "set", "hflip")
    else
        mp.commandv("vf", "set", "")
    end
end

-- Klick-Handler: reagiert auf Mausklick im Button-Bereich
-- Input: Mausposition via mouse-pos property
-- Output: toggle falls Klick im 48x18 Bereich oben links
mp.add_forced_key_binding("MBTN_LEFT", "webcam-flip-toggle", function()
    local pos = mp.get_property_native("mouse-pos")
    if pos and pos.x <= 48 and pos.y <= 18 then
        flipped = not flipped
        update_filter()
        draw_button()
    end
end)

update_filter()
draw_button()
