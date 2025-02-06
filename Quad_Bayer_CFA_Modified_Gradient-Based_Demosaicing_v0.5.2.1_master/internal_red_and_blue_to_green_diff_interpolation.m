function [R2F, B2F] = internal_red_and_blue_to_green_diff_interpolation(GM, raw, Mx, My, m, n, Matrix_C, Matrix_D, Matrix_F, Other_colors_used, H_used, V_used, D_used, T_used)

	%%%%%%%%%%%%%%% R/B Channel Grids %%%%%%%%%%%%%%%
	[Rx,Ry] = red_and_blue_channel_grids(m,n,'r');
	[Bx,By] = red_and_blue_channel_grids(m,n,'b');

	%%%%%%%%%%%%%%% CFA %%%%%%%%%%%%%%%
	[Gcfa, GRcfa, GBcfa, Rcfa, Bcfa, LTcfa, RTcfa, LBcfa, RBcfa] = CFA_produce(m,n);

	%%%%%%%%%%%%%%% Sub-sampling %%%%%%%%%%%%%%%
	Rsample = interp2(Mx, My, raw, Rx, Ry,'nearest');
	Bsample = interp2(Mx, My, raw, Bx, By,'nearest');

	%%%%%%%%%%%%%%% R'-G and B'-G %%%%%%%%%%%%%%%
	[R_All_Diff, B_All_Diff] = r_and_b_to_g_diff_produce(GM,Rsample,Bsample,Mx,My,Rx,Ry,Bx,By,Matrix_F,raw,Rcfa,Gcfa,Bcfa,GRcfa,GBcfa,LTcfa,RTcfa,LBcfa,RBcfa,H_used,V_used,D_used,T_used);

	% %%%%%%%%%%%%%%% Red / Blue Channel Processing %%%%%%%%%%%%%%%	
	R_Fix = interp2(Rx, Ry, sqrt(Rsample+0.49)-0.7, Mx, My, 'spline');
	B_Fix = interp2(Bx, By, sqrt(Bsample+0.49)-0.7, Mx, My, 'spline');
	
	R_Max = max( abs(GM + R_All_Diff), R_Fix );
	B_Max = max( abs(GM + B_All_Diff), B_Fix );
	
	% %%%%%%%%%%%%%%% Lightweight De-aliasing %%%%%%%%%%%%%%%
	Other_colors_used_R = conv2( R_Max, Matrix_C, 'same');
	Other_colors_used_B = conv2( B_Max, Matrix_C, 'same');
	
	% %%%%%%%%%%%%%%% Final Output %%%%%%%%%%%%%%%
	R2F = R_Max.*Rcfa + (1-Rcfa).*( R_Max.*(1-Other_colors_used) + Other_colors_used_R.*Other_colors_used );
	B2F = B_Max.*Bcfa + (1-Bcfa).*( B_Max.*(1-Other_colors_used) + Other_colors_used_B.*Other_colors_used );
		
end




function [Fx, Fy] = red_and_blue_channel_grids(m, n, color)

	%%%%%%%%%%%%%%% Red and Blue channel grids %%%%%%%%%%%%%%%
	if color == 'r'
		[ltx, lty] = meshgrid(3:4:n-1, 1:4:m-3);
		[rtx, rty] = meshgrid(4:4:n-0, 1:4:m-3);
		[lbx, lby] = meshgrid(3:4:n-1, 2:4:m-2);
		[rbx, rby] = meshgrid(4:4:n-0, 2:4:m-2);
	else
		[ltx, lty] = meshgrid(1:4:n-3, 3:4:m-1);
		[rtx, rty] = meshgrid(2:4:n-2, 3:4:m-1);
		[lbx, lby] = meshgrid(1:4:n-3, 4:4:m-0);
		[rbx, rby] = meshgrid(2:4:n-2, 4:4:m-0);
	end
	Fx = zeros(m/2, n/2);
	Fx(1:2:end-1, 1:2:end-1) = ltx;
	Fx(2:2:end-0, 1:2:end-1) = lbx;
	Fx(1:2:end-1, 2:2:end-0) = rtx;
	Fx(2:2:end-0, 2:2:end-0) = rbx;
	Fy = zeros(m/2, n/2);
	Fy(1:2:end-1, 1:2:end-1) = lty;
	Fy(2:2:end-0, 1:2:end-1) = lby;
	Fy(1:2:end-1, 2:2:end-0) = rty;
	Fy(2:2:end-0, 2:2:end-0) = rby;

end




function [Gcfa,GRcfa,GBcfa,Rcfa,Bcfa,LTcfa,RTcfa,LBcfa,RBcfa] = CFA_produce(m,n)

	GRcfa = repmat([1,1,0,0; 1,1,0,0; 0,0,0,0; 0,0,0,0], [m,n]/4);
	GBcfa = repmat([0,0,0,0; 0,0,0,0; 0,0,1,1; 0,0,1,1], [m,n]/4);
	Gcfa  = repmat([1 1 0 0; 1 1 0 0; 0 0 1 1; 0 0 1 1], [m,n]/4);
	Rcfa  = repmat([0 0 1 1; 0 0 1 1; 0 0 0 0; 0 0 0 0], [m,n]/4);
	Bcfa  = repmat([0 0 0 0; 0 0 0 0; 1 1 0 0; 1 1 0 0], [m,n]/4);
	LTcfa = repmat([1 0 1 0; 0 0 0 0; 1 0 1 0; 0 0 0 0], [m,n]/4);
	RTcfa = repmat([0 1 0 1; 0 0 0 0; 0 1 0 1; 0 0 0 0], [m,n]/4);
	LBcfa = repmat([0 0 0 0; 1 0 1 0; 0 0 0 0; 1 0 1 0], [m,n]/4);	
	RBcfa = repmat([0 0 0 0; 0 1 0 1; 0 0 0 0; 0 1 0 1], [m,n]/4);

end




function [R_All_Diff, B_All_Diff] = r_and_b_to_g_diff_produce(GM,Rsample,Bsample,Mx,My,Rx,Ry,Bx,By,Matrix_F,raw,Rcfa,Gcfa,Bcfa,GRcfa,GBcfa,LTcfa,RTcfa,LBcfa,RBcfa,H_used,V_used,D_used,T_used)

	%%%%%%%%%%%%%%% R'-G and B'-G interpolation I %%%%%%%%%%%%%%%
	R_diff = Rcfa.*(raw - GM);
	B_diff = Bcfa.*(raw - GM);
	
	R_Other_Lab = interp2(Rx, Ry, Rsample - interp2(Mx, My, GM, Rx, Ry, 'spline'), Mx, My, 'spline');
	B_Other_Lab = interp2(Bx, By, Bsample - interp2(Mx, My, GM, Bx, By, 'spline'), Mx, My, 'spline');
	
	R_RD_Lab = R_Other_Lab;
	B_RD_Lab = B_Other_Lab;
	
	R_H_Lab = R_Other_Lab;
	R_V_Lab = R_Other_Lab;
	B_H_Lab = B_Other_Lab;
	B_V_Lab = B_Other_Lab;
	
	%%%%%%%%%%%%%%% R'./G and B'./G Compare %%%%%%%%%%%%%%%
	R_RD = conv2( double((conv2(abs(R_Other_Lab + GM),Matrix_F,'same')./conv2(GM, Matrix_F,'same'))>=1.25), Matrix_F, 'same')>=1;
	B_RD = conv2( double((conv2(abs(B_Other_Lab + GM),Matrix_F,'same')./conv2(GM, Matrix_F,'same'))>=1.25), Matrix_F, 'same')>=1;
	
	%%%%%%%%%%%%%%% R'-G and B'-G interpolation II %%%%%%%%%%%%%%%
	R_Other_Lab = conv2( R_Other_Lab, Matrix_F, 'same');
	B_Other_Lab = conv2( B_Other_Lab, Matrix_F, 'same');
	
	[R_D_Lab, R_T_Lab] = red_or_blue_gradient_pre_interpolation(R_diff, Bcfa, GRcfa, GBcfa, LTcfa, RTcfa, LBcfa, RBcfa);
	[B_D_Lab, B_T_Lab] = red_or_blue_gradient_pre_interpolation(B_diff, Rcfa, GBcfa, GRcfa, LTcfa, RTcfa, LBcfa, RBcfa);
	
	%%%%%%%%%%%%%%% Gradient Processing %%%%%%%%%%%%%%%
	R_H_used = H_used.*GRcfa;
	R_V_used = V_used.*GBcfa;
	R_D_used = D_used.*(1-Rcfa);
	R_T_used = T_used.*(1-Rcfa);
	R_Other_used = 1 - R_H_used - R_V_used - R_D_used - R_T_used;

	B_H_used = H_used.*GBcfa;
	B_V_used = V_used.*GRcfa;
	B_D_used = D_used.*(1-Bcfa);
	B_T_used = T_used.*(1-Bcfa);
	B_Other_used = 1 - B_H_used - B_V_used - B_D_used - B_T_used;
	
	%%%%%%%%%%%%%%% All Diff Processing %%%%%%%%%%%%%%%
	R_All_Diff = R_diff + (1-Rcfa).*(R_RD.*R_RD_Lab + (1-R_RD).*(R_H_used.*R_H_Lab + R_V_used.*R_V_Lab + R_D_used.*R_D_Lab + R_T_used.*R_T_Lab + R_Other_used.*R_Other_Lab) );
	B_All_Diff = B_diff + (1-Bcfa).*(B_RD.*B_RD_Lab + (1-B_RD).*(B_H_used.*B_H_Lab + B_V_used.*B_V_Lab + B_D_used.*B_D_Lab + B_T_used.*B_T_Lab + B_Other_used.*B_Other_Lab) );
	
end




function [D_Lab, T_Lab] = red_or_blue_gradient_pre_interpolation(raw, Re_cfa, G_same_cfa, G_Re_cfa, LTcfa, RTcfa, LBcfa, RBcfa)
	%H_Lab = G_same_cfa.*( ...
	%	LTcfa.*( raw(:, [1 1:end-1])*(2/3) + raw(:, [3:end end end])/3 ) + ...
	%	LBcfa.*( raw(:, [1 1:end-1])*(2/3) + raw(:, [3:end end end])/3 ) + ...
	%	RTcfa.*( raw(:, [1 1 1:end-2])/3  +  raw(:, [2:end end])*(2/3) ) + ...
	%	RBcfa.*( raw(:, [1 1 1:end-2])/3  +  raw(:, [2:end end])*(2/3) ) );

	%V_Lab = G_Re_cfa.*( ...
	%	LTcfa.*( raw([1 1:end-1], :)*(2/3) + raw([3:end end end], :)/3 ) + ...
	%	RTcfa.*( raw([1 1:end-1], :)*(2/3) + raw([3:end end end], :)/3 ) + ...
	%	LBcfa.*( raw([1 1 1:end-2], :)/3  +  raw([2:end end], :)*(2/3) ) + ...
	%	RBcfa.*( raw([1 1 1:end-2], :)/3  +  raw([2:end end], :)*(2/3) ) );

	D_Lab = Re_cfa.*( ...
		LTcfa.*( raw([1 1:end-1], [1 1:end-1])*(2/3) + raw([3:end end end], [3:end end end])/3 ) + ...
		RTcfa.*( raw([1 1 1:end-2], [1 1 1:end-2])/2 + raw([3:end end end], [3:end end end])/2 ) + ...
		LBcfa.*( raw([1 1 1:end-2], [1 1 1:end-2])/2 + raw([3:end end end], [3:end end end])/2 ) + ...
		RBcfa.*( raw([1 1 1:end-2], [1 1 1:end-2])/3 + raw([2:end end], [2:end end])*(2/3)   ) ) + ...
			  G_same_cfa.*( ...
		LTcfa.*( raw(:, [1 1:end-1])*0.4375               + raw([1 1 1 1:end-3], [1 1 1:end-2])*0.1875 + ...
				 raw([2:end end], [3:end end end])*0.3125 + raw([5:end end end end end], [4:end end end end])*0.0625 ) + ...
		LBcfa.*( raw([1 1:end-1], [1 1:end-1])*0.75       + raw([4:end end end end], [4:end end end end])/4 )          + ...
		RTcfa.*( raw([1 1 1 1:end-3], [1 1 1 1:end-3])/4  + raw([2:end end], [2:end end])*0.75 )                       + ...
		RBcfa.*( raw(:, [2:end end])*0.4375               + raw([4:end end end end], [3:end end end])*0.1875 + ...
				 raw([1 1:end-1], [1 1 1:end-2])*0.3125   + raw([1 1 1 1 1:end-4], [1 1 1 1:end-3])*0.0625 )           ) + ...
			  G_Re_cfa.*( ...
		LTcfa.*( raw([1 1:end-1], :)*0.4375               + raw([1 1 1:end-2], [1 1 1 1:end-3])*0.1875 + ...
				 raw([3:end end end], [2:end end])*0.3125 + raw([4:end end end end], [5:end end end end end])*0.0625 ) + ...
		RTcfa.*( raw([1 1:end-1], [1 1:end-1])*0.75       + raw([4:end end end end], [4:end end end end])/4 )          + ...
		LBcfa.*( raw([1 1 1 1:end-3], [1 1 1 1:end-3])/4  + raw([2:end end], [2:end end])*0.75 )                       + ...
		RBcfa.*( raw([2:end end], :)*0.4375               + raw([3:end end end], [4:end end end end])*0.1875 + ...
				 raw([1 1 1:end-2], [1 1:end-1])*0.3125   + raw([1 1 1 1:end-3], [1 1 1 1 1:end-4])*0.0625 )           );

	T_Lab = Re_cfa.*( ...
		LTcfa.*( raw([1 1 1:end-2], [3:end end end])/2 + raw([3:end end end], [1 1 1:end-2])/2   ) + ...
		RTcfa.*( raw([1 1:end-1], [2:end end])*(2/3)   + raw([3:end end end], [1 1 1:end-2])/3   ) + ...
		LBcfa.*( raw([1 1 1:end-2], [3:end end end])/3 + raw([2:end end], [1 1:end-1])*(2/3)     ) + ...
		RBcfa.*( raw([1 1 1:end-2], [3:end end end])/2 + raw([3:end end end], [1 1 1:end-2])/2 ) ) + ...
			  G_same_cfa.*( ...
		LTcfa.*( raw([2:end end], [1 1:end-1])*0.75          + raw([1 1 1 1:end-3], [4:end end end end])/4 )          + ...
		RTcfa.*( raw(:, [2:end end])*0.4375                  + raw([1 1 1 1:end-3], [3:end end end])*0.1875 + ...
				 raw([2:end end], [1 1 1:end-2])*0.3125      + raw([5:end end end end end], [1 1 1 1:end-3])*0.0625 ) + ...
		LBcfa.*( raw(:, [1 1:end-1])*0.4375                  + raw([4:end end end end], [1 1 1:end-2])*0.1875 + ...
				 raw([1 1:end-1], [3:end end end])*0.3125    + raw([1 1 1 1 1:end-4], [4:end end end end])*0.0625 )   + ...
		RBcfa.*( raw([4:end end end end], [1 1 1 1:end-3])/4 + raw([1 1:end-1], [2:end end])*0.75 )                   ) + ...
			  G_Re_cfa.*( ...
		RBcfa.*( raw([2:end end], [1 1:end-1])*0.75  + raw([1 1 1 1:end-3], [4:end end end end])/4 )                  + ...
		LBcfa.*( raw([2:end end], :)*0.4375                  + raw([3:end end end], [1 1 1 1:end-3])*0.1875 + ...
				 raw([1 1 1:end-2], [2:end end])*0.3125      + raw([1 1 1 1:end-3], [5:end end end end end])*0.0625 ) + ...
		RTcfa.*( raw([1 1:end-1], :)*0.4375                  + raw([1 1 1:end-2], [4:end end end end])*0.1875 + ...
				 raw([3:end end end], [1 1:end-1])*0.3125    + raw([4:end end end end], [1 1 1 1 1:end-4])*0.0625 )   + ...
		LTcfa.*( raw([4:end end end end], [1 1 1 1:end-3])/4 + raw([1 1:end-1], [2:end end])*0.75  )                  );
		
end