{  
    c_persist.seen_weapons = c_persist.seen_weapons or {}
    use_enemy_tiles = false
    last_hp = 0

    function c_message(text, channel)
        if string.match(text, "!checkdmg") then
            local item = convert_weapon(items.equipped_at(0))
            if item == nil or is_valid_weapon(item) then
                display_damage(item)
            else
                display_line("No valid weapon equipped...", "magenta")
            end
        end
        if string.match(text, "!bestwep") then
            compare_damage()
        end
    end

    function ready()
        remember_weapons()
        get_monsters_in_los()
        if assess_threat_level(false) > 0 then
            check_health()
        end
        -- assess_threat_level()
    end

    function check_health()
        local hp, max = you:hp()
        if hp == last_hp then return end
        local diff = hp - last_hp
        local color
        local text
        if diff == 0 then return end
        if diff > 0 then
            text = tostring(hp) .. "/" .. tostring(max) .. " (+" .. tostring(diff) .. ")"
            color = "lightgreen"
        else
            text = tostring(hp) .. "/" .. tostring(max) .. " (" .. tostring(diff) .. ")"
            if hp < max * 0.75 then
                color = "red"
            else
                color = "lightred"
            end
            
        end
        display_line(text, color)
        if diff < -(max / 4.0) then
            crawl.more()
        end
        last_hp = hp
    end
    
    function convert_weapon(weap)
        -- converts from opaque Userdata object to table
        local name = weap:name()
        local name_coloured = weap:name_coloured()
        local ego = weap:ego()
        local class = weap:class()
        local subtype = weap:subtype()
        return { name = function() return name end,
        name_coloured = function() return name_coloured end,
        ego = function() return ego end,
        subtype = function() return subtype end,
        class = function() return class end,
        weap_skill = weap.weap_skill,
        is_unarmed = weap.is_unarmed,
        description = weap.description,
        fully_identified = weap.fully_identified,
        damage = weap.damage,
        branded = weap.branded,
        plus = weap.plus,
        delay = weap.delay,
        accuracy = weap.accuracy,
        attr = get_weap_attr(weap) }
    end

    function get_weap_attr(weap)
        if string.match(weap.weap_skill, "Blades") or weap.is_ranged then
            return "Dex"
        end
        return "Str"
    end

    function catalogue_weapon(weap, inventory)
        c_persist.seen_weapons[weap:name()] = {item = weap, location = inventory and "in your inventory" or location_string() }
        -- display_line(tostring(#seen_weapons) .. " weapons found")
        -- list_contents(seen_weapons)
    end

    function list_contents(arr)
        if type(arr) ~= "table" then
            display_line(arr)
        else
            for key, value in pairs(arr) do
                list_contents(key)
                list_contents(value)
            end
        end
    end

    function location_string()
        return "on " .. you:branch() .. ":" .. you:depth()
    end

    function remember_weapons()
        function catalogue_weapon_arr(array, inventory)
            for i, item in ipairs(array) do
                if is_valid_weapon(item) then
                    catalogue_weapon(convert_weapon(item), inventory)
                end
            end
        end
        catalogue_weapon_arr(you:floor_items())
        catalogue_weapon_arr(items:inventory(), true)
    end
  
    function is_valid_weapon(item) 
        return item:class() == "Hand Weapons" or item:class() == "Magical Staves"
    end

    function is_staff(item)
        return string.match(item:class(), "Magical Staves") ~= nil
    end

    function unarmed_data() 
        local base_damage = 3
        local claws_level = you.get_base_mutation_level("claws")
        local skill = you.skill("Unarmed Combat")
        local item = 
        {   damage = (base_damage + 2 * claws_level) + skill,
            ego = function() return nil end,
            name = function() return "Unarmed" end,
            name_coloured = function() return "<lightgray>Unarmed</lightgray>" end,
            subtype = function() return "Unarmed" end,
            class = function() return "Hand Weapons" end,
            branded = false,
            fully_identified = true,
            is_useless = false,
            weap_skill = "Unarmed Combat",
            attr = "Str",
            accuracy = 0,
            plus = 0,
            delay = 10 - 1 * (skill / 5.4),
            is_unarmed = true, }
        return item
    end
    
    function compare_damage()
        display_line("Comparing items in your inventory and under your feet...")
        display_line("Fighting against imaginary ogres...", "darkgray")

        local highest_base_damage = 0
        local highest_total_damage = 0

        local highest_base_damage_weapon
        local highest_total_damage_weapon
        local items_ = items.inventory()
        local weapons = { { name = "Unarmed", item = unarmed_data(), location = "attached to your body" } }
        for name, data in pairs(c_persist.seen_weapons) do
            
            table.insert(weapons, { name = name, item = data.item, location = data.location, })
        end
        -- list_contents(weapons)

        -- get_weapons_from(known_weapons)
        -- crawl.mpr(tostring(items.inventory()))
        
        for i, data in ipairs(weapons) do
            -- display_line("got here", "red")
            -- list_contents(data)
            local name = data.name
            local item = data.item
            -- display_line(weapon:name())
            local enemy_stats = { ac = 1, ev = 6 }
            enemy_stats.hit_chance = hit_chance(to_hit(item), enemy_stats.ev)
            local base_damage = get_dpt(item, enemy_stats, false, false)
            local total_damage = (item.branded or is_staff(item)) and get_dpt(item, enemy_stats, true, false) or base_damage
            -- display_line(tostring(base_damage) .. " " .. tostring(total_damage))
            data.base_damage = base_damage
            data.damage = total_damage
            -- item.total_damage = total_damage
            -- if base_damage >= highest_base_damage then
            --     highest_base_damage = base_damage
            --     highest_base_damage_weapon = item
            -- end
            if total_damage >= highest_total_damage then
                highest_total_damage = total_damage
                highest_total_damage_weapon = data
            end
        end
        -- display_line("Highest damage: " .. highest_base_damage_weapon:name_coloured() .. " at " .. fmt_num(highest_base_damage) .. " damage per 1.0 AUTs", "white")
        -- display_line(fmt_num(highest_total_damage_weapon.damage) .. "</lightgreen> damage per 1.0 AUTs, found on " .. data.location)
        display_line("Highest total (branded) damage: " .. highest_total_damage_weapon.item:name_coloured() .. " at <lightgreen>" .. fmt_num(highest_total_damage_weapon.base_damage) .. " / " .. fmt_num(highest_total_damage_weapon.damage) .. "</lightgreen> damage per 1.0 AUTs, found " .. highest_total_damage_weapon.location .. ".", "white")
        crawl.more()
        function sort_predicate(a, b)
            return a.damage > b.damage
        end
        table.sort(weapons, sort_predicate)
        for i, data in ipairs(weapons) do
            if i > 1 and i <= 10 then
                local item = data.item
                local damage = fmt_num(data.base_damage) .. " / " .. fmt_num(data.damage)
                display_line(tostring(i) .. ". " .. item:name_coloured() .. " - <white>" .. damage .. "</white> dmg, " .. data.location)
                -- display_line("got here")
            end
        end
    end

    function display_line(text, color)
        if type(text) ~= "string" then
            text = tostring(text)
        end
        color = color or "lightgray"
        crawl.message("<"..color..">"..text.."</"..color..">", 0)    
    end

    function display_damage(item)
        
        -- if item == nil then
        --     return 
        -- end
        
        -- display_line(item:class())
        item = item or unarmed_data()
        
        local enemy_stats = { ac = 1, ev = 6}
        
        crawl.mpr("Enemy AC (default 1): ", 2)
        local ac = tonumber(crawl.c_input_line())

        crawl.mpr("Enemy EV (default 6): ", 2)
        local ev = tonumber(crawl.c_input_line())

        
        if type(ac) == "number" then
            enemy_stats.ac = ac
        end     
        
        if type(ev) == "number" then
            enemy_stats.ev = ev
        end
        
        enemy_stats.hit_chance = hit_chance(to_hit(item), enemy_stats.ev)
        local dpt_no_brand = get_dpt(item, enemy_stats, false)
        display_line("Warning: this figure is a VERY rough approximation and does not account for armor encumbrance, slaying, and most other buffs or status effects.", "lightred")
        display_line("Fighting against imaginary enemy with " .. tostring(enemy_stats.ac) .. " AC and " .. tostring(enemy_stats.ev) .. " EV...", "darkgray")
        if item.is_unarmed then
            display_line("Unarmed calculations assume no gloves worn.", "magenta")
        end
        function extra_reports(has_ego) -- 
            local ego_avg_damage = has_ego and (" / " .. fmt_num(get_damage(item, enemy_stats, true))) or ""
            local ego_max_damage = has_ego and (" / " .. fmt_num(get_damage(item, enemy_stats, true, true))) or ""

            display_line("Average damage per attack: " .. fmt_num(get_damage(item, enemy_stats, false)) .. ego_avg_damage .. " ~(" .. fmt_num(weapon_delay(item) / 10) .. " AUTs)", "green")
            display_line("Max damage per attack: " .. fmt_num(get_damage(item, enemy_stats, false, true)) .. ego_max_damage, "green")
        end
        
        if not (item.branded or is_staff(item)) then
            display_line("Approx pre-buff weapon damage per 1.0 AUTs: " .. "<lightcyan>" .. tostring(dpt_no_brand) .. "</lightcyan>", "lightgreen")
            extra_reports(false)
        else
            local dpt_with_brand = get_dpt(item, enemy_stats, true)
            display_line("Approx pre-buff weapon damage per 1.0 AUTs:", "lightgreen")
            display_line("(before brand / after brand vs susceptible creatures)", "lightgreen")
            display_line("      " .. tostring(dpt_no_brand) .. "    /    " .. tostring(dpt_with_brand), "lightcyan")
            extra_reports(true)
        end

        local hit_chance = enemy_stats.hit_chance * 100
        local hit_chance_color = "darkgray"
        if hit_chance >= 10 then
            hit_chance_color = "red"
        end
        if hit_chance >= 30 then
            hit_chance_color = "lightred"
        end
        if hit_chance >= 50 then
            hit_chance_color = "yellow"
        end
        if hit_chance >= 70 then
            hit_chance_color = "green"
        end
        if hit_chance >= 90 then
            hit_chance_color = "lightgreen"
        end
        display_line("Chance to hit: <" .. hit_chance_color .. ">" .. "~" .. fmt_num(hit_chance) .. "%" .. "</" .. hit_chance_color .. ">")

            -- item.description = item.description .. message_string
    end
    
    function get_dpt(item, enemy_stats, use_brand, format_result)
        
        if format_result == nil then format_result = true end
        local damage_per_swing = get_damage(item, enemy_stats, use_brand)
        local additional_notes = ""
        local you_delay = weapon_delay(item)
        local venom_adjustment = 0
        if use_brand then
            if is_staff(item) then
                if item:subtype() == "poison" then
                    local activation_chance = math.min((50 + you.skill("Poison Magic") * 12.5), 100)
                    venom_adjustment = midrange(1, 7) * (activation_chance / 100)
                    additional_notes = additional_notes .. " (estimated adjustment for poison damage, " .. fmt_num(activation_chance) .. "% chance to activate)"
                end
            else
                if item:ego() == "venom" then
                    venom_adjustment = midrange(1, 7)
                    additional_notes = additional_notes .. " (estimated adjustment for poison damage, 75% chance to activate)"
                end
            end
        end
        local result = damage_per_swing * (1 / (you_delay / 10)) + venom_adjustment
        if format_result then
            return fmt_num(result) .. additional_notes
        else
            return result
        end
    end

    function get_damage(item, enemy_stats, use_brand, max)
        local dice_avg = not max and dice_avg or (function(num_dice, num_sides) return num_dice * num_sides end) -- if we're looking for the max possible damage, dont get the average of any dice rolls - just the highest possible rolls.
        -- ignores slaying bonus, other "final multipliers"
        --[[
        Damage = 
            {
                [1d(Base damage * Strength modifier +1)-1] 
                    * Weapon skill modifier 
                    * Fighting modifier 
                    + Misc modifiers 
                    + Slaying bonuses
            } * Final multipliers 
            + Stabbing bonus 
            - AC damage reduction[1]
        --]]
        
        local die_num = item.damage * attr_modifier(item.attr == "Str" and you.strength() or you.dexterity(), item.max) + 1
        -- display_line("got here")
        local effective_enchantment = item.plus or 0

        if effective_enchantment > 0 then
            effective_enchantment = dice_avg(1, 1 + effective_enchantment) - 1
        elseif effective_enchantment < 0 then
            effective_enchantment = -dice_avg(1, 1 - effective_enchantment) + 1
        end
        local damage = math.max(((dice_avg(1, die_num) - 1) * weapon_skill_modifier(item, max) * fighting_modifier(max)) + effective_enchantment - (enemy_stats.ac/2), 0)
        if not max then 
            damage = damage * enemy_stats.hit_chance
        end
        -- display_line(tostring(string.match(item:class(), "Magical Staves")))
        if use_brand then
            if is_staff(item) then
                damage = damage + staff_bonus(item, damage, max)
            else
                damage = damage + brand_bonus(item, damage, max)
            end
        end

        return damage 
    end

    function weapon_delay(item)
        if item.is_unarmed then
            return item.delay
        end
        local base_delay = item.delay
        local min_delay = math.min(base_delay / 2, 7)
        if item.subtype() == "rapier" then
            min_delay = 5
        end

        local you_delay = math.max(base_delay - math.ceil(you.skill(item.weap_skill)/2 + 0.5), min_delay)

        if item:ego() == "speed" then
            you_delay = you_delay * 0.66666
        end
        return you_delay
    end

    function hit_chance(to_hit, ev)
        if ev <= 0 then 
            return 0.99
        end
        local total = 0
        for i=1,to_hit do
            for j=1,ev do
                if i >= j then
                    total = total + 1
                end
            end
        end
        return total / (to_hit * ev)
    end
    
    function to_hit(item)
        local base = 15 + you.dexterity()/2 + you.skill("Fighting")/2
        -- item.plus = item.plus
        local weapon_accuracy = you.skill(item.weap_skill)/2 + item.accuracy + (item.plus or 0)
        base = base + weapon_accuracy
        return (base-1) / 2 -- average roll
    end

    function attr_modifier(attr, max)
        local dice_avg = not max and dice_avg or (function(num_dice, num_sides) return num_dice * num_sides end)
        if attr > 10 then
            return (39 + ((dice_avg(1, attr - 8) - 1) * 2)) / 39
        elseif attr < 10 then
            return (39 - ((dice_avg(1, 12 - attr) - 1) * 3)) / 39
        else
            return 1
        end
    end
    
    function weapon_skill_modifier(item, max)
        local dice_avg = not max and dice_avg or (function(num_dice, num_sides) return num_dice * num_sides end)
        local modifier = (2499 + dice_avg(1, 100 * you.skill(item.weap_skill) + 1)) / 2500
        return modifier
    end
    
    function fighting_modifier(max)
        local dice_avg = not max and dice_avg or (function(num_dice, num_sides) return num_dice * num_sides end)
        return (3999 + dice_avg(1, 100 * you.skill("Fighting") + 1)) / 4000
    end
    
    function brand_bonus(item, damage, max)
        local midrange = not max and midrange or (function(low, high) return high end)
        local dice_avg = not max and dice_avg or (function(num_dice, num_sides) return num_dice * num_sides end)
        local brand = item:ego()
        local bonuses = 
            {   disruption = damage * 0.67,
                draining = damage * 0.25,
                electrocution = midrange(8, 20) * 0.33,
                flaming = damage * 0.25,
                freezing = damage * 0.25,
                ["holy wrath"] = damage * 0.75,
                pain = damage * you.skill("Necromancy")/2,
                silver = damage * 0.1667,
                vorpal = damage * 0.1667, }
        local bonus = 0

        for k,v in pairs(bonuses) do
            if string.match(brand, k) then
                bonus = v
                break
            end
        end

        return bonus
    end

    function staff_bonus(item, damage, max)
        
        local midrange = not max and midrange or (function(low, high) return high end)
        local item_type = item:subtype()
        
        function calculate_bonus(school)
            local evo_skill = you.skill("Evocations")
            local school_skill = you.skill(school)
            return midrange(0, 1.25 * (school_skill+evo_skill/2)) * midrange(0, 6.66 + (evo_skill + school_skill/2)) / 100
        end
        
        local bonuses = 
        {   fire = calculate_bonus("Fire Magic"),
        cold = calculate_bonus("Ice Magic"),
        earth = calculate_bonus("Earth Magic"),
        air = calculate_bonus("Air Magic"),
        conjuration = calculate_bonus("Conjurations"),
        death = calculate_bonus("Necromancy")}
        
        -- display_line("got here")

        return bonuses[item_type] or 0
    end

    monsters_in_los = {}
    
    function get_monsters_in_los()
        monsters_in_los = {}
        local los = you.los()
        for x = -los,los do
            for y = -los,los do
                local monster = monster.get_monster_at(x,y)
                if monster and not monster:is_firewood() then
                    table.insert(monsters_in_los, monster)
                end
            end
        end
    end

    threat_thresholds = {
        NONE = 0,
        LOW = 1,
        DUBIOUS = 10,
        HIGH = 20, 
        ["RUN!!"] = 30,}

    threat_colors = {
        NONE = "darkgray",
        LOW = "lightgray",
        DUBIOUS = "yellow",
        HIGH = "red", 
        ["RUN!!"] = "magenta", }
    
    previous_threat_level = 0
    previous_threat_level_name = nil

    function determine_monster_threat(monster)
        if monster:threat() < 1 or monster:attitude() ~= 0 then return 0 end
        -- display_line(monster:name())
        local threat_per_spell = 2
        local threat = (monster:threat()+1)^2
        local distance = math.sqrt(monster:x_pos()^2 + monster:y_pos()^2)
        -- display_line(distance)
        threat = threat - distance/3
        local max_hp = tonumber(string.match(monster:max_hp(), "%d+"))
        -- local you_hp, you_max_hp = you:hp()
        -- if max_hp and monster:threat() >= 2 then
        --     threat = threat + (max_hp - you_max_hp) / 2
        -- end
        
        for i, spell in ipairs(monster:spells()) do
            threat = threat + threat_per_spell
        end
        
        -- local speed_threats = {
        --     ["very slow"] = -4, 
        --     ["slow"] = -2, 
        --     ["normal"] = 0, 
        --     ["fast"] = 2, 
        --     ["very fast"] = 4, 
        --     ["extremely fast"] = 8,}

        -- threat = threat + speed_threats[monster:speed_description()]
        if threat < 0 then threat = 1 end
        -- display_line(monster:name() .. " " .. fmt_num(threat))
        return threat
    end

    function assess_threat_level(display)
        local total_threat_level = 0
        if next(monsters_in_los) == nil then -- if no monsters in sight
            total_threat_level = 0
        else
            local hp, max_hp = you:hp()
            -- display_line(math.floor(100 * (1 - hp / max_hp)^2))
            total_threat_level = ((27 - you:xl()) / 4) + (20 * math.max((1 - hp / max_hp), 0.5)^3)
        end
        local num_monsters = 0
        for i, monster in ipairs(monsters_in_los) do
            local threat = determine_monster_threat(monster)
            total_threat_level = total_threat_level + threat
            num_monsters = i
        end

        total_threat_level = total_threat_level + num_monsters
        

        local level = "NONE"
        local col = "darkgray"
        for level_name, value in pairs(threat_thresholds) do
            if total_threat_level >= value and threat_thresholds[level] < value then
                level = level_name
                col = threat_colors[level]
            end
        end
        -- local displayed_level = total_threat_level > 0 and 10 * math.log(total_threat_level/10) / math.log(2) or 0
        if (total_threat_level ~= previous_threat_level) and display then
            crawl.mpr("<" .. col .. ">" .. "DANGER LEVEL: " .. fmt_num(total_threat_level) .. " (" .. level .. ")" .. "</" .. col .. ">", 7)
            if level ~= previous_threat_level_name and total_threat_level > previous_threat_level and total_threat_level >= threat_thresholds.HIGH then
                crawl.more()
            end
        end
        previous_threat_level = total_threat_level
        previous_threat_level_name = level
        return total_threat_level
    end
    
    function dice_avg(num_dice, num_sides)
        return ((num_sides + 1) / 2) * num_dice
    end

    function midrange(low, high)
        return (low + high) / 2
    end
    
    function round_tenths(num)
        return round(num * 10) / 10
    end

    function round(num)
        return math.floor(num + 0.5)
    end

    function random_round(num)
        
    end

    function fmt_num(num)
        return tostring(round_tenths(num))
    end

    function set_tile()
        local race_tilesets = { ["Demonspawn"] = {"MONS_DEMONSPAWN"},
            ["Deep Elf"] = {"MONS_ELF", "MONS_DEEP_ELF_SORCERER", "MONS_DEEP_ELF_ARCHER"},
            ["Spriggan"] = {"MONS_SPRIGGAN"},
            ["Troll"] = {"MONS_SNORG", "MONS_PURGY", "MONS_TROLL"},
            ["Hill Orc"] = {"MONS_ORC"}, }
            
        function get_tile_from_tileset(name)
            return race_tilesets[name][crawl.random_range(0, #race_tilesets[name])]
        end
        local race_string = race_tilesets[you:race()] and get_tile_from_tileset(you:race()) or "mons_" .. you:race():gsub(" ", "_")
        if race_string == "" then return end
        -- local tile_num = crawl.random_range(1, 2)
        local tile_string = race_string
        -- display_line(tile_num)
        -- display_line(tile_string)
        -- if not c_persist.overwrite_tile or (you.turns() == 0) then
        c_persist.overwrite_tile = "tile:" .. tile_string
        -- end
        crawl.setopt("tile_player_tile = " .. c_persist.overwrite_tile)
        -- crawl.redraw_screen()
    end
    


    if use_enemy_tiles then
        set_tile()
    end

    }