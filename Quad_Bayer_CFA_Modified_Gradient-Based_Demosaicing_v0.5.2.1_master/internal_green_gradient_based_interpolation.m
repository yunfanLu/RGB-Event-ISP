function [GM, Gsample, Other_colors_used, H_used, V_used, D_used, T_used] = internal_green_gradient_based_interpolation(m, n, raw, Matrix_A, Matrix_B, Matrix_E, Mx, My, crop_r, crop_b)

	%%%%%%%%%%%%%%% Sub-sampling Green %%%%%%%%%%%%%%%
	Gcfa = repmat([1 1 0 0; 1 1 0 0; 0 0 1 1; 0 0 1 1], [m,n]/4);
	Gsample = raw.*Gcfa;

	%%%%%%%%%%%%%%% Green pixels to be interpolated %%%%%%%%%%%%%%%
		GLTcfa = repmat([1 0 1 0; 0 0 0 0; 1 0 1 0; 0 0 0 0], [m,n]/4);
		GRTcfa = repmat([0 1 0 1; 0 0 0 0; 0 1 0 1; 0 0 0 0], [m,n]/4);
		GLBcfa = repmat([0 0 0 0; 1 0 1 0; 0 0 0 0; 1 0 1 0], [m,n]/4);
		GRBcfa = repmat([0 0 0 0; 0 1 0 1; 0 0 0 0; 0 1 0 1], [m,n]/4);
	
	%%%%%%%%%%%%%%% Gradient Processing I %%%%%%%%%%%%%%%
		[H_Lab, V_Lab, D_Lab, T_Lab] = gradient_pre_interpolation(raw, Gcfa, GLTcfa, GRTcfa, GLBcfa, GRBcfa);
		
		[H_new, V_new, D_new, T_new] = gradient_HVDT_1(H_Lab, V_Lab, D_Lab, T_Lab, Matrix_A, Matrix_B);
		
		[H_im, V_im, D_im, T_im] = gradient_HVDT_2(raw, Matrix_A, Matrix_B, GLTcfa, GRTcfa, GLBcfa, GRBcfa);

	%%%%%%%%%%%%%%% Gradient Processing II %%%%%%%%%%%%%%%
		H = conv2( min(H_new,H_im), Matrix_A, 'same');
		V = conv2( min(V_new,V_im), Matrix_A, 'same');
		D = conv2( min(D_new,D_im), Matrix_B, 'same');
		T = conv2( min(T_new,T_im), Matrix_B, 'same');

	clear H_new V_new D_new T_new H_im V_im D_im T_im;
	
		H = (GLTcfa+GLBcfa).*min(H,H(:,[2:end end])) + (GRTcfa+GRBcfa).*min(H,H(:,[1 1:end-1]));
		V = (GLTcfa+GRTcfa).*min(V,V([2:end end],:)) + (GLBcfa+GRBcfa).*min(V,V([1 1:end-1],:));
		D = (GRTcfa+GLBcfa).*D + GLTcfa.*min(D,D([2:end end],[2:end end])) + GRBcfa.*min(D,D([1 1:end-1],[1 1:end-1]));
		T = (GLTcfa+GRBcfa).*T + GRTcfa.*min(T,T([2:end end],[1 1:end-1])) + GLBcfa.*min(T,T([1 1:end-1],[2:end end]));
		
	%%%%%%%%%%%%%%% Downscale and Upscale %%%%%%%%%%%%%%%
		[Fx, Fy] = meshgrid(0.5:2:n+0.5-crop_r, 0.5:2:m+0.5-crop_b);
		Other_Lab = interp2(Fx, Fy, interp2(Mx, My, Gsample.*2, Fx, Fy, 'spline'), Mx, My, 'spline');
		
	%%%%%%%%%%%%%%% Gradient-Based interpolation II %%%%%%%%%%%%%%%
		[GM, Other_colors_used, H_used, V_used, D_used, T_used] = final_gradient_interpolation(Gsample, H_Lab, V_Lab, D_Lab, T_Lab, Other_Lab, H, V, D, T, Matrix_A, Matrix_B, Matrix_E, Gcfa);

end




function [H_Lab, V_Lab, D_Lab, T_Lab] = gradient_pre_interpolation(raw,Gcfa,GLTcfa,GRTcfa,GLBcfa,GRBcfa)

	%%%%%%%%%%%%%%% Gradient-Based interpolation I %%%%%%%%%%%%%%%
	H_Lab = raw.*Gcfa + (1-Gcfa).*( ...
		GLTcfa.*( raw(:, [1 1:end-1])*(2/3) + raw(:, [3:end end end])/3 ) + ...
		GRTcfa.*( raw(:, [1 1 1:end-2])/3  +  raw(:, [2:end end])*(2/3) ) + ...
		GLBcfa.*( raw(:, [1 1:end-1])*(2/3) + raw(:, [3:end end end])/3 ) + ...
		GRBcfa.*( raw(:, [1 1 1:end-2])/3  +  raw(:, [2:end end])*(2/3) ) );
	
	V_Lab = raw.*Gcfa + (1-Gcfa).*( ...
		GLTcfa.*( raw([1 1:end-1], :)*(2/3) + raw([3:end end end], :)/3 ) + ...
		GRTcfa.*( raw([1 1:end-1], :)*(2/3) + raw([3:end end end], :)/3 ) + ...
		GLBcfa.*( raw([1 1 1:end-2], :)/3  +  raw([2:end end], :)*(2/3) ) + ...
		GRBcfa.*( raw([1 1 1:end-2], :)/3  +  raw([2:end end], :)*(2/3) ) );

	D_Lab = raw.*Gcfa + (1-Gcfa).*( ...
		GLTcfa.*( raw([1 1:end-1], :)*0.375 + raw(:, [1 1:end-1])*0.375 + ...
				  raw([2:end end], [3:end end end])*0.125 + raw([3:end end end], [2:end end])*0.125 ) + ...
		GRTcfa.*( raw([1 1:end-1], [1 1:end-1])/2 + raw([2:end end], [2:end end])/2 ) + ...
		GLBcfa.*( raw([1 1:end-1], [1 1:end-1])/2 + raw([2:end end], [2:end end])/2 ) + ...
		GRBcfa.*( raw([2:end end], :)*0.375 + raw(:, [2:end end])*0.375 + ...
				  raw([1 1:end-1], [1 1 1:end-2])*0.125 + raw([1 1 1:end-2], [1 1:end-1])*0.125 ) );

	T_Lab = raw.*Gcfa + (1-Gcfa).*( ...
		GLTcfa.*( raw([2:end end], [1 1:end-1])/2 + raw([1 1:end-1], [2:end end])/2 ) + ...
		GRTcfa.*( raw([1 1:end-1], :)*0.375 + raw(:, [2:end end])*0.375 + ...
				  raw([2:end end], [1 1 1:end-2])*0.125 + raw([3:end end end], [1 1:end-1])*0.125 ) + ...
		GLBcfa.*( raw([2:end end], :)*0.375 + raw(:, [1 1:end-1])*0.375 + ...
				  raw([1 1:end-1], [3:end end end])*0.125 + raw([1 1 1:end-2], [2:end end])*0.125 ) + ...
		GRBcfa.*( raw([2:end end], [1 1:end-1])/2 + raw([1 1:end-1], [2:end end])/2 ) );
	
end




function [H_N, V_N, D_N, T_N] = gradient_HVDT_1(H_Lab, V_Lab, D_Lab, T_Lab, Matrix_A, Matrix_B)

	%%%%%%%%%%%%%%% Criterion I %%%%%%%%%%%%%%%
	H_new_O = gradient_HVDT_1_HV(H_Lab,'h');
	H_new_T = H_new_O([1 1:end-1], :);
	H_new_B = H_new_O([2:end end], :);
	H_new_L = H_new_O(:, [1 1:end-1]);
	H_new_R = H_new_O(:, [2:end end]);
	
	H_round = conv2( min( min( H_new_T, H_new_B), min( H_new_L, H_new_R) ), Matrix_A, 'same');

	clear H_new_O H_new_T H_new_B H_new_L H_new_R;

	V_new_O = gradient_HVDT_1_HV(V_Lab,'v');
	V_new_L = V_new_O(:, [1 1:end-1]);
	V_new_R = V_new_O(:, [2:end end]);
	V_new_T = V_new_O([1 1:end-1], :);
	V_new_B = V_new_O([2:end end], :);

	V_round = conv2( min( min( V_new_T, V_new_B), min( V_new_L, V_new_R) ), Matrix_A, 'same');
	
	clear V_new_O V_new_T V_new_B V_new_L V_new_R;
	
	D_new_O = gradient_HVDT_1_DT(D_Lab,1,'d');
	D_new_K = D_new_O([1 1:end-1], [2:end end]);
	D_new_J = D_new_O([2:end end], [1 1:end-1]);	
	D_new_E = D_new_O([1 1:end-1], [1 1:end-1]);
	D_new_V = D_new_O([2:end end], [2:end end]);

	D_round = conv2( min( min( min( D_new_K, D_new_J), min( D_new_E, D_new_V) ), D_new_O), Matrix_B, 'same');
	
	clear D_new_O D_new_K D_new_J D_new_E D_new_V;
	
	T_new_O = gradient_HVDT_1_DT(T_Lab,1,'t');
	T_new_E = T_new_O([1 1:end-1], [1 1:end-1]);
	T_new_V = T_new_O([2:end end], [2:end end]);
	T_new_K = T_new_O([1 1:end-1], [2:end end]);
	T_new_J = T_new_O([2:end end], [1 1:end-1]);	
	
	T_round = conv2( min( min( min( T_new_K, T_new_J), min( T_new_E, T_new_V) ), T_new_O), Matrix_B, 'same');
	
	clear T_new_O T_new_K T_new_J T_new_E T_new_V;
	
	%%%%%%%%%%%%%%% Criterion II %%%%%%%%%%%%%%%
	H_new = conv2( gradient_HVDT_1_HV(H_Lab,  'h' ), Matrix_A, 'same');
	V_new = conv2( gradient_HVDT_1_HV(V_Lab,  'v' ), Matrix_A, 'same');
	D_new = conv2( gradient_HVDT_1_DT(D_Lab,2,'d' ), Matrix_B, 'same');
	T_new = conv2( gradient_HVDT_1_DT(T_Lab,2,'t' ), Matrix_B, 'same');

	%%%%%%%%%%%%%%% Criterion Min-Max %%%%%%%%%%%%%%%
	H_N = conv2( max( H_round, H_new ) , Matrix_A, 'same');
	V_N = conv2( max( V_round, V_new ) , Matrix_A, 'same');
	D_N = conv2( max( D_round, D_new ) , Matrix_B, 'same');
	T_N = conv2( max( T_round, T_new ) , Matrix_B, 'same');
	
end

function HV_N = gradient_HVDT_1_HV(HV_Input, HV_axis)
	H_F = max( abs(( HV_Input(:, [1 1 1:end-2]) + HV_Input(:, [3:end end end]) )/2-HV_Input), abs(( HV_Input(:, [1 1:end-1]) + HV_Input(:, [2:end end]) )/2-HV_Input) );
	V_F = max( abs(( HV_Input([1 1 1:end-2], :) + HV_Input([3:end end end], :) )/2-HV_Input), abs(( HV_Input([1 1:end-1], :) + HV_Input([2:end end], :) )/2-HV_Input) );

	if HV_axis == 'h'
		HV_N = H_F-0.0256*(V_F>H_F).*(V_F.^(1/3));
	else
		HV_N = V_F-0.0256*(H_F>V_F).*(H_F.^(1/3));
	end
end

function DT_N = gradient_HVDT_1_DT(D_Input,pass,DT_axis)
	if pass == 1
		D_F = max( abs(( D_Input([1 1 1 1:end-3], [1 1 1 1:end-3]) + D_Input([4:end end end end], [4:end end end end]) )/2-D_Input), abs(( D_Input([1 1 1:end-2], [1 1 1:end-2]) + D_Input([3:end end end], [3:end end end]) )/2-D_Input) );
		T_F = max( abs(( D_Input([1 1 1 1:end-3], [4:end end end end]) + D_Input([4:end end end end], [1 1 1 1:end-3]) )/2-D_Input), abs(( D_Input([1 1 1:end-2], [3:end end end]) + D_Input([3:end end end], [1 1 1:end-2]) )/2-D_Input) );
	else 
		D_F = max( abs(( D_Input([1 1:end-1], [1 1:end-1]) + D_Input([2:end end], [2:end end]) )/2-D_Input), abs(( D_Input([1 1 1:end-2], [1 1 1:end-2]) + D_Input([3:end end end], [3:end end end]) )/2-D_Input) );
		T_F = max( abs(( D_Input([1 1:end-1], [2:end end]) + D_Input([2:end end], [1 1:end-1]) )/2-D_Input), abs(( D_Input([1 1 1:end-2], [3:end end end]) + D_Input([3:end end end], [1 1 1:end-2]) )/2-D_Input) );
	end

	if DT_axis == 'd'
		DT_N = D_F-0.023*(T_F>D_F).*(T_F.^(1/3));
	else
		DT_N = T_F-0.023*(D_F>T_F).*(D_F.^(1/3));
	end
end




function [H_im, V_im, D_im, T_im] = gradient_HVDT_2(raw, Matrix_A, Matrix_B, GLTcfa, GRTcfa, GLBcfa, GRBcfa)

	%%%%%%%%%%%%%%% Gradient I %%%%%%%%%%%%%%%
	H_old = conv2(abs(( raw(:, [1 1 1 1 1:end-4]) + raw(:, [5:end end end end end]) )/2-raw), Matrix_A, 'same');
	
	V_old = conv2(abs(( raw([1 1 1 1 1:end-4], :) + raw([5:end end end end end], :) )/2-raw), Matrix_A, 'same');
	
	D_old = conv2(abs(( raw([1 1 1 1 1:end-4], [1 1 1 1 1:end-4]) + raw([5:end end end end end], [5:end end end end end]) )/2-raw), Matrix_B, 'same');
	
	T_old = conv2(abs(( raw([1 1 1 1 1:end-4], [5:end end end end end]) + raw([5:end end end end end], [1 1 1 1 1:end-4]) )/2-raw), Matrix_B, 'same');
	
	%%%%%%%%%%%%%%% Gradient II %%%%%%%%%%%%%%%
	H_find = (GLTcfa+GLBcfa).*abs(( raw(:, [1 1 1 1:end-3]) + raw(:, [5:end end end end end])*(2/3) + raw(:, [2:end end])/3 )/2-raw) + ...
	    (GRTcfa+GRBcfa).*abs(( raw(:, [1 1 1 1 1:end-4])*(2/3) + raw(:, [1 1:end-1])/3 + raw(:, [4:end end end end]) )/2-raw);

	V_find = (GLTcfa+GRTcfa).*abs(( raw([1 1 1 1:end-3], :) + raw([5:end end end end end], :)*(2/3) + raw([2:end end], :)/3 )/2-raw) + ...
	    (GLBcfa+GRBcfa).*abs(( raw([1 1 1 1 1:end-4], :)*(2/3) + raw([1 1:end-1], :)/3 + raw([4:end end end end], :) )/2-raw);

	D_find = GLTcfa.*abs(( ...
			raw([1 1 1 1:end-3], [1 1 1 1:end-3]) + ...
			raw([5:end end end end end], [5:end end end end end])*(2/3) + ...
			raw([2:end end], [2:end end])/3 )/2-raw) + ...
		GRBcfa.*abs(( ...
			raw([1 1 1 1 1:end-4], [1 1 1 1 1:end-4])*(2/3) + ...
			raw([1 1:end-1], [1 1:end-1])/3 + ...
			raw([4:end end end end], [4:end end end end]) )/2-raw) + ...
		(GRTcfa+GLBcfa).*abs(( ...
			raw([1 1 1 1 1:end-4], [1 1 1 1 1:end-4]) + ...
			raw([5:end end end end end], [5:end end end end end]) )/2-raw);

	T_find = (GLTcfa+GRBcfa).*abs(( ...
			raw([1 1 1 1 1:end-4], [5:end end end end end]) + ...
			raw([5:end end end end end], [1 1 1 1 1:end-4]) )/2-raw) + ...
		GRTcfa.*abs(( ...
			raw([1 1 1 1:end-3], [4:end end end end]) + ...
			raw([5:end end end end end], [1 1 1 1 1:end-4])*(2/3) + ...
			raw([2:end end], [1 1:end-1])/3 )/2-raw) + ...
		GLBcfa.*abs(( ...
			raw([1 1 1 1 1:end-4], [5:end end end end end])*(2/3) + ...
			raw([1 1:end-1], [1 1:end-1])/3 + ...
			raw([4:end end end end], [1 1 1 1:end-3]) )/2-raw);
	
	%%%%%%%%%%%%%%% Gradient Max %%%%%%%%%%%%%%%
	H_im = conv2( max(H_old, H_find), Matrix_A,'same');
	V_im = conv2( max(V_old, V_find), Matrix_A,'same');
	D_im = conv2( max(D_old, D_find), Matrix_B,'same');
	T_im = conv2( max(T_old, T_find), Matrix_B,'same');
	
end




function [GM, Other_colors_used, H_used, V_used, D_used, T_used] = final_gradient_interpolation(Gsample, H_Lab, V_Lab, D_Lab, T_Lab, Other_Lab, H, V, D, T, Matrix_A, Matrix_B, Matrix_E, Gcfa)
		
	%%%%%%%%%%%%%%% Gradient useable I %%%%%%%%%%%%%%%
		H_used_C = (H<V).*(H<D).*(H<T);
		V_used_C = (V<H).*(V<D).*(V<T);
		D_used_C = (D<H).*(D<V).*(D<T);
		T_used_C = (T<H).*(T<V).*(T<D);
	
		HVC = abs( (abs(H-V)<=0.005).*H);
		DTC = abs( (abs(D-T)<=0.005).*D);
	
		Other_colors_used = conv2( ( H_used_C.*HVC + V_used_C.*HVC + D_used_C.*DTC + T_used_C.*DTC ).^0.125, Matrix_E, 'same');
	
		H_used = conv2( H_used_C.*(abs(H-V)>=0.0008), Matrix_E,'same');
		V_used = conv2( V_used_C.*(abs(H-V)>=0.0008), Matrix_E,'same');
		D_used = conv2( D_used_C.*(abs(D-T)>=0.0008), Matrix_E,'same');
		T_used = conv2( T_used_C.*(abs(D-T)>=0.0008), Matrix_E,'same');
	
		Other_used = (1 - H_used - V_used - D_used - T_used);
	
	%%%%%%%%%%%%%%% Gradient-Based interpolation II %%%%%%%%%%%%%%%
		GM = Gsample + (1-Gcfa).*( ...
				H_used.*H_Lab + ...
				V_used.*V_Lab + ...
				D_used.*D_Lab + ...
				T_used.*T_Lab + ...
				Other_used.*Other_Lab );

end