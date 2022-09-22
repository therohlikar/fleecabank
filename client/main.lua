local isOpened = false

RegisterCommand("open", function(source, args)
    if isOpened then
        isOpened = false
    else
        isOpened = true
        TriggerServerEvent("fleecabank:open", false)
    end
end)

RegisterCommand("openatm", function(source, args)
    if isOpened then
        isOpened = false
    else
        isOpened = true
        TriggerServerEvent("fleecabank:open", true)
    end
end)

RegisterCommand("payrent", function(source, args)
    TriggerServerEvent("fleecabank:paymain", 20)
end)

--[[RegisterCommand("payfine", function(source, args)
    TriggerServerEvent("fleecabank:payfine")
end)]]

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
    function(data, count, atm)
        openBank(data, count, atm)
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
            action = "refreshDetails",
            account = data,
            newAccount = newAccount
        })
    end
end
function updateAccounts(count, data, delete)
    if isOpened then
        SendNUIMessage({
            action = "show",
            accounts = data,
            settings = {
                accountsLeft = Config.maxAvailableAccounts - count
            }
        })
    end
end
function openBank(data, count, atm)
    SendNUIMessage({
        action = "show",
        accounts = data.accounts,
        settings = {
            accountsLeft = Config.maxAvailableAccounts - count,
            maxAccounts = Config.maxAvailableAccounts,
            job = {
                name = "lspd",
                grade = 1
            },
            charId = data.charId
        },
        atm = atm
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
        TriggerServerEvent("fleecabank:create", (data.value == nil and "CHANGE ME" or data.value))
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

--[[
RegisterNetEvent("fleecabank:paymentmethod")
AddEventHandler("fleecabank:paymentmethod",
    function(data, methods)
        WarMenu.CreateMenu(
            "payment_methods",
            data.title,
            "Zvolte způsob úhrady (" .. getFormattedCurrency(data.amount) .. ")"
        )
        WarMenu.OpenMenu("payment_methods")
        WarMenu.CreateSubMenu("method_account", "payment_methods", "Zvolte bankovní účet")
        WarMenu.CreateSubMenu("method_card", "payment_methods", "Zvolte platební kartu v ruce")

        while true do
            if WarMenu.IsMenuOpened("payment_methods") then
                if methods.cash and WarMenu.Button("Zaplatit hotovostí") then
                    TriggerServerEvent("fleecabank:choosepaymentmethod", data, "cash")
                    WarMenu.CloseMenu()
                end

                if methods.account then
                    WarMenu.MenuButton("Uhradit převodem z účtu", "method_account")
                end

                if methods.card then
                    WarMenu.MenuButton("Uhradit platební kartou", "method_card")
                end
                WarMenu.Display()
            elseif methods.account and WarMenu.IsMenuOpened("method_account") then
                for k, v in pairs(methods.data.account) do
                    if WarMenu.Button(v.data.account_name, k) then
                        TriggerServerEvent("fleecabank:choosepaymentmethod", data, "account", k)
                        WarMenu.CloseMenu()
                    end
                end

                WarMenu.Display()
            elseif methods.card and WarMenu.IsMenuOpened("method_card") then

                WarMenu.Display()
            else
                WarMenu.CloseMenu()
                break
            end

            Citizen.Wait(0)
        end
    end
)
]]

--[[RegisterNetEvent("fleecabank:choosepaymentmethod")
AddEventHandler("fleecabank:choosepaymentmethod",
    function(done, data, methodType, methodId)
        if done == "done" then
            print("YAAAAY", methodType, methodId, data.amount)
        else
            print("SAD FACE", done, methodType, methodId, data.amount)
        end
    end
)]]

function getFormattedCurrency(value)
    local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
    return "$" .. left .. (num:reverse():gsub('(%d%d%d)', '%1' .. ","):reverse()) .. right
end