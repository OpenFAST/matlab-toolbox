function st = csv2struct(filename, delim)
    % Reads a csv file to a structure
    % Assumes the first line to be a header line 
    % The header columns are stripped from units and spaces and used as struct fields
    % Columns that are made of numerical values only, will become regular array
    % Columns that contain strings will be stored as cell arrays
    %
    % INPUTS
    %  - filename: CSV filename (string)
    %
    % OPTIONAL INPUTS
    %  - delim: delimiter for csv file
    %
    % OUTPUTS:
    %  - st : structure with fields matching the column names of filename
    % 
    if ~exist('delim','var'); delim=','; end

    % ading csv to cell array
    [M, header] = csv2cellarray(filename,'delimiter',delim,'header',1);

    % Checking taht header contains a good number of column names
    colnames = regexp(header{1},delim,'split');
    nCol= size(M,2); 
    if length(colnames)<nCol
        error('Number of columns in headers (%d) is smaller than number of data columns (%d) for file %s',filename,length(colnames),nCol);
    end
    colnames=colnames(1:nCol);

    % Storing into a structure
    st = struct();
    for ic = 1:nCol
        % Strip units and spaces
        fieldname = strrep(colnames{ic},' ','');
        fieldname = strrep(fieldname   ,'_','');
        fieldname = regexprep(fieldname, '(\(.*\))|(\[.*\])', '');
        fieldname = fieldname(isletter(fieldname)); % important safety
        Col= M(:,ic);
        % If all values in column are numeric
        ColNum=str2double(Col);
        if all(~isnan(ColNum))
            Col=ColNum;
        end
        st.(fieldname) = Col;
    end
end
