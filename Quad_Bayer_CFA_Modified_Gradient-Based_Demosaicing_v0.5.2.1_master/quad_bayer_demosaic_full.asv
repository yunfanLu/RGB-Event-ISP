function RGB_full = quad_bayer_demosaic_full(qb_raw, y, x, bayer_type, crop_r, crop_b)
	%%%%%%%%%%%%%%% User Guide %%%%%%%%%%%%%%%
	% RGB_full:   Full size RGB image output
	% qb_raw:     Quad Bayer RAW Image Input, must be double type.
	% y/x:        Height and width of RAW image
	% bayer_type: Bayer CFA type, only the following modes are supported:
	%            'rggb'
	%            'bggr'
	%            'gbrg'
	%            'grbg' (default)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%
	bayer_type = lower(bayer_type);
	Matrix_A = [2,1,2;1,4,1;2,1,2]/16;
	Matrix_B = [1,2,1;2,4,2;1,2,1]/16;
	Matrix_C = [1;2;3;2;1]*[1,2,3,2,1]./81;
	Matrix_D = [2,1,2;1,4,1;2,1,2]/16;
	Matrix_E = [1;2;4;2;1]*[1,2,4,2,1]./100;
	Matrix_F = [1,2,1;2,4,2;1,2,1]/16;

	%%%%%%%%%%%%%%% Selects the decoding mode that produces the height and width of the image %%%%%%%%%%%%%%%
	%%%%%GRBG mode decoding is used. The rest of the modes are decoded by shifting to GRBG mode.
	switch bayer_type

		case 'rggb'
		raw(:, 3:x+2) = qb_raw;
		raw(y, x+4) = 0;
		m = y;
		n = x+4;
		
		case 'bggr'
		raw(3:y+2, :) = qb_raw;
		raw(y+4, x) = 0;
		m = y+4;
		n = x;
		
		case 'gbrg'
		raw(3:y+2, 3:x+2) = qb_raw;
		raw(y+4, x+4) = 0;
		m = y+4;
		n = x+4;
		
		otherwise
		raw = qb_raw;
		m = y;
		n = x;
	
	end

	%%%%%%%%%%%%%%% Space to process image %%%%%%%%%%%%%%%
	[Mx, My] = meshgrid(1:n, 1:m);

	%%%%%%%%%%%%%%% RGB %%%%%%%%%%%%%%%
	[G2F, ~, Other_colors_used, H_used, V_used, D_used, T_used] = internal_green_gradient_based_interpolation(m, n, raw, Matrix_A, Matrix_B, Matrix_E, Mx, My, crop_r, crop_b);
	[R2F,B2F] = internal_red_and_blue_to_green_diff_interpolation(abs(G2F), raw, Mx, My, m, n, Matrix_C, Matrix_D, Matrix_F, Other_colors_used, H_used, V_used, D_used, T_used);
	
	%%%%%%%%%%%%%%% RGB Merge %%%%%%%%%%%%%%%	
	img(:, :, 1) = R2F(1:end-crop_b, 1:end-crop_r);
	img(:, :, 2) = G2F(1:end-crop_b, 1:end-crop_r);
	img(:, :, 3) = B2F(1:end-crop_b, 1:end-crop_r);

	clear Gsample Other_colors_used;
	
	%%%%%%%%%%%%%%% Crop and Output %%%%%%%%%%%%%%%
	switch bayer_type
	
		case 'rggb'
		RGB_full = img(:, 3:end-2, :);
		
		case 'bggr'
		RGB_full = img(3:end-2, :, :);
		
		case 'gbrg'
		RGB_full = img(3:end-2, 3:end-2, :);
		
		otherwise
		RGB_full = img;
	
	end
	
end