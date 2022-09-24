# FLEECABANK

[SERVER SIDE EXPORTS](## SERVER SIDE EXPORTS)

[CLIENT SIDE EXPORTS](## CLIENT SIDE EXPORTS)

[doesAccountExist](# doesAccountExist)



```lua
local done =    "done" or 
                "notEnough" or 
                "missingAccount" or 
                "notEmpty" or 
                "negativeValue" or
                "missingVariable" or
                "sameAccount" or
                "missingSourceAccount" or
                "missingTargetAccount" or
                "missingFunds" or
                "missingDataTable" or
                "alreadyMain"


-- "done" is the only success
```



## SERVER SIDE EXPORTS

| #doesAccountExist (sourceAccount [int]) |
|:--------------------------------------- |
| returns true or false                   |

*example:*

```lua
if doesAccountExist(123456) then 
    print("EXISTS")
else
    print("DOES NOT EXIST")
end
```

| getMainAccountByOwner (ownerId [identifier]) |
|:-------------------------------------------- |
| returns account selected as main [table]     |

*example:*

```lua
-- ESX
local xPlayer = ESX.GetPlayerFromId(client)
if xPlayer then 
    local charId = xPlayer.char
    if charId then 
        local mainAccount = getMainAccountByOwner(charId)
        print(mainAccount.data.account_name)
    end
end
```

| getAccountsByOwner (ownerId [identifier])                 |
|:--------------------------------------------------------- |
| returns count of accounts [int], list of accounts [table] |

*example:*

```lua
-- ESX
local xPlayer = ESX.GetPlayerFromId(client)
if xPlayer then 
    local charId = xPlayer.char
    if charId then 
        local count, accounts = getAccountsByOwner(charId)
        print("COUNTED ACCOUNTS:", count)
        for k, v in pairs(accounts) do 
            print(k, v.data.account_name)
        end
    end
end
```

| getAccountByNumber (sourceAccount [int]) |
|:---------------------------------------- |
| returns account [table]                  |

*example:*

```lua
local account = getAccountByNumber(123456)
if account then
    print(account.data.account_name)
end
```

| isBankAccountOwner (sourceAccount [int], ownerId [identifier]) |
|:-------------------------------------------------------------- |
| returns true or false                                          |

*example:*

```lua
-- ESX
local xPlayer = ESX.GetPlayerFromId(client)
if xPlayer then 
    local charId = xPlayer.char
    if charId then 
        local isOwner = isBankAccountOwner(123456, charId)
        print(isOwner)
    end
end
```

| create (owner[identifier], balance [int], number [int], data [table], main [boolean])          |
|:---------------------------------------------------------------------------------------------- |
| max available accounts to create per person changeable in *Config.maxAvailableAccounts*        |
| the "number" parameter is only a beginning and from that number is generated an account number |
| <u>all </u>parameters except for owner can be <u>nil</u>                                       |
| generated account number is based in the function called <u>generateAccountNumber</u>          |
| returns status done [string], created new account [table]                                      |

*parameter data example:*

```lua
data = { 
    account_name = "STRING",
    account_created = os.time(),
    any_other_specific_and_unique_variable = nil
}
```

*example:*

```lua
-- ESX
local xPlayer = ESX.GetPlayerFromId(client)
if xPlayer then 
    local charId = xPlayer.char
    if charId then 
        local done, newAccount = create(charId, 0, os.time(), { 
            account_name = "MY NEW ACCOUNT",
            account_created = os.time()
        }, false)

        if done == "done" then 
            print("YOUR NEW ACCOUNT:", newAccount.number)
        end
    end
end
```

| delete (sourceAccount [int])                                                                                |
|:----------------------------------------------------------------------------------------------------------- |
| not possible if there is any amount on the account - changeable in *Config.enableDeleteNotEmptyBankAccount* |
| returns status done [string]                                                                                |

*example:*

```lua
local done = delete(123456)
print("DELETED?", done)
```

| checkFunds (sourceAccount [int], value [int], remove [boolean], save [boolean])                                    |
|:------------------------------------------------------------------------------------------------------------------ |
| if <u>remove </u>is set on true, the amount, after successful check, will be also removed in the end, if available |
| if <u>save</u> is set on true, the execution will be saved into database right away                                |
| returns status done [string]                                                                                       |

*example:*

```lua
local done = checkFunds(123456, 1000, true, true)
print("HAS ENOUGH?", done, "THEN REMOVE THE FUNDS")
```

| **removeFunds (sourceAccount [int], value [int], save [boolean])**                  |
|:----------------------------------------------------------------------------------- |
| if <u>save</u> is set on true, the execution will be saved into database right away |
| returns status done [string]                                                        |

*example:*

```lua
local done = removeFunds(123456, 1000, true)
print("REMOVED FUNDS?", done)
```

| **addFunds (sourceAccount [int], value [int], save [boolean])**                     |
|:----------------------------------------------------------------------------------- |
| if <u>save</u> is set on true, the execution will be saved into database right away |
| returns status done [string]                                                        |

*example:*

```lua
local done = addFunds(123456, 1000, true)
print("ADDED FUNDS?", done)
```

| transferFunds (sourceAccount [int], targetAccount [int], value [int], save [boolean]) |
|:------------------------------------------------------------------------------------- |
| if <u>save</u> is set on true, the execution will be saved into database right away   |
| returns status done [string]                                                          |

*example:*

```lua
-- ESX
local xPlayer = ESX.GetPlayerFromId(client)
local tPlayer = ESX.GetPlayerFromId(target)
if xPlayer and tPlayer then 
    local sourceChar = xPlayer.char
    local targetChar = tPlayer.char
    if sourceChar and targetChar then 
        local sourceMain = getMainAccountByOwner(sourceChar)
        local targetMain = getMainAccountByOwner(targetChar)
        if sourceMain and targetMain then 
            local done = transferFunds(sourceMain, targetMain, 1000, true)
            print("SUCCESS?", done)
        end
    end
end

```

| **updateAccountData (sourceAccount [int], variable [string], value [?])** |
|:------------------------------------------------------------------------- |
| variable can be unique for any bank account, fe: <u>account_name</u>      |
| returns status done [string]                                              |

*example:*

```lua
local done = updateAccountData(123456, "account_name", "MY NEW ACCOUNT NAME")
print("CHANGED ACCOUNT VARIABLE", done)
```



## SERVER SIDE EXPORTS

| **openPaymentMethod(data [table], success [func], failure [func])**                        |
|:------------------------------------------------------------------------------------------ |
| in the end of events it will execute either "success" or "failure" depending on the result |

*parameter data example:*

```lua
data = {
    title = "TITLE OF THE MENU",
    amount = 0
}
```

*example:*

```lua
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
```

`© rozkothe, 2022`