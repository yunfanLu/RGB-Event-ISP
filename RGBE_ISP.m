function ans_colors = RGBE_ISP(raw_npz_file, json_file, debug, has_known_colors, known_colors, gamma, setting_scale, is_test)

    fprintf('RGBE_ISP:');
    fprintf('   raw_npz_file :%s', raw_npz_file);
    fprintf('   json_file    :%s', json_file);

    % Read the raw data for black level calibration.
    pth_blcraw = './rawdata/3264_2448_8_8_20240423211335479.raw.npy';
    img_blc = readNPY(pth_blcraw);
    img_blc = double(img_blc) / 255.0; % img_blc_1

    if is_test
        test_flag = 1
    else
        test_flag = 0
    end

    % get the file name
    [pathstr, file_name, ext] = fileparts(raw_npz_file);

    using_fpn = 1;

    if debug
        tmp_fpn_image = sprintf('%s/%s_1_tmp_fpn_%d.png', pathstr, file_name, test_flag);
        imwrite(img_blc, tmp_fpn_image);
        % plot save this maxtrix, with value are all in [0, 1]
        % figure();
        % imshow(img_blc);
        % title('img_blc');
        % figure;
        % imshow(img_blc);
        % title('Gamma Corrected Image');
        % tmp_fpn_image = sprintf('%s/%s_1_1_tmp_fpn.png', pathstr, file_name);
        % imwrite(img_blc, tmp_fpn_image);
    end

    % Read rge quad raw data.
    img_quad = readNPY(raw_npz_file);
    img_quad = max(0, min(img_quad, 242));
    img_quad = double(img_quad) / 242.0;

    if debug
        tmp_raw_image = sprintf('%s/%s_2_tmp_raw_wo_fpn_%d.png', pathstr, file_name, test_flag)
        fprintf('tmp_raw_image: %s', tmp_raw_image);
        imwrite(img_quad, tmp_raw_image);
    end

    if using_fpn
        img_quad = img_quad - img_blc;
    else
        img_quad = img_quad;
    end

    if debug
        tmp_raw_image = sprintf('%s/%s_3_tmp_raw_w_fpn_%d_fpn%d.png', pathstr, file_name, test_flag, using_fpn);
        fprintf('tmp_raw_image: %s', tmp_raw_image);
        imwrite(img_quad, tmp_raw_image);
    end

    % clip the value to [0, 1]
    img_quad = max(0, min(img_quad, 1));
    [height, width] = size(img_quad);
    img_rgb = quad_bayer_demosaic_full(img_quad, height, width, 'grgb', 0, 0);

    if debug
        tmp_demosaicd_image = sprintf('%s/%s_4_tmp_demosaicd_%d_fpn%d.png', pathstr, file_name, test_flag, using_fpn);
        fprintf('tmp_demosaicd_image: %s', tmp_demosaicd_image);
        imwrite(img_rgb, tmp_demosaicd_image);
    end

    if has_known_colors
        colors = known_colors;
        ans_colors = [];
    else
        vertex_pts = get_color_card_coords_from_json(json_file);
        % check the vertex_pts has 4 points
        if size(vertex_pts, 1) ~= 4
            disp('Error: vertex_pts has not 4 points');
            return;
        end

        [colors, coord] = checker2colors(img_rgb, [4, 6], 'mode', 'auto', 'show', false, 'vertex_pts', vertex_pts);
        % save colors to file
        color_file = sprintf('%s/%s_colors.mat', pathstr, file_name);
        save(color_file, 'colors');
        % the colors will be reture value.
        ans_colors = colors
        % check NaN value in colors
        if any(isnan(colors))
            disp('Error: colors has NaN value');
            fprintf('raw_npz_file: %s', raw_npz_file);
            return;
        end

    end

    wb_multipliers = [colors(21, 2) / colors(21, 1), 1.0, colors(21, 2) / colors(21, 3)];
    img_wb = img_rgb;
    img_wb(:, :, 1) = img_wb(:, :, 1) * wb_multipliers(1);
    img_wb(:, :, 3) = img_wb(:, :, 3) * wb_multipliers(3);
    img_wb = max(0, min(img_wb, 1));

    if debug
        tmp_wb_image = sprintf('%s/%s_5_tmp_wb_%d.png', pathstr, file_name, test_flag);
        fprintf('tmp_wb_image: %s', tmp_wb_image);
        imwrite(img_wb, tmp_wb_image);
    end

    randn('seed', 0);
    sigma = 25;

    if is_test
        img_denoise = img_wb;
    else
        [~, img_denoise] = CBM3D(1, img_wb, sigma);

        if debug
            tmp_denoise_image = sprintf('%s/%s_6_tmp_denoise_%d_fpn%d.png', pathstr, file_name, test_flag, using_fpn);
            fprintf('tmp_denoise_image: %s', tmp_denoise_image);
            imwrite(img_denoise, tmp_denoise_image);
        end

    end

    srgb = zeros(24, 3);

    colors2checker(srgb);

    colors_wb = colors .* wb_multipliers

    % colors_wb = max(0, min(colors_wb, 1));

    % 24 x 3
    [ccm, scale, ~, ~] = ccmtrain(colors_wb, ...
        srgb, ...
        'omitlightness', true, ...
        'preservewhite', true, ...
        'model', 'linear3x3', ...
        'targetcolorspace', 'sRGB', ...
        'whitepoint', whitepoint('d65'));

    if setting_scale >= 1
        fprintf('Setting scale: %f Original scale: %f', setting_scale, scale);
        scale = setting_scale;
    end

    cam2xyz = ccm;
    lin_srgb = apply_cmatrix(img_denoise * (scale * 0.9), transpose(cam2xyz));
    lin_srgb = max(0, min(lin_srgb, 1));

    if debug
        tmp_lin_srgb_image = sprintf('%s/%s_7_tmp_lin_srgb_%d_fpn%d.png', pathstr, file_name, test_flag, using_fpn);
        fprintf('tmp_lin_srgb_image: %s', tmp_lin_srgb_image);
        imwrite(lin_srgb, tmp_lin_srgb_image);
    end

    % img_srgb = lin_srgb .^ 0.45;
    img_srgb = lin_srgb .^ gamma;
    img_srgb = max(0, min(img_srgb, 1));

    if debug
        tmp_good_srgb_image = sprintf('%s/%s_8_tmp_good_srgb_fpn%d.png', pathstr, file_name, using_fpn);
        imwrite(img_srgb, tmp_good_srgb_image);
    end

    good_rgb_file = sprintf('%s/%s_good_rgb.png', pathstr, file_name);
    imwrite(img_srgb, good_rgb_file);
    fprintf('DONE: %s', good_rgb_file);

end
