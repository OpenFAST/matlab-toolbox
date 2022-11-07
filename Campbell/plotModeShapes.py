from paraview.simple import * 
import os 
import sys
import glob
import numpy as np

if len(sys.argv) not in [3,4]:
    print('Error: Not enough argument provided.')
    print("""
usage:
    plotModeShapes ROOT_PATH STATEFILE [OUTPUTDIR]  [FPS]

where:
    ROOT_PATH: Path of the form VTKDIR\ROOTNAME
               where VTKDIR is the directory where vtp files are located 
               Modes and LinTimes will be selected using the pattern:
               ROOT_PATH.Mode*.LinTime*.vtp
    STATEFILE: State file used for visualization

""")
    sys.exit(-1)
print('----------------------- plotModeShapes.py-------------------------')

# --- Input Parameters
RootPath    = os.path.normpath(sys.argv[1])
StateFile   = os.path.normpath(sys.argv[2])
if len(sys.argv)==4:
    OutputDir = os.path.normpath(sys.argv[3])
else:
    OutputDir='./'
if len(sys.argv)==5:
    fps    =  int(sys.argv[4])
else:
    fps    =  3          # frames per second (rate to save in the .avi file)

# --- Derived params
rootSim     = os.path.basename(RootPath)
mainDirName = os.path.abspath(os.path.dirname(RootPath))

# --- Constants
StructureModule = 'ED'
BladeMesh       = "AD_Blade"

print('RootName        :',rootSim)
print('MainDirName     :',mainDirName)
print('StateFile       :',StateFile)

# --------------------------------------------------------------------------------}
# --- Helper functions 
# --------------------------------------------------------------------------------{
def extractModeNumbers(rootPath):
    """ Extract mode numbers based on a simulation directory and simulation basename """
    rootSim = os.path.basename(rootPath)
    dirName = os.path.dirname(os.path.abspath(rootPath))
    absrootMode = os.path.join(dirName, rootSim+'.Mode')
    pattern = absrootMode+'*.*.vtp'
    files = glob.glob(pattern)
    if len(files)==0:
        raise Exception('No file found with pattern: ',pattern)
    filesNoRoot=[f[len(absrootMode):] for f in files]
    modeNumbers=np.sort(np.unique(np.array([f.split('.')[0] for f in filesNoRoot]).astype(int)))
    return modeNumbers


def extractModeInfo(rootPath, iMode):
    """ 

    dirName/rootSim.Mode5.LinTime1.AD_Blade1.001.vtp

    return 
     - meshes: list of meshes available
     - nZeros: number of zeros before extension
     - nTimes: number of time steps
     - Suffix: number of time steps
    """
    rootSim = os.path.basename(rootPath)
    dirName = os.path.dirname(os.path.abspath(rootPath))
    rootMode    = rootSim+'.Mode{:d}.'.format(iMode)           # +Suffix
    absrootMode = os.path.join(dirName, rootMode)
    pattern     = absrootMode +'*.vtp'                       ;
    files       = glob.glob(pattern)
    print(pattern+' ({})'.format(len(files)))
    # if len(files)==0:
    #     continue # Should be an exception really...

    # --- Detect Suffix. If VTKLinTim=2, Suffix='LinTime1.', else Suffix=''
    filesNoRoot=[f[len(absrootMode):] for f in files]
    Suffix=''
    if filesNoRoot[0].startswith('LinTime1'):
        Suffix='.LinTime1' # TODO consider what to do if we have more lintimes
        filesNoRoot=[f[9:] for f in filesNoRoot]
    absrootMode += Suffix
    rootMode   += Suffix

    # --- Detect Meshes names and number of leading zeros
    #  Filename has the following structure   Root . MeshName . ZEROS . vtp
    #  Example:                               Beam . HubSurface . 003 . vtp
    meshes = set()
    nZeros = []  # Number of 
    timeStamps = []  # Numebr of 
    for f in filesNoRoot:
        sp = f.split('.')
        ts = sp[1]
        timeStamps.append(int(ts))
        meshes.add(sp[0])
        nZeros.append(len(sp[1]))
    nZerosUnique, counts = np.unique(nZeros, return_counts=True)
    index = np.argmax(counts)
    nZeros = nZeros[index]
    nTimes = np.max(timeStamps) # ...
    if len(nZerosUnique)>1:
        print('[WARN] Files have different number of leading zeros {}, choosing: {}'.format(nZerosUnique, nZeros))
    #txt = '{:0' + str(nZeros) + 'd}'
    #fileLeadingZeros = txt.format(1)

    return meshes, nZeros, nTimes, Suffix



# --- Detect number of modes
modeNumbers =  extractModeNumbers(rootPath)
nModes = len(modeNumbers)
print('Modes present   : ({}) {}'.format(nModes, list(modeNumbers)))

# Decreasing fps with mode number TODO
vFPS= np.linspace(5,1,nModes).astype(int) * fps
vFPS= [5]*nModes

modeNumbers=[6,7]



# --- Read paraview state file to extrct source names
# Look for: <ProxyCollection name="sources"> and extract source names
#  Example: 
#     <ProxyCollection name="sources">
#        <Item id="11771" name="Blade1Surface" logname="Root.Mode5.LinTime1.Blade1Surface.00*"/>
#     </ProxyCollection>
stateSourceNames    = []
stateSourceIDs      = []
with open(StateFile, 'r') as f:
    while (line := f.readline().strip()):
        if line.find('ProxyCollection name="sources"')>=0:
            while (line := f.readline().strip()):
                if line.find('/ProxyCollection')>=0:
                    break
                sourceID   = line.split('id="')[1].split('"')[0].strip()
                sourceName = line.split('name="')[1].split('"')[0].strip()
                # '5MW_Land_DLL_WTurb.Mode1.LinTime1.AD_Blade1.0*'
                #a5MW_Land_DLL_WTurbMode1LinTime1AD_Blade10FileName
                stateSourceNames.append(sourceName)
                stateSourceIDs  .append(sourceID)
if len(stateSourceNames)==0:
    print('[WARN] Cannot find state source names in state file. Using default, but script might fail. ')
    stateSourceNames = ['Blade1Surfaces','Blade2Surfaces','Blade3Surfaces']
print('StateSourceIDs:', stateSourceIDs)
print('StateSourceNames:')
for sn in stateSourceNames:
    print('               ',sn)



# --------------------------------------------------------------------------------}
# --- Looping through modes 
# --------------------------------------------------------------------------------{
rootSim = os.path.basename(rootPath)
for iiMode, iMode in enumerate(modeNumbers):
    print('--------------------------------- MODE {} --------------------------------------'.format(iMode))

    # --- Extract Mode info (which mesh are present, how many time steps)
    meshes, nZeros, nTimes, Suffix = extractModeInfo(rootPath, iMode)
    timeFormat = '{:0' + str(nZeros) + 'd}'
    fileLeadingZeros = timeFormat.format(1)

    print('Meshes          :',meshes)
    print('Number of zeros :',nZeros,fileLeadingZeros)

    # --- Detect number of blades
    # TODO BeamDyn
    IBlades  = [i for i in range(3) if 'Blade{}Surface'.format(i) in meshes ]
    IBlades += [i for i in range(3) if 'AD_Blade{}'.format(i) in meshes ]
    nBlades = np.max(IBlades)
    print('Number of blades:',nBlades)


    # --- Figure out which mesh the state file support
    # In the state file, look for: <ProxyCollection name="sources">
    stateSourceNamesLoc = stateSourceNames.copy()
    meshSource = {}
    for m in meshes:
        meshSource[m]=None
        # Try to find a matching Source Name for this mesh
        for sn,ID in zip(stateSourceNamesLoc,stateSourceIDs):
            #+'FileName'
            if sn.find(m)>=0:
                meshSource[m]={'name':sn,'id':ID}
                break
        if meshSource[m] is None:
            print('[WARN] Cannot find a way to plot mesh {} based on the sourceNames in state file'.format(m))
        else:
            stateSourceNamesLoc.remove(meshSource[m]['name'])
    stateSourceNamesNotFound=stateSourceNamesLoc # At the end, only the ones not found remain
    print('MeshSource:',[m['name'] for k,m in meshSource.items() if m is not None])


    # --- Create a dictionary to indicate the filenames for each source
    sourceFiles = {}
    fileNames =[]
    for meshName, source in meshSource.items():
        if source is not None:
            sourceName = source['name']
            sourceID   = source['id']
            # Modification of sourceName for FileName... TODO
            #if sourceName.find('.')>=0:
            #    sourceName = 'a'+sourceName.replace('*','').replace('.','')
#             if sourceName.find('*')>1:
#                 sourceName = 'a'+sourceName.replace('*','').replace('.','')
            if sourceName.find('*')>1:
                sourceName = sourceName.replace('*','').replace('.','')
            key         = sourceName+'FileName'
            filePattern = [absrootMode + meshName + '.' +fileLeadingZeros + '.vtp']
            sourceFiles[key] = filePattern

            d = {'name': sourceName,'id':sourceID, 'FileName':filePattern}
            fileNames.append(d)
    #print(sourceFiles)

    # --- Load State
    # Look for /paraview/bin/Lib/site-package/paraview/simple.py
    # New read (doesn't work)
    #st = LoadState(StateFile, filenames = fileNames)
    # Legacy reader
    LoadState(StateFile,LoadStateDataFileOptions='Choose File Names',
         DataDirectory=mainDirName,
       **sourceFiles # Legacy
         ) 
    # Example:
    #     st = LoadState(StateFile, LoadStateDataFileOptions='Choose File Names',
    #         DataDirectory=mainDirName,
    #           a5MW_Land_DLL_WTurbMode1LinTime1AD_Blade10FileName =[absrootMode + BladeMesh + '1.' + fileLeadingZeros + '.vtp'],
    #          )
    # 
    # --- find new sources
    def addSources(meshName, sourceName, prefix='', suffix=''):
        """ 
        prefix = rootMode
        suffix = '...vtp'
        """
        if meshName in meshes:
            print('Adding files for Mesh:{}, Source:{}'.format(meshName, sourceName))
            Source = FindSource(prefix + sourceName + suffix)
            if Source is None:
                raise Exception('Cannot find source')
            SetActiveSource(Source)
            ExtendFileSeries(Source)
            return Source


    for meshName, source in meshSource.items():
        if source is not None:
            addSources(meshName, source['name'])

    # --- Delete sources from state file that are not used
    for sourceName in stateSourceNamesNotFound:
        print('Deleting source ', sourceName)
        Src   = FindSource(sourceName)
        Delete(Src)
        del Src
    #####
    SetActiveView(GetRenderView())
    layout = GetLayout()
    animFile= os.path.join(OutputDir, rootSim+'.Mode{:d}.avi'.format(iMode))
    print('Animation    :',animFile)
    WriteAnimation(animFile, viewOrLayout=layout, FrameRate=vFPS[iiMode], ImageResolution=(1544,784), Compression=True)#  ImageResolution=(1544,784) 
    print(' Done.')

