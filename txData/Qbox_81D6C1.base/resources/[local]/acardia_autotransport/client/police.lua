local function isPoliceOnDuty()
    local job = exports.qbx_core:GetPlayerData().job
    if not job or not job.onduty then return false end
    return job.name == 'police' or job.name == 'bcso' or job.name == 'sasp'
end

local function openBoloMenu()
    if not isPoliceOnDuty() then return end
    local list = lib.callback.await('acardia_autotransport:getBoloList', false) or {}
    local options = {}

    if #list == 0 then
        options[#options + 1] = { title = 'Aucun vehicule recherche', disabled = true }
    else
        for _, row in ipairs(list) do
            options[#options + 1] = {
                title = ('%s · %s'):format(row.vehicle_label or row.vehicle_model, row.plate),
                description = ('Chauffeur: %s · %s'):format(row.driver_name or '?', row.last_coords or 'GPS inconnu'),
                onSelect = function()
                    lib.registerContext({
                        id = 'at_bolo_action',
                        title = row.plate,
                        options = {
                            {
                                title = 'Marquer retrouve / clos',
                                onSelect = function()
                                    lib.callback.await('acardia_autotransport:resolveTheft', false, row.id)
                                    lib.notify({ description = Locales.bolo_updated, type = 'success' })
                                end,
                            },
                        },
                    })
                    lib.showContext('at_bolo_action')
                end,
            }
        end
    end

    lib.registerContext({ id = 'at_bolo_list', title = 'BOLO Auto Import Export', options = options })
    lib.showContext('at_bolo_list')
end

RegisterCommand('boloauto', openBoloMenu, false)

exports('OpenBoloMenu', openBoloMenu)
