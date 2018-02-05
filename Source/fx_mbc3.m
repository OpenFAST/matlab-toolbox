function [MBC, matData, FAST_linData] = fx_mbc3( FileNames ) 
% MBC: Multi-Blade Coordinate Transformation for a turbine with 3-blade rotor
%
% Developed by Gunjit Bir, NREL (303-384-6953, gunjit_bir@nrel.gov)
%
% Last update: 08/30/2006
%    29-Jan-2018  - B. Jonkman, Envision Energy & J. Jonkman, NREL
%----------------------------------------------------------------------------------------
%
% Objectives:
% 1. Given state-space matrices (A,B) and output matrices (C,D), defined partly in the
%    rotoating frame and partly in the fixed frame, transform these matrices to the fixed
%    coordinate frame using multi-blade coordinate transformation (MBC). The transformned
%    matrices are MBC.A, MBC.B, MBC.C, and MBC.D.
%
% 2. Given second-order matrices (M,Dmp,K), control input matrix (F), 
%    displacement output matrix (Dc), and velocity output matrix (Vc), transform
%    these to the fixed coordinate frame using multi-blade coordinate transformation (MBC).
%    The transformed matrices are MBC.M, MBC.Dmp, MBC.K, MBC.F, MBC.Dc, and MBC.Vc.
%
% 3. Azimuth-average the MBC.A matrix and compute its eigenvalues and eigenvectors.  The
%    eigenvectors, referred to the fixed coordinates, are presented in both complex and
%    amplitude-phase forms. The eigenvalues, also referred to the fixed coordinates, are
%    presented in complex and damping-ratio/damped-frequency forms.
%
% ***Disclaimer: This code is still in the developmental stage and no guarantee is given
%    as to its proper functioning or accuracy of its results.
%
% ------------ INPUTS   (these are fields in matData [see fx_getMatx.m]) ---
% NumInputs  : total num of control inputs
% NumOutputs : total num of outputs
% NumStates  : number of states
%
% RotTripletIndicesStates   : State triplets in rotating frame (matrix of size rotating_dof_types*3)
% RotTripletIndicesCntrlInpt: Control-input triplets in rotating frame (matrix of size rotating_control_input_types*3)
% RotTripletIndicesOutput   : Output triplets in rotating frame (matrix of size rotating_output_types*3)
%
% DescStates : description of states associated with input matrices (FAST-specific) %%
%
% A, B, C, D:                     1st-order input matrices
% MassMat, DampMat, StffMat, FMat, VelCMat, DspCMat: 2nd-order input matrices
% Omega     : Vector of rotor speeds at specified azimuths (rad/sec)
% OmegaDot  : Vector of rotor accelerations at specified azimuths (rad/sec2)
% ndof      : total number of degrees of freedom
% NumStates : number of states
% Azimuth   : vector of azimuth positions (in deg)
%
% --------------------- OUTPUTS ----------------------------------------------------
% MBC.A,MBC.B         : state-space matrices transformed to the fixed frame
% MBC.C,MBC.D         : output matrices transformed to the fixed frame
% MBC.M,MBC.Dmp,MBC.K : second-order mass, damping/gyroscopic and stiffness matrices transformed to the fixed frame
% MBC.F               : control input matrix transformed to the fixed frame
% MBC.Dc,MBC.Vc       : displacement and velocity output matrices (Vc) transformed to the fixed frame
% -----------------------------------------------------------------------------------------
%**NOTE 1: All inputs and output matrices may not be present.  For example, user may supply or may be interested
%          in multi-blade coordinate transformation of A matrix only.  In this case, only MBC.A matrix along with
%          fixed-frame eigensolution will be genertaed as outputs.  The code checks for consistency and completness
%          of selected inputs and generates associated outputs.
%
% Equation numbers are from this document: https://nwtc.nrel.gov/system/files/MBC3.pdf
% -----------------------------------------------------------------------------------------

fprintf( '\n  Running %s\n\n', 'mbc3 (v2.0, 29-Jan-2018)' );

[matData, FAST_linData] = fx_getMats(FileNames);

MBC.DescStates = matData.DescStates; % save this in the MBC type for possible campbell_diagram processing later 

%% ---------- Multi-Blade-Coordinate transformation -------------------------------------------
if ~isfield(matData,'RotTripletIndicesStates')
    error('*** There are no rotating states. MBC transformation, therefore, cannot be performed.');
end

[n_RotTripletStates,nb] = size(matData.RotTripletIndicesStates);
if(nb ~= 3)
    error('**ERROR: the number of column vectors in matData.RotTripletIndicesStates must equal 3, the num of blades');
elseif(n_RotTripletStates*nb > matData.ndof)
    error('**ERROR: the rotating dof exceeds the total num of dof');
end

new_seq_dof    = get_new_seq(matData.RotTripletIndicesStates,matData.ndof); % these are the first ndof states (not "first time derivative" states)
new_seq_states = [new_seq_dof  new_seq_dof+matData.ndof]; % add the remaining ones (assumes ordering of displacements and velocities in state matrices)


if isfield(matData,'RotTripletIndicesCntrlInpt')
    [n_RotTripletInputs,nb] = size(matData.RotTripletIndicesCntrlInpt);
    if(nb ~= 3)
        error('**ERROR: the number of column vectors in RotTripletIndicesCntrlInpt must equal 3, the num of blades');
    end
    new_seq_inp = get_new_seq(matData.RotTripletIndicesCntrlInpt,matData.NumInputs);
else
    n_RotTripletInputs = 0; % number of rotating-frame control triplets
    new_seq_inp = 1:matData.NumInputs;
end

if isfield(matData,'RotTripletIndicesOutput')
    [n_RotTripletOutputs,nb] = size(matData.RotTripletIndicesOutput);
    if(nb ~= 3)
        error('**ERROR: the number of column vectors in RotTripletIndicesOutput must equal 3, the num of blades');
    end
    new_seq_out = get_new_seq(matData.RotTripletIndicesOutput,matData.NumOutputs);
else
    n_RotTripletOutputs = 0; % number of rotating-frame output triplets
    new_seq_out = 1:matData.NumOutputs;
end

n_FixFrameStates  = matData.ndof       - n_RotTripletStates*nb;  % fixed-frame dof
n_FixFrameInputs  = matData.NumInputs  - n_RotTripletInputs*nb;  % fixed-frame control inputs
n_FixFrameOutputs = matData.NumOutputs - n_RotTripletOutputs*nb; % fixed-frame outputs

if isfield(matData,'A')
    MBC.AvgA = zeros(matData.NumStates);
end

if ( size(matData.Omega) ~= matData.NAzimStep)
   error('**ERROR: the size of Omega vector must equal matData.NAzimStep, the num of azimuth steps');
end
if ( size(matData.OmegaDot) ~= matData.NAzimStep)
   error('**ERROR: the size of OmegaDot vector must equal matData.NAzimStep, the num of azimuth steps');
end

% begin azimuth loop 
for iaz = matData.NAzimStep:-1:1  
    %(loop backwards so we don't reallocate memory each time [i.e. variables with iaz index aren't getting larger each time])

    % compute azimuth positions of blades:
    az = matData.Azimuth(iaz)*pi/180.0 + 2*pi/nb* (0:(nb-1)) ; % Eq. 1, azimuth in radians

    % get rotor speed squared
    OmegaSquared = matData.Omega(iaz)^2;

    % compute transformation matrices
    cos_col = cos(az(:));
    sin_col = sin(az(:));
    
    tt = [ones(3,1), cos_col, sin_col];         % Eq. 9, t_tilde
    ttv = get_tt_inverse(sin_col, cos_col);     % inverse of tt (computed analytically in function below)
    
    %---
    T1 = eye(n_FixFrameStates);                 % Eq. 11
    for ii = 1:n_RotTripletStates
        T1 = blkdiag(T1, tt);
    end

    T1v = eye(n_FixFrameStates);                % inverse of T1
    for ii = 1:n_RotTripletStates
        T1v = blkdiag(T1v, ttv);
    end

    T2 = zeros(n_FixFrameStates);               % Eq. 14
    tt2 = [zeros(3,1), -sin_col,  cos_col];     % Eq. 16 a
    for ii = 1:n_RotTripletStates
        T2 = blkdiag(T2, tt2);
    end

    T3 = zeros(n_FixFrameStates);               % Eq. 15
    tt3 = [zeros(3,1), -cos_col, -sin_col];     % Eq. 16 b
    for ii = 1:n_RotTripletStates
        T3 = blkdiag(T3, tt3);
    end
    
    %---
    T1c = eye(n_FixFrameInputs);                % Eq. 21
    for ii = 1:n_RotTripletInputs;
        T1c = blkdiag(T1c, tt);
    end

    T1ov = eye(n_FixFrameOutputs);              % inverse of Tlo (Eq. 23)
    for ii = 1:n_RotTripletOutputs
        T1ov = blkdiag(T1ov, ttv);
    end

% mbc transformation of first-order matrices
%  if ( MBC.EqnsOrder == 1 ) % activate later

    if isfield(matData,'A')
            % Eq. 29, assuming
            % xAMat( 1:matData.ndof, 1:matData.NumStates ) = 0 and
            % xAMat( 1:matData.ndof, (matData.ndof+1):matData.NumStates) = I
        xAMat(:,:) = matData.A(new_seq_states,new_seq_states,iaz); %--
        AK = xAMat((matData.ndof+1):matData.NumStates,               1:matData.ndof);
        AC = xAMat((matData.ndof+1):matData.NumStates,(matData.ndof+1):matData.NumStates);
       
        MBC.A(new_seq_states,new_seq_states,iaz) = ...
               [zeros(matData.ndof),   eye(matData.ndof);
                T1v*(AK*T1 +   matData.Omega(iaz)*AC*T2 - OmegaSquared*T3 - matData.OmegaDot(iaz)*T2), ...
                T1v*(AC*T1 - 2*matData.Omega(iaz)*T2)];
    end

    if isfield(matData,'B')
            % Eq. 30
        xBMat = matData.B(new_seq_states,new_seq_inp,iaz); %--

        B1 = xBMat(1:matData.ndof,:);
        B2 = xBMat(matData.ndof+1:matData.NumStates,:);
        MBC.B(new_seq_states,new_seq_inp,iaz) = [T1v*B1; T1v*B2] * T1c; 
    end

    if isfield(matData,'C')
            % Eq. 31 (Note that to match Eq 31, this assumes matData.C(:,new_seq_states(1:matData.ndof)) = 0,
            % which does not appear to be true in general!!!!)
        MBC.C(new_seq_out, new_seq_states, iaz) = ...
                     T1ov * matData.C(new_seq_out,new_seq_states,iaz) * ...
                     [T1, zeros(matData.ndof); matData.Omega(iaz)*T2, T1];
    end

    if isfield(matData,'D')
           % Eq. 32
        MBC.D(new_seq_out,new_seq_inp,iaz) = T1ov * matData.D(new_seq_out,new_seq_inp,iaz) * T1c;
    end

%  end

% mbc transformation of second-order matrices
%  if ( EqnsOrder == 2 ) %% activate later

    if isfield(matData,'MassMat')
            % Eq. 19
        xMassMat = matData.MassMat(new_seq_dof,new_seq_dof,iaz); %--
        MBC.M(new_seq_dof,new_seq_dof,iaz) = xMassMat*T1; 

        xDampMat = matData.DampMat(new_seq_dof,new_seq_dof,iaz); %--
        MBC.Dmp(new_seq_dof,new_seq_dof,iaz) = 2*matData.Omega(iaz)*xMassMat*T2 + xDampMat*T1;

        MBC.K(new_seq_dof,new_seq_dof,iaz) =          OmegaSquared*xMassMat*T3 ...
                                           + matData.OmegaDot(iaz)*xMassMat*T2 ...
                                           + matData.Omega(   iaz)*xDampMat*T2 ...
                                           + matData.StffMat(new_seq_dof,new_seq_dof,iaz)*T1;
    end 

    if isfield(matData,'FMat')
            % Eq. 19
        MBC.F(new_seq_dof, new_seq_inp, iaz) = matData.FMat(new_seq_dof,new_seq_inp,iaz)*T1c;
    end

    if isfield(matData,'DspCMat')
            % Eq. 19
        MBC.Vc(new_seq_out,new_seq_dof,iaz) = T1ov * matData.VelCMat(new_seq_out,new_seq_dof,iaz) * T1;

        MBC.Dc(new_seq_out,new_seq_dof,iaz) = T1ov*(matData.Omega(iaz)*matData.VelCMat(new_seq_out,new_seq_dof,iaz)*T2 ...
                                                                     + matData.DspCMat(new_seq_out,new_seq_dof,iaz)*T1);       
    end

%  end

end   % end of azimuth loop



%------------- Eigensolution and Azimuth Averages -------------------------
if isfield(MBC,'A')
    MBC.AvgA = mean(MBC.A,3); % azimuth-average of azimuth-dependent MBC.A matrices
    MBC.eigSol = eiganalysis(MBC.AvgA);
end

if isfield(MBC,'B')
    MBC.AvgB = mean(MBC.B,3); % azimuth-average of azimuth-dependent MBC.B matrices
end

if isfield(MBC,'C')
    MBC.AvgC = mean(MBC.C,3); % azimuth-average of azimuth-dependent MBC.C matrices
end

if isfield(MBC,'D')
    MBC.AvgD = mean(MBC.D,3); % azimuth-average of azimuth-dependent MBC.D matrices
end

% ----------- Clear unneeded variables -------------------------------
  disp('  ');
  disp(' Multi-Blade Coordinate transformation completed ');
%-----------------------------------------------------------
return;
end

%% ------------------------------------------------------------------------
% compute the inverse of tt = [ones(3,1), cos_col, sin_col]
function [ttv] = get_tt_inverse(sin_col, cos_col)

    c1 = cos_col(1);
    c2 = cos_col(2);
    c3 = cos_col(3);
    
    s1 = sin_col(1);
    s2 = sin_col(2);
    s3 = sin_col(3);

    
    ttv = [ c2*s3 - s2*c3,  c3*s1 - s3*c1, c1*s2 - s1*c2
               s2 - s3 ,       s3 - s1,       s1 - s2
               c3 - c2 ,       c1 - c3,       c2 - c1 ] / (1.5*sqrt(3));

    return
end

%% ------------------------------------------------------------------------
% create a sequence where the non-rotating values are first, and are then 
% followed by the rotating series with b1, b2, b3 triplets:
function [new_seq] = get_new_seq(rot_triplet,ntot)
%  rot_q_triplet is size n x 3

    non_rotating = true(ntot,1);
    non_rotating(rot_triplet(:)) = false; % if they are rotating, set them false;

    new_seq = [find(non_rotating); reshape( rot_triplet', numel(rot_triplet), 1)];
    return
    
end

