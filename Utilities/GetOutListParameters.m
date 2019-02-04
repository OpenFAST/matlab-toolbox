function [Category, VarName, InvalidCriteria, ValidInputStr, ValidInputStr_VarName, ValidInputStr_Units ] = getOutListParameters( XLS_file, OutListSheet )
% Inputs:
%   XLS_file              - Excel file containing the OutListParameters
%   OutListSheet          - name of worksheet to read in XLS_file 
% Outputs:
%   Category              - the category column (raw data)
%   VarName               - the variable name used in the module (raw data)
%   InvalidCriteria       - criteria that determines when the variable is 
%                           invalid (raw data)
%   ValidInputStr         - valid entries in the input file (includes alias 
%                           names)
%   ValidInputStr_VarName - the VarName corresponding to ValidInputStr
%   ValidInputStr_Units   - the Units corresponding to ValidInputStr (and
%                           ValidInputStr_VarName)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~, ~, raw] = xlsread( XLS_file, OutListSheet );

% create variables from the column headings: Category, InputNUM, OutInd,
% SORTName, UniqueVals, InvalidCriteria, Units
for iCol = 1:size(raw,2)
   
    if ischar(raw{1,iCol})
        if strcmpi(raw{1,iCol},'Name')
            VarName = raw(2:end,iCol);
        elseif strfind( raw{1,iCol}, 'Other Name' )
            InputStr = raw(2:end,iCol);
        elseif strfind( raw{1,iCol}, 'Units' )
            Units = raw(2:end,iCol);
        elseif strfind( raw{1,iCol}, 'Invalid Channel Criteria' )
            InvalidCriteria = raw(2:end,iCol);
        elseif strfind( raw{1,iCol}, 'Category' )
            Category = raw(2:end,iCol);
        end
    end
    
end
%Category = raw{:,1};


%%
ValidInputStr = cell(1,1);
ValidInputStr_VarName  = cell(1,1);
ValidInputStr_Units = cell(1,1);
nr = 0;

for i=1:length(VarName)
    if ischar(VarName{i})
        nr = nr + 1;
        ValidInputStr{        nr,1} = VarName{i};
        ValidInputStr_VarName{nr,1} = VarName{i};
        ValidInputStr_Units{  nr,1} = Units{  i};
    end    
end

for i=1:length(InputStr)
    if ischar(InputStr{i}) && ~isempty(InputStr{i})
        tmp = textscan(InputStr{i},'%s','delimiter',',');
        n   = length(tmp{1});
        for i2 = 1:n %nr:(nr+n-1)
            ValidInputStr{nr+i2} = strtrim(tmp{1}{i2});
            ValidInputStr_VarName{nr+i2} = VarName{i};
            ValidInputStr_Units{nr+i2}   = Units{  i};
        end
        nr = nr + n;
    end
end


end