function post(url = "", data = {}) {
    fetch(url, {
      method: "POST",
      body: JSON.stringify(data)
    })
}

function getCurrency(price) {
    var currency = new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
        maximumFractionDigits: 0
    })
    return currency.format(price)
}

// tabs closing
function closeAll() {
    const pages = ["accounts", "newaccount", "editaccount", "deleteaccount", "account"]
    pages.forEach(function(v) {
        document.getElementById(v).style.display = "none"
    })
}

// display UI
function display(status, page = null) {
    if (status) {
        document.querySelector(".wrapper").style.display = "block"
        closeAll()
        document.querySelector("#" + page).style.display = "block"
    } else
    document.querySelector(".wrapper").style.display = "none"
}

function setUpTableHeader(element, titles) {
    let content = ""
    content = "<tr>"
    
    titles.forEach(function(value, key) {
        content += `<th>${value}</th>`
    })
    
    content += "</tr>"
    document.querySelector(element).innerHTML = content
}

function setUpAccounts(element, data) {
    let content = ""

    data.forEach(function(v) {
        content += "<tr>"
        content += `<td class="open-account" data-opened-acc-number="${v.account_number}">${v.account_number}</td>`
        content += `<td>${v.name}</td>`
        content += `<td>${getCurrency(v.balance)}</td>`
        content += "<td>"
        content += `<i class="fas fa-pen-square" id="edit-account" data-acc-name="${v.name}" data-acc-id="${v.id}"></i>\n`
        content += `<i class="fas fa-minus-square" id="delete-account" data-delete-acc-name="${v.name}" data-delete-acc-id="${v.id}"></i>`
        content += "</td>"
        content += "</tr>"
    })
    document.querySelector(element).innerHTML += content
}

function setUpAccount(element, data) {
    let content = ""
    
    if (data.main) {
        content = `<h1>Hlavní účet - <span id='opened-acc-name'>${data.name}</span></h1>`
    } else {
        content = `<h1>Účet - <span id='opened-acc-name'>${data.name}</span></h1>`
    }
    content += "Vyberte akci:<br>"
    content += "<select id='account-actions'>"
    content += "<option>Vyberte akci:</option>"
    
    // if (!data.main) {
    //     content += "<option value='setasmain'>Nastavit jako hlavní</option>"
    // }
    
    content += "<option value='deposit'>Vklad</option>"
    content += "<option value='withdraw'>Výběr</option>"
    content += "<option value='transfer'>Převod na účet</option>"
    content += "</select>"
    
    content += "<br><br>"
    
    content += "<div id='toggle-amount'>"
    content += "Částka:<br>"
    content += "<input type='number' id='amount' placeholder='Částka' autocomplete='off' spellcheck='false' min='1'>"
    content += "<br><br>"
    content += "</div>"

    content += "<div id='toggle-account-number'>"
    content += "Číslo účtu pro převod:<br>"
    content += "<input type='number' id='acctransfer' placeholder='Číslo účtu' autocomplete='off' spellcheck='false' min='1'>"
    content += "<br><br>"
    content += "</div>"

    content += `<input type="hidden" id="actions-acc-number" value="${data.account_number}">`
    content += "<button id='account-action-submit'>Potvrdit</button>"

    document.querySelector(element).innerHTML = content
}

display(false)

// UI listener
window.addEventListener("message", function(e) {
    let data = e.data
    if (data.status === true) {
        display(true, data.page)
        
        switch (data.page) {
            case "accounts":
                const titles = ["Číslo účtu", "Název účtu", "Zůstatek", "Možnosti"]
                setUpTableHeader(data.content[0][0], titles)
                setUpAccounts(data.content[0][0], data.content[1][0])
                break

            case "account":
                setUpAccount(data.content[0][0], data.content[1][0])
                break
        }
    } else
        display(false)
})

// close bank button
const closeButton = document.querySelector(".close");
closeButton.addEventListener("click", function() {
    post("https://rflx_bank/close", {})
})

// close bank by ESC
document.onkeyup = function(data) {
    if (data.key == "Escape") {
        post("https://rflx_bank/close", {})
    }
}

// switch to new account tab
const newAccButton = document.getElementById("new-acc-btn")
newAccButton.addEventListener("click", function() {
    post("https://rflx_bank/new-acc-tab", {})
})

// create account
const newAccountSubmit = document.getElementById("create-acc-submit")
newAccountSubmit.addEventListener("click", function() {
    let getAccName = document.getElementById("new-acc-name").value
    if (!getAccName) {
        post("https://rflx_bank/error", {
            error: "Neplatný název účtu"
        })
    } else {
        post("https://rflx_bank/create-account", {
            name: getAccName
        })
    }
})

// cancel button
const cancel = document.getElementsByClassName("cancel")
for (let i = 0; i < cancel.length; i++) {
    cancel[i].addEventListener("click", function() {
        post("https://rflx_bank/cancel", {})
    })
}

// change event listener
document.addEventListener("change", function(e) {
    // actions choosing
    if (e.target.matches("#account-actions")) {
        switch (e.target.value) {
            case "deposit":
                document.getElementById("toggle-amount").style.display = "block"
                break
            
            case "withdraw":
                document.getElementById("toggle-amount").style.display = "block"
                break

            case "transfer":
                document.getElementById("toggle-amount").style.display = "block"
                document.getElementById("toggle-account-number").style.display = "block"
                break

            default:
                document.getElementById("toggle-amount").style.display = "none"
                document.getElementById("toggle-account-number").style.display = "none"
                break
        }
    }
})

// click event listener
document.addEventListener("click", function(e) {
    // switch to edit account tab
    if (e.target.matches("#edit-account")) {
        let getAccName = e.target.getAttribute("data-acc-name")
        let getAccId = e.target.getAttribute("data-acc-id")
        document.getElementById("current-acc-name").innerHTML = getAccName
        document.getElementById("edit-acc-name").value = getAccName
        document.getElementById("edit-acc-id").value = getAccId
        post("https://rflx_bank/edit-acc-tab", {})
    }

    // switch to delete account tab
    else if (e.target.matches("#delete-account")) {
        let getAccName = e.target.getAttribute("data-delete-acc-name")
        let getAccId = e.target.getAttribute("data-delete-acc-id")
        document.getElementById("delete-acc-name").innerHTML = getAccName
        document.getElementById("retype-acc-confirm").value = getAccName
        document.getElementById("delete-acc-id").value = getAccId
        post("https://rflx_bank/delete-acc-tab", {})
    }

    // open account
    else if (e.target.matches(".open-account")) {
        let getAccNumber = e.target.getAttribute("data-opened-acc-number")
        post("https://rflx_bank/account-tab", {
            acc_number: getAccNumber
        })
    }

    // submitting action
    else if (e.target.matches("#account-action-submit")) {
        let getAction = document.getElementById("account-actions").value
        let getAmount = parseInt(document.getElementById("amount").value)
        let getAccNumber = parseInt(document.getElementById("actions-acc-number").value)
        let getAccTransfer = parseInt(document.getElementById("acctransfer").value)

        switch (getAction) {
            // case "setasmain":
            //     post("https://rflx_bank/set-main-account", {
            //         acc_number: getAccNumber
            //     })
            //     break

            case "deposit":
                if (getAmount > 0) {
                    post("https://rflx_bank/deposit", {
                        amount: getAmount,
                        acc_number: getAccNumber
                    })
                } else {
                    post("https://rflx_bank/error", {
                        error: "Neplatná částka"
                    })
                }
                break

            case "withdraw":
                if (getAmount > 0) {
                    post("https://rflx_bank/withdraw", {
                        amount: getAmount,
                        acc_number: getAccNumber
                    })
                } else {
                    post("https://rflx_bank/error", {
                        error: "Neplatná částka"
                    })
                }
                break

            case "transfer":
                if (getAmount > 0 && getAccTransfer > 0 && getAccTransfer !== getAccNumber) {
                    post("https://rflx_bank/transfer", {
                        amount: getAmount,
                        acc_number: getAccNumber,
                        transfer: getAccTransfer
                    })
                } else {
                    post("https://rflx_bank/error", {
                        error: "Chyba při převodu"
                    })
                }
                break
        }
    }
})

// edit account
const editAccountSubmit = document.getElementById("edit-acc-submit")
editAccountSubmit.addEventListener("click", function() {
    let getAccName = document.getElementById("edit-acc-name").value
    let getAccId = parseInt(document.getElementById("edit-acc-id").value)

    if (!getAccName) {
        post("https://rflx_bank/error", {
            error: "Neplatný název účtu"
        })
    } else {
        post("https://rflx_bank/edit-account", {
            name: getAccName,
            id: getAccId
        })
    }
})

// delete account
const deleteAccountSubmit = document.getElementById("delete-acc-submit")
deleteAccountSubmit.addEventListener("click", function() {
    let getRetypeAccName = document.getElementById("retype-acc-name").value
    let getRetypeAccConfirm = document.getElementById("retype-acc-confirm").value
    let getAccId = parseInt(document.getElementById("delete-acc-id").value)
    
    if (!getRetypeAccName) {
        post("https://rflx_bank/error", {
            error: "Neplatný název účtu"
        })
    }

    else if (getRetypeAccName !== getRetypeAccConfirm) {
        post("https://rflx_bank/error", {
            error: "Chybný název účtu"
        })
    } else {
        post("https://rflx_bank/delete-account", {
            id: getAccId
        })
    }
})

const deleteAccountCancel = document.getElementById("delete-acc-cancel")
deleteAccountCancel.addEventListener("click", function() {
    post("https://rflx_bank/cancel", {})
})