from paraview.simple import * 
import os 
import sys
import glob
import numpy as np
paraview.simple._DisableFirstRenderCameraReset()

if len(sys.argv) not in [2,3]:
    print('Error: wrong number of arguments provided.')
    print("""
usage:
    plotModeShapesSimple ROOT_PATH [OUTPUTDIR] [LENTGH]

where:
    ROOT_PATH: Path of the form VTKDIR\ROOTNAME
               where VTKDIR is the directory where vtp files are located 
               Modes and LinTimes will be selected using the pattern:
               ROOT_PATH.Mode*.LinTime*.vtp
    OUTPUTDIR : directory where animation wil be written
    LENGTH   : time length for animation files

""")
    sys.exit(-1)
print('----------------------- plotModeShapesSimple.py-------------------------')
# --- Parameters
movieLength = 3 # animation length in [s]
rootPath    = os.path.normpath(sys.argv[1])
if len(sys.argv)==3:
    OutputDir = os.path.normpath(sys.argv[2])
else:
    OutputDir   = os.path.dirname(os.path.dirname(rootPath))
if len(sys.argv)==4:
    movieLength    =  int(sys.argv[3])


# --- Options TODO
modeNumbers=None # will automatically be detected
wireFrameWidth = 5
# modeNumbers=[5]
Center        = [0,0,50]   # TODO
MaxDim        = 100        # TODO
MeshSupported  = ['Blade{:d}Surface'.format(i) for i in range(3)]
MeshSupported += ['BD_BldMotion{:d}'.format(i) for i in range(3)]
MeshSupported += ['HubSurface', 'NacelleSurface', 'TowerSurface']
#MeshSupported += ['ED_Hub', 'ED_Nacelle', 'ED_TowerLn2Mesh_motion']
wireFrameMesh =['BD_BldMotion1','BD_BldMotion2','BD_BldMotion3']
wireFrameMesh +=['ED_Hub','ED_Nacelle','ED_TowerLn2Mesh_motion']
nBack         = 6.0
print('OutputDir       : {}'.format(OutputDir))


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
    filesNoRoot=[f[len(absrootMode):] for f in files if f.find('DebugError')<0]
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
    filesNoRoot=[f[len(absrootMode):] for f in files if f.find('DebugError')<0]
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


def createSplitLayout():
    """ Create a paraview layout with three views"""
    # --- Create layout
    layout = GetLayoutByName("Layout #1")
    if layout is not None:
        RemoveLayout(layout)
    # create new layout object 'Layout #1'
    layout = CreateLayout(name='Layout #1')
    layout.SetSize(1507, 575)
    # get the material library
    materialLibrary1 = GetMaterialLibrary()
    # Create a new 'Render View'
    renderView1 = CreateView('RenderView')
    renderView1.AxesGrid = 'GridAxes3DActor'
    renderView1.StereoType = 'Crystal Eyes'
    renderView1.CameraFocalDisk = 1.0
    renderView1.BackEnd = 'OSPRay raycaster'
    renderView1.OSPRayMaterialLibrary = materialLibrary1
    # assign view to a particular cell in the layout
    AssignViewToLayout(view=renderView1, layout=layout, hint=0)
    # split cell
    layout.SplitHorizontal(0, 0.5)
    # set active view
    SetActiveView(None)
    # Create a new 'Render View'
    renderView2 = CreateView('RenderView')
    renderView2.AxesGrid = 'GridAxes3DActor'
    renderView2.StereoType = 'Crystal Eyes'
    renderView2.CameraFocalDisk = 1.0
    renderView2.BackEnd = 'OSPRay raycaster'
    renderView2.OSPRayMaterialLibrary = materialLibrary1
    # assign view to a particular cell in the layout
    AssignViewToLayout(view=renderView2, layout=layout, hint=2)
    # set active view
    SetActiveView(renderView2)
    # split cell
    layout.SplitHorizontal(2, 0.5)
    # set active view
    SetActiveView(None)
    # Create a new 'Render View'
    renderView3 = CreateView('RenderView')
    renderView3.AxesGrid = 'GridAxes3DActor'
    renderView3.StereoType = 'Crystal Eyes'
    renderView3.CameraFocalDisk = 1.0
    renderView3.BackEnd = 'OSPRay raycaster'
    renderView3.OSPRayMaterialLibrary = materialLibrary1
    # assign view to a particular cell in the layout
    AssignViewToLayout(view=renderView3, layout=layout, hint=6)
    # resize frame
    layout.SetSplitFraction(0, 0.33)

    return layout, (renderView1, renderView2, renderView3)

def cameraXYZ(renderView1, renderView2, renderView3, Center, MaxDim, nBack=2.5):
    """ set XYZ cameras """
    # X-view
    renderView1.CameraPosition = [ Center[0]-nBack*MaxDim, Center[1], Center[2]]
    renderView1.CameraFocalPoint = Center
    renderView1.CameraParallelScale = 1
    renderView1.CameraViewUp = [0,0,1]
    # Y-view
    renderView2.CameraPosition = [ Center[0], Center[1]-nBack*MaxDim, Center[2]]
    renderView2.CameraFocalPoint = Center
    renderView2.CameraParallelScale = 1
    renderView2.CameraViewUp = [0,0,1]
    # Z-view
    renderView3.CameraPosition = [ Center[0], Center[1], Center[2]-nBack*MaxDim]
    renderView3.CameraFocalPoint = Center
    renderView3.CameraParallelScale = 1
    renderView3.CameraViewUp = [1,0,0]


# --------------------------------------------------------------------------------}
# --- Looping through modes 
# --------------------------------------------------------------------------------{
rootSim = os.path.basename(rootPath)

if modeNumbers is None:
    # Find mode numbers available 
    modeNumbers =  extractModeNumbers(rootPath)
    print('Modes present   : ({}) {}'.format(len(modeNumbers), list(modeNumbers)))

for iMode in modeNumbers:
    print('--------------------------------- MODE {} --------------------------------------'.format(iMode))

    # --- Initialize session
    ResetSession()
    layout, views = createSplitLayout()
    renderView1, renderView2, renderView3 = views

    # --- Extract Mode info (which mesh are present, how many time steps)
    meshes, nZeros, nTimes, Suffix = extractModeInfo(rootPath, iMode)
    timeFormat = '{:0' + str(nZeros) + 'd}'

    print('Meshes       :',meshes)
    print('nTimes       :',nTimes)
    # --- Read data
    nAdded=0
    for meshName in meshes:
        if meshName in MeshSupported:
            print('Reading mesh :',meshName)
            baseName = rootPath+'.Mode{}{}.{:s}.'.format(iMode, Suffix, meshName)
            FileNames = [baseName + timeFormat.format(iTime+1) + '.vtp' for iTime in range(nTimes)]
            obj = XMLPolyDataReader(registrationName=meshName, FileName=FileNames)
            nAdded+=1
            # show data in Views
            for view in views:
                display = Show(obj, view, 'GeometryRepresentation')
                if meshName in wireFrameMesh:
                    display.SetRepresentationType('Wireframe')
                    display.RenderLinesAsTubes = 1
                    display.LineWidth = wireFrameWidth
                else:
                    display.Representation = 'Surface'
        else:
            print('Skipping mesh:',meshName)
    if nAdded==0:
        print('[WARN] no mesh plotted on scene. Skipping this mode.')
        continue
#     bld3 = FindSource(meshName)
#     print('bld3',bld3)
    # --- 
    animationScene1 = GetAnimationScene()
    animationScene1.UpdateAnimationUsingDataTimeSteps()

    # --- Setting Cameras
    cameraXYZ(renderView1, renderView2, renderView3, Center, MaxDim, nBack=nBack)

    # --- Animation
    FPS = np.round(nTimes/movieLength)
    print('FPS          : ', FPS)


    SetActiveView(GetRenderView()) 
    layout = GetLayout()
    animFile= os.path.join(OutputDir,rootSim+'.Mode{:d}.avi'.format(iMode))
    print('Animation    :',animFile)
    WriteAnimation(animFile, viewOrLayout=layout, FrameRate=FPS, ImageResolution=(1544,784), Compression=True)
    print('Done.')
