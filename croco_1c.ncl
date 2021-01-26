;*******************************************
; croco_1c.ncl
;
; Concepts illustrated:
;   - Plotting CROCO surface data
;   - Overlaying contours on a map using two-dimensional lat,lon arrays
;   - Drawing a map using the high resolution map outlines
; 
; Efraín Rodriguez-Rubio 
; Centro de Innovacion y Tecnologia-ICP/Ecopetrol
; Date: 26/01/2021
;*******************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  

begin
;*******************************************
; the data and the grid info are in two different files
;*******************************************
 grid = addfile ("../CROCO_FILES/croco_grd.nc", "r")
 lat2d  = grid->lat_rho
 lon2d  = grid->lon_rho
 m      = grid->mask_rho

 f    = addfile ("../CROCO_FILES/croco_avg.nc", "r")
; x    = f->zeta
 no3    = f->NO3
 dia    = f->DIA
 meso   = f->MESO
 zoo    = f->ZOO ; microzooplancton
 nano   = f->NANO
 po4    = f->PO4
 o2     = f->O2
 nchl   = f->NCHL
 dchl   = f->DCHL

 m    = f->mask_rho

; ******************************************************
 ; Seccion donde cambio la mascara de tierra de 0 a -9999
 ;*******************************************************

 do k=1,10
   do l=1,32

    no3(k-1,l-1,:,:) = where(no3(k-1,l-1,:,:).eq.0,-9999,no3(k-1,l-1,:,:))
    dia(k-1,l-1,:,:) = where(dia(k-1,l-1,:,:).eq.0,-9999,dia(k-1,l-1,:,:))
    meso(k-1,l-1,:,:) = where(meso(k-1,l-1,:,:).eq.0,-9999,meso(k-1,l-1,:,:))
    zoo(k-1,l-1,:,:) = where(zoo(k-1,l-1,:,:).eq.0,-9999,zoo(k-1,l-1,:,:))
    nano(k-1,l-1,:,:) = where(nano(k-1,l-1,:,:).eq.0,-9999,nano(k-1,l-1,:,:))
    po4(k-1,l-1,:,:) = where(po4(k-1,l-1,:,:).eq.0,-9999,po4(k-1,l-1,:,:))
    o2(k-1,l-1,:,:) = where(o2(k-1,l-1,:,:).eq.0,-9999,o2(k-1,l-1,:,:))
    nchl(k-1,l-1,:,:) = where(nchl(k-1,l-1,:,:).eq.0,-9999,nchl(k-1,l-1,:,:))
    dchl(k-1,l-1,:,:) = where(dchl(k-1,l-1,:,:).eq.0,-9999,dchl(k-1,l-1,:,:))

   end do
 end do

 no3@_FillValue=-9999
 dia@_FillValue=-9999
 meso@_FillValue=-9999
 zoo@_FillValue=-9999
 nano@_FillValue=-9999
 po4@_FillValue=-9999
 o2@_FillValue=-9999
 nchl@_FillValue=-9999
 dchl@_FillValue=-9999
 chl_tot=nchl+dchl

;***********************************************************

; since roms data has 2D lat/lon coordinates, we need to set these two 
;variables
 no3@lat2d=lat2d
 no3@lon2d=lon2d
 meso@lat2d=lat2d
 meso@lon2d=lon2d
 zoo@lat2d=lat2d
 zoo@lon2d=lon2d
 nano@lat2d=lat2d
 nano@lon2d=lon2d
 po4@lat2d=lat2d
 po4@lon2d=lon2d
 o2@lat2d=lat2d
 o2@lon2d=lon2d
 nchl@lat2d=lat2d
 nchl@lon2d=lon2d
 dchl@lat2d=lat2d
 dchl@lon2d=lon2d
 chl_tot@lat2d=lat2d
 chl_tot@lon2d=lon2d

;********************************************
; create plot
;********************************************
 wks  = gsn_open_wks ("png", "croco_Chlorophyll")             ; send graphics to PNG file
; cmap = read_colormap_file("testcmap")           ; read color data
 cmap = read_colormap_file("gui_default")
 ncolors = dimsizes(cmap(:,0))                   ; get number of colors
 plot =new(6,graphic)

                                          
 res                        = True               ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame

 res@cnFillOn               = True               ; color fill  
 res@cnFillPalette          = cmap(0:ncolors-2,:); set color map
 res@cnLinesOn              = True              ; no contour lines
 res@cnLineLabelsOn         = True              ; no contour labels
 res@cnFillDrawOrder        = "PreDraw"          ; put continents on top
 res@cnInfoLabelOn          = False              ; no contour info label
 res@cnLevelSelectionMode =  "ManualLevels"   
 res@cnMinLevelValF       = 0.
 res@cnMaxLevelValF       = 3.
 res@cnLevelSpacingF      = 0.2 

; data zoomed on a lambert conformal grid.  
 
 res@mpLimitMode         = "Corners"             ; choose range of map
 res@mpLeftCornerLatF    = -38
 res@mpLeftCornerLonF    = 8
 res@mpRightCornerLatF   = -26
 res@mpRightCornerLonF   = 21

 res@mpDataBaseVersion      = "HighRes"        ; use high resolution coast
 res@pmTickMarkDisplayMode  = "Always"           ; turn on tickmarks

 res1                        = True               ; plot mods desired
 res1@gsnDraw  = False                          ; don't draw
 res1@gsnFrame = False                          ; don't advance frame

 res1@cnFillOn               = True               ; color fill
 res1@cnFillPalette          = cmap(0:ncolors-2,:); set color map
 res1@cnLinesOn              = True              ; no contour lines
 res1@cnLineLabelsOn         = True              ; no contour labels
 res1@cnFillDrawOrder        = "PreDraw"          ; put continents on top
 res1@cnInfoLabelOn          = False              ; no contour info label
 res1@cnLevelSelectionMode =  "ManualLevels"
 res1@cnMinLevelValF       = 0.
 res1@cnMaxLevelValF       = 3.
 res1@cnLevelSpacingF      = 0.2

; data zoomed on a lambert conformal grid.

 res1@mpLimitMode         = "Corners"             ; choose range of map
 res1@mpLeftCornerLatF    = -38
 res1@mpLeftCornerLonF    = 8
 res1@mpRightCornerLatF   = -26
 res1@mpRightCornerLonF   = 21

 res1@mpDataBaseVersion      = "HighRes"        ; use high resolution coast
 res1@pmTickMarkDisplayMode  = "Always"           ; turn on tickmarks


 res2                        = True               ; plot mods desired
 res2@gsnDraw  = False                          ; don't draw
 res2@gsnFrame = False                          ; don't advance frame

 res2@cnFillOn               = True               ; color fill
 res2@cnFillPalette          = cmap(0:ncolors-2,:); set color map
 res2@cnLinesOn              = True              ; no contour lines
 res2@cnLineLabelsOn         = True              ; no contour labels
 res2@cnFillDrawOrder        = "PreDraw"          ; put continents on top
 res2@cnInfoLabelOn          = False              ; no contour info label
 res2@cnLevelSelectionMode =  "ManualLevels"
 res2@cnMinLevelValF       = 0.
 res2@cnMaxLevelValF       = 3.
 res2@cnLevelSpacingF      = 0.2

; data zoomed on a lambert conformal grid.

 res2@mpLimitMode         = "Corners"             ; choose range of map
 res2@mpLeftCornerLatF    = -38
 res2@mpLeftCornerLonF    = 8
 res2@mpRightCornerLatF   = -26
 res2@mpRightCornerLonF   = 21

 res2@mpDataBaseVersion      = "HighRes"        ; use high resolution coast
 res2@pmTickMarkDisplayMode  = "Always"           ; turn on tickmarks
 res2@gsnLeftString  = "Total chlorophyll"



;**********************************************************************
; plot = gsn_csm_contour_map(wks,x(0,:,:),res)
 plot(0) = gsn_csm_contour_map(wks,nchl(1,31,:,:),res)
 plot(1) = gsn_csm_contour_map(wks,nchl(9,31,:,:),res)     

 plot(2) = gsn_csm_contour_map(wks,dchl(1,31,:,:),res1)
 plot(3) = gsn_csm_contour_map(wks,dchl(9,31,:,:),res1)

 plot(4) = gsn_csm_contour_map(wks,chl_tot(1,31,:,:),res2)
 plot(5) = gsn_csm_contour_map(wks,chl_tot(9,31,:,:),res2)


;************************************************
; create panel
;************************************************
  gsn_panel(wks,plot,(/3,2/),False)             ; now draw as one plot


end
