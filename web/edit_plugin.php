<?php
include 'plugin_db.php';

// retrieve all plugins
$result = mysql_query("SELECT DISTINCT plugin, webdoc, curversion, description, link, tags, contactname, contactemail, github, critical, releasenotes FROM pluginsummary") or die (mysql_error());
$pending_result = mysql_query("SELECT plugin FROM pluginsummary_upload") or die (mysql_error());
$pending_plugins = array();
while ($plugin = mysql_fetch_array($pending_result, MYSQL_NUM)) {
    $pending_plugins[] = $plugin[0];
}
//echo implode("-",$pending_plugins);
$directory_self = str_replace(basename($_SERVER['PHP_SELF']), '', $_SERVER['PHP_SELF']);
$handler = 'http://' . $_SERVER['HTTP_HOST'] . $directory_self . 'process.plugin.update.php';
?>

<html lang="en">
<head>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.10.20/datatables.min.css"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <title>Edit Plug-in</title>
</head>
<body>
    <table class="table table-bordered table-hover sortable" id="mainTable">
        <thead>
        <tr>
            <th></th>
            <th></th>
            <th>Pending?</th>
            <th>Plug-in name</th>
            <th>Version</th>
            <th>Plug-in description</th>
            <th>Github</th>
            <th>Link</th>
            <th>Tags</th>
            <th>Contact</th>
	    <th>Critical</th>
	    <th>Release notes</th>
        </tr>
        </thead>
        <tbody>
        <?php
        while ($row = mysql_fetch_array($result, MYSQL_NUM)) {
            if (!empty($row[0]))
            {
		echo "\t\t\t<tr>\n";
                printf('<td><button type="button" class="btn btn-primary btn-sm" data-toggle="modal" data-target="#pluginEditModal" data-plugin="%s" data-doc="%s" data-version="%s" data-desc="%s" data-link="%s" data-tags="%s" data-contact="%s" data-email="%s" data-github="%s" data-critical=%d data-notes="%s"><i class="fa fa-edit"></i></button></td>',$row[0], $row[1], $row[2], $row[3], $row[4], $row[5], $row[6], $row[7], $row[8], $row[9], $row[10]);
                printf('<td><button type="button" class="btn btn-danger btn-sm" data-toggle="modal" data-target="#pluginDeleteModal" data-plugin="%s" data-link="%s"><i class="fa fa-trash"></i></button></td>', $row[0], $row[4]);
                if (in_array($row[0],$pending_plugins))
                    printf('<td><p style="color: green">pending</p></td>');
                else
                    printf("<td></td>");
                if(isset($row[1]) && $row[1] !== '') // if have documentation
                    printf("\t\t\t\t<td><a href='%s'>%s</a></td>\n",$row[1],$row[0]);
                else
                    printf("\t\t\t\t<td>%s</td>\n",$row[0]);
                printf("\t\t\t\t<td>%s</td>\n",$row[2]);
                printf("\t\t\t\t<td>%s</td>\n",$row[3]);
                printf("\t\t\t\t<td><a href='%s'>%s</a></td>\n",$row[8],$row[8]); // github link
                printf("\t\t\t\t<td><a href='%s'>Download</a></td>\n", str_replace("http","https",$row[4])); // replace http with https link on the fly for download without updating the database so that EEGLAB plugin manager can still work for <2018 Matlab (only supports http) - 01/07/2021 DT - also in plugin_list_all 
                printf("\t\t\t\t<td>%s</td>\n",$row[5]);
                printf("\t\t\t\t<td><a href='mailto:%s'>%s</a></td>\n",$row[7],$row[6]);
                printf("\t\t\t\t<td>%d</td>\n",$row[9]);
                printf("\t\t\t\t<td>%s</td>\n",$row[10]);
                echo "\t\t\t</tr>\n";
            }
        }
        ?>

        </tbody>
    </table>

    <!-- Edit Modal -->
    <div class="modal fade" id="pluginEditModal" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="pluginEditModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="pluginEditModalLabel">Edit plugin</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form method=POST id='Activate' name='Activate' action='<?php echo $handler ?>' enctype='multipart/form-data'>
                        <div class="form-group"><input type="hidden" class="form-control" id="plugin" name="plugin"></div>
                        <div class="form-group"><input type="hidden" class="form-control" id="action" name="action" value="update"></div>
                        <div class="form-group">
                            <label for="version" class="col-form-label">Version:</label>
                            <input type="text" class="form-control" id="version" name="version">
                        </div>
                        <div class="form-group">
                            <label for="description" class="col-form-label">Description:</label>
                            <textarea class="form-control" id="description" name="description"></textarea>
                        </div>
                        <div class="form-group">
                            <label for="doc" class="col-form-label">Documentation:</label>
                            <input class="form-control" id="doc" name="doc"></input>
                        </div>
                        <div class="form-group">
                            <label for="github" class="col-form-label">Github link:</label>
                            <input class="form-control" id="github" name="github"></input>
                        </div>
                        <div class="form-group">
                            <label for="link" class="col-form-label">Link:</label>
                            <input class="form-control" id="link" name="link"></input>
                        </div>
                        <div class="form-group">
                            <label for="link" class="col-form-label">Tags:</label>
                            <input class="form-control" id="tags" name="tags"></input>
                        </div>
                        <div class="form-group">
                            <label for="contact" class="col-form-label">Contact:</label>
                            <input class="form-control" id="contact" name="contact"></input>
                        </div>
                        <div class="form-group">
                            <label for="email" class="col-form-label">Email:</label>
                            <input class="form-control" id="email" name="email"></input>
                        </div>
                        <div class="form-group">
                            <label for="critical" class="col-form-label">Critical:</label>
                            <input class="form-control" id="critical" name="critical"></input>
                        </div>
                        <div class="form-group">
                            <label for="notes" class="col-form-label">Release Notes:</label>
                            <input class="form-control" id="notes" name="notes"></input>
                        </div>
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary" name="submit">Update</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <!-- Delete Modal -->
    <div class="modal fade" id="pluginDeleteModal" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="pluginDeleteModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title text-danger" id="pluginDeleteModalLabel">Delete plugin</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <p class="text-danger">Plugin info will be removed from database as well as the plugin download file!!</p>
                </div>
                <div class="modal-footer">
                    <form method=POST id='Activate' name='Activate' action='<?php echo $handler ?>' enctype='multipart/form-data'>
                        <div class="form-group"><input type="hidden" class="form-control" id="plugin" name="plugin"></div>
                        <div class="form-group"><input type="hidden" class="form-control" id="action" name="action" value="delete"></div>
                        <div class="form-group"><input type="hidden" class="form-control" id="link" name="link"></div>
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-danger" name="submit">I understand. Delete</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.4.1.slim.min.js" integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>
    <script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.10.20/datatables.min.js"></script>

    <script>
        $(document).ready(function() {
            $('#mainTable').DataTable( {
                "paging": false,
                "order": [[ 2, "desc"]],
                "columnDefs": [{"orderable": false, "targets":[0,1]}]
        });
        } );
    </script>
    <script>
        $('#pluginEditModal').on('show.bs.modal', function (event) {
            var button = $(event.relatedTarget) // Button that triggered the modal
            var pluginName = button.data('plugin')
            var version = button.data('version')
            var desc = button.data('desc')
            var link = button.data('link')
            var tags = button.data('tags')
            var contact = button.data('contact')
            var email = button.data('email')
            var doc = button.data('doc')
            var github = button.data('github')
            var critical = button.data('critical')
	    console.log(critical)
            var notes = button.data('notes')
	    console.log(notes)


            var modal = $(this)
            modal.find('.modal-title').text('Edit plugin "' + pluginName + '"')
            modal.find('.modal-body #plugin').val(pluginName)
            modal.find('.modal-body #version').val(version)
            modal.find('.modal-body #description').val(desc)
            modal.find('.modal-body #link').val(link)
            modal.find('.modal-body #tags').val(tags)
            modal.find('.modal-body #contact').val(contact)
            modal.find('.modal-body #email').val(email)
            modal.find('.modal-body #doc').val(doc)
            modal.find('.modal-body #github').val(github)
            modal.find('.modal-body #critical').val(critical)
            modal.find('.modal-body #notes').val(notes)
        })
        $('#pluginDeleteModal').on('show.bs.modal', function (event) {
            var button = $(event.relatedTarget) // Button that triggered the modal
            var pluginName = button.data('plugin')
            var link = button.data('link')

            var modal = $(this)
            modal.find('.modal-title').text('ARE YOU SURE YOU WANT TO DELETE PLUGIN ' + pluginName + '?')
            modal.find('.modal-footer #delete').attr("data-plugin",pluginName)
            modal.find('.modal-footer #plugin').val(pluginName);
            modal.find('.modal-footer #link').val(link);
        })
    </script>
</body>
</html>
