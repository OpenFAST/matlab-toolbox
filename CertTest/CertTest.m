% CertTest for users
clear all;          %clear everything first

%% Get data from test Files
for ifile = 1:1

  RootName = ['test' num2str(ifile,'%02.0f')];
FileVariables(1) = load(['TestFiles/File' RootName '.mat']);


%% Analyze File 2
GetMats      %tell what file name to use....
mbc3
cce


%% Copy variables from file 2 to FileVariables structure
%  and then, clear all the other variables
FileVars = who;    %create a cell-array containing all the variable names
for i= 1:length(FileVars)
    if ~strcmp( FileVars{i}, 'FileVariables' ) ...  %don't delete the FileVariables structure
        && ~strcmp( FileVars{i}, 'RootName' )  ...   %don't delete the FileVariables structure
        && ~strcmp( FileVars{i}, 'ifile' )             %don't delete the FileVariables structure
        eval(['FileVariables(2).' FileVars{i} ' = ' FileVars{i} ';']);  % copy the variables to a structure
        eval(['clear '        FileVars{i}] );                      % delete the variable from memory
    end
end
clear FileVars

%% Compare the values in the structure
VarNames = fieldnames(FileVariables);
fprintf('\nComparing variables from file %s.lin:\n', RootName);
for i = 1:length(VarNames)
    var1 = eval(['FileVariables(1).' VarNames{i}]);
    var2 = eval(['FileVariables(2).' VarNames{i}]);

    fprintf('  %s: ', VarNames{i});

    if isempty(var1)
        fprintf('Variable from file 1 is empty.\n');
    else
        if isnumeric(var1)  %the variable is numeric
            % compare numeric values
            if isempty(var2)
                var2 = zeros(size(var1));
            end

            if isnumeric(var2)
                diff = norm( var1(:) - var2(:) );

                if diff > 0
                    fprintf( 'Norm of difference = %f\n', diff);
                else
                    fprintf( 'No difference.\n' );
                end
            else
                fprintf( 'Variables have different types.\n' )
            end

        elseif ischar(var1)  %the variable is a character array
            if ischar(var2)
                if ~strcmp(var1,var2)
                    fprintf( 'File 1 = "%s", File 2 = "%s"\n', var1, var2 );
                else
                    fprintf( 'No difference.\n' );
                end
            else
                fprintf( 'Variables have different types.\n' )
            end

        else  %logical, cell, structure, etc
            fprintf('Values not compared (not numeric or character data).\n'); %a different variable that's not numeric or characters
        end
    end

end %i

clear VarNames i var1 var2 diff FileVars FileVariables

end %ifile