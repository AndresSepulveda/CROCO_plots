close all
load BC1_Fluent.csv
a=BC1_Fluent;
indx0=unique(a(:,1));
for i = 1:length(indx0)
	indx=find(a(:,1) == indx0(i));
	b=a(indx,:);
	indx2=find(b(:,2) == b(1,2));
	c=b(indx2,:);
	h=c(:,4);
	v=c(:,5);
	plot(abs(v),h,'-x')
	pause
end
