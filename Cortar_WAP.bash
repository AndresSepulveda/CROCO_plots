for i in
   ncea -d lat,-70,-66 -d lon,-74,-64 WAP_1k_avg_0${i}.nc Marga_1k_avg_0${i}.nc
end

ncrcat Marga_1k_avg_0???.nc  Marga_1k_avg_all.nc

rm Marga_1k_avg_0???.nc

%%%%ncks -C -O -x -v sat -v Marga_1k_avg_all.nc.nc out.nc
