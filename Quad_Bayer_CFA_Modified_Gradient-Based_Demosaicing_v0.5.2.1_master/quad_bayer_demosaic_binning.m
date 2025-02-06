function RGB_demosaic = quad_bayer_demosaic_binning(qb_raw, y, x, bayer_type, crop_r, crop_b)
	%%%%%%%%%%%%%%% User Guide %%%%%%%%%%%%%%%
	% RGB_binning:Quarter size RGB image output
	% qb_raw:     Quad Bayer RAW Image Input, must be double type.
	% y/x:        Height and width of RAW image
	% bayer_type: Bayer CFA type, only the following modes are supported：
	%            'rggb'
	%            'bggr'
	%            'gbrg'
	%            'grbg' (default)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%
	bayer_type = lower(bayer_type);
 
	yp = y/2;
	xp = x/2;
	crop_rp = floor(crop_r/2);
	crop_bp = floor(crop_b/2);

	binning_raw = ( qb_raw(1:2:end-1, 1:2:end-1) + qb_raw(1:2:end-1, 2:2:end) + qb_raw(2:2:end, 1:2:end-1) + qb_raw(2:2:end, 2:2:end) )./4;
	
	RGB_demosaic = bayer_demosaic(binning_raw, yp, xp, bayer_type, crop_rp, crop_bp);
	
end
