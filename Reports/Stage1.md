Iconic Challenge - Stage 1
================

Step 1: Download the password protected compressed database file
----------------------------------------------------------------

Download from the git repository  

``` r
wd <- getwd()
filep <- "https://github.com/theiconic/datascientist/raw/master/test_data.db.zip"
filename <- "../Data/test_data.db.zip"
download.file(url=filep, destfile=filename)
```

Step 2: Hashed Password
-----------------------

The password can be managed in a better way. Example: store it in a config file or credential store  

``` r
filepwd <- digest(object = 'welcometotheiconic', algo = 'sha256', serialize = FALSE)
```

Step 3: Extact zip file.
------------------------

Note: This requires an installation of 7zip (Third Party Software)  

``` r
sys_command <- paste0("7z ", "x ", filename, " -p", filepwd, " -o../Data -aoa")
system(sys_command, intern = F)
```

Step 4: Connect to database
---------------------------

Connect to the extracted database file  

``` r
db_file <- "../Data/test_data.db"

# Connecting to the database file
sqlite.driver <- dbDriver("SQLite")
db <- dbConnect(sqlite.driver,
                dbname = db_file)
```

Step 5: SQL Analysis
--------------------

### 1. What was the total revenue to the nearest dollar for customers who have paid by credit card?

Total credit card revenue  
Assumption 1: If there is a cancellation, the revenue includes the refund  
Assumption 2: We don't have revenue split by credit card and non credit card, so the entire revenue is considered for calculating total revenue even if a single order was fulfilled using a credit card  

``` r
query1 <- "SELECT round(sum(revenue) ) AS total_cc_revenue
              FROM customers
            WHERE cc_payments = 1 AND 
            orders > 0;"

res <- dbSendQuery(db, query1)
# Revenue rounded to the nearest dollar
output <- dbFetch(res)
output
```

    ##   total_cc_revenue
    ## 1         50372282

``` r
# -- 50,372,282
dbClearResult(res)
```

### 2. What percentage of customers who have purchased female items have paid by credit card?

Proportion of female customers who paid using a credit card  
Assumption 1: Female items includes any orders flagged as female items or women apparel/footwears/accessories/sports/curvy items  
Assumption 2: For any order cancellations, the number of items have already been adjusted accordingly  

``` r
query2 <- "SELECT round( (COUNT(DISTINCT customer_id) * 100.0) / (
              SELECT COUNT(DISTINCT customer_id) 
              FROM customers
            ), 2) AS prop_female_cc_customers
            FROM customers
            WHERE cc_payments = 1 AND 
            orders > 0 AND 
            (female_items > 0 OR 
              wapp_items > 0 OR 
              wftw_items > 0 OR 
              wacc_items > 0 OR 
              wspt_items > 0 OR 
              curvy_items > 0);"

res <- dbSendQuery(db, query2)
# Proportion of female customers who used credit card
output <- dbFetch(res)
output
```

    ##   prop_female_cc_customers
    ## 1                    50.16

``` r
# -- 50.16
dbClearResult(res)
```

### 3. What was the average revenue for customers who used either iOS, Android or Desktop?

Assumption 1: We don't have revenue split by desktop and mobile and other channels of orders, so the entire revenue is considered for calculating average even if majority of orders were from mobile site and a single order exists for desktop or ios or android  
Assumption 2: If there is a cancellation, the revenue includes the refunds  

``` r
query3 <- "SELECT round(avg(revenue), 2) AS avg_revenue_desktop_ios_android
            FROM customers
            WHERE orders > 0 AND 
            (desktop_orders > 0 OR 
            android_orders > 0 OR 
            ios_orders > 0);"

res <- dbSendQuery(db, query3)
# Average revenue for customers who used either iOS, Android or Desktop (round to two decimals)
output <- dbFetch(res)
output
```

    ##   avg_revenue_desktop_ios_android
    ## 1                         1484.89

``` r
# -- 1484.89
dbClearResult(res)
```

### 4. We want to run an email campaign promoting a new mens luxury brand. Can you provide a list of customers we should send to?

Assumption 1: All the customers who have subscribed to newletter, have also provided consent for marketing emails  
Assumption 2: All the customers who have subscribed to newletter, have an active email account attached to the customer record  
Assumption 3: Since the cost involved in email campaign is low, recommendation is send email to all the customers who have an email account and provided consent to contact for marketing purpose  

``` r
query4 <- "SELECT DISTINCT customer_id
            FROM customers
            WHERE is_newsletter_subscriber = 'Y';"

res <- dbSendQuery(db, query4)
output <- dbFetch(res)
# Printing top 5 customers
head(output, 5)
```

    ##                        customer_id
    ## 1 fa7c64efd5c037ff2abcce571f9c1712
    ## 2 18923c9361f27583d2320951435e4888
    ## 3 aa21f31def4edbdcead818afcdfc4d32
    ## 4 668c6aac52ff54d4828ad379cdb38e7d
    ## 5 111d48b932dae281aff64cae2f17c4d6

``` r
# -- 18,827 Customers
dbClearResult(res)
```

#### 4a Alternate Campaign: Target all male customers, who have subscribed to newsletter

Assumption: There is cost involved in sending out campaign to entire customer base and to reduce cost, target only a certain segment of customers  

``` r
query5 <- "SELECT DISTINCT customer_id 
            FROM customers
            WHERE orders > 0 AND 
            is_newsletter_subscriber = 'Y' AND 
            (male_items > 0 OR 
              unisex_items > 0 OR 
              mapp_items > 0 OR 
              mftw_items > 0 OR 
              macc_items > 0 OR 
              mspt_items > 0);"


res <- dbSendQuery(db, query5)
output <- dbFetch(res)
# Printing top 5 customers
head(output, 5)
```

    ##                        customer_id
    ## 1 fa7c64efd5c037ff2abcce571f9c1712
    ## 2 18923c9361f27583d2320951435e4888
    ## 3 aa21f31def4edbdcead818afcdfc4d32
    ## 4 040fb9742f9e14cf69c7a748bdf20137
    ## 5 9f3e6357fdcd178344772cff6d720cee

``` r
# -- 12,150 Customers
dbClearResult(res)
```

#### 4b Alternate Campaign: Target all male customers, who have subscribed to newsletter and spend more than an average male customer

Assumption: There is cost involved in sending out campaign to entire customer base and to reduce cost, target only a certain segment of customers  

``` r
query6 <- "SELECT DISTINCT customer_id
            FROM customers
            WHERE orders > 0 AND 
            is_newsletter_subscriber = 'Y' AND 
            (male_items > 0 OR 
              unisex_items > 0 OR 
              mapp_items > 0 OR 
              mftw_items > 0 OR 
              macc_items > 0 OR 
              mspt_items > 0) AND 
            revenue > (
              SELECT avg(revenue) 
              FROM customers
              WHERE orders > 0 AND 
              is_newsletter_subscriber = 'Y' AND 
              (male_items > 0 OR 
                unisex_items > 0 OR 
                mapp_items > 0 OR 
                mftw_items > 0 OR 
                macc_items > 0 OR 
                mspt_items > 0) 
            );"

res <- dbSendQuery(db, query6)
output <- dbFetch(res)
# Printing top 5 customers
head(output, 5)
```

    ##                        customer_id
    ## 1 fa7c64efd5c037ff2abcce571f9c1712
    ## 2 18923c9361f27583d2320951435e4888
    ## 3 040fb9742f9e14cf69c7a748bdf20137
    ## 4 9f3e6357fdcd178344772cff6d720cee
    ## 5 d439bd758fd2f20aca559a60a53a3b69

``` r
# -- 2,689 Customers
dbClearResult(res)
dbDisconnect(db)
```

We can further narrow down the list using active customers (using days since last order) or their shopping behaviour of cancelling/returning orders and even offer discounts based on their discount usage.  

[Stage 2](Stage2.md)
