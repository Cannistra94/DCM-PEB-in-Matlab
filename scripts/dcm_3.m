%% Set parameters
spm_threshold       = 1;
model_name          = 'roi_model';
use_parfor      = true;
copy_ind_dcm    = true;

%% FUNCTION STARTS HERE. DO NOT EDIT
%--------------------------------------------------------------------------
restoredefaultpath
addpath(genpath('Toolbox/spm12'));
addpath('DCM_PEB_NEW/functions');


use_parfor       = use_parfor;
copy_ind_dcm     = copy_ind_dcm;

% specify DCM output folders
output_stat = 'DCM/stat/roi_model';
output_files = fullfile(output_stat, 'DCM_files_new');
output_results = fullfile(output_stat, 'DCM_results_new');
if ~exist(output_files,'dir'); mkdir(output_files); end
if ~exist(output_results,'dir'); mkdir(output_results); end

% Read data
df              = readtable('DCM/analysis_all.csv');
df.id_trt_time  = strcat(arrayfun(@(x) sprintf('%03d', x), df.id ,'un', 0), '_', df.treatment, '_', df.timepoint);

% Read roi table

roispath= 'DCM/models_csv/roi_model.xlsx';
table= readtable(roispath);
rois=table.label;


% Assemble DCMs in a group DCM file
if copy_ind_dcm
    for ii = 1:height(df)
        ii_df       = df(ii, :);
        id          = sprintf('%03d', ii_df.id);
        timepoint   = ii_df.timepoint{1};
        treatment   = ii_df.treatment{1};

        % Copy file
        dcmdir='DCM/data';
        run_dir         = fullfile(dcmdir, id, treatment, timepoint);
        source          = fullfile(run_dir, 'DCM_rest_new.mat');
        if exist(source)
            destination     = fullfile(output_files, ['DCM_' id '_' treatment '_' timepoint '.mat']);
            copyfile(source, destination);
        end
    end
    clear ii ii_df id treatment timepoint run_dir source destination;
end

% Separate DCMs into each group
df_split = struct();
GCMs = struct();
params = struct();
params.treatment = {'A', 'B', 'C', 'D'};
params.time = {'pre', 'post'};
for ii = 1:size(params.treatment, 2)
    ii_treatment    = params.treatment{ii};
    for jj = 1:size(params.time, 2)
        jj_time             = params.time{jj};
        trt_time            = [ii_treatment '_' jj_time];
        df_split.(trt_time) = df.id_trt_time(~cellfun('isempty', strfind(df.id_trt_time, trt_time)));
        GCMs.(trt_time)     = fullfile(output_files, strcat('DCM_', df_split.(trt_time), '.mat'));
        
    end   
end
clear ii ii_treatment jj jj_time trt_time;

% Create one huge GCM file
GCM = struct2cell(GCMs);
GCM = vertcat(GCM{:});

% Start SPM
spm('Defaults','fMRI');
spm_jobman('initcfg');

%% Estiamte a first level GCM file
% Fully estimate model by jhana
GCM_VGAIT = spm_dcm_fit(GCM, use_parfor);
save(fullfile(output_results, 'GCM_DCM_fit_new.mat'), 'GCM_VGAIT');
