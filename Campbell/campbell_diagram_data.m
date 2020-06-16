function [CampbellData] = campbell_diagram_data(mbc_data, BladeLen, TowerLen, xlsFileName)
%%
% inputs: 
% -   mbc_data is the output data from mbc3 containing DescStates and
%     eigSol fields (as well as ndof2 & performedTrasformation)
% -   BladeLen and TowerLen are the lengths (in meters) of the blade and  
%     the tower, respectively, and are used for scaling the magnitudes of 
%     the rows (for consistent units)
%
outputXLSfile = nargin > 3 && ~isempty(xlsFileName);
usePercent = false;
%%
% mbc_data.eigSol = eiganalysis(mbc_data.AvgA);
ndof = mbc_data.ndof2 + mbc_data.ndof1; %size(mbc_data.AvgA,1)/2;          % number of translational states
nModes = length(mbc_data.eigSol.Evals);

%% change the state descriptions (add collective, sine, cosine, etc) and remove the last ndof of them (second order derivatives)
DescStates = PrettyStateDescriptions(mbc_data.DescStates, mbc_data.ndof2, mbc_data.performedTransformation);

%% store indices of max mode for state and to order natural frequencies
[~, StatesMaxMode] = max(mbc_data.eigSol.MagnitudeModes,[],2); % find which mode has the maximum value for each state (max of each row before scaling)
[~, SortedFreqIndx] = sort(mbc_data.eigSol.NaturalFreqs_Hz);

if BladeLen~=0 || TowerLen~=0
    %% get the scaling factors for the mode rows
    ScalingFactor = getScaleFactors(DescStates, TowerLen, BladeLen);

    %% scale the magnitude of the modes by ScalingFactor (for consistent units)
    %  and then scale the columns so that their maximum is 1

    ModesMagnitude = diag(ScalingFactor) * mbc_data.eigSol.MagnitudeModes; % scale the rows
    
    CampbellData.ScalingFactor = ScalingFactor;
else 
    ModesMagnitude = mbc_data.eigSol.MagnitudeModes;
end

if usePercent
    scaleCol = sum( ModesMagnitude ) ./ 100; % find the sum of the column, and multiply by 100 (divide here) to get a percentage
else
    scaleCol = max(ModesMagnitude); % find the maximum value in the column, so the first element has value of 1
end

ModesMagnitude = ModesMagnitude * diag(1./scaleCol); % scale the columns        


%%
CampbellData.NaturalFreq_Hz = mbc_data.eigSol.NaturalFreqs_Hz(SortedFreqIndx);
CampbellData.DampingRatio   = mbc_data.eigSol.DampRatios(     SortedFreqIndx);
CampbellData.RotSpeed_rpm   = mbc_data.RotSpeed_rpm;
if isfield(mbc_data,'WindSpeed')
    CampbellData.WindSpeed  = mbc_data.WindSpeed;
end

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
        % one (whose value == 1 or is the largest %), we'll stick a negative value on the magnitude:
    Phase = mod(Phase, 360);
    
    CampbellData.Modes{i}.PhaseDiff = mod( Phase - Phase(1), 360); % difference in range [0, 360)
    PhaseIndx = CampbellData.Modes{i}.PhaseDiff > 180;
    CampbellData.Modes{i}.PhaseDiff(PhaseIndx) = CampbellData.Modes{i}.PhaseDiff(PhaseIndx) - 360;   % move to range (-180, 180]
    
    if ~usePercent
        PhaseIndx = CampbellData.Modes{i}.PhaseDiff > 90;
        CampbellData.Modes{i}.MagnitudePhase(PhaseIndx) = -1*CampbellData.Modes{i}.MagnitudePhase(PhaseIndx);
        CampbellData.Modes{i}.PhaseDiff(PhaseIndx) = CampbellData.Modes{i}.PhaseDiff(PhaseIndx) - 180;

        PhaseIndx = CampbellData.Modes{i}.PhaseDiff <= -90;
        CampbellData.Modes{i}.MagnitudePhase(PhaseIndx) = -1*CampbellData.Modes{i}.MagnitudePhase(PhaseIndx);
        CampbellData.Modes{i}.PhaseDiff(PhaseIndx) = CampbellData.Modes{i}.PhaseDiff(PhaseIndx) + 180;
    end    
    
    CampbellData.Modes{i}.StateHasMaxAtThisMode = false(ndof,1);
    ix = (StatesMaxMode == SortedFreqIndx(i));
    if (any(ix))
        CampbellData.Modes{i}.StateHasMaxAtThisMode(ix(sort_state)) = true;
    end
    
end


%%
CampbellData.nColsPerMode = 5;
CampbellData.ModesTable = cell(ndof+5,CampbellData.nColsPerMode*nModes);

for i=1:nModes
    colStart = (i-1)*CampbellData.nColsPerMode;
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
    if usePercent
        CampbellData.ModesTable(5, colStart+3 ) = {['Mode ' num2str(i) ' contribution (%)']};
    else
        CampbellData.ModesTable(5, colStart+3 ) = {['Mode ' num2str(i) ' signed magnitude']};
    end
    CampbellData.ModesTable(5, colStart+4 ) = {['Mode ' num2str(i) ' phase (deg)']};
    
    CampbellData.ModesTable(6:end,colStart+1) = CampbellData.Modes{i}.DescStates;
    CampbellData.ModesTable(6:end,colStart+2) = num2cell( CampbellData.Modes{i}.StateHasMaxAtThisMode );
    CampbellData.ModesTable(6:end,colStart+3) = num2cell( CampbellData.Modes{i}.MagnitudePhase );
    CampbellData.ModesTable(6:end,colStart+4) = num2cell( CampbellData.Modes{i}.PhaseDiff );
     
end

%% if requested, output this data to a Microsoft Excel spreadsheet file, in a sheet named 'Modes_Data'
if outputXLSfile
    if (exist ("OCTAVE_VERSION", "builtin") > 0)
        warning('xlswrite unavailable with Octave.')
    else
        xlswrite(xlsFileName,CampbellData.ModesTable, 'Modes_Data')
    end
end

return
end

%% ------------------------------------------------------------------------    
function [StateDesc] = PrettyStateDescriptions(DescStates, ndof2, performedTransformation)
    DescStates = DescStates([1:ndof2  (ndof2*2+1):length(DescStates)]);

    if performedTransformation
        StateDesc = strrep(strrep(strrep(strrep(strrep(strrep( ...
                    strrep(strrep(strrep( ...
                    strrep(strrep(strrep( ...
                       DescStates,'BD_1','Blade collective'),...
                                  'BD_2','Blade cosine'),...
                                  'BD_3','Blade sine'),...
                                  'blade 1','blade collective'),...
                                  'blade 2','blade cosine'),...
                                  'blade 3','blade sine'),...    
                                  'Blade1','Blade collective '),...
                                  'Blade2','Blade cosine '),...
                                  'Blade3','Blade sine '), ...    
                                  'PitchBearing1','Pitch bearing collective '),...
                                  'PitchBearing2','Pitch bearing cosine '),...
                                  'PitchBearing3','Pitch bearing sine '); 
    else
        StateDesc = DescStates;
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
        
            % look for blade dofs:
        if ~isempty(strfind(DescStates{i},'blade')) || ...
               ~isempty(strfind(DescStates{i},'Blade'))
           
           if isempty(strfind(DescStates{i},'rotational')) % make sure this isn't a rotational dof from BeamDyn
               
               ScalingFactor( i ) =  1/BladeLen;
               
           end
        end
        
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

%%
