% GetMats_f8.m
% Written by J. Jonkman, NREL
% 19-July-2016: Updated by B. Jonkman (NREL) to convert FAST v8.16 
% linearization files into format expected by mbc3.m
% 22-Jan-2018: Updated by B. Jonkman, (Envision Energy) for BeamDyn linearization.
% 
% This m-file is used to read in the data written to multiple FAST linear output
%  (.lin) files, compute the state matrix, [A], at each of the equally-spaced
%  azimuth steps and their azimuth-average, along with their eigenvalues and
%  eigenvectors.
%
% ASSUMPTIONS:
% - all files in FileNames contain the same data structures (i.e., they
%   have the same numbers of inputs, outputs, and states; if a state matrix
%   exists in one, it exists in all)
% - all files in FileNames have the same rotor speed, but have different
%   azimuth angles
% - BeamDyn blade nodes are discretized in the same way for each blade.
% - the states for each module are ordered by module; in each module all of  
%   the displacement states are followed by all the velocity states.
% - descriptions of inputs, outputs, and (BD) states are triplets if they
%   match in all characters except the blade number. (see
%   findBladeTriplets.m for details)

format short g;

if isempty(FileNames)
    FileNames = {'Test18.1.lin','Test18.2.lin'};
end 

% Input data:

MdlOrder = 1;
NAzimStep = length(FileNames);
data(NAzimStep) = ReadFASTLinear(FileNames{1}); %we'll read this twice so we can allocate space first; putting it at NAzimStep saves some reallocation later
N = data(NAzimStep).n_x;
NActvDOF = N / 2;
NInputs  = data(NAzimStep).n_u;
NumOuts  = data(NAzimStep).n_y;


clear xdop xop AMat DescCntrlInpt BMat DescOutput OutName CMat DMat AvgBMat AvgCMat AvgDMat DescStates;
clear RotTripletIndicesStates RotTripletIndicesCntrlInpt RotTripletIndicesOutput StateOrderingIndx;

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

%% Reorder state matrices so that all the module's displacements are first,
%  followed by all the modules' velocities (because mbc assumes that the 
%  first ndof values are velocities).
if ( N > 0 )
    StateOrderingIndx = (1:N)';
    lastModName = '';
    mod_nDOFs = 0; % number of DOFs in each module
    sum_nDOFs = 0; % running total of DOFs
    indx_start=1;  % starting index of the module's
    for i=1:2:N % there are an even number of states, so we're going to save some time
        modName = strtok(DescStates{i}); % name of the module whose states we are looking at

        if ~strcmp(lastModName,modName)
            % this is the start of a new set of DOFs, so we'll set the
            % "first time derivative" descriptions to an empty string.
            StateOrderingIndx(  indx_start           :(indx_start+mod_nDOFs-1)) = sum_nDOFs +            (1:mod_nDOFs);
            StateOrderingIndx( (indx_start+mod_nDOFs):(i - 1))                  = sum_nDOFs + NActvDOF + (1:mod_nDOFs);

            % reset for a new module
            sum_nDOFs = sum_nDOFs + mod_nDOFs;
            mod_nDOFs = 0;
            indx_start = i;
            lastModName = modName;
        end
        mod_nDOFs = mod_nDOFs+1;
    end
    StateOrderingIndx(  indx_start           :(indx_start+mod_nDOFs-1)) = sum_nDOFs +            (1:mod_nDOFs);
    StateOrderingIndx( (indx_start+mod_nDOFs):N)                        = sum_nDOFs + NActvDOF + (1:mod_nDOFs);
    if strcmpi(lastModName,'ED')
        checkEDstates = true;
    else
        checkEDstates = false;
    end

    clear lastModName mod_nDOFs sum_nDOFs indx_start modName
    
    x_rotFrame(StateOrderingIndx) = data(NAzimStep).x_rotFrame;
    DescStates(StateOrderingIndx) = data(NAzimStep).x_desc;
end

%% .................................
% get data into variables expected by GetMats (concatenate data from
% different azimuths into matrices)
% ..................................

for iFile = 1:NAzimStep

    data(iFile) = ReadFASTLinear(FileNames{iFile});
    
    Omega(iFile)   = data(iFile).RotSpeed;
    Azimuth(iFile) = data(iFile).Azimuth*180/pi;

    if (isfield(data(iFile), 'A'))
        AMat(StateOrderingIndx,StateOrderingIndx,iFile) = data(iFile).A;
    end
    if (isfield(data(iFile), 'B'))
        BMat(StateOrderingIndx,:,iFile) = data(iFile).B;
    end
    if (isfield(data(iFile), 'C'))
        CMat(:,StateOrderingIndx,iFile) = data(iFile).C;
    end
    if (isfield(data(iFile), 'D'))
        DMat(:,:,iFile) = data(iFile).D;
    end

    if (isfield(data(iFile), 'x_op'))        
        xop(StateOrderingIndx,iFile) = cell2mat(data(iFile).x_op);
    end
    if (isfield(data(iFile), 'xdot_op'))
        xdop(StateOrderingIndx,iFile) = cell2mat(data(iFile).xdot_op);
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
%   frame (note that we avoid the "first time derivative" states)
if (NActvDOF > 0)   
    if (checkEDstates)
        [RotTripletIndicesStates, NRotTripletStates] = findBladeTriplets_EDstate(x_rotFrame(1:NActvDOF),DescStates(1:NActvDOF) );
    else
        [RotTripletIndicesStates, NRotTripletStates] = findBladeTriplets(x_rotFrame(1:NActvDOF),DescStates(1:NActvDOF) );
    end
    clear x_rotFrame
end

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
