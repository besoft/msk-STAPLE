function PlotFemur( CS, TrObjects )
%PLOTFEMUR Display figures of the femur
%   Detailed explanation goes here

figure()
% Plot the whole tibia, here TrObjects.Femur is a Matlab triangulation object
trisurf(TrObjects.Femur,'Facecolor',[0.65    0.65    0.6290],'FaceAlpha',1,'edgecolor','none');
hold on
axis equal

% handle lighting of objects
light('Position',CS.Origin' + 500*CS.Y + 500*CS.X,'Style','local')
light('Position',CS.Origin' + 500*CS.Y - 500*CS.X,'Style','local')
light('Position',CS.Origin' - 500*CS.Y + 500*CS.X - 500*CS.Z,'Style','local')
light('Position',CS.Origin' - 500*CS.Y - 500*CS.X + 500*CS.Z,'Style','local')
lighting gouraud

% Remove grid
grid off

%% Figure 2
figure()

% Here TrObjects.DistFem, TrObjects.EpiFemASMed and TrObjects.EpiFemASLat are Matlab triangulation objects
% The found Articular Surfaces are separated from the rest of the bone triangulation object
DistFem = TriDifferenceMesh( TrObjects.DistFem, TrObjects.EpiFemASLat);
DistFem = TriDifferenceMesh( DistFem, TrObjects.EpiFemASMed);
DistFem = TriDilateMesh(TrObjects.DistFem,DistFem,1);

trisurf(DistFem,'Facecolor',[0.65    0.65    0.6290],'FaceAlpha',0.7,'edgecolor','none');
hold on
axis equal


% Plot the identified articular surfaces
trisurf(TrObjects.EpiFemASLat,'Facecolor','r','FaceAlpha',1,'edgecolor','none');
trisurf(TrObjects.EpiFemASMed,'Facecolor','b','FaceAlpha',1,'edgecolor','none');

% handle lighting of objects
light('Position',CS.Origin' + 500*CS.Y + 500*CS.X,'Style','local')
light('Position',CS.Origin' + 500*CS.Y - 500*CS.X,'Style','local')
light('Position',CS.Origin' - 500*CS.Y + 500*CS.X - 500*CS.Z,'Style','local')
light('Position',CS.Origin' - 500*CS.Y - 500*CS.X + 500*CS.Z,'Style','local')
lighting gouraud

% % transforming to ISB ref system
% ISB2GB = [1  0  0
%           0  0 -1
%           0  1 0];
% GB2Glob = CS.V;
% CS.X = GB2Glob*ISB2GB*[1 0 0]';
% CS.Y = GB2Glob*ISB2GB*[0 1 0]';
% CS.Z = GB2Glob*ISB2GB*[0 0 1]';
% 
% using standard colors
plotArrow( CS.X, 1, CS.Origin, 30, 1, 'r')
plotArrow( CS.Y, 1, CS.Origin, 30, 1, 'g')
plotArrow( CS.Z, 1, CS.Origin, 30, 1, 'b')


% Remove grid
grid off

end