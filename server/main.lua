local accounts = {}

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
                    administrator = json.decode(result[i].administrator),
                    balance = result[i].balance,
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

function saveAccounts()
    print("FLEECABANK: CHANGED BANK ACCOUNTS SAVED")

    SetTimeout(25000, saveAccounts)
end

-- TESTING (later on will be put in as an admin command, highest/developer rank only)
RegisterCommand("cba", function(source, args)
    local client = source
    create(client, 150, os.time(), {
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


function create(administrator, balance, number, data)
    if administrator == nil then
        return "missingVariables"
    end

    if balance == nil then
        balance = 0
    end

    local try = 0
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
        data = {}
    end

    MySQL.Async.execute(
        "INSERT INTO bank_accounts (number, administrator, balance, data) VALUES (@number, @administrator, @balance, @data)",
        {
            ["@number"] = number,
            ["@administrator"] = json.encode(administrator),
            ["@balance"] = balance,
            ["@data"] = json.encode(data)
        },
        function()
            accounts[number] = {
                number = number,
                founder = administrator,
                balance = balance,
                data = data,
                changed = false
            }
        end
    )
    return "done", number
end
function generateAccountNumber(part1)
    local creatednumber = part1.sub(part1, 1, 2)
    local length = 10 - creatednumber.len(creatednumber)

    while length > 0 do
        local randomnumber = tostring(math.random(10, 99))
        creatednumber = creatednumber .. randomnumber
        length = length - randomnumber.len(randomnumber)
    end

    return creatednumber
end

function delete(sourceAccount)
    if accounts[sourceAccount] == nil then
        return "missingAccount"
    end

    MySQL.Async.execute(
        "DELETE FROM bank_accounts WHERE number=@number",
        {
            ["@number"] = sourceAccount
        },
        function()
            accounts[sourceAccount] = nil
            return "done"
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