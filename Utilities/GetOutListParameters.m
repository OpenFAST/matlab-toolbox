function [Category, VarName, InvalidCriteria, ValidInputStr, ValidInputStr_VarName, ValidInputStr_Units ] = GetOutListParameters( XLS_file, OutListSheet )
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

if (exist ("OCTAVE_VERSION", "builtin") > 0)
    pkg load io  % for xlswrite
    [num,txt] = xlsread(XLS_file, OutListSheet);
    %Category	Name	Other_Name(s)	Description	Convention	Units	Invalid Channel Criteria
    VarName         = txt(2:end,2);
    InputStr        = txt(2:end,3);
    Units           = txt(2:end,6);
    InvalidCriteria = txt(2:end,7);
    Category        = txt(2:end,1);
else
    opts = detectImportOptions(XLS_file, 'Sheet', OutListSheet, 'VariableNamingRule','modify');
    t = readtable(XLS_file,opts);
    % create variables from the column headings: Category, InputNUM, OutInd,
    % SORTName, UniqueVals, InvalidCriteria, Units
    VarName  = t.Name;
    InputStr = t.OtherName_s_;
    Units    = t.Units;
    InvalidCriteria = t.InvalidChannelCriteria;
    Category = t.Category;
end



%%
ValidInputStr = cell(1,1);
ValidInputStr_VarName  = cell(1,1);
ValidInputStr_Units = cell(1,1);
nr = 0;

for i=1:length(VarName)
    if ischar(VarName{i}) && ~isempty(VarName{i})
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
