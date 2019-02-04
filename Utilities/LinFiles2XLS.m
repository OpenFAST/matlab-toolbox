function Reduced = LinFiles2XLS( thisStructure, xlsFile )
%%
% This function takes the matrices stored in the data structure created in
% ReadFASTLinear() and writes them to Microxoft Excel files (xls or xlsx, 
% depending on xlsFile's extension), including descriptions of the rows and 
% colums. It creates worksheets for the full and reduced matrices (reduced 
% matrices remove the rows and columns from the full matrices that have only 
% zeros [or in the case of dUdu, values of dUdu-I that are only zero]).
%%

    theseFields = {'dXdx','dXdu','dYdx','dYdu','A','B','C','D','dUdu','dUdy'};
    matRows     = {'x',   'x',   'y',   'y',   'x','x','y','y','u',   'u'};
    matCols     = {'x',   'u',   'x',   'u',   'x','u','x','u','u',   'y'};

    Reduced = cell(length(theseFields),1);
    for i=1:length(theseFields)
        if isfield(thisStructure, theseFields{i})

            if strcmp(theseFields{i}, 'dUdu')
                nonZeros = thisStructure.dUdu - eye(size(thisStructure.dUdu)) ~= 0;
            else
                nonZeros = thisStructure.(theseFields{i}) ~= 0;
            end

            keepRows = squeeze(any(nonZeros,2));
            keepCols = squeeze(any(nonZeros,1));

            Reduced{i}.name = theseFields{i};
            Reduced{i}.mat  = thisStructure.(theseFields{i})(keepRows,keepCols);
            Reduced{i}.row_desc = thisStructure.([matRows{i} '_desc'])(keepRows);
            Reduced{i}.col_desc = thisStructure.([matCols{i} '_desc'])(keepCols);

            c = cat(2, cat(1, ' ', Reduced{i}.row_desc), cat(1, Reduced{i}.col_desc', num2cell(Reduced{i}.mat)) );
            xlswrite(xlsFile, c, ['Reduced-' Reduced{i}.name] );

            c1=cat(1, ' ', thisStructure.([matRows{i} '_desc']));
            c2=cat(1, thisStructure.([matCols{i} '_desc'])', num2cell(thisStructure.(theseFields{i})) );
            c = cat(2, c1, c2);
            xlswrite(xlsFile, c, ['Full-' theseFields{i}] );
        end
    end

return;
end
