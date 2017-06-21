$(document).ready(function () {

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

    var start = moment().subtract(1, 'days');
    var end = moment();
    var minDate = moment().subtract(100, 'days');

    function cb(startArg, endArg) {
        $('#reportrange span').html(startArg.format('MMMM D, YYYY') + ' - ' + endArg.format('MMMM D, YYYY'));
    }

    $('#reportrange').daterangepicker({
        startDate: start,
        endDate: start,
        maxDate: start,
        minDate: minDate,
        dateLimit: {
            days: 6
        },
        ranges: {
            'Yesterday': [start, start],
            'Week To Day': [moment().startOf('week'), moment().endOf('week')],
            'Month To Day': [moment().startOf('month'), moment().endOf('month')]//,
            //'Quarter To Day': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
        }
    }, cb);
    cb(start, start);

    $('#reportrange').on('apply.daterangepicker', function (ev, picker) {
        // FIRE new request to load data
        var url = ReconView.getContextPath() + '/webapi/orderResults/startDate/' + picker.startDate.format('YYYYMMDD') + '/endDate/' + picker.endDate.format('YYYYMMDD');
        serviceTable.ajax.url(url).load();
    });

    var url = ReconView.getContextPath() + '/webapi/orderResults/startDate/' + start.format('YYYYMMDD') + '/endDate/' + start.format('YYYYMMDD');

    var serviceTable = $('#serviceTable').DataTable({
        ajax: {
            url: url,
            dataSrc: ""
        },
        scrollX: true,
        orderCellsTop: true,
        pageLength: 25,
        //Note: Changing/Adding columns might break functionality. Do it cautiously.
        columns: [
            {data: 'wricef', defaultContent: ''},
            {data: 'source'},
            {data: 'target'},
            {data: 'currency'},
            {data: 'srcCount', defaultContent: 0},
            {data: 'srcTotal', defaultContent: 0},
            {data: 'srcSuccess', defaultContent: 0},
            {data: 'srcFailure', defaultContent: 0},
            {data: 'eisTotal', defaultContent: 0},
            {data: 'eisSuccess', defaultContent: 0},
            {data: 'eisFailure', defaultContent: 0},
            {data: 'sapTotal', defaultContent: 0},
            {data: 'sapSuccess', defaultContent: 0},
            {data: 'sapFailure', defaultContent: 0}
        ],
        columnDefs: [
            {
                targets: [0,2],
                render: $.fn.dataTable.render.ellipsis(30)
            },{
                targets: [5,6,7,8,9,10,11,12,13],
                className: 'dt-right',
                render: function (data, type, row) {
                    return data.toFixed(0).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
                }
            }, {
                targets: [7,10,13],
                fnCreatedCell: function (nTd, sData, oData, iRow, iCol) {
                    if (sData > 0) {
                       var errorSrc =  (iCol===7)?'SRC':(iCol===10?'EIS':'SAP');
                                           var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                                               + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors='+errorSrc
                                               + '&currencyCode='+oData.currency+'">' + sData + '</a>';
                       $(nTd).html(htmlLink).addClass('error-cell');
                   }
                }
            }, {
                 targets: [8],
                 fnCreatedCell: function (nTd, sData, oData, iRow, iCol) {
                   if((oData.srcSuccess !== oData.eisTotal)){
                         var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                                                                         + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=SRC'
                                                                         + '&currencyCode='+oData.currency+'">' + sData + '</a>';
                         $(nTd).html(htmlLink).addClass('warning-cell');
                         $(nTd).attr('title', 'SRC Success is not same as EIS Total');
                     }
                 }
             }
        ],
        language: {
            info: "<strong>_START_</strong>-<strong>_END_</strong> of <strong>_TOTAL_</strong>",
            infoFiltered: "(filtered from _MAX_ total entries)",
            infoPostFix: "",
            paginate: {
                next: "<i class='glyphicon glyphicon-menu-right'></i>",
                previous: "<i class='glyphicon glyphicon-menu-left'></i>"
            }
        },
        lengthChange: false,
        footerCallback: function (row, data, start, end, display) {
            var api = this.api(), data;

            // Remove the formatting to get integer data for summation
            var intVal = function (i) {
                return typeof i === 'string' ?
                    i.replace(/[\$,]/g, '') * 1 :
                    typeof i === 'number' ?
                        i : 0;
            };

            for (var i = 5; i <= 13; i++) {
                var total = api
                    .column(i)
                    .data()
                    .reduce(function (a, b) {
                        return intVal(a) + intVal(b);
                    }, 0);

                $(api.column(i).footer()).html(total.toFixed(0).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,"));
            }
            /*
             // Total over all pages
             total = api
             .column( 4 )
             .data()
             .reduce( function (a, b) {
             return intVal(a) + intVal(b);
             }, 0 );

             // Total over this page
             pageTotal = api
             .column( 4, { page: 'current'} )
             .data()
             .reduce( function (a, b) {
             return intVal(a) + intVal(b);
             }, 0 );

             // Update footer
             $( api.column( 4 ).footer() ).html(
             '$'+pageTotal +' ( $'+ total +' total)'
             );*/
        }
    });

    var buttons = new $.fn.dataTable.Buttons(serviceTable, {
        buttons: [{
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
            extend: 'excelHtml5',
            titleAttr: 'Export to Excel',
            text: '<span class="glyphicon glyphicon-download-alt"></span>',
            exportOptions: {
                modifier: {
                    page: 'current'
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


    $("#serviceTable_length").on('change', function () {
        serviceTable.page.len($(this).val()).draw();
    });

});
