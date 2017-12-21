# Make plot in Python and R with same data in ggplot style

# set working directory
import os
# os.chdir("C:/Users/M/Desktop/q_sigma_lambda/arxiv_paper/plotting")

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.transforms
import numpy as np
from sklearn import datasets

# style of plots ggplot, but with white background defined in file ggplot_white.mplstyle
theme_bw = "C:/Users/M/Desktop/q_sigma_lambda/ggplot_white.mplstyle"
# plt.style.use('ggplot')
plt.style.use(theme_bw)

# load data from simulation on cliff walking gridworld in long format
# df = np.load("data_long.npy")

# the famous iris data
iris = datasets.load_iris()
# convert to pandas data frame and rename columns
df = pd.DataFrame(data = np.c_[iris['data'], iris['target']],
                     columns = iris['feature_names'] + ['target'])
df.rename(columns = {'sepal length (cm)': 'sepal_length',
                     'sepal width (cm)': 'sepal_width',
                     "petal length (cm)": "petal_length",
                     "petal width (cm)": "petal_width",
                     "target": "species"}, inplace=True)

# bbox = matplotlib.transforms.Bbox([[-0.2, -0.36], [3.45, 2.56]])
fig = plt.figure(figsize = (9, 7.2), dpi = 50) # 12, 9.6
ax = plt.subplot(111)
fig.subplots_adjust(top=0.8,
                    bottom=0.1,
                    left=0.1,
                    right=0.9)
# specify colors
col = ["#E24A33", "#FBC15E", "#348ABD"]
species = ["setosa", "versicolor", "virginica"]
# plot for each species
for i in np.unique(df["species"]):
    ax.plot(df[df["species"] == i]["sepal_length"],
            df[df["species"] == i]["sepal_width"], "o", markersize = 8,
            c = col[int(i)], label = species[int(i)])
plt.ylabel("Sepal Width")
plt.xlabel("Sepal Length")
plt.title("Iris", loc = "left")
box = ax.get_position()
ax.set_position([box.x0, box.y0, box.width * 0.75, box.height])
ax.legend(bbox_to_anchor=(1, 0.6), title = "Species", labelspacing=1.5)
plt.xticks(np.arange(5, max(df.sepal_length) + 1, 1.0))
plt.savefig("iris_matplotlib.png", format = "png", dpi = 150, bbox_inches = "tight")
plt.show()


import matplotlib.pyplot as plt
import numpy as np
import matplotlib.transforms
bbox = matplotlib.transforms.Bbox([[-0.2, -0.36], [3.45, 2.56]])
fig = plt.figure(figsize = (3, 2.4), dpi = 150)
ax = plt.subplot(111)

for i in range(3):
    ax.plot(np.random.random(10), np.random.random(10), "o", label = i)
ax.legend(bbox_to_anchor=(1, 0.6), title = "Title")
plt.ylabel("Label")
plt.xlabel("Label")
plt.title("Title", loc = "left")
plt.savefig("test.png", format = "png", dpi = 150, bbox_inches = bbox)
