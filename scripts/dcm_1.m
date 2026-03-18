%% Set parameters
spm_threshold       = 1;

run_DCMregressor    = true;
run_createVOI       = true;
replace_VOI         = false;
run_delete3d        = false;
check_missingvois   = true; 

restoredefaultpath
addpath(genpath('Toolbox/spm12'));
addpath('DCM_PEB_NEW/functions');

% Read data
csvpath= 'DCM/analysis_all.csv';
df = readtable(csvpath);

%access rois file
roispath= 'DCM/models_csv/roi_model.xlsx';
table= readtable(roispath);
rois=table.label;

% Launch SPM
spm('Defaults','fMRI');
spm_jobman('initcfg');

parfor ii = 1:height(df)
    ii_df       = df(ii, :);
    id          = sprintf('%03d', ii_df.id);
    timepoint   = ii_df.timepoint{1};
    treatment   = ii_df.treatment{1};
    try
        % Create multiple regressor file
        disp(['starting dcm regressor new ', id, ' ', treatment, ' ', timepoint]);
        if run_DCMregressor; DCMregressor_new(id, treatment, timepoint); end

        % Create VOIs
        disp(['starting creating voi new ', id, ' ', treatment, ' ', timepoint]);
        if run_createVOI; createVOI_new(id, treatment, timepoint, rois, replace_VOI, spm_threshold); end
        
        % Delete 3d files
        if run_delete3d;  delete3d(dirs, treatment, run_no); end
        
    catch
        disp(['Error running ' id ' ' treatment ' ' timepoint]);
    end
end

%% Check if VOIs are missing
if check_missingvois
    
    % Do the check
    VOI_check_matrix = checkmissing_new(df, rois);

    % Beautify the matrix into a table
    colNames = horzcat({'id_treatment_timepoint'}, transpose(rois)) ;
    sTable = array2table(VOI_check_matrix,'VariableNames', colNames);

    % Save the table
    check_voi= 'DCM/models_voi_check';
    fname = fullfile(check_voi, ['roi_model_missing_vois_new.csv']);
    writetable(sTable, fname, 'WriteRowNames', true);
 
end
