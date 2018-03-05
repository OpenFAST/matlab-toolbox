function [NormalizedVelocity, Header, y, z] = readfile_WND_raw(FileName)
%[NormalizedVelocity, Header, y, z] = readfile_WND_raw(FileName)
% Input:
% FileName       - string, containing file name to open (.wnd extension is optional)
%
% Output:
%  NormalizedVelocity      - 4-D vector: time, velocity component, iy, iz 
%  Header                  - structure containing binary file header information
%  y                       - 1-D vector: horizontal locations y(iy)
%  z                       - 1-D vector: vertical locations z(iz)

%%
len    = length(FileName);
ending = FileName(len-3:len);

if strcmpi( ending, '.wnd' )
    FileName = FileName(1:len-4);
end

%-------------------------------------------------------------

%% -----------------------------------------
%  READ THE HEADER OF THE BINARY FILE 
%  ----------------------------------------- 
fid_wnd   = fopen( [ FileName '.wnd' ] );
if ( fid_wnd <= 0 )
   error( 'Wind file could not be opened.' );
end

nffc  = fread( fid_wnd, 1, 'int16' );                     % number of components

if nffc ~= -99  % AN OLD-STYLE AERODYN WIND FILE
    ConvFact = 1.0; %results in meters and seconds
    
    Header.dz      = fread( fid_wnd, 1, 'int16' );                  % delta z in mm
    Header.dy      = fread( fid_wnd, 1, 'int16' );                  % delta y in mm
    Header.dx      = fread( fid_wnd, 1, 'int16' );                  % delta x (actually t in this case) in mm
    Header.nt      = fread( fid_wnd, 1, 'int16' );                  % half number of time steps
    Header.MFFWS   = fread( fid_wnd, 1, 'int16' );                  % 10 times mean FF wind speed, should be equal to MWS
                     fread( fid_wnd, 5, 'int16' );                  % unnecessary lines
    Header.nz      = fread( fid_wnd, 1, 'int16' );                  % 1000 times number of points in vertical direction, max 32
    Header.ny      = fread( fid_wnd, 1, 'int16' );                  % 1000 times the number of points in horizontal direction, max 32
                     fread( fid_wnd, 3*(-nffc-1), 'int16' );

        % convert the integers to real numbers 
    Header.nffc     = -nffc;
    Header.dz       = 0.001*ConvFact*Header.dz;
    Header.dy       = 0.001*ConvFact*Header.dy;
    Header.dx       = 0.001*ConvFact*Header.dx;
    Header.MFFWS    = 0.1*ConvFact*Header.MFFWS;
    Header.nz       = fix( mod(Header.nz,2^16) / 1000 );            % the mod 2^16 is a work around for somewhat larger grids
    Header.ny       = fix( mod(Header.ny,2^16) / 1000 );            % the mod 2^16 is a work around for somewhat larger grids
        
else %== -99, THE NEWER-STYLE AERODYN WIND FILE
    fc       = fread( fid_wnd, 1, 'int16' );              % should be 4 to allow turbulence intensity to be stored in the header

    if fc == 4
        Header.nffc     = fread( fid_wnd, 1, 'int32' );             % number of components (should be 3)
        Header.lat      = fread( fid_wnd, 1, 'float32' );           % latitude (deg)
        Header.z0       = fread( fid_wnd, 1, 'float32' );           % Roughness length (m)
        Header.zOffset  = fread( fid_wnd, 1, 'float32' );           % Reference height (m) = Z(1) + GridHeight / 2.0
        Header.TI_U     = fread( fid_wnd, 1, 'float32' );           % Turbulence Intensity of u component (%)
        Header.TI_V     = fread( fid_wnd, 1, 'float32' );           % Turbulence Intensity of v component (%)
        Header.TI_W     = fread( fid_wnd, 1, 'float32' );           % Turbulence Intensity of w component (%)
    else
        if fc > 2
            Header.nffc = 3;
        else
            Header.nffc = 1;
        end
        Header.TI_U  = 1;
        Header.TI_V  = 1;
        Header.TI_W  = 1;
        
        if fc == 8 ... %MANN model 
          || fc == 7 % General Kaimal      
            Header.HeadRec = fread(fid_wnd,1,'int32');
            Header.nffc    = fread(fid_wnd,1,'int32');  %nffc?
        end
        
    end %fc == 4
     %%   
    Header.dz       = fread( fid_wnd, 1, 'float32' );            % delta z in m 
    Header.dy       = fread( fid_wnd, 1, 'float32' );            % delta y in m
    Header.dx       = fread( fid_wnd, 1, 'float32' );            % delta x in m           
    Header.nt       = fread( fid_wnd, 1, 'int32' );              % half the number of time steps
    Header.MFFWS    = fread( fid_wnd, 1, 'float32');             % mean full-field wind speed

                      fread( fid_wnd, 3, 'float32' );            % zLu, yLu, xLu: unused variables (for BLADED)
                      fread( fid_wnd, 2, 'int32' );              % unused variables (for BLADED) [unused integer, random seed]
    Header.nz       = fread( fid_wnd, 1, 'int32' );              % number of points in vertical direction
    Header.ny       = fread( fid_wnd, 1, 'int32' );              % number of points in horizontal direction
    if (Header.nffc==3)
               fread( fid_wnd, 2*Header.nffc, 'int32' );     % other length scales: unused variables (for BLADED)                
    end 
    
    if fc == 7
        Header.CohDec = fread(fid_wnd,1,'float32');
        Header.CohLc  = fread(fid_wnd,1,'float32');
    elseif fc == 8        % MANN model
        Header.gamma  = fread(fid_wnd,1,'float32');               % MANN model shear parameter
        Header.Scale  = fread(fid_wnd,1,'float32');               % MANN model scale length
                        fread(fid_wnd,4,'float32');
                        fread(fid_wnd,3,'int32');
                        fread(fid_wnd,2,'float32');
                        fread(fid_wnd,3,'int32');
                        fread(fid_wnd,2,'float32');
    end
            
end % old or new bladed styles

Header.nt     = max([Header.nt*2,1]);
Header.dt     = Header.dx/Header.MFFWS;

%%

%%
%-----------------------------------------
%READ THE GRID DATA FROM THE BINARY FILE
%-----------------------------------------                   
disp('Reading the grid data...');
NormalizedVelocity = zeros(Header.nt, Header.nffc, Header.ny, Header.nz);

v = fread( fid_wnd, 'int16' );

% NormalizedVelocity2 = reshape(v, [Header.nffc, Header.ny, Header.nz, Header.nt]);

cnt2 = 1;
for it = 1:Header.nt
    for iz = 1:Header.nz
        for iy = 1:Header.ny
            for k=1:Header.nffc
                NormalizedVelocity(it,k,iy,iz) = v(cnt2);
                cnt2 = cnt2 + 1;
            end %for k
        end %iy
    end % iz      
end %it

fclose(fid_wnd);

y    = (0:Header.ny-1)*Header.dy - Header.dy*(Header.ny-1)/2;
z    = (0:Header.nz-1)*Header.dz - Header.dz*(Header.nz-1)/2;

disp('Finished.');
disp('');

%%

return;