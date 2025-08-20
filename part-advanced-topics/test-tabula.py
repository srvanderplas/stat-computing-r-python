
import sys
sys.path.append("/usr/lib/jvm/default-java/bin/java")

import tabula
tabula.util.environment_info()

import pdfplumber
import tabula
from glob import glob
import numpy as np

files = glob("../data/bls-pdfs/*.pdf")

def find_page_number(file):
  pdf = pdfplumber.open(file)
  has_tb1 = ["Table 1" in i.extract_text() for i in pdf.pages]
  pdf.close()
  return int(np.where(has_tb1)[0][0])

# page_numbers = [find_page_number(i) for i in files]
# page_numbers = [i[0] for i in page_numbers]
page_numbers = [8, 8, 7, 8, 8, 8, 7, 8, 9, 8, 8, 7, 8, 8, 8, 9, 8, 8, 8, 7, 7, 9, 8]

tables = tabula.io.read_pdf(files[0], pages=page_numbers[0]+1)
print(tables )

tbl = tabula.io.read_pdf(files[0], pages=page_numbers[0]+1, area=[128, 35, 586, 575], pandas_options={'header': None})[0] 
print(tbl)
from itertools import chain
import pandas as pd 

header = tabula.io.read_pdf(files[0], pages=page_numbers[0]+1, area=[89, 35, 128, 575], pandas_options={'header': None})[0]

def fix_headers(tbl): # <1>
  modifiers=[["", "Rel_imp."], ["Unadj_idx."]*3, ["Unadj_pct_chg."]*2, ["Seas_adj_pct_chg."]*3] # <2>
  modifiers=list(chain.from_iterable(modifiers)) # <3>
  # https://stackoverflow.com/questions/11860476/how-to-unnest-a-nested-list
  
  spans=pd.Series([tbl.loc[0,0],  # <4>
  ''.join(tbl.loc[1:2,1]),  # <4>
  ''.join(tbl.loc[1:2,2]),  # <4>
  ''.join(tbl.loc[1:2,3]),  # <4>
  ''.join(tbl.loc[1:2,4]),  # <4>
  ''.join(tbl.loc[0:3,5]),  # <4>
  ''.join(tbl.loc[0:3,6]),  # <4>
  ''.join(tbl.loc[0:3,7]),  # <4>
  ''.join(tbl.loc[0:3,8]),  # <4>
  ''.join(tbl.loc[0:3,9])])  # <4>
  spans=spans.str.replace("\.", "", regex = True)  # <5>
  spans=spans.str.replace("[ -]", "_", regex = True)  # <5>
  
  return modifiers + spans

header = fix_headers(header)  # <6>
header

def read_table_1(file, page_number):   # <7>
  tbl    = read_pdf(file, pages=page_number+1, area=[128, 35, 586, 575], pandas_options={'header': None})[0]  # <8>
  header = read_pdf(file, pages=page_number+1, area=[ 89, 35, 128, 575], pandas_options={'header': None})[0]   # <9>
  header=fix_headers(header)  # <10>
  tbl = tbl.rename(header, axis=1)  # <11>
  return tbl

tables = [read_table_1(file, page_numbers[i]) for i,file in enumerate(files)]   # <12>
tables[2]


import pandas as pd
import os
 
report_date = pd.Series([os.path.basename(i) for i in files]) # <1>
report_date = report_date.str.replace("cpi_|\.pdf$", "", regex=True) # <1>
report_date = pd.to_datetime(report_date, format="%m%d%Y") # <1>

cpi_data = pd.DataFrame()
for i,tbl in enumerate(tables):
  tbl['report_date'] = report_date[i] # <2>
  tbl = tbl.melt(id_vars=['Expenditure_category', 'report_date'], value_name='val', var_name='var') # <3>
  cols = pd.DataFrame(tbl['var'].str.split("\.").to_list(), columns=['varname', 'vardate'])
  tbl = pd.concat([tbl, cols], axis = 1) # <4>
  tbl = tbl.set_index(['report_date', 'Expenditure_category', 'vardate']) # <5>
  tbl = tbl.drop(['var'], axis=1) # <5>
  tbl_wide = tbl.pivot(columns='varname', values = 'val') # <5>
  tbl_wide = tbl_wide.reset_index() # <5>
  cpi_data = pd.concat([cpi_data, tbl_wide], axis=0) # <6>

cpi_data['Expenditure_category'] = cpi_data['Expenditure_category'].str.replace("[ \.]{1,}$", "", regex=True) # <7>

cpi_data.shape
cpi_data.head



tmp = cpi_data.query("~vardate.str.contains(r'_')")
tmp = tmp.assign(vardate = pd.to_datetime(tmp['vardate'], format="%b%Y")) 

tmp2 = tmp.query('Expenditure_category.isin(["Energy", "Food", "Shelter", "Medical care services", "commodities", "Transportation services"])')

tmp2 = tmp2.assign(year = lambda x: x['vardate'].dt.year,
                   days = lambda x: (pd.to_datetime(x['year']+1, format='%Y') - 
                          pd.to_datetime(x['year'], format='%Y')).dt.days,
                   var_dec_date = lambda x: x.year + (x['vardate']-pd.to_datetime(x.year, format='%Y'))/ (x.days * pd.to_timedelta(1, unit="D")))

cat_repl = {'Medical care services':'Medical', 'commodities':'Goods', 'Transportation services':'Transit'}
tmp2=tmp2.rename(columns = {'Expenditure_category':'Category', 'var_dec_date': 'date'})
for old,new in cat_repl.items():
  tmp2.loc[:,'Category'] = tmp2.Category.str.replace(old, new, regex=False)

tmp_plot = tmp2[['date', 'Unadj_idx', 'Category']]
tmp_plot = tmp_plot.drop_duplicates()
tmp_plot = tmp_plot.assign(Unadj_idx = lambda x: pd.to_numeric(x.Unadj_idx))

import seaborn.objects as so
import seaborn as sns
import matplotlib.pyplot as plt

plot = sns.lineplot(data = tmp_plot, x = 'date', y = 'Unadj_idx', hue = 'Category')
plot.set(xlabel="Date", ylabel="Unadjusted Index")
plt.show()
