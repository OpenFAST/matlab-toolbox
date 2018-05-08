function [dat, data, columnTitles, columnUnits] = loadNodalData(fileName)
% This function reads a FAST file (either text or binary format) and
% stores the data in a data structure with channel names as fields; each
% channel has two fields:
%   dat.channelName.timeSer(time,nodeNumber,bladeNumber)
%        - a matrix 
% dat.channelName.unit contains the name of the units as a string
%
% ----------------
% N.B.
% 1 - "Azimuth" from ElastoDyn will get overwritten with "B1Azimuth" from
%      AeroDyn
% ----------------

    if length(fileName) > 4 && strcmpi( fileName((end-4):end),'.outb' )
        [data, columnTitles, columnUnits] =  ReadFASTbinary(fileName);
    else
        [data, columnTitles, columnUnits] = ReadFASTtext(fileName);
    end    
    
    % 1 = Blade structural distances; 2 = Blade aero distances;
    % 3 = Blade structural distances; 4 = Blade aero distances;    
    NumDistances.Blade_Structure = 0;
    NumDistances.Blade_Aero      = 0;
    NumDistances.Tower_Structure = 0;
    NumDistances.Tower_Aero      = 0;
    
    Distances.Blade_Structure = [];
    Distances.Blade_Aero      = [];
    Distances.Tower_Structure = [];
    Distances.Tower_Aero      = [];
    
    for i=1:length(columnTitles)
        
        channelName = lower(columnTitles{i});        
        channelType = [];
        
        % determine if this is a blade channel, and if so, which blade number:
        if strncmpi(channelName,'b',1)
            bladeNum = str2double( channelName(2:2) );
            if isnan(bladeNum)
                bladeNum = 1;
            else
                channelType = 'Blade_Structure';
                channelName = channelName(3:end);
            end
        elseif strncmpi(channelName,'aerob',5)
            bladeNum = str2double( channelName(6:6) );
            if isnan(bladeNum)
                bladeNum = 1;
            else
                channelType = 'Blade_Aero';
                channelName = channelName(7:end);
            end
        elseif strncmpi(channelName,'twr_',4)
            bladeNum=1;
            channelType = 'Tower_Structure';
            channelName = channelName(5:end);
        elseif strncmpi(channelName,'aerotwr_',8)
            bladeNum=1;
            channelType = 'Tower_Aero';
            channelName = channelName(5:end);
        else
            bladeNum = 1;
        end
        
        if strncmpi(channelName,'_',1)
            channelName = channelName(2:end);
        end
        
        
        % if this is a node, let's get the node number:
        if strncmpi(channelName,'n',1)            
            nodeNum = str2double( channelName(2:2) );
            if isnan(nodeNum)
                nodeNum = 1;
            else
                nodeNum2 = str2double( channelName(2:3) );
                if isnan(nodeNum2)
                    channelName = [channelName(3:end) '_Nd'];
                else
                    nodeNum3 = str2double( channelName(2:4) );
                    if isnan(nodeNum3)
                        nodeNum = nodeNum2;
                        channelName = channelName(4:end);
                    else
                        nodeNum = nodeNum3;
                        channelName = channelName(5:end);
                    end
                end
            end
            
        elseif strncmpi(channelName,'z',1)            
            dist = str2double( channelName(2:7) );
            
            if isnan(nodeNum)
                nodeNum = 1;
            else
                if isempty(Distances.(channelType)) || ~any(dist == Distances.(channelType))
                    NumDistances.(channelType) = NumDistances.(channelType) + 1;
                    nodeNum = NumDistances.(channelType);
                    Distances.(channelType)(nodeNum) = dist;
                else
                    nodeNum = find(dist==Distances.(channelType),1);                    
                end
                channelName = [channelType '_' channelName(9:end)];
            end
        else            
            nodeNum = 1;
        end
        
        dat.(channelName).timeSer(:,nodeNum,bladeNum) = data(:,i);
        dat.(channelName).unit = columnUnits{i};
        
        k=strfind(lower(columnTitles{i}), channelName);
        if (isempty(k))            
            k=strfind(lower(columnTitles{i}), strrep(channelName,[channelType '_'], ''));
        end
        dat.(channelName).name = columnTitles{i}(k(1):end);
    end

    channelTypes = fieldnames(Distances);
    for i=1:length(channelTypes)
        if NumDistances.(channelTypes{i}) > 1
            dat.nodeDistances.(channelTypes{i}) = Distances.(channelTypes{i})/1000;
        end
    end
    
    return

end
