% Set parameters
spm_threshold   = 1;
model_name      = 'roi_model';
use_parfor      = true;

%% FUNCTION STARTS HERE. DO NOT EDIT
%--------------------------------------------------------------------------
restoredefaultpath
addpath(genpath('Toolbox/spm12'));
addpath('DCM_PEB_NEW/functions');

tablepath='DCM/analysis_all.csv';
% Read data
df = readtable(tablepath);

% Read roi table
roispath= 'DCM/models_csv/roi_model.xlsx';
table= readtable(roispath);
rois=table.label;


% Start SPM
spm('Defaults','fMRI');
spm_jobman('initcfg');
parforloop(df);
%% Specify DCM
%parfor ii = 1:height(df)
 %   ii_df       = df(ii, :);
  %  id          = sprintf('%03d', ii_df.id);
   % timepoint   = ii_df.timepoint{1};
    %treatment   = ii_df.treatment{1};
    %disp(['running for ' id ' ' treatment ' ' timepoint]);
     %Specifying DCM
    %disp(['Specifying DCM for ' id ' ' treatment ' ' timepoint]);
    %out_error = specify_dcm_new(id, treatment, timepoint, rois);
%end
