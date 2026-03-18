function DCMregressor_new(id, treatment, timepoint)

% CONSTANTS
TR = 3; 

% Print run number
disp(['creating regressor file for ', id, ' ', treatment, ' ', timepoint]);

% Set directories
data_path='conn_VGAIT_rest_20190213';
rundata= fullfile (data_path, (['rest_' timepoint '_20190213']));

wm_csf_dir  = 'wm_csf';
dcmdata_dir = 'DCM/data';
run_dir     = fullfile(dcmdata_dir, id, treatment, timepoint);
run_3d_out  = fullfile(run_dir, '3d_data_new');

if ~exist(run_dir, 'dir'); mkdir(run_dir); end % create state/run folder if not exist
if ~exist(run_3d_out, 'dir'); mkdir(run_3d_out); end % create state/run folder if not exist

% Get the regressors 

motion_file     = ['rp_' timepoint '_rest_VGAIT' id '_' treatment '.txt'];
wm_file         = ['ROISignals_' id '_' timepoint '_' treatment '_wm_signals.txt'];
csf_file        = ['ROISignals_' id '_' timepoint '_' treatment '_csf_signals.txt'];

motion_params   = load(fullfile(rundata, motion_file));
wm_signals      = load(fullfile(wm_csf_dir, wm_file));
csf_signals     = load(fullfile(wm_csf_dir, csf_file));
mult_regs       = [wm_signals, csf_signals]; % Combine motion, wm, csf
[n, n_covar]    = size(mult_regs);


% DCT.  Creates discrete cosine set with frequencies ranging from the UL to the
% LL (default UL = 0.1Hz, LL = 1/128hz). Inputs are:
% dir = path for output SPM
% n = number of scans
% covar =  multiple regressor file
%--------------------------------------------------------------------------
% Prepare DCT
% -------------------------------------------------------------------------
disp(['starting spm glm rest dct function for ', id, ' ', treatment, ' ', timepoint]);

[n_cols, R] = spm_glm_rest_dct(run_dir, TR, n, mult_regs); 
savefile = fullfile(run_dir, 'glm_regr_new.mat');
save(savefile, 'R');
disp(['starting convert 4d to 3d for ', id, ' ', treatment, ' ', timepoint]);
% Convert 4D to 3D
run_4dfile = fullfile(rundata, ['swau' timepoint '_rest_VGAIT' id '_' treatment '.nii']);
sample_3dfile = fullfile(run_3d_out, ['swau' timepoint '_rest_VGAIT' id '_' treatment '_00001.nii']);
if ~exist(sample_3dfile, 'file'); convert4dto3d_new(run_4dfile, run_3d_out); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GLM SPECIFICATION, ESTIMATION & INFERENCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(['starting glm specification for ', id, ' ', treatment, ' ', timepoint]);
factors = load(fullfile(run_dir, 'glm_regr_new.mat')); % adapted
f = spm_select('FPList', fullfile(run_3d_out), [treatment '_*']);
img = cellstr(strcat(f, ',1'));

%clear matlabbatch
matlabbatch = [];

% OUTPUT DIRECTORY
%--------------------------------------------------------------------------
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = cellstr(run_dir);
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = 'GLM_new';


% MODEL SPECIFICATION
%--------------------------------------------------------------------------
matlabbatch{2}.spm.stats.fmri_spec.dir = cellstr(run_dir);
matlabbatch{2}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{2}.spm.stats.fmri_spec.timing.RT = TR;
matlabbatch{2}.spm.stats.fmri_spec.sess.scans = img(:, 1);
matlabbatch{2}.spm.stats.fmri_spec.sess.hpf = 100;
matlabbatch{2}.spm.stats.fmri_spec.sess.multi_reg = cellstr(fullfile(run_dir, 'glm_regr_new.mat'));
matlabbatch{1,2}.spm.stats.fmri_spec.bases  = struct('none', 1);

% MODEL ESTIMATION
%--------------------------------------------------------------------------
matlabbatch{3}.spm.stats.fmri_est.spmmat = cellstr(fullfile(run_dir, 'SPM.mat'));

% INFERENCE
%--------------------------------------------------------------------------
matlabbatch{4}.spm.stats.con.spmmat = cellstr(fullfile(run_dir, 'SPM.mat'));
matlabbatch{4}.spm.stats.con.consess{1}.fcon.name = 'Effects of Interest';
matlabbatch{4}.spm.stats.con.consess{1}.fcon.weights = eye(n_cols);

modelspecfile = fullfile(run_dir, 'model_spec_inference_new.mat');

%delete(fullfile(run_dir, 'SPM.mat'));
disp(['saving final files of dcm regressor function for ', id, ' ', treatment, ' ', timepoint]);
save(modelspecfile, 'matlabbatch');
disp(['model spec inference new saved for ', id, ' ', treatment, ' ', timepoint]);
spm_jobman('interactive', matlabbatch);
disp(['dcmregressor_new done for ', id, ' ', treatment, ' ', timepoint]);
