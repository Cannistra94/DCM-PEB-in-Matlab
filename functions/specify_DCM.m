function ses_run_error = specify_dcm_new(id, treatment, timepoint, rois)
disp([' specify_dcm_new starting for ' id ' ' treatment ' ' timepoint]);
% Prep dirs
dcmfolder   = 'DCM/data';
run_dir     = fullfile(dcmfolder, id, treatment, timepoint);
run_dir_voi = fullfile(run_dir, 'voi_new');

%--------------------------------------------------------------------------
% Specify DCM
%--------------------------------------------------------------------------
disp(['starting Specifying DCM for ' id ' ' treatment ' ' timepoint]);
try
    for jj=1:size(rois)
        if  exist(fullfile(run_dir_voi, ['VOI_' rois{jj} '_1']))
            load(fullfile(run_dir_voi, ['VOI_' rois{jj} '_1']), 'xY'); % need to adapt to own ROIs
            DCM.xY(jj) = xY;
        end
            
    end
    
    DCM.n = length(DCM.xY);      % number of regions
    DCM.v = length(DCM.xY(1).u); % number of time points

    load(fullfile(run_dir, 'SPM.mat'));

    %--------------------------------------------------------------------------
    % Time series
    %--------------------------------------------------------------------------
    DCM.Y.dt = SPM.xY.RT;
    DCM.Y.X0 = DCM.xY(1).X0;

    for i = 1:DCM.n
        DCM.Y.y(:,i)    = DCM.xY(i).u;
        DCM.Y.name{i}   = DCM.xY(i).name;
    end

    DCM.Y.Q     = spm_Ce(ones(1,DCM.n) * DCM.v);
    microtime   = 16;
    
    %--------------------------------------------------------------------------
    % Experimental inputs. DCM.U part of the DCM structure.
    % Since I'm running DCM on resting-state data, I do not have experimental
    % inputs; the design matrix is just made of regressors
    %--------------------------------------------------------------------------

    DCM.U.u    =  zeros(DCM.v * microtime, 1);  %out_error
    DCM.U.name = {'null'};  

    %--------------------------------------------------------------------------
    % DCM parameters and options
    %--------------------------------------------------------------------------

    DCM.delays = repmat(SPM.xY.RT/2, DCM.n, 1);
    DCM.TE     = 0.030;  % it's the Echo Time in s

    DCM.options.nonlinear   = 0;
    DCM.options.two_state   = 0;
    DCM.options.stochastic  = 0;
    DCM.options.nograph     = 1;
    DCM.options.analysis    = 'csd';
    %DCM.options.centre = 1;

    %--------------------------------------------------------------------------
    % Connectivity matrices for full model of endogenous connections
    %--------------------------------------------------------------------------

    DCM.a = ones(length(rois), length(rois));
%     DCM.b = zeros(DCM.n, DCM.n, 0);
%     DCM.c = zeros(DCM.n, 0);
%     DCM.d = zeros(DCM.n, DCM.n, 0);

    DCM.b = zeros(DCM.n, DCM.n, 1);
    DCM.c = zeros(DCM.n, 1);
    DCM.d = zeros(DCM.n, DCM.n, 1); 

    save(fullfile(run_dir, 'DCM_rest_new.mat'), 'DCM');
    disp([' DCM rest new saved ' ]);
    %--------------------------------------------------------------------------
    % DCM Estimation
    %--------------------------------------------------------------------------
    clear matlabbatch

    matlabbatch{1}.spm.dcm.estimate.dcms.subj.dcmmat    =  {fullfile(run_dir, 'DCM_rest_new.mat')};
    matlabbatch{1}.spm.dcm.estimate.output.single.dir   = {run_dir};
    matlabbatch{1}.spm.dcm.estimate.output.single.name  = 'estim_output';
    matlabbatch{1}.spm.dcm.estimate.est_type            = 1;
    matlabbatch{1}.spm.dcm.estimate.fmri.analysis       = 'csd';
   
    save(fullfile(run_dir, 'estimate_DCM_new.mat'), 'matlabbatch');
    disp([' estimate dcm new saved ' ]);
    spm_jobman('run', matlabbatch);   
    clear matlabbatch DCM SPM 

    ses_run_error = '';

catch
    disp(['Error with specifying DCM for', ' ', ses_no, ' ' run_no]);
    ses_run_error = [ses_no, '_' run_no];
    
end
