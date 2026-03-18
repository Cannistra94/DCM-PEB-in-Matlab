function convert4dto3d_new(run_4dfile, run_3d_out)

disp('3D scan files do not exist; Converting 4D to 3D scans now...');

% Copy data to DCM run directory temporarily
[filepath, name, ext]   = fileparts(run_4dfile);
filename                = [name ext];
copied_4dfile           = fullfile(run_3d_out, filename);
copyfile(run_4dfile, run_3d_out);

% Convert
matlabbatch = [];
matlabbatch{1}.spm.util.split.vol       = {[copied_4dfile ',1']};
matlabbatch{1}.spm.util.split.outdir    = {run_3d_out};
spm_jobman('run', matlabbatch);

% Delete 4d file
delete(copied_4dfile); 

end
