import dill

f=open("mean1_2010","r")
mean1=dill.load(f)
f.close()
print mean1

f=open("mean2_2010","r")
mean2=dill.load(f)
f.close()
print mean2

f=open("mean3_2010","r")
mean3=dill.load(f)
f.close()
print mean3
