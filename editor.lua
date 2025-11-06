-- storycam/editor.lua
-- Command system for editing and controlling StoryCam

minetest.register_chatcommand("story_create", {
    params = "<name>",
    description = "Create a new story project",
    func = function(name, param)
        if param == "" then return false, "Usage: /story_create <name>" end
        storycam.projects[param] = {points = {}}
        return true, "Created project " .. param
    end
})

minetest.register_chatcommand("story_addpoint", {
    params = "<name> <dur>",
    description = "Add your current camera as a waypoint",
    func = function(name, param)
        local pname, dur = param:match("^(%S+)%s*(%S*)$")
        if not pname then return false, "Usage: /story_addpoint <name> <dur>" end
        local player = minetest.get_player_by_name(name)
        local proj = storycam.projects[pname]
        if not proj then return false, "Project not found" end
        table.insert(proj.points, storycam.capture_waypoint(player, tonumber(dur) or 3))
        return true, "Added waypoint to " .. pname
    end
})

minetest.register_chatcommand("story_angle", {
    params = "<yaw> <pitch>",
    description = "Manually adjust your camera angle (editing only)",
    func = function(name, param)
        local yaw, pitch = param:match("^(%S+)%s+(%S+)$")
        if not yaw or not pitch then
            return false, "Usage: /story_angle <yaw> <pitch>"
        end
        local player = minetest.get_player_by_name(name)
        player:set_look_horizontal(math.rad(tonumber(yaw)))
        player:set_look_vertical(math.rad(tonumber(pitch)))
        return true, "Angle set to yaw=" .. yaw .. ", pitch=" .. pitch
    end
})

minetest.register_chatcommand("story_save", {
    params = "<name>",
    description = "Save current story project",
    func = function(_, param)
        local ok, err = storycam.save(param)
        return ok, ok and "Saved!" or err
    end
})

minetest.register_chatcommand("story_load", {
    params = "<name>",
    description = "Load a story project",
    func = function(_, param)
        local ok, err = storycam.load(param)
        return ok, ok and "Loaded!" or err
    end
})

minetest.register_chatcommand("story_play", {
    params = "<name> [player]",
    description = "Play cinematic sequence",
    privs = {server = true},
    func = function(caller, param)
        local pname, target = param:match("^(%S+)%s*(%S*)$")
        if not pname then
            return false, "Usage: /story_play <project> [player]"
        end
        local proj = storycam.projects[pname]
        if not proj then
            return false, "Project not found: " .. pname
        end
        local player = target ~= "" and minetest.get_player_by_name(target)
            or minetest.get_player_by_name(caller)
        if not player then
            return false, "Player not found"
        end

        storycam.play_sequence(player, proj)
        return true, "Playing story '" .. pname .. "' for " .. player:get_player_name()
    end
})
