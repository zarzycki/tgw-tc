load "/storage/home/cmz5202/sw/cymep/ncl/functions/getTrajectoriesGeneric.ncl"

begin

;thefile="traj.Historical_time_cleaned.txt"
;filename=thefile+"_appended"

ncols := -1 ; number of columns in non-header rows of trajectory file
maxLines := -1  ; set to -1 for auto-detection
traj_data := getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",False,False)

ntimes = traj_data@ntimes
ncol = traj_data@ncol
nstorms = traj_data@nstorms
slp = traj_data(:,4,:)
yyyy=toint(traj_data(:,ncol-4,:))
mm=toint(traj_data(:,ncol-3,:))
dd=toint(traj_data(:,ncol-2,:))
hh=toint(traj_data(:,ncol-1,:))
dslp = slp

quote = inttochar(34)
tab_space="    "
delim=tab_space
header="start"

print("deleting any existing files")
system("rm -fv "+filename)

do ii = 0,nstorms-1
  valid_ix := ind(.not.ismissing(slp(ii,:)))
  numvalid = dimsizes(valid_ix)
  dslp(ii,1:numvalid-1) = slp(ii,1:numvalid-1) - slp(ii,0:numvalid-2)
  dslp(ii,0) = 9999.
  ;print(slp(ii,:)+" "+dslp(ii,:))

  HEADSTR=header+delim+numvalid+delim+yyyy(ii,0)+delim+mm(ii,0)+delim+dd(ii,0)+delim+hh(ii,0)
  print("    ")
  ;print(HEADSTR+"")
  system("echo "+quote+      HEADSTR      +quote+" >> "+filename)

  sprinf_array = (/"%5.4g","%5.4g","%.6f","%.6f","%10.6e","%10.6e"/)
  do zz = 0,numvalid-1
    STORMSTR=""
    do jj = 0,(ncol-4-1)
      if (jj .le. 1) then
        STORMSTR=STORMSTR+delim+toint(traj_data(ii,jj,zz))
      else
        STORMSTR=STORMSTR+delim+sprintf( sprinf_array(jj), traj_data(ii,jj,zz) )
      end if

    end do

    ;; ADD NEW VARS HERE!
    STORMSTR=STORMSTR+delim+sprintf( "%8.4e", dslp(ii,zz) )

    ; Append times
    STORMSTR=STORMSTR+delim+yyyy(ii,zz)+delim+mm(ii,zz)+delim+dd(ii,zz)+delim+hh(ii,zz)
    ;print(""+STORMSTR)
    system("echo "+quote+      STORMSTR      +quote+" >> "+filename)
  end do

end do

system("sed -i 's/[[:blank:]]\+/\t/g' "+filename)

end

