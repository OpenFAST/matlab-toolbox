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
    
    
    for i=1:length(columnTitles)
        channelName = lower(columnTitles{i});
        
        if strncmpi(channelName,'b',1)
            bladeNum = str2double( channelName(2:2) );
            if isnan(bladeNum)
                bladeNum = 1;
            else
                channelName = channelName(3:end);
            end
        else
            bladeNum = 1;
        end
        
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
        else
            nodeNum = 1;
        end
        
        dat.(channelName).timeSer(:,nodeNum,bladeNum) = data(:,i);
        dat.(channelName).unit = columnUnits{i};
    end

    
    return

end
