--[[
    ShapeData — ModuleScript
    Place in: ReplicatedStorage/ShapeData

    Provides normalized (0-1) outline points for each drawable shape.
    Points are ordered and continuous — used for guide rendering and accuracy scoring.
--]]

local ShapeData = {}

local CANVAS = 500 -- virtual canvas size in pixels, used for threshold math context

local function circlePoints(n)
    local pts = {}
    for i = 0, n - 1 do
        local a = (i / n) * 2 * math.pi
        pts[#pts + 1] = Vector2.new(0.5 + 0.38 * math.cos(a), 0.5 + 0.38 * math.sin(a))
    end
    return pts
end

local function polygonPoints(sides, n)
    local vertices = {}
    for i = 0, sides - 1 do
        local a = (i / sides) * 2 * math.pi - math.pi / 2
        vertices[#vertices + 1] = Vector2.new(0.5 + 0.38 * math.cos(a), 0.5 + 0.38 * math.sin(a))
    end

    local pts = {}
    local perEdge = math.floor(n / sides)
    for i = 1, #vertices do
        local v1 = vertices[i]
        local v2 = vertices[(i % #vertices) + 1]
        for j = 0, perEdge - 1 do
            local t = j / perEdge
            pts[#pts + 1] = Vector2.new(v1.X + (v2.X - v1.X) * t, v1.Y + (v2.Y - v1.Y) * t)
        end
    end
    return pts
end

local SHAPES = {
    Circle = {
        coins       = 350,
        displayName = "Circle",
        generate    = function() return circlePoints(120) end,
    },
    Triangle = {
        coins       = 400,
        displayName = "Triangle",
        generate    = function()
            -- Equilateral triangle — flat base, point at top
            local n = 90
            local vertices = {
                Vector2.new(0.5,  0.12),
                Vector2.new(0.88, 0.86),
                Vector2.new(0.12, 0.86),
            }
            local pts = {}
            local perEdge = math.floor(n / 3)
            for i = 1, 3 do
                local v1 = vertices[i]
                local v2 = vertices[(i % 3) + 1]
                for j = 0, perEdge - 1 do
                    local t = j / perEdge
                    pts[#pts + 1] = Vector2.new(v1.X + (v2.X - v1.X) * t, v1.Y + (v2.Y - v1.Y) * t)
                end
            end
            return pts
        end,
    },
    Pentagon = {
        coins       = 700,
        displayName = "Pentagon",
        generate    = function() return polygonPoints(5, 100) end,
    },
}

function ShapeData.getShape(shapeName)
    local def = SHAPES[shapeName]
    if not def then return nil end
    return {
        name        = def.displayName,
        coins       = def.coins,
        points      = def.generate(),
    }
end

function ShapeData.getShapeNames()
    return {"Circle", "Triangle", "Pentagon"}
end

function ShapeData.getCoins(shapeName)
    local def = SHAPES[shapeName]
    return def and def.coins or 0
end

return ShapeData
