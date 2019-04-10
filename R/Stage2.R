# Install Packages
list.of.packages <- c("data.table"
                      ,"httr"
                      ,"jsonlite"
                      ,"digest"
                      ,"Hmisc"
                      ,"RJSONIO"
                      ,"RSQLite"
                      ,"ggplot2"
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

## Step 1: Download the password protected compressed json file
filep <- "https://github.com/theiconic/datascientist/raw/master/test_data.zip"
filename <- "../Data/test_data.zip"
download.file(url=filep, destfile=filename)

## Step 2: Hashed Password
filepwd <- digest(object = 'welcometotheiconic', algo = 'sha256', serialize = FALSE)

## Step 3:  Extact zip file.
sys_command <- paste0("7z ", "x ", filename, " -p", filepwd, " -o../Data -aoa")
system(sys_command, intern = F)

## Step 4:  Load JSON file.
jsonfile <- "../Data/data.json"
fjson <- read_json(jsonfile)

## Step 5:  Convert JSON to R data.table
customerDT <- rbindlist(fjson, fill = T)

#Summarize data table
summary(customerDT)

## Step 6:  Finding anomalies in the data
#Unique customers
customerDT[,uniqueN(customer_id)]
#check duplicate customers
customerDT[customer_id %in%head(customerDT[duplicated(customer_id) == T,customer_id],5)][order(customer_id)]
#Remove complete duplicates
customerDT <- unique(customerDT)
#Check again for duplicate customer ids
customerDT[duplicated(customer_id) == T,customer_id]

#Check days since last order and first order
customerDT[days_since_last_order > days_since_first_order, .N*100/nrow(customerDT)]

#Fix issue with days since last order and first order
customerDT[days_since_last_order > days_since_first_order, c('days_since_last_order', 'days_since_first_order'):=.(days_since_first_order,days_since_last_order)]

# More cancellations than orders per customer
customerDT[cancels > orders, .N*100/nrow(customerDT)]

# More returns than orders per customer
customerDT[returns > orders, .N*100/nrow(customerDT)]

# No revenue generating customers
customerDT[(revenue + redpen_discount_used + coupon_discount_applied + average_discount_used) <= 0 & (orders-cancels-returns > 0), .N*100/nrow(customerDT)]

# Outlier Analysis on customer orders
qplot(y=customerDT$orders, x= 1, geom = "boxplot")+
labs(x = "Customers", y = "Number of Orders") +
labs(title="Box Plot of Customer Orders", size = 15) +
theme(panel.background = element_blank(), axis.line = element_line(colour = "grey"),  plot.title = element_text(hjust = 0.5))

# Extracting the orders in the upper whisker of the box plot
customerDT[orders>max(boxplot.stats(customerDT$orders)$stats), list(orders)][order(-orders)]

## Step 7:  Save Cleaned Dataset to a file
# Save cleaned dataset to a file
fwrite(customerDT, "../Data/cleanedData.csv")

