<?php
$directory_self = str_replace(basename($_SERVER['PHP_SELF']), '', $_SERVER['PHP_SELF']);
$handler = 'http://' . $_SERVER['HTTP_HOST'] . $directory_self . 'update.manual.notes.php';
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
					<div id="nemarpath"></div>
                    <form method=POST id='Activate' name='Activate' enctype='multipart/form-data'>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">Log dir:</label>
                            <input class="form-control" id="logDir" name="logDir"></input>
			    <button type="button" onclick="copyText('logDir')">Copy path</button>
                        </div>
                        <div class="form-group">
                            <label for="version" class="col-form-label">Ind log dir:</label>
                            <input type="text" class="form-control" id="indLogDir" name="indLogDir">
			    <button type="button" onclick="copyText('indLogDir')">Copy path</button>
                        </div>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">Debug note:</label>
                            <input class="form-control" id="note" name="note"></input>
			    <button type="button" onclick="copyText('note')">Copy path</button>
                        </div>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">sbatch file:</label>
                            <input class="form-control" id="sbatch" name="sbatch"></input>
			    <button type="button" onclick="copyText('sbatch')">Copy path</button>
                        </div>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">nemar.json:</label>
                            <input class="form-control" id="nemarjson" name="nemarjson"></input>
			    <button type="button" onclick="copyText('nemarjson')">Copy path</button>
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

    <!-- Debug note edit model-->
    <div class="modal fade" id="noteEditModal" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="noteEditModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="noteEditModalLabel">Edit manual note</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form method=POST id='Activate' name='Activate' action='' enctype='multipart/form-data'>
                        <div class="form-group"><input type="hidden" class="form-control" id="plugin" name="plugin"></div>
                        <div class="form-group"><input type="hidden" class="form-control" id="action" name="action" value="update"></div>
                        <div class="form-group">
                            <label for="noteEditDsnumber" class="col-form-label">Dsnumber:</label>
                            <input type="text" class="form-control" id="noteEditDsnumber" readonly  name="noteEditDsnumber">
                        </div>
                        <div class="form-group">
                            <label for="notes" class="col-form-label">Manual note:</label>
			    <textarea class="form-control" id="notes" name="notes" rows="10"></textarea>
                        </div>
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-primary" data-dismiss="modal" id="noteEditModalSubmit" name="submit">Update</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Ind Log content modal -->
    <div class="modal fade" id="dsIndLogs" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="dsIndLogsLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="dsMatlabLogsLabel">Individual Log Files</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form method=POST id='Activate' name='Activate' enctype='multipart/form-data'>
                        <div class="form-group">
                            <label for="logcontent" class="col-form-label">Log:</label>
			    <div>
				<div class="row">
				    <div class="col" id="indlogtable"></div>
				    <div class="col">
			    		<textarea class="form-control" id="indlogcontent" name="indlogcontent" rows="90"></textarea>
				    </div>
				</div>
			    </div>
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
			$(this).find('th').eq(-1).after('<th>log_files</th>'); 	
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
			last_td.append("<a data-toggle='modal' class='text-success' data-target='#dsIndLogs' data-dsnumber='" + dsnumber + "' data-file='ind'>Ind status</a><br>");
			last_td.append("<a data-toggle='modal' class='text-danger' data-target='#dsMatlabLogs' data-dsnumber='" + dsnumber + "' data-file='sbatcherr'>Batch .err</a><br>");
			last_td.append("<a data-toggle='modal' class='text-info' data-target='#dsMatlabLogs' data-dsnumber='" + dsnumber + "' data-file='sbatchout'>Batch .out</a><br>");
			last_td.append("<a data-toggle='modal' class='text-warning' data-target='#noteEditModal' data-dsnumber='" + dsnumber + "' data-file='manualnote'>Edit note</a>");
			var manual_note_col = $(this).children().eq(15);
			manual_note_col.attr('id','manual_note_' + dsnumber);
			$.post('get_file.php', { dsnumber: dsnumber, file: 'manualnote' }, function(result) { 
			     manual_note_col.text(result);
			});
		    });

	    });
	    $('#dsLogs').on('show.bs.modal', function (event) {
		var clicked = $(event.relatedTarget);
		var dsnumber = clicked.data('dsnumber');
		var modal = $(this);
		modal.find('#nemarpath').html('<a href="https://nemar.org/dataexplorer/detail?dataset_id=' + dsnumber + '">View on NEMAR</a>');
		modal.find('#logDir').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs');
		modal.find('#indLogDir').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs/eeg_logs');
		modal.find('#note').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/logs/debug/manual_debug_note');
		modal.find('#sbatch').val('/expanse/projects/nemar/openneuro/processed/logs/' + dsnumber + 'sbatch');
		modal.find('#nemarjson').val('/expanse/projects/nemar/openneuro/processed/' + dsnumber + '/code/nemar.json');
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
	    $('#dsIndLogs').on('show.bs.modal', function (event) {
		var clicked = $(event.relatedTarget);
		var dsnumber = clicked.data('dsnumber');
		var file = clicked.data('file');
		console.log(file);
		var modal = $(this);
		$.post('get_file.php', { dsnumber: dsnumber, file: file }, function(result) { 
		    if (file === "ind") {
		        var result = csv_string_to_table(result, dsnumber);
		    }
		    modal.find('#indlogtable').html(result);
		});
	    });
	    $('#noteEditModal').on('show.bs.modal', function (event) {
		var clicked = $(event.relatedTarget);
		var dsnumber = clicked.data('dsnumber');
		var file = clicked.data('file');
		var modal = $(this);
		$.post('get_file.php', { dsnumber: dsnumber, file: file }, function(result) { 
		    modal.find('#notes').val(result);
		});
		$("#noteEditDsnumber").val(dsnumber);
	    });
	    $('#noteEditModalSubmit').on('click', function (event) {
		var clicked = $(event.relatedTarget);
		var dsnumber = $('#noteEditDsnumber').val();
		var notes = $('#notes').val();
		var modal = $('#noteEditModal');
		console.log(notes);
		$('#manual_note_' + dsnumber).text(notes);
		$.post('update.manual.notes.php', { dsnumber: dsnumber, notes: notes }, function(result) { 
		    console.log(result);
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

	function csv_string_to_table(csv_string, dsnumber) {
	    var rows = csv_string.trim().split(/\r?\n|\r/); // Regex to split/separate the CSV rows
	    var table = '';
	    var table_rows = '';
	    var table_header = '';

	    rows.forEach(function(row, row_index) {
		var table_columns = '';
		var columns = row.split(','); // split/separate the columns in a row
		columns.forEach(function(column, column_index) {
			if (row_index == 0) {
				table_columns += '<th>' + column + '</th>';
			}
			else {
				if (column_index == 0) {
					var filename = column.split('.')[0];
					//column = "<a data-toggle='modal' class='text' data-target='#dsMatlabLogs' data-dsnumber='" + dsnumber + "' data-file='" + filename + "'>" + filename + "</a>";
					column = "<a class='text-secondary' onclick=\"showIndLogContent('" + dsnumber + "', '" + filename + "')\">" + filename + "</a>";
					table_columns += '<td>' + column + '</td>';
				}
				else {
					table_columns += '<td>' + column + '</td>';
				}
			}
		});
		if (row_index == 0) {
		    table_header += '<tr>' + table_columns + '</tr>';
		} else {
		    table_rows += '<tr>' + table_columns + '</tr>';
		}
	    });

	    table += '<table>';
		table += '<thead>';
		    table += table_header;
		table += '</thead>';
		table += '<tbody>';
		    table += table_rows;
		table += '</tbody>';
	    table += '</table>';

	    return table;
	}
	function showIndLogContent(dsnumber, logfile) {
		$.post('get_file.php', { dsnumber: dsnumber, file: logfile }, function(result) { 
		    $('#indlogcontent').val(result);
		});

	}
    </script>
    </body>
</html>

