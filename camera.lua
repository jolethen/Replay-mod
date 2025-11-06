-- storycam/camera.lua
-- Smooth playback controller

minetest.register_globalstep(function(dtime)
    for id, play in pairs(storycam.active_plays) do
        local path = play.path
        if not path or #path == 0 then
            storycam.active_plays[id] = nil
        else
            local cur = path[play.idx]
            local nxt = path[play.idx + 1]
            if not cur then
                for _, p in ipairs(play.players) do storycam.lock_player(p, false) end
                storycam.active_plays[id] = nil
            else
                play.timer = play.timer + dtime
                local dur = cur.dur or 2
                local t = math.min(play.timer / dur, 1)
                local eased = storycam.ease(t)

                local pos, yaw, pitch
                if nxt then
                    pos = {
                        x = storycam.lerp(cur.pos.x, nxt.pos.x, eased),
                        y = storycam.lerp(cur.pos.y, nxt.pos.y, eased),
                        z = storycam.lerp(cur.pos.z, nxt.pos.z, eased)
                    }
                    yaw = storycam.lerp_angle(cur.yaw, nxt.yaw, eased)
                    pitch = storycam.lerp(cur.pitch, nxt.pitch, eased)
                else
                    pos = cur.pos
                    yaw = cur.yaw
                    pitch = cur.pitch
                end

                for _, p in ipairs(play.players) do
                    if p and p:is_player() then
                        p:set_pos(pos)
                        p:set_look_horizontal(yaw)
                        p:set_look_vertical(pitch)
                    end
                end

                if t >= 1 then
                    play.idx = play.idx + 1
                    play.timer = 0
                    if play.idx > #path then
                        for _, p in ipairs(play.players) do
                            storycam.lock_player(p, false)
                        end
                        storycam.active_plays[id] = nil
                    end
                end
            end
        end
    end
end)

-- Start playback
function storycam.play(projname, players)
    local proj = storycam.projects[projname]
    if not proj then return false, "no such project" end
    local id = projname.."_"..math.random(1000,9999)
    storycam.active_plays[id] = {path = proj.points, players = players, idx = 1, timer = 0}
    for _, p in ipairs(players) do storycam.lock_player(p, true) end
    return true
end
