function CSs = createFemurCoordMiranda2010(DistFem, CSs)

%% Compute the femur diaphysis axis
Z0 = CSs.Z0;
Alt = linspace( min(DistFem.Points*Z0)+0.1 ,max(DistFem.Points*Z0)-0.1, 200);
Area=[];
for d = Alt
    [ Curves , Area(end+1), ~ ] = TriPlanIntersect(DistFem, Z0 , d );
end

[maxArea,ImaxArea] = max(Area);

[~,Id] = min(abs(maxArea/2-Area(ImaxArea:end)));

Loc1 = Alt(ImaxArea);
Loc2 = Alt(ImaxArea+Id);

dd = Loc2 - min(Alt);


% ElmtsDia = find(DistFem.incenter*Z0>(dd+1.3*(dd-min(Alt))));
% ElmtsEpi = find(DistFem.incenter*Z0<(dd+1.3*(dd-min(Alt))));

ElmtsDia = find(DistFem.incenter*Z0>(min(Alt) + 1.3*dd));
ElmtsEpi = find(DistFem.incenter*Z0<(min(Alt) + 1.3*dd));

DiaFem = TriReduceMesh( DistFem, ElmtsDia );
DiaFem = TriFillPlanarHoles(DiaFem);

[ DiaFem_InertiaMatrix, DiaFem_Center ] = InertiaProperties( DiaFem.Points, DiaFem.ConnectivityList );
% probably alternative
% [ V_all, CenterVol ] = TriInertiaPpties( Femur );

[V_DiaFem,~] = eig(DiaFem_InertiaMatrix);

Zdia = V_DiaFem(:,1);

EpiFem = TriReduceMesh( DistFem, ElmtsEpi );

%% Find Pt1 described in their method

LinePtNodes = bsxfun(@minus, EpiFem.Points, DiaFem_Center');

CP = (cross(repmat(Zdia',length(LinePtNodes),1),LinePtNodes));

Dist = sqrt(sum(CP.^2,2));
[~,IclosestPt] = min(Dist);
Pt1 = EpiFem.Points(IclosestPt,:);


%% Find Pt2
% Get the curves of the cross section at 
[ Curves , ~, ~ ] = TriPlanIntersect(DistFem.Points, DistFem.ConnectivityList, Z0 , min(Alt) + dd );

% Get the center of the bounding box inertial axis algined
NewPts = V_all'*Curves.Pts'; NewPts = NewPts';
CenterCS_0 = [mean(NewPts(:,1)),0.5*(min(NewPts(:,2))+max(NewPts(:,2))),0.5*(min(NewPts(:,3))+max(NewPts(:,3)))];
CenterCS = V_all*CenterCS_0';

% IDX = knnsearch(Curves.Pts,CenterCS','K',100);
IDX = knnsearch(Curves.Pts,CenterCS');

Uap = Curves.Pts(IDX,:)-CenterCS';
Uap = Uap'/norm(Uap);

PosteriorPts = Curves.Pts(Curves.Pts*Uap>CenterCS'*Uap,:);


% ClosestPts = Curves.Pts(IDX,:);


% The Point P2

LinePtNodes = bsxfun(@minus, PosteriorPts, CenterCS');

CP = (cross(repmat(X0',length(LinePtNodes),1),LinePtNodes));

Dist = sqrt(sum(CP.^2,2));
[~,IclosestPt] = min(Dist);
Pt2 = PosteriorPts(IclosestPt,:);

tic
%% Define first plan iteration
npcs = cross( Pt1-Pt2, Y0); npcs = npcs'/norm(npcs);

if (Center0'-Pt1)*npcs > 0
    npcs = -npcs;
end

ElmtsDPCs = find(EpiFem.incenter*npcs > Pt1*npcs);
PCsFem = TriReduceMesh( EpiFem, ElmtsDPCs );

% First Cylinder Fit
Axe0 = Y0';
Radius0 = 0.5*(max(PCsFem.Points*npcs)-min(PCsFem.Points*npcs));

[x0n, an, rn, d] = lscylinder(PCsFem.Points(1:3:end,:), mean(PCsFem.Points)' - 2*npcs, Axe0, Radius0, 0.001, 0.001);

%% Define second plan iteration
npcs = cross( Pt1-Pt2, an); npcs = npcs'/norm(npcs);

if (Center0'-Pt1)*npcs > 0
    npcs = -npcs;
end

ElmtsDPCs = find(EpiFem.incenter*npcs > Pt1*npcs);
PCsFem = TriReduceMesh( EpiFem, ElmtsDPCs );

% Second and last Cylinder Fit
Axe0 = an/norm(an);
Radius0 = rn;

[x0n, an, rn, d] = lscylinder(PCsFem.Points(1:3:end,:), x0n, Axe0, Radius0, 0.001, 0.001);



EpiPtsOcyl_tmp = bsxfun(@minus,PCsFem.Points,x0n');

CylStart = min(EpiPtsOcyl_tmp*an)*an' + x0n';
CylStop = max(EpiPtsOcyl_tmp*an)*an' + x0n';

CylCenter = 1/2*(CylStart + CylStop);

Results.Yend_Miranda = an;
Results.Xend_Miranda = cross(an,Zdia); 
Results.Xend_Miranda = Results.Xend_Miranda  / norm(Results.Xend_Miranda);
Results.Zend_Miranda = cross(Results.Xend_Miranda,Results.Yend_Miranda);
Results.CenterKnee_Miranda = CylCenter;

end
