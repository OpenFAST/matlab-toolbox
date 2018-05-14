function [] = saveFigureAsPNG( f, outPNGName, ReferenceFile )
% (c) 2016 Bonnie Jonkman @NREL
%
% This routine saves the a figure as a 150-dpi PNG file.
%
% saveFigureAsPNG( f, outPNGName ) saves figure f to a file named
% <outPNGName>.png.
%
% saveFigureAsPNG( f, outPNGName, ReferenceFile ) saves figure f to a file 
% named <path of Reference File>\Plots\<outPNGName>.png
%
% Required input parameters:
%   f               - figure handle, such as returned from gcf()
%   outPNGName      - name of the PNG file to be created
% optional input parameter:
%   ReferenceFile   - name of reference file; figure will be placed in
%                     [ <path of Reference File> \ Plots ]; 

    if (nargin > 2)
        [pathstr] = fileparts(ReferenceFile );
        if isempty(pathstr)
            pathstr = '.';
        end        
    %     OutFilePath = [pathstr filesep 'AllBEMPlots' ];
        OutFilePath = [pathstr filesep 'Plots' ];
    else
        OutFilePath = '.';
    end
    
    OutFileRoot = [OutFilePath filesep outPNGName];
    [~,~,ext] = fileparts(OutFileRoot);
    if strcmpi(ext, '.png')
        OutFile = OutFileRoot;
    else
        OutFile = [OutFileRoot '.png'];
    end
    
        % make sure the directory exists; if not, create it
    if ~exist(OutFilePath, 'dir')
        mkdir( OutFilePath );
    end 
                
    print(f,'-dpng','-r150',OutFile);
    close(f)

    return
end