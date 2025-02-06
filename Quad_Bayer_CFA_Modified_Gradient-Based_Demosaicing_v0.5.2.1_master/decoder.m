
	%%%%%%%%%%%%%%% Input the photo to be simulated %%%%%%%%%%%%%%%
    imageRGB = imread('test.bmp');

	%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%
	color_raw  = im2double(imageRGB);
	bayer_type = 'gbrg';

	%%%%%%%%%%%%%%% Quad Bayer Image Generation %%%%%%%%%%%%%%%
	[qb_raw, qb_cfa, y, x, crop_r, crop_b] = sampling_quad_bayer(color_raw, bayer_type);

	%%%%%%%%%%%%%%% Quad Bayer Image Decoding %%%%%%%%%%%%%%%
    RGB_binning = quad_bayer_demosaic_binning(qb_raw, y, x, bayer_type, crop_r, crop_b);

	RGB_quarter = quad_bayer_demosaic_quarter(qb_raw, y, x, bayer_type, crop_r, crop_b);

 	RGB_full = quad_bayer_demosaic_full(qb_raw, y, x, bayer_type, crop_r, crop_b);
    psnr_now = psnr(RGB_full,color_raw)
    ssim_now_G = ssim(RGB_full(:,:,2),color_raw(:,:,2))
    ssim_now_R_and_B = (ssim(RGB_full(:,:,1),color_raw(:,:,1)) + ssim(RGB_full(:,:,3),color_raw(:,:,3)))/2
    
    %%%%%%%%%%%%%%% Quad Bayer RGB Image Saving %%%%%%%%%%%%%%%
    %imwrite(im2uint16(RGB_binning),'test_Quad_Bayer_binning.tiff');
    
    %imwrite(im2uint16(RGB_quarter),'test_Quad_Bayer_quarter_res.tiff');
    
    %imwrite(im2uint16(RGB_full),'test_Quad_Bayer_full_res.tiff');
    