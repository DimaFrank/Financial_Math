/* Computation of a Bond Price using Spot Rates*/

data Bonds;
input Year SpotRate;
datalines;
1 0.022
2 0.025
3 0.030
4 0.032
;
run;

proc print data=Bonds;
run;

%let coupon = 4;
%let par_value = 100;

data calc;
	set Bonds;
	coupon = &coupon.;
	if Year = 4 then result = (coupon+&par_value.) / (1+SpotRate)**Year;
	else result = coupon / (1+SpotRate)**Year;
run;

proc print data=calc;
run;

proc sql;
select SUM(result) as Bond_value
from calc
;quit;



/* Computation of a Bond Yield Curve missing term using Spot Rates*/


%macro fw_rate(t1, t2, Spot_t1, Spot_t2);

data temp noprint;
	 num = (&Spot_t2.* &t2.) - (&Spot_t1. * &t1.);
	 denum = &t2. - &t1.;
	 result = num/denum;
run;

proc sql;
	select result as "f_&t1._&t2."n
	from temp
;quit;

%mend fw_rate;


%macro Spot_rate(t, S_prev, S_next);

	data temp noprint;
		spot_of_Y&t. = &S_prev. + ( ((&S_next. - &S_prev.) / ((&t.+1) - (&t.-1))) * (&t.-(&t.-1)) );
	run;
	proc print data=temp;
	run;
	
	%global S_rate;
	proc sql noprint; select spot_of_Y&t. into: S_rate from temp;
	quit;
	
%mend Spot_rate;


data Treasury_data;
input Maturity $8. M1 M3 M6 Y Y2 Y3 Y5 Y7 Y10 Y20 Y30;
datalines;
30/10/15 0.01 0.08 0.23 0.34 0.75 1.05 1.52 1.88 2.16 2.57 2.93
30/10/05 3.77 3.98 4.26 4.31 4.40 4.41 4.45 4.49 4.57 4.84 .
;
run;
proc print data=Treasury_data;
run;


%fw_rate(2, 3, 0.0075, 0.0105);


%Spot_rate(4, 1.05, 1.52);

data Treasury_data;
	set Treasury_data;
	if Maturity = '30/10/15' then Y4 = &S_rate.;
run;

%Spot_rate(4, 4.41, 4.45);

data Treasury_data;
	set Treasury_data;
	if Maturity = '30/10/05' then Y4 = &S_rate.;
run;

proc sql;
create table Treasury_data
as 
select Maturity, M3, M6, Y, Y2, Y3, Y4, Y5, Y7, Y10, Y20, Y30
from Treasury_data;
quit;



proc transpose data=Treasury_data
out = transposed_data;
run;
proc print data=transposed_data;
run;


proc sgplot data=transposed_data
    noautolegend;
  series x=_NAME_ y=COL1;
  series x=_NAME_ y=COL2;
run;	
	

