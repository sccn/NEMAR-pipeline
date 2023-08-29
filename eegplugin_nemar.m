function vers = eegplugin_nemar( fig, try_strings, catch_strings )
%EEGLABPLUGIN_ICLABEL EEGLAB plugin for EEG IC labeling
%   Label independent components using ICLabel. Go to
%   https://sccn.ucsd.edu/wiki/ICLabel for a tutorial on this plug-in. Go
%   to labeling.ucsd.edu/tutorial/about for more information. To report a
%   bug or issue, please create an "Issue" post on the GitHub page at 
%   https://github.com/sccn/ICLabel/issues or send an email to 
%   eeglab@sccn.ucsd.edu.
%
%   Results are stored in EEG.etc.ic_classifications.ICLabel. The matrix of
%   label vectors is stored under "classifications" and the cell array of
%   class names are stored under "classes". The matrix stored under
%   "classifications" is organized with each column matching to the
%   equivalent element in "classes" and each row matching to the equivalent
%   IC. For example, if you want to see what percent ICLabel attributes IC
%   7 to the class "eye", you would look at:
%       EEG.etc.ic_classifications.ICLabel.classifications(7, 3)
%   since EEG.etc.ic_classifications.ICLabel.classes{3} is "eye".

% version
vers = 'NEMAR0.1';

% input check
if nargin < 3
    error('eegplugin_iclabel requires 3 arguments');
end

% add items to EEGLAB tools menu
menui3 = findobj(fig, 'label', 'File');

uimenu( menui3, 'label', 'Run NEMAR pipeline', ...
    'callback', 'pop_run_pipeline;', 'userdata', 'startup:on;study:on');


