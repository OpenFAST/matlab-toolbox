function [alpha0,alpha1,alpha2,C_nalpha,Cn1,Cn2,Cd0,Cm0] = WritePolarAD15(PolarIn,filename_out,Label,Re)
% Writes a polar matrix to a AeroDyn15 File format
% 
% INPUTS:
%   PolarIn: A polar matrix nx4, alpha, Cl, Cd, Cm
%
% OPTIONAL INPUTS:
%   filename_out: Name of aerodyn output file, if empty or not provided, no file is written
%   Re          : Reynolds number in Million! if not provided 1 Million  is used
%
% OUTPUTS:
%   alpha0, Cd0, Cm0: values at zero lift 
% 
%  09/06/2016 S. Guntur (NWTC/NREL)
%  08/11/2018 E. Branlard (NWTC/NREL), small code clean-up (more to do), and speed up of IO 

% --- Optional arguments
if ~exist('filename_out','var'); filename_out=[]; end
if ~exist('Label','var'); Label=''; end
if ~exist('Re','var'); Re=1; end

% --- Safety checks
if size(PolarIn,2)~=4   ; error('Polar should have 4 colums for alpha Cl Cd Cm') ; end ; 
if PolarIn(1,1)~=-180    ; error('FAST requires first alpha value to be -180')     ; end
if PolarIn(end,1)~=180 ; error('FAST requires last alpha value to be 180')     ; end
if ~all(PolarIn(1,2:end)==PolarIn(end,2:end))
    warning('First and last polar data (i.e. 180 and -180) do not match. Forcing the last one to equal the first');
    PolarIn(end,2:end)= PolarIn(1,2:end);
end


% --- Determining airfoil characteristic parameters
res = PolarIn;
nAlpha = size(res,1);

nUniqueCl=length(unique(res(:,2)));
nUniqueCd=length(unique(res(:,3)));
nUniqueCm=length(unique(res(:,4)));
if nUniqueCl==1 && nUniqueCd==1 && nUniqueCm==1
    fprintf(2,'[WARN] all values unique, likely a cylinder.\n')
    alpha0 = 0;
    Cd0    = res(1,3);
    Cm0    = res(1,4);
    alpha1=alpha0;
    alpha2=alpha0;
    Cn1=0;
    Cn2=0;
    C_nalpha =0;

elseif nAlpha==3
    fprintf(2,'[WARN] 3 points, likely a cylinder.\n')
    zeroind = find(abs(res(:,1))==min(abs(res(:,1))));
    alpha0 = interp1(res(zeroind-1:zeroind+1 ,2),res(zeroind-1:zeroind+1 ,1),0   ,'linear','extrap');
    Cd0    = interp1(res(zeroind-1:zeroind+1,1),res(zeroind-1:zeroind+1,3),alpha0,'linear','extrap');
    Cm0    = interp1(res(zeroind-1:zeroind+1,1),res(zeroind-1:zeroind+1,4),alpha0,'linear','extrap');
    alpha1=alpha0;
    alpha2=alpha0;
    Cn1=0;
    Cn2=0;
    C_nalpha =0;
elseif nAlpha>=31
    zeroind = find(abs(res(:,1))==min(abs(res(:,1))));
    alpha0 = interp1(res(zeroind-5:zeroind+5 ,2),res(zeroind-5:zeroind+5 ,1),0     ,'linear','extrap');
    Cd0    = interp1(res(zeroind-15:zeroind+5,1),res(zeroind-15:zeroind+5,3),alpha0,'linear','extrap');
    Cm0    = interp1(res(zeroind-15:zeroind+5,1),res(zeroind-15:zeroind+5,4),alpha0,'linear','extrap');
    CN = res(:,2).*cosd ( res(:,1) ) + ( res(:,3) - Cd0).*sind ( res(:,1) );
    B = diff(CN);
    Loc = find(B(2:end)<0 & B(1:(end-1))>0)+1;
    Cn1 = CN(Loc(find(Loc>zeroind,1)));
    B = diff(-CN);
    Loc = find(B(2:end)<0 & B(1:(end-1))>0)+1;
    temp = Loc(Loc<zeroind);
    Cn2 = CN(temp(end));

    C_nalpha = 180/pi*(CN(zeroind+1) - CN(zeroind-1))./(res(zeroind+1,1)-res(zeroind-1,1));
    CNaf = pi/180*C_nalpha.*( res(:,1) - alpha0 )*((1+sqrt(0.7))/2)^2;
    [x0,~,~,~] = intersections(res(:,1),CNaf,res(:,1),CN);
    %disp(size(x0))
    if size(x0,1)==3
       alpha1=x0(3);
       alpha2=x0(1);
    else
      alpha2=-abs(x0(1));
      alpha1=abs(x0(1));
    end
else
    error('Number of datapoints too low, this script was not intended for that. TODO')
end



if isempty(filename_out)
    return
end

% --- Writing polar to file
fid = fopen(filename_out,'w');
fprintf(fid,'! ------------ AirfoilInfo v1.01.x Input File ----------------------------------.\n');
fprintf(fid,'! %s\n',Label);
fprintf(fid,'! \n');
fprintf(fid,'! Note that this file uses Marshall Buhl''s new input file processing; start all comment lines with !\n');
fprintf(fid,'! ------------------------------------------------------------------------------\n');
fprintf(fid,'"DEFAULT"     InterpOrd         ! Interpolation order to use for quasi-steady table lookup {1=linear; 3=cubic spline; "default"} [default=3] \n');
fprintf(fid,'1.0         NonDimArea        ! The non-dimensional area of the airfoil (area/chord^2) (set to 1.0 if unsure or unneeded)\n');
% fprintf(fid,['@"',coords_filename,'"         NumCoords         ! The number of coordinates in the airfoil shape file.  Set to zero if coordinates not included.\n']);
fprintf(fid,'0          NumCoords         ! The number of coordinates in the airfoil shape file.  Set to zero if coordinates not included.\n');
fprintf(fid,'1           NumTabs           ! Number of airfoil tables in this file.  Each table must have lines for Re and Ctrl.\n');
fprintf(fid,'! ------------------------------------------------------------------------------\n');
fprintf(fid,'! data for table 1\n');
fprintf(fid,'! ------------------------------------------------------------------------------\n');
fprintf(fid,'%f        Re                ! Reynolds number in millions\n',Re);
fprintf(fid,'0         Ctrl              ! Control setting (must be 0 for current AirfoilInfo)\n');
fprintf(fid,'True        InclUAdata        ! Is unsteady aerodynamics data included in this table? If TRUE, then include 30 UA coefficients below this line\n');
fprintf(fid,'!........................................\n');
fprintf(fid,[num2str(alpha0,'%1.4f'),'  alpha0            ! 0-lift angle of attack, depends on airfoil.\n']);
fprintf(fid,[num2str(alpha1,'%1.4f'),'  alpha1            ! Angle of attack at f=0.7, (approximately the stall angle) for AOA>alpha0. (deg)\n']);
fprintf(fid,[num2str(alpha2,'%1.4f'),'  alpha2            ! Angle of attack at f=0.7, (approximately the stall angle) for AOA<alpha0. (deg)\n']);
fprintf(fid,'1        eta_e             ! Recovery factor in the range [0.85 - 0.95] used only for UAMOD=1, it is set to 1 in the code when flookup=True.\n');
fprintf(fid,[num2str(C_nalpha,'%1.4f'),'   C_nalpha          ! Slope of the 2D normal force coefficient curve. (1/rad)\n']);
fprintf(fid,'default  T_f0              ! Initial value of the time constant associated with Df in the expression of Df and f''''. [default = 3]\n');
fprintf(fid,'default  T_V0              ! Initial value of the time constant associated with the vortex lift decay process; it is used in the expression of Cvn. It depends on Re,M, and airfoil class. Default value= 6.\n');
fprintf(fid,'default  T_p               ! Boundary-layer,leading edge pressure gradient time constant in the expression of Dp. It should be tuned based on airfoil experimental data. Default =1.7.\n');
fprintf(fid,'default  T_VL              ! Initial value of the time constant associated with the vortex advection process; it represents the non-dimensional time in semi-chords, needed for a vortex to travel from LE to trailing edge (TE); it is used in the expression of Cvn. It depends on Re, M (weakly), and airfoil. [valid range = [6; 13]; default value= 11]\n');
fprintf(fid,'default  b1                ! Constant in the expression of phi_alpha^c and phi_q^c. This value is relatively insensitive for thin airfoils, but may be different for turbine airfoils.\n');
fprintf(fid,'default  b2                ! Constant in the expression of phi_alpha^c and phi_q^c. This value is relatively insensitive for thin airfoils, but may be different for turbine airfoils.\n');
fprintf(fid,'default  b5                ! Constant in the expression of K''''''_q,Cm_q^nc, and k_m,q. [from  experimental results, defaults to 5]\n');
fprintf(fid,'default  A1                ! Constant in the expression of phi_alpha^c and phi_q^c. This value is relatively insensitive for thin airfoils, but may be different for turbine airfoils.\n');
fprintf(fid,'default  A2                ! Constant in the expression of phi_alpha^c and phi_q^c. This value is relatively insensitive for thin airfoils, but may be different for turbine airfoils.\n');
fprintf(fid,'default  A5                ! Constant in the expression of K''''''_q,Cm_q^nc, and k_m,q. [from  experimental results, defaults to 1]\n');
fprintf(fid,'0        S1                ! Constant in the f curve best-fit for alpha0<=AOA<=alpha1;by definition it depends on the airfoil. [ignored if UAMod<>1]\n');
fprintf(fid,'0        S2                ! Constant in the f curve best-fit for         AOA>alpha1;by definition it depends on the airfoil. [ignored if UAMod<>1]\n');
fprintf(fid,'0        S3                ! Constant in the f curve best-fit for alpha2<=AOA<alpha0;by definition it depends on the airfoil. [ignored if UAMod<>1]\n');
fprintf(fid,'0        S4                ! Constant in the f curve best-fit for         AOA<alpha2;by definition it depends on the airfoil. [ignored if UAMod<>1]\n');
fprintf(fid,[num2str(Cn1,'%1.4f'),'  Cn1               ! Critical value of C0n at leading edge separation. It should be extracted from airfoil data at a given Mach and Reynolds number. It can be calculated from the static value of Cn at either the break in the pitching moment or the loss of chord force at the onset of stall. It is close to the condition of maximum lift of the airfoil at low Mach numbers.\n']);
fprintf(fid,[num2str(Cn2,'%1.4f'),'  Cn2               ! As Cn1 for negative AOAs.\n']);
fprintf(fid,'default  St_sh             ! Strouhal''s shedding frequency constant. [default = 0.19]\n');
fprintf(fid,[num2str(Cd0,'%1.4f'),'  Cd0               ! 2D drag coefficient value at 0-lift.\n']);
fprintf(fid,[num2str(Cm0,'%1.4f'),'  Cm0               ! 2D pitching moment coefficient about 1/4-chord location, at 0-lift, positive if nose up. [If the aerodynamics coefficients table does not include a column for Cm, this needs to be set to 0.0]\n']);
fprintf(fid,'0        k0                ! Constant in the \\hat(x)_cp curve best-fit; = (\\hat(x)_AC-0.25). [ignored if UAMod<>1]\n');
fprintf(fid,'0        k1                ! Constant in the \\hat(x)_cp curve best-fit. [ignored if UAMod<>1]\n');
fprintf(fid,'0        k2                ! Constant in the \\hat(x)_cp curve best-fit. [ignored if UAMod<>1]\n');
fprintf(fid,'0        k3                ! Constant in the \\hat(x)_cp curve best-fit. [ignored if UAMod<>1]\n');
fprintf(fid,'0        k1_hat            ! Constant in the expression of Cc due to leading edge vortex effects. [ignored if UAMod<>1]\n');
fprintf(fid,'default  x_cp_bar          ! Constant in the expression of \\hat(x)_cp^v. [ignored if UAMod<>1, default = 0.2]\n');
fprintf(fid,'default  UACutout          ! Angle of attack above which unsteady aerodynamics are disabled (deg). [Specifying the string "Default" sets UACutout to 45 degrees]\n');
fprintf(fid,'"DEFAULT"     filtCutOff        ! Cut-off frequency (-3 dB corner frequency) for low-pass filtering the AoA input to UA, as well as the 1st and 2nd derivatives (Hz) [default = 20] \n');
fprintf(fid,'!........................................\n');
fprintf(fid,'! Table of aerodynamics coefficients\n');
fprintf(fid,'%d      NumAlf            ! Number of data lines in the following table\n',nAlpha);
fprintf(fid,'!    Alpha      Cl      Cd        Cm\n');
fprintf(fid,'!    (deg)      (-)     (-)       (-)\n');
% Storing into a cell string to speed up IO
sPolar=cell(1,nAlpha);
for i=1:nAlpha
    sPolar{i}=sprintf('%6.1f %10.5f %10.5f %10.5f',res(i,:));
end

fprintf(fid,'%s\n',sPolar{:});
fclose(fid);
end



function [x0,y0,iout,jout] = intersections(x1,y1,x2,y2,robust)
%INTERSECTIONS Intersections of curves.
%   Computes the (x,y) locations where two curves intersect.  The curves
%   can be broken with NaNs or have vertical segments.
%
% Example:
%   [X0,Y0] = intersections(X1,Y1,X2,Y2,ROBUST);
%
% where X1 and Y1 are equal-length vectors of at least two points and
% represent curve 1.  Similarly, X2 and Y2 represent curve 2.
% X0 and Y0 are column vectors containing the points at which the two
% curves intersect.
%
% ROBUST (optional) set to 1 or true means to use a slight variation of the
% algorithm that might return duplicates of some intersection points, and
% then remove those duplicates.  The default is true, but since the
% algorithm is slightly slower you can set it to false if you know that
% your curves don't intersect at any segment boundaries.  Also, the robust
% version properly handles parallel and overlapping segments.
%
% The algorithm can return two additional vectors that indicate which
% segment pairs contain intersections and where they are:
%
%   [X0,Y0,I,J] = intersections(X1,Y1,X2,Y2,ROBUST);
%
% For each element of the vector I, I(k) = (segment number of (X1,Y1)) +
% (how far along this segment the intersection is).  For example, if I(k) =
% 45.25 then the intersection lies a quarter of the way between the line
% segment connecting (X1(45),Y1(45)) and (X1(46),Y1(46)).  Similarly for
% the vector J and the segments in (X2,Y2).
%
% You can also get intersections of a curve with itself.  Simply pass in
% only one curve, i.e.,
%
%   [X0,Y0] = intersections(X1,Y1,ROBUST);
%
% where, as before, ROBUST is optional.

% Version: 1.12, 27 January 2010
% Author:  Douglas M. Schwarz
% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})


% Theory of operation:
%
% Given two line segments, L1 and L2,
%
%   L1 endpoints:  (x1(1),y1(1)) and (x1(2),y1(2))
%   L2 endpoints:  (x2(1),y2(1)) and (x2(2),y2(2))
%
% we can write four equations with four unknowns and then solve them.  The
% four unknowns are t1, t2, x0 and y0, where (x0,y0) is the intersection of
% L1 and L2, t1 is the distance from the starting point of L1 to the
% intersection relative to the length of L1 and t2 is the distance from the
% starting point of L2 to the intersection relative to the length of L2.
%
% So, the four equations are
%
%    (x1(2) - x1(1))*t1 = x0 - x1(1)
%    (x2(2) - x2(1))*t2 = x0 - x2(1)
%    (y1(2) - y1(1))*t1 = y0 - y1(1)
%    (y2(2) - y2(1))*t2 = y0 - y2(1)
%
% Rearranging and writing in matrix form,
%
%  [x1(2)-x1(1)       0       -1   0;      [t1;      [-x1(1);
%        0       x2(2)-x2(1)  -1   0;   *   t2;   =   -x2(1);
%   y1(2)-y1(1)       0        0  -1;       x0;       -y1(1);
%        0       y2(2)-y2(1)   0  -1]       y0]       -y2(1)]
%
% Let's call that A*T = B.  We can solve for T with T = A\B.
%
% Once we have our solution we just have to look at t1 and t2 to determine
% whether L1 and L2 intersect.  If 0 <= t1 < 1 and 0 <= t2 < 1 then the two
% line segments cross and we can include (x0,y0) in the output.
%
% In principle, we have to perform this computation on every pair of line
% segments in the input data.  This can be quite a large number of pairs so
% we will reduce it by doing a simple preliminary check to eliminate line
% segment pairs that could not possibly cross.  The check is to look at the
% smallest enclosing rectangles (with sides parallel to the axes) for each
% line segment pair and see if they overlap.  If they do then we have to
% compute t1 and t2 (via the A\B computation) to see if the line segments
% cross, but if they don't then the line segments cannot cross.  In a
% typical application, this technique will eliminate most of the potential
% line segment pairs.


% Input checks.
error(nargchk(2,5,nargin))

% Adjustments when fewer than five arguments are supplied.
switch nargin
	case 2
		robust = true;
		x2 = x1;
		y2 = y1;
		self_intersect = true;
	case 3
		robust = x2;
		x2 = x1;
		y2 = y1;
		self_intersect = true;
	case 4
		robust = true;
		self_intersect = false;
	case 5
		self_intersect = false;
end

% x1 and y1 must be vectors with same number of points (at least 2).
if sum(size(x1) > 1) ~= 1 || sum(size(y1) > 1) ~= 1 || ...
		length(x1) ~= length(y1)
	error('X1 and Y1 must be equal-length vectors of at least 2 points.')
end
% x2 and y2 must be vectors with same number of points (at least 2).
if sum(size(x2) > 1) ~= 1 || sum(size(y2) > 1) ~= 1 || ...
		length(x2) ~= length(y2)
	error('X2 and Y2 must be equal-length vectors of at least 2 points.')
end


% Force all inputs to be column vectors.
x1 = x1(:);
y1 = y1(:);
x2 = x2(:);
y2 = y2(:);

% Compute number of line segments in each curve and some differences we'll
% need later.
n1 = length(x1) - 1;
n2 = length(x2) - 1;
xy1 = [x1 y1];
xy2 = [x2 y2];
dxy1 = diff(xy1);
dxy2 = diff(xy2);

% Determine the combinations of i and j where the rectangle enclosing the
% i'th line segment of curve 1 overlaps with the rectangle enclosing the
% j'th line segment of curve 2.
[i,j] = find(repmat(min(x1(1:end-1),x1(2:end)),1,n2) <= ...
	repmat(max(x2(1:end-1),x2(2:end)).',n1,1) & ...
	repmat(max(x1(1:end-1),x1(2:end)),1,n2) >= ...
	repmat(min(x2(1:end-1),x2(2:end)).',n1,1) & ...
	repmat(min(y1(1:end-1),y1(2:end)),1,n2) <= ...
	repmat(max(y2(1:end-1),y2(2:end)).',n1,1) & ...
	repmat(max(y1(1:end-1),y1(2:end)),1,n2) >= ...
	repmat(min(y2(1:end-1),y2(2:end)).',n1,1));

% Force i and j to be column vectors, even when their length is zero, i.e.,
% we want them to be 0-by-1 instead of 0-by-0.
i = reshape(i,[],1);
j = reshape(j,[],1);

% Find segments pairs which have at least one vertex = NaN and remove them.
% This line is a fast way of finding such segment pairs.  We take
% advantage of the fact that NaNs propagate through calculations, in
% particular subtraction (in the calculation of dxy1 and dxy2, which we
% need anyway) and addition.
% At the same time we can remove redundant combinations of i and j in the
% case of finding intersections of a line with itself.
if self_intersect
	remove = isnan(sum(dxy1(i,:) + dxy2(j,:),2)) | j <= i + 1;
else
	remove = isnan(sum(dxy1(i,:) + dxy2(j,:),2));
end
i(remove) = [];
j(remove) = [];

% Initialize matrices.  We'll put the T's and B's in matrices and use them
% one column at a time.  AA is a 3-D extension of A where we'll use one
% plane at a time.
n = length(i);
T = zeros(4,n);
AA = zeros(4,4,n);
AA([1 2],3,:) = -1;
AA([3 4],4,:) = -1;
AA([1 3],1,:) = dxy1(i,:).';
AA([2 4],2,:) = dxy2(j,:).';
B = -[x1(i) x2(j) y1(i) y2(j)].';

% Loop through possibilities.  Trap singularity warning and then use
% lastwarn to see if that plane of AA is near singular.  Process any such
% segment pairs to determine if they are colinear (overlap) or merely
% parallel.  That test consists of checking to see if one of the endpoints
% of the curve 2 segment lies on the curve 1 segment.  This is done by
% checking the cross product
%
%   (x1(2),y1(2)) - (x1(1),y1(1)) x (x2(2),y2(2)) - (x1(1),y1(1)).
%
% If this is close to zero then the segments overlap.

% If the robust option is false then we assume no two segment pairs are
% parallel and just go ahead and do the computation.  If A is ever singular
% a warning will appear.  This is faster and obviously you should use it
% only when you know you will never have overlapping or parallel segment
% pairs.

if robust
	overlap = false(n,1);
	warning_state = warning('off','MATLAB:singularMatrix');
	% Use try-catch to guarantee original warning state is restored.
	try
		lastwarn('')
		for k = 1:n
			T(:,k) = AA(:,:,k)\B(:,k);
			[unused,last_warn] = lastwarn;
			lastwarn('')
			if strcmp(last_warn,'MATLAB:singularMatrix')
				% Force in_range(k) to be false.
				T(1,k) = NaN;
				% Determine if these segments overlap or are just parallel.
				overlap(k) = rcond([dxy1(i(k),:);xy2(j(k),:) - xy1(i(k),:)]) < eps;
			end
		end
		warning(warning_state)
	catch err
		warning(warning_state)
		rethrow(err)
	end
	% Find where t1 and t2 are between 0 and 1 and return the corresponding
	% x0 and y0 values.
	in_range = (T(1,:) >= 0 & T(2,:) >= 0 & T(1,:) <= 1 & T(2,:) <= 1).';
	% For overlapping segment pairs the algorithm will return an
	% intersection point that is at the center of the overlapping region.
	if any(overlap)
		ia = i(overlap);
		ja = j(overlap);
		% set x0 and y0 to middle of overlapping region.
		T(3,overlap) = (max(min(x1(ia),x1(ia+1)),min(x2(ja),x2(ja+1))) + ...
			min(max(x1(ia),x1(ia+1)),max(x2(ja),x2(ja+1)))).'/2;
		T(4,overlap) = (max(min(y1(ia),y1(ia+1)),min(y2(ja),y2(ja+1))) + ...
			min(max(y1(ia),y1(ia+1)),max(y2(ja),y2(ja+1)))).'/2;
		selected = in_range | overlap;
	else
		selected = in_range;
	end
	xy0 = T(3:4,selected).';
	
	% Remove duplicate intersection points.
	[xy0,index] = unique(xy0,'rows');
	x0 = xy0(:,1);
	y0 = xy0(:,2);
	
	% Compute how far along each line segment the intersections are.
	if nargout > 2
		sel_index = find(selected);
		sel = sel_index(index);
		iout = i(sel) + T(1,sel).';
		jout = j(sel) + T(2,sel).';
	end
else % non-robust option
	for k = 1:n
		[L,U] = lu(AA(:,:,k));
		T(:,k) = U\(L\B(:,k));
	end
	
	% Find where t1 and t2 are between 0 and 1 and return the corresponding
	% x0 and y0 values.
	in_range = (T(1,:) >= 0 & T(2,:) >= 0 & T(1,:) < 1 & T(2,:) < 1).';
	x0 = T(3,in_range).';
	y0 = T(4,in_range).';
	
	% Compute how far along each line segment the intersections are.
	if nargout > 2
		iout = i(in_range) + T(1,in_range).';
		jout = j(in_range) + T(2,in_range).';
	end
end

% Plot the results (useful for debugging).
% plot(x1,y1,x2,y2,x0,y0,'ok');
end
