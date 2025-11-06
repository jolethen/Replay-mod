-- storycam/init.lua
storycam = {}
storycam.projects = {}
storycam.modpath = minetest.get_modpath("storycam")
storycam.worldpath = minetest.get_worldpath()

-- Load core parts
dofile(storycam.modpath .. "/core.lua")
dofile(storycam.modpath .. "/project.lua")
dofile(storycam.modpath .. "/camera.lua")
dofile(storycam.modpath .. "/editor.lua")

-- Register commands
minetest.register_chatcommand("story_create", {
    params = "<name>",
    description = "Create a new cinematic project",
    func = function(name, param)
        if param == "" then
            return false, "Usage: /story_create <name>"
        end
        storycam.projects[param] = { points = {} }
        return true, "Created new project '" .. param .. "'"
    end
})

minetest.register_chatcommand("story_addpoint", {
    params = "<name> <duration> [frame]",
    description = "Add a camera waypoint (optionally specify frame index)",
    func = function(name, param)
        local pname, dur, frame = param:match("^(%S+)%s+(%S+)%s*(%S*)$")
        if not pname or not dur then
            return false, "Usage: /story_addpoint <name> <duration> [frame]"
        end
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end

        local proj = storycam.projects[pname]
        if not proj then return false, "Project not found" end

        local frame_num = tonumber(frame)
        local point = storycam.capture_waypoint(player, tonumber(dur))

        if frame_num then
            proj.points[frame_num] = point
        else
            table.insert(proj.points, point)
        end

        return true, "Added point to '" .. pname .. "' (duration " .. dur .. ")"
    end
})

minetest.register_chatcommand("story_save", {
    params = "<name>",
    description = "Save a cinematic project",
    func = function(_, param)
        if not param or param == "" then
            return false, "Usage: /story_save <name>"
        end
        local ok, err = storycam.save(param)
        if ok then
            return true, "Saved project '" .. param .. "'"
        else
            return false, err
        end
    end
})

minetest.register_chatcommand("story_load", {
    params = "<name>",
    description = "Load a cinematic project from disk",
    func = function(_, param)
        if not param or param == "" then
            return false, "Usage: /story_load <name>"
        end
        local ok, err = storycam.load(param)
        if ok then
            return true, "Loaded project '" .. param .. "'"
        else
            return false, err
        end
    end
})

minetest.register_chatcommand("story_play", {
    params = "<name> [player]",
    description = "Play cinematic sequence for a player (server only)",
    privs = {server = true},
    func = function(caller, param)
        local pname, target = param:match("^(%S+)%s*(%S*)$")
        if not pname then
            return false, "Usage: /story_play <project> [player]"
        end
        local proj = storycam.projects[pname]
        if not proj then
            return false, "Project not found"
        end
        local player = target ~= "" and minetest.get_player_by_name(target)
            or minetest.get_player_by_name(caller)
        if not player then
            return false, "Player not found"
        end
        storycam.play(player, proj)
        return true, "Playing cinematic '" .. pname .. "'"
    end
})

minetest.register_chatcommand("story_list", {
    description = "List all loaded cinematic projects and frame counts",
    privs = {server = true},
    func = function()
        local out = {}
        for name, proj in pairs(storycam.projects or {}) do
            local count = #(proj.points or {})
            table.insert(out, string.format("%s (%d frames)", name, count))
        end

        if #out == 0 then
            return true, "No projects loaded."
        else
            return true, "Loaded projects:\n- " .. table.concat(out, "\n- ")
        end
    end
})

minetest.register_chatcommand("story_edit", {
    params = "<name>",
    description = "Open a simple story editor UI",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local proj = storycam.projects[param]
        if not proj then return false, "Project not found" end
        storycam.show_editor(player, param)
        return true, "Opened editor for '" .. param .. "'"
    end
})

minetest.log("action", "[StoryCam] Loaded successfully.")
