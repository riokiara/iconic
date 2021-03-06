Iconic Data Science Challenge
================

Executive Summary
-----------------

The ICONIC has a rich data about their shoppers including their website visits, purchases and behavioural data. There exists an opportunity to understand that data and extract meaningful insights about customers' preferences on purchasing the merchandise.

The project focusses on extracting the customers' preferred category of gender while purchasing the merchandise. This doesn't necessary imply that ICONIC is trying to infer customers' gender rather they are interested in shoppers' preference of merchandise. A customer may be shopping for themselves or for their partner/family/friends. So, we really can't infer the customers' gender but only their preferred gender category.

Since we don't have factual data about customers' gender or explicity specified preferred gender category, an unsupervised machine learning approach was tried to infer the preferred gender category. However, the results weren't convincing enough to recommend that model/approach.

Alternative approach was tried where merchandise gender category of the purchased products was used to generate a gender label for each customer. Customers' behaviours around discount usage and payment methods was also taken into consideration to generate the gender label. This new information was then used to teach a supervised machine learning model, whose accuracy was tested out to be 92%. This implies that the trained model is successfully able to predict 9 out of 10 customers' preferred gender correctly. However, the machine learning model is as good as the data we have. We would need a highly accurate labelled dataset to re-train the machine learning model to be able to effectively reap the benefits of machine learning model.

Project Objectives
------------------

Customers at THE ICONIC provide the bare minimum of information needed when signing up as a new user or simply purchase their items as a ‘Guest’ user. They do not provide their age, gender or any other personal details when they register as a new customer.

THE ICONIC want to better understand their customers without voilating their privacy. The key objectives of understanding the shoppers' profile is to be able to better tailor the ICONIC website, branding strategy, marketing, product and most importantly merchandising.

Project Methodology
-------------------

The project utilised CRISP-DM methodology as a structured approach for planning. It followed the usual data mining project steps of understanding the business, it's data, exploring the data, preparing the data for modelling, the modelling phase and evaluation phase.

### Business and Data Understanding

The stage 1 (SQL Analysis) helped in the business understanding and how the business utilizes its data to make business decisions. It also helped in the data understanding and how to deal with different data sources as the Stage 2 presented with a different challenge of handling data from another source (JSON file as opposed to a database file in Stage 1). Approach used in the stage 2 was ELT (Extract, Load and Transform) to bring the data in a shape ready for data exploration. Stage 1 just required Extract & Connect and data was ready in a structured format for doing the SQL analysis. The detailed steps of stage 1 are listed here [Stage 1 Analysis](Stage1.md)

### Data Exploration and Preparation

Stage 2 required additional transformation step of converting the JSON format to a R data table format for easy exploration. The exploration included missing values analysis, duplicates analysis, anomaly detection and outlier analysis. Some anomalies were treated, duplicates were removed and missing attributes imputed, while other issues were left untreated because of lack of business understanding around the usage of those attributes. The cleaned dataset was then saved as a base for next stage analysis. The detailed steps of stage 2 are listed here [Stage 2 Analysis](Stage2.md)

### Modelling and Evaluation

The project utilises machine learning algorithms to predict the inferred/preferred gender category for each customer. Since we do not have labelled data, the first approach was to use unsupervised learning model. Clustering is a widely used approach to classify observations into clusters. K-means algorithm was used to identify clusters based on gender information. An attempt was made to identify the optimal number of clusters that can be used in k-mean algorithm but the statistics did not indicate an ideal number. However, since we are expecting atleast two clusters, an effort was made to cluster the data in 3 different groups of female, male and unisex category. The clusters that were formed very not really suggestive of gender categorization.

Second attempt was to reduce the dimensions of the data first and then tackle the clustering. For that, t-SNE algorithm was used to extract 2 features that explain most of the variation in the data. Those 2 features were then used to re-run K-means clustering. Again, the statistics of k-means clusters were not indicative of the gender categories.

Since unsupervised learning was not successful, a new feature was generated which was used as a target variable for supervised learning. This was done as proof of concept assuming ICONIC would have access to actual gender information about a subset of its customers and can be used to train a supervised model. The new feature called as the inferred/preferred gender was generated based on the customers' purchases of merchandise gender category. A simple rule based on number of male or female items purchased was implemented to classify the customers into male or female. A subset of customer which did not follow that rule were checked for the discount usage. It is assumed that female customer tends to purchase discounted items more than men. Another assumption was that females are better at managing credit cards, hence all the customer who have utilized afterpay options are females. Another rule that was not implemented was based on credit card customers. In Australia, there are more male credit card holders than female. But other assumption superseded this assumption and hence was not implemented.

A deep learning algorithm was compiled and fitted on all the features (no exlusions). The model evaluated to be 92% accurate on the hold-out dataset. Just re-iterating, the model is as good as the data. The gender label that was engineered was based on certain assumptions and if those are incorrect, then the model accuracy is baseless. The detailed steps of stage 3 are listed here [Stage 3 Analysis](Stage3.md)

Call to Action
--------------

The classification model presents a good fit for the labelled data. If we can source highly accurate gender labels for a considerably large dataset, we can then use it to train a deep learning model which then can be used as a gender classifier. For that to happen and make the process more robust, we could look at the following additional data sources for gender prediction:
1. Customers who provide their gender information during sign-up 
2. Name of the customers can be fed to a separate machine learning model which can pretty accurately classify the gender of the customer 
3. Similar classification algorith can be run on the customers' email addresses 
4. Website visits data which may not be just limited to purchases, but also have information on viewed items 
5. Items that are in customers' whishlist
