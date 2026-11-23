/* Final Project.sas
   FEV1 longitudinal analysis (MATH 6364 Statistical Methods, Fall 2023)
   Transcribed from the SAS code appendix of the final report.
   Only change from the original: the FILENAME path now points to the
   repository's data/fev.csv instead of the author's local machine path.

   NOTE: In the source printout, the last two GEE steps (compound symmetry
   and AR(1)) are cut off after the MODEL statement — the REPEATED statement
   and RUN are missing there, exactly as printed. The unstructured GEE step
   below shows the pattern they follow.
*/

/* Importing FEV Data from CSV File */
FILENAME REFFILE "data/fev.csv";

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=respiratory REPLACE;
GETNAMES=YES;
RUN;

/* Quick Look at the Imported Data */
proc print data=respiratory;
run;

/* Creating Visual Profiles for Each Study Arm */
/* Visualizing Individual Time Series by Drug */
ods graphics on;
proc sgpanel data=respiratory;
panelby DRUG / onepanel columns=3;
series x=Time y=fev / group=PATIENT lineattrs=(thickness=1);
rowaxis grid min=0 max=6;
colaxis grid max=8;
run;
ods graphics off;

/* Sorting Data by Drug for Separate Plots */
proc sort data=RESPIRATORY;
by DRUG;
run;

/* Plotting FEV1-FEV8 for Each Patient by Drug */
proc sgplot data=RESPIRATORY;
series x=time y=fev / group=patient;
by drug;
run;

/* Sorting Data by Drug and Time */
proc sort data=RESPIRATORY;
by DRUG time;
run;

/* Calculating and Displaying Mean FEV1 by Time and Drug */
proc means data=RESPIRATORY mean;
by DRUG time;
var fev;
output out=fev_means mean=mean_fev;
run;

proc print data=fev_means;
title 'FEV1 Means by Time for Each Drug';
var DRUG time mean_fev;
run;

/* Creating Table for Mean FEV for Each Drug */
proc sql;
create table mean_fev as
select time, DRUG, mean(fev) as Mean_FEV
from respiratory
group by time, DRUG;
quit;

/* Plotting Mean FEV by Time for Each Drug */
ods graphics on;
proc sgplot data=mean_fev;
series x=time y=Mean_FEV / group=DRUG markers lineattrs=(thickness=2);
xaxis label='Time (Hours)';
yaxis label='Mean FEV' min=2 max=4;
run;
ods graphics off;

/* Repeated Measures Models with Different Covariance Structures */
/* Unstructured (UN) Covariance Structure */
proc mixed data=respiratory method=reml covtest;
class drug patient time;
model fev=drug time drug*time / solution;
repeated / type=un subject=patient(drug) r rcorr;
run;

/* Compound Symmetry (CS) Covariance Structure */
proc mixed data=respiratory method=reml covtest;
class drug patient time;
model fev=drug time drug*time;
repeated / type=cs subject=patient(drug) r rcorr;
run;

/* Autoregressive (AR1) Covariance Structure */
proc mixed data=respiratory method=reml covtest;
class drug patient time;
model fev=drug time drug*time;
repeated / type=ar(1) subject=patient(drug) r rcorr;
run;

/* Unstructured (UN) Covariance Structure - Assessing Assumptions */
proc mixed data=respiratory method=reml covtest plots=all;
class drug patient time;
model fev=drug time drug*time;
repeated / type=un subject=patient(drug) r rcorr;
run;

/* Multilevel Models for FEV Data Analysis */
/* Unconditional Mean Model */
proc means data=respiratory mean std stderr;
var fev;
run;

proc mixed data=respiratory method=reml covtest;
class patient;
model fev = / solution notest outpm=modelA;
random intercept / sub=patient type=un;
run;

/* Unconditional Growth Model */
proc mixed data=respiratory method=reml covtest;
class patient;
model fev = time / solution notest outpm=modelB;
random intercept time / type=un sub=patient;
run;

/* Conditional Growth Model with Drug Interactions */
proc mixed data=respiratory method=reml covtest;
class patient drug;
model fev = drug time drug*time / solution outpm=modelC;
random intercept time / type=un sub=patient;
run;

/* Assumption Checks for Multilevel Models */
proc mixed data=respiratory covtest method=reml plots=all;
class patient drug;
model fev = drug time drug*time / solution;
random intercept time / type=un sub=patient;
run;

/* GEE Models with Various Correlation Structures */
/* GEE Model with Compound Symmetry (CS) */
proc genmod data=respiratory;
class patient drug;
model fev = drug time drug*time;
/* NOTE: source printout ends this step here (no REPEATED statement, no RUN). */

/* GEE with UN Structure */
proc genmod data=respiratory;
class patient drug;
model fev = drug time drug*time;
repeated subject=patient / type=un corrw;
run;

/* GEE with AR(1) Structure */
proc genmod data=respiratory;
class patient drug;
model fev = drug time drug*time;
/* NOTE: source printout ends here — the AR(1) GEE step is cut off mid-code. */
