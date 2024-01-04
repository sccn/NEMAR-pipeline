addpath('/home/dtyoung/NEMAR-pipeline')

% processed datasets
dsfolders = {'ds001785','ds001787','ds001810','ds001849','ds002034','ds002094','ds002218','ds002336','ds002338','ds002578','ds002680','ds002691','ds002718','ds002720','ds002721','ds002722','ds002723','ds002724','ds002725','ds002778','ds002814','ds002833','ds003004','ds003039','ds003061','ds003190','ds003194','ds003195','ds003343','ds003458','ds003474','ds003478','ds003506','ds003516','ds003517','ds003518','ds003519','ds003522','ds003523','ds003570','ds003574','ds003626','ds003638','ds003655','ds003690','ds003710','ds003739','ds003753','ds003768','ds003774','ds003801','ds003822','ds003838','ds003885','ds003887','ds004015','ds004018','ds004019','ds004022','ds004040','ds004043','ds004105','ds004117','ds004121','ds004147','ds004148','ds004151','ds004152','ds004196','ds004197','ds004200','ds004252','ds004262','ds004264','ds004295','ds004315','ds004317','ds004324','ds004346','ds004347','ds004348','ds004350','ds004357','ds004367','ds004408','ds004457','ds004477','ds004502','ds004504','ds004515','ds004572','ds004574','ds004575','ds004577','ds004579','ds004580','ds004584','ds004588','ds004595','ds004657','ds004660','ds004752'};
for i=1:numel(dsfolders)
    dsnumber = dsfolders{i};
    
	fprintf('Processing %s\n', dsnumber);
    try
        run_pipeline(dsnumber, 'preprocess', false, 'vis', true, 'vis_plots', {'icahist'}, 'dataqual', false, 'maxparpool', 127, 'modeval', 'resume');
    catch ME
        fprintf('%s\n', ME.identifier);
        fprintf('%s\n', ME.message);
        fprintf('%s\n', ME.getReport());
    end
end
