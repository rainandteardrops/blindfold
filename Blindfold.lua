-- Blindfold: RP blind addon with mouse peephole
-- /blind on          - enable
-- /blind off         - disable
-- /blind size <n>    - change peephole radius (default 80)

local PEEP_RADIUS = 80
local UPDATE_RATE = 0
local LERP_SPEED  = 6    -- lower = more lag/smoothing, higher = snappier

------------------------------------------------------------
-- Peephole: 4 black rects + vignette ring for soft edges
-- Uses BACKGROUND strata so LOW+ UI renders above it
------------------------------------------------------------

local rects  = {}
local active = false
local curX, curY = nil, nil  -- smoothed cursor position

local function makeRect(name)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(1)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(f)
    t:SetColorTexture(0, 0, 0, 1)
    f:Hide()
    return f
end

local function makeVignette(name)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(2)  -- just above the black rects
    f:SetSize(1, 1)
    -- Four gradient textures forming a soft ring around the hole
    -- Left fade
    local tl = f:CreateTexture(nil, "ARTWORK")
    tl:SetColorTexture(0, 0, 0, 0)
    tl:SetGradient("HORIZONTAL", CreateColor(0,0,0,1), CreateColor(0,0,0,0))
    -- Right fade
    local tr = f:CreateTexture(nil, "ARTWORK")
    tr:SetColorTexture(0, 0, 0, 0)
    tr:SetGradient("HORIZONTAL", CreateColor(0,0,0,0), CreateColor(0,0,0,1))
    -- Top fade
    local tt = f:CreateTexture(nil, "ARTWORK")
    tt:SetColorTexture(0, 0, 0, 0)
    tt:SetGradient("VERTICAL", CreateColor(0,0,0,0), CreateColor(0,0,0,1))
    -- Bottom fade
    local tb = f:CreateTexture(nil, "ARTWORK")
    tb:SetColorTexture(0, 0, 0, 0)
    tb:SetGradient("VERTICAL", CreateColor(0,0,0,1), CreateColor(0,0,0,0))

    f.tl = tl
    f.tr = tr
    f.tt = tt
    f.tb = tb
    f:Hide()
    return f
end

local runner = CreateFrame("Frame")
runner:SetScript("OnUpdate", function(self, dt)
    if not active then return end

    local mx, my = GetCursorPosition()
    local scale  = UIParent:GetEffectiveScale()
    mx = mx / scale
    my = my / scale

    -- Initialise smoothed position on first frame
    if not curX then curX, curY = mx, my end

    -- Lerp smoothed position towards real cursor
    local t = math.min(1, dt * LERP_SPEED)
    curX = curX + (mx - curX) * t
    curY = curY + (my - curY) * t

    local cx, cy = curX, curY
    local r  = PEEP_RADIUS
    local fade = r * 0.5  -- width of the soft vignette fade

    -- Hard black rects
    rects.top:ClearAllPoints()
    rects.top:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, cy + r)
    rects.top:SetPoint("TOPRIGHT",   UIParent, "TOPRIGHT",   0, 0)

    rects.bottom:ClearAllPoints()
    rects.bottom:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    rects.bottom:SetPoint("TOPRIGHT",   UIParent, "BOTTOMRIGHT", 0, cy - r)

    rects.left:ClearAllPoints()
    rects.left:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0,      cy - r)
    rects.left:SetPoint("TOPRIGHT",   UIParent, "BOTTOMLEFT", cx - r, cy + r)

    rects.right:ClearAllPoints()
    rects.right:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx + r, cy - r)
    rects.right:SetPoint("TOPRIGHT",   UIParent, "BOTTOMRIGHT", 0,     cy + r)

    -- Soft vignette fades overlapping the hole edges
    local v = rects.vignette

    -- Left fade: sits just inside the left rect edge
    v.tl:ClearAllPoints()
    v.tl:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx - r,        cy - r)
    v.tl:SetPoint("TOPRIGHT",   UIParent, "BOTTOMLEFT", cx - r + fade, cy + r)

    -- Right fade
    v.tr:ClearAllPoints()
    v.tr:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx + r - fade, cy - r)
    v.tr:SetPoint("TOPRIGHT",   UIParent, "BOTTOMLEFT", cx + r,        cy + r)

    -- Top fade
    v.tt:ClearAllPoints()
    v.tt:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx - r, cy + r - fade)
    v.tt:SetPoint("TOPRIGHT",   UIParent, "BOTTOMLEFT", cx + r, cy + r)

    -- Bottom fade
    v.tb:ClearAllPoints()
    v.tb:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx - r, cy - r)
    v.tb:SetPoint("TOPRIGHT",   UIParent, "BOTTOMLEFT", cx + r, cy - r + fade)
end)

local function enable()
    if not rects.top then
        rects.top      = makeRect("BlindfoldTop")
        rects.bottom   = makeRect("BlindfoldBottom")
        rects.left     = makeRect("BlindfoldLeft")
        rects.right    = makeRect("BlindfoldRight")
        rects.vignette = makeVignette("BlindfoldVignette")
    end
    curX, curY = nil, nil  -- reset smoothing
    active = true
    rects.top:Show()
    rects.bottom:Show()
    rects.left:Show()
    rects.right:Show()
    rects.vignette:Show()
    print("|cff00ff00Blindfold|r: Peephole enabled. (/blind off to disable)")
end

local function disable()
    active = false
    if rects.top then
        rects.top:Hide()
        rects.bottom:Hide()
        rects.left:Hide()
        rects.right:Hide()
        rects.vignette:Hide()
    end
    print("|cff00ff00Blindfold|r: Sight restored.")
end

------------------------------------------------------------
-- Slash commands
------------------------------------------------------------

SLASH_BLINDFOLD1 = "/blind"
SlashCmdList["BLINDFOLD"] = function(msg)
    msg = strtrim(msg:lower())

    local function showHelp()
        print("|cff00ff00Blindfold|r: Commands:")
        print("  |cffffff00/blind on|r       - Enable the blindfold peephole effect")
        print("  |cffffff00/blind off|r      - Disable the blindfold and restore full sight")
        print("  |cffffff00/blind size <n>|r - Set the peephole radius (default: 80)")
        print("  |cffffff00/blind lag <n>|r  - Set cursor smoothing (default: 6, lower = more lag)")
        print("  |cffffff00/blind help|r     - Show this help message")
    end

    if msg == "on" then
        enable()
    elseif msg == "off" or msg == "" then
        disable()
    elseif msg == "help" then
        showHelp()
    elseif msg:match("^size %d+$") then
        local n = tonumber(msg:match("%d+"))
        if n and n > 0 then
            PEEP_RADIUS = n
            print(string.format("|cff00ff00Blindfold|r: Peephole radius set to %d.", n))
        end
    elseif msg:match("^lag %d+$") then
        local n = tonumber(msg:match("%d+"))
        if n and n > 0 then
            LERP_SPEED = n
            print(string.format("|cff00ff00Blindfold|r: Lag set to %d (lower = more lag).", n))
        end
    else
        showHelp()
    end
end

------------------------------------------------------------
-- Startup
------------------------------------------------------------

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function(self)
    print("|cff00ff00Blindfold|r loaded. Use /blind on to begin.")
end)
