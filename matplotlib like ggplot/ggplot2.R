# scatterplot iris data
library(ggplot2)

# scaleFUN <- function(x) sprintf("%.1f", x)

cols <- c("setosa" = "#E24A33", "virginica" = "#348ABD", "versicolor" = "#FBC15E")
g <- ggplot(data = iris, aes(x = Sepal.Length, y = Sepal.Width, col = factor(Species))) +
  geom_point(size = 3) +
  theme_bw() +
  theme(panel.grid.minor = element_blank()) +
  xlab("Sepal Length") +
  ylab("Sepal Width") +
  ggtitle("Iris") +
  scale_colour_manual(values = cols) +
  guides(col = guide_legend(title = "Species")) +
  theme(legend.title.align = 0.5,
    legend.background = element_rect(colour = 'lightgrey', linetype = 'solid'))

g
# scale_x_continuous(labels = scaleFUN) +
# , breaks = round(seq(min(iris$Sepal.Length), max(iris$Sepal.Width), by = 0.5)))

# save plot as png
ggsave("iris_r.png", g, device = "png", width = 15, height = 12, units = "cm")

# # load python data into R
# library(RcppCNPy)
#
# data = npyLoad("data_long.npy")
