function [CS, TrObjects] = GIBOK_tibia(Tibia, DistTib, fit_method, result_plots, in_mm, debug_plots)

% check units
if nargin<5;     in_mm = 1;  end
if in_mm == 1;     dim_fact = 0.001;  else;  dim_fact = 1; end
% result plots on by default, debug off
if nargin<4; result_plots = 1; end
if nargin<6; debug_plots = 0; end

% coordinate system structure to store results
CS = struct();

% if this is an entire tibia then cut it in two parts
% but keep track of all geometries
if ~exist('DistTib','var') || isempty(DistTib)
     % Only one mesh, this is a long bone that should be cutted in two
     % parts
      [ProxTib, DistTib] = cutLongBoneMesh(Tibia);
else
    ProxTib = Tibia;
    % join two parts in one triangulation
    Tibia = TriUnite(DistTib, ProxTib);
end

% Get the mean edge length of the triangles composing the tibia
% This is necessary because the functions were originally developed for
% triangulation with constant mean edge lengths of 0.5 mm
PptiesTibia = TriMesh2DProperties( Tibia );

% Assume triangles are equilaterals
meanEdgeLength = sqrt( 4/sqrt(3) * PptiesTibia.TotalArea / Tibia.size(1) );

% Get the coefficient for morphology operations
CoeffMorpho = 0.5 / meanEdgeLength ;

% Get eigen vectors V_all of the Tibia 3D geometry and volumetric center
[ V_all, CenterVol, InertiaMatrix ] = TriInertiaPpties( Tibia );

% Initial estimate of the Inf-Sup axis Z0 - Check that the distal tibia
% is 'below': the proximal tibia, invert Z0 direction otherwise;
Z0 = V_all(:,1);
Z0 = sign((mean(ProxTib.Points)-mean(DistTib.Points))*Z0)*Z0;

% store approximate Z direction and centre of mass of triangulation
CS.Z0 = Z0;
CS.CenterVol = CenterVol;
CS.InertiaMatrix = InertiaMatrix;
CS.V_all = V_all;

% extract the tibia (used to compute the mechanical Z axis)
CS.CenterAnkleInside = GIBOK_tibia_DistMaxSectCentre(DistTib, CS);

% extract the distal tibia articular surface
AnkleArtSurf = GIBOK_tibia_DistArtSurf(DistTib, CS, CoeffMorpho);

% Method to get ankle center : 
%  1) Fit a LS plan to the distal tibia art surface, 
%  2) Inset the plan 5mm
%  3) Get the center of section at the intersection with the plan 
%  4) Project this center Bback to original plan
%-----------
% parameters
%-----------
plane_thick = 5 * dim_fact; 
%-----------
[oLSP_AAS, nAAS] = lsplane(AnkleArtSurf.Points, Z0);
Curves           = TriPlanIntersect( DistTib, nAAS , (oLSP_AAS + plane_thick*nAAS') );

% this gets the larger area (allows tibia to be in the geometry)
[Curve, N_curves, ~] = GIBOK_getLargerPlanarSect(Curves);

% checks how many objects have been sliced
tibia_and_fibula=0;
if N_curves==2
    tibia_and_fibula=1;
    disp('Tibia and Fibula are detected in the triangulation.')
elseif N_curves>2
    warndlg(['Tibia has ', num2str(N_curves), ' section areas .']);
%     error('This should not be the case (only tibia and fibula should be there.')
end

% ankle centre (considers only tibia)
Centre = PlanPolygonCentroid3D( Curve.Pts );
CS.AnkleCenter = Centre - plane_thick * nAAS';
% check ankle centre section
if debug_plots == 1
    plot3(Curve.Pts(:,1), Curve.Pts(:,2), Curve.Pts(:,3)); hold on; axis equal
    plot3(CS.AnkleCenter(1),CS.AnkleCenter(2),CS.AnkleCenter(3),'o')
end

%% Find a pseudo medioLateral Axis
% DIFFERENCE FROM ORIGINAL TOOLBOX
% NB: in GIBOK AnkleArtSurfProperties is calculated from the AnkleArtSurf
% BEFORE the last iteration and filters
AnkleArtSurfProperties = TriMesh2DProperties(AnkleArtSurf);

% Most Distal point of the medial malleolus (MDMMPt)
ZAnkleSurf = AnkleArtSurfProperties.meanNormal;
[~,I] = max(DistTib.Points*ZAnkleSurf);

% define a pseudo-medial axis
if debug_plots==1
    quickPlotTriang(DistTib,'m',1); hold on
end

% Y0 needs to be correct in direction (pointing laterally here and for GIBOK)
% most distal point
MD_Pt = DistTib.Points(I,:);
% vector from most-distal point ro ankle centre.
U_tmp = CS.AnkleCenter-MD_Pt;
col_plot = 'r';
% ASSUMPTION: most distal point will be on tibia (medial) if there is no
% fibula, otherwise it will be lateral, and the vector needs to be
% reversed.
if tibia_and_fibula == 1
    U_tmp = -U_tmp;
    col_plot = 'b';
end

% debug plot for most distal point
if debug_plots == 1;   plotDot(MD_Pt,'k',3) ; end

% Make the vector U_tmp orthogonal to Z0 and normalize it
Y0 = normalizeV(  U_tmp' - (U_tmp*Z0)*Z0  ); 
CS.Y0 = Y0;

%% Proximal Tibia
% isolate tibia proximal epiphysis 
EpiTib = GIBOK_isolate_epiphysis(ProxTib, Z0, 'proximal');

%============
% ITERATION 1 
%============
%Identify raw Articular Surfaces (AS) based on curvature
%--------------
% parameters
%--------------
angle_thresh = 35;% deg
curv_quartile = 0.25;
%--------------
[EpiTibAS, oLSP, Ztp] = GIBOK_tibia_FullProxArtSurf(EpiTib, CS, CoeffMorpho, angle_thresh, curv_quartile);

% debug plots
if debug_plots == 1
    quickPlotTriang(EpiTibAS, [], 1);hold on
    title('STEP1: Full proximal Articular Surface')
end

% remove the ridge and the central part of the surface
EpiTibAS = GIBOK_tibia_ProxArtSurf_it1(ProxTib, EpiTib, EpiTibAS, CS, Ztp , oLSP, CoeffMorpho);

% debug plots
if debug_plots == 1
    quickPlotTriang(EpiTibAS, [], 1);hold on
    title('STEP2: Full proximal Articular Surface (central ridge removed)')
end

% Smooth found ArtSurf
EpiTibAS = TriOpenMesh(EpiTib,EpiTibAS, 15*CoeffMorpho);
EpiTibAS = TriCloseMesh(EpiTib,EpiTibAS, 30*CoeffMorpho);

%==================
% ITERATION 2 & 3 
%==================
[EpiTibASMed, EpiTibASLat, ~] = GIBOK_tibia_ProxArtSurf_it2(EpiTib, EpiTibAS, CS, CoeffMorpho);

% builld the triangulation
% EpiTibAS3 is the final triang of the articular surfaces
EpiTibAS3 = TriUnite(EpiTibASMed, EpiTibASLat);

% debug plots
if debug_plots == 1
    quickPlotTriang(EpiTibAS3, [], 1);hold on
    title('STEP3: Final Articular Surface (refined)')
end

% compute joint coord system
switch fit_method
    case 'ellipse'
        % fit an ellipse to the articular surface
        [CS, JCS] = CS_tibia_Ellipse(EpiTibAS3, CS);
    case 'centroids'
        % uses the centroid of the articular surfaces to define the Z axis
        [CS, JCS] = CS_tibia_ArtSurfCentroids(EpiTibASMed, EpiTibASLat, CS);
    case 'plateau'
        [CS, JCS] = CS_tibia_PlateauLayer(EpiTib, EpiTibAS3, CS);
    otherwise
        error('GIBOK_tibia.m ''method'' input has value: ''ellipse'', ''centroids'' or ''plateau''.')
end

% define segment ref system
CS.V = JCS.knee_r.V;
CS.Origin = CenterVol;

% CS.Y = mech axis
% CS.X = perp to plane YZ
% CS.Z = XY

if result_plots == 1
    
    figure

    % plot entire tibia 
    subplot(2,2,[1,3])
    PlotTriangLight(Tibia, CS, 0);
    quickPlotRefSystem(JCS.knee_r)
    quickPlotTriang(EpiTibASMed,'r');
    quickPlotTriang(EpiTibASLat,'b');
    quickPlotTriang(AnkleArtSurf, 'g');

    % plot proximal tibia
    subplot(2,2,2)
    alpha_AS = 0.3;
    PlotTriangLight(ProxTib, CS, 0);
    switch fit_method
        case 'ellipse'
            quickPlotTriang(EpiTibAS3,'g', 0, alpha_AS );
            quickPlotRefSystem(JCS.knee_r)
        case 'centroids'
            quickPlotTriang(EpiTibASMed,'r', 0, alpha_AS );
            quickPlotTriang(EpiTibASLat,'b',0, alpha_AS);
            plotDot(CS.Centroid_AS_lat, 'b', 4);
            plotDot(CS.Centroid_AS_med, 'r', 4);
            plotCylinder((CS.Centroid_AS_lat-CS.Centroid_AS_med)', 3, (CS.Centroid_AS_lat+CS.Centroid_AS_med)/2,...
                1.7*norm(CS.Centroid_AS_lat-CS.Centroid_AS_med), 1, 'k');
        case 'plateau'
            quickPlotTriang(EpiTibAS3,'g', 0, alpha_AS );
            quickPlotRefSystem(JCS.knee_r)
    end

    % plot distal tibia
    subplot(2,2,4)
    PlotTriangLight(DistTib, CS, 0);
    quickPlotTriang(AnkleArtSurf, 'g');
    plotDot(CS.AnkleCenter, 'g', 4);
%     plotDot(CS.CenterAnkleInside, 'y', 4);
    plotDot(MD_Pt,col_plot,3); % color changes dep on tibia/fib presence

end


%% Inertia Results
% Yi = V_all(:,2); Yi = sign(Yi'*Y0)*Yi;
% Xi = cross(Yi,Z0);
% 
% CSs.CenterAnkle2 = CenterAnkleInside;
% CSs.CenterAnkle = ankleCenter;
% CSs.Zinertia = Z0;
% CSs.Yinertia = Yi;
% CSs.Xinertia = Xi;
% CSs.Minertia = [Xi Yi Z0];

end

