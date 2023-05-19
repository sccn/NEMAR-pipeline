<?php

$base_path = "/data/qumulo/openneuro/processed";
$dsnumber = $_POST["dsnumber"];
$file = $_POST["file"];
if ($file == "matlab") {
    $filepath = $base_path . "/" . $dsnumber . "/logs/matlab_log";
}
elseif ($file == "ind") {
    $filepath = $base_path . "/" . $dsnumber . "/logs/ind_pipeline_status.csv";
}
elseif ($file == "sbatcherr") {
    $filepath = $base_path . "/logs/" . $dsnumber . ".err";
}

if (file_exists($filepath)) {
    $fileContent = file_get_contents($filepath);
    // Do something with $fileContent
    echo $fileContent;
} else {
    echo "File does not exist.";
}

?>
