# Databricks notebook source
import pyspark
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('test').getOrCreate()
# cores = spark._jsc.sc().getExecutorMemoryStatus().keySet().size()
# print("The number of cores we are using:", cores)
spark
print('Done!')

# COMMAND ----------

mkdir tt

# COMMAND ----------

# MAGIC %md
# MAGIC ## Data Loading

# COMMAND ----------

# path = "dbfs:/FileStore/test/"
# df = spark.read.csv(path + 'Toddler Autism dataset July 2018.csv',inferSchema=True,header=True)
# Toddler_Autism_dataset_July_2018.csv

df = spark.read.csv('dbfs:/FileStore/test/credit_card_data.csv',inferSchema=True,header=True)

# COMMAND ----------

df.limit(6).toPandas()

# COMMAND ----------

display(df.limit(6))

# COMMAND ----------

df.printSchema()

# COMMAND ----------

# MAGIC %md
# MAGIC ### Check null values

# COMMAND ----------

from pyspark.sql.functions import *

def null_value_calc(df):
    null_columns_counts = []
    numRows = df.count()
    for k in df.columns:
        nullRows = df.where(col(k).isNull()).count()
        if(nullRows > 0):
            temp = k,nullRows,(nullRows/numRows)*100
            null_columns_counts.append(temp)
    return(null_columns_counts)

null_columns_calc_list = null_value_calc(df)
spark.createDataFrame(null_columns_calc_list, ['Column_Name', 'Null_Values_Count','Null_Value_Percent']).show()

# COMMAND ----------

# MAGIC %md
# MAGIC ### Fill in null values

# COMMAND ----------

from pyspark.sql.functions import *
def fill_with_mean(df, include=set()): 
    stats = df.agg(*(avg(c).alias(c) for c in df.columns if c in include))
    return df.na.fill(stats.first().asDict())

columns = df.columns
columns = columns[1:]
df = fill_with_mean(df, columns)
df.limit(5).toPandas()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Convert to vectors

# COMMAND ----------

from pyspark.ml.feature import VectorAssembler
input_columns = df.columns # Collect the column names as a list
input_columns = input_columns[1:] # keep only relevant columns: from column 8 until the end
vecAssembler = VectorAssembler(inputCols=input_columns, outputCol="features")
df_kmeans = vecAssembler.transform(df) #.select('CUST_ID', 'features')
df_kmeans.limit(4).toPandas()

# COMMAND ----------

# MAGIC %md
# MAGIC ## K-mean clustering

# COMMAND ----------

from pyspark.ml.clustering import KMeans
from pyspark.ml.evaluation import ClusteringEvaluator
import numpy as np

# COMMAND ----------

# set a max for the number of clusters you want to try out
kmax = 500
# Create and array filled with zeros for the amount of k
# Similar to creating an empty list
kmcost = np.zeros(kmax)
for k in range(2,kmax):
    # Set up the k-means alogrithm
    kmeans = KMeans().setK(k).setSeed(1).setFeaturesCol("features")
    # Fit it on dataframe
    model = kmeans.fit(df_kmeans)
    # Fill in the zeros of array with cost....
    predictions = model.transform(df_kmeans)
    evaluator = ClusteringEvaluator()
    kmcost[k] = evaluator.evaluate(predictions) #computing Silhouette score

# COMMAND ----------

# set a max for the number of clusters you want to try out
kmax = 1000
# Create and array filled with zeros for the amount of k
# Similar to creating an empty list
kmcost = np.zeros(kmax)
for k in range(2,kmax):
    # Set up the k-means alogrithm
    kmeans = KMeans().setK(k).setSeed(1).setFeaturesCol("features")
    # Fit it on dataframe
    model = kmeans.fit(df_kmeans)
    # Fill in the zeros of array with cost....
    predictions = model.transform(df_kmeans)
    evaluator = ClusteringEvaluator()
    kmcost[k] = evaluator.evaluate(predictions) #computing Silhouette score

# COMMAND ----------

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# Set up the plot dimensions
fig, ax = plt.subplots(1,1, figsize =(8,6))
# Then specify the range of values for the axis and call on your cost array
ax.plot(range(2,kmax),kmcost[2:kmax])
# Set up the axis labels
ax.set_xlabel('k')
ax.set_ylabel('cost')

# COMMAND ----------

import seaborn as sns


# COMMAND ----------

# MAGIC %md
# MAGIC ## Frequent Pattern Mining

# COMMAND ----------

path = 'dbfs:/FileStore/test/'

df = spark.read.option("delimiter", "\t").csv(path+'data_final.csv',inferSchema=True,header=True)

# COMMAND ----------

df.limit(4).toPandas()

# COMMAND ----------

df.count()

# COMMAND ----------

# MAGIC %md
# MAGIC ### Find Frequent pattern

# COMMAND ----------

from pyspark.sql.functions import *

p_types = df.withColumn("vert",expr("CASE WHEN EXT1 in('4','5') or EXT5 in('4','5') or EXT7 in('4','5') or EXT9 in('4','5') THEN 'extrovert' WHEN EXT1 in('1','2') or EXT5 in('1','2') or EXT7 in('1','2') or EXT9 in('1','2') THEN 'introvert' ELSE 'neutrovert' END AS vert"))
p_types = p_types.withColumn("mood",expr("CASE WHEN EST2 in('4','5') THEN 'chill' WHEN EST2 in('1','2') THEN 'highstrung' ELSE 'neutral' END AS mood"))

p_types = p_types.select(array('mood', 'vert').alias("items"))
p_types.limit(4).toPandas()

# COMMAND ----------

from pyspark.ml.fpm import FPGrowth
fpGrowth = FPGrowth(itemsCol="items", minSupport=0.3, minConfidence=0.1)
model = fpGrowth.fit(p_types)

# COMMAND ----------

# MAGIC %md 
# MAGIC ### Determine item popularity

# COMMAND ----------

itempopularity = model.freqItemsets
itempopularity.createOrReplaceTempView("itempopularity")
# Then Query the temp view
print("Top 20")
spark.sql("SELECT * FROM itempopularity ORDER BY freq desc").limit(200).toPandas()

# COMMAND ----------

# MAGIC %md
# MAGIC ### Association rules

# COMMAND ----------

# Display generated association rules.
assoc = model.associationRules
assoc.createOrReplaceTempView("assoc")
# Then Query the temp view
print("Top 20")
spark.sql("SELECT * FROM assoc ORDER BY confidence desc").limit(20).toPandas()

# COMMAND ----------

# MAGIC %md
# MAGIC ### Prediction  

# COMMAND ----------

predict = model.transform(p_types)
predict.limit(15).toPandas()

# COMMAND ----------

df_array = df.select(array(array('EXT1', 'EXT2'),array('EXT3','EXT4'),array('EXT5','EXT6'),array('EXT7','EXT8'),array('EXT9','EXT10')).alias("sequence"))
df_array.show(truncate=False)

# COMMAND ----------

dbutils.help()

# COMMAND ----------

display(dbutils.fs.ls("/databricks-datasets"))

# COMMAND ----------

