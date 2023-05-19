<?php
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
	    td { white-space:pre-wrap; word-wrap:break-word }
        </style>
                <title>NEMAR pipeline status</title>
        </head>

        <body>
    <div class="container p-3">
        <div class="border border-primary"><h1 class="display-4 text-center text-bold text-primary"><strong>NEMAR pipeline status</strong></h1></div>
    </div>
    <div class="container">
        <p class="text-center lead" id="listalldescription">Status of running NEMAR pipeline on Openneuro datasets</p>
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
                    <h5 class="modal-title" id="dsLogTitle">Log Files location</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form method=POST id='Activate' name='Activate' enctype='multipart/form-data'>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">Log dir:</label>
                            <input class="form-control" id="logDir" name="logDir"></input>
			    <button type="button" onclick="copyText('logDir')">Copy path</button>
                        </div>
                        <div class="form-group">
                            <label for="version" class="col-form-label">MATLAB log:</label>
                            <input type="text" class="form-control" id="matlabLog" name="matlabLog">
			    <button type="button" onclick="copyText('matlabLog')">Copy path</button>
                        </div>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">Debug note:</label>
                            <input class="form-control" id="note" name="note"></input>
			    <button type="button" onclick="copyText('note')">Copy path</button>
                        </div>
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                    </form>
		</div>
	    </div>
	</div>
    </div>
                                   
    <!-- Log content modal -->
    <div class="modal fade" id="dsMatlabLogs" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="dsMatlabLogsLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="dsMatlabLogsLabel">Log Files content</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form method=POST id='Activate' name='Activate' enctype='multipart/form-data'>
                        <div class="form-group">
                            <label for="logcontent" class="col-form-label">Log:</label>
                            <textarea class="form-control" id="logcontent" name="matlab" rows="30"></textarea>
                        </div>
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                    </form>
		</div>
	    </div>
	</div>
    </div>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>
    <script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.10.20/datatables.min.js"></script>

    <script>
        $(document).ready(function() {
	    $.ajaxSetup ({
	      // Disable caching of AJAX responses
	      cache: false
	    });

            $("#statusTable").load('pipeline_status_all.html', function() {
		    $('table').find('tr').each(function(){ 	
			$(this).find('th').eq(-1).after('<th>HEADER</th>'); 	
			$(this).find('td').eq(-1).after('<td>ROW</td>'); 
		    });

		    $('table').DataTable( {
			"paging": false,
			"order": [[ 0, "asc"]],
			//"columnDefs": [{"orderable": false, "targets":[3,8]}]
		    });
		    var dsnumber = "";
		    $('tbody > tr').each(function(index) {
			var first_td = $(this).children().first();
			var dsnumber = first_td.html();
			first_td.html("<a data-toggle='modal' data-target='#dsLogs' data-dsnumber='" + dsnumber + "'>" + dsnumber + "</a>");
			var last_td = $(this).children().last();
			last_td.html("<a data-toggle='modal' class='text-primary' data-target='#dsMatlabLogs' data-dsnumber='" + dsnumber + "' data-file='matlab'>MATLAB</a><br>");
			last_td.append("<a data-toggle='modal' class='text-success' data-target='#dsMatlabLogs' data-dsnumber='" + dsnumber + "' data-file='ind'>Ind status</a><br>");
			last_td.append("<a data-toggle='modal' class='text-danger' data-target='#dsMatlabLogs' data-dsnumber='" + dsnumber + "' data-file='sbatcherr'>Batch .err</a>");
		    });

	    });
	    $('#dsLogs').on('show.bs.modal', function (event) {
		var clicked = $(event.relatedTarget);
		var dsnumber = clicked.data('dsnumber');
		var modal = $(this);
		modal.find('#logDir').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs');
		modal.find('#matlabLog').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs/matlab_log');
		modal.find('#note').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs/debug/debug_note');
	    });
	    $('#dsMatlabLogs').on('show.bs.modal', function (event) {
		var clicked = $(event.relatedTarget);
		var dsnumber = clicked.data('dsnumber');
		var file = clicked.data('file');
		var modal = $(this);
		$.post('get_file.php', { dsnumber: dsnumber, file: file }, function(result) { 
		    modal.find('#logcontent').val(result);
		});
	    });
        } );
	function copyText(type) {
	  // Get the text field
	  var copyText = document.getElementById(type);

	  // Select the text field
	  copyText.select();
	  copyText.setSelectionRange(0, 99999); // For mobile devices

	   // Copy the text inside the text field
	  navigator.clipboard.writeText(copyText.value);
	} 
    </script>
    </body>
</html>

