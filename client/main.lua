local isOpened = false
local ESX = nil
local playerData = {}

CreateThread(function()
    while ESX == nil do
        ESX = exports["rflx_extended"]:getSharedObject()
        Wait(10)
    end

    while exports["rflx_multichar"]:getChar() == nil do
        Wait(100)
    end

    playerData = ESX.GetPlayerData()
end)

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

RegisterCommand("payfine", function(source, args)
    openPaymentMethod({
        amount = 500,
        title = "ŠKOLKA PRO VOJTÍKA"
    },
    function()
        print("SUCCESS")
    end,
    function()
        print("FAILURE")
    end)
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
    function(done, accounts)
        print("DELETE", done)

        updateAccounts(accounts)
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
    function(done, newAccount, accounts)
        print("CREATE", done)

        update(newAccount, accounts)
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

function update(data, accounts)
    if isOpened  then
        SendNUIMessage({
            action = "refreshDetails",
            account = data,
            accounts = accounts
        })
    end
end
function updateAccounts(accounts)
    if isOpened then
        SendNUIMessage({
            action = "show",
            accounts = accounts
        })
    end
end
function openBank(data, count, atm)
    SendNUIMessage({
        action = "show",
        accounts = data.accounts,
        settings = {
            accountsLeft = Config.maxAvailableAccounts - count,
            charId = data.charId
        },
        atm = atm
    })
    SetNuiFocus(true, true)
end
function openPaymentMethod(data, success, failure)
    ESX.TriggerServerCallback('fleecabank:openpaymentmethod', function(methods)
        if methods then
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
                    if Config.defaultPaymentMethodsAllowed.cash and WarMenu.Button("Zaplatit hotovostí") then
                        data.methodType = "cash"
                        WarMenu.CloseMenu()
                    end

                    if Config.defaultPaymentMethodsAllowed.account then
                        WarMenu.MenuButton("Uhradit převodem z účtu", "method_account")
                    end

                    if Config.defaultPaymentMethodsAllowed.card then
                        WarMenu.MenuButton("Uhradit platební kartou", "method_card")
                    end
                    WarMenu.Display()
                elseif Config.defaultPaymentMethodsAllowed.account and WarMenu.IsMenuOpened("method_account") then
                    for k, v in pairs(methods.accounts) do
                        if WarMenu.Button(v.data.account_name, k) then
                            data.methodType = "account"
                            data.methodId = k
                            WarMenu.CloseMenu()
                        end
                    end

                    WarMenu.Display()
                elseif Config.defaultPaymentMethodsAllowed.card and WarMenu.IsMenuOpened("method_card") then
                    -- to do
                    WarMenu.Display()
                else
                    WarMenu.CloseMenu()
                    break
                end

                Citizen.Wait(0)
            end
            if data.methodType then
                ESX.TriggerServerCallback('fleecabank:choosepaymentmethod', function(done)
                    if done == "done" then
                        success()
                    else
                        failure()
                    end
                end, data)
            else
                failure()
            end
        end
    end)
end

RegisterNUICallback("closepanel", function(data, cb) close() end)

function close()
    SendNUIMessage({action = "hide"})
    SetNuiFocus(false, false)
    isOpened = false
end

RegisterNUICallback("action", function(data, cb)
    if data.action == "createaccount" then
        TriggerServerEvent("fleecabank:create", (data.account_name == nil and "CHANGE ME" or data.account_name))
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

function getFormattedCurrency(value)
    local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
    return "$" .. left .. (num:reverse():gsub('(%d%d%d)', '%1' .. ","):reverse()) .. right
end