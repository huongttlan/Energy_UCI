libname rawdata "C:\Users\huong.trinh\Desktop\household_power_consumption\datatosas";
proc import 
datafile="C:\Users\huong.trinh\Desktop\household_power_consumption\household_power_consumption_1.csv"
out=household1 dbms=dlm
replace;
delimiter=",";
getnames=yes;
guessingrows=20000;
run;
proc import 
datafile="C:\Users\huong.trinh\Desktop\household_power_consumption\household_power_consumption_2.csv"
out=household2 dbms=dlm
replace;
delimiter=",";
getnames=yes;
guessingrows=20000;
run;
data group;
	set household1 household2;
	/*Transform the values into numeric*/
	Global_active_power_n=input(Global_active_power,??best.);
	Global_reactive_power_n=input(Global_reactive_power,??best.);
	Voltage_n=input(Voltage,??best.);
	Global_intensity_n=input(Global_intensity,??best.);
	Sub_metering_1_n=input(Sub_metering_1,??best.);
	Sub_metering_2_n=input(Sub_metering_2,??best.);
	Sub_metering_3_n=input(Sub_metering_3,??best.);
	drop Global_active_power Global_reactive_power Voltage Global_intensity Sub_metering_1 Sub_metering_2 Sub_metering_3;
	rename Global_active_power_n=Global_active_power 
			Global_reactive_power_n=Global_reactive_power Voltage_n=Voltage Global_intensity_n=Global_intensity 
			Sub_metering_1_n=Sub_metering_1 sub_metering_2_n=Sub_metering_2 sub_metering_3_n=Sub_metering_3;
run;
data rawdata.rawpower;
	set group;
run;
