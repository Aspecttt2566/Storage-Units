RPC.register('aspect_storageunits:fetchData', function(source, array)
    local src = source
    local user = exports['aspect_framework']:GetModule('GetPlayer')(src)
    local query = MySQL.query.await('SELECT * FROM _storageunits WHERE id = @STORAGE_ID', {
        ['@STORAGE_ID'] = array.STORAGEUNIT_ID
    })
    local ACCESS = json.decode(query[1].access)

    if array.TYPE == 'Owner' then
        for k, v in ipairs(ACCESS) do
            if v.TYPE == 'Owner' and v.STATE_ID == user['PlayerData']['id'] then
                return v.STATE_ID
            end
        end
    elseif array.TYPE == 'Member' then
        for k, v in ipairs(ACCESS) do
            if v.TYPE == 'Member' or v.TYPE == 'Owner' and v.STATE_ID == user['PlayerData']['id'] then
                return v.STATE_ID
            end
        end
    end
end)

RPC.register('aspect_storageunits:fetchUnitAccess', function(source, array)
    local src = source
    local TABLE = {}
    local CONTEXT_ID = 0
    local user = exports['aspect_framework']:GetModule('GetPlayer')(src)
    local query = MySQL.query.await('SELECT * FROM _storageunits WHERE id = @STORAGE_ID', {
        ['@STORAGE_ID'] = array.ID
    })
    local ACCESS = json.decode(query[1].access)

    for k, v in ipairs(ACCESS) do
        local CHAR_DATA = MySQL.query.await('SELECT * FROM characters WHERE id = @STATE_ID', {
            ['@STATE_ID'] = v.STATE_ID
        })
        CONTEXT_ID = CONTEXT_ID + 1
        if CHAR_DATA[1].first_name .. ' ' .. CHAR_DATA[1].last_name == user['PlayerData']['first_name'] .. ' ' .. user['PlayerData']['last_name'] then
            disabledStatus = true
        else
            disabledStatus = false
        end
        table.insert(TABLE, {
            title = CHAR_DATA[1].first_name .. ' ' .. CHAR_DATA[1].last_name,
            description = 'Remove access for this user. State ID: ' .. v.STATE_ID,
            event = 'aspect_storageunits:removeAccess',
            disabled = disabledStatus,
            server = true,
            args = {
                ['id'] = array.ID,
                ['STATE_ID'] = v.STATE_ID
            }
        })
    end

    TriggerClientEvent('aspect_ui:openContext', src, {
        title = 'Mange Access',
        data = TABLE
    })
end)

RegisterServerEvent('aspect_storageunits:removeAccess')
AddEventHandler('aspect_storageunits:removeAccess', function(args)
    local src = source
    local DATA = MySQL.query.await("SELECT * FROM _storageunits WHERE id = @STORAGEUNIT_ID", {
        ["@STORAGEUNIT_ID"] = args.id
    })

    local UNIT_ACCESS = json.decode(DATA[1].access)
    for k, v in pairs(UNIT_ACCESS) do
        if tonumber(v.STATE_ID) == tonumber(args.STATE_ID) then
            table.remove(UNIT_ACCESS, k)
            MySQL.query.await("UPDATE _storageunits SET access = @access WHERE id = @STORAGEUNIT_ID", {
                ["@access"] = json.encode(UNIT_ACCESS),
                ["@STORAGEUNIT_ID"] = args.id
            })
            local CHAR_INFO = MySQL.query.await('SELECT * FROM characters WHERE id = @STATE_ID', {['@STATE_ID'] = v.STATE_ID})
            TriggerClientEvent('aspect_ui:sentNotification', src, 'error', 'Revoked ' .. CHAR_INFO[1].first_name .. ' ' .. CHAR_INFO[1].last_name .. ', [State ID: ' .. v.STATE_ID .. '] access from storage unit ' .. args.id, 5000)
        end
    end
end)

RPC.register('aspect_storageunits:giveAccess', function(source, array)
    local src = source
    local DATA = MySQL.query.await("SELECT * FROM _storageunits WHERE id = @STORAGEUNIT_ID", {
        ["@STORAGEUNIT_ID"] = array.id
    })
    local CHAR_INFO = MySQL.query.await('SELECT * FROM characters WHERE id = @STATE_ID', {
        ['@STATE_ID'] = array.STATE_ID
    })
    if CHAR_INFO[1] == nil then print('[ERROR] State ID doesnt exist.. ' .. array.STATE_ID) return end
    STORAGEUNIT_ACCESS = json.decode(DATA[1].access)

    NEW_DATA = {
        STATE_ID = array.STATE_ID,
        TYPE = 'Member',
    }
    table.insert(STORAGEUNIT_ACCESS, NEW_DATA)
    MySQL.query.await("UPDATE _storageunits SET access = @ACCESS WHERE id = @STORAGEUNIT_ID", {
        ["@ACCESS"] = json.encode(STORAGEUNIT_ACCESS),
        ["@STORAGEUNIT_ID"] = array.id
    })
    TriggerClientEvent('aspect_ui:sentNotification', src, 'success', 'Granted ' .. CHAR_INFO[1].first_name .. ' ' .. CHAR_INFO[1].last_name .. ' access to storage unit (' .. array.id .. ').', 5000)
end)

RPC.register('aspect_storageunits:fetchCode', function(source, array)
    local src = source
    local query = MySQL.query.await('SELECT * FROM _storageunits WHERE id = @STORAGE_ID', {
        ['@STORAGE_ID'] = array.STORAGEUNIT_ID
    })

    return query[1].passcode
end)

RPC.register('aspect_storageunits:updateCode', function(source, array)
    local data = MySQL.query.await('UPDATE _storageunits SET passcode = @CODE WHERE id = @STORAGE_ID', {
        ['@CODE'] = array.newCode,
        ['@STORAGE_ID'] = array.STORAGE_ID
    })

    return data
end)

RPC.register('aspect_storageunits:fetchUnitInfo', function(source, array)
    local query = MySQL.query.await('SELECT * FROM _storageunits WHERE id = @STORAGEUNIT_ID', {
        ['@STORAGEUNIT_ID'] = array.id
    })

    local ACCESS = json.decode(query[1].access)
    for k, v in ipairs(ACCESS) do
        if v.TYPE == 'Owner' then
            local CHARINFO = MySQL.query.await('SELECT * FROM characters WHERE id = @CHARACTER_ID', {
                ['@CHARACTER_ID'] = v.STATE_ID
            })

            return CHARINFO[1].first_name .. ' ' .. CHARINFO[1].last_name
        end
    end
end)

RPC.register('aspect_storageunits:sellUnit', function(source, array)
    local src = source

    for x, y in pairs(GetPlayers()) do
        local PLAYER = exports['aspect_framework']:GetModule("GetPlayer")(tonumber(y))

        if PLAYER['PlayerData']['id'] == tonumber(array.STATE_ID) then
            TriggerClientEvent('aspect_phone:notification:storageUnitOffer', tonumber(y), {['UNIT_ID'] = array.id, ['HEADER'] = 'Storage Unit Offer', ['PRICE'] = array.PRICE, ['STATE_ID'] = array.STATE_ID, ['TYPE'] = array.TYPE})
        end
    end
end)

RPC.register('aspect_storageunits:attemptBuy', function(source, ARRAY)
    local src = source
    local STORAGEUNIT_ACCESS = {}
    local user = exports['aspect_framework']:GetModule('GetPlayer')(src)
    local query = MySQL.query.await('SELECT * FROM _storageunits WHERE id = @STORAGE_ID', {
        ['@STORAGE_ID'] = ARRAY.UNIT_ID
    })

    if tonumber(ARRAY.PRICE) <= exports['aspect_framework']:GetBalance(src) then
        if ARRAY.TYPE == 'Business' then
            exports['aspect_banking']:AddBusinessMoney('PaiNLess', tonumber(ARRAY.PRICE))
        else
            for x, y in pairs(GetPlayers()) do
                for k, v in pairs(json.decode(query[1].access)) do
                    local PLAYER = exports['aspect_framework']:GetModule("GetPlayer")(tonumber(y))
        
                    if PLAYER['PlayerData']['id'] == tonumber(v.STATE_ID) then
                        exports["aspect_framework"]:AddCash(tonumber(y), tonumber(ARRAY.PRICE))
                        TriggerClientEvent('aspect_ui:sentNotification', tonumber(y), 'success', 'You sold storage unit ' .. ARRAY.UNIT_ID .. ' for $' .. tonumber(ARRAY.PRICE).. '.', 5000)
                    end
                end
            end
        end
            
        exports["aspect_framework"]:RemoveBank(src, tonumber(ARRAY.PRICE))

        NEW_DATA = {
            TYPE = 'Owner',
            STATE_ID = tonumber(ARRAY.STATE_ID),
        }
        table.insert(STORAGEUNIT_ACCESS, NEW_DATA)
        MySQL.query.await("UPDATE _storageunits SET access = @ACCESS WHERE id = @STORAGEUNIT_ID", {
            ["@ACCESS"] = json.encode(STORAGEUNIT_ACCESS),
            ["@STORAGEUNIT_ID"] = ARRAY.UNIT_ID
        })
        TriggerClientEvent('aspect_ui:sentNotification', src, 'info', 'Successfully purchased storage unit.', 5000)
    else
        TriggerClientEvent('aspect_ui:sentNotification', src, 'error', 'Not enough money', 5000)
    end
end)

RPC.register('aspect_storageunits:logRaid', function(source)
    local src = source
    exports['aspect_framework']:sendToDiscord('Cop Raided Storage Unit', "Cop Steam Name: " .. GetPlayerName(src) .. '\n Character Name: ' .. user['PlayerData']['first_name'] .. ' ' .. user['PlayerData']['last_name'] .. '\n Unit ID: ' ..array.STORAGEUNIT_ID .. '\n Time & Date: ' .. os.date("%H:%M:%S") .. ' | ' .. os.date("%x"), "https://discord.com/api/webhooks/1104050133416542299/6VRrtX0Pzf9bs90fhq3FrZprntlMBW01mFBHLxQ_epWKWadjpDyxVw8o3qG8MAUvDFxV")
end)