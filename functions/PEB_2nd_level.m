function [GCM, PEB, BMA] = peb_2ndlevel_new(GCM_DCM, trt_time_no)

trt_pre     = [trt_time_no '_pre'];
trt_post    = [trt_time_no '_post'];

% Specify PEB model settings
M       = struct();
M.alpha = 1;
M.beta  = 16;
M.hE    = 0;
M.hc    = 1/16;
M.Q     = 'single';

GCM_DCM_pre     = GCM_DCM.(trt_pre);
GCM_DCM_post    = GCM_DCM.(trt_post);

N_pre       = size(GCM_DCM_pre, 1);
N_post      = size(GCM_DCM_post, 1);
N_all       = N_pre + N_post;

% Create contrast
M.X         = [ones(N_all, 1), ...
    cat(1, ones(N_pre, 1) * 0, ones(N_post, 1) * 1)];

% Choose a field
field       = {'A'};
%output
output_result ='DCM/stat/roimodel/DCM_results_new';

% Estimate second level PEB
GCM         = [GCM_DCM_pre; GCM_DCM_post];
PEB         = spm_dcm_peb(GCM, M, field);
fname_PEB   = ['PEB_DCM_' trt_time_no '.mat'];
save(fullfile(output_result, fname_PEB), 'PEB');


% Search over nested models rather than compare specific hypothesis
% You may wish to simply prune away any parameters from the PEB
BMA = spm_dcm_peb_bmc(PEB);
fname_BMA = ['BMA_DCM_' trt_time_no '.mat'];
save(fullfile(output_result, fname_BMA), 'BMA');

end
