load "getTrajectoriesGeneric.ncl"

begin

gridfile="./ERA5.topo.nc"
is_grid_2D=False
flip_grid_180=True
correct_pres_wind = True ; do we want to fill in missing P/W with K&Z 07?
DURTHRESH=3

print_to_screen=True
print_names=False

ibstyr=1979
ibenyr=2019

ibdir="/Users/cmz5202/Software/cymep/convert-traj/"
ibfilename="IBTrACS.ALL.v04r00.nc"
ibversion="v4"

TIMETHRESH=0.15
filename="../trajs/traj.ibtracs.txt_final"








tgwfile="../trajs/traj.Historical_time_cleaned.txt_final"

ncols := -1 ; number of columns in non-header rows of trajectory file
maxLines := -1  ; set to -1 for auto-detection
traj_data := getTrajectoriesGeneric(tgwfile,ncols,maxLines,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres  = tofloat(traj_data(:,4,:))/100.
xwind  = traj_data(:,5,:)*1.0
xyear  = toint(traj_data(:,toint(traj_data@ncol)-4,:))
xmonth  = toint(traj_data(:,toint(traj_data@ncol)-3,:))
xday  = toint(traj_data(:,toint(traj_data@ncol)-2,:))
xhour  = toint(traj_data(:,toint(traj_data@ncol)-1,:))
timeunits="days since 1900-01-01 00:00"
xzero=xhour
xzero=0
xtime = cd_inv_calendar(xyear,xmonth,xday,xhour,xzero,xzero,timeunits,0)
; get nstorms + ntimes (max) from dims of one of the returned arrays
xdims=dimsizes(xlon)
xnstorms=xdims(0)
xntimes=xdims(1)









; below this, don't touch

numyears=tofloat(ibenyr-ibstyr+1)

ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

wcStrt     = systemfunc("date")

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")

;ibdir = "/Users/cmz5202/NetCDF/ibtracs/"
;ibfilename="Allstorms.ibtracs_wmo.v03r10.nc"
;ibversion="v3"

ibfile = addfile(ibdir+ibfilename,"r")

;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

iblat = ibfile->lat(stix:enix,:)
iblon = ibfile->lon(stix:enix,:)
ibtype = tostring(ibfile->nature(stix:enix,:,:))
ibwind_ = ibfile->wmo_wind(stix:enix,:)/ms_to_kts
ibpres = ibfile->wmo_pres(stix:enix,:)
ibtime = ibfile->time(stix:enix,:)
ibnamechar = ibfile->name(stix:enix,:)
ibbasin = tostring(ibfile->basin(stix:enix,:,:))

if (flip_grid_180) then
  iblon=where(iblon.lt.0,iblon+360.,iblon)
end if

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

ibstormcount=dimsizes(ibfile->season(stix:enix))
ibsizes = dimsizes(iblat)
ibntimes = ibsizes(1)

; Need to convert char to str for name
ibnamesingle = new(ibstormcount,"string")
do i = 0,ibstormcount-1
  ibnamesingle(i)=oneDtostring(ibnamechar(i,:))
  ibnamesingle(i)=str_sub_str(ibnamesingle(i),",","")
end do

ibname = conform(ibwind_,ibnamesingle,0)

; Needed to correct for weird IBTrACS issues with .0000000005 times, etc.
ibtime = decimalPlaces(ibtime,3,True)

ibwind_ = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibwind_,ibwind_@_FillValue)
ibpres = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibpres,ibpres@_FillValue)
iblat = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblat,iblat@_FillValue)
iblon = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblon,iblon@_FillValue)
ibtime = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibtime,ibtime@_FillValue)
ibname = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibname,ibname@_FillValue)

; Correct for non-standard times
eps=0.00001
ibwind_ = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibwind_@_FillValue,ibwind_)
ibpres = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibpres@_FillValue,ibpres)
iblat  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblat@_FillValue,iblat)
iblon  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblon@_FillValue,iblon)
ibtime = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibtime@_FillValue,ibtime)
;ibname = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibname@_FillValue,ibname)



oned_ibtime=ndtooned(ibtime)
oned_ibpres=ndtooned(ibpres)
oned_ibwind=ndtooned(ibwind_)
oned_iblat=ndtooned(iblat)
oned_iblon=ndtooned(iblon)
oned_ibname=ndtooned(ibname)



; ======= file stuff
quote = inttochar(34)
delim="	"
system("rm -v -rf "+filename)

stormfile="storm_names.txt"
system("rm -v -rf "+stormfile)


; debugging, set this to a small number
;xnstorms=5

do ii = 0,xnstorms-1
numentries = num(.not.ismissing(xlon(ii,:)))

do jj = 0,xntimes-1
if .not.ismissing(xlon(ii,jj)) then



thisTime = cd_inv_calendar(xyear(ii,jj),xmonth(ii,jj),xday(ii,jj),xhour(ii,jj),0.0,0.0,ibtime@units, 0)

time_diff = abs(oned_ibtime-thisTime)

poss_inds := ind(time_diff .lt. TIMETHRESH)

these_time := oned_ibtime(poss_inds)
these_pres := oned_ibpres(poss_inds)
these_wind := oned_ibwind(poss_inds)
these_lat := oned_iblat(poss_inds)
these_lon := oned_iblon(poss_inds)
these_name := oned_ibname(poss_inds)

these_dist := gc_latlon(xlat(ii,jj),xlon(ii,jj),these_lat,these_lon,2,4)

nearest_index = minind(these_dist)


if (jj .eq. 0) then
  if print_names then
    header=these_name(nearest_index)
  else
    header="start"
  end if
  HEADSTR=header+delim+numentries+delim+xyear(ii,jj)+delim+xmonth(ii,jj)+delim+xday(ii,jj)+delim+xhour(ii,jj)
  if print_to_screen then
    print("    ")
    print(HEADSTR+"")
  end if
  system("echo "+quote+      HEADSTR      +quote+" >> "+filename)

  storm_string:=these_name(nearest_index)+delim+xyear(ii,jj)+delim+xmonth(ii,jj)+delim+xday(ii,jj)+delim+xhour(ii,jj)+delim+numentries
  system("echo "+quote+      storm_string      +quote+" >> "+stormfile)

end if

STORMSTR=delim+"-999"+delim+"-999"+delim+sprintf("%6.2f", these_lon(nearest_index))+delim+sprintf("%6.2f", these_lat(nearest_index))+delim+sprintf("%6.0f", these_pres(nearest_index))+delim+sprintf("%8.2f", these_wind(nearest_index))+delim+sprintf("%5.2f", these_dist(nearest_index))+delim+xyear(ii,jj)+delim+xmonth(ii,jj)+delim+xday(ii,jj)+delim+xhour(ii,jj)

if print_to_screen then
  print(STORMSTR+"")
end if

system("echo "+quote+      STORMSTR       +quote+" >> "+filename)



end if
end do
end do





end

