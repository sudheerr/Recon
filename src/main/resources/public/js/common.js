var ReconView = (function() {

    function getContextPath() {
        return window.location.pathname.substring(0, window.location.pathname.indexOf("/",2));
    };

    function getURLParameter(sParam) {
        var sPageURL = window.location.search.substring(1);
        var sURLVariables = sPageURL.split('&');
        for (var i = 0; i < sURLVariables.length; i++) {
            var sParameterName = sURLVariables[i].split('=');
            if (sParameterName[0] === sParam) {
                return sParameterName[1];
            }
        }
    };

    function isSafari() {
        var ua = navigator.userAgent.toLowerCase();
        if (ua.indexOf('safari') !== -1) {
            return ua.indexOf('chrome') <= -1;
        }
        return false;
    }

    var currMap={AED:"د.إ",AFN:"؋",ALL:"L",ANG:"ƒ",AOA:"Kz",ARS:"$",AUD:"$",AWG:"ƒ",AZN:"₼",BAM:"KM",BBD:"$",BDT:"৳",BGN:"лв",BHD:".د.ب",BIF:"FBu",BMD:"$",BND:"$",BOB:"Bs.",BRL:"R$",BSD:"$",BTC:"฿",BTN:"Nu.",BWP:"P",BYR:"p.",BZD:"BZ$",CAD:"$",CDF:"FC",CHF:"Fr.",CLP:"$",CNY:"¥",COP:"$",CRC:"₡",CUC:"$",CUP:"₱",CVE:"$",CZK:"Kč",DJF:"Fdj",DKK:"kr",DOP:"RD$",DZD:"دج",EEK:"kr",EGP:"£",ERN:"Nfk",ETB:"Br",ETH:"Ξ",EUR:"€",FJD:"$",FKP:"£",GBP:"£",GEL:"₾",GGP:"£",GHC:"₵",GHS:"GH₵",GIP:"£",GMD:"D",GNF:"FG",GTQ:"Q",GYD:"$",HKD:"$",HNL:"L",HRK:"kn",HTG:"G",HUF:"Ft",IDR:"Rp",ILS:"₪",IMP:"£",INR:"₹",IQD:"ع.د",IRR:"﷼",ISK:"kr",JEP:"£",JMD:"J$",JPY:"¥",KES:"KSh",KGS:"лв",KHR:"៛",KMF:"CF",KPW:"₩",KRW:"₩",KYD:"$",KZT:"₸",LAK:"₭",LBP:"£",LKR:"₨",LRD:"$",LSL:"M",LTC:"Ł",LTL:"Lt",LVL:"Ls",MAD:"MAD",MDL:"lei",MGA:"Ar",MKD:"ден",MMK:"K",MNT:"₮",MOP:"MOP$",MUR:"₨",MVR:"Rf",MWK:"MK",MXN:"$",MYR:"RM",MZN:"MT",NAD:"$",NGN:"₦",NIO:"C$",NOK:"kr",NPR:"₨",NZD:"$",OMR:"﷼",PAB:"B/.",PEN:"S/.",PGK:"K",PHP:"₱",PKR:"₨",PLN:"zł",PYG:"Gs",QAR:"﷼",RMB:"￥",RON:"lei",RSD:"Дин.",RUB:"₽",RWF:"R₣",SAR:"﷼",SBD:"$",SCR:"₨",SDG:"ج.س.",SEK:"kr",SGD:"$",SHP:"£",SLL:"Le",SOS:"S",SRD:"$",SSP:"£",STD:"Db",SVC:"$",SYP:"£",SZL:"E",THB:"฿",TJS:"SM",TMT:"T",TND:"د.ت",TOP:"T$",TRL:"₤",TRY:"₺",TTD:"TT$",TVD:"$",TWD:"NT$",TZS:"TSh",UAH:"₴",UGX:"USh",USD:"$",UYU:"$U",UZS:"лв",VEF:"Bs",VND:"₫",VUV:"VT",WST:"WS$",XAF:"FCFA",XBT:"Ƀ",XCD:"$",XOF:"CFA",XPF:"₣",YER:"﷼",ZAR:"R",ZWD:"Z$"};
    function getSymbolFromCurrency(symbol){
        return currMap[symbol];
    };
    return {
        getURLParameter: getURLParameter,
        getContextPath:getContextPath,
        getSymbolFromCurrency: getSymbolFromCurrency,
        isSafari:isSafari
    };
})();


$(document).ready(function($){

    //Load header page
    $("#header").load("header.html", function () {
        var userDetUrl = ReconView.getContextPath()+'/webapi/user';
        $.ajax({
            url: userDetUrl,
        }).done(function (data) {
            if(data){
                $('#user-name-label').text(data.userName);
            }
        });
    });

    //Load footer page
    $("#footer").load("footer.html");

    // browser window scroll (in pixels) after which the "back to top" link is shown
    var offset = 200,
        //browser window scroll (in pixels) after which the "back to top" link opacity is reduced
        offset_opacity = 1200,
        //duration of the top scrolling animation (in ms)
        scroll_top_duration = 700,
        //grab the "back to top" link
        $back_to_top = $('.cd-top');

    //hide or show the "back to top" link
    $(window).scroll(function(){
        ( $(this).scrollTop() > offset ) ? $back_to_top.addClass('cd-is-visible') : $back_to_top.removeClass('cd-is-visible cd-fade-out');
        if( $(this).scrollTop() > offset_opacity ) {
            $back_to_top.addClass('cd-fade-out');
        }
    });

    //smooth scroll to top
    $back_to_top.on('click', function(event){
        event.preventDefault();
        $('body,html').animate({
                scrollTop: 0 ,
            }, scroll_top_duration
        );
    });

    $body = $("body");
    $(document).on({
        ajaxStart: function () {
            $body.addClass("loading");
        },
        ajaxStop: function () {
            $body.removeClass("loading");
        }
    });

    // Inserting row to filtering
    $('#serviceTable thead tr#filterrow th').each(function () {
        $(this).html('<div class="rounded"><input style="width:100%" type="text"/></div>');
    });

// Initialize dialog's
    var dialog3 = $("#dialog3").dialog({
        autoOpen: false,
        modal: true,
        height: 150,
        width: 400,
        dialogClass: "no-close",
        buttons: [{
            text: "Ok",
            click: function() {
                $(this).dialog('close');
            }
        }]
    });
    if(dialog3.length){
        dialog3.data("uiDialog")._title = function(title) {
            title.html(this.options.title);
        };
        dialog3.dialog('option', 'title', '<i class="glyphicon glyphicon-info-sign" aria-hidden="true"></i> Information');
    }

    var dialog2 = $("#dialog2").dialog({
        autoOpen: false,
        modal: true,
        height: 180,
        width: 400,
        dialogClass: "no-close",
        buttons: [{
            text: "Ok",
            click: function() {
                var table = $('#serviceTable').DataTable();
                $(this).dialog('close');
                table.button('0').trigger();
            }
        }]
    });
    if(dialog2.length){
        dialog2.data("uiDialog")._title = function(title) {
            title.html(this.options.title);
        };
        dialog2.dialog('option', 'title', '<i class="glyphicon glyphicon-info-sign" aria-hidden="true"></i> Information');
    }
});