library(h2o)
cc <- read_csv("CC GENERAL.csv")
vq <-c('BALANCE','CREDIT_LIMIT','PURCHASES','PURCHASES_TRX','ONEOFF_PURCHASES',
       'INSTALLMENTS_PURCHASES','CASH_ADVANCE', 'CASH_ADVANCE_TRX')

# Duplicates
sum(duplicated(cc$CUST_ID))


# Distribution 
for (i in vq) { 
  hist(cc[,i], col='grey75', border='grey65', 
       xlab = paste(i, 'NA count:', sum(is.na(cc[,i]))),
       main = paste(gsub('_', ' ', i), 'Median:', round(median(cc[,i], na.rm=T),1))) 
}

# Forget NAs 
cc <- cc[is.na(cc$CREDIT_LIMIT)==F,]
cc <- cc[is.na(cc$MINIMUM_PAYMENTS)==F,]

# Use h2o object 
h2o.init()
df  <- as.h2o(cc[,vq])

# Build Isolation Tree 
it  <- h2o.isolationForest(training_frame = df,
                           sample_rate = 0.1,
                           max_depth = 20,
                           ntrees = 1000)
it

# Keep prediction and mean length and add to original df
pred   <- h2o.predict(it, df)
cc_df <- cbind(cc,as.data.frame(pred))

# Distribution of mean length and predicted values:
hist(cc_df$mean_length, col='grey75', border='grey65', main = 'iTree mean split length', xlab = 'Mean Split Length') 
hist(cc_df$predict,     col='grey75', border='grey65', main = 'iTree predicted values', xlab = 'Predicted')
abline(v = 0.85, col='orange', lwd=3, lty=3)

# <4% fall in this group 
prop.table(table(cc_df$predict>0.85))
CC_GENERAL <- read_csv("CC GENERAL.csv")
table(cc_df$predict>0.85)

# Scatterpots
# some more vars to plot (log) and remove the freq vars, all into vq2
cc_df$LOG_PAYMENTS <- log(cc_df$PAYMENTS)
cc_df$LOG_MINIMUM_PAYMENTS <- log(cc_df$MINIMUM_PAYMENTS)
vq2 <- c(vq,'LOG_PAYMENTS','LOG_MINIMUM_PAYMENTS')


for (i in vq2) { 
  plot(cc_df[,i], cc_df[, 'predict'], col='grey75', main=paste('iTree prediction vs', tolower(i)), 
       xlab = paste(i, 'Corr =', round(cor(cc_df[,i], cc_df[, 'predict']),2)), ylab='Predicted' ) 
  abline(h = 0.85, col='orange', lwd=3, lty=3) 
}
