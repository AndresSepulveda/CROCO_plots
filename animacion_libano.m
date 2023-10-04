start

j=2
if j < 2
	for i = 1:365
	i
 	horizslice('croco_his.nc.Y3','temp',i,-1,[0 0 0 0],1,0,...
                     15,30,[],37.0,30,38,...
                    10,1,'100 500',3,1,0.1,...
                    'coastline_f.mat','town.dat','croco_his.nc.Y3',[],[],NaN)
	if i < 999
	  fname=['Lebanon_SST_',num2str(i),'.png'];
	end
	if i < 99
	  fname=['Lebanon_SST_0',num2str(i),'.png'];
	end
	if i < 9
	  fname=['Lebanon_SST_00',num2str(i),'.png'];
	end
	  print('-dpng',fname)
	close all
        end
end
if j > 1
	for i = 1:365
	i
 	horizslice('croco_his.nc.Y3','*Speed',i,-1,[0 0 0 0],1,0,...
                     0,0.50,[],37.0,30,38,...
                    10,1,'100 500',3,1,0.1,...
                  'coastline_f.mat','town.dat','croco_his.nc.Y3',[],[],NaN)
	if i < 999
	  fname=['Lebanon_SSM_',num2str(i),'.png'];
	end
	if i < 99
	  fname=['Lebanon_SSM_0',num2str(i),'.png'];
	end
	if i < 9
	  fname=['Lebanon_SSM_00',num2str(i),'.png'];
	end
	  print('-dpng',fname)
	close all
        end
end



%horizslice(hisfile,vname,tindex,vlevel,rempts,coef,gridlevs,...
%                    colmin,colmax,lonmin,lonmax,latmin,latmax,...
%                    ncol,pltstyle,isobath,cstep,cscale,cunit,...
%                    coastfile,townfile,gridfile,h0,handles,Yorig)
