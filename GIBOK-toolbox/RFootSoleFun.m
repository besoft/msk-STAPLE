%% Initial Set up 
clearvars
close all
addpath(genpath(strcat(pwd,'/SubFunctions')));

%% Read the mesh of the Foot file

% [Foot] = ReadMesh('../test_geometries/TLEM2/foot_r.stl');
% [Foot] = ReadMesh('../test_geometries/LHDL_CT/calcn_r.stl');

cwd = 'C:\Users\jbapt\Documents\Research\auto-msk-model\test_geometries';
% load( strcat(cwd, '\TLEM2_MRI_tri\calcn_l.mat') )
% load( strcat(cwd, '\TLEM2_MRI_tri\calcn_r.mat') )
% load( strcat(cwd, '\TLEM2_CT_tri\calcn_l.mat') )
% load( strcat(cwd, '\TLEM2_CT_tri\calcn_r.mat') )
% load( strcat(cwd, '\P0_MRI_tri\calcn_r.mat') )
% load( strcat(cwd, '\LHDL_CT_tri\calcn_l.mat') )
load( strcat(cwd, '\LHDL_CT_tri\calcn_r.mat') )

Foot = curr_triang;
% Foot = ReadMesh(strcat(cwd,'\JIA_CSm6\calcn_r.stl'));

% Need to account for cases where the foot is subidivided into multiple 
% meshes. 
% Foot define here all the bone distal to the ankle joint except from the
% Talus. Phalanges are not mandatory and their presence or absence
% should not impact the results.

%========================
% LUCA's COMMENT
%========================
% The mesh you have chosen for development is special, in the sense that
% normally in building models we do not attach the phalanges to the rest of
% the foot, but we have 1) talus, 2) calcn+all other bones, 3)
% toes/phalanges.
% trying your script with data more similar to the one we use, e.g.
% [Foot] = ReadMesh('../test_geometries/TLEM2_CT/calcn_r.stl');
% it seems to work very nicely, and the blu plane is exactly what I was
% looking for, without even need for cutting the mesh.
%========================

% 1. Indentify initial CS of the foot
% Get eigen vectors V_all of the Talus 3D geometry and volumetric center
[ V_all, CenterVol, InertiaMatrix, D ] = TriInertiaPpties( Foot );

X0 = V_all(:,1); Y0 = V_all(:,2); Z0 = V_all(:,3);

% Get least square plane normal vector of the foot
[~,Z0] = lsplane(Foot.Points);
Y0 = normalizeV(cross(Z0,X0));
Z0 = cross(X0,Y0);

%Visually check the Inertia Axis orientation relative to the Talus geometry
figure()
% Plot the whole talus, here Talus is a Matlab triangulation object
trisurf(Foot,'Facecolor',[0.65    0.65    0.6290],'FaceAlpha',.6,'edgecolor','none');
hold on
axis equal

% handle lighting of objects
light('Position',CenterVol' + 500*Y0' + 500*X0','Style','local')
light('Position',CenterVol' + 500*Y0' - 500*X0','Style','local')
light('Position',CenterVol' - 500*Y0' + 500*X0' - 500*Z0','Style','local')
light('Position',CenterVol' - 500*Y0' - 500*X0' + 500*Z0','Style','local')
lighting gouraud

% Remove grid
grid off

%Plot the inertia Axis & Volumic center
plotDot( CenterVol', 'k', 2 )
plotArrow( X0, 1, CenterVol, 150, 1, 'r')
plotArrow( Y0, 1, CenterVol, 50, 1, 'g')
plotArrow( Z0, 1, CenterVol, 50, 1, 'b')

% 2. Get a convex hull of the Foot
[x, y, z] = deal(Foot.Points(:,1), Foot.Points(:,2), Foot.Points(:,3));

% K = convhull(x,y,z,'simplify', false);

[ IdxPtsPair , EdgesLength , K] = LargestEdgeConvHull(Foot.Points);

% trisurf(K,x,y,z,'Facecolor','c','FaceAlpha',.2,'edgecolor','k');
% for i = 1:10
%     plot3(x(IdxPtsPair(i,:)),y(IdxPtsPair(i,:)),z(IdxPtsPair(i,:)),...
%         'k-*','linewidth',2)
% end
%% Convexhull approach with prior deleting of the phalanges

% In the vast majority of cases, the reference system at the foot is
% computed using the geometries from talus to metatarsal bone, without the
% phalanges.
% This part of code is not needed
%==========================================
% Foot_Start = min(Foot.Points*X0);
% Foot_End = max(Foot.Points*X0);
% Foot_Length = Foot_End - Foot_Start; 
% ElmtsNoPhalange= find(Foot.incenter*X0 < (Foot_Start+0.80*Foot_Length));
% Foot2 = TriReduceMesh( Foot, ElmtsNoPhalange );
%==========================================

Foot2 = Foot;
% K = convhull(x,y,z,'simplify', false);
[x, y, z] = deal(Foot2.Points(:,1), Foot2.Points(:,2), Foot2.Points(:,3));
[ IdxPtsPair , EdgesLength , K] = LargestEdgeConvHull(Foot2.Points);

trisurf(K,x,y,z,'Facecolor','c','FaceAlpha',.2,'edgecolor','k');
for i = 1:round(0.02*length(IdxPtsPair))
    plot3(x(IdxPtsPair(i,:)),y(IdxPtsPair(i,:)),z(IdxPtsPair(i,:)),...
        'k-*','linewidth',2)
end

% Convert the convexHull to triangulation object
Foot2_CH = triangulation(K,x,y,z);
[V_all_CH, CenterVol_CH] = TriInertiaPpties( Foot2_CH );

% Get a vector superior to inferior from the center of the foot and its
% convex hull to creat a new temporary coordinate system R1
Ucenters0 = normalizeV(CenterVol_CH - CenterVol);
Ucenters = Ucenters0 - (Ucenters0'*X0)*X0;
Z1 = normalizeV(Ucenters);
X1 = X0;
Y1 = cross( Z1, X1 );

% Project the convex hull along the previously found direction
XY1 = [X1,Y1];
ProjZ1 = XY1*inv(XY1'*XY1)*XY1';

Foot2_CH_PTS_Proj = (ProjZ1*Foot2_CH.Points')';
Foot2_CH_Proj = triangulation(Foot2_CH.ConnectivityList, Foot2_CH_PTS_Proj);

% Find the largest triangle on the projected Convex Hull
[ Foot2_CH_Proj_Ppties ] = TriMesh2DProperties( Foot2_CH_Proj );
[~,I] = max(Foot2_CH_Proj_Ppties.Area);

trisurf(Foot2_CH.ConnectivityList(I,:),x,y,z,'Facecolor','b','FaceAlpha',1,'edgecolor','k');



%% Get the three points of interest 
%   1.  Select from the longest edges those which are below a plan 
%       parallel to the one defined by the largest triangle (the start and
%       end of those edges must be below that plan)
%   2.  Cluster the points defining the largest edges in 3 clusters
%   3.  Associate the the cluster to the medial and lateral distal points
%       of the triangles
%   4.  Get the the points as the furthest one from the ones from the
%       triangles
%   5.  Keep the proximal vertices of the triangle as the calcaneus tip






%% This section will certainly disappear in the terminal version

% Get neighbour facets of the largest one if the normal are not too
% different
n0 = Foot2_CH.faceNormal(I);

N = neighbors(Foot2_CH);
Nghbrs0=I;
Nghbrs_c=I;
for i = 1:2
    Nghbrs_c = N(Nghbrs_c,:);
    Nghbrs0 = unique([Nghbrs0(:) ; Nghbrs_c(:)]);
end

Nghbrs_OK = [];
for f = Nghbrs0   
    if n0*Foot2_CH.faceNormal(f)' > 0.9994
        Nghbrs_OK(end+1) = f
    end
end  

% Project all the facet in the plane associated to the largest facet

% Compute the 2D convhull of the projected facet found the two longest side
% The 3 or 4 points defined by the two longest side are the one ore two pts
% of the calcaneus et the 1st and 5th metatarse points


%% Try to find the direction of the meta

for i =1:5
    Foot_Start = min(Foot.Points*X0);
    Foot_End = max(Foot.Points*X0);
    Foot_Length = Foot_End - Foot_Start;
    
    % Keep only Meta -> Points located between 50% and 66% of the foot length
    ElmtsMeta = find(Foot.incenter*X0 > (Foot_Start+0.50*Foot_Length) &...
        Foot.incenter*X0 < (Foot_Start+0.66*Foot_Length));
    Meta = TriReduceMesh( Foot, ElmtsMeta );
    
    % Get least square plane normal vector of the foot
    [a,Z0] = lsplane(Foot.Points);
    Y0 = normalizeV(cross(Z0,X0));
    X0 = cross(Y0,Z0);
end


