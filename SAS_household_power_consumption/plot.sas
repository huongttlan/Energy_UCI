****************************************************;
libname rawdata "C:\Users\huong.trinh\Desktop\household_power_consumption\datatosas";
data rawpower;
	set rawdata.rawpower;
	/*Try to make the first plot as time series based on all data */
	datetime=dhms(Date, 0, 0, Time);
	format datetime datetime23.; 
	monthcat=month(date);
	daycat=day(date);
	yearcat=year(date);
	hourcat=hour(time);
	other=Global_active_power*1000/60 - Sub_metering_1-Sub_metering_2-Sub_metering_3;
proc sort;
by date hourcat;
run;
proc sql;
create table rawpower1 as
select date, yearcat, monthcat, daycat, hourcat, sum(Global_active_power) *1000/60 as sum_active, sum(global_reactive_power) *100/60 as sum_reactive,
		sum(Sub_metering_1) as sum_sub1, sum(sub_metering_2) as sum_sub2, sum(sub_metering_3) as sum_sub3,
		sum(other) as sum_other, avg(voltage)as avg_vol, avg(global_intensity) as avg_int
from rawpower
group by date, yearcat, monthcat, daycat, hourcat
order by  yearcat, monthcat, hourcat, daycat, date;
quit;
/*****************************************************************/
*Now get the average by hourcat for every day in each month;
proc sql;
create table rawpower2 as
select yearcat, monthcat, hourcat, avg(sum_active) as avg_active1, avg(sum_reactive) as avg_reactive1,  avg(sum_sub1) as avg_sub11,
	avg(sum_sub2) as avg_sub21, avg(sum_sub3) as avg_sub31, avg(sum_other) as avg_other1, avg(avg_vol) as avg_vol1,
	avg(avg_int) as avg_int1
from rawpower1
group by yearcat, monthcat, hourcat
order by monthcat, hourcat, yearcat;
quit;
*Now get the average by year;
proc sql;
create table rawpower3 as
select monthcat, hourcat, avg(avg_active1) as avg_active2, avg(avg_reactive1) as avg_reactive2,  avg(avg_sub11) as avg_sub12,
	avg(avg_sub21) as avg_sub22, avg(avg_sub31) as avg_sub32, avg(avg_other1) as avg_other2, avg(avg_vol1) as avg_vol2,
	avg(avg_int1) as avg_int2
from rawpower2
group by monthcat, hourcat
order by monthcat, hourcat ;
quit;
data rawpower3;
	set rawpower3;
	ordering=_N_;
	label avg_sub12="Monthly average of the averaged usage of the kitchen (containing mainly a dishwasher, an oven and a microwave) per hour block (0-23)"
		avg_sub22="Monthly average of the averaged usage of the laundry room (containing a washing-machine, a tumble-dryer, a refrigator and a light) per hour block (0-23)"
		avg_sub32="Monthly average of the averaged usage of the electric water-heater and the air-conditioner per hour block (0-23)"
		avg_other2="Monthly average of the averaged usage of other appliance at home per hour block (0-23)";
proc sort;
by monthcat hourcat; 
run;
/*Dummy data for hourcat to represent every hour block in each montht*/
data hourcat;
	set rawpower3;
	keep hourcat;
proc sort nodupkey;
by hourcat;
run;
data monthcat;
	set rawpower3;
	keep monthcat;
proc sort nodupkey;
by monthcat;
run;
proc sql;
create table dummy as
select hourcat, monthcat
from monthcat, hourcat
order by monthcat, hourcat;
quit;
data rawpower4;
	merge dummy rawpower3;
	by monthcat hourcat;
run;
/********************************************************************/
/********************************************************************/
/********************************************************************/
/********************************************************************/

ods path show;
ods path(prepend) work.templat(update);
proc template;
	define statgraph block;
		begingraph/designwidth=1200px designheight=800px;
			entrytitle 'Cycle of the 4-Year Based Monthly Average Usage of Active Energy in Each Hour Block in Different Sub-metering Categories';
			layout overlay/ xaxisopts=(type=linear offsetmin=0.01 offsetmax=0.01 
										label="From left to right, each color block represents a month from January to December. In each color block, from left to right is hour category from 0 to 23"
										display=all /*(line label tickvalues)*/ labelattrs = (size = 11) )
							yaxisopts=(type=linear offsetmin=0.01 offsetmax=0.01 
										label ="4-Year Averaged Usage of Active Energy in Each Hour Block in Each Month (Watt-hour)" display = all labelattrs = (size = 11));
				blockplot x=ordering block=monthcat/valuevalign=bottom datatransparency=0.75 display=(fill values);

				scatterplot x=ordering y=avg_sub12/ datalabel=hourcat  markerattrs=(symbol=circle color=red size=3px);
				seriesplot x=ordering y=avg_sub12/name="sub1" lineattrs=(pattern=solid color=red);

				scatterplot x=ordering y=avg_sub22/  markerattrs=(symbol=plus color=blue size=3px);
				seriesplot x=ordering y=avg_sub22/name="sub2" lineattrs=(pattern=shortdash color=blue);

				scatterplot x=ordering y=avg_sub32/ datalabel=hourcat   markerattrs=(symbol=diamond color=green size=3px);
				seriesplot x=ordering y=avg_sub32/name="sub3" lineattrs=(pattern=dot color=green);
				
				scatterplot x=ordering y=avg_other2/ datalabel=hourcat  markerattrs=(symbol=Square color=purple size=3px);
				seriesplot x=ordering y=avg_other2/name="subother" lineattrs=(pattern=MediumDash color=purple);
				discretelegend "sub1" "sub2" "sub3" "subother"/ location=outside halign=left valign=bottom border=off across=1;

			endlayout;
		endgraph;
	end;
run;
proc sgrender data=rawpower4 template=block;
run;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
*Try to make bubble plots;
/*ODS PATH(PREPEND) work.templat(update);*/
proc format;
	picture yaxfmt
	1 = 'January'
	2 = 'February'
	3 = 'March'
	4 = 'April'
	5 = 'May'
	6 = 'June'
	7 = 'July'
	8 = 'August'
	9 = 'September'
	10 = 'October'
	11 = 'November'
	12 = 'December';
	run;
/*For the kitchen */
ods graphics on/border=off width=9in height=6in;
%let title = Bubble Plot for the Averaged Energy Usage of the Kitchen by Month and Hour;
%let data=rawpower4;
%let xvar=hourcat;
%let yvar=monthcat;
/*%let opts= group=sex;*/
%let bubblevar=avg_sub12;
%let function=sqrt;
%let scale=0.0005;

****************************************************;
proc means data=&data noprint;
	output out=__minmax min(&xvar &yvar)=mx my max(&xvar &yvar)=mxx mxy;
run;
data _null_;
	set __minmax;
	range= max(mxx-mx,1e-16);
	inc=10**ceil(log10(range)-1.0);
/*	if range/inc >=7.5 then inc=inc*2;*/
/*	if range/inc <=2.5 then inc=inc/2;*/
/*	if range/inc <=2.5 then inc=inc/2;*/
	inc=1;
	call symputx('__xmin', floor(mx/inc) *inc);
	call symputx('__xmax',ceil(mxx/inc) * inc);
	call symputx('__xinc',inc);

	range=max(mxy-my,1e-16);
	inc=10**ceil(log10(range)-1.0);
/*	if range/inc >=7.5 then inc=inc*2;*/
/*	if range/inc <=2.5 then inc=inc/2;*/
/*	if range/inc <=2.5 then inc=inc/2;*/
	inc=1;
	call symputx('__ymin', floor(my/inc) *inc);
	call symputx('__ymax',ceil(mxy/inc) * inc);
	call symputx('__yinc',inc);
run;
%put &__xmin;
%put &__xmax;
%put &__xinc;
%let xminx=-2;
%let xmaxx=25;

%put &__ymin;
%put &__ymax;
%put &__yinc;
****************************************************;
proc template;
	define statgraph bubbleplot;
		begingraph;
			entrytitle "&title";
			layout overlay/ xaxisopts=(linearopts= (viewmin=-0.5 viewmax=23.5 tickvaluesequence=(start=&__xmin end=&__xmax increment=&__xinc)) label="Hour Block")
				yaxisopts=(linearopts= (viewmin=0.5 viewmax=12.5  tickvalueformat=Yaxfmt. tickvaluesequence=(start=&__ymin end=&__ymax increment=&__yinc ) 
										)	
							Label="Month"
						   );
				scatterplot x=&xvar y=&yvar/datatransparency=1;
				ellipseparm semimajor=__a1 semiminor=__a2 slope=0 
						xorigin=&xvar yorigin=&yvar/display=(fill outline) outlineattrs=(pattern=solid) fillattrs= (color=red transparency=0.6) ;
/*&opts*/
			endlayout;
			entryfootnote "The area of the bubble represents the energy used in the hour block.";
			entryfootnote "The kitchen contains mainly a dishwasher, and oven and a microwave.";

		endgraph;
	end;
run;
data __minmax;
	set &data;
	__a1=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16)) * (5/4);
	__a2=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16));
run;
proc sgrender data=__minmax template=bubbleplot;
run;
ods graphics off;
/***************************************************/
ods graphics on/border=off width=9in height=6in;
*Now for the laundry rom;
%let title = Bubble Plot for the Average Energy Usage of the Laundry Room by Month and Hour;
%let bubblevar=avg_sub22;
proc template;
	define statgraph bubbleplot1;
		begingraph;
			entrytitle "&title";
			layout overlay/ xaxisopts=(linearopts= (viewmin=-0.5 viewmax=23.5 tickvaluesequence=(start=&__xmin end=&__xmax increment=&__xinc)) label="Hour Block")
				yaxisopts=(linearopts= (viewmin=0.5 viewmax=12.5  tickvalueformat=Yaxfmt. tickvaluesequence=(start=&__ymin end=&__ymax increment=&__yinc ) 
										)	
							Label="Month"
						   );
				scatterplot x=&xvar y=&yvar/datatransparency=1;
				ellipseparm semimajor=__a1 semiminor=__a2 slope=0 
						xorigin=&xvar yorigin=&yvar/display=(fill outline) outlineattrs=(pattern=solid) fillattrs= (color=green transparency=0.6) ;
/*&opts*/
			endlayout;
			entryfootnote "The area of the bubble represents the energy used in the hour block.";
			entryfootnote "The laundry room contains a washing machine, a tumble dryer, a refrigator and a light.";
		endgraph;
	end;
run;

data __minmax;
	set &data;
	__a1=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16)) * (5/4);
	__a2=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16));
run;
proc sgrender data=__minmax template=bubbleplot1;
run;
/****************************************************************/
*Air conditioner;
ods graphics off;
/***************************************************/
ods graphics on/border=off width=9in height=6in;
*Now for the laundry rom;
%let title = Bubble Plot for the Average Energy Usage of the Electric Heater and Air Conditioner by Month and Hour;
%let bubblevar=avg_sub32;
proc template;
	define statgraph bubbleplot2;
		begingraph;
			entrytitle "&title";
			layout overlay/ xaxisopts=(linearopts= (viewmin=-0.5 viewmax=23.5 tickvaluesequence=(start=&__xmin end=&__xmax increment=&__xinc)) label="Hour Block")
				yaxisopts=(linearopts= (viewmin=0.5 viewmax=12.5  tickvalueformat=Yaxfmt. tickvaluesequence=(start=&__ymin end=&__ymax increment=&__yinc ) 
										)	
							Label="Month"
						   );
				scatterplot x=&xvar y=&yvar/datatransparency=1;
				ellipseparm semimajor=__a1 semiminor=__a2 slope=0 
						xorigin=&xvar yorigin=&yvar/display=(fill outline) outlineattrs=(pattern=solid) fillattrs= (color=yellow transparency=0.6) ;
/*&opts*/
			endlayout;
			entryfootnote "The area of the bubble represents the energy used in the hour block.";
			entryfootnote "";
		endgraph;
	end;
run;

data __minmax;
	set &data;
	__a1=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16)) * (5/4);
	__a2=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16));
run;
proc sgrender data=__minmax template=bubbleplot2;
run;
/****************************************************************/
*Other;
ods graphics off;
/***************************************************/
ods graphics on/border=off width=9in height=6in;
*Now for the laundry rom;
%let title = Bubble Plot for the Average Energy Usage of Other Appliances at Home by Month and Hour;
%let bubblevar=avg_other2;
proc template;
	define statgraph bubbleplot3;
		begingraph;
			entrytitle "&title";
			layout overlay/ xaxisopts=(linearopts= (viewmin=-0.5 viewmax=23.5 tickvaluesequence=(start=&__xmin end=&__xmax increment=&__xinc)) label="Hour Block")
				yaxisopts=(linearopts= (viewmin=0.5 viewmax=12.5  tickvalueformat=Yaxfmt. tickvaluesequence=(start=&__ymin end=&__ymax increment=&__yinc ) 
										)	
							Label="Month"
						   );
				scatterplot x=&xvar y=&yvar/datatransparency=1;
				ellipseparm semimajor=__a1 semiminor=__a2 slope=0 
						xorigin=&xvar yorigin=&yvar/display=(fill outline) outlineattrs=(pattern=solid) fillattrs= (color=blue transparency=0.6) ;
/*&opts*/
			endlayout;
			entryfootnote "The area of the bubble represents the energy used in the hour block.";
			entryfootnote "";
		endgraph;
	end;
run;

data __minmax;
	set &data;
	__a1=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16)) * (5/4);
	__a2=&scale * (&__xmax - &__xmin) * &function(max(&bubblevar, 1e-16));
run;
proc sgrender data=__minmax template=bubbleplot3;
run;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/*Ok, make another bar plot for total sum */
proc sql;
create table rawpower5 as
select yearcat, monthcat, sum(sum_active)/1000 as sum_active1, sum(sum_reactive)/1000 as sum_reactive1,
		sum(sum_sub1)/1000 as sum_sub11, sum(sum_sub2)/1000 as sum_sub21, sum(sum_sub3)/1000 as sum_sub31,
		sum(sum_other)/1000 as sum_other1, avg( avg_vol)as avg_vol1, avg(avg_int) as avg_int1
from rawpower1
group by yearcat, monthcat
order by yearcat, monthcat;
quit;
proc transpose data=rawpower5 out=rawpower5_tp;
by yearcat monthcat;
var sum_sub11 sum_sub21 sum_sub31 sum_other1 sum_reactive1;
run;
data rawpower5_tp;
	set rawpower5_tp;
	length cat $200;
	select(_name_);
		when ("sum_sub11")
			cat="Total active energy consumed by the kitchen (containing mainly a dishwasher, an oven and a microwave";
		when ("sum_sub21")
			cat="Total active energy consumed by the laundry room (containing a washing-machine, a tumble-dryer, a refrigator and a light";
		when ("sum_sub31")
			cat="Total active energy consumed by the electric water-heater and an air-conditioner";
		when ("sum_other1")
			cat="Total active energy consumed by other appliance";
		otherwise
			cat="Total reactive energy";
	end;
	label cat="Category" col1="Total energy consumed in a month (KiloWatt-hour)";
run;
ods graphics on/width=16in height=8in;
title "Total Energy Consumed by Month, Year and Type";
proc sgpanel data=rawpower5_tp;
panelby yearcat/layout=columnlattice onepanel novarname noborder colheaderpos=bottom;
vbar monthcat/ barwidth=1 response=col1 group=cat groupdisplay=cluster;
colaxis display=(nolabel);
rowaxis grid;
run;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
*Ok, need to explore reactive energy more;
data rawpower6;
	set rawpower5;
	*Need to calculate apparent power and power_factor;
	apparent=sqrt(sum_active1*sum_active1 + sum_reactive1*sum_reactive1);
	power_factor=sum_active1/apparent;
/*	angle=arcos(power_factor)/constant('pi')* 180;*/

	keep yearcat monthcat sum_active1 sum_reactive1 apparent power_factor /*angle*/;
	label sum_active1="Total active energy (KiloWatt-hour)" 
		  sum_reactive1="Total reactive energy (KiloWatt-hour)"
		  power_factor="Power Factor";
run;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
*Make the whole active energy alone;
ods graphics on/border=off width=16in height=6in;
title "Total Active Energy Consumed by Month, Year";
proc sgpanel data=rawpower6;
panelby yearcat/layout=columnlattice onepanel novarname noborder colheaderpos=bottom;
vbar monthcat/barwidth=1 response=sum_active1 /*group=cat groupdisplay=cluster*/ fillattrs=(color=lightgreen);
colaxis display=(nolabel) /*label="Month, Year"*/;
rowaxis grid;
run;
ods graphics off;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
*Make reactive energy alone;
ods graphics on/ border=off width=16in height=3.5in;
title "Total Reactive Energy Consumed by Month, Year";
proc sgpanel data=rawpower6;
panelby yearcat/layout=columnlattice onepanel novarname noborder colheaderpos=bottom;
vbar monthcat/barwidth=1 response=sum_reactive1 /*group=cat groupdisplay=cluster*/ fillattrs=(color=lightpink);
colaxis display=(nolabel) min=0 max=25;
rowaxis grid;
run;
footnote "";
ods graphics off;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
*Now make the power factor;
ods graphics on/border=off width=16in height=3in;
title "Power Factor by Month, Year";
footnote 
"Power factor is the ratio of the active power that is used to do work and the apparent power (active power and reactive power) that is supplied to the circuit";
proc sgpanel data=rawpower6;
panelby yearcat/layout=columnlattice onepanel novarname noborder colheaderpos=bottom;
series x=Monthcat y=power_factor/lineattrs=(color=Blue) ;
colaxis display=(nolabel) values= (1 to 12 by 1) integer;
rowaxis grid values=(0.998 to 1 by 0.0005);
run;
footnote "";
ods graphics off;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/*Ok, make one stack for different type of active_energy */
data rawpower5_tp_active;
	set rawpower5_tp;
	if _NAME_^="sum_reactive1";
	label col1="Total active energy (KiloWatt-hour)";
run;
ods graphics on/ border=off width=16in height=6in;
title "Total Active Energy Consumed by Month, Year and Type";
footnote "The whole column is the total active energy (or the energy used to do actual work) consumed in a month.";
proc sgpanel data=rawpower5_tp_active;
panelby yearcat/layout=columnlattice onepanel novarname noborder colheaderpos=bottom;
vbar monthcat/ barwidth=1 response=col1 group=cat groupdisplay=stack;
colaxis display=(nolabel);
rowaxis grid;
footnote "";
run;
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
/**************************************************************/
