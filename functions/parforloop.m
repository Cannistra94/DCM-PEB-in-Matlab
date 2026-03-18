function parforloop(df)
parfor ii = 1:height(df)
    ii_df       = df(ii, :);
    id          = sprintf('%03d', ii_df.id);
    timepoint   = ii_df.timepoint{1};
    treatment   = ii_df.treatment{1};
    disp(['running for ' id ' ' treatment ' ' timepoint]);
     %Specifying DCM
    disp(['Specifying DCM for ' id ' ' treatment ' ' timepoint]);
    out_error = specify_dcm_new(id, treatment, timepoint, rois);
end
