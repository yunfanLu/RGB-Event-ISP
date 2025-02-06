function [qb_raw, qb_cfa, y, x, crop_r, crop_b] = sampling_quad_bayer(color_raw, bayer_type)

	%%%%%%%%%%%%%%% User Guide %%%%%%%%%%%%%%%
	% qb_raw:     Quad Bayer RAW Image Output
	% qb_cfa:     Quad Bayer RAW Fake Color Image
	% y/x:        Height and width of RAW image
	% crop_r:     Right black edge crop value
	% crop_b:     Bottom black edge crop value
	% color_raw:  RGB color image. It's recommended to use double-type linear space image by "im2double" conversion.
	% bayer_type: Bayer CFA type, only the following modes are supported.
	%            'rggb'
	%            'bggr'
	%            'gbrg'
	%            'grbg' (default)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if nargin == 1
		bayer_type = 'grbg';
	end
	
	%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%
	crop_r = 0;
	crop_b = 0;
	bayer_type = lower(bayer_type);
	
	%%%%%%%%%%%%%%% load the image %%%%%%%%%%%%%%%
	org = color_raw;
	
	%%%%%%%%%%%%%%% Height and width of RAW image %%%%%%%%%%%%%%%
	[m,n] = size(org(:,:,1));
	
	%%%%%%%%%%%%%%% Expanded processable space %%%%%%%%%%%%%%%
	y = ceil(m/4)*4;
	x = ceil(n/4)*4;
	
	if (y ~= m)
		org(y,:,:) = 0;
		crop_b = y - m;
	end
	
	if (x ~= n)
		org(:,x,:) = 0;
		crop_r = x - n;
	end
	
	%%%%%%%%%%%%%%% R/G/B CFA %%%%%%%%%%%%%%%
	switch bayer_type
	
		case 'rggb'
			Rcfa = repmat([1 1 0 0; 1 1 0 0; 0 0 0 0; 0 0 0 0],[m,n]/4);
			Gcfa = repmat([0 0 1 1; 0 0 1 1; 1 1 0 0; 1 1 0 0],[m,n]/4);
			Bcfa = repmat([0 0 0 0; 0 0 0 0; 0 0 1 1; 0 0 1 1],[m,n]/4);
			
		case 'bggr'
			Bcfa = repmat([1 1 0 0; 1 1 0 0; 0 0 0 0; 0 0 0 0],[m,n]/4);
			Gcfa = repmat([0 0 1 1; 0 0 1 1; 1 1 0 0; 1 1 0 0],[m,n]/4);
			Rcfa = repmat([0 0 0 0; 0 0 0 0; 0 0 1 1; 0 0 1 1],[m,n]/4);
			
		case 'gbrg'
			Gcfa = repmat([1 1 0 0; 1 1 0 0; 0 0 1 1; 0 0 1 1],[m,n]/4);
			Bcfa = repmat([0 0 1 1; 0 0 1 1; 0 0 0 0; 0 0 0 0],[m,n]/4);
			Rcfa = repmat([0 0 0 0; 0 0 0 0; 1 1 0 0; 1 1 0 0],[m,n]/4);	
			
		case 'grbg'
			Gcfa = repmat([1 1 0 0; 1 1 0 0; 0 0 1 1; 0 0 1 1],[m,n]/4);
			Rcfa = repmat([0 0 1 1; 0 0 1 1; 0 0 0 0; 0 0 0 0],[m,n]/4);
			Bcfa = repmat([0 0 0 0; 0 0 0 0; 1 1 0 0; 1 1 0 0],[m,n]/4);
			
		otherwise
			disp('Wrong value! bayer_type is set to "grbg" by default.');
			Gcfa = repmat([1 1 0 0; 1 1 0 0; 0 0 1 1; 0 0 1 1],[m,n]/4);
			Rcfa = repmat([0 0 1 1; 0 0 1 1; 0 0 0 0; 0 0 0 0],[m,n]/4);
			Bcfa = repmat([0 0 0 0; 0 0 0 0; 1 1 0 0; 1 1 0 0],[m,n]/4);
			
	end
	
	%%%%%%%%%%%%%%% Sub-sampling %%%%%%%%%%%%%%%
	Rorg = double(org(:,:,1));
	Gorg = double(org(:,:,2));
	Borg = double(org(:,:,3));
	
	%%%%%%%%%%%%%%% Quad Bayer RAW Image Output %%%%%%%%%%%%%%%
	qb_raw = Rorg.*Rcfa + Gorg.*Gcfa + Borg.*Bcfa;
	
    qb_cfa(:,:,1) = Rorg.*Rcfa;
    qb_cfa(:,:,2) = Gorg.*Gcfa;
    qb_cfa(:,:,3) = Borg.*Bcfa;
end