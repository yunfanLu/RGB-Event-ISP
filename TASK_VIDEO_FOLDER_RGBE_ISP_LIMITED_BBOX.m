function [] = TASK_VIDEO_FOLDER_RGBE_ISP_LIMITED_BBOX(root, N, gamma, scale, test)

    addpath('./npy-matlab-master/npy-matlab/')
    addpath('./Quad_Bayer_CFA_Modified_Gradient-Based_Demosaicing_v0.5.2.1_master/')
    addpath('./color-checker-extraction-master/')
    addpath(genpath('./color-correction-toolbox-master/'))
    addpath('./BM3D-master')
    %
    root
    json_files = dir(fullfile(root, '*.json'));
    raw_npz_files = dir(fullfile(root, '*.npy'));
    debug = true;

    % 对 json_files 按照第四个数字进行排序
    [~, json_order] = sort(arrayfun(@(x) getFourthNumber(x.name), json_files));
    json_files = json_files(json_order);

    % 对 raw_npz_files 按照第四个数字进行排序
    [~, raw_npz_order] = sort(arrayfun(@(x) getFourthNumber(x.name), raw_npz_files));
    raw_npz_files = raw_npz_files(raw_npz_order);

    colors = 0;
    color_template = 0;
    color_cound = 0;
    for i = 1:length(json_files)
        raw_npz_file = fullfile(root, raw_npz_files(i).name);
        if i <= N
            json_file = fullfile(root, json_files(i).name)
            color_template = RGBE_ISP(raw_npz_file, json_file, debug, false, [], gamma, scale, test);
            if isnan(color_template)
                continue;
            end

            colors = colors + color_template;
            color_cound = color_cound + 1;

            if test
                return;
            end

            if i == N
                if color_cound == 0
                    return;
                end
                colors = colors / color_cound;
                [pathstr, file_name, ext] = fileparts(raw_npz_file);
                color_file = sprintf('%s/%s_%d_colors_average.mat', pathstr, file_name, N);
                save(color_file, 'colors');
            end
        else
            color_template = RGBE_ISP(raw_npz_file, NaN, debug, true, colors, gamma, scale, test);
        end
    end
end

function fourth_number = getFourthNumber(filename)
    parts = strsplit(filename, '_');
    fourth_number = str2double(parts{4});
end