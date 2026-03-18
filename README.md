# 🧠 Dynamic Causal Modeling – Parametric Empirical Bayes
This repository provides a complete pipeline for performing Dynamic Causal Modeling (DCM) and Parametric Empirical Bayes (PEB) analysis on fMRI data using SPM12 in MATLAB.

Dynamic Causal Modeling (DCM) is a framework used to estimate the effective connectivity between brain regions, moving beyond simple correlations to model how one area exerts influence over another. When combined with Parametric Empirical Bayes (PEB), the method allows for a hierarchical analysis where individual-level connection strengths are used to make group-level inferences, accounting for both within-subject and between-subject variability.

Repository Structure

To maintain a clean and reproducible workflow, the files are organized into functional directories:

📂 scripts/

Contains the primary entry-point scripts that drive the analysis pipeline in sequential order.

dcm_1_new.m: Step 1 - Pre-processing & VOI Extraction. Handles GLM specification, movement regressor creation, and extracting Time Series from Volumes of Interest (VOIs).

dcm_2_new.m: Step 2 - Model Specification & Estimation. Sets up the DCM structure (A, B, and C matrices) and runs the inversion/estimation process for every subject.

dcm_3_new.m: Step 3 - Group-level PEB Analysis. Aggregates individual DCMs, defines the second-level design matrix (e.g., treatment vs. placebo), and performs Bayesian Model Averaging (BMA).

📂 functions/

Modular helper functions used by the main scripts to perform specific tasks.

createVOI_new.m: Automates the extraction of masked regional time series.

DCMregressor_new.m: Generates the multiple regressor files (motion, WM, CSF) for the GLM.

specify_dcm_new.m: Defines the neural and hemodynamic parameters for the DCM model.

retrieve_BMA_parameters_new.m: Extracts connectivity strengths and probabilities from the final group results.

spm_glm_rest_dct.m: Implements Discrete Cosine Transform (DCT) filtering within the SPM GLM framework.

parforloop.m: A utility to enable parallel processing for faster computation across large cohorts.

📂 metadata/ (Recommended)

This is where you should store your project-specific configuration files.

analysis_all.csv: The master list containing subject IDs, treatment groups, and timepoints.

roi_model.xlsx: The coordinates and labels for the brain regions included in your connectivity model.

Requirements: - MATLAB

SPM12 (Statistical Parametric Mapping)
