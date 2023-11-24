function item_element_refresher_check_charge(keys)
    local item = keys.ability
    local caster = keys.caster

    if item:GetCurrentCharges() == 0 then item:SetCurrentCharges(1) end
    if item.blink_charge == nil then item:SetCurrentCharges(get_charge_ammount(caster)) end

    item.blink_charge = true
    item.blink_next_charge = GameRules:GetGameTime() + get_charge_time(caster)

    Timers:CreateTimer(0.3,function() 
        if item.blink_charge == true then
            if GameRules:GetGameTime() >= item.blink_next_charge and item:GetCurrentCharges() < get_charge_ammount(caster) then
                item:SetCurrentCharges(item:GetCurrentCharges()+1)
                item.blink_next_charge = GameRules:GetGameTime() + get_charge_time(caster)
            end
            return 0.3
        end
    end)
end

function item_element_refresher_stop_charge(keys)
    local item = keys.ability
    item.element_charge = false
end

function item_element_refresher_refresh(keys)
    local item = keys.ability
    local caster = keys.caster
    print (item:GetCurrentCharges())
    if item:GetCurrentCharges() > 0 then
        if caster:GetName() == "npc_dota_hero_invoker" then
            for i = 0, caster:GetAbilityCount() - 1 do
                local ability = caster:GetAbilityByIndex( i )
                if ability and ability ~= keys.ability then --and not no_refresh_skill[ ability:GetAbilityName() ]
                    ability:EndCooldown()
                end
            end
            --ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
            if item:GetCurrentCharges() == get_charge_ammount(caster) then
                item.blink_next_charge = GameRules:GetGameTime() + get_charge_time(caster)
            end
            item:SetCurrentCharges(item:GetCurrentCharges()-1)
            if item:GetCurrentCharges() == 0 then
                item:StartCooldown(item.blink_next_charge - GameRules:GetGameTime())
            end
        else 
            local pID = caster:GetPlayerID() 
            FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You must be invoker to use this item." } )
        end
    end
end

--[[function get_octarine_multiplier(caster)
    local octarine_multiplier = 1
    for itemSlot = 0, 5, 1 do
        local Item = caster:GetItemInSlot( itemSlot )
        if Item ~= nil and Item:GetName() == "item_octarine_core" then
            if octarine_multiplier > 0.75 then
                octarine_multiplier = 0.75
            end
        end
        if Item ~= nil and Item:GetName() == "item_octarine_core2" then
            if octarine_multiplier > 0.67 then
                octarine_multiplier = 0.67
            end
        end
        if Item ~= nil and Item:GetName() == "item_octarine_core3" then
            if octarine_multiplier > 0.5 then
                octarine_multiplier = 0.5
            end
        end
        if Item ~= nil and Item:GetName() == "item_octarine_core4" then
            if octarine_multiplier > 0.33 then
                octarine_multiplier = 0.33
            end
        end
    end
    return octarine_multiplier
end]]--

function get_charge_time(caster)
    local level = caster:GetLevel()
    local octarine_multiplier = get_octarine_multiplier(caster)
    local time = (30 * (1/level)^0.2)*octarine_multiplier
    return time
end

function get_charge_ammount(caster)
    local level = caster:GetLevel()
    local charge = math.ceil (10 * ((25+level)/100)^1.05)
    return charge
end