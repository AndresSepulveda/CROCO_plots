#
# Y1
#

gzip -d Odette_fisica_Y1S1.nc.gz
ncra -F -d time,1,3 Odette_fisica_Y1S1.nc Odette_fisica_Y1_EFM.nc
ncra -F -d time,4,6 Odette_fisica_Y1S1.nc Odette_fisica_Y1_AMJ.nc
gzip Odette_fisica_Y1S1.nc &

gzip -d Odette_fisica_Y1S2.nc.gz
ncra -F -d time,1,3 Odette_fisica_Y1S2.nc Odette_fisica_Y1_JAS.nc
ncra -F -d time,4,6 Odette_fisica_Y1S2.nc Odette_fisica_Y1_OND.nc
gzip Odette_fisica_Y1S2.nc &

#
# Y2
#

gzip -d Odette_fisica_Y2S1.nc.gz
ncra -F -d time,1,3 Odette_fisica_Y2S1.nc Odette_fisica_Y2_EFM.nc
ncra -F -d time,4,6 Odette_fisica_Y2S1.nc Odette_fisica_Y2_AMJ.nc
gzip Odette_fisica_Y2S1.nc &

gzip -d Odette_fisica_Y2S2.nc.gz
ncra -F -d time,1,3 Odette_fisica_Y2S2.nc Odette_fisica_Y2_JAS.nc
ncra -F -d time,4,6 Odette_fisica_Y2S2.nc Odette_fisica_Y2_OND.nc
gzip Odette_fisica_Y2S3.nc &

#
# Y3
#

gzip -d Odette_fisica_Y3S1.nc.gz
ncra -F -d time,1,3 Odette_fisica_Y3S1.nc Odette_fisica_Y3_EFM.nc
ncra -F -d time,4,6 Odette_fisica_Y3S1.nc Odette_fisica_Y3_AMJ.nc
gzip Odette_fisica_Y3S1.nc &


#
# PISCES
#

#
# Y1
#

gzip -d Odette_Y1S1.nc.gz
ncra -F -d time,1,3 Odette_Y1S1.nc Odette_Y1_EFM.nc
ncra -F -d time,4,6 Odette_Y1S1.nc Odette_Y1_AMJ.nc
gzip Odette_Y1S1.nc &

gzip -d Odette_Y1S2.nc.gz
ncra -F -d time,1,3 Odette_Y1S2.nc Odette_Y1_JAS.nc
ncra -F -d time,4,6 Odette_Y1S2.nc Odette_Y1_OND.nc
gzip Odette_Y1S1.nc &

#
# Y2
#

gzip -d Odette_Y2S1.nc.gz
ncra -F -d time,1,3 Odette_Y2S1.nc Odette_Y2_EFM.nc
ncra -F -d time,4,6 Odette_Y2S1.nc Odette_Y2_AMJ.nc
gzip Odette_Y2S1.nc &

gzip -d Odette_Y2S2.nc.gz
ncra -F -d time,1,3 Odette_Y2S2.nc Odette_Y2_JAS.nc
ncra -F -d time,4,6 Odette_Y2S2.nc Odette_Y2_OND.nc
gzip Odette_fisica_Y2S1.nc &

#
# Y3
# 

gzip -d Odette_Y3S1.nc.gz
ncra -F -d time,1,3 Odette_Y3S1.nc Odette_Y3_EFM.nc
ncra -F -d time,4,6 Odette_Y3S1.nc Odette_Y3_AMJ.nc
gzip Odette_Y2S1.nc &

#
#  PISCES
#


#
# Y1
#
ncks -A Odette_Y1_EFM.nc Odette_fisica_Y1_EFM.nc
mv Odette_fisica_Y1_EFM.nc Odette_PISCES_Y1_EFM.nc

ncks -A Odette_Y1_AMJ.nc Odette_fisica_Y1_AMJ.nc
mv Odette_fisica_Y1_AMJ.nc Odette_PISCES_Y1_AMJ.nc

ncks -A Odette_Y1_JAS.nc Odette_fisica_Y1_JAS.nc
mv Odette_fisica_Y1_JAS.nc Odette_PISCES_Y1_JAS.nc

ncks -A Odette_Y1_OND.nc Odette_fisica_Y1_OND.nc
mv Odette_fisica_Y1_OND.nc Odette_PISCES_Y1_OND.nc

#
# Y2
#
ncks -A Odette_Y2_EFM.nc Odette_fisica_Y2_EFM.nc
mv Odette_fisica_Y2_EFM.nc Odette_PISCES_Y2_EFM.nc

ncks -A Odette_Y2_AMJ.nc Odette_fisica_Y2_AMJ.nc
mv Odette_fisica_Y2_AMJ.nc Odette_PISCES_Y2_AMJ.nc

ncks -A Odette_Y2_JAS.nc Odette_fisica_Y2_JAS.nc
mv Odette_fisica_Y2_JAS.nc Odette_PISCES_Y2_JAS.nc

ncks -A Odette_Y2_OND.nc Odette_fisica_Y2_OND.nc
mv Odette_fisica_Y2_OND.nc Odette_PISCES_Y2_OND.nc



 
