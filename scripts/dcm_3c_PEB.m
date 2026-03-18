%% Set parameters
spm_threshold   = 1;
model_name      = 'roi_model';
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
df.trt_time     = strcat(df.treatment, '_', df.timepoint);
df.id_trt_time  = strcat(arrayfun(@(x) sprintf('%03d', x), df.id ,'un', 0), '_', df.treatment, '_', df.timepoint);

% Read roi table
roispath= 'DCM/models_csv/roi_model.xlsx';
table= readtable(roispath);
rois    = roi_table.region;

% Read first level PEB
GCM_DCM = struct();
load(fullfile(output_results, 'GCM_DCM_fit_new.mat'))
params                  = struct();
params.time             = {'pre', 'post'};
params.treatment        = {'A', 'B', 'C', 'D'};
for ii = 1:size(params.treatment, 2)
    ii_treatment    = params.treatment{ii};
    for jj = 1:size(params.time, 2)
        jj_time             = params.time{jj};
        trt_time            = [ii_treatment '_' jj_time];
        i_bool              = ismember(df.trt_time, trt_time);
        GCM_DCM.(trt_time)  = GCM_VGAIT(i_bool);
    end   
end
clear ii ii_treatment jj jj_time trt_time i_bool;

spm_dcm_fmri_check({GCM_DCM.A_pre{1}; GCM_DCM.A_pre{2}})

%% Diagnostics check (after having completed the estimation of the first-level DCMs)
stability = struct();
variance = struct();

for ii = 1:size(params.treatment, 2)
    ii_treatment  = params.treatment{ii};
    for jj = 1:size(params.time, 2)
        jj_time   = params.time{jj};
        trt_time  = [ii_treatment '_' jj_time];
        for kk = 1:size(GCM_DCM.(trt_time), 1)
            DCM_ij                      = GCM_DCM.(trt_time){jj};
            stability.(trt_time)(kk, 1) = spm_dcm_check_stability(DCM_ij);
            PSS   = sum(sum(sum(abs(DCM_ij.Hc).^2)));
            RSS   = sum(sum(sum(abs(DCM_ij.Rc).^2)));
            varExp  = 100*PSS/(PSS + RSS);
            variance.(trt_time)(kk, 1)  = varExp;
        end   
    end
end
stability = struct2cell(stability); df.stability = vertcat(stability{:});
variance = struct2cell(variance);   df.variance = vertcat(variance{:});
clear ii ii_treatment jj jj_time trt_time kk DCM_ij;

%% Retrieve first level parameters
for i = 1:size(GCM_VGAIT,1)
    subCM(i,:) = GCM_VGAIT{i}.Ep.A(:)'; % Connectivity matrix
    subPM(i,:) = GCM_VGAIT{i}.Pp.A(:)'; % Probability matrix
end

subCM = num2cell(subCM);
subPM = num2cell(subPM);


roi_roi = {};
counter = 1;
for i = 1:length(rois)
    for j = 1:length(rois)
        roi_roi{counter} = [rois{i} '_' rois{j}];
        counter = counter + 1;
    end
end

subCM = cell2table(subCM, 'VariableNames', roi_roi);
subPM = cell2table(subPM, 'VariableNames', roi_roi);

fname_CM = fullfile(output_stat, [model_name '_CM_new.csv']);
fname_PM = fullfile(output_stat, [model_name '_PM_new.csv']);
writetable([df, subCM], fname_CM, 'WriteRowNames', false);
writetable([df, subPM], fname_PM, 'WriteRowNames', false);


%% Estimate a second level PEB (Parametric Empirical Bayes) model
trt_time_no1 = 'C';
trt_time_no2 = 'A';
[GCM1, PEB1, BMA1] = peb_2ndlevel_new(GCM_DCM, trt_time_no1);
[GCM2, PEB2, BMA2] = peb_2ndlevel_new(GCM_DCM, trt_time_no2);


% Review results
%spm_dcm_peb_review(BMA1, GCM1);
spm_dcm_peb_review(BMA1, GCM1);
spm_dcm_peb_review(BMA2, GCM2);

%% Retrieve second-level parameters and save
BMA_parameters = struct();
BMA_parameters.(trt_time_no1) = retrieve_BMA_parameters_new( rois, trt_time_no1);
BMA_parameters.(trt_time_no2) = retrieve_BMA_parameters_new( rois, trt_time_no2);
BMA_parameters = struct2cell(BMA_parameters);
BMA_parameters = vertcat(BMA_parameters{:});

% Save the table
fname = fullfile(output_stat, [model_name '_' trt_time_no1 '_' trt_time_no2 '_BMA_parameters_new.csv']);
writetable(BMA_parameters, fname, 'WriteRowNames', false);


%% Run Third-level PEB
trt_time_no3 = [trt_time_no1 '_' trt_time_no2];
GCM     = {GCM2; GCM2};
PEBs    = {PEB1; PEB2};
X3      = [1 -1; 1 1];
PEB    = spm_dcm_peb(PEBs, X3);
BMA    = spm_dcm_peb_bmc(PEB);
fname_BMA3 = ['BMA_DCM_thirdlevel' trt_time_no3 '.mat'];
save(fullfile(output_results, fname_BMA3), 'BMA');
spm_dcm_peb_review(BMA);

%BMA_parameters = struct();
%BMA_parameters.(trt_time_no3) = retrieve_BMA_parameters(dirs, rois, trt_time_no3);


%% Balanced design
% N_trt1_pre  = size(GCM_DCM.([trt_time_no1 '_pre']), 1);
% N_trt1_post = size(GCM_DCM.([trt_time_no1 '_post']), 1);
% N_trt2_pre  = size(GCM_DCM.([trt_time_no1 '_pre']), 1);
% N_trt2_post = size(GCM_DCM.([trt_time_no1 '_post']), 1);
% N_all       = N_trt1_pre + N_trt1_post + N_trt2_pre + N_trt2_post;
% 
% GCM = [GCM_DCM.([trt_time_no1 '_pre']); ...
%     GCM_DCM.([trt_time_no1 '_post']); ...
%     GCM_DCM.([trt_time_no2 '_pre']); ...
%     GCM_DCM.([trt_time_no2 '_post']); ...
%     ];
% X = [ones(N_all, 1), ...
%     cat(1, ones(N_trt1_pre, 1) * -1, ones(N_trt1_post, 1) * 1,  ones(N_trt2_pre, 1) * 0, ones(N_trt2_post, 1) * 0), ...
%     cat(1, ones(N_trt1_pre, 1) * 0, ones(N_trt1_post, 1) * 0,  ones(N_trt2_pre, 1) * -1, ones(N_trt2_post, 1) * 1), ...
%     cat(1, ones(N_trt1_pre, 1) * 1, ones(N_trt1_post, 1) * -1,  ones(N_trt2_pre, 1) * -1, ones(N_trt2_post, 1) * 1)];
% 
% PEB = spm_dcm_peb(GCM, X);
% spm_dcm_peb_review(PEB, GCM);
% 
