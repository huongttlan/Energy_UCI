from flask import Flask, render_template, request, redirect
from flask_bootstrap import Bootstrap
import urllib2
from bs4 import BeautifulSoup
import re

import pandas
from datetime import datetime
from bokeh.plotting import figure, show, save, output_file, vplot, hplot

#Function to read in the web and create data frame
def extract_data(link):
    #Open the data to get the values
        req = urllib2.Request(link)
        response = urllib2.urlopen(req)
        the_page = response.read()
        stocks=BeautifulSoup(the_page,"html.parser")
        #colname=stocks.find_all('column-name') 
        #Get the column names to know which one to extract
     
        #colname_clean=[]
        #for i in xrange(len(colname)):
            #colname_clean.append(repr(colname[i].contents))
            #if repr(colname[i].contents)=="[u'Date']": date_ix=i
            #elif repr(colname[i].contents)=="[u'Close']": close_ix=i
            #elif repr(colname[i].contents)=="[u'Adj. Close']": adjclose_ix=i
            #elif repr(colname[i].contents)=="[u'Volume']": vol_ix=i
        
        date_ix=0
        close_ix=4
        adjclose_ix=11 
        vol_ix=5
        #print date_ix, close_ix, adjclose_ix, vol_ix
        
        group=stocks.find_all('datum')
        datelist=[] #list for date
        closelist=[] #list for closing prices
        adjcloselist=[] #list for adjcloselist
        vollist=[] #list for volist
        for i in xrange(len(group)):
            if i%14==0: j=0
            else: j+=1
            if j==date_ix+1: 
                datelist.append(datetime.strptime(repr(group[i].contents)[3:-2],'%Y-%m-%d'))    
            elif j==close_ix+1: 
                closelist.append(float(repr(group[i].contents)[3:-2]))
            elif j==adjclose_ix+1:
                adjcloselist.append(float(repr(group[i].contents)[3:-2]))
            elif j==vol_ix+1:vollist.append(float(repr(group[i].contents)[3:-2]))
    
        df=pandas.DataFrame({'Date':datelist, 'Closing':closelist, 'Adj Closing':adjcloselist\
                   , 'Volume':vollist})

        return df
        
#Function to create graph
def create_grph(lst,df,stock):
    TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
    #Just figure out how to divide the graph to make it nicer
    fig_list=[]
    if u'Closing' in lst:
        output_file("./templates/stock.html", title=stock)
        a = figure(x_axis_type = "datetime", tools=TOOLS)
        a.line(df['Date'], df['Closing'], color='#1F78B4', legend='Closing Prices')
        a.title = "%s Closing Prices" %(stock)
        a.grid.grid_line_alpha=0.3
        fig_list.append('a')
    
    if u'Adjusted' in lst:
        output_file("./templates/stock.html", title=stock)
        b = figure(x_axis_type = "datetime", tools=TOOLS)
        b.line(df['Date'], df['Adj Closing'], color='#FF0000', legend='Adjusted Closing Prices')
        b.title = "%s Adjusted Closing Prices" %(stock)
        b.grid.grid_line_alpha=0.3 
        fig_list.append('b')

    if u'Volume' in lst:
        output_file("./templates/stock.html", title=stock)
        c = figure(x_axis_type = "datetime", tools=TOOLS)
        c.line(df['Date'], df['Volume'], color='#228B22', legend='Volumes')
        c.title = "%s Volumes" %(stock)
        c.grid.grid_line_alpha=0.3 
        fig_list.append('c')
        
    if 'a' in fig_list and 'b' in fig_list and 'c' in fig_list:
        p=vplot(hplot(a,b),c)
    elif 'a' in fig_list and 'b' in fig_list:
        p=hplot(a,b)
    elif 'a' in fig_list and 'c' in fig_list:
        p=hplot(a,c)
    elif 'b' in fig_list and 'c' in fig_list:
        p=hplot(b,c)
    elif 'a' in fig_list:
        p=a
    elif 'b' in fig_list:
        p=b
    elif 'c' in fig_list:
        p=c

    save(p)
    return None

app = Flask(__name__)
Bootstrap(app)


#Multiple choice questions
app.questions={}
app.questions['Stock']=('Closing price','Adjusted closing price','Volume')
app.nquestions=len(app.questions)

#Just a dictionary for the name of the stock
#ticket_database=ticket_dbs()

@app.route('/')
def main():
  return redirect('/index')
  
@app.route('/index',methods=['GET','POST'])
def index():
    nquestions=app.nquestions
    a1=app.questions['Stock'][0]
    a2=app.questions['Stock'][1]
    a3=app.questions['Stock'][2]
    if request.method == 'GET':
        return render_template('index.html',num=nquestions, ans1=a1,ans2=a2,ans3=a3)
    else:
        #request was a POST
        #Get stock name
        stock_name=request.form['symbol'].upper()
        lst=request.form.getlist('Type')
        
        #Now deal with when no choice is chosen
        
        #if stock_name not in ticket_database.keys(): 
        if u'Closing' not in lst and u'Adjusted' not in lst and u'Volume' not in lst:
            return redirect('/nochoice')
        else: 
            try:
                link="https://www.quandl.com/api/v3/datasets/WIKI/" + stock_name + ".xml" 
                df=extract_data(link)
                create_grph(lst,df,stock_name)
                return redirect('/answer')
            except:
                return redirect('/errormsg')

@app.route('/errormsg', methods=['GET','POST']) 
def errormsg():
    if request.method == 'GET':
        return render_template('errormsg.html')
    else:
        return redirect('/index')
        
@app.route('/nochoice',methods=['GET','POST']) 
def nochoice():
    if request.method == 'GET':
        return render_template('nochoice.html')
    else:
        return redirect('/index')

@app.route('/answer',methods=['GET']) 
def answer():
    return render_template("stock.html")
    
if __name__ == '__main__':
    app.run(host='0.0.0.0')
