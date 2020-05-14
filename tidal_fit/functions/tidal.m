function [Ures,Vres,U0,V0]=tidal(profile,dates,U,V)

% this function makes a tidal adjustement on U,V current components and
% calcs the residual current. Be careful with your dt input data and your
% request on tidal components, keep in mind the nyquist frequency
% 
% input_
%
% profile    : vector with heigth/depth/pressure levels
% dates      : vector with time levels, can be in time format or a simple vector of dt increase
% U          : matrix U component of size profile x dates
% V          : matrix V component of size profile x dates
%
% Author              : chsegura@udec.cl
% Last modification   : 2020-05-07

%% settings

if size(dates,2)>1
    dates=dates';
end

Ures=NaN(size(U));
Vres=NaN(size(V));

for i=1:size(U,1)
observed=U(i,:)';
data=[dates,observed];

[tidal,const]=tidalfitvar(data,{'M2','S2','O1','K1'});% you can add more components!
predicted=tidal;    

residual=observed-predicted;

U0(i,1)=const;
Ures(i,:)=residual;
end

for i=1:size(V,1)
observed=V(i,:)';
data=[dates,observed];

[tidal,const]=tidalfitvar(data,{'M2','S2','O1','K1'});
predicted=tidal;    

residual=observed-predicted;

V0(i,1)=const;
Vres(i,:)=residual;
end

return
