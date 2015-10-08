from flask import Flask, render_template, request, redirect
from flask_bootstrap import Bootstrap
import urllib2
from bs4 import BeautifulSoup
import re

import pandas
from datetime import datetime
from bokeh.plotting import figure, show, save, output_file, vplot, hplot

#Now read in the data that got extracted:
def readsubset(yearno):
    energy=pandas.read_csv("energy%s.txt"%(yearno),sep=";",low_memory=False)
    return energy
nah=readsubset(yearno='2006')
yearno='2006'

TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
output_file("./templates/year.html", title=yearno)
a = figure(tools=TOOLS,width=1200, height=500)
a.line(nah.index,  nah['Sub_metering_1'], color='#1F78B4', legend='Kitchen')
a.title = "%s Energy Type" %(yearno)
#a.grid.grid_line_alpha=0.3
show(a)
#fig_list.append('a')