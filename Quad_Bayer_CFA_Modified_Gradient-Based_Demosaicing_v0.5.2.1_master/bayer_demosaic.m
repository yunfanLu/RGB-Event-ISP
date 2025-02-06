function RGB_demosaic = bayer_demosaic(bayer_raw, yp, xp, bayer_type, crop_rp, crop_bp)
	%%%%%%%%%%%%%%% User Guide %%%%%%%%%%%%%%%
	% RGB_demosaic:RGB image output
	% bayer_raw:   Bayer RAW Image Input, must be double type.
	% y/x:         Height and width of RAW image
	% bayer_type:  Bayer CFA type, only the following modes are supported：
	%             'rggb'
	%             'bggr'
	%             'gbrg'
	%             'grbg' (default)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%
	bayer_type = lower(bayer_type);
	Matrix_A = [2,1,2;1,4,1;2,1,2]/16;
	Matrix_B = [1,2,1;2,4,2;1,2,1]/16;
	
	%%%%%%%%%%%%%%% Selects the decoding mode that produces the height and width of the image %%%%%%%%%%%%%%%
	%%%%%GRBG mode decoding is used. The rest of the modes are decoded by shifting to GRBG mode.
	switch bayer_type

		case 'rggb'
		raw(:, 2:xp+1) = bayer_raw;
		raw(yp, xp+2) = 0;
		m = yp;
		n = xp+2;
		
		case 'bggr'
		raw(2:yp+1, :) = bayer_raw;
		raw(yp+2, xp) = 0;
		m = yp+2;
		n = xp;
		
		case 'gbrg'
		raw(2:yp+1, 2:xp+1) = bayer_raw;
		raw(yp+2, xp+2) = 0;
		m = yp+2;
		n = xp+2;
		
		otherwise
		raw = bayer_raw;
		m = yp;
		n = xp;
	
	end

	%%%%%%%%%%%%%%% Space to process image %%%%%%%%%%%%%%%
	[Mx, My] = meshgrid(1:n, 1:m);

	%%%%%%%%%%%%%%% Red channel grids %%%%%%%%%%%%%%%
	[Rx, Ry] = meshgrid(2:2:n, 1:2:m-1);

	%%%%%%%%%%%%%%% Blue channel grids %%%%%%%%%%%%%%%
	[Bx, By] = meshgrid(1:2:n-1, 2:2:m);
	
	%%%%%%%%%%%%%%% G CFA %%%%%%%%%%%%%%%
	GRcfa = repmat([1 0; 0 0], [m,n]/2);
	GBcfa = repmat([0 0; 0 1], [m,n]/2);
	Gpicfa = repmat([0 1; 1 0], [m,n]/2);
	Rcfa = repmat([0 1; 0 0], [m,n]/2);
	Bcfa = repmat([0 0; 1 0], [m,n]/2);

	%%%%%%%%%%%%%%% Sub-sampling %%%%%%%%%%%%%%%
	G_sample = raw.*(GRcfa+GBcfa);
	R_sample = raw.*Rcfa;
	B_sample = raw.*Bcfa;

	% Green %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%%%%%%%%%%%%%%% Gradient-Based interpolation I %%%%%%%%%%%%%%%
	Other_Lab = G_sample + ( G_sample(:, [1 1:end-1]) + G_sample(:, [2:end end]) + G_sample([1 1:end-1], :) + G_sample([2:end end], :) )/4;
	H_Lab = G_sample + ( G_sample(:, [1 1:end-1]) + G_sample(:, [2:end end]) )/2;
	V_Lab = G_sample + ( G_sample([1 1:end-1], :) + G_sample([2:end end], :) )/2;
	D_Lab = ( Other_Lab([1 1:end-1], [1 1:end-1]) + Other_Lab + Other_Lab([2:end end], [2:end end]) )/3;
	T_Lab = ( Other_Lab([1 1:end-1], [2:end end]) + Other_Lab + Other_Lab([2:end end], [1 1:end-1]) )/3;

	H_new = conv2( gradient_HV(H_Lab, 'h') , Matrix_A, 'same');
	V_new = conv2( gradient_HV(V_Lab, 'v') , Matrix_A, 'same');	
	D_new = conv2( gradient_DT(D_Lab, 'd') , Matrix_B, 'same');
	T_new = conv2( gradient_DT(T_Lab, 't') , Matrix_B, 'same');	
	
	%%%%%%%%%%%%%%% Generating gradient %%%%%%%%%%%%%%%
	H_find = conv2( abs( ( raw(:, [1 1 1:end-2]) + raw(:, [3:end end end]) )./2 - raw ), Matrix_A, 'same');
	V_find = conv2( abs( ( raw([1 1 1:end-2], :) + raw([3:end end end], :) )./2 - raw ), Matrix_A, 'same');
	D_find = conv2( abs( ( raw([1 1 1:end-2], [1 1 1:end-2]) + raw([3:end end end], [3:end end end]) )./2 - raw ), Matrix_B, 'same');
	T_find = conv2( abs( ( raw([1 1 1:end-2], [3:end end end]) + raw([3:end end end], [1 1 1:end-2]) )./2 - raw ), Matrix_B, 'same');
	
	H = conv2( max( H_new, H_find), Matrix_A, 'same');
	V = conv2( max( V_new, V_find), Matrix_A, 'same');
	D = conv2( max( D_new, D_find), Matrix_B, 'same');
	T = conv2( max( T_new, T_find), Matrix_B, 'same');
	
	clear H_new V_new D_new T_new H_find V_find D_find T_find;

	%%%%%%%%%%%%%%% Gradient useable %%%%%%%%%%%%%%%
	G_H_used = (H<V).*(abs(H-V)>0.00005);
	G_V_used = (V<H).*(abs(H-V)>0.00005);
	H_used = (H<V).*(H<D).*(H<T).*(abs(H-V)>0.0001) + (D==T).*(D<H).*(H<V).*(abs(H-V)>0.0001);
	V_used = (V<H).*(V<D).*(V<T).*(abs(H-V)>0.0001) + (D==T).*(D<V).*(V<H).*(abs(H-V)>0.0001);
	D_used = (D<T).*(D<H).*(D<V).*(abs(D-T)>0.0001) + (H==V).*(H<D).*(D<T).*(abs(D-T)>0.0001);
	T_used = (T<D).*(T<H).*(T<V).*(abs(D-T)>0.0001) + (H==V).*(H<T).*(T<D).*(abs(D-T)>0.0001);
	Other_used = 1 - G_H_used - G_V_used;
	
	clear H V D T;
	%%%%%%%%%%%%%%% Gradient-Based interpolation II %%%%%%%%%%%%%%%
	G2F = G_sample + Gpicfa.*( ...
		G_H_used.*H_Lab + ...
		G_V_used.*V_Lab + ...
		Other_used.*Other_Lab );
	
	clear G_sample G_H_used G_V_used Other_used Other_Lab T_Lab D_Lab V_Lab H_Lab Gpicfa;
	
	% Red and Blue %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%%%%%%%%%%%%%%% R'-G and B'-G in H and V %%%%%%%%%%%%%%%
	R_Diff = (R_sample - G2F).*Rcfa;
	B_Diff = (B_sample - G2F).*Bcfa;
	
	R_H_used = H_used.*GRcfa;
	R_V_used = V_used.*GBcfa;
	R_D_used = D_used.*Bcfa;
	R_T_used = T_used.*Bcfa;
	R_Other_used = (1 - R_H_used - R_V_used - R_D_used - R_T_used).*(1-Rcfa);
	
	R_H_Lab = GRcfa.*conv2(R_Diff, [1,0,1]/2, 'same');
	R_V_Lab = GBcfa.*conv2(R_Diff, [1;0;1]/2, 'same');
	R_D_Lab = Bcfa.*conv2(R_Diff, [1,0,0; 0,0,0; 0,0,1]/2, 'same');
	R_T_Lab = Bcfa.*conv2(R_Diff, [0,0,1; 0,0,0; 1,0,0]/2, 'same');
	
	B_H_used = H_used.*GBcfa;
	B_V_used = V_used.*GRcfa;
	B_D_used = D_used.*Rcfa;
	B_T_used = T_used.*Rcfa;
	B_Other_used = (1 - B_H_used - B_V_used - B_D_used - B_T_used).*(1-Bcfa);
	
	B_H_Lab = GBcfa.*conv2(B_Diff, [1,0,1]/2, 'same');
	B_V_Lab = GRcfa.*conv2(B_Diff, [1;0;1]/2, 'same');
	B_D_Lab = Rcfa.*conv2(B_Diff, [1,0,0; 0,0,0; 0,0,1]/2, 'same');	
	B_T_Lab = Rcfa.*conv2(B_Diff, [0,0,1; 0,0,0; 1,0,0]/2, 'same');	
	
	%%%%%%%%%%%%%%% Sub-sampling %%%%%%%%%%%%%%%
	Rsample = interp2(Mx, My, raw, Rx, Ry,'nearest');
	Bsample = interp2(Mx, My, raw, Bx, By,'nearest');
	
	%%%%%%%%%%%%%%% R'-G and B'-G in Green Diff %%%%%%%%%%%%%%%
	G_Rg_G_Diff = interp2(Rx, Ry, interp2(Mx, My, G2F, Rx, Ry, 'spline'), Mx, My, 'linear');
	G_Bg_G_Diff = interp2(Bx, By, interp2(Mx, My, G2F, Bx, By, 'spline'), Mx, My, 'linear');
	
	%%%%%%%%%%%%%%% R'-G and B'-G in Others %%%%%%%%%%%%%%%
	Rg_Diff = interp2(Rx, Ry, ( Rsample - interp2(Mx, My, G2F, Rx, Ry, 'spline') ), Mx, My, 'linear');
	Bg_Diff = interp2(Bx, By, ( Bsample - interp2(Mx, My, G2F, Bx, By, 'spline') ), Mx, My, 'linear');
	
	R_Other_Lab = Color_Dff_Find_Back(G2F, G_Rg_G_Diff, Rg_Diff);
	B_Other_Lab = Color_Dff_Find_Back(G2F, G_Bg_G_Diff, Bg_Diff);
	
	R_Other_Lab(1,:)   = Rg_Diff(1,:);
	R_Other_Lab(end,:) = Rg_Diff(end,:);
	R_Other_Lab(:,1)   = Rg_Diff(:,1);
	R_Other_Lab(:,end) = Rg_Diff(:,end);	
	B_Other_Lab(1,:)   = Bg_Diff(1,:);
	B_Other_Lab(end,:) = Bg_Diff(end,:);
	B_Other_Lab(:,1)   = Bg_Diff(:,1);
	B_Other_Lab(:,end) = Bg_Diff(:,end);	
	
	%%%%%%%%%%%%%%% Red / Blue Channel I %%%%%%%%%%%%%%%	
	R_All = abs(G2F + R_Diff + 0.5.*(R_H_used.*R_H_Lab + R_V_used.*R_V_Lab + R_D_used.*R_D_Lab + R_T_used.*R_T_Lab) + (R_Other_used + 0.5.*(R_H_used+R_V_used+R_D_used+R_T_used) ).*R_Other_Lab);
	B_All = abs(G2F + B_Diff + 0.5.*(B_H_used.*B_H_Lab + B_V_used.*B_V_Lab + B_D_used.*B_D_Lab + B_T_used.*B_T_Lab) + (B_Other_used + 0.5.*(B_H_used+B_V_used+B_D_used+B_T_used) ).*B_Other_Lab);
	
	clear R_Diff B_Diff Rg_Diff Bg_Diff R_H_used B_H_used R_H_Lab B_H_Lab R_V_used B_V_used R_V_Lab B_V_Lab R_D_used B_D_used R_D_Lab B_D_Lab R_T_used B_T_used R_T_Lab B_T_Lab R_Other_used B_Other_used R_Other_Lab B_Other_Lab G_Rg_G_Diff G_Bg_G_Diff;
	
	%%%%%%%%%%%%%%% Red / Blue Channel II %%%%%%%%%%%%%%%
	R2F = max( R_All, interp2(Rx, Ry, sqrt(Rsample+0.49)-0.7, Mx, My, 'linear') );
	B2F = max( B_All, interp2(Bx, By, sqrt(Bsample+0.49)-0.7, Mx, My, 'linear') );

	clear Rsample Bsample;

	%%%%%%%%%%%%%%% RGB Merge %%%%%%%%%%%%%%%
	img(:, :, 1) = R2F(1:end-crop_bp, 1:end-crop_rp);
	img(:, :, 2) = G2F(1:end-crop_bp, 1:end-crop_rp);
	img(:, :, 3) = B2F(1:end-crop_bp, 1:end-crop_rp);
	
	%%%%%%%%%%%%%%% Crop and Output %%%%%%%%%%%%%%%
	switch bayer_type
	
		case 'rggb'
		RGB_demosaic = img(:, 2:end-1, :);
		
		case 'bggr'
		RGB_demosaic = img(2:end-1, :, :);
		
		case 'gbrg'
		RGB_demosaic = img(2:end-1, 2:end-1, :);
		
		otherwise
		RGB_demosaic = img;
	
	end

end

function HV_N = gradient_HV(HV_Input, HV_axis)
	H_F = max( abs(( HV_Input(:, [1 1 1:end-2]) + HV_Input(:, [3:end end end]) )/2-HV_Input), abs(( HV_Input(:, [1 1:end-1]) + HV_Input(:, [2:end end]) )/2-HV_Input) );
	V_F = max( abs(( HV_Input([1 1 1:end-2], :) + HV_Input([3:end end end], :) )/2-HV_Input), abs(( HV_Input([1 1:end-1], :) + HV_Input([2:end end], :) )/2-HV_Input) );

	if HV_axis == 'h'
		HV_N = H_F-0.0256*(V_F>H_F).*(V_F.^(1/3));
	else
		HV_N = V_F-0.0256*(H_F>V_F).*(H_F.^(1/3));
	end
end

function DT_N = gradient_DT(DT_Input, DT_axis)
	D_F = max( abs(( DT_Input([1 1:end-1], [1 1:end-1]) + DT_Input([2:end end], [2:end end]) )/2-DT_Input), abs(( DT_Input([1 1 1:end-2], [1 1 1:end-2]) + DT_Input([3:end end end], [3:end end end]) )/2-DT_Input) );
	T_F = max( abs(( DT_Input([1 1:end-1], [2:end end]) + DT_Input([2:end end], [1 1:end-1]) )/2-DT_Input), abs(( DT_Input([1 1 1:end-2], [3:end end end]) + DT_Input([3:end end end], [1 1 1:end-2]) )/2-DT_Input) );

	if DT_axis == 'd'
		DT_N = D_F-0.023*(T_F>D_F).*(T_F.^(1/3));
	else
		DT_N = T_F-0.023*(D_F>T_F).*(D_F.^(1/3));
	end
end

function Color_Output = Color_Dff_Find_Back(Green_Org, Green_Processed, Color_Input)
	Color_Sum =((Green_Org - Green_Processed) + Color_Input).*4;
	Color_Sum = (Green_Org - conv2(Green_Processed, [1,0,0; 0,0,0; 0,0,0], 'same')) + conv2(Color_Input, [1,0,0; 0,0,0; 0,0,0], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [0,0,1; 0,0,0; 0,0,0], 'same')) + conv2(Color_Input, [0,0,1; 0,0,0; 0,0,0], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [0,0,0; 0,0,0; 1,0,0], 'same')) + conv2(Color_Input, [0,0,0; 0,0,0; 1,0,0], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [0,0,0; 0,0,0; 0,0,1], 'same')) + conv2(Color_Input, [0,0,0; 0,0,0; 0,0,1], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [1; 0; 0], 'same')) + conv2(Color_Input, [1; 0; 0], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [0; 0; 1], 'same')) + conv2(Color_Input, [0; 0; 1], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [1, 0, 0], 'same')) + conv2(Color_Input, [1, 0, 0], 'same') + Color_Sum;
	Color_Sum = (Green_Org - conv2(Green_Processed, [0, 0, 1], 'same')) + conv2(Color_Input, [0, 0, 1], 'same') + Color_Sum;
    
	Color_Sum = Color_Sum./12;
    
    Color_Used = ((Color_Sum./Color_Input)<=1.12).*((Color_Sum./Color_Input)>=0.9);
    
    Color_Output = Color_Used.*Color_Sum + (1-Color_Used).*Color_Input;
end