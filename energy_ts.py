#Import packages
import pandas as pd
import numpy as np


import sklearn
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import FeatureUnion
from sklearn.pipeline import Pipeline
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsRegressor
from sklearn.feature_extraction import DictVectorizer
from sklearn import datasets, linear_model

import datetime
import simplejson as js
import json 
import dill
import re






import re
import pandas as pd
from sklearn import linear_model
import sklearn
import dill
import sklearn

class mySuperEstimator(sklearn.base.BaseEstimator, sklearn.base.RegressorMixin):
    def __init__(self):
        self.estimators = dict()
        self.hot=dict()
    def fit(self, data):
        def localfun(localdata):
            cname = localdata['city'].values[0]
            y = localdata[['temp']]
            X = localdata[['month','hour']]
            estimator = linear_model.LinearRegression()
            onehot=sklearn.preprocessing.OneHotEncoder()
            t=onehot.fit_transform(X)
            estimator.fit(t, y)
            self.estimators[cname] = estimator
            self.hot[cname]=onehot
            return None
            
        data.groupby('city').apply(localfun)

        return self

    def predict(self, line):
        data=line.split()
        month_test=int(data[1])
        hour_test=int(data[3])
        city_test=data[-1]
        aaa=pd.DataFrame([int(data[1]),int(data[3])]).T
        bbb=self.hot[city_test].transform(aaa)
        retval = float(self.estimators[city_test].predict(bbb)[0])
        return retval
     


myRawTrainData = pd.read_csv('train.txt', delim_whitespace=True, header=None)
myRawTrainData.columns = ['year', 'month', 'day', 'hour', 'temp', 'dew_temp', 'pressure', \
                          'wind_angle', 'wind_speed', 'sky_code', 'rain_hour', 'rain_6hour', \
                          'city']
#print myRawTrainData

hey=myRawTrainData[myRawTrainData['temp']!=-9999]
tmpEst = mySuperEstimatorByCity()
tmpEst.fit(hey)

f=open("q1_model_sat","wb")
dill.dump(tmpEst,f)
f.close()
'''

linesTxt = [
    u"2000 01 01 00   -11   -72 10197   220    26     4     0     0 bos",
    u"2000 01 01 01    -6   -78 10206   230    26     2     0 -9999 bos",
    u"2000 01 01 02   -17   -78 10211   230    36     0     0 -9999 bos",
    u"2000 01 01 03   -17   -78 10214   230    36     0     0 -9999 bos",
    u"2000 01 01 04   -17   -78 10216   230    36     0     0 -9999 bos",
]


f=open("q1_model_sat", "r")
q1_model=dill.load(f)
print q1_model.predict(linesTxt[0])
f.close()
