$(document).ready(function () {


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
        // dateLimit: {
        //     days: 6
        // },
        // locale: {
        //     customRangeLabel: 'Custom Range (Max 7 days)'
        // },
        ranges: {
            'Yesterday': [start, start],
            'Week To Day': [moment().startOf('week'), start],
            'Month To Day': [moment().startOf('month'), start],
            'Quarter To Day': [moment().startOf('quarter'), start]//TODO Change to financial Quarter
        }
    }, cb);
    cb(start, start);

    $('#reportrange').on('apply.daterangepicker', function (ev, picker) {
        // FIRE new request to load data
        var url = ReconView.getContextPath() + '/webapi/results/startDate/' + picker.startDate.format('YYYYMMDD') + '/endDate/' + picker.endDate.format('YYYYMMDD');
        serviceTable.ajax.url(url).load();
    });

    var url = ReconView.getContextPath() + '/webapi/results/startDate/' + start.format('YYYYMMDD') + '/endDate/' + start.format('YYYYMMDD');

    var serviceTable = $('#serviceTable').DataTable({
        ajax: {
            url: url,
            dataSrc: ""
        },
        scrollY: '70vh',
        scrollCollapse: true,
        scrollX: true,
        orderCellsTop: true,
        pageLength: 25,
        fixedColumns: true,
        columns: [
            // Changing or Adding columns will break functionality. Do it Cautiously.
            {data: 'wricef', defaultContent: ''},
            {data: 'source', width: '120px'},
            {data: 'target'},
            {data: 'interfaceName'},
            {data: 'srcTotal', defaultContent: ''},
            {data: 'srcSuccess', defaultContent: ''},
            {data: 'srcFailure', defaultContent: ''},
            {data: 'eisTotal', defaultContent: ''},
            {data: 'eisSuccess', defaultContent: ''},
            {data: 'eisFailure', defaultContent: ''},
            {data: 'sapTotal', defaultContent: ''},
            {data: 'sapSuccess', defaultContent: ''},
            {data: 'sapFailure', defaultContent: ''}
        ],
        columnDefs: [{
            "targets": [6, 9, 12],
            className: 'dt-right',
            fnCreatedCell: function (nTd,
                                     sData, oData, iRow, iCol) {
                if (sData > 0) {
                    var errorSrc = (iCol === 6) ? 'SRC' : (iCol === 9 ? 'EIS' : 'SAP');
                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                        + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=' + errorSrc + '">' + sData + '</a>';
                    $(nTd).html(htmlLink).addClass('error-cell');
                }
            }
        }, {
            targets: [1, 3],
            render: $.fn.dataTable.render.ellipsis(30)
        }, {
            targets: [4, 5, 8, 11, 10],
            className: 'dt-right'
        }, {
            targets: [7],
            className: 'dt-right',
            fnCreatedCell: function (nTd, sData, oData, iRow, iCol) {
                if ((oData.srcSuccess !== oData.eisTotal)) {
                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                        + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=EIS_MISS">' + sData + '</a>';

                    $(nTd).html(htmlLink).addClass('warning-cell');
                    $(nTd).attr('title', 'SRC Success is not same as EIS Total');
                }
            }
        }, {
            targets: [10],
            className: 'dt-right',
            fnCreatedCell: function (nTd, sData, oData, iRow, iCol) {
                if ((oData.eisSuccess !== oData.sapTotal)) {

                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                        + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=SAP_MISS">' + sData + '</a>';

                    $(nTd).html(htmlLink).addClass('warning-cell');
                    $(nTd).attr('title', 'EIS Success is not same as SAP Total');

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
        lengthChange: false
    });

    var buttons = new $.fn.dataTable.Buttons(serviceTable, {
        buttons: [{
            extend: 'excelHtml5',
            titleAttr: 'Export to Excel',
            text: '<span class="glyphicon glyphicon-download-alt"></span>',
            exportOptions: {
                modifier: {
                    page: 'current'
                }
            }
        }, {
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

    // Not required
    // $("#serviceTable_length").on('change', function () {
    //     serviceTable.page.len($(this).val()).draw();
    // });
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
});