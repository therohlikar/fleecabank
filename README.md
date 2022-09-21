# FLEECABANK

Lua, HTML, CSS, JS.



> **doesAccountExist (sourceAccount [int])**
> 
> returns true or false



> **getMainAccountByOwner (ownerId [identifier])**
> 
> returns account selected as main [table]



> **getAccountsByOwner (ownerId [identifier])**
> 
> returns count of accounts [int], list of accounts [table]



> **getAccountByNumber (sourceAccount [int])**
> 
> returns account [table]



> **isBankAccountOwner (sourceAccount [int], ownerId [identifier])**
> 
> returns true or false



> **create (owner[identifier], balance [int], number [int], data [table], main [boolean])**
> 
> `data = {`
> 
> `    account_name = "STRING",`
> 
> `    account_created = os.time()`
> 
> `}`
> 
> max available accounts to create per person changeable in *Config.maxAvailableAccounts*
> 
> <u>all </u>parameters except for owner can be <u>nil</u>
> 
> returns status done [string], created new account [table]



> **delete (sourceAccount [int])**
> 
> not possible if there is any amount on the account - changeable in *Config.enableDeleteNotEmptyBankAccount*
> 
> returns status done [string]



> **checkFunds (sourceAccount [int], value [int], remove [boolean], save [boolean])**
> 
> if <u>remove </u>is set on true, the amount, after successful check, will be also removed in the end, if available
> 
> if <u>save</u> is set on true, the execution will be saved into database right away
> 
> returns status done [string]



> **removeFunds (sourceAccount [int], value [int], save [boolean])**
> 
> if <u>save</u> is set on true, the execution will be saved into database right away
> 
> returns status done [string]



> **addFunds (sourceAccount [int], value [int], save [boolean])**
> 
> if <u>save</u> is set on true, the execution will be saved into database right away
> 
> returns status done [string]



> **transferFunds (sourceAccount [int], targetAccount [int], value [int], save [boolean])**
> 
> if <u>save</u> is set on true, the execution will be saved into database right away
> 
> returns status done [string]



> **updateAccountData (sourceAccount [int], variable [string], value [?])**
> 
> variable can be unique for any bank account, fe: <u>account_name</u>
> 
> returns status done [string]



`© rozkothe, 2022`