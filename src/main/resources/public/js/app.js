$(document).ready(function() {
    $body = $("body");
    $(document).on({
        ajaxStart: function() { $body.addClass("loading");    },
        ajaxStop: function() { $body.removeClass("loading"); }
    });

    // Inserting row to filtering
    // $('#serviceTable thead tr#filterrow th').each(function() {
    //     $(this).html('<div class="rounded"><input style="width:100%" type="text"/></div>');
    // });

    var start = moment().subtract(1, 'days');
    var end = moment();
    var minDate= moment().subtract(100, 'days');

    function cb(startArg, endArg) {
        $('#reportrange span').html(startArg.format('MMMM D, YYYY') + ' - ' + endArg.format('MMMM D, YYYY'));
    }

    $('#reportrange').daterangepicker({
        startDate: start,
        endDate: start,
        maxDate:start,
        minDate:minDate,
        dateLimit:{
            days:6
        },
        ranges: {
            'Yesterday': [start, start],
            'Week To Day': [moment().startOf('week'), moment().endOf('week')],
            'Month To Day': [moment().startOf('month'), moment().endOf('month')]//,
            //'Quarter To Day': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
        }
    }, cb);
    cb(start, start);

    $('#reportrange').on('apply.daterangepicker', function(ev, picker) {
        // FIRE new request to load data
        var url = ReconView.getContextPath()+'/webapi/results/startDate/'+picker.startDate.format('YYYYMMDD')+'/endDate/'+picker.endDate.format('YYYYMMDD');
        serviceTable.ajax.url(url).load();
    });

    var url = ReconView.getContextPath()+'/webapi/results/startDate/'+start.format('YYYYMMDD')+'/endDate/'+start.format('YYYYMMDD');

    var serviceTable = $('#serviceTable').DataTable({
        ajax: {
            url:url,
            dataSrc: ""
        },
        scrollY:'70vh',
        scrollCollapse: true,
        scrollX: true,
        orderCellsTop: true,
        pageLength: 25,
        fixedColumns:true,
        columns: [
            { data: 'wricef', defaultContent: '' },
            { data: 'source', width: '120px' },
            { data: 'target'},
            { data: 'interfaceName'},
            { data: 'srcTotal',  defaultContent: '' },
            { data: 'srcSuccess',  defaultContent: '' },
            { data: 'srcFailure', defaultContent: '' },
            { data: 'eisTotal', defaultContent: '' },
            { data: 'eisSuccess', defaultContent: '' },
            { data: 'eisFailure', defaultContent:''},
            // { data: 'flowDirection', defaultContent: '' },
            { data: 'sapTotal',  defaultContent: '' },
            { data: 'sapSuccess',  defaultContent: '' },
            { data: 'sapFailure', defaultContent: '' }
        ],
        columnDefs : [{
            "targets" : 12,
            className:'dt-right',
            fnCreatedCell : function(nTd,
                                     sData, oData, iRow, iCol) {
                if (sData > 0) {
                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate='+oData.startDate
                        +'&eDate='+oData.endDate+'&wricef='+oData.wricef+'&errors=SAP">'+sData+'</a>';
                    $(nTd).html(htmlLink).addClass('error-cell');
                }
            }
        } , {
            "targets" : 9,
            className:'dt-right',
            fnCreatedCell : function(nTd,
                                     sData, oData, iRow, iCol) {
                if (sData > 0) {
                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate='+oData.startDate
                        +'&eDate='+oData.endDate+'&wricef='+oData.wricef+'&errors=EIS">'+sData+'</a>';
                    $(nTd).html(htmlLink).addClass('error-cell');

                }
            }
        } ,{
            "targets" : 6,
            className:'dt-right',
            fnCreatedCell : function(nTd,
                                     sData, oData, iRow, iCol) {
                if (sData > 0) {
                    var htmlLink = '<a target="_blank" href="recon-detail.html?sDate='+oData.startDate
                        +'&eDate='+oData.endDate+'&wricef='+oData.wricef+'&errors=SRC">'+sData+'</a>';
                    $(nTd).html(htmlLink).addClass('error-cell');
                }
            }
        },
            // {	"targets": 10,
            //    className:"dt-center",
            //     "render": function ( data, type, row ) {
            //     	if(data && data.indexOf('I')===0){
            //     		  return '<span class="glyphicon glyphicon-arrow-right"></span>';
            //     	}else{
            //     		 return '<span class="glyphicon glyphicon-arrow-left"></span>';
            //     	}
            //     }
            // },
            {
                targets: 1,
                render: $.fn.dataTable.render.ellipsis(20)
            },{
                targets: 3,
                render: $.fn.dataTable.render.ellipsis(30)
            },{
                targets: 4,
                className:'dt-right'
            },{
                targets: 5,
                className:'dt-right'
            },{
                targets: 7,
                className:'dt-right',
                fnCreatedCell : function(nTd,
                                         sData, oData, iRow, iCol) {
                    if (oData.srcSuccess !== oData.eisTotal) {
                        $(nTd).addClass('warning-cell');
                        $(nTd).attr('title','SRC Success is not same as EIS Total');
                    }
                }
            },{
                targets: 8,
                className:'dt-right'
            },{
                targets: 10,
                className:'dt-right',
                fnCreatedCell : function(nTd,sData, oData, iRow, iCol) {
                    if (oData.eisSuccess !== oData.sapTotal) {
                        $(nTd).addClass('warning-cell');
                        $(nTd).attr('title','EIS Success is not same as SAP Total');
                    }
                }
            },{
                targets: 11,
                className:'dt-right'
            }
        ],
        language: {
            info:           "<strong>_START_</strong>-<strong>_END_</strong> of <strong>_TOTAL_</strong>",
            infoFiltered:   "(filtered from _MAX_ total entries)",
            infoPostFix:    "",
            paginate: {
                next: "<i class='glyphicon glyphicon-menu-right'></i>",
                previous: "<i class='glyphicon glyphicon-menu-left'></i>"
            }
        },
        lengthChange: false
    });

    var buttons = new $.fn.dataTable.Buttons(serviceTable, {
        buttons: [{
            titleAttr: 'Toggle Filter',
            text: '<span class="glyphicon glyphicon-filter"></span>',
            action: function() {
                $('#filterrow').toggle();
            }
        },{
            titleAttr: 'Clear ALL Filters',
            text: '<span class="glyphicon glyphicon-remove-circle"></span>',
            action: function() {
                $('#filterrow').find('input').each(function(index, input) { $(input).val(''); });
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
    $("#filterrow input").on('keyup change', function() {
        var column  = serviceTable.column($(this).parent().parent().index() + ':visible');
        column.search(this.value).draw();
        var header = $(column.header());
        if(!this.value){
            header.removeClass('appliedFilter');
        }else{
            header.addClass('appliedFilter');
        }
    });

    $("#serviceTable_length").on('change', function() {
        serviceTable.page.len( $(this).val() ).draw();
    });

});