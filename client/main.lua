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


RegisterNetEvent("fleecabank:open")
AddEventHandler("fleecabank:open",
    function(currentAccounts, count)
        for k, v in pairs(currentAccounts) do
            print(k, v.owner, v.balance, count)
        end

        openBank(currentAccounts, count)
    end
)

function openBank(data, count)
    SendNUIMessage({
        action = "show",
        accounts = data,
        settings = {
            count = count,
            maxAccounts = Config.maxAvailableAccounts,
            job = {
                name = "lspd",
                grade = 1
            },
            charId = 2
        }
    })
    SetNuiFocus(true, true)
end

