function fid = openfile(filename, mode)
    fid = fopen(filename, mode);
    if fid == -1
        error('Could not open file %s', filename);
    end
end