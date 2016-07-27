function [OutListAry, CommentAry] = GetOutListVars(OutList, OutListComments)
%[OutListAry, CommentAry] = getOutListVars(OutList, Comment)
% This routine parses the OutList field into individual variables (the
% input value may contain several variables per line)
%Inputs: 
%   OutList     - .OutList cell array, as returned from FAST2Matlab
%   Comment     - .OutListComment cell array, as returned from FAST2Matlab
%Outputs:
%   OutListAry  - .OutList cell array, with only one variable per line
%   CommentAry  - .OutListComm cell array, with only one variable per line
%--------------------------------------------------------------------------

    OutListAry = {};
    CommentAry = {};
    numOuts = 0;
    for i=1:length(OutList)
        OutListRow = strrep(OutList{i},',', ' '); %Replace any commas that may separate the OutList variables with spaces
        OutListRow = strrep(OutListRow,'"', '');  %Remove any quotes that may enclose the OutList variables on this line
        tmp = textscan(OutListRow,'%s');
        for j=1:length(tmp{1})
            numOuts = numOuts + 1;
            OutListAry{numOuts} = tmp{1}{j};
            CommentAry{numOuts} = OutListComments{i};
        end
    end

    return
    
end