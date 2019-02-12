
modesDesc = { 
{'Generator DOF (not shown)'     , 'ED Variable speed generator DOF, rad'}
{'1st Tower FA'                  , 'ED 1st tower fore-aft bending mode DOF, m'}
{'1st Tower SS'                  , 'ED 1st tower side-to-side bending mode DOF, m'}
{'1st Blade Flap (Regressive)'   , 'ED 1st flapwise bending-mode DOF of blade (sine|cosine), m', ...
                                   'Blade (sine|cosine) finite element node \d rotational displacement in Y, rad'}
{'1st Blade Flap (Collective)'   , 'ED 1st flapwise bending-mode DOF of blade collective, m', ...
                                   'Blade collective finite element node \d rotational displacement in Y, rad'}
{'1st Blade Flap (Progressive)'  , 'ED 1st flapwise bending-mode DOF of blade (sine|cosine), m'} % , ...% 'Blade (sine|cosine) finite element node \d rotational displacement in Y, rad'}
{'1st Blade Edge (Regressive)'   , 'ED 1st edgewise bending-mode DOF of blade (sine|cosine), m', ...
                                   'Blade (sine|cosine) finite element node \d rotational displacement in X, rad'}
{'1st Blade Edge (Progressive)'  , 'ED 1st edgewise bending-mode DOF of blade (sine|cosine), m'}
{'1st Drivetrain Torsion'        , 'ED Drivetrain rotational-flexibility DOF, rad'}
{'2nd Tower FA'                  , 'ED 2nd tower fore-aft bending mode DOF, m'}
{'2nd Tower SS'                  , 'ED 2nd tower side-to-side bending mode DOF, m'}
{'2nd Blade Flap (Regressive)'   , 'ED 2nd flapwise bending-mode DOF of blade (sine|cosine), m'}
{'2nd Blade Flap (Collective)'   , 'ED 2nd flapwise bending-mode DOF of blade collective, m', ...
                                   'Blade collective finite element node \d rotational displacement in Y, rad'}
{'2nd Blade Flap (Progressive)'  , 'ED 2nd flapwise bending-mode DOF of blade (sine|cosine), m'} 
{'Nacelle Yaw (not shown)'  , 'ED Nacelle yaw DOF, rad'} ...
...
};

%%

nModes = length(modesDesc);
nRuns = length(CampbellData);
modeID_table = zeros(nModes,nRuns);

modesIdentified = cell(nRuns,1);


for i=1:nRuns
    modesIdentified{i} = false( size(CampbellData{i}.Modes) );
    
    for modeID = 2:length(modesDesc) % list of modes we want to identify
        found = false;
        
        if isempty( strtrim( modesDesc{modeID}{2} ) ) 
            continue;
        end 
        
        tryNumber = 1;
        while ~found && tryNumber <= 2
            m = 0;
            while ~found && m < length(modesIdentified{i})
                m = m + 1;
                if modesIdentified{i}(m) || CampbellData{i}.Modes{m}.NaturalFreq_Hz < 0.1 % already identified this mode
                    continue;
                end

                if tryNumber == 1
                    maxDesc = CampbellData{i}.Modes{m}.DescStates ( CampbellData{i}.Modes{m}.StateHasMaxAtThisMode );
                else
                    maxDesc = CampbellData{i}.Modes{m}.DescStates ( 1 );
                end
                    
                if ~isempty(maxDesc)
                    j = 0;
                    while ~found && j < length(maxDesc)
                        j = j + 1;
%                         if strcmpi( maxDesc{j}, modesDesc{modeID}{2} ) || ...
                        if ~isempty( regexp(maxDesc{j},modesDesc{modeID}{2},'match') ) || ...                        
                           ( length(modesDesc{modeID})>2 && ...
                            ~isempty( regexp(maxDesc{j},modesDesc{modeID}{3},'match') ) )
                            modesIdentified{i}(m) = true;
                            modeID_table(modeID,i) = m;
                            found = true;
                        end                    
                    end % while                
                end

            end
            tryNumber = tryNumber + 1;
        end        
        
    end
end

%     
% for m = l:nModes
% end