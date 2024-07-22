begin

;fn = "./tgw_wrf_historical_three_hourly_1981-09-17_00_00_00.nc"
;OUTDIR="./"

f = addfile(fn,"r")

BASENAME=systemfunc("basename "+fn)
print("NCL: BASENAME "+BASENAME)

P0=1000.
kappa=0.2854
grav=9.80665

P = f->P
PB = f->PB
PRES = P
PRES = (P + PB)*0.01
PRES@units="hPa"
delete([/P,PB/])

PH = f->PH
PHB = f->PHB
PH := wrf_user_unstagger(PH,PH@stagger)
PHB := wrf_user_unstagger(PHB,PHB@stagger)
ZG = PH
ZG = (PH + PHB)/grav
ZG@units="m"
delete([/PH,PHB/])

T = f->T
THETA = T+300.

TEMP = T
TEMP = THETA / (P0/PRES)^kappa
TEMP@units="K"
TEMP@long_name="Air temperature"
TEMP@description="Derived from T"
delete([/THETA,T/])

Q = f->QVAPOR
U = f->U
V = f->V
W = f->W
U := wrf_user_unstagger(U,U@stagger)
V := wrf_user_unstagger(V,V@stagger)
W := wrf_user_unstagger(W,W@stagger)

;standard_levels = (/1000, 925, 850, 700, 500, 400, 300, 250, 200, 150, 100, 70/)

T1000 = wrf_user_interp_level(TEMP,PRES,1000,False)
T925  = wrf_user_interp_level(TEMP,PRES,925,False)
T850  = wrf_user_interp_level(TEMP,PRES,850,False)
T700  = wrf_user_interp_level(TEMP,PRES,700,False)
T500  = wrf_user_interp_level(TEMP,PRES,500,False)
T400  = wrf_user_interp_level(TEMP,PRES,400,False)
T300  = wrf_user_interp_level(TEMP,PRES,300,False)
T250  = wrf_user_interp_level(TEMP,PRES,250,False)
T200  = wrf_user_interp_level(TEMP,PRES,200,False)
T150  = wrf_user_interp_level(TEMP,PRES,150,False)
T100  = wrf_user_interp_level(TEMP,PRES,100,False)
T70   = wrf_user_interp_level(TEMP,PRES,70,False)

Q1000 = wrf_user_interp_level(Q,PRES,1000,False)
Q925  = wrf_user_interp_level(Q,PRES,925,False)
Q850  = wrf_user_interp_level(Q,PRES,850,False)
Q700  = wrf_user_interp_level(Q,PRES,700,False)
Q500  = wrf_user_interp_level(Q,PRES,500,False)
Q400  = wrf_user_interp_level(Q,PRES,400,False)
Q300  = wrf_user_interp_level(Q,PRES,300,False)
Q250  = wrf_user_interp_level(Q,PRES,250,False)
Q200  = wrf_user_interp_level(Q,PRES,200,False)
Q150  = wrf_user_interp_level(Q,PRES,150,False)
Q100  = wrf_user_interp_level(Q,PRES,100,False)
Q70   = wrf_user_interp_level(Q,PRES,70,False)

U1000 = wrf_user_interp_level(U,PRES,1000,False)
U925  = wrf_user_interp_level(U,PRES,925,False)
U850  = wrf_user_interp_level(U,PRES,850,False)
U700  = wrf_user_interp_level(U,PRES,700,False)
U500  = wrf_user_interp_level(U,PRES,500,False)
U400  = wrf_user_interp_level(U,PRES,400,False)
U300  = wrf_user_interp_level(U,PRES,300,False)
U250  = wrf_user_interp_level(U,PRES,250,False)
U200  = wrf_user_interp_level(U,PRES,200,False)
U150  = wrf_user_interp_level(U,PRES,150,False)
U100  = wrf_user_interp_level(U,PRES,100,False)
U70   = wrf_user_interp_level(U,PRES,70,False)

V1000 = wrf_user_interp_level(V,PRES,1000,False)
V925  = wrf_user_interp_level(V,PRES,925,False)
V850  = wrf_user_interp_level(V,PRES,850,False)
V700  = wrf_user_interp_level(V,PRES,700,False)
V500  = wrf_user_interp_level(V,PRES,500,False)
V400  = wrf_user_interp_level(V,PRES,400,False)
V300  = wrf_user_interp_level(V,PRES,300,False)
V250  = wrf_user_interp_level(V,PRES,250,False)
V200  = wrf_user_interp_level(V,PRES,200,False)
V150  = wrf_user_interp_level(V,PRES,150,False)
V100  = wrf_user_interp_level(V,PRES,100,False)
V70   = wrf_user_interp_level(V,PRES,70,False)

W1000 = wrf_user_interp_level(W,PRES,1000,False)
W925  = wrf_user_interp_level(W,PRES,925,False)
W850  = wrf_user_interp_level(W,PRES,850,False)
W700  = wrf_user_interp_level(W,PRES,700,False)
W500  = wrf_user_interp_level(W,PRES,500,False)
W400  = wrf_user_interp_level(W,PRES,400,False)
W300  = wrf_user_interp_level(W,PRES,300,False)
W250  = wrf_user_interp_level(W,PRES,250,False)
W200  = wrf_user_interp_level(W,PRES,200,False)
W150  = wrf_user_interp_level(W,PRES,150,False)
W100  = wrf_user_interp_level(W,PRES,100,False)
W70   = wrf_user_interp_level(W,PRES,70,False)

ZG1000 = wrf_user_interp_level(ZG,PRES,1000,False)
ZG925  = wrf_user_interp_level(ZG,PRES,925,False)
ZG850  = wrf_user_interp_level(ZG,PRES,850,False)
ZG700  = wrf_user_interp_level(ZG,PRES,700,False)
ZG500  = wrf_user_interp_level(ZG,PRES,500,False)
ZG400  = wrf_user_interp_level(ZG,PRES,400,False)
ZG300  = wrf_user_interp_level(ZG,PRES,300,False)
ZG250  = wrf_user_interp_level(ZG,PRES,250,False)
ZG200  = wrf_user_interp_level(ZG,PRES,200,False)
ZG150  = wrf_user_interp_level(ZG,PRES,150,False)
ZG100  = wrf_user_interp_level(ZG,PRES,100,False)
ZG70   = wrf_user_interp_level(ZG,PRES,70,False)

;varflg = -1
;intyp = 2
;kxtrp = True
;HGT = f->HGT
;T2 = f->T2
;PSFC = f->PSFC
;Zp = vintp2p_ecmwf(ZG, PRES, (/1000./) ,PSFC, intyp, 1,kxtrp,varflg,T2,(HGT*grav))
;Z1000 = ZG1000
;Z1000 = (/Zp/)
;Zp = vintp2p_ecmwf(ZG, PRES, (/850./) ,PSFC, intyp, 1,kxtrp,varflg,T2,(HGT*grav))
;Z850 = ZG850
;Z850 = (/Zp/)
;Zp = vintp2p_ecmwf(ZG, PRES, (/500./) ,PSFC, intyp, 1,kxtrp,varflg,T2,(HGT*grav))
;Z500 = ZG500
;Z500 = (/Zp/)
;
;
;DIFF1000 = Z1000
;DIFF1000 = (Z1000 - ZG1000)
;print("1000: "+avg(DIFF1000))
;
;DIFF850 = Z850
;DIFF850 = (Z850 - ZG850)
;print("850: "+avg(DIFF850))
;
;DIFF500 = Z500
;DIFF500 = (Z500 - ZG500)
;print("500: "+avg(DIFF500))

SH2O_005=f->SH2O(:,0,:,:)
SH2O_005@long_name="Soil liquid water at 5cm"
SH2O_150=f->SH2O(:,3,:,:)
SH2O_150@long_name="Soil liquid water at 150cm"

;printVarSummary(T500)
;W500 = wrf_user_interp_level(W,PRESH,500,False)
;Q500 = wrf_user_interp_level(Q,PRES,500,False)
;U500 = wrf_user_interp_level(U,PRES,500,False)
;V500 = wrf_user_interp_level(V,PRES,500,False)
;TINT = wrf_user_interp_level(TEMP,PRES,standard_levels,False)
;QINT = wrf_user_interp_level(Q,PRES,standard_levels,False)
;UINT = wrf_user_interp_level(U,PRES,standard_levels,False)
;VINT = wrf_user_interp_level(V,PRES,standard_levels,False)
;WINT = wrf_user_interp_level(W,PRES,standard_levels,False)
;delete([/PRES,PRESH/])

FILEOUT=OUTDIR+"/_z_"+BASENAME
print("Writing: "+FILEOUT)
system("/bin/rm -f "+FILEOUT)   ; remove any pre-existing file
ncdf = addfile(FILEOUT ,"c")  ; open output netCDF file

;ncdf->TEMP = TEMP
;ncdf->T = T
;ncdf->T2 = f->T2
;ncdf->TH2 = f->TH2
;ncdf->THETA = THETA
;ncdf->T500 = T500
;ncdf->U500 = U500
;ncdf->V500 = V500
;ncdf->Q500 = Q500
;ncdf->W500 = W500
;ncdf->T = TINT
;ncdf->Q = QINT
;ncdf->U = UINT
;ncdf->V = VINT
;ncdf->W = WINT

ncdf->T1000 = T1000
ncdf->T925  = T925
ncdf->T850  = T850
ncdf->T700  = T700
ncdf->T500  = T500
ncdf->T400  = T400
ncdf->T300  = T300
ncdf->T250  = T250
ncdf->T200  = T200
ncdf->T150  = T150
ncdf->T100  = T100
ncdf->T70   = T70

ncdf->Q1000 = Q1000
ncdf->Q925  = Q925
ncdf->Q850  = Q850
ncdf->Q700  = Q700
ncdf->Q500  = Q500
ncdf->Q400  = Q400
ncdf->Q300  = Q300
ncdf->Q250  = Q250
ncdf->Q200  = Q200
ncdf->Q150  = Q150
ncdf->Q100  = Q100
ncdf->Q70   = Q70

ncdf->U1000 = U1000
ncdf->U925  = U925
ncdf->U850  = U850
ncdf->U700  = U700
ncdf->U500  = U500
ncdf->U400  = U400
ncdf->U300  = U300
ncdf->U250  = U250
ncdf->U200  = U200
ncdf->U150  = U150
ncdf->U100  = U100
ncdf->U70   = U70

ncdf->V1000 = V1000
ncdf->V925  = V925
ncdf->V850  = V850
ncdf->V700  = V700
ncdf->V500  = V500
ncdf->V400  = V400
ncdf->V300  = V300
ncdf->V250  = V250
ncdf->V200  = V200
ncdf->V150  = V150
ncdf->V100  = V100
ncdf->V70   = V70

ncdf->W1000 = W1000
ncdf->W925  = W925
ncdf->W850  = W850
ncdf->W700  = W700
ncdf->W500  = W500
ncdf->W400  = W400
ncdf->W300  = W300
ncdf->W250  = W250
ncdf->W200  = W200
ncdf->W150  = W150
ncdf->W100  = W100
ncdf->W70   = W70

ncdf->Z1000 = ZG1000
ncdf->Z925  = ZG925
ncdf->Z850  = ZG850
ncdf->Z700  = ZG700
ncdf->Z500  = ZG500
ncdf->Z400  = ZG400
ncdf->Z300  = ZG300
ncdf->Z250  = ZG250
ncdf->Z200  = ZG200
ncdf->Z150  = ZG150
ncdf->Z100  = ZG100
ncdf->Z70   = ZG70

;ncdf->Z1000   = Z1000
;ncdf->Z850   = Z850
;ncdf->Z500   = Z500
;ncdf->DIFF1000 = DIFF1000
;ncdf->DIFF850 = DIFF850

ncdf->SH2O_005   = SH2O_005
ncdf->SH2O_150   = SH2O_150

print("... done writing: "+FILEOUT)

status_exit(0)

end
