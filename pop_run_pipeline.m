% GUI function for NEMAR

function res = pop_run_pipeline(varargin)

if ~isempty(varargin)
    command = varargin{1};
    fig     = varargin{2};
    switch varargin{1}
        case 'bids_select'
            res = uigetdir;
            if isequal(res, 0)
                return;
            end
            set(findobj(gcbf, 'tag', 'bids_select'), 'string', res );
            [~,bidsName] = fileparts(res);
            set(findobj(gcbf, 'tag', 'out_select'), 'string', fullfile('/expanse/projects/nemar/Annalisa/Inprogress/', [bidsName '-debug'] ));
        case 'out_select'
            res = uigetdir;
            if isequal(res, 0)
                return;
            end
            set(findobj(gcbf, 'tag', 'out_select'), 'string', res );
        otherwise
            error([ 'Unknown command ''' command '''' ]);
    end
    return
end

bids_select = 'pop_run_pipeline(''bids_select'', gcbf);';
out_select  = 'pop_run_pipeline(''out_select'', gcbf);';
ctffunc = {'fileio' 'ctfimport'};
uilist = { { 'style' 'text' 'string' 'NEMAR pipeline' 'fontweight' 'bold' } ...
           ...
           { 'style' 'text' 'string' 'Select BIDS' } ...
           { 'style' 'edit' 'string' '/expanse/projects/nemar/openneuro' 'tag' 'bids_select' } ...
           { 'style' 'pushbutton' 'string' '...' 'callback' bids_select } ...
           ...
           { 'style' 'text' 'string' 'Output folder' } ...
           { 'style' 'edit' 'string' '' 'tag' 'out_select'  } ...
           { 'style' 'pushbutton' 'string' '...' 'callback' out_select } ...
           ...
           { 'style' 'text' 'string' 'Subject index(ices)' } ...
           { 'style' 'edit' 'string' '' 'tag' 'subjects' } ...
           { } ...
           ...
           { 'style' 'text' 'string' 'Exclude subjects' } ...
           { 'style' 'edit' 'string' '' 'tag' 'rmsubjects' } ...
           { } ...
           { 'style' 'text' 'string' 'Memory (Gb)' } ...
           { 'style' 'edit' 'string' '16' 'tag' 'mem' } ...
           { } ...
           { 'style' 'text' 'string' 'CTF import function' } ...
           { 'style' 'popupmenu' 'string' ctffunc 'tag' 'ctffunc' } ...
           { } ...
           ...
           { 'style' 'checkbox' 'string' 'Run in batch mode (default parameters) or local (custom parameters above)' 'tag' 'run_batch' } ...
           { 'style' 'checkbox' 'string' 'Use final output folder instead of debugging one above)' 'tag' 'run_final_folder' } ...
           { 'style' 'checkbox' 'string' 'Reused previously imported files' 'tag' 'reuse' 'value', 0} ...
           { 'style' 'checkbox' 'string' 'Run the cleaning pipeline' 'tag' 'preprocess' 'value', 0} ...
           { 'style' 'checkbox' 'string' 'Compute data quality' 'tag' 'dataqual' 'value', 0} ...
           };
uigeom = { [1] [1 2 0.4] [1 2 0.4] [1 2 0.4] [1 2 0.4] [1 2 0.4] [1 2 0.4] 1 1 1 1 1};

[~,~,~, res] = inputgui('geometry', uigeom, 'uilist', uilist);
if isempty(res) || isempty(res.bids_select)
    disp('Abort')
    return
end

% Do not forget to print the command line so Annalisa can copy and past in
% a bug report
[~,bidsName] = fileparts(res.bids_select);
if ~isequal(bidsName(1:2), 'ds')
    error('Not a BIDS folder')
end
if ~isempty(res.rmsubjects)
    participants = loadtxt(fullfile(res.bids_select, 'participants.tsv'));
    res.subjects = sprintf('%s ', setdiff(1:size(participants,1)-1, str2num(res.rmsubjects)));
end

otherOtions = {'modeval', fastif(res.reuse, 'rerun', 'new'), 'run_local', ~logical(res.run_batch),'preprocess', logical(res.preprocess), 'plugin', false, 'dataqual', logical(res.dataqual), 'preprocess_pipeline', {'check_chanloc', 'remove_chan'}, 'run_local', true, 'ctffunc', ctffunc{res.ctffunc}, 'memory', str2num(res.mem) };
if res.run_final_folder
    res.out_select = sprintf('/expanse/projects/nemar/openneuro/processed/%s', bidsName);
end
command = sprintf('\nrun_pipeline(''%s'', ''subjects'', [%s], ''outputdir'', ''%s'',  ''logdir'', ''%s'', %s);\n\n', bidsName, res.subjects, res.out_select, [res.out_select '/logs'], vararg2str(otherOtions));
if res.run_batch
    fprintf(2, 'You are running in batch mode, your parameters will be ignored!\n')
    cleanrun_command = sprintf('\nds_create_and_submit_job(''%s'');\n\n', bidsName);
	disp(cleanrun_command);
	eval(cleanrun_command);
else
	fprintf(command);
	eval(command)
end



