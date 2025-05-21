<?php
$directory_self = str_replace(basename($_SERVER['PHP_SELF']), '', $_SERVER['PHP_SELF']);
$base_path = "/data/qumulo/openneuro/processed";
$dsnumber = $_POST["dsnumber"];

$nemarjson_file = $filepath = $base_path . "/" . $dsnumber . "/code/nemar.json";
//echo $nemarjson_file;
// retrieve data from form
$nemarjson_fileid = fopen($nemarjson_file, "r");
echo $nemarjson_fileid;
//fwrite($note_file, $notes);
$fileContent = file_exists($nemarjson_file);
// Do something with $fileContent
echo $fileContent;
if (file_exists($nemarjson_file)) {
    $fileContent = file_get_contents($nemarjson_file);
    // Do something with $fileContent
    echo $fileContent;
} else {
    echo "File does not exist.";
}
fclose($nemarjson_file);


// make an error handler which will be used if the processing fails
function error($error, $location, $seconds = 60)
{
	header("Refresh: $seconds; URL=\"$location\"");
	echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"'."\n".
	'"http://www.w3.org/TR/html4/strict.dtd">'."\n\n".
	'<html lang="en">'."\n".
	'	<head>'."\n".
	'		<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">'."\n\n".
	'		<link rel="stylesheet" type="text/css" href="stylesheet.css">'."\n\n".
	'	<title>Processing error</title>'."\n\n".
	'	</head>'."\n\n".
	'	<body>'."\n\n".
	'	<div id="Upload">'."\n\n".
	'		<h1>Error processing upload request</h1>'."\n\n".
	'		<p>An error has occured: '."\n\n".
	'		<span class="red">' . $error . '...</span>'."\n\n".
	'	 	Requests page is reloading</p>'."\n\n".
	'	 </div>'."\n\n".
	'</html>';
	exit;
} // end error handler
?>
