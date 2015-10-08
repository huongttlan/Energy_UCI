from flask import Flask, render_template, request, redirect
from flask_bootstrap import Bootstrap
import urllib2
from bs4 import BeautifulSoup
import re

import pandas
from datetime import datetime
from bokeh.plotting import figure, show, save, output_file, vplot, hplot
import numpy as np

#Function to read in the whole dataset
def readin(yearno):
    energy=pandas.read_csv\
            ("/Users/huongtrinh/Desktop/Energy_dataset/household_power_consumption.txt",\
            sep=";",low_memory=False)
    year=[]
    month=[]
    day=[]
    hour=[]
    minute=[]
    for i in xrange(energy.shape[0]):
        temp=re.findall(r'(\w*/)',energy.ix[i,'Date'])
        year.append(int(energy.ix[i,'Date'][-4:]))
        month.append(int(temp[1][:-1]))
        day.append(int(temp[0][:-1]))
        hour.append(int(energy.ix[i,'Time'][0:2]))
        minute.append(int(energy.ix[i,'Time'][3:5]))
        #try:
        #    energy.ix[i,'Sub_metering_1']=float(energy.ix[i,'Sub_metering_1'])
        #except:
        #    energy.ix[i,'Sub_metering_1']=np.nan
            
    energy['Year']=year
    energy['Month']=month
    energy['Day']=day
    energy['Hour']=hour
    energy['Minute']=minute
    #energy['Sub_metering_1']=energy['Sub_metering_1'].astype(float)
    
    #Ok, data are too big so have to divide them into different year to read it quicker
    dataout=energy[energy['Year']==yearno]
    #dataout['index'] = dataout.index
    return energy, dataout #Just a data to extract

total_energy, energy2006=readin(yearno=2006)
#print total_energy
#print total_energy.dtypes
energy_fin = total_energy.convert_objects(convert_numeric=True)

######################################
# Now add the time series part in
energy2010=energy_fin [energy_fin['Year']==2010]
energy2010.is_copy=False
#print energy2010

energy_train=energy_fin [energy_fin['Year']!=2010]
energy_train.is_copy=False

#print energy_train
import sklearn
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import FeatureUnion
from sklearn.pipeline import Pipeline
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsRegressor
from sklearn.feature_extraction import DictVectorizer
from sklearn import datasets, linear_model
from sklearn.metrics import r2_score

#First Mean estimator 
class Estimator_mean(sklearn.base.BaseEstimator, sklearn.base.RegressorMixin):
    def __init__ (self):
        self.avg_Submetering1 ={}
        self.avg_Submetering2 ={}
        self.avg_Submetering3 ={}
        
    def fit(self, df):
        try:
            self.avg_Submetering1=df.groupby(by=['Month', 'Day', 'Hour', 'Minute'])['Sub_metering_1'].mean()   
        except:
            self.avg_Submetering1 ={}
        
        try:
            self.avg_Submetering2=df.groupby(by=['Month', 'Day', 'Hour', 'Minute'])['Sub_metering_2'].mean()   
        except:
            self.avg_Submetering2 ={}
        
        try:
            self.avg_Submetering3=df.groupby(by=['Month', 'Day', 'Hour', 'Minute'])['Sub_metering_3'].mean()   
        except:
            self.avg_Submetering3 ={}

        return self
  
    def predict1(self,monthx, dayx, hourx, minutex):
        try:
            return float(self.avg_Submetering1[monthx, dayx, hourx, minutex])
        except:
            return 0
    
    def predict2(self,monthx, dayx, hourx, minutex):
        try:
            return float(self.avg_Submetering2[monthx, dayx, hourx, minutex])
        except:
            return 0
    
    def predict3(self,monthx, dayx, hourx, minutex):
        try:
            return float(self.avg_Submetering3[monthx, dayx, hourx, minutex])
        except:
            return 0   


estimator = Estimator_mean()  # initialize
estimator.fit(energy_train)  # fit data   
#print estimator.avg_Submetering1
#print energy_train.groupby(by=['Month', 'Day', 'Hour'])['Sub_metering_1'].mean() 
mean1=[]
mean2=[]
mean3=[]

for i in xrange(0, energy2010.shape[0]):
    mean1.append(estimator.predict1(energy2010['Month'].values[i], energy2010['Day'].values[i],\
                             energy2010['Hour'].values[i], energy2010['Minute'].values[i]))
    mean2.append(estimator.predict2(energy2010['Month'].values[i], energy2010['Day'].values[i],\
                             energy2010['Hour'].values[i], energy2010['Minute'].values[i]))
    mean3.append(estimator.predict3(energy2010['Month'].values[i], energy2010['Day'].values[i],\
                             energy2010['Hour'].values[i], energy2010['Minute'].values[i]))

energy2010['Mean_Est_Sub_metering_1']=mean1
energy2010['Mean_Est_Sub_metering_2']=mean2
energy2010['Mean_Est_Sub_metering_3']=mean3

print energy2010

###############################
# Second linear regression estimator
class kEstimator(sklearn.base.BaseEstimator, sklearn.base.RegressorMixin):
    def __init__ (self):
        self.neigh=KNeighborsRegressor(n_neighbors=5)
        
    def fit(self,X, y):
        self.neigh.fit(X, y) 
        return self
    
    def predict(self,X):
        try:
            return self.neigh.predict(X)
        except:
            return 0
'''
Xsubset_np=energy_train[['Month','Hour', 'Day']].as_matrix()
Ysubset_np=energy_train[['Sub_metering_1']].as_matrix()
test=np.array([energy2010['Month'], energy2010['Hour'], energy2010['Day'], energy2010['Minute']])
estimator_kmeans = kEstimator()  # initialize
print estimator_kmeans.fit(Xsubset_np,Ysubset_np)  # fit data
'''
#Just figure out how to divide the graph to make it nicer
fig_list=[]

from bokeh.plotting import figure, show, output_file

def create_grph2(df):
    TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
    output_file("test.html")
    a = figure(tools=TOOLS,height=500, width=1000)
    a.xaxis.axis_label = 'Original Results'
    a.yaxis.axis_label = 'Estimated Results'
    a.circle(df['Sub_metering_1'].as_matrix(), df['Mean_Est_Sub_metering_1'].as_matrix(), color='#1F78B4', \
                 legend='The Kitchen',fill_alpha=0.2, size=10)
    #a.line(df.Fulldate, df['Sub_metering_2'], color='#FF0000', legend='The Laundry Room Original')
    #a.line(df.Fulldate, df['Sub_metering_3'], color='#228B22', legend='Heater and Air Conditioner Original')
    a.title = "Comparison between original results and results estimated by regression"
    a.grid.grid_line_alpha=0.3
    return a
a=create_grph2(energy2010)
show(a)

'''
from sklearn.metrics import r2_score

coefficient_of_dermination = r2_score(energy2010['Sub_metering_1'].as_matrix(), \
                                        energy2010['Mean_Est_Sub_metering_1'].as_matrix())
print coefficient_of_dermination
'''


from scipy import stats
import numpy as np
x = energy2010['Sub_metering_1'].as_matrix()
y = energy2010['Mean_Est_Sub_metering_1'].as_matrix()
slope, intercept, r_value, p_value, std_err = stats.linregress(x,y)
print r_value**2

#print energy2010

import dill

'''
f=open("mean1_2010","wb")
dill.dump(mean1, f)
f.close()

f=open("mean2_2010","wb")
dill.dump(mean2, f)
f.close()

f=open("mean3_2010","wb")
dill.dump(mean3, f)
f.close()
'''


