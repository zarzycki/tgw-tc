load "~/Software/cymep/ncl/functions/surfaceWindCorrFactor.ncl"
load "~/Software/cymep/ncl/functions/getTrajectoriesGeneric.ncl"
load "~/Software/cymep/ncl/functions/mask_tc.ncl"

begin

output_type="pdf"
basin="conus"
cutatTS=False
factor = 1.0

pres_thresh=950.
basinfilt = -1
maskspacing=1.0
tcMask = mask_tc_allbasin(0,-999,-999,maskspacing,360)

thedir="./"
thefile="traj.Historical_time_cleaned.txt_final"
ncols = -1                    ; assign number of columns
maxLines = -1
headerDelimStr = "start"
delimStr="tab"
isHeader=False
isUnstruc=False
traj_data = getTrajectoriesGeneric(thedir+"/"+thefile,ncols,maxLines,headerDelimStr,delimStr,isUnstruc,isHeader)

trajdims = dimsizes(traj_data)
ncols = trajdims(1)

lon = traj_data(:,2,:)
lat = traj_data(:,3,:)
wind = traj_data(:,5,:)*factor
pres = traj_data(:,4,:)
yyyy=  traj_data(:,ncols-4,:)
mm= traj_data(:,ncols-3,:)
dd= traj_data(:,ncols-2,:)
hh= traj_data(:,ncols-1,:)

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

if (0 .eq. 0) then
  do ii = 0,nstorms-1
    orilat=lat(ii,0)
    orilon=min((/lon(ii,0),359.0/))
      do jj = 0,ntimes-1
        if (.not.ismissing(pres(ii,jj))) then
          if (pres(ii,jj) .lt. pres_thresh) then
            print("Storm : "+ii+" lat: "+lat(ii,jj)+" lon: "+lon(ii,jj)+" pres: "+pres(ii,jj)+" wind: "+wind(ii,jj)+" YYYYMMDDHH: "+yyyy(ii,jj)+" "+mm(ii,jj)+" "+dd(ii,jj)+" "+hh(ii,jj))
          end if
        end if
      end do
      print("------------------------------")
  end do
end if



;--------------------------------------------------------
print("Beginning plot sequence")
;wks_type@wkWidth = 2500
;wks_type@wkHeight = 2500
wks  = gsn_open_wks(output_type,"map."+thefile)
map = new(1,graphic)

res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True

if (basin .eq. "atlantic")
  res@mpMinLatF             = 5
  res@mpMaxLatF             = 45
  res@mpMinLonF             = 260
  res@mpMaxLonF             = 355
end if
if (basin .eq. "wpac")
  res@mpMinLatF             = 5
  res@mpMaxLatF             = 45
  res@mpMinLonF             = 115
  res@mpMaxLonF             = 180
end if
if (basin .eq. "refine")
  res@mpMinLatF             = 3
  res@mpMaxLatF             = 60
  res@mpMinLonF             = 90
  res@mpMaxLonF             = 359
end if
if (basin .eq. "conus")
  res@mpMinLatF             = 20
  res@mpMaxLatF             = 51
  res@mpMinLonF             = 235
  res@mpMaxLonF             = 297
end if
if (basin .eq. "tropics")
  res@mpMinLatF             = -65
  res@mpMaxLatF             = 65
  res@mpCenterLonF = 200.
end if

res@mpGridAndLimbOn      = True
res@gsnMajorLatSpacing = 10
res@gsnMajorLonSpacing = 10
res@gsnMinorLatSpacing = 2
res@gsnMinorLonSpacing = 2
res@mpGridSpacingF       = 10
res@mpGridLineDashPattern = 2
res@tmXTOn = False
res@tmYROn = False

map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True

dum = new((/nstorms,ntimes/),graphic)
dum1 = new((/nstorms,ntimes/),graphic)

text = new((/nstorms/),graphic)


SSthresh_wind = (/1005.,990.,975.,960.,945./)

color_pw=True

;lineres@gsLineThicknessF = 8.0
; We need to use thinner lines for the global map
if (basin .eq. "global") then
  linethicknesses = (/0.2,0.3,1.3,1.9,2.3,2.7/)
else if (basin .eq. "tropics") then
  linethicknesses = (/0.1,0.25,0.6,1.0,1.3,1.6/)
else if (basin .eq. "refine") then
  linethicknesses = (/0.1,0.25,0.9,1.3,1.6,2.2/)
else
  linethicknesses = (/0.5,0.8,1.3,1.9,2.3,2.6/)
end if
end if
end if
linethicknesses = 6.0*linethicknesses


;nstorms=10
do i = 0,nstorms-1
print("storm: "+i+" of "+(nstorms-1))
do j = 0,ntimes-1

if (color_pw) then
  thisWind=pres(i,j)
else
  thisWind=wind(i,j)
end if

thisLat=lat(i,j)
thisLon=lon(i,j)

if (.not.ismissing(thisWind))


  polyres@gsMarkerSizeF = 0.008
  if (thisWind .gt. SSthresh_wind(0))
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (thisWind .le. SSthresh_wind(0) .and. thisWind .gt. SSthresh_wind(1))
    polyres@gsMarkerSizeF = polyres@gsMarkerSizeF*1.2
    polyres@gsMarkerColor = (/"green"/)
    lineres@gsLineColor = (/"green"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (thisWind .le. SSthresh_wind(1) .and. thisWind .gt. SSthresh_wind(2))
    polyres@gsMarkerSizeF = polyres@gsMarkerSizeF*1.7
    polyres@gsMarkerColor = (/"yellow"/)
    lineres@gsLineColor = (/"yellow"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (thisWind .le. SSthresh_wind(2) .and. thisWind .gt. SSthresh_wind(3))
    polyres@gsMarkerSizeF = polyres@gsMarkerSizeF*2.0
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (thisWind .le. SSthresh_wind(3) .and. thisWind .gt. SSthresh_wind(4))
    polyres@gsMarkerSizeF = polyres@gsMarkerSizeF*2.3
    polyres@gsMarkerColor = (/"darkorange3"/)
    lineres@gsLineColor = (/"darkorange3"/)
    lineres@gsLineThicknessF  = linethicknesses(4)
  else
    polyres@gsMarkerSizeF = polyres@gsMarkerSizeF*2.7
    polyres@gsMarkerColor = (/"red"/)
    lineres@gsLineColor = (/"red"/)
    lineres@gsLineThicknessF  = linethicknesses(5)
  end if
  end if
  end if
  end if
  end if

;if (lat(i,j) .gt. 30. .and. lon(i,j) .gt. 180. .and. lon(i,j) .lt. 270.) then
;  print(lon(i,j)+" "+lat(i,j))
;  print(thisWind+""+lineres@gsLineColor)
;end if

  polyresback=polyres
  polyresback@gsMarkerSizeF= polyres@gsMarkerSizeF + (polyres@gsMarkerSizeF*0.3)
  polyresback@gsMarkerColor="black"

      dum1(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyresback)
       dum(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyres)

;  if (j .eq. 0) then
;    str=tostring(toint(mm(i,j)))+tostring(toint(dd(i,j)))
;    txres = True
;    txres@txFontColor = "black"
;    txres@txFontHeightF = 0.015             ; Set the font height
;    txres@amJust = "TopLeft"
;    text(i) = gsn_add_text(wks,map,str,lon(i,j)+0.5,lat(i,j)-0.5,txres)
;  end if

end if

end do
end do


; if we are doing a varres grid, let's push an outline of the atl30x4 grid
;if (modelgrid .eq. "vr") then
;  map = plot_outline_fcn(wks,map,"black",3.0)
;end if

;******************
; Plot a legend   *
;******************

lgres                    = True

lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.08       ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.12       ; was 0.08        ; height of legend (NDC)
; lgres@lgBottomMarginF    = 0.17     ; was 0.25

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

;lgres@lgOrientation = "Horizontal"

; lgres@lgBoxMajorExtentF  = 0.4
lgres@lgBoxMinorExtentF  = 0.2	; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

; lgres@lgBoxBackground    = "PaleTurquoise3"

lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
lgres@lgMonoMarkerIndex     = False
lgres@lgMonoLineThickness   = False
lgres@lgMonoMarkerThickness = False
lgres@lgMonoMarkerSize      = False

;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.07
lgres@lgLabelFontAspectF      = 1.5
lgres@lgLabelConstantSpacingF = 0.0

legendType = "Markers"
markerSize = .008
markerIndex = 16

if (cutatTS) then
  lgres@lgItemCount        = 5
  lgres@lgItemTypes        = (/legendType,legendType,legendType,legendType,legendType/)
  lgres@lgMarkerIndexes    = (/markerIndex,markerIndex,markerIndex,markerIndex,markerIndex/)
  lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
  lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow2",   "green4" /) ; colors for legend lines
  legend_labels = (/"Category 4/5","Category 3","Category 2",\
                 "Category 1","Tropical Storm"/)
else
  lgres@lgItemCount        = 6
  ;lgres@lgLineDashSegLenF  = 0.8
  lgres@lgItemTypes        = (/"Markers","Markers","Markers","Markers","Markers","Markers"/)
  lgres@lgMarkerIndexes    = (/      16,      16,      16,      16,      16,      16/)
  lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
  lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow",   "green",    "blue"    /) ; colors for legend lines
  ;lgres@lgDashIndexes      = (/      0,          0,          0,         0,               0,      0      /) ; dash indexes
  legend_labels = (/"Cat. 4/5","Cat. 3","Cat. 2",\
                 "Cat. 1","TS","TD"/)
end if


legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
if (basin .eq. "atlantic") then
amres@amParallelPosF   = 0.43		    ; move legend to the right
amres@amOrthogonalPosF = -.3             ; move the legend down
else if (basin .eq. "tropics") then
amres@amParallelPosF   = -0.455		    ; move legend to the right .37 formerly
amres@amOrthogonalPosF = -0.305            ; move the legend down
else if (basin .eq. "refine") then
amres@amParallelPosF   = -0.46
amres@amOrthogonalPosF = -0.18
else if (basin .eq. "conus") then
amres@amParallelPosF   = -0.45
amres@amOrthogonalPosF = -0.34
else
amres@amParallelPosF   = -0.30		    ; move legend to the right .37 formerly
amres@amOrthogonalPosF = .27             ; move the legend down
end if
end if
end if
end if

annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot

print("Drawing plot")

resP = True
resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end
