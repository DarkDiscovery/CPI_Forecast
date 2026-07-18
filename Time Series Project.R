library(dplyr)
library(tseries)
library(forecast)

# Loading the Data set and making formatting edits.

CPI_Data = read.csv("CPI - Rural, Urban, Combined.csv")
CPI_Data = CPI_Data[-1,]
colnames(CPI_Data)= c("Month", "Commodity", "Status", "Rural_Index", "Rural_Inflation", "Urban_Index", "Urban_Inflation", "Combined_Index", "Combined_Inflation")


# filtering the CPI data to use only the general index and final values
filt_cpi = filter(CPI_Data, CPI_Data$Commodity=="A) General Index" & CPI_Data$Status=="Final" )
chrono_cpi= filt_cpi[rev(1:nrow(filt_cpi)), ]
cpi_values = as.numeric(chrono_cpi$Combined_Index)
length(cpi_values)

#Converting the Cleaned data into time series
cpi_ts <- ts(cpi_values, start = c(2013, 1), frequency = 12)
cpi_ts
head(cpi_ts)
plot(cpi_ts, main="All India CPI Index", col="darkblue", lwd=2, ylab = "Index Values")

# Stationarity Analysis
par(mfrow = c(1,2))

acf(cpi_ts, lag.max = 36, main = "ACF for CPI")

pacf(cpi_ts, lag.max = 36, main = "PACF for CPI")

par(mfrow = c(1, 1))
# The ACF decays very slowly, the series is not stationary
# Since there is a very significant visual spike in the PACF at lag one, may be random walk


## Transformations to achieve Stationarity

#Approach 1: Yearly Lag

diff_cpi <- diff(cpi_ts, lag = 12)

plot(diff_cpi, main="YoY Seasonal Differenced CPI", col="red", lwd=2)

par(mfrow = c(1, 2))
acf(diff_cpi, lag.max = 36, main = "ACF (Year Differenced)")
pacf(diff_cpi, lag.max = 36, main = "PACF (Year Differenced)")
par(mfrow = c(1, 1))

# there are still signs of non Stationarity

# Approach 2: Log Transformation

log_cpi = log(cpi_ts)

plot(log_cpi, main="Log CPI", col="red", lwd=2)

par(mfrow = c(1, 2))
acf(log_cpi, lag.max = 36, main = "ACF (Log CPI)")
pacf(log_cpi, lag.max = 36, main = "PACF (Log CPI)")
par(mfrow = c(1, 1))

# Still A clear trend, Differencing is necessary

#Approach 3: Monthly Differencing

diff_cpi_m = diff(cpi_ts, lag = 1)

plot(diff_cpi_m, main="Monthly Differenced CPI", col="red", lwd=2)

par(mfrow = c(1, 2))
acf(diff_cpi_m, lag.max = 36, main = "ACF (Month Differenced)")
pacf(diff_cpi_m, lag.max = 36, main = "PACF (Month Differenced)")
par(mfrow = c(1, 1))

# Still not stationary, this has introduced very clear seasonality.


#Approch 4: log transformation and differencing (yearly), to remove seasonality as well

diff_log_cpi <- diff(log(cpi_ts), lag = 12)


plot(diff_log_cpi, main="YoY Seasonal Differenced Log CPI", col="red", lwd=2)


par(mfrow = c(1, 2))
acf(diff_log_cpi, lag.max = 36, main = "ACF (Log Diff)")
pacf(diff_log_cpi, lag.max = 36, main = "PACF (Log Diff)")
par(mfrow = c(1, 1))

# Approach 5: difference both at lag 1 and then at lag 12(Both Monthly and Yearly)

app_5_cpi <- diff(diff(log(cpi_ts), lag = 1), lag = 12)

plot(app_5_cpi, main="Twice-Differenced Log CPI (d=1, D=1)", col="darkblue", lwd=2)

par(mfrow = c(1, 2))
acf(app_5_cpi, lag.max = 36, main = "ACF (Twice-Difference)")
pacf(app_5_cpi, lag.max = 36, main = "PACF (Twice-Difference)")
par(mfrow = c(1, 1))

# this looks stationary now, though the spike at lag 1 is suspicious

#Formally Checking Stationarity using ADF test.


adf_result = adf.test(app_5_cpi)

adf_result$p.value
print(adf_result)
# reject the null hypothesis of non Stationarity
# the Process is now stationary


# Fitting a time series model using auto arima


final_cpi_model<- auto.arima(log(cpi_ts), d = 1, D = 1, stepwise = FALSE, approximation = FALSE)


summary(final_cpi_model)

#Residual Analysis

checkresiduals(final_cpi_model)
Box.test(residuals(final_cpi_model),lag = 36,fitdf = 4,type = "Ljung-Box")
#p-value = 0.9095

# We Fail to reject the null Hypothesis that the error terms follow white noise


#Plotting the series and predictions

cpi_forecast = forecast(final_cpi_model, h = 12, level = 95)

plot(cpi_forecast, main = "12-Month Ahead CPI Forecast(log scale)", col = "blue", lwd = 2)

cpi_forecast

# Plot to focus on the latest data and the predicted values
plot(cpi_forecast, main = "12-Month Ahead CPI Forecast (Log Scale)", xlab = "Year", ylab = "Log CPI", col = "blue", lwd = 2, xlim = c(2024, 2027))

