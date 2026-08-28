JobAccess = {}

function JobAccess.HasJob()
    return exports.qbx_core:HasGroup(Config.JobName)
end

function JobAccess.IsOnDutyClient()
    local job = exports.qbx_core:GetPlayerData().job
    return job and job.name == Config.JobName and job.onduty == true
end
