function Main(root)
    close all
    clear all
    addpath('./npy-matlab-master/npy-matlab/')
    addpath('./Quad_Bayer_CFA_Modified_Gradient-Based_Demosaicing_v0.5.2.1_master/')
    addpath('./color-checker-extraction-master/')
    addpath(genpath('./color-correction-toolbox-master/'))
    addpath('./BM3D-master')

    % Read the raw data for black level calibration.
    % no scale
    TASK_VIDEO_FOLDER_RGBE_ISP_LIMITED_BBOX(root, 10, 0.45, 1.6, false)
    % %
    % TASK_VIDEO_FOLDER_RGBE_ISP_LIMITED_BBOX(root, 10, 0.45, 1.6, true)
    % TASK_VIDEO_FOLDER_RGBE_ISP_LIMITED_BBOX(root, 10, 0.45, 0, true)
end