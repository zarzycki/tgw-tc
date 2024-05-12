load "/Users/cmz5202/Software/cymep/ncl/functions/getTrajectoriesGeneric.ncl"

begin

;xfile="../trajs/traj.ibtracs.txt_final"
;yfile="../trajs/traj.Historical_time_cleaned.txt_final"
;error_var="wind"    ; "track" "psl" "wind"
;outfile="tmp"

print("error_var: "+error_var)
print("xfile: "+xfile)
print("yfile: "+yfile)
print("outfile: "+outfile)

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

end

