$(document).ready(function () {


    var yesterday = moment().subtract(1, 'days');
    //var end = moment();
    var minDate = moment().subtract(100, 'days');

    function cb(startArg, endArg) {
        $('#reportrange span').html(startArg.format('MMMM D, YYYY') + ' - ' + endArg.format('MMMM D, YYYY'));
    }

    $('#reportrange').daterangepicker({
        startDate: yesterday,
        endDate: yesterday,
        maxDate: yesterday,
        minDate: minDate,
        // dateLimit: {
        //     days: 6
        // },
        // locale: {
        //     customRangeLabel: 'Custom Range (Max 7 days)'
        // },
        ranges: {
            'Yesterday': [yesterday, yesterday],
            'Week To Day': [moment().startOf('week'), yesterday],
            'Month To Day': [moment().startOf('month'), yesterday],
            'Quarter To Day': [ReconView.getFinancialQuarter(), yesterday]
        }
    }, cb);
    cb(yesterday, yesterday);

    $('#reportrange').on('apply.daterangepicker', function (ev, picker) {
        // FIRE new request to load data
        var url = ReconView.getContextPath() + '/webapi/results/startDate/' + picker.startDate.format('YYYYMMDD') + '/endDate/' + picker.endDate.format('YYYYMMDD');
        serviceTable.ajax.url(url).load();
    });

    var url = ReconView.getContextPath() + '/webapi/results/startDate/' + yesterday.format('YYYYMMDD') + '/endDate/' + yesterday.format('YYYYMMDD');

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
            // Changing or Adding columns will break functionality. Do it Cautiously!!!
            {data: 'wricef', width: '40px'},
            {data: 'source', width: '75px'},
            {data: 'target', width: '40px'},
            {data: 'interfaceName', width: '80px'},
            {data: 'srcTotal', defaultContent: ''},
            {data: 'srcSuccess', defaultContent: ''},
            {data: 'srcFailure', defaultContent: ''},
            {data: 'eisTotal', defaultContent: ''},
            {data: 'eisMissing', defaultContent: ''},
            {data: 'eisSuccess', defaultContent: ''},
            {data: 'eisFailure', defaultContent: ''},
            {data: 'tgtTotal', defaultContent: ''},
            {data: 'tgtMissing', defaultContent: ''},
            {data: 'tgtSuccess', defaultContent: ''},
            {data: 'tgtFailure', defaultContent: ''}
        ],
        columnDefs: [{
            "targets": [6, 10, 14],
            className: 'dt-right',
            fnCreatedCell: function (nTd,
                                     sData, oData, iRow, iCol) {
                if (sData > 0) {
                    var errorSrc = (iCol === 6) ? 'SRC' : (iCol === 10 ? 'MW' : 'TGT');
                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                        + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=' + errorSrc + '">' + sData + '</a>';
                    $(nTd).html(htmlLink).addClass('error-cell');
                }
            }
        }, {
            targets: [1, 3],
            render: $.fn.dataTable.render.ellipsis(30)
        }, {
            targets: [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            className: 'dt-right'
        }, {
            targets: [8],
            fnCreatedCell: function (nTd, sData, oData, iRow, iCol) {
                if (oData.eisMissing > 0) {

                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                        + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=MW_MISS">' + sData + '</a>';

                    $(nTd).html(htmlLink).addClass('warning-cell');
                    $(nTd).attr('title', 'SRC Success is not same as MW Total');
                }
            }
        }, {
            targets: [12],
            fnCreatedCell: function (nTd, sData, oData, iRow, iCol) {

                if (oData.tgtMissing > 0) {

                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate=' + oData.startDate
                        + '&eDate=' + oData.endDate + '&wricef=' + oData.wricef + '&errors=TGT_MISS">' + sData + '</a>';

                    $(nTd).html(htmlLink).addClass('warning-cell');
                    $(nTd).attr('title', 'MW Success is not same as Target Total');

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