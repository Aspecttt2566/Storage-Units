Citizen.CreateThread(function()
    CreateStorageUnits(Config.StorageUnits)
end)

CreateStorageUnits = function(CONFIG_DATA)
    for k, v in ipairs(CONFIG_DATA) do
        exports['aspect_target']:AddBoxZone(v.UNIT_NAME, v.polyVector3, v.polyNum1AfterVector3, v.polyNum2AfterVector3, {
            name = v.UNIT_NAME,
            heading = v.polyHeading,
            minZ = v.polyMinZ,
            maxZ = v.polyMaxZ,
        }, {
            options = {
                {
                    icon = "fas fa-warehouse", 
                    label = "View Storage Unit " .. v.id,
                    action = function()
                        local DATA = RPC.execute('aspect_storageunits:fetchData', {
                            ['STORAGEUNIT_ID'] = v.id,
                            ['TYPE'] = 'Owner'
                        })
                        local CODE = RPC.execute('aspect_storageunits:fetchCode', {
                            ['STORAGEUNIT_ID'] = v.id
                        })

                        local CONTEXT = {
                            {
                                title = 'Open Storage Container',
                                description = 'Storage Unit #' .. v.id .. ' Capacity (200)',
                                event = 'aspect_storageunits:enterPincode',
                                parameters = {
                                    ['UNIT_ID'] = v.id,
                                    ['UNIT_NAME'] = v.UNIT_NAME,
                                    ['CODE'] = CODE,
                                }
                            }
                        }

                        if exports['aspect_resources']:fetchData('cid') == DATA then
                            table.insert(CONTEXT, {
                                title = 'Change Password',
                                description = 'Change the password of the storage unit.',
                                event = 'aspect_storageunits:changePassword',
                                parameters = {
                                    ['UNIT_ID'] = v.id
                                }
                            })

                            table.insert(CONTEXT, {
                                title = 'Storage Unit Actions',
                                event = 'aspect_storageunits:actionsMenu',
                                parameters = {
                                    ['UNIT_ID'] = v.id
                                }
                            })
                        end

                        TriggerEvent('aspect_ui:openContext', {
                            title = 'Storage Unit',
                            data = CONTEXT
                        })
                    end,
                },
                {
                    icon = "fas fa-dollar-sign", 
                    label = "Sell Unit",
                    action = function()
                        local UNIT_INFO = RPC.execute('aspect_storageunits:fetchUnitInfo', {['id'] = v.id})

                        if UNIT_INFO == nil then disabledStatus = false contextHeader = 'Not owned by anyone at this time.' else disabledStatus = true contextHeader = 'Currently owned by: ' .. UNIT_INFO end
                        local CONTEXT = {
                            {
                                title = contextHeader
                            },
                            {
                                title = 'Sell storage unit.',
                                disabled = disabledStatus,
                                event = 'aspect_storageunits:sellUnit',
                                parameters = {
                                    ['id'] = v.id,
                                }
                            }
                        }

                        TriggerEvent('aspect_ui:openContext', {
                            title = 'Sell Storage Unit',
                            data = CONTEXT
                        })
                    end,
                    canInteract = function()
                        return exports['aspect_phone']:IsEmployedAt('PaiNLess')
                    end,
                },
            },
            distance = 2.0
        })
    end
end

RegisterNetEvent('aspect_storageunits:actionsMenu')
AddEventHandler('aspect_storageunits:actionsMenu', function(args)
    local DATA = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.UNIT_ID, ['TYPE'] = 'Owner'})

    if exports['aspect_resources']:fetchData('cid') == DATA then
        local CONTEXT = {
            {
                title = 'Give Access',
                event = 'aspect_storageunits:giveAccess',
                parameters = {
                    ['id'] = args.UNIT_ID
                }
            },
            {
                title = 'Remove Access',
                icon = 'fas fa-user-minus',
                event = 'aspect_storageunits:removeAccess',
                parameters = {
                    ['id'] = args.UNIT_ID
                }
            },
            {
                title = 'Sell Storage Unit',
                event = 'aspect_storageunits:sellUnit',
                parameters = {
                    ['id'] = args.UNIT_ID,
                    ['TYPE'] = "Player"
                }
            }
        }

        TriggerEvent('aspect_ui:openContext', {
            title = 'Storage Unit Actions',
            data = CONTEXT
        })
    end
end)

RegisterNetEvent('aspect_storageunits:giveAccess')
AddEventHandler('aspect_storageunits:giveAccess', function(args)
    local DATA = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.id, ['TYPE'] = 'Owner'})

    if exports['aspect_resources']:fetchData('cid') == DATA then
        local INPUT = exports['aspect_dialog']:AmityInputDialog(("State ID"),{
            {
                type = 'input',
                label = 'State ID',
                icon = 'id-card',
                required = true,
            },
        })

        if INPUT == nil then return end
        RPC.execute('aspect_storageunits:giveAccess', {['STATE_ID'] = INPUT[1], ['id'] = args.id})
    end
end)

RegisterNetEvent('aspect_storageunits:removeAccess')
AddEventHandler('aspect_storageunits:removeAccess', function(args)
    local DATA = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.id, ['TYPE'] = 'Owner'})

    if exports['aspect_resources']:fetchData('cid') == DATA then
        RPC.execute('aspect_storageunits:fetchUnitAccess', {['ID'] = args.id})
    end
end)

RegisterNetEvent('aspect_storageunits:changePassword')
AddEventHandler('aspect_storageunits:changePassword', function(args)
    local DATA = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.UNIT_ID, ['TYPE'] = 'Owner'})

    if exports['aspect_resources']:fetchData('cid') == DATA then
        local INPUT = exports['aspect_dialog']:AmityInputDialog(("Storage New Code"),{
            {
                type = 'input',
                label = 'New Passcode',
                icon = 'lock',
                required = true,
                password = true,
            },
        })

        if INPUT == nil then return end
        local PASSWORD = RPC.execute('aspect_storageunits:updateCode', {['newCode'] = INPUT[1], ['STORAGE_ID'] = args.UNIT_ID})
        if PASSWORD then
            TriggerEvent('aspect_ui:sentNotification', 'error', 'Updated password for storage unit ' .. args.UNIT_ID .. '.', 5000)
        else
            TriggerEvent('aspect_ui:sentNotification', 'error', 'Failed to update password for storage unit ' .. args.UNIT_ID .. '.', 5000)
        end
    end
end)

RegisterNetEvent('aspect_storageunits:enterPincode')
AddEventHandler('aspect_storageunits:enterPincode', function(args)
    local DATA = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.UNIT_ID, ['TYPE'] = 'Member'})
    local ACCESS = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.UNIT_ID, ['TYPE'] = 'Owner'})
    local POLICE = RPC.execute('aspect_jobs:policeFetchData')
    local JOB = RPC.execute('aspect_doors:fetchJob')

    if JOB == 'Police' then
        if POLICE[1].rank >= 7 then
            RPC.execute('aspect_storageunits:logRaid')
            exports['aspect_inventory']:OpenInventory('1', 'STORAGE_UNIT_' .. array.STORAGEUNIT_ID)
            return
        end
    end

    local INPUT = exports['aspect_dialog']:AmityInputDialog(("Storage Unit Code"),{
        {
            type = 'input',
            label = 'Passcode',
            icon = 'lock',
            required = true,
            password = true,
        },
    })

    if INPUT == nil then return end
    if args.CODE == INPUT[1] then
        if exports['aspect_resources']:fetchData('cid') == DATA or exports['aspect_resources']:fetchData('cid') == ACCESS then
            TriggerEvent('aspect_ui:sentNotification', 'info', 'Access granted', 5000)
            exports['aspect_inventory']:OpenInventory('1', 'STORAGE_UNIT_' .. array.STORAGEUNIT_ID)
        else
            TriggerEvent('aspect_ui:sentNotification', 'error', 'Access denied', 5000)
        end
    else
        TriggerEvent('aspect_ui:sentNotification', 'error', 'Access denied', 5000)
    end
end)

RegisterNetEvent('aspect_storageunits:sellUnit')
AddEventHandler('aspect_storageunits:sellUnit', function(args)
    local DATA = RPC.execute('aspect_storageunits:fetchData', {['STORAGEUNIT_ID'] = args.id, ['TYPE'] = 'Owner'})

    if exports['aspect_phone']:IsEmployedAt('PaiNLess') or exports['aspect_resources']:fetchData('cid') == DATA then
        
        local INPUT = exports['aspect_dialog']:AmityInputDialog(("Sell Storage Unit"),{
            {
                type = 'input',
                label = 'State ID',
                icon = 'id-card',
                required = true,
            },
            {
                type = 'select',
                label = "Storage Unit Price",
                options = {
                    {
                        value = 50000,
                        label = 'Sell unit id: ' .. args.id .. ' for $50,000'
                    },
                    {
                        value = 75000,
                        label = 'Sell unit id: ' .. args.id .. ' for $75,000'
                    },
                    {
                        value = 100000,
                        label = 'Sell unit id: ' .. args.id .. ' for $100,000'
                    }
                }
            },
        })
        
        if INPUT == nil then return end
        if args.TYPE == nil then TYPE = 'Business' else TYPE = args.TYPE end
        RPC.execute('aspect_storageunits:sellUnit', {['id'] = args.id, ['STATE_ID'] = INPUT[1], ['PRICE'] = INPUT[2], ['TYPE'] = TYPE})
    end
end)