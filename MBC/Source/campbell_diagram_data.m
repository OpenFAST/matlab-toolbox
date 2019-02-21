function [CampbellData, VTK] = campbell_diagram_data(mbc_data, BladeLen, TowerLen, xlsFileName, ModeVizFileName)
%%
% inputs: 
% -   mbc_data is the output data from mbc3 containing DescStates and
%     eigSol fields
% -   BladeLen and TowerLen are the lengths (in meters) of the blade and  
%     the tower, respectively, and are used for scaling the magnitudes of 
%     the rows (for consistent units)
%
outputXLSfile = nargin > 3 && ~isempty(xlsFileName);

% mbc_data.eigSol = eiganalysis(mbc_data.AvgA);
ndof = size(mbc_data.AvgA,1)/2;          % number of translational states
nModes = length(mbc_data.eigSol.Evals);

%% change the state descriptions (add collective, sine, cosine, etc) and remove the last ndof of them
DescStates = PrettyStateDescriptions(mbc_data.DescStates, mbc_data.ndof2, mbc_data.performedTransformation);

%% get the scaling factors for the mode rows
ScalingFactor = getScaleFactors(DescStates, TowerLen, BladeLen);

%% store indices of max mode for state and to order natural frequencies
[~, StatesMaxMode] = max(mbc_data.eigSol.MagnitudeModes,[],2); % find which mode has the maximum value for each state (max of each row before scaling)
[~, SortedFreqIndx] = sort(mbc_data.eigSol.NaturalFreqs_Hz);

%% scale the magnitude of the modes by ScalingFactor (for consistent units)
%  and then scale the columns so that their maximum is 1

ModesMagnitude = diag(ScalingFactor) * mbc_data.eigSol.MagnitudeModes; % scale the rows
maxCol         = max(ModesMagnitude,[],1); % find the maximum value in the column
ModesMagnitude = ModesMagnitude * diag(1./maxCol); % scale the columns

if nargout > 1
    [VTK] = GetDataForVTK(mbc_data, ModesMagnitude, maxCol, ScalingFactor, SortedFreqIndx);
    if nargin > 4
        WriteDataForVTK(VTK, ModeVizFileName)
    end        
end

%%
CampbellData.NaturalFreq_Hz = mbc_data.eigSol.NaturalFreqs_Hz(SortedFreqIndx);
CampbellData.DampingRatio   = mbc_data.eigSol.DampRatios(     SortedFreqIndx);

%%

% Matlab apparently does not allow nested arrays of structures, so Modes will be a cell array
CampbellData.Modes = cell(nModes,1);
for i=1:nModes
    CampbellData.Modes{i}.NaturalFreq_Hz = mbc_data.eigSol.NaturalFreqs_Hz(SortedFreqIndx(i));
    CampbellData.Modes{i}.DampedFreq_Hz  = mbc_data.eigSol.DampedFreqs_Hz( SortedFreqIndx(i));
    CampbellData.Modes{i}.DampingRatio   = mbc_data.eigSol.DampRatios(     SortedFreqIndx(i));

    [~,sort_state] = sort( ModesMagnitude(:,SortedFreqIndx(i)), 'descend' );
    
    CampbellData.Modes{i}.DescStates = DescStates(sort_state);
        
    CampbellData.Modes{i}.MagnitudePhase = ModesMagnitude(sort_state,SortedFreqIndx(i));
    Phase =                mbc_data.eigSol.PhaseModes_deg(sort_state,SortedFreqIndx(i));
        % if the phase is more than +/- 90 degrees different than the first
        % (whose value == 1) one, we'll stick a negative value on the magnitude:
    Phase = mod(Phase, 360);
    
    CampbellData.Modes{i}.PhaseDiff = mod( Phase - Phase(1), 360); % difference in range [0, 360)
    PhaseIndx = CampbellData.Modes{i}.PhaseDiff > 180;
    CampbellData.Modes{i}.PhaseDiff(PhaseIndx) = CampbellData.Modes{i}.PhaseDiff(PhaseIndx) - 360;   % move to range (-180, 180]
    
    PhaseIndx = CampbellData.Modes{i}.PhaseDiff > 90;
    CampbellData.Modes{i}.MagnitudePhase(PhaseIndx) = -1*CampbellData.Modes{i}.MagnitudePhase(PhaseIndx);
    CampbellData.Modes{i}.PhaseDiff(PhaseIndx) = CampbellData.Modes{i}.PhaseDiff(PhaseIndx) - 180;

    PhaseIndx = CampbellData.Modes{i}.PhaseDiff <= -90;
    CampbellData.Modes{i}.MagnitudePhase(PhaseIndx) = -1*CampbellData.Modes{i}.MagnitudePhase(PhaseIndx);
    CampbellData.Modes{i}.PhaseDiff(PhaseIndx) = CampbellData.Modes{i}.PhaseDiff(PhaseIndx) + 180;
    
    
    CampbellData.ModesTable(5, (i-1)*3+2 ) = {['State has max at mode ' num2str(i)]};
    
    CampbellData.Modes{i}.StateHasMaxAtThisMode = false(ndof,1);
    ix = (StatesMaxMode == SortedFreqIndx(i));
    if (any(ix))
        CampbellData.Modes{i}.StateHasMaxAtThisMode(ix(sort_state)) = true;
    end
    
end


%%
nColsPerMode = 5;

CampbellData.ModesTable = cell(ndof+5,nColsPerMode*nModes);

for i=1:nModes
    colStart = (i-1)*nColsPerMode;
    CampbellData.ModesTable(1, colStart+1 ) = {'Mode number:'};
    CampbellData.ModesTable(1, colStart+2 ) = num2cell(i);

    CampbellData.ModesTable(2, colStart+1 ) = {'Natural (undamped) frequency (Hz):'};
    CampbellData.ModesTable(2, colStart+2 ) = num2cell( CampbellData.Modes{i}.NaturalFreq_Hz );

    CampbellData.ModesTable(3, colStart+1 ) = {'Damped frequency (Hz):'};
    CampbellData.ModesTable(3, colStart+2 ) = num2cell( CampbellData.Modes{i}.DampedFreq_Hz );

    CampbellData.ModesTable(4, colStart+1 ) = {'Damping ratio (-):'};
    CampbellData.ModesTable(4, colStart+2 ) = num2cell( CampbellData.Modes{i}.DampingRatio );
    
    CampbellData.ModesTable(5, colStart+1 ) = {['Mode ' num2str(i) ' state description']};
    CampbellData.ModesTable(5, colStart+2 ) = {['State has max at mode ' num2str(i)]};
    CampbellData.ModesTable(5, colStart+3 ) = {['Mode ' num2str(i) ' signed magnitude']};
    CampbellData.ModesTable(5, colStart+4 ) = {['Mode ' num2str(i) ' phase (deg)']};
    
    CampbellData.ModesTable(6:end,colStart+1) = CampbellData.Modes{i}.DescStates;
    CampbellData.ModesTable(6:end,colStart+2) = num2cell( CampbellData.Modes{i}.StateHasMaxAtThisMode );
    CampbellData.ModesTable(6:end,colStart+3) = num2cell( CampbellData.Modes{i}.MagnitudePhase );
    CampbellData.ModesTable(6:end,colStart+4) = num2cell( CampbellData.Modes{i}.PhaseDiff );
     
end

%% if requested, output this data to a Microsoft Excel spreadsheet file, in a sheet named 'Modes_Data'
if outputXLSfile
    xlswrite(xlsFileName,CampbellData.ModesTable, 'Modes_Data')
end

return
end

%% ------------------------------------------------------------------------    
function [StateDesc] = PrettyStateDescriptions(DescStates, ndof2, performedTransformation)
    DescStates = DescStates([1:ndof2  (ndof2*2+1):length(DescStates)]);

    if performedTransformation
        StateDesc = strrep(strrep(strrep(strrep(strrep(strrep( ...
                    strrep(strrep(strrep( ...
                       DescStates,'BD_1','Blade collective'),...
                                  'BD_2','Blade cosine'),...
                                  'BD_3','Blade sine'),...
                                  'blade 1','blade collective'),...
                                  'blade 2','blade cosine'),...
                                  'blade 3','blade sine'),...    
                                  'Blade1','Blade collective '),...
                                  'Blade2','Blade cosine '),...
                                  'Blade3','Blade sine ');    
    end
    
    for i=1:length( StateDesc )                                                                            
        First = regexp(StateDesc{i},'\(','split');
        Last  = regexp(StateDesc{i},'\)','split');

        if ~isempty(First) && ~isempty(Last) ...
            && length( First{1} ) ~= length(StateDesc{i}) ...
            && length( Last{end} ) ~= length(StateDesc{i})             
            StateDesc{i} = [strtrim(First{1}) Last{end}];
        end
    end
    return
end

%% ------------------------------------------------------------------------
function [ScalingFactor] = getScaleFactors(DescStates, TowerLen, BladeLen)
    
    ScalingFactor = ones(length(DescStates),1);
    
    % look at the state description strings for tower and blade
    % translational dofs:
    for i=1:length(ScalingFactor)
        
            % look for tower translational dofs:
        if ~isempty(strfind(DescStates{i},'tower')) || ...
           ~isempty(strfind(DescStates{i},'Tower')) 
           
            ScalingFactor ( i ) = 1/TowerLen;
            
            % look for blade dofs:
        elseif ~isempty(strfind(DescStates{i},'blade')) || ...
               ~isempty(strfind(DescStates{i},'Blade'))
           
           if isempty(strfind(DescStates{i},'rotational')) % make sure this isn't a rotational dof from BeamDyn
               
               ScalingFactor( i ) =  1/BladeLen;
               
           end
        end
        
    end

end

%% ------------------------------------------------------------------------
function [VTK] = GetDataForVTK(mbc_data, ModesMagnitude, maxCol, ScalingFactor, SortedFreqIndx)

    %% Get data required for VTK visualization:
    % % % mbc_data.eigSol.EigenVects_q2_dot(:,SortedFreqIndx)
    % % % mbc_data.eigSol.EigenVects(:,SortedFreqIndx)       

    ModesMagnitude_q2_dot = mbc_data.eigSol.MagnitudeModes_q2_dot * diag(1./maxCol); % scale the columns
    ModesMagnitude_q2_q1  = diag(1./ScalingFactor) * ModesMagnitude;

    x_eig_magnitude = [ModesMagnitude_q2_q1(1:mbc_data.ndof2,:)  
                       ModesMagnitude_q2_dot(:,:) 
                       ModesMagnitude_q2_q1((mbc_data.ndof2+1):end,:)];

    x_eig_phase     = [mbc_data.eigSol.PhaseModes_deg(1:mbc_data.ndof2,:)  
                       mbc_data.eigSol.PhaseModes_deg_q2_dot(:,:) 
                       mbc_data.eigSol.PhaseModes_deg((mbc_data.ndof2+1):end,:)] * pi/180;

    %put these in order of natural frequency:
    VTK.NaturalFreq_Hz = mbc_data.eigSol.NaturalFreqs_Hz(SortedFreqIndx);
    VTK.DampedFreq_Hz  = mbc_data.eigSol.DampedFreqs_Hz( SortedFreqIndx);
    VTK.DampingRatio   = mbc_data.eigSol.DampRatios(     SortedFreqIndx);

    x_eig_magnitude    = x_eig_magnitude(:, SortedFreqIndx);
    x_eig_phase        = x_eig_phase(    :, SortedFreqIndx);

    if (mbc_data.performedTransformation)
        nb = 3;
        x_eig = x_eig_magnitude .* exp(1i*x_eig_phase); % convert back to imaginary number

        VTK.x_eig = repmat( x_eig, 1,1, length(mbc_data.Azimuth) );

        % inverse MBC3 (Eq. 4, to move from collective, sine, cosine back to blade 1, blade 2, blade 3):
        dof1_offset = mbc_data.ndof2*2;

        for iazim=1:length(mbc_data.Azimuth)
            % compute MBC3 transformation matrices
            az = mbc_data.Azimuth(iazim)*pi/180.0 + 2*pi/nb* (0:(nb-1)) ; % Eq. 1, azimuth in radians
            tt = [ones(3,1), cos(az(:)), sin(az(:))];        % Eq. 9, t_tilde

            for i2 = 1:size(mbc_data.RotTripletIndicesStates2,1)
                    %q2:
                VTK.x_eig(mbc_data.RotTripletIndicesStates2(i2,:),:,iazim) = tt * x_eig(mbc_data.RotTripletIndicesStates2(i2,:),:);
                    %q2_dot:
                VTK.x_eig(mbc_data.RotTripletIndicesStates2(i2,:)+mbc_data.ndof2,:,iazim) = tt * x_eig(mbc_data.RotTripletIndicesStates2(i2,:)+mbc_data.ndof2,:);
            end

            for i1 = 1:length(mbc_data.RotTripletIndicesStates1)
                    %q1:
                VTK.x_eig(mbc_data.RotTripletIndicesStates1(i1,:)+dof1_offset,:,iazim) = tt * x_eig(mbc_data.RotTripletIndicesStates1(i1,:)+dof1_offset,:);
            end

        end

        % put this in order states are stored in FAST
        VTK.x_eig = VTK.x_eig(mbc_data.StateOrderingIndx,:,:);
        
        VTK.x_eig_magnitude = abs(VTK.x_eig);
        VTK.x_eig_phase     = angle(VTK.x_eig);
    else    
        % put this in order states are stored in FAST
        VTK.x_eig_magnitude = x_eig_magnitude(mbc_data.StateOrderingIndx,:);
        VTK.x_eig_phase     = x_eig_phase(mbc_data.StateOrderingIndx,:);
    end

    VTK.x_desc = mbc_data.DescStates(mbc_data.StateOrderingIndx);
    
return;
end

%% ------------------------------------------------------------------------
function WriteDataForVTK(VTK, ModeVizFileName)

    fileFmt = 'float64'; %8-byte real numbers

    fid = fopen(ModeVizFileName,'w');
    if fid < 0
        error(['Invalid file: ' ModeVizFileName])
        return
    end
    [nStates, nModes, NLinTimes] = size(VTK.x_eig_magnitude);
   
    fwrite(fid, 1,        'int16' ); % write a file identifier in case we ever change this format
    fwrite(fid, nModes,   'int16' ); % number of modes (for easier file reading)
    fwrite(fid, nStates,  'int16' ); % number of states (for easier file reading)
    fwrite(fid, NLinTimes,'int16' ); % number of azimuths (i.e., LinTimes) (for easier file reading)

    % these are output, but not used in the FAST visualization algorithm
    fwrite(fid, VTK.NaturalFreq_Hz, fileFmt);
    fwrite(fid, VTK.DampingRatio,   fileFmt);
    
    fwrite(fid, VTK.DampedFreq_Hz,  fileFmt);
   
        % I am going to reorder these by mode (so if reading sequentially, 
        % we don't have to read every mode)
        
    for iMode = 1:nModes
        fwrite(fid, VTK.x_eig_magnitude(:,iMode,:), fileFmt);
        fwrite(fid, VTK.x_eig_phase(    :,iMode,:), fileFmt);
    end
   
return;
end