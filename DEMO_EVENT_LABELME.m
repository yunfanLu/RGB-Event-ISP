close all
clear all
addpath('./npy-matlab-master/npy-matlab/')
addpath('./Quad_Bayer_CFA_Modified_Gradient-Based_Demosaicing_v0.5.2.1_master/')
addpath('./color-checker-extraction-master/')
addpath(genpath('./color-correction-toolbox-master/'))
addpath('./BM3D-master')
pth_raw = './rawdata/quad.npy';

%calibrate the blc and fpn
pth_blcraw = './rawdata/3264_2448_8_8_20240423211335479.raw.npy';
img_blc = readNPY(pth_blcraw);
img_blc = double(img_blc) / 255.0;
blc = min(img_blc(:));
img_fpn = img_blc - blc;
imwrite(img_fpn, 'rawdata/img_fpn.png');

%read quad raw
img_quad = readNPY(pth_raw);
img_quad = double(img_quad) / 255.0;

img_quad = img_quad - blc -img_fpn;
img_quad = max(0, min(img_quad, 1));
[height, width] = size(img_quad);
%quad2rgb
%img_rgb  = quad_bayer_demosaic_full(img_quad, height, width, 'grgb', 0, 0);
img_rgb = quad_bayer_demosaic_binning(img_quad, height, width, 'grgb', 0, 0);
% figure();
% imshow(img_rgb);
imwrite(img_rgb, 'rawdata/img_rgb_demosaicd.png')

%interactive get wb and ccm
vertex_pts = [856.5548 851.8973;
              338.6370 902.8196;
              296.4087 562.5091;
              825.5046 505.3767];
[colors, coord] = checker2colors(img_rgb, [4, 6], 'mode', 'auto', 'show', false, 'vertex_pts', vertex_pts);

%filename = fullfile('data', '0012_DSC_11116.DNG');
%[~, metadata] = Load_Data_and_Metadata_from_DNG(filename);

%white balance
%wb_multipliers = metadata.AsShotNeutral;
%wb_multipliers = wb_multipliers.^-1;

wb_multipliers = [colors(21, 2) / colors(21, 1), 1.0, colors(21, 2) / colors(21, 3)];
img_wb = img_rgb;
img_wb(:, :, 1) = img_wb(:, :, 1) * wb_multipliers(1);
img_wb(:, :, 3) = img_wb(:, :, 3) * wb_multipliers(1);
img_wb = max(0, min(img_wb, 1));


% figure();
% imshow(img_wb);
imwrite(img_wb, 'rawdata/img_wb.png')

%denoise here, it takes long time here. be patient.
randn('seed', 0);
sigma = 25;
[~, img_denoise] = CBM3D(1, img_wb, sigma);
%img_denoise = img_wb;
% figure();
% imshow(img_denoise);
imwrite(img_denoise, 'rawdata/img_denoise.png')

%optimize ccm and apply ccm
if false
    load('spectral_reflectance_data.mat');
    spectra = spectral_reflectance_data.XRite_Classic;
    % calculate the XYZ values for the color checker under D65
    srgb = spectra2colors(spectra, 400:5:700, ...
        'spd', 'D65', 'output', 'sRGB');
end

srgb = zeros(24, 3);
srgb = [
        112, 76, 60;
        197, 145, 125; 87, 120, 155; 82, 106, 60; 126, 125, 174; 98, 187, 166;
        238, 158, 25; 157, 188, 54; 83, 58, 106; 195, 79, 95; 58, 88, 159; 222, 118, 32;
        25, 55, 135; 57, 146, 64; 186, 26, 51; 245, 205, 0; 192, 75, 145; 0, 127, 159;
        43, 41, 43; 80, 80, 78; 122, 118, 116; 161, 157, 154; 202, 198, 195; 249, 242, 238;
        ];
srgb = srgb / 255.0;
srgb = srgb .^ 2.2;
colors2checker(srgb);


colors_wb = colors;
colors_wb(:,1) = colors_wb(:,1) * wb_multipliers(1);
colors_wb(:,3) = colors_wb(:,3) * wb_multipliers(3);

[ccm, scale, ~, ~] = ccmtrain(colors_wb,...
                              srgb,...
                             'omitlightness',true,...
                             'preservewhite',true,...
                             'model', 'linear3x3',...
                             'targetcolorspace', 'sRGB',...
                             'whitepoint', whitepoint('d65'));
cam2xyz = ccm;
lin_srgb = apply_cmatrix(img_denoise * (scale * 0.9), transpose(cam2xyz));
lin_srgb = max(0, min(lin_srgb, 1)); % clip
%img_srgb=xyz2rgb(lin_xyz); % xyz to srgb -- this one applies gamma
%img_srgb = max(0,min(img_srgb,1));
img_srgb = lin_srgb .^ 0.6;
img_srgb = max(0, min(img_srgb, 1));
%linsrgb2rgb(lin_srgb); this camera has a weird rgb spectrum curve.
% figure();
% imshow(img_srgb);
imwrite(img_srgb, 'rawdata/img_srgb.png');
disp('DONE');