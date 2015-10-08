*******************************************************************************************
Program:    plot.sas
Programmer: Huong Trinh
Validator:
Client:     Sponsor Name
Project:    Study Name
Date:       15JUN2015
Production Path:  C:\Users\huong.trinh\Desktop\household_power_consumption\project\Tables\Production\plot.sas
Purpose:
*******************************************************************************************
Modification:
Version   Date       Pgm     Val   Reason
*******************************************************************************************;

data rawpower;
	set rawdata.rawpower;
	/*Try to make the first plot as time series based on all data */
	datetime=dhms(Date, 0, 0, Time);
	format datetime datetime23.; 
	monthcat=month(date);
	hourcat=hour(time);
	other=Global_active_power*1000/60 - Sub_metering_1-Sub_metering_2-Sub_metering_3;
run;
/********************************************************************/
/********************************************************************/
/********************************************************************/
*Try to summary by hours;
proc sql;
create table hours as
select monthcat, hourcat, avg(Global_active_power) as hr_active, avg(Global_reactive_power) as hrreactive,
		avg(Voltage) as hr_voltage, avg(Global_intensity) as hr_Global_intensity, 
		avg(Sub_metering_1) as hr_Sub_metering_1, avg(Sub_metering_2) as hr_Sub_metering_2, 
		avg(Sub_metering_3) as hr_Sub_metering_3
from rawpower
group by monthcat, hourcat
order by monthcat, hourcat;
quit;

%let ttlfnts=10;
%let textfnts=9;
%let _tmargin=0.01;
%let _bmargin=0.01;
%let _lmargin=0.01;
%let _rmargin=0.01;
%put &_tmargin;
%let _pagesize=71;
ods path show;
ods path(prepend) work.templat(update);

proc template;
	define statgraph block;
		begingraph;
			layout overlay;
				blockplot x=hourcat block=monthcat/valuevalign=bottom datatransparency=0.75 display=(fill values);
				scatterplot y=hr_active x=hourcat;
				pbsplineplot y=hr_active x=hourcat;
		endlayout;
		endgraph;
	end;
run;
proc template;
	define statgraph series;
	dynamic xlabel ylabel ymin ymax xmin xmax increase increase1;
	begingraph;
			layout overlay/ xaxisopts=(type=linear offsetmin=0.01 offsetmax=0.01 label=xlabel display=all /*(line label tickvalues)*/
										linearopts = (viewmin=xmin viewmax=xmax  
														tickvaluesequence = (start=xmin end=xmax increment=increase1))
										labelattrs = (size = &textfnts))

				yaxisopts=(type=linear offsetmin=0.01 offsetmax=0.01 label =ylabel display = all
                     	  linearopts = (viewmin=ymin viewmax=ymax /* tickvalueformat=Yaxfmt.*/ 
										tickvaluesequence = (start=ymin end=ymax increment=increase))
                      	 labelattrs = (size = &textfnts));

				seriesplot  x=datetime y=SUB_METERING_1/ /*group=TRIPno*/ name="Trip";
				scatterplot x=datetime y=SUB_METERING_1/ /*group=TRIPno*/ datalabel=ord1 markerattrs=(symbol=diamond /*color=red*/ size=3px);

			endlayout;
		endgraph;
	end;
run;
options noquotelenmax validvarname=upcase compress=yes
            sysprintfont= ("&_fontface" &_fontsize All) ORIENTATION=LANDSCAPE   
            topmargin=&_tmargin in  bottommargin=&_bmargin in leftmargin=&_lmargin in  rightmargin=&_rmargin in 
            ls=&_linesize ps=&_pagesize nocenter nodate nonumber pageno=1 missing=' ' nofmterr
            FORMCHAR="|____|+|___+=|_/\<>*"
            /*FORMCHAR="|----|+|---+=|-/\<>*"*/
            mautosource sasautos=(sasautos, "&_root.macro");
%let subfnsize = %sysevalf(&ttlfnts - 1);
ods listing close;
options orientation = landscape;
goptions xpixels = 3200 ypixels = 2800;
%macro printout(fileout=,title1=);
%prepp(_tltyp=%str(rtf2), _tlnam=&fileout);
proc printto new print=outfile; run;
ods graphics on / reset width = 15.69in height = 11.34in border = off ;
*** please generate titles and footnotes same methods as tables ***;
/*    title1 &_t1; */
/*    title2 &_t2; */
	title1 justify= center "&title1";
%mend;
%macro finaloutput(datain=,labely=, labelx=,miny=,maxy=,minx=, maxx=, inc=, inc1=0.005,temp=scatter);
proc sgrender data=&datain template=&temp;
	dynamic  ylabel=&labely xlabel=&labelx ymin=&miny ymax=&maxy xmin=&minx xmax=&maxx increase=&inc increase1=&inc1;
run;
%mend;
%printout(fileout=%str(Series_plot),title1=%str(Energy Usage Trend));
%finaloutput(datain=rawpower,labely=%str("Testout"), labelx=%str("year") ,miny=0,maxy=1,inc=0.01, maxx=10000,minx=1000, temp=series);



