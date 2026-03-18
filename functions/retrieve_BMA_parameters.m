function [parameters] = retrieve_BMA_parameters_new( rois, trt_time_no)

% Load BMA

output_stat = 'DCM/stat/roimodel';
output_results = fullfile(output_stat, 'DCM_results_new');
load(fullfile(output_results, ['BMA_DCM_' trt_time_no '.mat']), 'BMA');
% Retrieve CP and PP matrices
analysis_j1j2 = repmat({trt_time_no}, length(rois)^2, 1);

%defining Ep, 
n_parameters = length(rois)^2;
mult=2;
startingindx = n_parameters*(mult-1) + 1;
endingindx = n_parameters*mult;

Ep = full(BMA.Ep(startingindx:endingindx));

%defining Pp
np = length(BMA.Pnames); % Parameters
ns = length(BMA.Snames); % Subjects
nc = size(BMA.Ep(n_parameters+1:n_parameters+n_parameters)); 
Ep = BMA.Ep(startingindx:endingindx);
Cp = diag(BMA.Cp);
Cp = Cp(startingindx:endingindx);

T  = 0;
Pp = 1 - spm_Ncdf(T,abs(Ep),Cp);

%defining CI
Ep = full(BMA.Ep);
[nrow, ncol] = size(Ep);
ncovariates = nrow*ncol/n_parameters;
totalConnections = n_parameters*ncovariates;


Cp = zeros(totalConnections,1);
for i = 1:totalConnections
    Cp(i,1) = BMA.Cp(i,i);
end

% Get the CI
startingindx = n_parameters*(mult-1) + 1;
endingindx = n_parameters*mult;
CI_0 = Cp(startingindx:endingindx,:);
ci = spm_invNcdf(1 - 0.05);  
CI = ci * sqrt(CI_0);

roi_roi = {};
counter = 1;
for i = 1:length(rois)
    for j = 1:length(rois)
        roi_roi{counter, 1} = [rois{i} '_' rois{j}];
        counter = counter + 1;
    end
end

parameters = table(analysis_j1j2, roi_roi, Ep, Pp, CI);

end
