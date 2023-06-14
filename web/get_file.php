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
elseif ($file == "sbatchout") {
    $filepath = $base_path . "/logs/" . $dsnumber . ".out";
}
else {
    $dspath = $base_path . "/" . $dsnumber;
    $filepath = searchFileRecursive($dspath, $file);
}

if (file_exists($filepath)) {
    $fileContent = file_get_contents($filepath);
    // Do something with $fileContent
    echo $fileContent;
} else {
    echo "File does not exist.";
}

function searchFileRecursive($directory, $filename) {
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($directory));

    foreach ($iterator as $file) {
        if ($file->isFile()) {
            if ($file->getFilename() === $filename) {
                return $file->getPathname();
            }
        }
    }

    return "";
}
?>
