local accounts = {}
local _tempCharId = 2 -- remove me my beauty

--local ESX = exports["rflx_extended"]:getSharedObject()

--local xPlayer = ESX.GetPlayerFromId(client)
--if xPlayer then
--    local identifier = xPlayer.char
-- end


MySQL.ready(function()
    Wait(5)

    MySQL.Async.fetchAll(
        "SELECT * FROM bank_accounts",
        {},
        function(result)
            local _count = 0
            for i=1, #result do
                accounts[result[i].number] = {
                    number = result[i].number,
                    owner = json.decode(result[i].owner),
                    balance = result[i].balance,
                    main = result[i].main,
                    data = json.decode(result[i].data),
                    changed = false
                }
                _count = _count + 1
            end

            print("FLEECABANK: BANK ACCOUNTS RESTORED ", _count)
        end
    )

    SetTimeout(25000, saveAccounts)
end)

-- check is close, or it will probably could be opened by some random dick fuck (I mean, it will just open his bank account, but why not to ban that prick)
RegisterNetEvent("fleecabank:open")
AddEventHandler("fleecabank:open",
    function(atm)
        local client = source
        --local xPlayer = ESX.GetPlayerFromId(client)
        --if xPlayer then
        --    local identifier = xPlayer.char
            local count, accessedAccounts = 0, {}
            count, accessedAccounts.accounts = getAccountsByOwner(_tempCharId) -- getAccountsByOwner(identifier)
            accessedAccounts.charId = _tempCharId -- identifier
        -- end
        TriggerClientEvent("fleecabank:open", client, accessedAccounts, count, atm)
    end
)

RegisterNetEvent("fleecabank:create")
AddEventHandler("fleecabank:create",
    function()
        local client = source
        --local xPlayer = ESX.GetPlayerFromId(client)
        --if xPlayer then
            -- local identifier = xPlayer.char
            -- create(identifier,
            local done, newAccount = create(_tempCharId, 0, os.time(), {
                account_name = "CHANGE NAME",
                account_created = os.time()
            }, false)
        --end
        TriggerClientEvent("fleecabank:create", client, done, newAccount)
    end
)

RegisterNetEvent("fleecabank:paymain")
AddEventHandler("fleecabank:paymain",
    function(amount)
        local client = source
        --local xPlayer = ESX.GetPlayerFromId(client)
        --if xPlayer then
            -- local identifier = xPlayer.char
            -- removeFunds(getMainAccountByOwner(identifier).number, amount, true)
            local done = removeFunds(getMainAccountByOwner(client).number, amount, true)
        --end
        TriggerClientEvent("fleecabank:paymain", client, done, amount)
    end
)

RegisterNetEvent("fleecabank:transfer")
AddEventHandler("fleecabank:transfer",
    function(sourceAccount, targetAccount, amount)
        local client = source

        local done = transferFunds(sourceAccount, targetAccount, amount, true)
        TriggerClientEvent("fleecabank:transfer", client, done, accounts[sourceAccount])
    end
)

RegisterNetEvent("fleecabank:rename")
AddEventHandler("fleecabank:rename",
    function(sourceAccount, val)
        local client = source

        local done = updateAccountData(sourceAccount, "account_name", val)
        TriggerClientEvent("fleecabank:rename", client, done, accounts[sourceAccount])
    end
)

RegisterNetEvent("fleecabank:delete")
AddEventHandler("fleecabank:delete",
    function(sourceAccount)
        local client = source

        --local xPlayer = ESX.GetPlayerFromId(client)
        --if xPlayer then
        --    local identifier = xPlayer.char
        local done = delete(sourceAccount)
        local count, accounts = getAccountsByOwner(_tempCharId) -- getAccountsByOwner(identifier)
        --end
        TriggerClientEvent("fleecabank:delete", client, done, count, accounts)
    end
)

RegisterNetEvent("fleecabank:cash")
AddEventHandler("fleecabank:cash",
    function(sourceAccount, amount, action)
        local client = source

        --local xPlayer = ESX.GetPlayerFromId(client)
        --if xPlayer then
        --    local identifier = xPlayer.char


        local done = ""
        if action == "withdraw" then
            done = removeFunds(sourceAccount, amount, true)
            if done == "done" then
                -- xPlayer.addMoney(amount)
            end
        elseif action == "deposit" then
                --if amount >= xPlayer.getMoney() then
                done = addFunds(sourceAccount, amount, true)
                if done == "done" then
                    -- xPlayer.removeMoney(amount)
                end
            --end
        end
        TriggerClientEvent("fleecabank:cash", client, done, amount, action, accounts[sourceAccount])
    end
)

RegisterNetEvent("fleecabank:syncAccount")
AddEventHandler("fleecabank:syncAccount",
    function(sourceAccount)
        local client = source
        TriggerClientEvent("fleecabank:syncAccount", client, getAccountByNumber(sourceAccount))
    end
)
--[[
RegisterNetEvent("fleecabank:choosepaymentmethod")
AddEventHandler("fleecabank:choosepaymentmethod",
    function(data, methodType, methodId)
        local client = source
        local done = "missingAmount"
        if methodType == "cash" then
            -- if xPlayer.getMoney() >= data.amount then
            --      xPlayer.removeMoney(data.amount)
            --      done = "done"
            -- end
            done = "done"
        elseif methodType == "account" then
            done = checkFunds(methodId, data.amount, true, true)
        end

        TriggerClientEvent("fleecabank:choosepaymentmethod", client, done, data, methodType, methodId)
    end
)

RegisterNetEvent("fleecabank:payfine")
AddEventHandler("fleecabank:payfine",
    function(data)
        local client = source
        openPaymentMethod(client, {})
    end
)

function openPaymentMethod(client, data)
    -- data to test
    data = {
        title = "ZAPLACENÍ POKUTY",
        amount = 5000,
        success = "",
        sadface = string.dump(function()
            print("SAD FACE BY FUNC")
            end)
    }
    --
    local methods = Config.defaultPaymentMethodsAllowed
    if methods.cash then
        methods.data.cash = 10000 -- xPlayer.getMoney()
    end
    if methods.account then
        local _, accounts = getAccountsByOwner(_tempCharId) -- xPlayer.char
        methods.data.account = accounts
    end
    if methods.card then
        -- get cards which he has
    end
    TriggerClientEvent("fleecabank:paymentmethod", client, data, methods)
end]]

function saveAccounts()
    for k,_ in pairs(accounts) do
        if accounts[k] ~= nil and accounts[k].changed then
            accounts[k].changed = false
            MySQL.Async.execute(
                "INSERT INTO bank_accounts (number, owner, balance, main, data) VALUES (@number, @owner, @balance, @main, @data) ON DUPLICATE KEY UPDATE owner = @owner, balance = @balance, main = @main, data = @data",
                {
                    ["@number"] = k,
                    ["@owner"] = accounts[k].owner,
                    ["@balance"] = accounts[k].balance,
                    ["@main"] = accounts[k].main,
                    ["@data"] = json.encode(accounts[k].data)
                }
            )

            print("BANK ACCOUNT SAVED: " .. k)
        end
    end

    SetTimeout(25000, saveAccounts)
end
function doesAccountExist(sourceAccount)
    return (accounts[sourceAccount] ~= nil)
end
function getMainAccountByOwner(ownerId)
    local mainAccount = nil
    for k,v in pairs(accounts) do
        if v.owner == ownerId and v.main then
            mainAccount = v
        end
    end
    return mainAccount
end
function getAccountsByOwner(ownerId)
    if ownerId == nil then
        return "missingVariable"
    end

    local _owned = {}
    local _count = 0
    for k,v in pairs(accounts) do
        if v.owner == ownerId then
            _owned[k] = {
                data = {
                    account_name = v.data.account_name
                },
                balance = v.balance
            }
            _count = _count + 1
        end
    end
    return _count, _owned
end
function getAccountByNumber(sourceAccount)
    if sourceAccount == nil or accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    return accounts[sourceAccount]
end
function isBankAccountOwner(sourceAccount, ownerId)
    if sourceAccount == nil or accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if ownerId == nil then
        return "missingVariables"
    end

    return (accounts[sourceAccount].owner == ownerId)
end
function create(owner, balance, number, data, main)
    if owner == nil then
        return "missingVariables"
    end

    if balance == nil then
        balance = 0
    end

    local try = 0

    if number == nil then
        number = os.time()
    end

    number = generateAccountNumber(tostring(number))
    while accounts[number] ~= nil do
        number = generateAccountNumber(tostring(number))
        Citizen.Wait(50)
        try = try + 1

        if try > 20 then
            return "looped"
        end
    end

    if data == nil then
        data = {
            account_name = "CHANGE ME",
            account_created = os.time()
        }
    end

    if main == nil then
        main = false
    end

    accounts[number] = {
        number = number,
        owner = owner,
        balance = balance,
        main = main,
        data = data,
        changed = false
    }

    MySQL.Async.execute(
        "INSERT INTO bank_accounts (number, owner, balance, main, data) VALUES (@number, @owner, @balance, @main, @data)",
        {
            ["@number"] = number,
            ["@owner"] = json.encode(owner),
            ["@balance"] = balance,
            ["@main"] = main,
            ["@data"] = json.encode(data)
        },
        function() end)

    return "done", accounts[number]
end
function generateAccountNumber(part1)
    local creatednumber = part1.sub(part1, 1, 2)
    local length = 6 - creatednumber.len(creatednumber)

    while length > 0 do
        local randomnumber = tostring(math.random(10, 99))
        creatednumber = creatednumber .. randomnumber
        length = length - randomnumber.len(randomnumber)
    end

    return tonumber(creatednumber)
end
function delete(sourceAccount)
    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if not Config.enableDeleteNotEmptyBankAccount and accounts[sourceAccount].balance >= 0 then
        return "notEmpty"
    end

    accounts[sourceAccount] = nil
    MySQL.Async.execute(
        "DELETE FROM bank_accounts WHERE number=@number",
        {
            ["@number"] = sourceAccount
        },
        function()

        end
    )
    return "done"
end
function checkFunds(sourceAccount, value, remove, save)
    if sourceAccount == nil or value == nil then
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if type(value) ~= "number" then
        value = tonumber(value)
    end

    if value <= 0 then
        return "negativeValue"
    end

    if accounts[sourceAccount].balance < value then
        return false
    end

    if remove then
        accounts[sourceAccount].balance = accounts[sourceAccount].balance - value
    end

    if save then
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true
    end

    return true
end
function removeFunds(sourceAccount, value, save)
    if sourceAccount == nil or value == nil then
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if type(value) ~= "number" then
        value = tonumber(value)
    end

    if value <= 0 then
        return "negativeValue"
    end

    if accounts[sourceAccount].balance < value then
        return "notEnough"
    end

    accounts[sourceAccount].balance = accounts[sourceAccount].balance - value

    if save then
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true
    end

    return "done"
end
function addFunds(sourceAccount, value, save)
    if sourceAccount == nil or value == nil then
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if type(value) ~= "number" then
        value = tonumber(value)
    end

    if value <= 0 then
        return "negativeValue"
    end

    accounts[sourceAccount].balance = accounts[sourceAccount].balance + value

    if save then
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true
    end

    return "done"
end
function transferFunds(sourceAccount, targetAccount, value, save)
    if sourceAccount == nil or value == nil or targetAccount == nil then
        return "missingVariable"
    end

    if targetAccount == sourceAccount then
        return "sameAccount"
    end

    if accounts[sourceAccount] == nil then
        return "missingSourceAccount"
    end

    if accounts[targetAccount] == nil then
        return "missingTargetAccount"
    end

    if type(value) ~= "number" then
        value = tonumber(value)
    end

    if value <= 0 then
        return "negativeValue"
    end

    if accounts[sourceAccount].balance < value then
        return "missingFunds"
    end

    accounts[sourceAccount].balance = accounts[sourceAccount].balance - value
    accounts[targetAccount].balance = accounts[targetAccount].balance + value

    if save then
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )

        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[targetAccount].balance,
                ["number"] = targetAccount
            }
        )
    else
        accounts[sourceAccount].changed = true
        accounts[targetAccount].changed = true
    end

    return "done"
end
function setAccountMain(sourceAccount, ownerId, status)
    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if accounts[sourceAccount].main then
        return "alreadyMain"
    end

    local mainAccount = getMainAccountByOwner(ownerId)
    if mainAccount then
        accounts[mainAccount.number].main = not status
        accounts[mainAccount.number].changed = true
    end

    accounts[sourceAccount].main = status
    accounts[sourceAccount].changed = true

    return "done"
end
function updateAccountData(sourceAccount, variable, value)
    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    if accounts[sourceAccount].data == nil then
        return "missingDataTable"
    end

    if accounts[sourceAccount].data[variable] == nil then
        return "missingVariable"
    end

    accounts[sourceAccount].data[variable] = value
    accounts[sourceAccount].changed = true
    return "done"
end

-- TESTING (later on will be put in as an admin command, highest/developer rank only)
RegisterCommand("cba", function(source, args)
    local client = source
    create(client, 0, os.time(), {
        account_created = os.time(),
        account_name = "NO NAME"
    })
end)
RegisterCommand("rba", function(source, args)
    local sourceAcc = tonumber(args[1])

    local done = delete(sourceAcc)

    print("DELETE ACC", sourceAcc, done)
end)
RegisterCommand("check", function(source, args)
    local val = tonumber(args[1])
    local sourceAcc = tonumber(args[2])

    local hasValue = checkFunds(sourceAcc, val, false)

    print("CHECK FUNDS", sourceAcc, val, hasValue)
end)
RegisterCommand("remove", function(source, args)
    local val = tonumber(args[1])
    local sourceAcc = tonumber(args[2])

    local done = removeFunds(sourceAcc, val, true)

    print("REMOVE FUNDS", sourceAcc, val, done)
end)
RegisterCommand("transfer", function(source, args)
    local val = tonumber(args[1])
    local sourceAcc = tonumber(args[2])
    local targetAcc = tonumber(args[3])

    local done = transferFunds(sourceAcc, targetAcc, val, true)

    print("TRANSFER FUNDS", sourceAcc, targetAcc, val, done)
end)
--