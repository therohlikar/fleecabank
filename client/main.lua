local isOpened = false

RegisterCommand("open", function(source, args)
    if isOpened then
        isOpened = false
    else
        isOpened = true
        TriggerServerEvent("fleecabank:open")
    end
end)

RegisterCommand("payrent", function(source, args)
    TriggerServerEvent("fleecabank:paymain", 20)
end)

RegisterNetEvent("fleecabank:paymain")
AddEventHandler("fleecabank:paymain",
    function(done)
        print(done)
    end
)
RegisterNetEvent("fleecabank:rename")
AddEventHandler("fleecabank:rename",
    function(done, account)
        print(done, "NEW NAME", account.data.account_name)

        update(account)
    end
)

RegisterNetEvent("fleecabank:transfer")
AddEventHandler("fleecabank:transfer",
    function(done, account)
        print(done, "TRANSFER - NEW BALANCE", account.balance)

        update(account)
    end
)

RegisterNetEvent("fleecabank:delete")
AddEventHandler("fleecabank:delete",
    function(done, count, accounts)
        print("DELETE", done)

        updateAccounts(count, accounts, true)
    end
)

RegisterNetEvent("fleecabank:cash")
AddEventHandler("fleecabank:cash",
    function(done, amount, action, account)
        print("CASH", done, action, amount)

        update(account)
    end
)

RegisterNetEvent("fleecabank:create")
AddEventHandler("fleecabank:create",
    function(done, newAccount)
        print("CREATE", done)

        update(newAccount, true)
    end
)

RegisterNetEvent("fleecabank:open")
AddEventHandler("fleecabank:open",
    function(data, count)
        openBank(data, count)
    end
)

RegisterNetEvent("fleecabank:syncAccount")
AddEventHandler("fleecabank:syncAccount",
    function(account)
        update(account)
    end
)

function update(data, newAccount)
    if isOpened  then
        SendNUIMessage({
            action = "updateaccount",
            account = data,
            newAccount = newAccount
        })
    end
end
function updateAccounts(count, data, delete)
    if isOpened then
        SendNUIMessage({
            action = "updateaccounts",
            accounts = data,
            count = count,
            delete = delete
        })
    end
end
function openBank(data, count)
    SendNUIMessage({
        action = "show",
        accounts = data.accounts,
        settings = {
            count = count,
            maxAccounts = Config.maxAvailableAccounts,
            job = {
                name = "lspd",
                grade = 1
            },
            charId = data.charId
        }
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback("closepanel", function(data, cb) close() end)

function close()
    SendNUIMessage({action = "hide"})
    SetNuiFocus(false, false)
    isOpened = false
end

RegisterNUICallback("action", function(data, cb)
    if data.action == "createaccount" then
        TriggerServerEvent("fleecabank:create")
    elseif data.action == "syncaccount" then
        TriggerServerEvent("fleecabank:syncAccount", data.account)
    elseif data.action == "rename" then
        TriggerServerEvent("fleecabank:rename", data.account, data.value)
    elseif data.action == "delete" then
        TriggerServerEvent("fleecabank:delete", data.account)
    elseif data.action == "transfer" then
        TriggerServerEvent("fleecabank:transfer", tonumber(data.account), tonumber(data.target), tonumber(data.value))
    elseif data.action == "cash" then
        TriggerServerEvent("fleecabank:cash", data.account, tonumber(data.value), data.subaction)
    end
end)