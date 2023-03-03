warfare = {
    protector = {}
}

local path = minetest.get_modpath("warfare")
dofile(path.."/overrides.lua")
dofile(path.."/protector.lua")

warfare.protector.load_areas()

-- Defense structures: walls
-- Some information:
-- 1. Wall bricks are very hard to destroy to add realism
-- 2. The hardness of the wall bricks will be based on the materials used
--    for building the walls.
--    a. Wall bricks will be produced on a special furnace that allow mixing elements
--    b. Elements added to the stone will have an effect on its hardness
--    c. How to implement this: when furnace produces itemstack, set metadata and add the
--       value of param2. When on_place, get this metadata and set the param2 value via
--       minetest.swap_node
-- 3. There will be different textures for different type of wall bricks
-- 4. Wall brick will show damage. There will be 3 levels of visible damage

-- Base is a Lua table with the following format
warfare.register_wall_material = function(name, description, base_texture, variations)
    local get_def = function() 
        return {
            description = description,
            tiles = {base_texture},
            groups = {wally = 2, stone = 1, level = 3},
            drop = "warfare:hard_stone",
            paramtype1 = "none",
            paramtype2 = "none",
            place_param2 = 10,
            on_place = function(itemstack, placer, pointed_thing)
                -- TODO: Get param2 from itemstack and pass it here
                local _, pos = minetest.item_place(itemstack, placer, pointed_thing)
                -- Store original param2 (how many times node has to be dug) in param1
                local node = minetest.get_node(pos)
                node.param1 = 10
                minetest.swap_node(pos, node)
            end,
            on_punch = function(pos, node, puncher, pointed_thing)
                -- TODO: If inside an area owned by puncher, then reduce param2 to 0
                if warfare.protector.is_pos_inside_owned_area(pos, puncher) then
                    node.param2 = 0
                    minetest.swap_node(pos, node)
                end
            end,
            on_dig = function(pos, node, digger)
                minetest.log("Param 2: "..node.param2)

                if node.param2 == 0 then
                    -- Destroy
                    return minetest.node_dig(pos, node, digger)
                end

                -- Add visible damage, if needed
                if node.param2 == node.param1 then
                    node.name = node.name.."_damage_1"
                else
                    local damage_interval, _ = math.modf(node.param1 / 3)
                    if node.param2 % damage_interval == 0 then
                        -- TODO: Swap with more damaged block
                        minetest.log("More damage!")
                    end
                end

                node.param2 = node.param2 - 1
                minetest.swap_node(pos, node)
                return false
            end,
            sounds = default.node_sound_stone_defaults(),
        }
    end

    local def = get_def()
    minetest.register_node("warfare:"..name, def)

    -- Register damaged nodes
    for i = 1, 3 do
        local def = get_def()
        def.tiles = {base_texture.."^[cracko:1:"..(i * 2)}
        def.groups["not_in_creative_inventory"] = 1
        minetest.register_node("warfare:"..name.."_damage_"..i, def)
    end

    for key,value in pairs(variations) do
        local def = get_def()
        def.tiles = {base_texture.."^"..variations[key].overlay}
        def.description = variations[key].description
        minetest.register_node("warfare:"..name.."_"..key, def)

        -- Register damaged nodes
        for i = 1, 3 do
            local def = get_def()
            def.tiles = {base_texture.."^"..variations[key].overlay.."^[cracko:1:"..(i * 2)}
            def.groups["not_in_creative_inventory"] = 1
            minetest.register_node("warfare:"..name.."_"..key.."_damage_"..i, def)
        end
    end
end

warfare.register_wall_material("stone_bricks", "Wall Stone Bricks", "default_stone_brick.png", {
    ["gold_studded"] = {overlay = "default_mineral_gold.png", description = "Gold Studded Wall Stone Bricks"}
})