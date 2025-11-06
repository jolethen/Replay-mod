-- storycam/core.lua
-- Shared utilities

function storycam.lerp(a, b, t)
    return a + (b - a) * t
end

function storycam.lerp_angle(a, b, t)
    local diff = (b - a + math.pi) % (2 * math.pi) - math.pi
    return a + diff * t
end

-- Simple cubic easing (smooth in/out)
function storycam.ease(t)
    return t < 0.5 and 4*t*t*t or 1 - math.pow(-2*t + 2, 3) / 2
end

function storycam.filepath(name)
    return storycam.worldpath .. "/story_" .. name .. ".json"
end

function storycam.lock_player(p, lock)
    if lock then
        p:set_physics_override({speed=0, jump=0})
        p:hud_set_flags({
            wielditem=false, crosshair=false,
            healthbar=false, hotbar=false
        })
    else
        p:set_physics_override({speed=1, jump=1})
        p:hud_set_flags({
            wielditem=true, crosshair=true,
            healthbar=true, hotbar=true
        })
    end
end
