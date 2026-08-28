lib.locale()

RegisterNUICallback('npwd:qbx_mail:getMail', function(_, cb)
	local mail = lib.callback.await('npwd:qbx_mail:getMail', false)
	cb({ status = 'ok', data = mail })
end)

RegisterNUICallback('npwd:qbx_mail:updateRead', function(data, cb)
	lib.callback.await('npwd:qbx_mail:updateRead', false, data)
	cb({ status = 'ok' })
end)

RegisterNUICallback('npwd:qbx_mail:deleteMail', function(data, cb)
	local mailDeleted = lib.callback.await('npwd:qbx_mail:deleteMail', false, data)
	cb({ status = (not mailDeleted or mailDeleted.affectedRows == 0) and 'error' or 'ok' })
end)

RegisterNUICallback('npwd:qbx_mail:updateButton', function(data, cb)
	TriggerEvent(data.button.buttonEvent, data.button.buttonData)
	local buttonUpdated = lib.callback.await('npwd:qbx_mail:updateButton', false, data.mailid)
	cb({ status = buttonUpdated == 0 and 'error' or 'ok' })
end)

RegisterNetEvent('npwd:qbx_mail:newMail', function(data)
	exports.npwd:sendNPWDMessage('npwd_qbx_mail', 'newMail', {data})
	Wait(100)
	exports.npwd:createNotification({
		notisId = 'npwd:newmail',
		appId = 'npwd_qbx_mail',
		content = locale('newmail'),
		keepOpen = false,
		duration = 5000,
		path = '/npwd_qbx_mail',
	})
end)

RegisterNetEvent('npwd_qbx_mail:testMail', function()
	local email = {
		sender = 'Mr. Attenborough',
		subject = 'Test Email',
		message = 'This is a test of our electronic mail system',
	}
    TriggerServerEvent('qb-phone:server:sendNewMail', email)
end)