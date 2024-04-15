USE cryptopunk;

-- Q1 How many sales occurred during this time period?
SELECT COUNT(*) AS total_sales
FROM pricedata;

-- Q2 Return the top 5 most expensive transactions (by USD price) for this data set. Return the name, ETH price, and USD price, as well as the date.
SELECT name, eth_price, usd_price, event_date FROM pricedata 
ORDER BY usd_price DESC LIMIT 5;

-- Q3 Return a table with a row for each transaction with an event column, a USD price column, and a moving average of USD price that averages the last 50 transactions.
SELECT token_id AS transaction, event_date AS event, usd_price AS 'USD price' , AVG(usd_price) 
OVER (ORDER BY event_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS moving_average
FROM pricedata 
ORDER BY event_date;

-- Q4 Return all the NFT names and their average sale price in USD. Sort descending. Name the average column as average_price.
SELECT
	name,
    AVG(usd_price) AS average_price
FROM pricedata
GROUP BY name
ORDER BY average_price DESC;

-- Q5 Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. Order by the count of transactions in ascending order.
SELECT 
	DAYNAME(event_date) AS day_of_week,
    AVG(eth_price) AS avg_price_in_eth,
    COUNT(token_id) AS transaction_count
FROM pricedata
GROUP BY day_of_week
ORDER BY transaction_count ASC;

-- Q6 Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.
SELECT 
	CONCAT(name, ' was sold for $ ', round(usd_price, 3), ' to ', buyer_address , ' from ', seller_address, ' on ', event_date) 
    AS Summary
FROM pricedata;

-- Q7 Create a view called “1919_purchases” and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.
CREATE VIEW 1919_purchases AS 
	SELECT * FROM pricedata WHERE buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';
SELECT * FROM 1919_purchases; -- Display the above view

-- Q8 Create a histogram of ETH price ranges. Round to the nearest hundred value. 
SELECT ROUND(eth_price, -2) AS bucket,
	COUNT(*) AS count,
    RPAD('', COUNT(*), '*') AS bar
FROM pricedata
	GROUP BY bucket
    ORDER BY bucket;
    
-- Q9 Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying “highest” with a query that has the lowest price each NFT was bought for and the status column saying “lowest”. The table should have a name column, a price column called price, and a status column. Order the result set by the name of the NFT, and the status, in ascending order. 
SELECT 
	name, MAX(usd_price) AS price,
    'highest' AS status
FROM pricedata
GROUP BY name

UNION

SELECT 
	name, MIN(usd_price) AS price,
    'lowest' AS STATUS
FROM pricedata
GROUP BY name
ORDER BY name ASC, status ASC;

-- Q10 What NFT sold the most each month / year combination? Also, what was the name and the price in USD? Order in chronological format. 
SELECT 
	EXTRACT(YEAR_MONTH FROM event_date) AS year_month_, 
	name,
    MAX(usd_price) AS highest_price
FROM pricedata
GROUP BY year_month_, name
ORDER BY year_month_, highest_price DESC;

-- Q11 Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).
SELECT DATE_FORMAT(event_date, '%Y-%m') AS month_year,
	ROUND(SUM(usd_price), 2) AS total_volume
FROM pricedata
GROUP BY month_year
ORDER BY month_year;

-- Q12 Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.
SELECT COUNT(*) AS transaction_count
FROM pricedata 
WHERE buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' OR seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

-- Q13 Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
 -- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 -- Take the daily average of remaining transactions
	-- a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function. Save it as a temporary table.
CREATE TEMPORARY TABLE temp_1 AS
	SELECT event_date, AVG(usd_price) OVER(PARTITION BY event_date) AS avg_usd_price
    FROM pricedata;
	-- b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value which is just the daily average of the filtered data.
SELECT pricedata.*, temp_1.avg_usd_price  FROM pricedata 
	LEFT JOIN temp_1 ON temp_1.event_date = pricedata.event_date
	WHERE pricedata.usd_price > temp_1.avg_usd_price * 0.1;
    
-- Q14 Consider a dataset named pricedata containing records of transactions with seller and buyer addresses along with the corresponding USD prices. Use the provided SQL query to analyze the profitability of transactions between sellers and buyers.
CREATE TEMPORARY TABLE temp_selling_price AS
	SELECT 
		seller_address,
        SUM(usd_price) AS total_selling_price
	FROM pricedata
    WHERE seller_address IS NOT NULL
    GROUP BY seller_address;
    
CREATE TEMPORARY TABLE temp_buying_price AS
	SELECT
		buyer_address,
        SUM(usd_price) AS total_buying_price
	FROM pricedata
    WHERE buyer_address IS NOT NULL
    GROUP BY buyer_address;

SELECT
	temp_seller.seller_address AS seller_address,
    temp_buyer.buyer_address AS buyer_address,
		CASE
        WHEN
        (temp_seller.total_selling_price - temp_buyer.total_buying_price) > 0 
			THEN 'Profit'
            ELSE 'Loss'
				END AS profit_or_loss
FROM temp_selling_price temp_seller
	LEFT JOIN temp_buying_price temp_buyer
    ON temp_seller.seller_address = temp_buyer.buyer_address;