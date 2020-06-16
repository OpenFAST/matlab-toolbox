function modesData2XLS(XLSname, ModesData)
% Write summary of Campbell data and modes identification to one XLS file
%
% INPUTS:
%   - XLSname     :  filename of Excel file to write to
%   - ModesData: structure as returned by IdentifyModes
%

fprintf('Excel file: %s\n',XLSname)
if (exist ("OCTAVE_VERSION", "builtin") > 0)
    pkg load io  % for xlswrite
end

nOP=length(ModesData);

%--- Write Cambell identification Table to separate sheet
try
    xlswrite(XLSname, ModesData.modeID_table, ModesData.modeID_name); % create a worksheet with these modes
catch
    disp('warning::could not write modes identification to Excel.')
end

% --- Write Operating points to seperate sheet
try
    xlswrite(XLSname, ModesData.opTable, 'OP'); % create a worksheet with these operating points
catch
    disp('warning::could not write operating points table to Excel. ')
end

%--- Write individual Linearization data to different spreadsheets
for iOP =nOP:-1:1
    try
        xlswrite(XLSname, ModesData.ModesTable{iOP}, ModesData.ModesTable_names{iOP}); % create a worksheet with these modes
    catch
        disp(['warning::could not write Campbell data in Excel worksheet for ' ModesData.ModesTable_names{iOP}]);
    end
end

end
