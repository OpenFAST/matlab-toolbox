function [Channels, ChanName, ChanUnit, FileID] = ReadFASTbinary(FileName)
%[Channels, ChannelNames, ChannelUnits] = ReadFASTbinary(FileName)
% Author: Bonnie Jonkman, National Renewable Energy Laboratory
% (c) 2012, National Renewable Energy Laboratory
%
%  Edited for FAST v7.02.00b-bjj  22-Oct-2012
%
% Input:
%  FileName      - string: contains file name to open
%
% Output:
%  Channels      - 2-D array: dimension 1 is time, dimension 2 is channel 
%  ChanName      - cell array containing names of output channels
%  ChanUnit      - cell array containing unit names of output channels
%  FileID        - constant that determines if the time is stored in the
%                  output, indicating possible non-constant time step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
LenName = 10;  % number of characters per channel name
LenUnit = 10;  % number of characters per unit name

FileFmtID = struct( 'WithTime',   1, ...               % File identifiers used in FAST
                    'WithoutTime',2 );

fid  = fopen( FileName );
if fid > 0
    %----------------------------        
    % get the header information
    %----------------------------
    
    FileID       = fread( fid, 1, 'int16');             % FAST output file format, INT(2)

    NumOutChans  = fread( fid, 1, 'int32');             % The number of output channels, INT(4)
    NT           = fread( fid, 1, 'int32');             % The number of time steps, INT(4)

    if FileID == FileFmtID.WithTime
        TimeScl  = fread( fid, 1, 'float64');           % The time slopes for scaling, REAL(8)
        TimeOff  = fread( fid, 1, 'float64');           % The time offsets for scaling, REAL(8)
    else
        TimeOut1 = fread( fid, 1, 'float64');           % The first time in the time series, REAL(8)
        TimeIncr = fread( fid, 1, 'float64');           % The time increment, REAL(8)
    end
    
    ColScl       = fread( fid, NumOutChans, 'float32'); % The channel slopes for scaling, REAL(4)
    ColOff       = fread( fid, NumOutChans, 'float32'); % The channel offsets for scaling, REAL(4)

    LenDesc      = fread( fid, 1,           'int32' );  % The number of characters in the description string, INT(4)
    DescStrASCII = fread( fid, LenDesc,     'uint8' );  % DescStr converted to ASCII
    DescStr      = char( DescStrASCII' );                     
    
    
    ChanName = cell(NumOutChans+1,1);                   % initialize the ChanName cell array
    for iChan = 1:NumOutChans+1 
        ChanNameASCII = fread( fid, LenName, 'uint8' ); % ChanName converted to numeric ASCII
        ChanName{iChan}= strtrim( char(ChanNameASCII') );
    end
    
    ChanUnit = cell(NumOutChans+1,1);                   % initialize the ChanUnit cell array
    for iChan = 1:NumOutChans+1
        ChanUnitASCII = fread( fid, LenUnit, 'uint8' ); % ChanUnit converted to numeric ASCII
        ChanUnit{iChan}= strtrim( char(ChanUnitASCII') );
    end            

    disp( ['Reading from the file ' FileName ' with heading: ' ] );
    disp( ['   "' DescStr '".' ] ) ;
    
    %-------------------------        
    % get the channel time series
    %-------------------------

    nPts        = NT*NumOutChans;           % number of data points in the file   
    Channels    = zeros(NT,NumOutChans+1);  % output channels (including time in column 1)
    
    if FileID == FileFmtID.WithTime
        [PackedTime cnt] = fread( fid, NT, 'int32' ); % read the time data
        if ( cnt < NT ) 
            fclose(fid);
            error(['Could not read entire ' FileName ' file: read ' num2str( cnt ) ' of ' num2str( NT ) ' time values.']);
        end
    end
        
        
    [PackedData cnt] = fread( fid, nPts, 'int16' ); % read the channel data
    if ( cnt < nPts ) 
        fclose(fid);
        error(['Could not read entire ' FileName ' file: read ' num2str( cnt ) ' of ' num2str( nPts ) ' values.']);
    end
    
    fclose(fid);
    
    %-------------------------
    % Scale the packed binary to real data
    %-------------------------
    
    ip = 1;
    for it = 1:NT
        for ic = 1:NumOutChans
            Channels(it,ic+1) = ( PackedData(ip) - ColOff(ic) ) / ColScl(ic) ;
            ip = ip + 1;
        end % ic       
    end %it

    if FileID == FileFmtID.WithTime
        Channels(:,1) = ( PackedTime - TimeOff ) ./ TimeScl;
    else
        Channels(:,1) = TimeOut1 + TimeIncr*(0:(NT-1))';
    end
    
else
    error(['Could not open the FAST binary file: ' FileName]) ;
end

return;

