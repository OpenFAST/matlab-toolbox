function [HDP] = newInputs_HD_v2_02_00(HDPar)
% [HDP] = newInputs_HD_v2_02_00(HDPar)
% HDP is the data structure containing already-filled parameters for
% HydroDyn. We're going to add existing fields and based on the old ones.

    HDP = HDPar;
    
    
     
    n = length(HDP.Label);

    
 % v2.02.00 Specification
    
    % WaveDirMod, WaveDirSpread, WaveNDir, WaveDirRange
    [WaveDirMod, err1] = GetFASTPar(HDP,'WaveDirMod');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WaveDirMod';
        HDP.Val{n}   = 0;
    end
    [WaveDirSpread, err1] = GetFASTPar(HDP,'WaveDirSpread');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WaveDirSpread';
        HDP.Val{n}   = 1;
    end
    [WaveNDir, err1] = GetFASTPar(HDP,'WaveNDir');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WaveNDir';
        HDP.Val{n}   = 1;
    end
    [WaveDirRange, err1] = GetFASTPar(HDP,'WaveDirRange');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WaveDirRange';
        HDP.Val{n}   = 90;
    end
    
    % WvDiffQTF, WvSumQTF, WvLowCOffD, WvHiCOffD, WvLowCOffS, WvHiCOffS 
    [WvDiffQTF, err1] = GetFASTPar(HDP,'WvDiffQTF');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WvDiffQTF';
        HDP.Val{n}   = 'False';
    end
    [WvSumQTF, err1] = GetFASTPar(HDP,'WvSumQTF');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WvSumQTF';
        HDP.Val{n}   = 'False';
    end
    [WvLowCOffD, err1] = GetFASTPar(HDP,'WvLowCOffD');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WvLowCOffD';
        HDP.Val{n}   = 0;
    end
    [WvHiCOffD, err1] = GetFASTPar(HDP,'WvHiCOffD');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WvHiCOffD';
        HDP.Val{n}   = 3.5;
    end
    [WvLowCOffS, err1] = GetFASTPar(HDP,'WvLowCOffS');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WvLowCOffS';
        HDP.Val{n}   = 0.1;
    end
    [WvHiCOffS, err1] = GetFASTPar(HDP,'WvHiCOffS');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'WvHiCOffS';
        HDP.Val{n}   = 3.5;
    end
    
    
    % MnDrift, NewmanApp, DiffQTF, SumQTF    
    [MnDrift, err1] = GetFASTPar(HDP,'MnDrift');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'MnDrift';
        HDP.Val{n}   = 0;
    end
    [NewmanApp, err1] = GetFASTPar(HDP,'NewmanApp');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'NewmanApp';
        HDP.Val{n}   = 0;
    end
    [DiffQTF, err1] = GetFASTPar(HDP,'DiffQTF');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'DiffQTF';
        HDP.Val{n}   = 0;
    end
    [SumQTF, err1] = GetFASTPar(HDP,'SumQTF');    
    if err1
        n = n + 1;
        HDP.Label{n} = 'SumQTF';
        HDP.Val{n}   = 0;
    end
    
    % v2.03.00 specification GHWvFile  is replaced with WvKinFile
    [GHWvFile, err1, Indx] = GetFASTPar(HDP,'GHWvFile');    
    if ~err1
        HDP.Label{Indx} = 'WvKinFile';
        HDP.Val{Indx}   = '';
    end
    
    [NAxCoef, err1] = GetFASTPar(HDP,'NAxCoef');    
    if err1
      [NAxCoef, err1] = GetFASTPar(HDP,'NHvCoef');    
      if ~err1
        n = n + 1;
        HDP.Label{n} = 'NAxCoef';
        HDP.Val{n}   = NAxCoef;
        HDP.AxCoefsHdr    = HDP.HvCoefsHdr;
        HDP.AxCoefsHdr{1} = 'AxCoefID';
        HDP.AxCoefsHdr{2} = 'AxCd';
        HDP.AxCoefsHdr{3} = 'AxCa';
        HDP.AxCoefs       = HDP.HvCoefs;
      end
    end
    
    % v2.03.00 specification GHWvFile  is replaced with WvKinFile
    [HasWAMIT, err1, Indx] = GetFASTPar(HDP,'HasWAMIT');    
    if ~err1
        HDP.Label{Indx} = 'PotMod';
        if ( strcmpi(HasWAMIT, 'FALSE') || strcmpi(HasWAMIT, 'F') )
         HDP.Val{Indx}   = 0;
        else
         HDP.Val{Indx}   = 1;  
        end
    end
    
    [WAMITFile, err1, Indx] = GetFASTPar(HDP,'WAMITFile');    
    if ~err1
        HDP.Label{Indx} = 'PotFile';
    end
    
    if length(HDP.AxCoefsHdr) < 4
      % v2.00.03 specification
      HDP.AxCoefsHdr{4} = 'AxCp';       
      for i=1:NAxCoef
         HDP.AxCoefs(i,4) = 1.0;     
      end
    end
    
      % Change header labels for Joint table per v2.00.03 specification
    HDP.JointsHdr{2}   = 'Jointxi';
    HDP.JointsHdr{3}   = 'Jointyi';
    HDP.JointsHdr{4}   = 'Jointzi';
    HDP.JointsHdr{5}   = 'JointAxID';
    
    if length(HDP.SmplPropHdr) < 5
      % v2.00.03 specification
      HDP.SmplPropHdr{5}= 'SimplCp';
      HDP.SmplPropHdr{6}= 'SimplCpMG';
      HDP.SmplProp(5)   = 1.0;
      HDP.SmplProp(6)   = 1.0;
    end
    if length(HDP.SmplPropHdr) < 7 
      % v2.00.05 specification
      HDP.SmplPropHdr{7}= 'SimplAxCa';
      HDP.SmplPropHdr{8}= 'SimplAxCaMG';
      HDP.SmplPropHdr{9}= 'SimplAxCp';
      HDP.SmplPropHdr{10}= 'SimplAxCpMG';
      HDP.SmplProp(7:10)   = 1.0;
    end
    
    if length(HDP.DpthPropHdr) < 6
      HDP.DpthPropHdr{6}     = 'DpthCp';
      HDP.DpthPropHdr{7}     = 'DpthCpMG';
      HDP.DpthProp(1:size(HDP.DpthProp,1),6:7)     = 1.0;     
    end
    
    if length(HDP.DpthPropHdr) < 8
      HDP.DpthPropHdr{8}     = 'DpthAxCa';
      HDP.DpthPropHdr{9}     = 'DpthAxCaMG';
      HDP.DpthPropHdr{10}    = 'DpthAxCp';
      HDP.DpthPropHdr{11}    = 'DpthAxCpMG';
      HDP.DpthProp(1:size(HDP.DpthProp,1),8:11)     = 1.0;
    end
    
    if length(HDP.MemberPropHdr) < 10
      HDP.MemberPropHdr{10}     = 'MemberCp1';
      HDP.MemberPropHdr{11}     = 'MemberCp2';
      HDP.MemberPropHdr{12}     = 'MemberCpMG1';
      HDP.MemberPropHdr{13}     = 'MemberCpMG2';
      HDP.MemberProp(1:size(HDP.MemberProp,1),10:13)     = 1.0;       
    end
    
    if length(HDP.MemberPropHdr) < 14
      HDP.MemberPropHdr{14}     = 'MemberAxCa1';
      HDP.MemberPropHdr{15}     = 'MemberAxCa2';
      HDP.MemberPropHdr{16}     = 'MemberAxCaMG1';
      HDP.MemberPropHdr{17}     = 'MemberAxCaMG2';
      HDP.MemberPropHdr{18}     = 'MemberAxCp1';
      HDP.MemberPropHdr{19}     = 'MemberAxCp2';
      HDP.MemberPropHdr{20}     = 'MemberAxCpMG1';
      HDP.MemberPropHdr{21}     = 'MemberAxCpMG2';
      HDP.MemberProp(1:size(HDP.MemberProp,1),14:21)     = 1.0;       
    end
    
    if ( strcmpi(HDP.MembersHdr{8},'PropWAMIT') )
       HDP.MembersHdr{8} = 'PropPot';
    end
    if ~isfield(HDP,'OutList')
      if isfield(HDP,'PtfmOutList')  && isfield(HDP,'MeshOutList') 
         HDP.OutList = [HDP.PtfmOutList; HDP.MeshOutList];
         HDP.OutListComments = [HDP.PtfmOutListComments; HDP.MeshOutListComments];
      elseif isfield(HDP,'PtfmOutList') 
         HDP.OutList = HDP.PtfmOutList;
         HDP.OutListComments = HDP.PtfmOutListComments;
      elseif isfield(HDP,'MeshOutList')
         HDP.OutList = HDP.MeshOutList;
         HDP.OutListComments = HDP.MeshOutListComments;
      end
    end
    
end 
