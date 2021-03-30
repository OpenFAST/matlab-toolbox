function s=replaceModeDescription(s)
    % Perform replacements to shorten mode description
    s = strrep(s,'First time derivative of'     ,'d/dt of');
    s = strrep(s,'fore-aft bending mode DOF, m'    ,'FA'     );
    s = strrep(s,'side-to-side bending mode DOF, m','SS'     );
    s = strrep(s,'bending-mode DOF of blade '    ,''     );
    s = strrep(s,' rotational-flexibility DOF, rad','-ROT'   );
    s = strrep(s,'rotational displacement in ','rot'   );
    s = strrep(s,'Drivetrain','DT'   );
    s = strrep(s,'translational displacement in ','trans'   );
    s = strrep(s,', rad','');
    s = strrep(s,', m','');
    s = strrep(s,'finite element node ','N'   );
    s = strrep(s,'cosine','cos'   );
    s = strrep(s,'sine','sin'   );
    s = strrep(s,'collective','coll.');
    s = strrep(s,'Blade','Bld');
    s = strrep(s,'rotZ','TORS-R');
    s = strrep(s,'transX','FLAP-D');
    s = strrep(s,'transY','EDGE-D');
    s = strrep(s,'rotX','EDGE-R');
    s = strrep(s,'rotY','FLAP-R');
    s = strrep(s,'flapwise','FLAP');
    s = strrep(s,'edgewise','EDGE');
    s = strrep(s,',','|');
end


