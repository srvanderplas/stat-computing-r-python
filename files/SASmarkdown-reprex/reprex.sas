PROC SGPLOT data=sashelp.snacks;
SCATTER x = date y = QtySold /
  markerattrs=(size=8pt symbol=circlefilled)
  group = product; /* maps to point color by default */
RUN;
QUIT;
