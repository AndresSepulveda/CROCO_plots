function [mld]=ra_mld(salt,temp,Z,dT)
% It is quasi homogeneous layer in the upper ocean where variation of density is negligible. 
%===========================================================%
% RA_MLD  $Id: ra_mld.m, 2015/01/14 $
%          Copyright (C) CORAL-IITKGP, Ramkrushn S. Patel 2014.
%
% AUTHOR: 
% Ramkrushn S. Patel (ramkrushn.scrv89@gmail.com)
% Roll No: 13CL60R05
% Place: IIT Kharagpur.
% This is a part of M. Tech project under the supervision of DR. ARUN CHAKRABORTY
%===========================================================%
%
% USAGE: MLD=ra_mld(salt,temp,Z,dT)
% 
% PREREQUISITE: you must have installed SW Package or you must have
% following function from Sea Water package
% sw_den.m ; sw_dens.m; sw_dens0.m; sw_seck.m; sw_smow.m
% 
% DESCRIPTION:  This function determines Mixed Layer Depth (MLD) from profile data
% sets based on subjective method. If you have 3D data sets i.e. level, lat and lon and want 
% to compute the MLD, then this function will be very handy. Because this function is 
% specifically designed for those cases. However, it can evaluate MLD from profile data too.
% 
% INPUTS: 
% salt = Salinity profiles over the study region [psu], either 3D or vector
% temp = Temperature profiles over the study region [deg. C], either 3D or vector
% Z = Levels [m], Must be vector
% dT = temperature difference criterion [deg. C], Must be scalar
%
% OUTPUT: 
% mld = mixed layer depth, spatial output [m]
% 
% DISCLAIMER: 
% Albeit this function is designed only for academic purpose, it can be implemented in 
% research. Nonetheless, author does not guarantee the accuracy.
% 
% REFERENCE:
% de Boyer Mont�gut, C., Madec, G., Fischer, A. S., Lazar, L. and Iudicone, D., Mixed, 2004:  
% layer depth over the global ocean: an examination of profile data and a profile-based 
% climatology. Journal of Geophysical Research, 109, C12003.
%
% ACKNOWLEDGMENT:
% Author is grateful to MathWorks and CSIRO for developing in built functions and 
% basic function for sea water property respectively. I would like to acknowledge Dr. Sudip Jana
% who provided basic algorithm to compute MLD.
% ***********************************************************************************************%
% Taking care of sufficient input agrument
if ((nargin < 3) || (nargin > 4))
   error('ra_mld.m: Must pass minimum 3 parameters')
end 
% Optional value
if (nargin == 3)
    dT=[];
    str='U R using DEFAULT value for TEMP Difference Criterion: dT = 1';
    warning(['ra_mld.m: ', str])  %#ok<WNTAG>
end
if (isempty(dT))
    dT=1; % desire temperature difference criterion (deltaT)
end
% Check : S & T must have same shape
[sn1, sn2, sn3]=size(salt); % n1, n2, n3 stands for level, latitude
[tn1, tn2, tn3]=size(temp);  % longitude respectively. 
if (size(salt) ~= size(temp))
    error('ra_mld.m: SALT & TEMP must have same shape')
end
if ((sn2 == tn2) && (sn3 == tn3))
    lt=sn2; 
    ln=sn3;
else
    error('ra_mld.m: Dimension mismatch - check SALT & TEMP')
end
if ((sn1 ~= length(Z)) || (tn1 ~= length(Z)))
    error('ra_mld.m: Check_Z - level must be same as ')
end
if (numel(dT) ~= 1)
    error('ra_mld.m: DT must be scalar'); end
% Post processing of the Data sets
% Salinity data
S=reshape(salt, sn1, sn2*sn3);
land=isnan(salt(1, :)); % Land portion location
S(:,land)=[]; % removing land data
[sn4, sn5]=size(S);
% Temp data
T=reshape(temp, tn1, tn2*tn3);
oce= ~isnan(temp(1, :)); % Not land portion since land portion is NAN
land=isnan(temp(1, :)); % Land portion location
T(:, land)=[]; % removing land data
[tn4, tn5]=size(T);
% Check dimension of S & T for oceanic portion
if ((sn4 == tn4) && (sn5 == tn5))
    n5=sn5; 
else
    error('ra_mld.m: Oceanic portion of data set is not same')
end
% Mixed Layer Depth computation
mldepth=NaN(n5, 1);
for ii=1:n5
    s=S(:, ii);
    t=T(:, ii);
    sst_dT=t(1) - dT;
    sigma_t=sw_dens(s, t, 0) - 1000;
    sigma_dT=sw_dens(s(1), sst_dT, 0) - 1000;
    pos1=find(sigma_t > sigma_dT);
    if ((numel(pos1) > 0) && (pos1(1) > 1))
        p2=pos1(1);
        p1=p2-1;
        mldepth(ii)=interp1(sigma_t([p1, p2]), Z([p1, p2]), sigma_dT);
    else
        mldepth(ii)=NaN;
    end % endif
end % endfor
mld=NaN*ones(1, lt*ln);
mld(oce)=mldepth;
mld=reshape(mld, lt, ln);