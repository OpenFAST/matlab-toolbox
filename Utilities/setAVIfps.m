function setAVIfps(aviName, fps)
%% setAVIfps(aviName, fps)
% This function takes an avi file, and copies it to a new file using
% the given frame rate. This is a work-around for ParaView ignoring
% frame rates when saving animation files.

if nargin < 2
    fps = 15;
end

if ~exist(aviName,'file')
    return
end

v = VideoReader(aviName);
vw = VideoWriter( strrep(aviName,'.avi', '.2.avi') );

vw.FrameRate = fps;

open(vw);
while hasFrame(v)
    frame = readFrame(v);
    writeVideo(vw,frame);
end

close(vw);
