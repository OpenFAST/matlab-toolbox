% GenStepWindFile
% Function for generating a step wind speed file given:
% 1) A base filename
% 2) An array of windspeeds
% - The generated file will have a name BaseName_Windspeed_MPS.wnd
%
%In:    fileName          -   filename for step file
%       windSpeedArray    -   array of wind speeds in m/s
% 
%In: (OPTIONAL):
%     tstep  -  time length between jump of wind speed. Default:100
%     dt     -  margin determining how steep the step is. Default: 0.1
%     tmax   -  an additional final time. Default: none.
%
%
% Oct. 2018: Emmanuel Branlard: adding tstep, dt and tmax
% June 2011: Paul Fleming, initial version
%            based on code written by Jan-Willem van Wingerden in July 2010


function GenStepWindFile(fileName,windSpeed,tstep,dt,tmax)
% --- Default arguments
if ~exist('tstep','var'); tstep = []; end
if ~exist('dt'   ,'var'); dt    = []; end
if ~exist('tmax' ,'var'); tmax  = []; end
if isempty(tstep); tstep = 100; end
if isempty(dt   ); dt   = 0.1 ; end

fid= fopen(fileName,'w');
fprintf(fid,'!Wind file with step changes in wind speed. \n');
fprintf(fid,'!Time  Wind     Wind	Vert.       Horiz.      Vert.       LinV        Gust \n');
fprintf(fid,'!      Speed    Dir    Speed       Shear		Shear       Shear       Speed \n');
fprintf(fid,'%2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f\n', 0, windSpeed(1), 0, 0,0, 0,0,0);
for i=1:1:length(windSpeed)
    fprintf(fid,'%2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f\n', dt+tstep*(i-1), windSpeed(i), 0, 0,0, 0,0,0);
    fprintf(fid,'%2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f\n',    tstep*i    , windSpeed(i), 0, 0,0, 0,0,0);    
end
if ~isempty(tmax); 
    if tmax>tstep*i
        fprintf(fid,'%2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f\n',    tmax    , windSpeed(i), 0, 0,0, 0,0,0);    
    end
end

fclose(fid);
