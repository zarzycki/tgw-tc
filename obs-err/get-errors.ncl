load "getTrajectoriesGeneric.ncl"

begin

;xfile="../trajs/traj.ibtracs.txt_final"
;yfile="../trajs/traj.Historical_time_cleaned.txt_final"
;error_var="wind"    ; "track" "psl" "wind"
;outfile="tmp"
;plot_pw=True

print("error_var: "+error_var)
print("xfile: "+xfile)
print("yfile: "+yfile)
print("outfile: "+outfile)
print("plot_pw: "+plot_pw)

xtraj_data := getTrajectoriesGeneric(xfile,-1,-1,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = xtraj_data(:,2,:)
xlat  = xtraj_data(:,3,:)
xpres  = tofloat(xtraj_data(:,4,:))
xwind  = xtraj_data(:,5,:)
xyear  = toint(xtraj_data(:,toint(xtraj_data@ncol)-4,:))
xmonth  = toint(xtraj_data(:,toint(xtraj_data@ncol)-3,:))
xday  = toint(xtraj_data(:,toint(xtraj_data@ncol)-2,:))
xhour  = toint(xtraj_data(:,toint(xtraj_data@ncol)-1,:))
timeunits="days since 1900-01-01 00:00"
xzero=xhour
xzero=0
xtime = cd_inv_calendar(xyear,xmonth,xday,xhour,xzero,xzero,timeunits,0)
xdims=dimsizes(xlon)
xnstorms=xdims(0)
xntimes=xdims(1)



ytraj_data := getTrajectoriesGeneric(yfile,-1,-1,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
ylon  = ytraj_data(:,2,:)
ylat  = ytraj_data(:,3,:)
ypres  = tofloat(ytraj_data(:,4,:))
ywind  = ytraj_data(:,5,:)
yyear  = toint(ytraj_data(:,toint(ytraj_data@ncol)-4,:))
ymonth  = toint(ytraj_data(:,toint(ytraj_data@ncol)-3,:))
yday  = toint(ytraj_data(:,toint(ytraj_data@ncol)-2,:))
yhour  = toint(ytraj_data(:,toint(ytraj_data@ncol)-1,:))
timeunits="days since 1900-01-01 00:00"
yzero=yhour
yzero=0
ytime = cd_inv_calendar(yyear,ymonth,yday,yhour,yzero,yzero,timeunits,0)
ydims=dimsizes(ylon)
ynstorms=ydims(0)
yntimes=ydims(1)

;print(ndtooned(xpres)+" "+ndtooned(ypres))

num_valid = num(.not.ismissing(ylon))
print("num_valid: "+num_valid)
errors=new(num_valid,"float")
zz=0

do ii = 0,xnstorms-1
numentries = num(.not.ismissing(xlon(ii,:)))
do jj = 0,xntimes-1
if .not.ismissing(xlon(ii,jj)) then

  if (error_var .eq. "track") then
    errors(zz) = gc_latlon(xlat(ii,jj),xlon(ii,jj),ylat(ii,jj),ylon(ii,jj),2,4)
  else if (error_var .eq. "psl") then
    errors(zz) = ypres(ii,jj) - xpres(ii,jj)
    if (abs(errors(zz)) .gt. 200.0) then
      errors(zz) = -99999.
    end if
  else if (error_var .eq. "wind") then
    errors(zz) = ywind(ii,jj) - xwind(ii,jj)
    if (abs(errors(zz)) .gt. 200.0) then
      errors(zz) = -99999.
    end if
  else
    print("unknown value for error_var: "+error_var)
    exit
  end if
  end if
  end if
  zz=zz+1

end if
end do
end do

system("rm -v -rf "+outfile)
asciiwrite (outfile,errors)



if (plot_pw) then

colorArray = (/"blue","red"/)
lineColors = (/"blue4","red4"/)
markerTypes = (/2,5/)
threshWind = 17.5 ; threshold wind in m/s
out_type="pdf"

drawRegLines=True

onedpres_x = ndtooned(xpres)
onedwind_x = ndtooned(xwind)
onedpres_y = ndtooned(ypres)
onedwind_y = ndtooned(ywind)

if (threshWind .gt. 0) then
  onedpres_x = where(onedwind_x.lt.threshWind, -999, onedpres_x)
  onedwind_x = where(onedwind_x.lt.threshWind, 1e7, onedwind_x)
  onedpres_y = where(onedwind_y.lt.threshWind, -999, onedpres_y)
  onedwind_y = where(onedwind_y.lt.threshWind, 1e7, onedwind_y)
end if

good_ix = ind(.not.ismissing(onedwind_x) .and. .not.(onedwind_x .gt. 1000) .and. .not.(onedpres_x .lt. 0) )
onedpres_x := onedpres_x(good_ix)
onedwind_x := onedwind_x(good_ix)

good_iy = ind(.not.ismissing(onedwind_y) .and. .not.(onedwind_y .gt. 1000) .and. .not.(onedpres_y .lt. 0) )
onedpres_y := onedpres_y(good_iy)
onedwind_y := onedwind_y(good_iy)

;print(onedpres_x+" "+onedwind_x)
;print("-----")
;print(onedpres_y+" "+onedwind_y)
print("Number x: "+num(.not.ismissing(onedpres_x))+"  Number y: "+num(.not.ismissing(onedpres_y)))

;--------------------------------------------------------

if drawRegLines then
  print("Calculating regression for best-fit line")
  polyn = 3
  regx = fspan(0,100,750)

  quad_x = lspoly(onedwind_x, onedpres_x , 1, polyn)
  quad_y = lspoly(onedwind_y, onedpres_y , 1, polyn)
  x_regy = new(dimsizes(regx),float)
  y_regy = new(dimsizes(regx),float)
  x_regy = quad_x(0) + quad_x(1)*regx + quad_x(2)*regx^2
  y_regy = quad_y(0) + quad_y(1)*regx + quad_y(2)*regx^2
end if

;print(x_regy+" "+regx)
;print("-----")
;print(y_regy+" "+regx)
;--------------------------------------------------------

mainStr  = "Pressure-Wind (10-m)"

wks  = gsn_open_wks(out_type,"_pw_"+str_sub_str(outfile,"./",""))

res  = True
res@gsnMaximize            = True       ; Maximize plot in frame.
res@gsnDraw    = False                         ; don't draw
res@gsnFrame   = False                         ; don't advance frame

res@tiMainString  = mainStr

res@tiYAxisString = "Wind speed (m/s)" 	; y axis title
res@tiXAxisString = "Surface pressure (hPa)" 	; y axis title

res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = 0.018
res@tiMainFontHeightF = 0.02
res@tmXBLabelFontHeightF = 0.015
res@tmYLLabelFontHeightF = 0.015

res@trXMinF           = 875.
res@trXMaxF           = 1025.
res@trYMinF           = 17.5
res@trYMaxF           = 90.

res@xyMarkLineMode = "Markers"

res@xyMarkerColors = colorArray(0)
res@xyMarker      = markerTypes(0)
res@xyMarkerSizeF = 0.005
plot = gsn_csm_xy(wks,onedpres_x,onedwind_x,res)

res@xyMarkerColors = colorArray(1)
res@xyMarker      = markerTypes(1)
res@xyMarkerSizeF = 0.005
plot6 = gsn_csm_xy(wks,onedpres_y,onedwind_y,res)
overlay(plot,plot6)


; Now we will plot the quad fit lines
if drawRegLines then
  res@xyMarker      = 1
  res@xyMarkerSizeF = 0.015

  res@xyMarkerColors = lineColors(0)
  plot4 = gsn_csm_xy(wks,x_regy,regx,res)
  overlay(plot,plot4)

  res@xyMarkerColors = lineColors(1)
  plot6 = gsn_csm_xy(wks,y_regy,regx,res)
  overlay(plot,plot6)
end if

lgres                    = True
lgres@lgMonoMarkerSize = False
lgres@lgLabelFontHeightF = 0.07
lgres@vpWidthF           = 0.2
lgres@vpHeightF          = 0.1
lgres@lgPerimOn =False
;lgres@lgPerimColor       = "black"
;lgres@lgPerimThicknessF  = 1.0
lgres@lgMonoMarkerIndex = False
lgres@lgItemType         = "Markers"

lgres@lgMarkerColors     = colorArray(::-1)
lgres@lgMarkerIndexes = markerTypes(::-1)
lgres@lgMarkerSizes = (/0.012,0.012/)

lbid = gsn_create_legend(wks,2,(/"WRF","OBS"/),lgres)

amres = True
amres@amParallelPosF   = 0.3		    ; move legend to the right
amres@amOrthogonalPosF = -.4             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

draw(plot)
frame(wks)

end if



end

