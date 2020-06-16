function writeOperatingPoints(filename, OP)
    % Write an "Operating Point" delimited file from a structure. 
    %
    % The structure fields are used as column names
    %
    % INPUTS
    %  - filename: CSV filename (string)
    %  - OP : structure with any of the following fields: {WindSpeed, RotorSpeed,GeneratorTorque, PitchAngle, YawAngle, Filename}

    FieldsAccepted = {'WindSpeed', 'RotorSpeed','GeneratorTorque', 'PitchAngle', 'YawAngle', 'Filename'};

    fieldnames_in = fieldnames(OP);
    IKeep = find(cellfun(@(x)any(strcmp(FieldsAccepted,x)), fieldnames_in));

    if length(IKeep)==0
        error('Structure needs to contain at least one of the fields supported.')
    end
    fieldref = fieldnames_in{IKeep(1)}; % We use the first field to estimate length
    nRow = length(OP.(fieldref));
    nCol = length(IKeep);

    % Convert to cell array
    Mout = cell(nRow+1,nCol);
    for ic = 1:nCol
        fieldname=fieldnames_in{IKeep(ic)};
        Mout{1,ic} = fieldname;
        if length(OP.(fieldname))~=nRow
            error('Inconsistent number of values between field %s (%d) and field %s (%d)',fieldname, length(OP.(fieldname)),fieldref,nRow)
        end
        if iscell(OP.(fieldname))
            Mout(2:end,ic)= OP.(fieldname);
        else
            Mout(2:end,ic)= num2cell(OP.(fieldname));
        end
    end

    % Write to cell array
    cellarray2csv(filename, Mout);
