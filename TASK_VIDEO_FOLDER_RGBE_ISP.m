function [] = TASK_VIDEO_FOLDER_RGBE_ISP(root)
    json_files = dir(fullfile(root, '*.json'));
    raw_npz_files = dir(fullfile(root, '*.npy'));
    debug = false;

    for i = 1:length(json_files)
        raw_npz_file = fullfile(root, raw_npz_files(i).name)
        json_file = fullfile(root, json_files(i).name)
        RGBE_ISP(raw_npz_file, json_file, debug);
    end
end