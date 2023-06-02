addpath('/home/dtyoung/NEMAR-pipeline')

dsfolders = {'ds001787','ds002094','ds002218','ds002680','ds002691','ds002718','ds002720','ds002722','ds002723','ds002724','ds002725','ds002778','ds002814','ds002893','ds003039','ds003061','ds003190','ds003194','ds003195','ds003458','ds003474','ds003478','ds003506','ds003516','ds003517','ds003519','ds003522','ds003574','ds003645','ds003655','ds003739','ds003751','ds003753','ds003768','ds003801','ds004015','ds004033','ds004040','ds004152','ds004197'}
for i=1:numel(dsfolders)
    dsnumber = dsfolders{i};
    
	fprintf('Processing %s\n', dsnumber);
    try
        run_pipeline(dsnumber, 'preprocess', false, 'vis', true, 'vis_plots', {'midraw', 'icaact'}, 'dataqual', false, 'maxparpool', 127, 'modeval', 'rerun');
    catch ME
        fprintf('%s\n', ME.identifier);
        fprintf('%s\n', ME.message);
        fprintf('%s\n', ME.getReport());
    end
end
