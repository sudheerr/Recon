$(document).ready(function (ReconView) {


    var sDate = ReconView.getURLParameter('sDate');
    var eDate = ReconView.getURLParameter('eDate');
    var wricef = ReconView.getURLParameter('wricef');
    var errorLoc = ReconView.getURLParameter('errors');
    var currencyCode = ReconView.getURLParameter('currencyCode');

    //#TODO need to perform validation for all fields
    if (['SRC', 'MW', 'TGT', 'MW_MISS', 'TGT_MISS'].indexOf(errorLoc) === -1) {
        showErrorDialog('Not a valid Error Code. Valid values are SRC, MW, TGT, MW_MISS and TGT_MISS.');
        return;
    }

    //Listening to grid init event, then configure additional settings.
    $('#serviceTable').on('init.dt', function (e, settings) {
        var api = new $.fn.dataTable.Api(settings);

        $("#serviceTable_length").on('change', function () {
            api.table().page.len($(this).val()).draw();
        });

        // Apply the filter
        $("#filterrow input").on('keyup change', function () {
            var column = serviceTable.column($(this).parent().parent().index() + ':visible');
            column.search(this.value).draw();
            var header = $(column.header());
            if (!this.value) {
                header.removeClass('appliedFilter');
            } else {
                header.addClass('appliedFilter');
            }
        });

        var buttons = new $.fn.dataTable.Buttons(api.table(), {
            buttons: [{
                extend: 'excelHtml5',
                titleAttr: 'Export to Excel',
                text: '<span class="glyphicon glyphicon-download-alt"></span>',
                exportOptions: {
                    modifier: {
                        page: 'current'
                    }
                }
                },{
                    titleAttr: 'Toggle Filter',
                    text: '<span class="glyphicon glyphicon-filter"></span>',
                    action: function () {
                        $('#filterrow').toggle();
                    }
                }, {
                    titleAttr: 'Clear ALL Filters',
                    text: '<span class="glyphicon glyphicon-remove-circle"></span>',
                    action: function () {
                        $('#filterrow').find('input').each(function (index, input) {
                            $(input).val('');
                        });
                        serviceTable.columns().search('').draw();
                        $(serviceTable.columns().header()).removeClass('appliedFilter');
                    }
            }, {
                titleAttr: 'Export to Excel',
                text: '<span class="glyphicon glyphicon-download-alt"></span>',
                action: function () {
                    if (ReconView.isSafari()) {
                        $('#dialog3').dialog('open');
                    } else {
                        $('#dialog2').dialog('open');
                    }
                }
            }
            ],
            dom: {
                container: {
                    tag: 'span',
                    className: 'pull-right svcBtn'
                },
                buttonContainer: {
                    tag: 'span'
                },
                button: {
                    tag: 'a',
                    className: 'btn'
                }
            }
        }).container().appendTo($('#serviceTableHeader'));

//        setTimeout(function () {
//            $("#serviceDetailsBody").collapse();
//        }, 2000);
    });

    var url = ReconView.getContextPath() + '/webapi/details/' + wricef + '/' + errorLoc + '/startDate/' + sDate + '/endDate/' + eDate;
    if (currencyCode) {
        url += '/currencyCode/' + currencyCode;
    }

    $.ajax({
        url: url,
        dataType: 'json'
    }).done(function (response) {
        if (response) {
            if (response.errorFlag) {
                showErrorDialog(response.errorMsg);
                return;
            }

            fillDetailsForm(response);

            initializeGrid(response.columns, response.data);
        }
    });

    function fillDetailsForm(response) {
        var formControls = $('#serviceDetails .form-control');
        formControls[0].textContent = response.startDate;
        formControls[1].textContent = response.source;
        formControls[2].textContent = response.interfaceName;
        formControls[4].textContent = response.target;
        formControls[3].textContent = response.endDate;
        formControls[5].textContent = response.wricef;

        var tempVar ='';
        if(errorLoc === 'SRC'){
            tempVar = response.source + ' Error Report';
        }else if(errorLoc === 'TGT'){
            tempVar = response.target + ' Error Report';
        }else if(errorLoc === 'MW'){
            tempVar = 'Middleware Error Report';
        }else if(errorLoc === 'MW_MISS'){
            tempVar = 'Middleware Missing Transaction Report';
            formControls[4].textContent = 'Middleware';
        }else if(errorLoc === 'TGT_MISS'){
            tempVar = response.target + ' Missing Transaction Report';
            formControls[1].textContent = 'Middleware';
        }
       $('#serviceTableHeader span').text(tempVar);
    }

    function showErrorDialog(text) {
        $("#reconDialog p").text(text);
        $("#reconDialog").dialog({
            modal: true,
            dialogClass: "no-close",
            buttons: [{
                text: "OK",
                click: function () {
                    $(this).dialog("close");
                }
            }]
        });
    }

    function initializeGrid(columns, data) {

        //Create FilterRow before initialization,
        //otherwise the filterrow is getting removed when table redrawn.(As this is a Dynamic Grid)

        var trow ='<tr>';
        var trow2 ='<tr id="filterrow" style="display: none;">';
        for(var i=0;i<columns.length;i++){
            trow+='<th>'+columns[i].colTitle+'</th>';
            trow2+='<th><div class="rounded"><input style="width:100%" type="text"/></div></th>';
        }
        trow+='</tr>'+trow2+'</tr>';

        $('#serviceTable thead').append(trow);

        serviceTable = $('#serviceTable').DataTable({
            data: data,
            scrollY: '70vh',
            scrollCollapse: true,
            pageLength: 25,
            columns: columns,
            fixedColumns: true,
            orderCellsTop: true,
            columnDefs: [{
                targets: '_all',
                render: function (data, type, row, meta) {
                    if (meta.settings.aoColumns[meta.col].columnType == 'NUMBER') {
                        data = parseInt(data, 10);
                        return data.toFixed(0).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
                    }
                    if (meta.settings.aoColumns[meta.col].columnType == 'CURRENCY') {
                        data = parseInt(data, 10);
                        if (Number.isNaN(data)) {
                            return 0;
                        }
                        if (data > 0) {
                            var curSymbol = ReconView.getSymbolFromCurrency(row.currency);
                            return (curSymbol ? curSymbol : '') + data.toFixed(0).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
                        }
                        return data.toFixed(0).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
                    }
                    return data;
                }
            }],
            language: {
                info: "<strong>_START_</strong>-<strong>_END_</strong> of <strong>_TOTAL_</strong>",
                infoFiltered: "(filtered from _MAX_ total entries)",
                infoPostFix: "",
                paginate: {
                    next: "<i class='glyphicon glyphicon-menu-right'></i>",
                    previous: "<i class='glyphicon glyphicon-menu-left'></i>"
                }
            },
            lengthChange: false
        });
    }

}(ReconView));