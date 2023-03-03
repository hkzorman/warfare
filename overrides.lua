-- Tool overrides
-- To each of the default tools, we add an overridee to handle the "wally" group
minetest.override_item("default:pick_diamond", {
    tool_capabilities = {
        groupcaps = {
            wally = {times={[1]=10, [2]=7, [3]=4}, uses=30, maxlevel=3},
        }
    }
})