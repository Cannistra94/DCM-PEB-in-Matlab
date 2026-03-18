function batch = createVOI_new(id, treatment, timepoint, rois, replace_VOI, spmthresh)

disp(['creating VOIs for ', id, ' ' treatment, ' ', timepoint]);
    
% Create VOI folder to store the VOIs
data_path='conn_VGAIT_rest_20190213';
rundata= fullfile (data_path, (['rest_' timepoint '_20190213']));
wm_csf_dir  = 'wm_csf';
dcmdata_dir = 'DCM/data';
run_dir     = fullfile(dcmdata_dir, id, treatment, timepoint);
run_3d_out  = fullfile(run_dir, '3d_data_new');
run_dir_voi = fullfile(run_dir, 'voi_new');

if ~exist(run_dir_voi, 'dir'); mkdir(run_dir_voi); end % create voi folder if not exist
if ~exist(run_3d_out, 'dir'); mkdir(run_3d_out); end % create state/run folder if not exist

% Convert 4d to 3d if 3d scans not available
run_4dfile = fullfile(rundata, ['swau' timepoint '_rest_VGAIT' id '_' treatment '.nii']);
sample_3dfile = fullfile(run_3d_out, ['swau' timepoint '_rest_VGAIT' id '_' treatment '_00001.nii']);
if ~exist(sample_3dfile, 'file'); convert4dto3d_new(run_4dfile, run_3d_out); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VOLUMES OF INTEREST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(['starting creating VOIs for ', id, ' ' treatment, ' ', timepoint]);
clear matlabbatch SPM  
counter = 1;
for jj=1:size(rois)
    %-------------------------------------------------------%
    % DELETE OLD ROIS TO AVOID CONFUSIONS WITH MISSING ROIS %
    %-------------------------------------------------------% 
    eigenfile = fullfile(run_dir, 'voi_new', ['VOI_' rois{jj} '_1_eigen.nii']);
    matfile = fullfile(run_dir, 'voi_new', ['VOI_' rois{jj} '_1.mat']);
    voifile = fullfile(run_dir, 'voi_new', ['VOI_' rois{jj} '_mask.nii']);
    if replace_VOI
        delete(eigenfile);
        delete(matfile); 
        delete(voifile); 
    end
    
    %--------------------------------------------------%
    % EXTRACTING TIME SERIES FOR ALL ROIS IN EACH PIDN %
    %--------------------------------------------------%
    
    %     matlabbatch{jj}.spm.util.voi.adjust = 0;
    %     You are telling it to use the raw timeseries. 
    %     However, you should be telling it to mean-correct the timeseries, and remove any other nuisance regressors you have included in the GLM. 
    %     
    %     If everything in the GLM is a nuisance regressor (i.e. no interesting effects), you can regress all of these out using:
    %     matlabbatch{jj}.spm.util.voi.adjust = NaN;
    %     
    %     Alternatively, if you have interesting regressors in your design matrix – 
    %     such as cosine basis functions representing the frequencies of the default mode network, or the onsets of trials of a task, then you should do:
    %     matlabbatch{jj}.spm.util.voi.adjust = 1;
    %     Where ‘1’ is the index of your Effects of Interest f-contrast.
    
    if ~exist(matfile, 'file')
        
        matlabbatch{counter}.spm.util.voi.spmmat = cellstr(fullfile(run_dir,'SPM.mat'));
        matlabbatch{counter}.spm.util.voi.adjust = 1; 
        matlabbatch{counter}.spm.util.voi.session = 1; 
        matlabbatch{counter}.spm.util.voi.name = rois{jj};
        matlabbatch{counter}.spm.util.voi.roi{1}.spm.spmmat = {''}; % using SPM.mat above
        matlabbatch{counter}.spm.util.voi.roi{1}.spm.contrast = 1;  % F test
        matlabbatch{counter}.spm.util.voi.roi{1}.spm.threshdesc = 'none';
        matlabbatch{counter}.spm.util.voi.roi{1}.spm.thresh = spmthresh;
        matlabbatch{counter}.spm.util.voi.roi{1}.spm.extent = 0;
        %matlabbatch{counter}.spm.util.voi.roi{2}.spm.mask.contrast = 1; 
        matlabbatch{counter}.spm.util.voi.roi{2}.mask.image = cellstr(fullfile('DCM/rois', [rois{jj}, '.nii,1']));
        matlabbatch{counter}.spm.util.voi.roi{2}.mask.threshold = 0.5; %0.5
        matlabbatch{counter}.spm.util.voi.expression = 'i1 & i2';

        counter = counter + 1;
    end
      
end

% Save the VOI matlabbatch file
if counter ~= 1
    save(fullfile(run_dir, 'extraction_voi_new.mat'), 'matlabbatch');
    spm_jobman('run', matlabbatch);
end

%% Move VOI files to voi folder
voi_files_ext = fullfile(run_dir, 'VOI_*'); 

try
    % Move files to folder
    movefile(voi_files_ext, run_dir_voi);
    msg2 = ['VOI files for ' id ' ' treatment ' ' timepoint ' moved to folder: ' run_dir_voi];
    disp(msg2);
catch
    msg3 = ['VOI files for ' id ' ' treatment ' ' timepoint ' not found.'];
    disp(msg3)
end

% Delete 3d files
% delete3d(dirs, ses_no, run_no);

end
