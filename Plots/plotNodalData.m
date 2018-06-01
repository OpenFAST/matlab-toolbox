function [np] = plotNodalData(dat, fieldName, np, nr, nc)
% This function plots data stored in dat.fieldName, which was
% loaded from a data structure from function loadNodalData.
%
% required inputs:
%   dat       - data structure from loadNodalData
%   fieldName - string that contains the name of the field to plot
%
% optional inputs (if not all are input, all will be overwritten with default 
%                  of one plot per figure):
%    np       - number of last subplot used in the figure
%    nr       - number of rows of subplots in the figure (default = 1)
%    nc       - number of columns of subplots in the figure (default = 1)
%
% output:
%    np       - number of current subplot used in the figure
%
%------------------------------------------
% Use this code to plot all data from a FAST simulation on figures with
% two rows and two columns of subplots:
%
%       [ThisData] = loadNodalData(fileName);
%       n = fieldnames(ThisData);
% 
%       np=0;
%       for i=1:length(n)
%           [np] = plotNodalData(ThisData, n{i}, np, 2, 2);
%       end
%------------------------------------------


% default to one plot per figure here
if nargin < 5
    np = 0;
    nr = 1;
    nc = 1;
end

firstNode = 1; % first node to plot on mesh plots
lastNode = 0; % how many nodes to remove from the last one plotted on mesh plot
%t = dat.time.timeSer>5;

% firstNode = 2;  % skip first node
% lastNode  = -1; % skip last node
% t = dat.time.timeSer<99999;

    if size(dat.(fieldName).timeSer,2)==1 %plot one time series, possibly per blade on one plot
        [np] = nextFigure(np,nr,nc);
        
        plot(dat.time.timeSer,squeeze(dat.(fieldName).timeSer),':.'); 
        xlabel(['time ' dat.time.unit]);
        ylabel([ fieldName ' ' dat.(fieldName).unit]);
        title(fieldName)
        grid on
    else
        nodes = firstNode:( size(dat.(fieldName).timeSer,2) + lastNode );
        
        for ic=1:size(dat.(fieldName).timeSer,3) % plot each node on mesh, each blade on separate plot
            [np] = nextFigure(np,nr,nc);

            mesh(nodes, dat.time.timeSer, dat.(fieldName).timeSer(:,nodes,ic));            
            title([fieldName ', blade ' num2str(ic)]);
            view(3)
            grid on
            xlabel('node number')
            ylabel(['time ' dat.time.unit])
            zlabel([ fieldName ' ' dat.(fieldName).unit]);
        end
    end

return
end

function [np] = nextFigure(np,nr,nc)

    np = mod(np,nr*nc)+1;
    if np==1
        figure;
    end
    subplot(nr,nc,np)

end