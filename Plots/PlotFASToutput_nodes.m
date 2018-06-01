function [outData_struct]=PlotFASToutput_nodes(FASTfiles) %,FASTfilesDesc,ReferenceFile,Channels,ShowLegend,CustomHdr,PlotPSDs,OnePlot)
if ~iscell(FASTfiles)
    FASTfiles = {FASTfiles};
end

nf = 1;

[outData_struct] = loadNodalData(FASTfiles{nf});


n = fieldnames(outData_struct);


%%
np = 0;
for i=1:length(n)
    if strcmp( n{i}, 'time' ) || strcmp( n{i}, 'nodeDistances' )
        continue;
    end
    
    if size(outData_struct.(n{i}).timeSer,3)==1 || size(outData_struct.(n{i}).timeSer,2)==1 % one blade or one node
        np = getNextSubPlot(np);
    
%      'displayname',[FASTfiles{nf} ': blade ' num2str(outData_struct.(n{i}),3)) ', node ' num2str(size(outData_struct.(n{i}),2))] );
        numLines = numel( outData_struct.(n{i}).timeSer(1,:,:) );
        set(gca,'ColorOrder',jet(numLines));
        
        plot(outData_struct.time.timeSer, squeeze( outData_struct.(n{i}).timeSer ),':.','displayname',FASTfiles{nf} );
        
        xlabel([outData_struct.time.name ' ' outData_struct.time.unit]);
        ylabel([outData_struct.(n{i}).name ' ' outData_struct.(n{i}).unit], 'interpreter','none');
        setLabels(outData_struct, n{i});
        
    else % multiple blades

        
        for nb=1:size(outData_struct.(n{i}).timeSer,3)
            np = getNextSubPlot(np);

            if ~isempty( strfind(n{i}, 'Blade_Aero_') ) 
                X = outData_struct.nodeDistances.Blade_Aero;
                x_label = 'Blade node distance (m)';
            else
                X = 1:size(outData_struct.(n{i}).timeSer(:,:,nb),2);
                x_label = 'node number (-)';
            end
            mesh( X, ...
                 outData_struct.time.timeSer, ...
                 outData_struct.(n{i}).timeSer(:,:,nb), ...
                 'displayname',FASTfiles{nf});
            
            view(3)
            setLabels(outData_struct, n{i});
            xlabel(x_label);
            ylabel([outData_struct.time.name ' ' outData_struct.time.unit]);
            zlabel([outData_struct.(n{i}).name ' ' outData_struct.(n{i}).unit], 'interpreter','none');
        end
    end
    %legend show
end




end 

%%
function [np] = getNextSubPlot(np)
nr = 2; % number of rows on figure
nc = 3; % number of columns on figure


    np = mod(np,nr*nc)+1;
    if np==1
        figure;
    end
    subplot(nr,nc,np)
    hold on;

    return;
end

%%
function [] = setLabels(outData_struct, fieldName)

    title(fieldName,'interpreter','none')
    grid on


end
