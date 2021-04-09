using JDF
using CSV
using DataFrames

#generate data
n=20_000
df0=DataFrame(v=repeat(vcat("abc"),n));
allowmissing(df0)
df0.v = convert(Vector{Union{Missing,String}},df0.v)
df0.v[end] = missing

#write file
csvfile = raw"C:\tmp\afile.csv"
CSV.write(csvfile ,df0)

#read file
csvSep=','
df =  CSV.read(csvfile, DataFrame,threaded=true, delim=csvSep, pool=0.05,strict=true, lazystrings=false);

#save jdf
jdffi = raw"C:\tmp\df.jdf"
jdffile = JDF.savejdf(jdffi, df)

#load jdf
dfloaded = JDF.loadjdf(jdffi)

df.v #<- this one is pooled as expected
dfloaded.v #<- not pooled anymore

df.v

using DataAPI
levels(df.v)
describe(df.v)
DataAPI.refpool(df.v)
refvalue(df.v)
DataAPI.refarray(df.v)
DataAPI.defaultarray(df.v)

Base.summarysize(df)/1024/1024
Base.summarysize(dfloaded)/1024/1024