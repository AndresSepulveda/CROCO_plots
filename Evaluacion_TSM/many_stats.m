function [samples bias rmse si d slope bs as d2 conf] = many_stats(X,Y)

%
% N
%
samples=length(X);
%
% Bias
%
bias=mean(X-Y);
%
% RMSE
%
rmse=sqrt((1/(length(X)-1))*sum((X-Y).*(X-Y)));
%
%  Scatter Index
%
si=rmse/mean(X);
%
% Willmot Index
%
anomm=abs(X-mean(Y));
anoms=abs(Y-mean(Y));
difanom=anomm+anoms;
d=1-(sum((X-Y).*(X-Y))/sum(difanom.*difanom));
%
% Slope
%
slope=(sum(X.*Y)/sum(X.*X));
%
% Inertial slope (bs) and Intercept (as)
%
yx = cov(X,Y); 
Syx = Syx(1,2); 
Sxy = Syx; 
Sxx = cov(X); 
byx = Syx/Sxx; 
ayx = mean(Y) - byx*mean(X);
Syy = cov(Y); 
bxy = Syy/Syx; 
axy = mean(X) - bxy*mean(Y);
bs = sqrt(byx*bxy);                % Inertial Slope
as = mean(Y) - bs*mean(X);         % Inertial Intercept
d2=(bs.*X -Y + as);
d2=d2.*d2;
d2=d2./(1+bs.*bs);
d2=sqrt(mean(d2));
%
% Percentage of data within +/- 2std
%
jj=[];
jj=find((X-Y <= mean(X-Y) + 2*std(X-Y)) & (X-Y >= mean(X-Y) - 2*std(X-Y))); 
conf=length(jj)*100/length(X)


%fprintf(' N    =%6.0f\n\r MEAN =%8.4f M \n \r STD  =%8.4f M \n\r CONF =%8.2f \n' , length(X), mean(X-Y), std(X-Y) , conf);
%fprintf(' SLOPE= %8.4f\n\r INT  = %8.4f \n \r DIST = %8.4f \n' , bs, as, sqrt(mean(d2)) );

%%		tbl_c=[tbl_c; [indx(i) totsamples totbias totrmse totsi totslope totd]];
%
%dlmwrite('Table_Oceanic_J2.txt',tbl_o,'delimiter',' ','precision',5)
%


