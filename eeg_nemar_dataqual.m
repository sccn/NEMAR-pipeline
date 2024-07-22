function cur_report = eeg_nemar_dataqual(EEG, varargin)
    import java.text.* % for json formatting
    metrics_all = {'dataqual'}; % for now. In future it would be broken down, e.g. {'dataP', 'chanP', 'icaP'};
    opt = finputcheck(varargin, { ...
        'metrics'        'cell'    {}                        metrics_all; ...         % dataqual metrics to compute
        'outputdir'      'string'    {}                      EEG.filepath; ...   
        'logdir'         'string'    {}                      './eeg_nemar_logs'; ...
        'legacy'         'boolean'   {}                      false; ...
    }, 'generate_report');
    if isstr(opt), error(opt); end
    if ~exist(opt.outputdir, 'dir')
        mkdir(opt.outputdir);
    end
    if ~exist(opt.logdir, 'dir')
        mkdir(opt.logdir);
    end

    if ~exist('eeglab')
        addpath('/expanse/projects/nemar/dtyoung/NEMAR-pipeline/eeglab');
        eeglab nogui;
    end
    if ~exist('jsonread')
        addpath('/expanse/projects/nemar/dtyoung/NEMAR-pipeline/JSONio');
    end

    if ~opt.legacy
        [~, filename, ext] = fileparts(EEG.filename);
        preprocess_status_file = fullfile(opt.logdir, [filename '_preprocess.csv']);
        % if preprocess status_file doesn't exists, we're not running data quality
        if ~exist(preprocess_status_file, 'file')
            error('Preprocess status file not found. Data quality cannot be run without preprocess.')
        end
    end

    decFormatter = DecimalFormat;
    [~, filename, ext] = fileparts(EEG.filename);

    log_file = fullfile(opt.logdir, filename);
    status_file = fullfile(opt.logdir, [filename '_dataqual.csv']);
    status_tbl = array2table(zeros(1, numel(metrics_all)));
    status_tbl.Properties.VariableNames = metrics_all;
    writetable(status_tbl, status_file);
    disp(status_tbl)

    diary(log_file);
    try
        fprintf('Generating reports for %s\n', fullfile(EEG.filepath, EEG.filename));
        report_file = fullfile(opt.outputdir, [EEG.filename(1:end-4) '_dataqual.json']);
        fid = fopen(report_file,'w');
        fprintf(fid,'{}');
        fclose(fid);

        cur_report = jsonread(report_file);
        if isfield(EEG.etc, 'clean_sample_mask')
            goodDataPercent = round(100*EEG.pnts/numel(EEG.etc.clean_sample_mask), 2); % new change to clean_raw_data
            cur_report.nGoodData = char(decFormatter.format(EEG.pnts));
            cur_report.goodDataPercent = sprintf('%s of %s (%.0f%%)', char(decFormatter.format(EEG.pnts)), char(decFormatter.format(numel(EEG.etc.clean_sample_mask))), goodDataPercent);
            cur_report.goodDataPercentRaw = sprintf('%.0f', goodDataPercent);
        else
            cur_report.goodDataFail = 1;
            warning('Warning: clean_sample_mask not found');
        end
        jsonwrite(report_file, cur_report);

        if isfield(EEG.etc, 'clean_channel_mask')
            goodChanPercent = round(100*EEG.nbchan/numel(EEG.etc.clean_channel_mask), 2);
            cur_report.nGoodChans = EEG.nbchan;
            cur_report.goodChansPercent = goodChanPercent;
            cur_report.goodChansPercent= sprintf('%d of %d (%.0f%%)', EEG.nbchan, numel(EEG.etc.clean_channel_mask), goodChanPercent);
            cur_report.goodChansPercentRaw = sprintf('%.0f', goodChanPercent);
        else
            cur_report.goodChanFail = 1;
            warning('Warning: clean_channel_mask not found');
        end
        jsonwrite(report_file, cur_report);

        cur_report = jsonread(report_file);
        if isfield(EEG, 'icaact') && ~isempty(EEG.icaact)
            cur_report.icaFail = 0;
            rejected_ICs = sum(EEG.reject.gcompreject);
            numICs = EEG.nbchan-1;
            cur_report.nICs = numICs;
            cur_report.nGoodICs = numICs-rejected_ICs;
            cur_report.goodICA = sprintf('%d of %d (%.0f%%)', numICs-rejected_ICs, numICs, round(100*(numICs-rejected_ICs)/numICs, 2));

            goodICPercent = round(100*(numICs-rejected_ICs)/numICs, 2);
            cur_report.goodICAPercentRaw = sprintf('%.0f', goodICPercent);
        else
            cur_report.icaFail = 1;
            warning('Warning: ICA report failed');
        end
        jsonwrite(report_file, cur_report);
        
        % MIR
        %{
        cur_report = jsonread(report_file);
        
        if isfield(EEG, 'icaweights') && ~isempty(EEG.icaweights) && isfield(EEG, 'icasphere') && ~isempty(EEG.icasphere)
            cur_report.mirFail = 0;
            [mir_mean, mir_std, ~] = mir(EEG.data, EEG.icaweights * EEG.icasphere);
            cur_report.mir = sprintf('%.2f (%.2f stdev)', mir_mean, mir_std);
        else
            cur_report.mirFail = 1;
            warning('Warning: MIR report failed');
        end
        jsonwrite(report_file, cur_report);
        %}

        % magnitude of line noise
        cur_report = jsonread(report_file);
        g = finputcheck({}, { 'freq'    'integer' []         [6, 10, 22]; ...
                    'freqrange'   'integer'   []         [1 70]; ...
                    'percent'   'integer'    [], 10});
        [spec, freqs] = spectopo(EEG.data, 0, EEG.srate, 'freqrange', g.freqrange, 'title', '', 'chanlocs', EEG.chanlocs, 'percent', g.percent,'plot', 'off');
        [~,ind50]=min(abs(freqs-50));
        freq_50 = mean(spec(:, ind50));
        [~,ind60]=min(abs(freqs-60));
        freq_60 = mean(spec(:, ind60));
        if freq_50 > freq_60
            linenoise_magn = freq_50 - mean(mean(spec(:, [ind50-6:ind50-2 ind50+2:ind50+6]), 1));
        else
            linenoise_magn = freq_60 - mean(mean(spec(:, [ind60-6:ind60-2 ind60+2:ind60+6]), 1));
        end
        cur_report.linenoise_magn = sprintf('%.2fdB',linenoise_magn);
        jsonwrite(report_file, cur_report);

        % if reached, operation completed without error
        % write status file
        status_tbl.dataqual = 1; % for now, later add more metrics
        writetable(status_tbl, status_file);
        disp(status_tbl)
    catch ME
        fprintf('%s\n%s\n',ME.identifier, ME.getReport());
    end
    diary off;

    function [mutual_info,mutual_info_var, detailed_mir] = mir(data,linT)
        %MIR computes the mutual information reduction by a linear transformation
        %   It so happends that simple codes are being used as event types in
        %   EEG files. Such codes would be problamtic if proper descitiption is
        %   not attached. A simple fix can be replacing the event codes with their
        %   short descitpiotn using a lookup table.
        %
        %   INPUTS:
        %       data
        %           An [x t] array, usually EEG.data,  where the rows are the
        %           channels and the columns are the time frames.
        %       linT
        %           The linear transformation matrix, usually W * S, which should
        %           is expected (but not necessarily) to be of size [x x].
        %
        %   OUTPUTS:
        %       mir
        %           The overal MIR across all channels
        %       mir_var
        %           The variance of the MIR across channels
        %       detailed_mir
        %           NOT_YET_IMPLEMENTED The vector containing the MIR per channel, i.e., how much
        %           infomration of each channel is reduced.
        %   
        % (c) Seyed Yahya Shirazi, 06/2023 UCSD, INC, SCCN, from github.com/bigdelys/pre_ICA_Cleaing/getMIR.m
        
        [hx,vx] = getent4(robust_sphering_matrix(data) * data); % sphereing is needed to make sure that the MIR is only related to ICA
        
        y = linT*data;
        
        [hy,vy] = getent4(y);
        
        mutual_info = sum(log(abs(eig(W)))) + sum(hx) - sum(hy);
        
        if nargout > 1
            mutual_info_var = (sum(vx)+sum(vy))/N;
        elseif nargout > 2
            detailed_mir = []; % not yet implemented
        end
        
        function [Hu,v] = getent4(u,nbins)
            % function [Hu,deltau] = getent2(u,nbins)
            %
            % Calculate nx1 marginal entropies of components of u.
            %
            % Inputs:
            %           u       Matrix (n by N) of nu time series.
            %           nbins   Number of bins to use in computing pdfs. Default is
            %                   min(100,sqrt(N)).
            %
            % Outputs:
            %           Hu      Vector n by 1 differential entropies of rows of u.
            %           v       Variance of entropy estimates in Hu
            %
            
            [nu,Nu] = size(u);
            if nargin < 2 || isempty(nbins)
                nbins = round(3*log2(1+Nu/10));
            end
            
            Hu = zeros(nu,1);
            deltau = zeros(nu,1);
            for i = 1:nu
                umax = max(u(i,:));
                umin = min(u(i,:));
                deltau(i) = (umax-umin)/nbins;
                u(i,:) = 1 + round((nbins - 1) * (u(i,:) - umin) / (umax - umin));
            
                pmfr = diff([0 find(diff(sort(u(i,:)))) Nu])/Nu;
                Hu(i) = -sum(pmfr.*log(pmfr));
                v(i) = sum(pmfr.*(log(pmfr).^2)) - Hu(i)^2;
                Hu(i) = Hu(i) + (nbins-1)/(2*Nu) + log(deltau(i));
            end
        end
        function [robustSphering, mixing, covarianceMatrix] = robust_sphering_matrix(X)
            % [robustSphering mixing] = robust_sphering_matrix(X);
            % X is channel x times data, e.g. EEG.data
            
            [C,S] = size(X);
            X = X';
            blocksize = 10;
            blocksize = max(blocksize,ceil((C*C*S*8*3*2)/hlp_memfree));
            
            % calculate the sample covariance matrices U (averaged in blocks of blocksize successive samples)
            U = zeros(length(1:blocksize:S),C*C);
            for k=1:blocksize
                range = min(S,k:blocksize:(S+k-1));
                U = U + reshape(bsxfun(@times,reshape(X(range,:),[],1,C),reshape(X(range,:),[],C,1)),size(U));
            end
            
            % get the mixing matrix M
            covarianceMatrix = real(reshape(block_geometric_median(U/blocksize),C,C));
            mixing = sqrtm(covarianceMatrix);
            robustSphering = inv(mixing);
        end
	    function result = hlp_memfree
		    % Get the amount of free physical memory, in bytes
    
		    % Copyright (C) Christian Kothe, SCCN, 2010, christian@sccn.ucsd.edu
		    %
		    % This program is free software; you can redistribute it and/or modify it under the terms of the GNU
		    % General Public License as published by the Free Software Foundation; either version 2 of the
		    % License, or (at your option) any later version.
		    %
		    % This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
		    % even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
		    % General Public License for more details.
		    %
		    % You should have received a copy of the GNU General Public License along with this program; if not,
		    % write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
		    % USA
    
		    bean = java.lang.management.ManagementFactory.getOperatingSystemMXBean();
		    result = bean.getFreePhysicalMemorySize();
        end
        function y = geometric_median(X,tol,y,max_iter)
            % Calculate the geometric median for a set of observations (mean under a Laplacian noise distribution)
            % This is using Weiszfeld's algorithm.
            %
            % In:
            %   X : the data, as in mean
            %   tol : tolerance (default: 1.e-5)
            %   y : initial value (default: median(X))
            %   max_iter : max number of iterations (default: 500)
            %
            % Out:
            %   g : geometric median over X
            
            % Copyright (C) Christian Kothe, SCCN, 2012, ckothe@ucsd.edu
            %
            % This program is free software; you can redistribute it and/or modify it under the terms of the GNU
            % General Public License as published by the Free Software Foundation; either version 2 of the
            % License, or (at your option) any later version.
            %
            % This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
            % even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
            % General Public License for more details.
            %
            % You should have received a copy of the GNU General Public License along with this program; if not,
            % write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
            % USA
            
            if ~exist('tol','var') || isempty(tol)
                tol = 1.e-5; end
            if ~exist('y','var') || isempty(y)
                y = median(X); end
            if ~exist('max_iter','var') || isempty(max_iter)
                max_iter = 500; end
            
            for i=1:max_iter
                invnorms = 1./sqrt(sum(bsxfun(@minus,X,y).^2,2));
                [y,oldy] = deal(sum(bsxfun(@times,X,invnorms)) / sum(invnorms),y);
                if norm(y-oldy)/norm(y) < tol
                    break; end
            end
        end
        function y = block_geometric_median(X,blocksize,varargin)
            % Calculate a blockwise geometric median (faster and less memory-intensive 
            % than the regular geom_median function).
            %
            % This statistic is not robust to artifacts that persist over a duration that
            % is significantly shorter than the blocksize.
            %
            % In:
            %   X : the data (#observations x #variables)
            %   blocksize : the number of successive samples over which a regular mean 
            %               should be taken
            %   tol : tolerance (default: 1.e-5)
            %   y : initial value (default: median(X))
            %   max_iter : max number of iterations (default: 500)
            %
            % Out:
            %   g : geometric median over X
            %
            % Notes:
            %   This function is noticably faster if the length of the data is divisible by the block size.
            %   Uses the GPU if available.
            % 
            
            % Copyright (C) Christian Kothe, SCCN, 2013, christian@sccn.ucsd.edu
            %
            % This program is free software; you can redistribute it and/or modify it under the terms of the GNU
            % General Public License as published by the Free Software Foundation; either version 2 of the
            % License, or (at your option) any later version.
            %
            % This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
            % even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
            % General Public License for more details.
            %
            % You should have received a copy of the GNU General Public License along with this program; if not,
            % write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
            % USA
            
            if nargin < 2 || isempty(blocksize)
                blocksize = 1; end
            
            if blocksize > 1
                [o,v] = size(X);       % #observations & #variables
                r = mod(o,blocksize);  % #rest in last block
                b = (o-r)/blocksize;   % #blocks
                if r > 0
                    X = [reshape(sum(reshape(X(1:(o-r),:),blocksize,b*v)),b,v); sum(X((o-r+1):end,:))*(blocksize/r)];
                else
                    X = reshape(sum(reshape(X,blocksize,b*v)),b,v);
                end
            end
            
            try
                y = gather(geometric_median(gpuArray(X),varargin{:}))/blocksize;
            catch
                y = geometric_median(X,varargin{:})/blocksize;
            end
        end
    end
end
