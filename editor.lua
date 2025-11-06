-- storycam/editor.lua
storycam = storycam or {}

-- helper to build a simple formspec that lists frames + actions
local function build_edit_formspec(playername, project_name)
    local proj = storycam.projects[project_name]
    if not proj then return nil end
    proj.points = proj.points or {}
    local ordered = storycam.get_ordered_points(proj.points)

    local formspec = "size[8,9]" ..
                     "label[0.2,0.2;Editing project: " .. minetest.formspec_escape(project_name) .. "]" ..
                     "button[6.4,0.1;1.5,0.6;close;Close]" ..
                     "button[6.4,0.8;1.5,0.6;save;Save]"

    -- list frames
    local y = 1.2
    if #ordered == 0 then
        formspec = formspec .. "label[0.5,1.2;No frames yet. Use /story_addpoint to add one.]"
    else
        formspec = formspec .. "tablecolumns[color;string;string]" ..
                    "table[0.2,1.1;6.6,6;frames;"
        local rows = {}
        for i, item in ipairs(ordered) do
            local f = item.frame
            local dur = tostring(item.point.dur or 3)
            table.insert(rows, tostring(f) .. "," .. dur .. ",Play")
        end
        formspec = formspec .. table.concat(rows, ",") .. ";1]" -- select first row by default

        -- action buttons (Play selected, Delete selected, Jump)
        formspec = formspec ..
          "button[6.4,2.1;1.5,0.6;play_sel;Play]" ..
          "button[6.4,3.0;1.5,0.6;del_sel;Delete]" ..
          "button[6.4,3.9;1.5,0.6;jump_sel;Jump]"
    end

    return formspec
end

-- open editor formspec
minetest.register_chatcommand("story_edit", {
    params = "<project>",
    description = "Open story editor UI",
    func = function(caller, param)
        if not param or param == "" then return false, "Usage: /story_edit <project>" end
        local proj = storycam.projects[param]
        if not proj then return false, "Project not found" end
        local formspec = build_edit_formspec(caller, param)
        if not formspec then return false, "Failed to build UI" end
        minetest.show_formspec(caller, "storycam:editor:" .. param, formspec)
        return true
    end
})

-- helper: find selected frame from table index
local function find_frame_by_table_index(points_map, table_index)
    local ordered = storycam.get_ordered_points(points_map)
    if not ordered or #ordered == 0 then return nil end
    local idx = tonumber(table_index) or 1
    local item = ordered[idx]
    if item then return item.frame, item.point end
    return nil
end

-- handle formspec events
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname:find("^storycam:editor:") then return end
    local project_name = formname:sub(#"storycam:editor:" + 1)
    local proj = storycam.projects[project_name]
    if not proj then
        minetest.chat_send_player(player:get_player_name(), "Project missing.")
        return
    end

    if fields.close then
        minetest.close_formspec(player:get_player_name(), formname)
        return
    end

    if fields.save then
        local ok, err = storycam.save(project_name)
        minetest.chat_send_player(player:get_player_name(), ok and "Saved project." or ("Save failed: " .. (err or "unknown")))
        return
    end

    -- table selection index is passed as fields["frames"] = "r,c" or similar; more reliable is "frames" selection index in fields
    -- Minetest formspec table returns "frames" = "row,col" or "frames" = "row,col,row,col" depending; we take first row index
    local table_index = nil
    if fields.frames and fields.frames ~= "" then
        -- extract first number before comma
        local r = fields.frames:match("^(%-?%d+)")
        table_index = tonumber(r)
    end
    -- If player clicked Play selected
    if fields.play_sel then
        local frame, point = find_frame_by_table_index(proj.points, table_index or 1)
        if not frame then minetest.chat_send_player(player:get_player_name(), "No frame selected") return end
        -- build small single-frame project to play that frame (or play whole project)
        storycam.play_sequence(player, proj)
        return
    end

    if fields.del_sel then
        local frame, point = find_frame_by_table_index(proj.points, table_index or 1)
        if not frame then minetest.chat_send_player(player:get_player_name(), "No frame selected") return end
        proj.points[frame] = nil
        minetest.chat_send_player(player:get_player_name(), "Deleted frame " .. tostring(frame))
        -- reopen UI to refresh
        local fs = build_edit_formspec(player:get_player_name(), project_name)
        minetest.show_formspec(player:get_player_name(), formname, fs)
        return
    end

    if fields.jump_sel then
        local frame, point = find_frame_by_table_index(proj.points, table_index or 1)
        if not frame or not point then minetest.chat_send_player(player:get_player_name(), "No frame selected") return end
        -- teleport player to that point for editing (only while editing)
        pcall(function() player:set_pos(point.pos) end)
        pcall(function() storycam.safe_set_look(player, point.yaw or 0, point.pitch or 0) end)
        minetest.chat_send_player(player:get_player_name(), "Jumped to frame " .. tostring(frame) .. " for editing.")
        return
    end
end)
