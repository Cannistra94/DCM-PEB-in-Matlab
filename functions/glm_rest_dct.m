
function [n_cols, dct_mreg] = spm_glm_rest_dct(dir, TR, n, mult_regs)

% Specify and estimate a DCT GLM
% -------------------------------------------------------------------------
% Creates discrete cosine set with frequencies ranging from the UL to the
% LL (default UL = 0.1Hz, LL = 1/128hz). Inputs are:
% dir = path for output SPM
% scans = cell array of strings with the paths to your scans
% n = number of scans
% mult_regs = path to multiple regressor file

% -------------------------------------------------------------------------
% 

% Prepare DCT
% -------------------------------------------------------------------------
full_dct = spm_dctmtx(n, n);
UL       = 0.08;
LL       = 0.02;

% Calculate lower limit components & remove
LL_com   = fix(2*(n*TR)*LL+1); 
full_dct(:,1:LL_com) = []; 
        
% Calculate upper limit components & remove
UL_com   = fix(2*(n*TR)/(1/UL)+1);
full_dct(:,UL_com:end) = []; 

[~, n_cols] = size(full_dct);

% Integrate into nuissance matrix
% -------------------------------------------------------------------------
%mreg     = load(mult_regs,'-ascii');
dct_mreg = [full_dct mult_regs]; clear mreg;

cd(dir);

dlmwrite('mreg_full_dct_new.txt', dct_mreg, '\t');
mreg     = fullfile(dir,'mreg_full_dct_new.txt');

% Calculate the contrasts to test
%if n>200
%     F = eye(n_cols+1);
%     F(1,1) = 0;
%else
    F = eye(n_cols);
%end

% Prepare GLMDCT
% -------------------------------------------------------------------------
% spm_glmx(dir,TR,scans,mreg,'dct',F);
