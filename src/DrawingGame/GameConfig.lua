--[[
    GameConfig — ModuleScript
    Place in: ReplicatedStorage/GameConfig
--]]

return {
    DRAW_TIME           = 45,    -- seconds per round
    WIN_THRESHOLD       = 70,    -- % accuracy to earn full coin reward
    MIN_ACCURACY        = 25,    -- % accuracy to earn partial coins
    ACCURACY_THRESHOLD  = 28,    -- pixel radius: drawn point counts as "hitting" a shape point
    PENALTY_RADIUS_MULT = 1.8,   -- multiplier on threshold before stray penalty kicks in
    STRAY_PENALTY_MAX   = 25,    -- maximum % penalty for drawing outside the shape
    LINE_THICKNESS      = 5,     -- drawing stroke thickness in pixels
    GUIDE_DOT_SIZE      = 5,     -- size of each guide dot in pixels
    GUIDE_DASH_SKIP     = 2,     -- render every Nth guide segment (dashed look)
    CANVAS_SIZE         = 500,   -- virtual canvas dimensions (square)
}
