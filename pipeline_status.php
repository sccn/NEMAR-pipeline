<?php
copy('/data/qumulo/openneuro/processed/logs/pipeline_status_all.html', 'pipeline_status_all.html');
?>
<html lang="en">
        <head>
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
        <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.10.20/datatables.min.css"/>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<!--            <link rel="stylesheet" type="text/css" href="stylesheet.css">-->
        <style>
            .star-icon {
                color: gray;
                font-size: 16;
                position: relative;
            }
            .star-icon.full:before {
                color: #ff9900;
                content: '\2605'; /* Full star in UTF8 */
                position: absolute;
                left: 0;
            }
            .star-icon.half:before {
                color: #ff9900;
                content: '\2605'; /* Full star in UTF8 */
                position: absolute;
                left: 0;
                width: 50%;
                overflow: hidden;
            }
        </style>
                <title>NEMAR pipeline status</title>
        </head>

        <body>
    <div class="container p-3">
        <div class="border border-primary"><h1 class="display-4 text-center text-bold text-primary"><strong>NEMAR pipeline status</strong></h1></div>
    </div>
    <div class="container">
        <p class="text-center lead" id="listalldescription">
Status of running NEMAR pipeline on Openneuro datasets
        </p>
    </div>
                <br>
<br>
    <div class="container" id="statusTable">
    </div>
    <!-- Edit Modal -->
    <div class="modal fade" id="dsLogs" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="dsLogs" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
            <div class="modal-header">
                    <h5 class="modal-title" id="dsLogTitle">MATLAB Log File</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                        <input type="text" value="matlab log path" id="dsnumber">
                        <button onclick="copyText()">Copy</button>
                </div>
            </div>
        </div>
      <div>

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>
    <script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.10.20/datatables.min.js"></script>

    <script>
        $(document).ready(function() {
            $("#statusTable").load('pipeline_status_all.html', function() {
                    $('table').DataTable( {
                        "paging": false,
                        "order": [[ 0, "asc"]],
                        //"columnDefs": [{"orderable": false, "targets":[3,8]}]
                    });
                    $('tbody > tr > td:first-child').each(function(index) {
                        var dsnumber = $(this).html();                  
                        $(this).html("<a data-toggle='modal' data-target='#dsLogs' data-dsnumber='" + dsnumber + "'>" + dsnumber + "</a>");
                    });
            });
            $('#dsLogs').on('show.bs.modal', function (event) {
                var clicked = $(event.relatedTarget);
                var dsnumber = clicked.data('dsnumber');
                var modal = $(this);
                modal.find('#dsnumber').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs/matlab_log');
            });
        } );
        function copyText() {
          // Get the text field
          var copyText = document.getElementById("dsnumber");

          // Select the text field
          copyText.select();
          copyText.setSelectionRange(0, 99999); // For mobile devices

          // Copy the text inside the text field
          navigator.clipboard.writeText(copyText.value);
        } 
    </script>
    </body>
</html>
