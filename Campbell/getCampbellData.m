function CampbellData = getCampbellData(FastFiles, WindSpeed)
% Returns a cell-array of "CampbellData" by Running MBC on FAST linearization files 
%
% INPUTS:
%  - FastFiles: cell-array of strings containing path to ".fst" files (must exist)
%               These .fst files should be the ones that were used to produce 
%               the linearization files.
%               Linearization files fill be looked for based on these filenames.
%
% OPTIONAL INPUTS:
%  - WindSpeed: array of same size than FastFiles, containing wind speed values 
%
% OUTPUTS:
%  - CampbellData: cell-array of "CampbellData", main structure used for the campbell scripts
%       Each cell contains structure with the following fields:
%          - NaturalFreq_Hz 
%          - DampingRatio  
%        Potential fields:
%          - RotSpeed_rpm          
%          - WindSpeed
%
if ~exist('WindSpeed','var'); WindSpeed=NaN(1,length(FastFiles)); end

%% --- Running MBC on all cases
nOP = length(FastFiles);
CampbellData = cell(nOP,1);
for iOP = 1:nOP
    fst = FastFiles{iOP} ;
    % -- Reading data from fst file
    FP = FAST2Matlab(fst,2); %FP are Fast Parameters, specify 2 lines of header (FAST 8)
    [baseDir, baseName, ext ] = fileparts(fst);
    if strcmp(baseDir,filesep)
        baseDir = ['.' filesep];
    end
    CompAero     = GetFASTPar(FP, 'CompAero');
    [EP, EDFile] = GetFASTPar_Subfile(FP, 'EDFile', baseDir, baseDir);
    TipRad       = GetFASTPar(EP, 'TipRad');
    HubRad       = GetFASTPar(EP, 'HubRad');
    BladeLen     = TipRad - HubRad;
    TowerLen     = GetFASTPar(EP, 'TowerHt');

    % --- Finding *.lin files 
    [fdir, fbase,~] = fileparts(fst);
    fullbase = strrep(strrep([fdir '/'  fbase], '//','/'),'\','/');
    pattern    = sprintf('%s.*.lin',fullbase);
    fprintf('Lin. files: %s ',pattern);
    files      = dir(pattern);
    nPerPeriod = length(files);
    FileNames  = cell(1,nPerPeriod);
    for iT = 1:nPerPeriod
        FileNames{iT}=sprintf('%s.%d.lin',fullbase,iT);
        if exist(FileNames{iT}, 'file')~=2
            nPerPeriod=iT-1;
            disp(['warning::' sprintf('Linearization data %d missing for base %s',iT, base)]);
            break
        end
    end
    fprintf('(%d)\n',nPerPeriod);
    if nPerPeriod<=0
        disp(['warning::' sprintf('No linearization data for base %s',base)]);
        continue
    end
    FileNames=FileNames(1:nPerPeriod);

    % --- Find checkpoints files *.chkp
    chkpFile = [fullbase '.ModeShapeVTK.chkp'];
    if exist(chkpFile, 'file')
        fprintf('Chkp file:  %s\n',chkpFile);
        ModesVizName = [fullbase '.ModeShapeVTK.postmbc'];
    else
        ModesVizName = '';
    end

    % --- Performing MBC on existing lin files
    if length(ModesVizName)>0
        [mbc_data, ~, ~] = fx_mbc3( FileNames, ModesVizName );
    else
        [mbc_data, ~, ~] = fx_mbc3( FileNames );
    end
    [CampbellData{iOP}] = campbell_diagram_data(mbc_data, BladeLen, TowerLen);
    CampbellData{iOP}.WindSpeed  = WindSpeed(iOP) ;
    CampbellData{iOP}.CompAero  = CompAero; 
end


%% Sort
% if all(~isnan(WindSpeed))
%     [~,I] = sort(WindSpeed);
%     CampbellData=CampbellData(I);
% end

