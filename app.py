from flask import Flask, render_template, request, redirect
from flask_bootstrap import Bootstrap
import urllib2
from bs4 import BeautifulSoup
import re

import pandas
from datetime import datetime
from bokeh.plotting import figure, show, save, output_file, vplot, hplot

#Function to read in the whole dataset
def readin(yearno):
    energy=pandas.read_csv\
            ("household_power_consumption.txt",\
            sep=";",low_memory=False)
    year=[]
    month=[]
    day=[]
    for i in xrange(energy.shape[0]):
        temp=re.findall(r'(\w*/)',energy.ix[i,'Date'])
        year.append(int(energy.ix[i,'Date'][-4:]))
        month.append(int(temp[1][:-1]))
        day.append(int(temp[0][:-1]))
    
    energy['Year']=year
    energy['Month']=month
    energy['Day']=day
    
    #Ok, data are too big so have to divide them into different year to read it quicker
    dataout=energy[energy['Year']==yearno]
    #dataout['index'] = dataout.index
    return dataout #Just a data to extract

#Have to do this way because the dataset is pretty big so I cannot just wait them to load all

#energy2006=readin(yearno=2006)
#energy2006.to_csv('energy2006.txt', sep=';')

#energy2007=readin(yearno=2007)
#energy2007.to_csv('energy2007.txt', sep=';')

#energy2008=readin(yearno=2008)
#energy2008.to_csv('energy2008.txt', sep=';')

#energy2009=readin(yearno=2009)
#energy2009.to_csv('energy2009.txt', sep=';')

#energy2010=readin(yearno=2010)
#energy2010.to_csv('energy2010.txt', sep=';')

##############################################


#Now read in the data that got extracted:
def readsubset(yearno):
    energy=pandas.read_csv("energy%s.txt"%(yearno),sep=";",low_memory=False)
    return energy

#Function to create graph
def create_grph(year,df):
    TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
    #Just figure out how to divide the graph to make it nicer
    fig_list=[]
    output_file("./templates/year.html", title=year)
    a = figure(tools=TOOLS,width=1200, height=500)
    a.line(df.index,  df['Sub_metering_1'], color='#1F78B4', legend='The Kitchen')
    a.line(df.index, df['Sub_metering_2'], color='#FF0000', legend='The Laundry Room')
    a.line(df.index, df['Sub_metering_3'], color='#228B22', legend='Heater and Air Conditioner')
    a.title = "%s Usage of Electricity in Different Categories " %(year)
        #a.grid.grid_line_alpha=0.3
    fig_list.append('a')
    #show(a)
    p=a
    save(p)
    return None

    

app = Flask(__name__)
Bootstrap(app)


#Multiple choice questions
app.questions={}
app.questions['Measure']=('Summary description of active and reactive energy',\
                            'Seasonal minute voltage')
#app.nquestions=len(app.questions)

app.year={}
app.year['Year']=('2006','2007','2008', '2009', '2010')


@app.route('/')
def main():
  return redirect('/index')
  
@app.route('/index',methods=['GET','POST'])
def index():
    a1=app.questions['Measure'][0]
    a2=app.questions['Measure'][1]
   
    
    y1=app.year['Year'][0]
    y2=app.year['Year'][1]
    y3=app.year['Year'][2]
    y4=app.year['Year'][3]
    y5=app.year['Year'][4]
    
    if request.method == 'GET':
        return render_template('index.html',ans1=a1,ans2=a2,
                                year1=y1, year2=y2, year3=y3, year4=y4, year5=y5)
    else:
        #request was a POST
        lst=request.form.getlist('Measure')
        print lst
        if u'Summary' in lst:
            return redirect('/graph2')
        elif u'Energy' in lst:
            return redirect('/graph1')
        elif u'Seasonal' in lst:
            return redirect('/graph3')
        else:
            try:
                year=request.form['Year']
                datain=readsubset(year)
                create_grph(year=year,df=datain)
                return redirect('/answer')
            except:
                return redirect('/errormsg')
        
        #Now deal with when no choice is chosen
        
@app.route('/errormsg', methods=['GET','POST']) 
def errormsg():
    if request.method == 'GET':
        return render_template('errormsg.html')
    else:
        return redirect('/index')
 
@app.route('/graph2', methods=['GET','POST']) 
def graph2():
    if request.method == 'GET':
        return render_template('graph2.html')
    else:
        return redirect('/index')

@app.route('/graph3', methods=['GET','POST']) 
def graph3():
    if request.method == 'GET':
        return render_template('graph3.html')
    else:
        return redirect('/index')
        

@app.route('/graph1', methods=['GET','POST']) 
def graph1():
    if request.method == 'GET':
        return render_template('graph1.html')
    else:
        return redirect('/index')

@app.route('/answer',methods=['GET']) 
def answer():
    return render_template("year.html")
    
if __name__ == '__main__':
    app.run(host='0.0.0.0')

