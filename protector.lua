-- Area protector
-- In this areas, protection consists of reduced ability to place and dig nodes. Combat and interaction is allowed.

-- TODO: Hamper node placing and node digging for all players if protection is on
-- How to hamper? Check protection violation and then ... well... check timer on player and... well... etc.
-- TODO: Add area conquering
-- TODO: Add ability to enable/disable protection
-- TODO: Change protector to be a NPC?

warfare.protector.area_check_interval = 2
warfare.protector.area_check_timer = 0
warfare.protector.hud = {}

warfare.protector.load_areas = function()
    warfare.protector.areas = AreaStore()
end

warfare.protector.is_pos_inside_owned_area = function(pos, player)
    local all_areas = warfare.protector.areas:get_areas_for_pos(pos, true, true)
    for _, area in pairs(all_areas) do
        local data = minetest.deserialize(area.data)
        if data.owner == player:get_player_name() then
            return true
        end
    end
end

warfare.protector.is_pos_inside_area = function(pos)
    local all_areas = warfare.protector.areas:get_areas_for_pos(pos, true, true)
    for _, area in pairs(all_areas) do
        return area
    end
end

--insert_area(corner1, corner2, data, [id])`: inserts an area into the store.

minetest.register_node("warfare:protector", {
    description = "Protector",
    drop = "warfare:protector",
    paramtype = "light",
    drawtype = "glasslike_framed_optional",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	sunlight_propagates = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
    on_place = function(itemstack, placer, pointed_thing)
        local stack, pos = minetest.item_place(itemstack, placer, pointed_thing)
        local pos1 = vector.subtract(pos, 10)
        local pos2 = vector.add(pos, 10)
        local data = {
            ["owner"] = placer:get_player_name()
        }

        minetest.log("Adding new area at positions ["..minetest.pos_to_string(pos1).." - "..minetest.pos_to_string(pos2).."]")
        warfare.protector.areas:insert_area(pos1, pos2, minetest.serialize(data))
        return stack
    end,
    on_punch = function(pos, node, puncher, pointed_thing)
        -- TODO: If inside an area owned by puncher, then reduce param2 to 0
    end,
    on_dig = function(pos, node, digger)
        return minetest.node_dig(pos, node, digger)
    end,
    sounds = default.node_sound_stone_defaults(),
})

-- Updates HUD
minetest.register_globalstep(function(dtime)
    warfare.protector.area_check_timer = warfare.protector.area_check_timer + dtime
    if warfare.protector.area_check_timer >= warfare.protector.area_check_interval then
        warfare.protector.area_check_timer = 0
        
        for _, player in pairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local pos = vector.round(player:get_pos())

            local area = warfare.protector.is_pos_inside_area(pos)
            if area ~= nil then
                local data = minetest.deserialize(area.data)
                local areaString = data.owner.."'s land"
                local hud = warfare.protector.hud[name]
                if not hud then
                    hud = {}
                    warfare.protector.hud[name] = hud
                    hud.areasId = player:hud_add({
                        hud_elem_type = "text",
                        name = "Areas",
                        number = 0xFFFFFF,
                        position = {x=0, y=1},
                        offset = {x=8, y=-8},
                        text = areaString,
                        scale = {x=200, y=60},
                        alignment = {x=1, y=-1},
                    })
                    hud.oldAreas = areaString
                    return
                elseif hud.oldAreas ~= areaString then
                    player:hud_change(hud.areasId, "text", areaString)
                    hud.oldAreas = areaString
                end
            else
                local hud = warfare.protector.hud[name]
                if hud then
                    player:hud_remove(hud.areasId)
                    warfare.protector.hud[name] = nil
                end
            end
        end
    end
end)