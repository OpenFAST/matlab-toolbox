function [matData, data] = fx_getMats(FileNames)
% fx_getMats(FileNames)
% Written by J. Jonkman, NREL
% 19-July-2016: Updated by B. Jonkman (NREL) to convert FAST v8.16 
% linearization files into format expected by mbc3.m
% 22-Jan-2018: Updated by B. Jonkman, (Envision Energy) for BeamDyn linearization
%              converted to a function with data types.
% 
% This m-file is used to read in the data written to multiple FAST linear output
%  (.lin) files, compute the state matrix, [A], at each of the equally-spaced
%  azimuth steps and their azimuth-average, along with their eigenvalues and
%  eigenvectors.
%
% inputs: 
%   FileNames - cell string containing names of FAST linear output files
% outputs:
%   matData   - structure containing computations of FAST linear data.
%   data      - raw data read from the FAST linearization files.
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
% - descriptions of inputs, outputs, and (BeamDyn) states are triplets if
%   they match in all characters except the blade number. (see
%   findBladeTriplets.m for details)

if nargin < 1 || isempty(FileNames)
    FileNames = {'Test18.1.lin','Test18.2.lin'};
elseif ~iscell(FileNames)
    FileNames = {FileNames}; % convert (hopefully a) string to cell
end 

% Input data from linearization files:
matData.NAzimStep       = length(FileNames);
data(matData.NAzimStep) = ReadFASTLinear(FileNames{1}); %we'll read this twice so we can allocate space first; putting it at matData.NAzimStep saves some reallocation later
matData.NumStates       = data(matData.NAzimStep).n_x;
matData.ndof            = matData.NumStates / 2;
matData.NumInputs       = data(matData.NAzimStep).n_u;
matData.NumOutputs      = data(matData.NAzimStep).n_y;


%% .................................
% allocate space for these variables
% ..................................
matData.Azimuth   = zeros(matData.NAzimStep, 1);
matData.Omega     = zeros(matData.NAzimStep, 1);
matData.OmegaDot  = zeros(matData.NAzimStep, 1);

if ( matData.NumStates > 0 )
    matData.DescStates = data(matData.NAzimStep).x_desc;
    matData.xdop       = zeros(matData.NumStates,                    matData.NAzimStep);
    matData.xop        = zeros(matData.NumStates,                    matData.NAzimStep);
    matData.A          = zeros(matData.NumStates, matData.NumStates, matData.NAzimStep);   
end

if ( matData.NumInputs > 0 )
    matData.DescCntrlInpt = data(matData.NAzimStep).u_desc;    
    if (matData.NumStates>0) 
        matData.B = zeros(matData.NumStates, matData.NumInputs, matData.NAzimStep);
    end
end

if ( matData.NumOutputs > 0 )
    matData.DescOutput    = data(matData.NAzimStep).y_desc;    
    if ( matData.NumStates > 0 )
        matData.C         = zeros(matData.NumOutputs, matData.NumStates, matData.NAzimStep);
    end
    if ( matData.NumInputs > 0 )
        matData.D         = zeros(matData.NumOutputs, matData.NumInputs, matData.NAzimStep);
    end
end

%% Reorder state matrices so that all the modules' displacements are first,
%  followed by all the modules' velocities (because mbc assumes that the 
%  first ndof values are velocities).
if ( matData.NumStates > 0 )
    [StateOrderingIndx, checkEDstates]    = getStateOrderingIndx(matData);
    
    x_rotFrame(StateOrderingIndx)         = data(matData.NAzimStep).x_rotFrame;
    matData.DescStates(StateOrderingIndx) = data(matData.NAzimStep).x_desc;
end

%% .................................
% get data into variables expected by GetMats (concatenate data from
% different azimuths into matrices)
% ..................................

for iFile = 1:matData.NAzimStep

    data(iFile) = ReadFASTLinear(FileNames{iFile});
    
    matData.Omega(iFile)   = data(iFile).RotSpeed;
    matData.Azimuth(iFile) = data(iFile).Azimuth*180/pi;

    if (isfield(data(iFile), 'A'))
        matData.A(StateOrderingIndx,StateOrderingIndx,iFile) = data(iFile).A;
    end
    if (isfield(data(iFile), 'B'))
        matData.B(StateOrderingIndx,:,iFile) = data(iFile).B;
    end
    if (isfield(data(iFile), 'C'))
        matData.C(:,StateOrderingIndx,iFile) = data(iFile).C;
    end
    if (isfield(data(iFile), 'D'))
        matData.D(:,:,iFile) = data(iFile).D;
    end

    if (isfield(data(iFile), 'x_op'))        
        matData.xop(StateOrderingIndx,iFile) = cell2mat(data(iFile).x_op);
    end
    if (isfield(data(iFile), 'xdot_op'))
        matData.xdop(StateOrderingIndx,iFile) = cell2mat(data(iFile).xdot_op);
    end
    
end 


%% Find the azimuth-averaged linearized 1st order state matrices:
if isfield(matData,'A')
    matData.Avgxdop = mean(matData.xdop,2);
    matData.Avgxop  = mean(matData.xop, 2);
    matData.AvgA    = mean(matData.A,3);
end
if isfield(matData,'B')
    matData.AvgB    = mean(matData.B,3);
end
if isfield(matData,'C')
    matData.AvgC    = mean(matData.C,3);
end
if isfield(matData,'D')
    matData.AvgD    = mean(matData.D,3);
end


%%
for i=1:matData.ndof
    col = strfind(matData.DescStates{i},'DOF_GeAz'); % find the starting index of the string 'DOF_GeAz'
    if ( ~isempty(col) )     % true if the matData.DescStates contains the string 'DOF_GeAz'
        matData.Omega(:)    = matData.xdop(i,:)';
        matData.OmegaDot(:) = matData.xdop(i+matData.ndof,:)';
        break;
    end
end
for i=1:matData.ndof
    col = strfind(matData.DescStates{i},'DOF_DrTr'); % find the starting index of the string 'DOF_DrTr'
    if ( ~isempty(col) )     % true if the matData.DescStates contains the string 'DOF_GeAz'
        matData.Omega(:)    = matData.Omega(:)    + matData.xdop(i,:)'; %This always comes after DOF_GeAz so let's just add it here (it won't get written over later).
        matData.OmegaDot(:) = matData.OmegaDot(:) + matData.xdop(i+matData.ndof,:)';
        break;
    end
end

% ----------- Find multi-blade coordinate (MBC) transformation indices ----

%% Find the indices for, state triplets in the rotating frame
%  (note that we avoid the "first time derivative" states)
if (matData.ndof > 0)   
    if (checkEDstates)
        [matData.RotTripletIndicesStates] = findBladeTriplets_EDstate(x_rotFrame(1:matData.ndof),matData.DescStates(1:matData.ndof) );
    else
        [matData.RotTripletIndicesStates] = findBladeTriplets(        x_rotFrame(1:matData.ndof),matData.DescStates(1:matData.ndof) );
    end
end

%% Find the indices for control input triplets in the rotating frame:
if (matData.NumInputs > 0)
    [matData.RotTripletIndicesCntrlInpt] = findBladeTriplets(data(1).u_rotFrame,matData.DescCntrlInpt );
end

%% Find the indices for output measurement triplets in the rotating frame:
if (matData.NumOutputs > 0 )
    [matData.RotTripletIndicesOutput] = findBladeTriplets(data(1).y_rotFrame,matData.DescOutput );
end
    
return;
end

%% Reorder state matrices so that all the module's displacements are first,
%  followed by all the modules' velocities (because mbc assumes that the 
%  first ndof values are velocities).
function [StateOrderingIndx, checkEDstates] = getStateOrderingIndx(matData)

    StateOrderingIndx = (1:matData.NumStates)';
    lastModName = '';
    mod_nDOFs   = 0;    % number of DOFs in each module
    sum_nDOFs   = 0;    % running total of DOFs
    indx_start  = 1;    % starting index of the modules
    
    for i=1:2:matData.NumStates % there are an even number of states, so we're going to save some time
        
        modName = strtok(matData.DescStates{i}); % name of the module whose states we are looking at

        if ~strcmp(lastModName,modName)
            % this is the start of a new set of DOFs, so we'll set the
            % "first time derivative" descriptions to an empty string.
            StateOrderingIndx(  indx_start           :(indx_start+mod_nDOFs-1)) = sum_nDOFs +                (1:mod_nDOFs);
            StateOrderingIndx( (indx_start+mod_nDOFs):(i - 1))                  = sum_nDOFs + matData.ndof + (1:mod_nDOFs);

            % reset for a new module
            sum_nDOFs = sum_nDOFs + mod_nDOFs;
            mod_nDOFs = 0;
            indx_start = i;
            lastModName = modName;
        end
        mod_nDOFs = mod_nDOFs+1;
        
    end
    
    StateOrderingIndx(  indx_start           :(indx_start+mod_nDOFs-1)) = sum_nDOFs +                (1:mod_nDOFs);
    StateOrderingIndx( (indx_start+mod_nDOFs):matData.NumStates)        = sum_nDOFs + matData.ndof + (1:mod_nDOFs);
    
        % ED has the blade number in the state description twice, so we
        % have to check the strings differently. We'll note that here:
    if strcmpi(lastModName,'ED')
        checkEDstates = true;
    else
        checkEDstates = false;
    end

end
