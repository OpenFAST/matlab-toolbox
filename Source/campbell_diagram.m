mbc_data = eiganalysis(MBC_AvgA);
%%
% user input
BladeLen = 61.5; %m
TowerLen = 87.6; %m
ndof = size(MBC_AvgA,1)/2;
nModes = length(mbc_data.Evals);
%%
ScalingFactor = ones(length(mbc_data.MagnitudeModes),1);
% look at DescStates for tower and blade transational dofs:
ScalingFactor(1:4)   = 1/TowerLen;
% not the rotations
ScalingFactor( 8:6:end) = 1/BladeLen;
ScalingFactor( 9:6:end) = 1/BladeLen;
ScalingFactor(10:6:end) = 1/BladeLen;

% ScalingFactor(8:end) = 1/BladeLen; %ED FIX ME!!!!
%%
ModesMagnitude = diag(ScalingFactor) * mbc_data.MagnitudeModes; % scale the rows
[~,StatesMaxMode] = max(ModesMagnitude,[],2); % find which mode has the maximum value for each state (max of each row before scaling)
maxCol = max(ModesMagnitude,[],1); %maximum value in the column
ModesMagnitude = ModesMagnitude * diag(1./maxCol); % scale the columns

%%
[sorted_NaturalFreq_Hz, indx] = sort(mbc_data.NaturalFreqs_Hz);
%%                  
mbc_data.DescStates = strrep(strrep(strrep(strrep(strrep(strrep(DescStates(1:ndof),'BD_1','Blade collective'),...
                                                                                   'BD_2','Blade cosine'),...
                                                                                   'BD_3','Blade sine'),...
                                                                                   'blade 1','blade collective'),...
                                                                                   'blade 2','blade cosine'),...
                                                                                   'blade 3','blade sine');        
%%
% CampbellData.Modes
CampbellData.Modes = cell(ndof+5,3*nModes);

for i=1:nModes       
    CampbellData.Modes(1, (i-1)*3+1 ) = {'Mode number:'};
    CampbellData.Modes(1, (i-1)*3+2 ) = num2cell(i);
    CampbellData.Modes(1, (i-1)*3+3 ) = {''};

    CampbellData.Modes(2, (i-1)*3+1 ) = {'Natural (undamped) frequency (Hz):'};
    CampbellData.Modes(2, (i-1)*3+2 ) = num2cell( mbc_data.NaturalFreqs_Hz(indx(i)) );

    CampbellData.Modes(3, (i-1)*3+1 ) = {'Damped frequency (Hz):'};
    CampbellData.Modes(3, (i-1)*3+2 ) = num2cell( mbc_data.DampedFreqs_Hz(indx(i)) );

    CampbellData.Modes(4, (i-1)*3+1 ) = {'Damping ratio (-):'};
    CampbellData.Modes(4, (i-1)*3+2 ) = num2cell( mbc_data.DampRatios(indx(i)) );
    
    CampbellData.Modes(5, (i-1)*3+1 ) = {['Mode ' num2str(i) ' state description']};
    CampbellData.Modes(5, (i-1)*3+2 ) = {['State has max at mode ' num2str(i)]};
    CampbellData.Modes(5, (i-1)*3+3 ) = {['Mode ' num2str(i) ' magnitude / phase']};
    
    [~,sort_state] = sort( ModesMagnitude(:,indx(i)), 'descend' );
    CampbellData.Modes(6:end,           (i-1)*3+1) = mbc_data.DescStates(sort_state);

    ix = StatesMaxMode == indx(i);
    CampbellData.Modes(6:end,(i-1)*3+2) = {false};
    if (any(ix))
        CampbellData.Modes(find(ix(sort_state))+5,(i-1)*3+2)  = {true};
    end
    
    PhaseDiff = mod(mbc_data.PhaseModes_deg(sort_state,indx(i)), 360);
    PhaseDiff = mod( PhaseDiff - PhaseDiff(1), 360); 
    PhaseDiff(PhaseDiff > 180) = PhaseDiff(PhaseDiff > 180) - 360;
     
    thisMode = ModesMagnitude(sort_state,indx(i));  
    thisMode(abs(PhaseDiff)>90) = -1*thisMode(abs(PhaseDiff)>90);
    CampbellData.Modes(6:end,(i-1)*3+3) = num2cell(thisMode);
end

% vertcat( CampbellData.RowDesc, ...
%          num2cell(CampbellData.table) );
