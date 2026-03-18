function VOI_check_matrix = checkmissing_new(df, rois)

% This function checks if your VOIs for DCM are missing
% INPUT: 
%       df = table of states and run numbers
%       dirs = structure of directories
%       rois = cell array of ROIs
%
% OUTPUT:
%       VOI_check_matrix = matrix of VOIs. 'MISSING' = missing VOIs.

%if nargin == 3
%else
 %   error('the first three arguments are required');
%end


%% Check if file exist
template_VOIs = strcat('VOI_', rois, '_1.mat');

% Prepare matrix
VOI_check_matrix = [];

%Loop the subjects list
for ii = 1:height(df)
    
    ii_df       = df(ii, :);
    id          = sprintf('%03d', ii_df.id);
    timepoint   = ii_df.timepoint{1};
    treatment   = ii_df.treatment{1};
    id_trt_time = [id '_' treatment '_' timepoint];
    data_path='conn_VGAIT_rest_20190213';
    rundata= fullfile (data_path, (['rest_' timepoint '_20190213']));
    wm_csf_dir  = 'wm_csf';
    dcmdata_dir = 'DCM/data';
    run_dir     = fullfile(dcmdata_dir, id, treatment, timepoint);
    run_3d_out  = fullfile(run_dir, '3d_data_new');
    run_dir_voi = fullfile(run_dir, 'voi_new');

   % Start looping over the template
   for jj = 1:size(template_VOIs, 1)

       VOI_check_matrix{ii, 1} = id_trt_time;

       if exist(fullfile(run_dir_voi, template_VOIs{jj}), 'file')
           VOI_check_matrix{ii, jj + 1} = 'NOT MISSING';
       else
           VOI_check_matrix{ii, jj + 1} = 'MISSING';
       end % End if loop
   end % End VOI loop
end % End df loop
