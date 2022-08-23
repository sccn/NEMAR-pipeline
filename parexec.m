function ALLEEG = parexec(data, fun, logdir, varargin)
    options = varargin;
    optionsText = argArray2Str(options);
    fid = fopen(sprintf('%s/%s_params',logdir,fun),'w');
    fprintf(fid, optionsText);
    fclose(fid);
    ALLEEG = data;
    
    parfor i=1:numel(data)
       EEG = data(i);
       try
           fid = fopen(sprintf('%s/stdout', logdir),'a');
           fprintf(fid, 'Evaluating %s for subject %d\n', fun, i);
           fclose(fid);
           EEGout = feval(fun, EEG, options{:}); % script use EEG, which exists in current scope
           ALLEEG(i) = EEGout;
       catch ME
           fid = fopen(sprintf('%s/stderr', logdir),'a');
           fprintf(fid, 'Error evaluating %s at subject %d\n', fun, i);
           fclose(fid);
           
           fid = fopen(sprintf('%s/subject_%d.err',logdir, i),'a');
           fprintf(fid, '\t%s:%s\n', ME.identifier, ME.message);
           fclose(fid);
       end
    end
    
    function text = argArray2Str(cellArray)
        text = [];
        for idx=1:numel(cellArray)
            item = cellArray{idx};
            if isnumeric(item)
                if isempty(item)
                    itemText = '[]';
                else
                    itemText = num2str(item);
                end
            elseif ischar(item)
                itemText = sprintf("'%s'",item);
            end
            
            text = [text ' ' char(itemText)];
        end
    end
end