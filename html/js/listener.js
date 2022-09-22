let opened = false;
let blocked = false;
let wasBlocked = false
let accounts = [];
let charNames = [];
let jobNames = [];
let removeAccount = 0;
let usedAccount = 0;
let charId = 0
let accountsLeft = 0
let filter = "all";
let company = "";
let selectedIcon = 'fas fa-university';
let currentTransactions = [];
let balanceChart = null;

const months = [
    'LED',
    'ÚNO',
    'BŽE',
    'DUB',
    'KVĚ',
    'ČVN',
    'ČVC',
    'SRP',
    'ZÁŘ',
    'ŘÍJ',
    'LIS',
    'PRO'
]

const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
});

document.onkeyup = function (data) {
    if (data.which === 27 && opened) {
        closepanel();
    }
};

new ClipboardJS('.copy');

$('.icp-dd').iconpicker({
    title: 'Zvolte ikonku účtu',
    hideOnSelect: true,
    templates: {
        search: '<input type="search" class="form-control iconpicker-search" placeholder="Hledat v ikonkách" />',
    }
});

$(function () {
    window.addEventListener('message', function (event) {
        blocked = false;

        switch (event.data.action) {
            case 'show':
                opened = true;

                if (event.data.accounts) {
                    accounts = event.data.accounts;
                }

                if (event.data.bankCompany !== undefined) {
                    company = event.data.bankCompany;
                }else company = "fleeca";

                if (event.data.settings !== undefined) {
                    accountsLeft = event.data.settings.accountsLeft;
                }

                $('#logoImage').attr('src', 'img/' + company + '.png');

                showBank();
                break;
            case 'hide':
                hideAllPanels();
                $('#box').hide();
                $('body').hide();
                opened = false;
                break;
            case 'refreshDetails':
                $('#sendAcountNumber').val('');
                $('#sendAmount').val('');

                filter = "all";
                accounts[event.data.account.number] = event.data.account;

                if (event.data.accessData !== undefined) {
                    access = event.data.accessData;
                }

                if (event.data.charId !== undefined) {
                    charId = event.data.charId;
                }

                if (event.data.logs !== undefined) {
                    currentTransactions = event.data.logs;
                }

                //loadTransactions();
                useAccount(event.data.account.number);
                break;
            default:
                console.log('bank: unknown action!');
                break;
        }
    }, false);
});

function closepanel() {
    $.post('https://fleecabank/closepanel', JSON.stringify({}));
}

function hideAllPanels() {
    $('#add-new-bank-account').modal('hide');
    $('#remove-bank-account').modal('hide');
    $('#bank-account-deposit').modal('hide');
    $('#bank-account-withdraw').modal('hide');
    $('#transaction-detail').modal('hide');
    $('#bank-account-send').modal('hide');
    $('#bank-account-edit').modal('hide');
    $('#subHeader').hide();
    $('#bankAccounts').hide();
    $('#bankAccountDetail').hide();
    $('#bankAccountDetailTransactions').hide();
    $('#bankAccountDetailAccesses').hide();
    $('#removeAccountButton').hide();
    $('#accountActions').hide();
    $('#accountActionsHr').hide();
    $('#accountActionsWithdraw').hide();
    $('#accountActionsDeposit').hide();
    $('#navSend').hide();
    $('#navEdit').hide();

    $("[name=allFilters]").val(["all"]);
    $('.secondary-nav .nav-link').removeClass('active');
}

$('#bank-account-deposit').on('shown.bs.modal', function (e) {
    $('#depositAmount').focus();
})

$('#bank-account-withdraw').on('shown.bs.modal', function (e) {
    $('#withdrawAmount').focus();
})

$('#bank-account-edit').on('show.bs.modal', function (e) {
    const accountData = accounts[usedAccount];
})

$('#add-new-bank-account').on('show.bs.modal', function (e) {
    selectedIcon = 'fas fa-university';
    $('#accountIcon').data('selected', selectedIcon);

    $("#accountIconIcon").removeAttr('class');
    $("#accountIconIcon").attr('class', selectedIcon);
})

$('input[type=radio][name=allFilters]').change(function () {
    if (filter !== this.value) {
        filter = this.value;
        loadTransactions();
    }
});

$("#send").submit(function (event) {
    event.preventDefault();

    if (!blocked) {
        blocked = true;
        $.post('https://fleecabank/action', JSON.stringify({
            action: "transfer",
            target: $('#sendAcountNumber').val(),
            value: $('#sendAmount').val(),
            account: usedAccount
        }));
    }
});

$("#deposit").submit(function (event) {
    event.preventDefault();

    if (!blocked) {
        blocked = true;
        $('#bank-account-deposit').modal('hide');

        $.post('https://fleecabank/action', JSON.stringify({
            action: "cash",
            value: $('#depositAmount').val(),
            account: usedAccount,
            subaction: "deposit"
        }));

        $('#depositAmount').val('');
    }
});

$("#withdraw").submit(function (event) {
    event.preventDefault();

    if (!blocked) {
        blocked = true;
        $('#bank-account-withdraw').modal('hide');

        $.post('https://fleecabank/action', JSON.stringify({
            action: "cash",
            value: $('#withdrawAmount').val(),
            account: usedAccount,
            subaction: "withdraw"
        }));

        $('#withdrawAmount').val('');
    }
})

$("#editbankaccount").submit(function (event) {
    event.preventDefault();

    if (!blocked) {
        blocked = true;
        $('#bank-account-edit').modal('hide');

        $.post('https://fleecabank/action', JSON.stringify({
            account: usedAccount,
            value: $('#accountNameEdit').val(),
            action: "rename"
        }));
    }
});

$("#addbankaccount").submit(function (event) {
    event.preventDefault();

    if (!blocked && accountsLeft > 0) {
        blocked = true;
        $('#add-new-bank-account').modal('hide');

        $.post('https://fleecabank/action', JSON.stringify({
            action: "createaccount",
            value: $('#accountName').val()
        }));

        $('#accountName').val('');
        accountsLeft--;
    }
});

function filterCheck(action) {
    if (filter === 'deposit' && action !== 'DEPOSIT_CASH') {
        return false;
    } else if (filter === 'withdraw' && action !== 'WITHDRAW_CASH') {
        return false;
    } else if (filter === 'in' && action !== 'RECEIVE_MONEY') {
        return false;
    } else if (filter === 'out' && action !== 'SEND_MONEY') {
        return false;
    }

    return true;
}

function loadTransactions() {
    $('#transactions').html('');
    $.each(currentTransactions, function (index, transactionInfo) {
        if (filterCheck(transactionInfo.action)) {
            let textTop;

            if (transactionInfo.action === 'WITHDRAW_CASH') {
                textTop = 'Výběr hotovosti';
            } else if (transactionInfo.action === 'DEPOSIT_CASH') {
                textTop = 'Vklad hotovosti';
            } else if (transactionInfo.action === 'SEND_MONEY') {
                textTop = 'Odchozí platba';
            } else if (transactionInfo.action === 'RECEIVE_MONEY') {
                textTop = 'Příchozí platba';
            }

            if (transactionInfo.date < 10000000000) {
                transactionInfo.date *= 1000;
            }
            let date = new Date(transactionInfo.date);

            let negativeSign = '';
            let negativeClass = '';
            if (transactionInfo.negative) {
                negativeSign = '-';
                negativeClass = 'negative';
            }

            $('#transactions').append(`<div class="transaction-item ${negativeClass} px-4 py-3" data-toggle="modal" data-target="#transaction-detail" onclick="transactionDetail(${index})">
                <div class="row align-items-center flex-row">
                  <div class="col-2 col-sm-1 text-center"> <span class="d-block text-4 font-weight-300">${date.getDate()}</span> <span class="d-block text-1 font-weight-300 text-uppercase">${months[date.getMonth()]}</span> </div>
                  <div class="col col-sm-9"> <span class="d-block text-4">${textTop}</span> <span class="text-muted">${transactionInfo.description}</span> </div>
                  <div class="col-2 col-sm-2 text-right text-4"> <span class="text-nowrap">${negativeSign}${formatter.format(transactionInfo.amount)}</span></div>
                </div>
              </div>`);
        }
    });
}

function useAccount(accountNumber) {
    usedAccount = accountNumber;
    const accountData = accounts[accountNumber];

    hideAllPanels();

    $('#navDetail .nav-link').addClass('active');
    $('#bankAccountDetailName').text(accountData.data.account_name);
    $('#bankAccountDetailNumber').text(accountNumber);
    $('#bankAccountDetailBalance').text(formatter.format(accountData.balance));

    checkAccountSubmenu();

    $('#accountNameEdit').val(accountData.data.account_name);

    $('#subHeader').show();
    $('#bankAccountDetailTransactions').show();
    $('#bankAccountDetail').show();
}

$("#navDetail").click(function () {
    loadAccount(usedAccount);
});

function showATM() {
    hideAllPanels();

    $('body').show();
    $('#credit-card-modal').modal('show');
}

function transactionDetail(transactionIndex) {
    let transactionInfo = currentTransactions[transactionIndex];
    if (transactionInfo.date < 10000000000) {
        transactionInfo.date *= 1000;
    }
    let date = new Date(transactionInfo.date);
    $("#transactionTargetBox").hide();

    $('#transactionDateTime').html(("0" + date.getDate()).slice(-2) + "." + ("0" + (date.getMonth() + 1)).slice(-2) + "." + date.getFullYear() + " " + ("0" + date.getHours()).slice(-2) + ":" + ("0" + date.getMinutes()).slice(-2) + ":" + ("0" + date.getSeconds()).slice(-2));
    if(transactionInfo.targetAccount != null && transactionInfo.targetAccount != ""){
        $("#transactionTargetBox").show();

        $("#transactionTargetLabel").html("Na účet:");
        if(transactionInfo.action == "RECEIVE_MONEY")
            $("#transactionTargetLabel").html("Z účtu:");

        $('#transactionTarget').html(transactionInfo.targetAccount);
    }
    $('#transactionAmount').html(formatter.format(transactionInfo.amount));
    $('#transactionBalance').html(formatter.format(transactionInfo.balance));
}

function showBank() {
    hideAllPanels();
    setupBankAccounts();

    $('.navbar-nav li').removeClass('active');
    $('#navAllList').addClass('active');

    if (accountsLeft <= 0) {
        $('#addNewBankAccountButton').hide();
    } else {
        $('.accountsLeft').text(accountsLeft);
        $('#addNewBankAccountButton').show();
    }

    $('#bankAccounts').show();
    $('#box').show();
    $('body').show();
}

function checkAccountSubmenu() {
    if(!accounts[usedAccount].main)
        $('#removeAccountButton').show();

    $('#navEdit').show();
    $('#navSend').show();
    $('#accountActionsHr').show();
    $('#accountActions').show();
    $('#accountActionsDeposit').show();
    $('#accountActionsHr').show();
    $('#accountActions').show();
    $('#accountActionsWithdraw').show();
}

function loadAccount(accountNumber) {
    if (!blocked) {
        blocked = true;
        $.post('https://fleecabank/action', JSON.stringify({
            account: accountNumber,
            action: "syncaccount"
        }));
    }
}

function confirmRemoveAccount() {
    if (!blocked) {
        blocked = true;
        $('#remove-bank-account').modal('hide');

        $.post('https://fleecabank/action', JSON.stringify({
            account: removeAccount,
            action: "delete"
        }));
    }
}

function removeAccountModal() {
    removeAccount = usedAccount;
    const accountData = accounts[usedAccount];

    $('#removeAccountNumber').text(usedAccount);
    $('#removeAccountName').text(accountData.name);
    $('#remove-bank-account').modal('show');

    if(accountData.balance > 0) {
        $('#remove-account-btn-confirm').hide();
        $('#remove-account-message').html("Na účtu se nachází zůstatek. Přesuňte ho nebo jej vyberte, abyste mohl úspěšně smazat účet.");
    }
    else {
        $('#remove-account-btn-confirm').show();
        $('#remove-account-message').html("Opravdu si přeješ smazat účet <strong id='removeAccountName'></strong> s číslem <strong id='removeAccountNumber'>" + usedAccount + "</strong>?<br><br><strong>Tato akce je nevratná! Smazáním účtu přijdeš o veškerý zůstatek na něm!</strong>");
    }
}

function setupBankAccounts() {
    $(".bankAccountSingle").remove();

    $.each(accounts, function (accountNumber, accountData) {
        $('#bankAccountsListRows').prepend(`<div class="col-12 col-sm-6 bankAccountSingle">
                <div class="account-card account-card-primary text-white rounded mb-4 mb-lg-0">
                  <div class="row no-gutters">
                    <div class="col-3 d-flex justify-content-center p-3">
                      <div class="my-auto text-center"> <span class="text-13"><i class="fas fa-university"></i></span>
                      </div>
                    </div>
                    <div class="col-9 border-left">
                      <div class="py-4 my-2 pl-4">
                        <p class="text-4 font-weight-500 mb-1">${accountData.data.account_name}</p>
                        <p class="text-4 opacity-9 mb-1">${accountNumber}</p>
                      </div>
                    </div>
                  </div>
                  <a href="#" onclick="loadAccount(${accountNumber})" class="text-light btn-link mx-2">
                  <div class="account-card-overlay rounded"> <span class="mr-1"><i class="fas fa-share"></i></span>Spravovat účet
                  </div>
                  </a> 
                </div>
              </div>`);
    });
}

(function () {
    if (wasBlocked) {
        wasBlocked = false;
        if (blocked) {
            blocked = false;
        }
    } else {
        if (blocked) {
            wasBlocked = true;
        }
    }

    setTimeout(arguments.callee, 250);
})();

$('.icp-dd').on('iconpickerSelected', function (event) {
    selectedIcon = event.iconpickerValue;
});