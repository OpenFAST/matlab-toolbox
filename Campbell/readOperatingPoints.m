function OP = readOperatingPoints(filename, delim)
    % Reads an "Operating Point" delimited file to a structure. 
    %
    % The first line should be a header line defining the column names
    %
    % An example of header line with the units that are assumed by this script:
    %    WindSpeed_[m/s], RotSpeed_[rpm], PitchAngle_[deg], GeneratorTorque_[Nm], Filename_[-]
    % 
    % The file should at the minimum contain the rotor speed or the wind speed.
    % The field "Filename" is added to the structure if this column is not provided.
    %
    % The header columns will become field names after the following manipulations:
    %  - units () [] are stripped
    %  - spaces  are removed
    %  - replacements are made to ensure standardization.
    % 
    % Columns that are made of numerical values only, will become regular array
    % Columns that contain strings will be stored as cell arrays
    % 
    %
    % INPUTS
    %  - filename: CSV filename (string)
    %
    % OPTIONAL INPUTS
    %  - delim: delimiter for csv file
    %
    % OUTPUTS:
    %  - OP : structure with standardized fields:
    %        - nOP : number of operating points 
    %        - rpmSweep: True if no wind speed is provided
    %        - Filename: fst filenames for each operating point
    %                    This field is added if column is not present in csv file.
    %        - {WindSpeed, RotorSpeed}: at least one of the two
    %        - {GeneratorTorque, PitchAngle, YawAngle}: Optional fields, potentially present in input file
    % 

    if ~exist('delim','var'); delim=','; end

    % Read delimited file to a structure. NOTE: we don't use a table for maximum compatibility
    st0 = csv2struct(filename, delim);
    fieldnames_in = fieldnames(st0);

    % Perform some field name replacements for standardization
    OP=struct();
    for iField = 1:length(fieldnames_in)
        fieldname = strtrim(lower(fieldnames_in{iField}));
        if any(strcmp({'windspeed','ws'},fieldname))
            OP.WindSpeed = st0.(fieldnames_in{iField});

        elseif any(strcmp({'rotorspeed','rotspeed','rpm','omega'},fieldname))
            OP.RotorSpeed = st0.(fieldnames_in{iField});

        elseif any(strcmp({'generatortorque','gentrq','gentorque'},fieldname))
            OP.GeneratorTorque = st0.(fieldnames_in{iField});

        elseif any(strcmp({'pitchangle','pitch','bldpitch'},fieldname))
            OP.PitchAngle = st0.(fieldnames_in{iField});

        elseif any(strcmp({'filename','file'},fieldname))
            OP.Filename = st0.(fieldnames_in{iField});

        elseif any(strcmp({'ttdspfa','ttdispfa','towertopdispfa'},fieldname))
            OP.TowerTopDispFA = st0.(fieldnames_in{iField});

        else
            OP.(fieldnames_in{iField}) = st0.(fieldnames_in{iField});
        end
    end
    if ~isfield(OP,'WindSpeed')
        keyboard
    end

    % Check that at least the rotational speed or wind speed was provided
    if ~isfield(OP,'WindSpeed') && ~isfield(OP,'RotorSpeed')
        error('The operating point file should at least contain the Wind Speed or Rotor Speed column')
    end
    if isfield(OP,'RotorSpeed') && ~isfield(OP,'WindSpeed')
        OP.rpmSweep=true;
        OP.nOP = length(OP.RotorSpeed);
    else
        OP.rpmSweep=false;
        OP.nOP = length(OP.WindSpeed);
    end

    % Generate a standardized filename if "FileName" was not provided
    if ~isfield(OP,'Filename')
        OP.Filename=defaultFilenames(OP, OP.rpmSweep);
    else
        % Removing quotes from filenames if any
        for iOP = 1:OP.nOP
            OP.Filename{iOP}=strtrim(regexprep(OP.Filename{iOP}, '('')|(")', ''));
        end
    end


