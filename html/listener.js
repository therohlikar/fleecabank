var accounts = null;
var inMachine = false;
var inMachineAccount = null;

var currentPermissions = null;
var selectedAccount = 0;

var blockInput = false;

document.onkeyup = function (data) {
    if (data.which === 27) {
        closePanel();
    }
};

function formatCurrency(price) {
    var currency = new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
        maximumFractionDigits: 0
    })
    return currency.format(price)
}
$(function () {
	window.addEventListener('message', function (event) {
		switch (event.data.action) {
			case 'show-machine':
				$('#box').show();
				inMachine = true;

				selectedAccount = event.data.account.number;
				inMachineAccount = event.data.account;
				settings = event.data.settings;

				openmenu("cash-machine");
				opencontent('cashmachine-login');	
				break;
			case 'hide-machine':
				inMachine = false;
				$('#box').hide();
				break;
			case 'show':
				$('#box').show();	
				inMachine = false;

				selectedAccount = 0;
				accounts = event.data.accounts;
				settings = event.data.settings;

				openmenu("main");
				opencontent('accountlist');
				break;
			case 'hide':
				$('#box').hide();
				break;
            case 'updateaccounts':
                selectedAccount = 0;
                accounts = event.data.accounts;

                if(event.data.delete) settings.count--;

                blockInput = false;

                openmenu("main");
                opencontent('accountlist');
                break;
			case 'updateaccount':
			    var newAccountNumber = event.data.account.number
				accounts[newAccountNumber] = event.data.account

				/* sync values which can be changed */
				selectaccount(event.data.account.number);
				update(event.data.account);

				blockInput = false;

				if(event.data.newAccount) settings.count++;

				break;
			default:
				console.log('ui_fleecabank: unknown action!');
				break;
		}
	}, false);
});

function rename(){
	if($('#input-text').val() == "" || $('#input-text').val().length > 50) return; 

	$.post("http://fleecabank/action", JSON.stringify({
		action: "rename",
		account: selectedAccount,
		value: $('#input-text').val()
	}));
}

function cash(action){
	if($('#input-number').val() <= 0) return; 

	$.post("http://fleecabank/action", JSON.stringify({
		action: "cash",
		subaction: action,
		account: selectedAccount,
		value: $('#input-number').val()
	}));

	$('#input-number').val('');
}

function transfer(){
	if($('#input-number').val() <= 0) return; 
	if($('#input-text').val() == "") return; 

	$.post("http://fleecabank/action", JSON.stringify({
		action: "transfer",
		account: selectedAccount,
		target: $('#input-text').val(),
		value: $('#input-number').val()
	}));

	$('#input-number').val(0);
	$('#input-text').val("");
}

function update(account){
	var number = account.number;
	$('.balance-' + number).html(formatCurrency(account.balance));
	$('.description-' + number).html(account.data.account_name);
}

function selectaccount(index){
    selectedAccount = index;
    openmenu("account");
    opencontent("information");

    blockInput = false;
}

function syncaccount(index){
    if(!blockInput){
        blockInput = true;

        $.post("http://fleecabank/action", JSON.stringify({
            action: "syncaccount",
            account : index
        }));
    }
}

function createaccount(){
    if(!blockInput){
        blockInput = true;
        $.post("http://fleecabank/action", JSON.stringify({
            action: "createaccount"
        }));
    }
}

function deleteaccount(){
    if(!blockInput){
        blockInput = true;
        $.post("http://fleecabank/action", JSON.stringify({
            action: "delete",
            account: selectedAccount
        }));
    }
}

function opencontent(name){
	if(name == "accountlist"){
		openmenu("main");

		$('#content').html('<ul>');
		var count = 0;
		$.each(accounts, function(k, v) {
		    count++;
            $('#content').append("<li onclick='syncaccount(" + k + ")' class='list-point activate'><span class='to-the-left type-" + k + "'>OSOBNÍ ÚČET: " + k + "</span><span class='in-the-middle description-"+ k + "'>" + v.data.account_name + "</span></li>");
		});

		if(count<=0){
			$('#content').append("<li onclick=\"opencontent('newaccount')\" class='list-point activate'>NEMÁTE ŽÁDNÝ DOSTUPNÝ ÚČET</li>");
		}
		
		$('#content').append('</ul>');
	}else if(name == "newaccount"){
		openmenu("main");
        $('#content').html("");
		if(settings.count >= settings.maxAccounts){
			$('#content').html("<div onclick=\"opencontent('accountlist')\" class='list-point red-activate'>SPRAVUJETE JIŽ MAXIMÁLNÍ MNOŽSTVÍ ÚČTŮ</div>");
		}else{
			$('#content').append("<div onclick=\"createaccount()\" class='list-point activate'>Otevřít nový účet</div>");
		}
	}else if(name == "information"){
		$('#content').html("<div onclick=\"copyToClipboard(accountnumber)\" class='list-point activate'>Číslo účtu: <span class='to-the-right' id='accountnumber'>" + selectedAccount + "</span></div>");
		$('#content').append("<div class='list-point'>Typ účtu: <span class='to-the-right type-" + selectedAccount + "'>OSOBNÍ ÚČET</span></div>");
		$('#content').append("<div class='list-point'>Aktuální stav účtu: <span class='to-the-right balance-" + selectedAccount + "'>" + formatCurrency(accounts[selectedAccount].balance) + "</span></div>");
		$('#content').append("<div onclick=\"opencontent('edit_description')\" class='list-point activate'>Název účtu: <span class='to-the-right description-" + selectedAccount + "'>" + accounts[selectedAccount].data.account_name + "</span></div>");
		if(!accounts[selectedAccount].main) $('#content').append("<div onclick=\"opencontent('delete')\" class='list-point red-activate'>Permanentně smazat účet</div>");
		else $('#content').append("<div class='red-point list-point'>Účet je označen jako hlavní, nelze smazat</div>");
	}else if(name == "transfers"){
        $('#content').html("");
        $('#content').append("<div class='list-point'>Aktuální stav účtu: <span class='balance-" + selectedAccount + "'>" + formatCurrency(accounts[selectedAccount].balance) + "</span></div>");
        $('#content').append("<div class='block'><input type='text' id='input-text' placeholder='Protiúčet' maxlength='10'><input type='number' id='input-number' value='0' min='0'><button onclick='transfer()' class='activate' type='submit' id='btn-transfer'>Zpracovat platbu</button></div>");
	}else if(name == "delete"){
		$('#content').html("<div onclick=\"opencontent('information')\" class='list-point activate'>Ponechat účet</div><div onclick=\"deleteaccount()\" class='list-point red-activate'>Permatnentně smazat účet</div>");
	}else if(name == "cash"){
		$('#content').html("");
		$('#content').append("<div class='list-point'>Aktuální stav účtu: <span class='balance-" + selectedAccount + "'>" + formatCurrency(accounts[selectedAccount].balance) + "</span></div>");
		$('#content').append("<div class='block'><input type='number' id='input-number' placeholder='0' min='0'><button onclick='cash(\"deposit\")' class='activate' type='submit' id='btn-deposit'>Vložit peníze na účet</button><button onclick='cash(\"withdraw\")' class='activate' type='submit' id='btn-withdraw'>Vybrat peníze z účtu</button></div>");
		$('#btn-deposit').show();
		$('#btn-withdraw').show();
	}else if(name == "edit_description"){
		$('#content').html("<div class='list-point'>Aktuální název účtu: <span class='description-" + selectedAccount + "'>" + accounts[selectedAccount].data.account_name + "</span></div><div class='block'><input type='text' id='input-text' value='" + accounts[selectedAccount].data.account_name + "'><button onclick=\"rename()\" class='activate' type='submit' id='btn-rename'>Přejmenovat účet</button></div>");
	}else if(name == "cashmachine-login"){
		$('#content').html("<div class='block'><input type='text' id='input-text' placeholder='Zadejte přístupový kód'><button onclick=\"logincard()\" class='activate' type='submit' id='btn-card-login'>Vstoupit</button></div>");
	}else if(name == "cash-machine"){
		$('#content').html("<div class='list-point'>Aktuální stav účtu: <span class='balance-" + selectedAccount + "'>$" + inMachineAccount.balance + "</span></div>");
		$('#content').append("<div class='block'><input type='number' id='input-number' placeholder='0' min='0'><button onclick='cash(\"deposit\")' class='activate' type='submit' id='btn-deposit'>Vložit peníze na účet</button><button onclick='cash(\"withdraw\")' class='activate' type='submit' id='btn-withdraw'>Vybrat peníze z účtu</button></div>");
	}
}

function openmenu(name){
	if(name == "main"){
		selectedAccount = 0;

		$('#logged-menu').hide();
		$('#cashmachine-menu').hide();
		$('#unlogged-menu').show();
	}else if(name == "account"){
		$('#unlogged-menu').hide();
		$('#cashmachine-menu').hide();
		$('#logged-menu').show();
	}else{
		$('#logged-menu').hide();
		$('#cashmachine-menu').show();
		$('#unlogged-menu').hide();
	}
}

function closePanel(){
	$.post('http://fleecabank/closepanel', JSON.stringify({}));
}

function notify(type, title, text){
	$.post("http://bank/notify", JSON.stringify({
		type: type,
		title: title,
		text: text
	}));
}

function copyToClipboard(element) {
	var $temp = $("<input>");
	$("body").append($temp);
	$temp.val($(element).html()).select();
	document.execCommand("copy");
	$temp.remove();
}