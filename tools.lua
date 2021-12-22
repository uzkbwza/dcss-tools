{
    function c_message(text, channel)
        if string.match(text, "!checkdmg") then
            local item = items.equipped_at(0)
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
        local weapons = { unarmed_data() }
        function get_weapons_from(tab)
            if tab ~= nil and tab[0] == nil then
                for i, item in ipairs(tab) do
                    if type(item) == "userdata" then
                        -- display_line((item))
                        if is_valid_weapon(item) and item.fully_identified and not (item.is_useless) then -- weapon
                            table.insert(weapons, item)
                        end
                    end
                end
            end
        end
        get_weapons_from(items.inventory())
        -- display_line(tostring(items.shopping_list()))
        get_weapons_from(you.floor_items())

        -- get_weapons_from(known_weapons)
        -- crawl.mpr(tostring(items.inventory()))

        local base_damage_map = {}
        local total_damage_map = {}
        
        for i, item in ipairs(weapons) do
            -- display_line(weapon:name())
            local enemy_stats = { ac = 1, ev = 6 }
            enemy_stats.hit_chance = hit_chance(to_hit(item), enemy_stats.ev)
            local base_damage = get_dpt(item, enemy_stats, false, false)
            local total_damage = (item.branded or is_staff(item)) and get_dpt(item, enemy_stats, true, false) or base_damage
            -- display_line(tostring(base_damage) .. " " .. tostring(total_damage))
            -- item.base_damage = base_damage
            -- item.total_damage = total_damage
            base_damage_map[item] = base_damage
            total_damage_map[item] = total_damage
            if base_damage >= highest_base_damage then
                highest_base_damage = base_damage
                highest_base_damage_weapon = item
            end
            if total_damage >= highest_total_damage then
                highest_total_damage = total_damage
                highest_total_damage_weapon = item
            end
        end
        
        -- display_line("Highest damage: " .. highest_base_damage_weapon:name_coloured() .. " at " .. fmt_num(highest_base_damage) .. " damage per 1.0 AUTs", "white")
        display_line("Highest total (branded) damage: " .. highest_total_damage_weapon:name_coloured() .. " at <lightgreen>" .. fmt_num(base_damage_map[highest_total_damage_weapon]) .. " / " .. fmt_num(total_damage_map[highest_total_damage_weapon]) .. "</lightgreen> damage per 1.0 AUTs", "white")
        crawl.more()
    
        function sort_predicate(a, b)
            return total_damage_map[a] > total_damage_map[b]
        end

        table.sort(weapons, sort_predicate)
        for i, item in ipairs(weapons) do
            if i > 1 then
                local damage = fmt_num(base_damage_map[item]) .. " / " .. fmt_num(total_damage_map[item])
                display_line(tostring(i) .. ". " .. item:name_coloured() .. " - <white>" .. damage .. "</white> dmg")
            end
        end
    end

    function display_line(text, color)
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
        local hit_chance_color = "darkgrey"
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
        
        local die_num = item.damage * strength_modifier(max) + 1
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

    function strength_modifier(max)
        local dice_avg = not max and dice_avg or (function(num_dice, num_sides) return num_dice * num_sides end)
        local strength = you.strength()
        if strength > 10 then
            return (39 + ((dice_avg(1, strength - 8) - 1) * 2)) / 39
        elseif strength < 10 then
            return (39 - ((dice_avg(1, 12 - strength) - 1) * 3)) / 39
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
    }
