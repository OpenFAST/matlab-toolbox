% GetMats_f8.m
% Written by J. Jonkman, NREL
% 19-July-2016: Updated to convert FAST v8.16 linearization files into
% format expected by mbc3.m
% NOTE that we assume all the files in RootNames contain the same data
% structures (same state matrices; same number of inputs, outputs, states, 
% etc.; same rotor speed; but should have different azimuth angles.

% This m-file is used to read in the data written to multiple FAST linear output
%  (.lin) files, compute the state matrix, [A], at each of the equally-spaced
%  azimuth steps and their azimuth-average, along with their eigenvalues and
%  eigenvectors.

format short g;

FileNames = {'C:\Users\bjonkman\Documents\DATA\DesignCodes\simulators\FAST\SVNdirectory\branches\BJonkman\CertTest\Test18.1.lin'};
FileNames = {'Test18.1.lin'};

% Input data:

MdlOrder = 1;
NAzimStep = length(FileNames);
data(NAzimStep) = ReadFASTLinear(FileNames{1}); %we'll read this twice so we can allocate space first; putting it at NAzimStep saves some reallocation later
N = data(NAzimStep).n_x;
NActvDOF = N / 2;
NInputs  = data(NAzimStep).n_u;
NumOuts  = data(NAzimStep).n_y;


clear xdop xop AMat DescCntrlInpt BMat DescOutput OutName CMat DMat AvgBMat AvgCMat AvgDMat;
clear RotTripletIndicesStates RotTripletIndicesCntrlInpt RotTripletIndicesOutput;

%% .................................
% allocate space for these variables
% ..................................
Azimuth   = zeros(NAzimStep, 1);
Omega     = zeros(NAzimStep, 1);
OmegaDot  = zeros(NAzimStep, 1);
NDisturbs = 0;
if ( N > 0 )
    DescStates = data(NAzimStep).x_desc;
    xdop      = zeros(N,    NAzimStep);
    xop       = zeros(N,    NAzimStep);
    AMat      = zeros(N, N, NAzimStep);   
end

if ( NInputs > 0 )
    DescCntrlInpt = data(NAzimStep).u_desc;    
    if (N>0) 
        BMat = zeros(N, NInputs, NAzimStep);
    end
end

if ( NumOuts > 0 )
    DescOutput    = data(NAzimStep).y_desc;    
    if ( N > 0 )
        CMat      = zeros(NumOuts, N, NAzimStep);
    end
    if ( NInputs > 0 )
        DMat      = zeros(NumOuts, NInputs, NAzimStep);
    end
end

%% .................................
% get data into variables expected by GetMats (concatenate data from
% different azimuths into matrices)
% ..................................

for iFile = 1:NAzimStep

    data(iFile) = ReadFASTLinear(FileNames{iFile});
    
    Omega(iFile)   = data(iFile).RotSpeed;
    Azimuth(iFile) = data(iFile).Azimuth;

    if (isfield(data(iFile), 'A'))
        AMat(:,:,iFile) = data(iFile).A;
    end
    if (isfield(data(iFile), 'B'))
        BMat(:,:,iFile) = data(iFile).B;
    end
    if (isfield(data(iFile), 'C'))
        CMat(:,:,iFile) = data(iFile).C;
    end
    if (isfield(data(iFile), 'D'))
        DMat(:,:,iFile) = data(iFile).D;
    end

    if (isfield(data(iFile), 'x_op'))        
        xop(:,iFile) = cell2mat(data(iFile).x_op);
    end
    if (isfield(data(iFile), 'xdot_op'))
        xdop(:,iFile) = cell2mat(data(iFile).xdot_op);
    end
    
end 


%% Find the azimuth-averaged linearized 1st order state matrices:
if ( isfield(data(1),'A') )
    Avgxdop = mean(xdop,2);
    Avgxop  = mean(xop, 2);
    AvgAMat = mean(AMat, 3);
end
if ( isfield(data(1),'B') )
    AvgBMat = mean(BMat, 3);
end
if ( isfield(data(1),'C') )
    AvgCMat = mean(CMat, 3);
end
if ( isfield(data(1),'D') )
    AvgDMat = mean(DMat, 3);
end


%%
for i=1:NActvDOF
    col = strfind(DescStates{i},'DOF_GeAz'); % find the starting index of the string 'DOF_GeAz'
    if ( ~isempty(col) )     % true if the DescStates contains the string 'DOF_GeAz'
        Omega(:)    = xdop(i,:)';
        OmegaDot(:) = xdop(i+NActvDOF,:)';
        break;
    end
end
for i=1:NActvDOF
    col = strfind(DescStates{i},'DOF_DrTr'); % find the starting index of the string 'DOF_DrTr'
    if ( ~isempty(col) )     % true if the DescStates contains the string 'DOF_GeAz'
        Omega(:)    = Omega(:)    + xdop(i,:)'; %This always comes after DOF_GeAz so let's just add it here (it won't get written over later).
        OmegaDot(:) = OmegaDot(:) + xdop(i+NActvDOF,:)';
        break;
    end
end

% ----------- Find multi-blade coordinate (MBC) transformation indices ----

%% Find the number of, and indices for, state triplets in the rotating
%   frame:
NRotTripletStates = 0;                  % first initialize to zero
for i = 1:NActvDOF	% loop through all active (enabled) DOFs
    if data(1).x_rotFrame(i)  % this is a state in the rotating frame

        col = strfind(DescStates{i},'blade');                    % find the starting index of the string 'blade'
        if ~isempty(col)             % true if the DescStates{I} contains the string 'blade'
            k = str2double(DescStates{i}(col+6));                % save the blade number for the initial blade
            Tmp = zeros(1,3);                                       % first initialize to zero
            Tmp(k) = i;                                           % save the index for the initial blade
            for j = (i+1):NActvDOF                                  % loop through all remaining active (enabled) DOFs
                if strncmp(DescStates{j},DescStates{i},col)      % true if we have the same state from a different blade
                    k = str2double(DescStates{j}(col+6));        % save the blade numbers for the remaining blades
                    Tmp(k) = j;                                   % save the indices for the remaining blades
                    
                    if ( all(Tmp) )     % true if all the elements of Tmp are nonzero; thus, we found a triplet of rotating indices
                        NRotTripletStates = NRotTripletStates + 1;           % this  is  the number  of  state triplets in the rotating frame
                        RotTripletIndicesStates(NRotTripletStates,:) = Tmp;  % these are the indices for state triplets in the rotating frame
                        break;
                    end
                end
            end %for j
        end
        
    end
end % i - all active (enabled) DOFs

%% Find the number of, and indices for, control input triplets in the
%   rotating frame:
if (NInputs > 0)
    [RotTripletIndicesCntrlInpt, NRotTripletCntrlInpt] = findBladeTriplets(data(1).u_rotFrame,DescCntrlInpt );
end


%% Find the number of, and indices for, output measurement triplets in the
%   rotating frame:
if (NumOuts > 0 )
    [RotTripletIndicesOutput, NRotTripletOutput] = findBladeTriplets(data(1).y_rotFrame,DescOutput );
end
    
% ----------- Clear some unneeded variables -------------------------------
clear iFile i j k col Tmp;

% ----------- We're finished ----------------------------------------------

% Tell the user that we are finished:
disp( '                                      ' );
disp( 'GetMats_f8.m completed                ' );
disp( 'Type "who" to list available variables' );
