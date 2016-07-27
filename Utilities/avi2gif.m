function avi2gif(aviFileName, gifFileName, StartIndx)
% (c) 2016 Bonnie Jonkman, National Renewable Energy Laboratory
%
% This function converts an avi file to a continuous-loop, animated gif.
%
% avi2gif(aviFileName, gifFileName) creates an animated gif called
% gifFileName from the avi file named aviFileName.
%
% avi2gif(aviFileName, gifFileName, StartIndx) creates an animated gif called
% gifFileName from the avi file named aviFileName, omitting all the frames
% before StartIndx.
%
%
% Required inputs:
%   aviFileName - the full name (including path [if necessary] and
%                 extension) of the avi file
%   gifFileName - the name of the gif file to create. avi2gif will add
%                 the ".gif" extension if it isn't already specified
% Optional inputs:
%   StartIndx   - the first frame to add to the gif; if omitted, default is
%                 1 (the first frame from the avi file)
%--------------------------------------------------------------------------

        % optional input; default is 1
    if nargin < 3
        StartIndx = 1;
    end

        % make sure gif file name ends in .gif; add a new extension if
        % it doesn't:
    [~, ~, ext] = fileparts(gifFileName);
    if ~strcmpi(ext,'.gif')
        gifFileName = [gifFileName '.gif'];
    end

        % read the avi file:
    xyloObj = VideoReader(aviFileName);

    vidWidth = xyloObj.Width;
    vidHeight = xyloObj.Height;
    dt = 1/xyloObj.FrameRate;

    ThisFrame = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

    k = 1;
    AppendFile = false;
    while hasFrame(xyloObj)
        ThisFrame.cdata = readFrame(xyloObj);

        im = frame2im( ThisFrame );
        [A,map] = rgb2ind(im,256);

%         tc = double( A(1) ); %,'TransparentColor',tc
        if k == StartIndx
            AppendFile = true;
            imwrite(A,map,gifFileName,'gif','LoopCount',Inf,     'DelayTime',dt); %continuous loop
        elseif AppendFile
            imwrite(A,map,gifFileName,'gif','WriteMode','append','DelayTime',dt);
        end    

        k = k+1;

    end

end % end of function