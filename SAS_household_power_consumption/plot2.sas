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
*Ok, now working with voltage;
data voltage;
	set rawpower;
	*Ok, try to classify as season;
	length season $200;
	if monthcat in (3,4,5) then do;
		season="SPRING";
		seasonn=1;
	end;
	else if monthcat in (6,7,8) then do;
			season="SUMMER";
			seasonn=2;
		end;
		else if monthcat in (9,10,11) then do;
				season="AUTUMN";
				seasonn=3;
			end;
			else if monthcat in (12,1,2) then do;
					season="WINTER";
					seasonn=4;
				end;

	keep date time  season seasonn datetime monthcat daycat yearcat hourcat voltage;
proc sort;
by yearcat seasonn datetime;
run;
/*************************************************/
/*************************************************/
/*************************************************/
/*************************************************/
/*************************************************/
/*************************************************/
proc univariate data=voltage;
var voltage;
class yearcat seasonn;
ods output  quantiles=q ;
run;
proc means data=voltage noprint;
by yearcat seasonn;
var voltage;
output out=overall_tp  Mean=estimate;
run;
ods listing;
data overall_tp;
	set overall_tp;
	length quantile $10;
	quantile="Mean";
	drop _type_ _freq_;
run;
data q1;
	set q;
	quantile=scan(quantile,2, ' ');
	if quantile ne ' ';
	yearcat_n=input(trim(left(yearcat)),??best.);
	seasonn_n=input(trim(left(seasonn)),??best.);

	drop varname yearcat seasonn;
	rename yearcat_n=yearcat seasonn_n=seasonn;
run;
data q1;
	set q1 overall_tp;
proc sort; by yearcat seasonn quantile;
run;
/*************************************************/
/*************************************************/
/*************************************************/
/*************************************************/
/*************************************************/
data q2;
	set q1;
	/* quantile order; */
	select(quantile);
	when ("Min") ordering=1;
	when ("Q1") ordering=2;
	when ("Mean") ordering=3;
	when ("Median") ordering=4;
	when ("Q3") ordering=5;
	when ("Max") ordering=6;
	otherwise;
	end;
proc sort; by yearcat ordering quantile;
run;
proc transpose data=q2 out=q2_tp;
by yearcat ordering quantile;
id seasonn;
var ESTIMATE;
run;
data q2_tp;
	set q2_tp;
	if yearcat=2006 then do; 
      	_1_xaxis=1.5; 
		_2_xaxis=2.5; 
		_3_xaxis=3.5;
		_4_xaxis=4.5;
		x1=5.5; y1=0;
	end;
	else if yearcat=2007 then do;
			_1_xaxis=6.5; 
			_2_xaxis=7.5; 
			_3_xaxis=8.5;
			_4_xaxis=9.5;
			x2=11.5; y2=0;
		end; 
		else if  yearcat=2008 then do;
			_1_xaxis=13.5; 
			_2_xaxis=14.5; 
			_3_xaxis=15.5;
			_4_xaxis=16.5;
			x3=18.5; y3=0;
			end; 
			else if yearcat=2009 then do;
					_1_xaxis=19.5; 
					_2_xaxis=20.5; 
					_3_xaxis=21.5;
					_4_xaxis=22.5;
					x3=24.5; y3=0;

				end; 
				else if yearcat=2010 then do;
					_1_xaxis=25.5; 
					_2_xaxis=26.5; 
					_3_xaxis=27.5;
					_4_xaxis=28.5;
					end; 

run;
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
ods graphics on/border=off width=15in height=9in;
ods path show;
ods path(prepend) work.templat(update);
proc template;
	define statgraph boxplot;
	begingraph;
		entrytitle "Box-and-Whisker Plot for the seasonal minute-averaged voltage";
		layout lattice /columns=1 rows=3 rowweights=(0.75 0.05 0.2); 
		layout overlay / 
			xaxisopts=(type=discrete offsetmin=0.05 offsetmax=0.05  display = (line)
					linearopts = (viewmin =0 viewmax = 30 tickvaluelist=(0  30) tickdisplaylist=('' '')) labelattrs = (size = 12))
			yaxisopts=(type=linear offsetmin=0.05 offsetmax=0.05 label ="Voltage (Volt)" display = all
                       linearopts = (viewmin=220 viewmax=260  tickvaluesequence = (start=210 end=260 increment=5) /*tickvalueformat=Yaxfmt.*/)
                       labelattrs = (size = 12));
			boxplotparm y=_1 x= _1_xaxis stat=quantile /  name="Spring" groupdisplay=overlay /*discreteoffset=0.15*/
					boxwidth=.3legendlabel="Spring (March, April, May)"
					fillattrs=(transparency=0.6 color=green) display=(caps fill mean median) extreme=true ;
			boxplotparm y=_2 x= _2_xaxis stat=quantile /  name="Summer" groupdisplay=overlay /*discreteoffset=0.15*/
					boxwidth=.3 legendlabel="Summer (June, July, August)"
					fillattrs=(transparency=0.6 color=red) display=(caps fill mean median) extreme=true ;
			boxplotparm y=_3 x= _3_xaxis stat=quantile /  name="Autumn" groupdisplay=overlay /*discreteoffset=0.15*/
					boxwidth=.3 legendlabel="Autumn (September, October, November)"
					fillattrs=(transparency=0.6 color=yellow) display=(caps fill mean median) extreme=true ;
			boxplotparm y=_4 x= _4_xaxis stat=quantile /  name="Winter" groupdisplay=overlay /*discreteoffset=0.15*/
					boxwidth=.3 legendlabel="Winter (December, January, February)"
					fillattrs=(transparency=0.6 color=blue) display=(caps fill mean median) extreme=true ;
			discretelegend "Winter" "Spring" "Summer" "Autumn" / location=inside halign=right valign=top border=off across=1;
		endlayout;

		layout overlay;
			drawtext "2006" / x=25 y=35 /*anchor=top*/ justify=center xspace=graphpercent yspace=graphpercent width=40;
			drawtext "Year" / x=55 y=30 /*anchor=top*/ justify=center xspace=graphpercent yspace=graphpercent width=40;
	    	drawtext "2007" / x=35 y=35 justify=center xspace=graphpercent yspace=graphpercent width=40;
			drawtext "2008" / x=55 y=35 justify=center xspace=graphpercent yspace=graphpercent width=40;
	    	drawtext "2009" / x=73 y=35 justify=center xspace=graphpercent yspace=graphpercent width=40;
	    	drawtext "2010" / x=88 y=35 justify=center xspace=graphpercent yspace=graphpercent width=40;
		endlayout;
		layout overlay/ xaxisopts=(type=discrete display=NONE) walldisplay=none;
			blockplot x=_1_xaxis block=_1/ class=quantile display=(values label outline) outlineattrs=(color=lightgray)
					valuehalign=center labelattrs=(size = 8) valueattrs=(size = 8);
			blockplot x=x1 block=y1/class=quantile display=( outline ) outlineattrs=(color=white) valuehalign=center
          			labelattrs=(size = 4) valueattrs=(size = 4);

			blockplot x=_2_xaxis block=_2/ class=quantile display=(values label outline) outlineattrs=(color=lightgray)
					valuehalign=center labelattrs=(size =8) valueattrs=(size = 8);
			blockplot x=x2 block=y2/class=quantile display=( outline) outlineattrs=(color=white) valuehalign=center
          			labelattrs=(size = 4) valueattrs=(size = 4);

			blockplot x=_3_xaxis block=_3/ class=quantile display=(values label outline) outlineattrs=(color=lightgray)
					valuehalign=center labelattrs=(size = 8) valueattrs=(size = 8);

			blockplot x=x3 block=y3/class=quantile display=( outline ) outlineattrs=(color=white) valuehalign=center
          			labelattrs=(size = 4) valueattrs=(size = 4);

			blockplot x=_4_xaxis block=_4/ class=quantile display=(values label outline) outlineattrs=(color=lightgray)
					valuehalign=center labelattrs=(size = 8) valueattrs=(size = 8);
	    	drawtext "Summary Statistics Table" / x=53 y=23 justify=center xspace=graphpercent yspace=graphpercent width=30;

		endlayout;
	  	endlayout;
	endgraph;
end;
proc sgrender data=q2_tp template=boxplot;
run;
