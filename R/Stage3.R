# Install Packages
list.of.packages <- c("data.table"
                      ,"httr"
                      ,"jsonlite"
                      ,"digest"
                      ,"Hmisc"
                      ,"RJSONIO"
                      ,"RSQLite"
                      ,"ggplot2"
                      ,"caret"
                      ,"Rtsne"
                      ,"ggcorrplot"
                      ,"keras"
)
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, dependencies = T)

# Load Packages
library(data.table)
library(jsonlite)
library(httr)
library(curl)
library(digest)
library(Hmisc)
library(RJSONIO)
library(RSQLite)
library(ggplot2)
library(caret)
library(Rtsne)
library(ggcorrplot)
library(keras)
install_keras()

## Step 1: Load the cleaned dataset
customerDT <- fread("Data/cleanedData.csv")

## Step 2: Clustering Analysis

# Initialize total within sum of squares error: wss
wss <- 0

# For 1 to 15 cluster centers
for (i in 1:15) {
  km.out <- kmeans(scale(customerDT[,2:43]), centers = i,nstart = 2, iter.max = 20)
  # Save total within sum of squares to wss variable
  wss[i] <- km.out$tot.withinss
}

# Plot total within sum of squares vs. number of clusters
plot(1:15, wss, type = "b", 
     xlab = "Number of Clusters", 
     ylab = "Within groups sum of squares")


# Clustering using all the dimensions
clusters <- kmeans(scale(customerDT[,2:43]), 25)
clusters

# Customers who prefer female merchandise over male/unisex merchandise
customerDT[female_items > male_items + unisex_items, .N/nrow(customerDT)*100]

## Rtsne function may take some minutes to complete...
set.seed(131)  
tsne_model_1 = Rtsne(as.matrix(customerDT[,2:43]), check_duplicates=FALSE, pca=TRUE, perplexity=30, theta=0.5, dims=2)

## getting the two dimension matrix
d_tsne_1 = as.data.frame(tsne_model_1$Y) 

setDT(d_tsne_1)

ggplot(d_tsne_1, aes(x=V1, y=V2)) +  
  geom_point(size=0.25) +
  guides(colour=guide_legend(override.aes=list(size=6))) +
  xlab("") + ylab("") +
  ggtitle("t-SNE") +
  theme_light(base_size=20) +
  theme(axis.text.x=element_blank(),
        axis.text.y=element_blank()) +
  scale_colour_brewer(palette = "Set2")

## keeping original data
d_tsne_1_original=d_tsne_1

# Initialize total within sum of squares error: wss
wss <- 0
# For 1 to 15 cluster centers
for (i in 1:15) {
  km.out <- kmeans(scale(d_tsne_1), centers = i,nstart = 2, iter.max = 20)
  # Save total within sum of squares to wss variable
  wss[i] <- km.out$tot.withinss
}
# Plot total within sum of squares vs. number of clusters
plot(1:15, wss, type = "b", 
     xlab = "Number of Clusters", 
     ylab = "Within groups sum of squares")

## Creating k-means clustering model, and assigning the result to the data used to create the tsne
fit_cluster_kmeans=kmeans(scale(d_tsne_1), 3)  
d_tsne_1_original$cl_kmeans = factor(fit_cluster_kmeans$cluster)

ggplot(d_tsne_1_original, aes_string(x="V1", y="V2", color="cl_kmeans")) +
  geom_point(size=0.25) +
  guides(colour=guide_legend(override.aes=list(size=6))) +
  xlab("") + ylab("") +
  ggtitle("") +
  theme_light(base_size=20) +
  theme(axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        legend.direction = "horizontal", 
        legend.position = "bottom",
        legend.box = "horizontal") + 
  scale_colour_brewer(palette = "Accent") 

# Customers who buy more female merchandise are inferred as females
customerDT[female_items > male_items + unisex_items, inf_gender := 1]
# Customers who buy more male merchandise are inferred as males
customerDT[male_items > female_items + unisex_items, inf_gender := 0]
# Customers who buy more female/unisex merchandise are inferred as females
customerDT[is.na(inf_gender) & male_items == 0 & female_items >= unisex_items, inf_gender:= 1]
# Customers who buy more male/unisex merchandise are inferred as males
customerDT[is.na(inf_gender) & female_items == 0 & male_items >= unisex_items, inf_gender:= 0]
customerDT[is.na(inf_gender) & (female_items > male_items), inf_gender:= 1]
customerDT[is.na(inf_gender) & (male_items > female_items), inf_gender:= 0]
# For remaining customer, we assume that customer who used discounts or pay later options are females, otherwise we assume them as males
customerDT[is.na(inf_gender) & (average_discount_used > 0 | afterpay_payments >0), inf_gender:= 1]
customerDT[is.na(inf_gender) & !(average_discount_used > 0 | afterpay_payments >0), inf_gender:= 0]

set.seed(131)

# Determine sample size
ind <- sample(2, nrow(customerDT), replace=TRUE, prob=c(0.67, 0.33))

# Split the data
customerDT.train <- customerDT[ind==1, 2:43]
customerDT.test <- customerDT[ind==2, 2:43]
customerDT.train <- normalize(as.matrix(customerDT.train))
customerDT.test <- normalize(as.matrix(customerDT.test))

# Split the class attribute
customerDT.traintarget <- as.matrix(customerDT[ind==1, 44])
customerDT.testtarget <- as.matrix(customerDT[ind==2, 44])

# Initialize a sequential model
model <- keras_model_sequential()

# Add layers to the model
model %>% 
  layer_dense(units = 20, activation = 'relu', input_shape = c(42)) %>% 
  layer_dropout(rate = 0.5) %>% 
  layer_dense(units = 20, activation = 'relu') %>% 
  layer_dropout(rate = 0.4) %>% 
  layer_dense(units = 10, activation = 'relu') %>% 
  layer_dropout(rate = 0.3) %>% 
  layer_dense(units = 1, activation = 'sigmoid')

# Define an optimizer
rmsprop <- optimizer_rmsprop(lr = 0.001)

# Compile the model
model %>% compile(
  loss = 'binary_crossentropy',
  optimizer = rmsprop,
  metrics= 'accuracy'
)

# Fit the model 
history <- model %>% fit(
  customerDT.train, 
  customerDT.traintarget, 
  epochs = 200, 
  batch_size = 128, 
  validation_split = 0.2
)

plot(history)

# Predict the classes for the test data
classes <- model %>% predict_classes(customerDT.test)

# Confusion matrix
table(customerDT.testtarget, classes)

model %>% evaluate(customerDT.test, customerDT.testtarget)
