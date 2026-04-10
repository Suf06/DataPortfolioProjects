/* SuperStore Sales Data Project */

/* First we will be cleaning the data before we do any analysis. */

Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Data (Customer_Name, Segement, Ship Mode, Category, Sub_Category)

-- Standardize Text Fields to Upper for Customer_Name
SELECT
    Customer_ID, 
    Customer_Name,
    
    CASE
        -- If the name contains a space (First + Last name)
        -- CHARINDEX returns 0 if no space is found, so we check > 0
        WHEN CHARINDEX(' ', Customer_Name) > 0 THEN
            CONCAT(
                -- First letter of first name
                UPPER(LEFT(Customer_Name, 1)),

                -- Rest of first name
                LOWER(SUBSTRING(Customer_Name, 2, CHARINDEX(' ', Customer_Name) - 2)),
                -- CHARINDEX finds the space between first and last name
                -- Subtracting 2 ensures we only capture characters before the space
                ' ', -- Space between first and last name

                -- First letter of last name
                UPPER(SUBSTRING(Customer_Name, CHARINDEX(' ', Customer_Name) + 1, 1)),

                -- Rest of last name
                LOWER(SUBSTRING(Customer_Name, CHARINDEX(' ', Customer_Name) + 2, LEN(Customer_Name)))
            )

        -- If the name has NO space (single name)
        ELSE
            CONCAT(
                UPPER(LEFT(Customer_Name, 1)), 
                LOWER(SUBSTRING(Customer_Name, 2, LEN(Customer_Name)))
            )
    END AS Capitalized_Names

FROM SuperstoreSalesProject.dbo.samplesuperstore
ORDER BY Customer_ID;

-- Segment standardization
Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

SELECT DISTINCT Segment,
    CASE 
        WHEN Segment IN ('Consumer', 'consumer', 'CONSUMER') THEN 'Consumer'
        WHEN Segment IN ('Corporate', 'corporate', 'CORPORATE') THEN 'Corporate'
        WHEN Segment IN ('Home Office', 'home office', 'HOME OFFICE') THEN 'Home Office'
        ELSE Segment -- If it doesn't match any of the above, keep it as is
    END AS Standardized_Segment
FROM SuperstoreSalesProject.dbo.samplesuperstore;

-- Ship Mode standardization
Select *
from SuperstoreSalesProject.dbo.samplesuperstore;


SELECT DISTINCT Ship_Mode,
    CASE
        WHEN Ship_Mode IN ('First Class', 'first class', 'FIRST CLASS') THEN 'First Class'
        WHEN Ship_Mode IN ('Second Class', 'second class', 'SECOND CLASS') THEN 'Second Class'
        WHEN Ship_Mode IN ('Standard Class', 'standard class', 'STANDARD CLASS') THEN 'Standard Class'
        WHEN Ship_Mode IN ('Same Day', 'same day', 'SAME DAY') THEN 'Same Day'
        ELSE Ship_Mode
    END AS Standardized_Ship_Mode
    FROM SuperstoreSalesProject.dbo.samplesuperstore;

-- Category & Sub_Category standardization
Select DISTINCT Sub_Category
from SuperstoreSalesProject.dbo.samplesuperstore;

SELECT DISTINCT Category,
    CASE
        WHEN Category IN ('Furniture', 'furniture', 'FURNITURE') THEN 'Furniture'
        WHEN Category IN ('Office Supplies', 'office supplies', 'OFFICE SUPPLIES') THEN 'Office Supplies'
        WHEN Category IN ('Technology', 'technology', 'TECHNOLOGY') THEN 'Technology'
        ELSE Category
    END AS Standardized_Category
FROM SuperstoreSalesProject.dbo.samplesuperstore;

SELECT DISTINCT Sub_Category,
    CASE
        WHEN Sub_Category IN ('Bookcases', 'bookcases', 'BOOKCASES') THEN 'Bookcases'
        WHEN Sub_Category IN ('Chairs', 'chairs', 'CHAIRS') THEN 'Chairs'
        WHEN Sub_Category IN ('Furnishings', 'furnishings', 'FURNISHINGS') THEN 'Furnishings'
        WHEN Sub_Category IN ('Fasteners', 'fasteners', 'FASTENERS') THEN 'Fasteners'
        WHEN Sub_Category IN ('Supplies', 'supplies', 'SUPPLIES') THEN 'Supplies'
        WHEN Sub_Category IN ('Paper', 'paper', 'PAPER') THEN 'Paper'
        WHEN Sub_Category IN ('Art', 'art', 'ART') THEN 'Art'
        WHEN Sub_Category IN ('Accessories', 'accessories', 'ACCESSORIES') THEN 'Accessories'
        ELSE Sub_Category
    END AS Standardized_Sub_Category
FROM SuperstoreSalesProject.dbo.samplesuperstore;


--------------------------------------------------------------------------------------------------------------------------

/* Analyze Data */

Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

-- Primary Metriccs: Total Sales, Total Profit, Profit Margin

SELECT Category, CAST(SUM(Sales) AS Decimal(10,2)) AS Total_Sales, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit, CAST((SUM(Profit) / SUM(Sales)) AS Decimal(10,2)) AS Profit_Margin, SUM(Quantity) AS Total_Quantity
FROM SuperstoreSalesProject.dbo.samplesuperstore
Group By Category;

-- Supporting Metrics: Average Discount, Order Count, Customer Count

SELECT Category, CAST(AVG(Discount) AS Decimal(10,2)) AS Average_Discount, COUNT(DISTINCT Order_ID) AS Order_Count, COUNT(DISTINCT Customer_ID) AS Customer_Count
FROM SuperstoreSalesProject.dbo.samplesuperstore
Group By Category;


--------------------------------------------------------------------------------------------------------------------------

/* Profitability vs Sales */
-- Which categories and sub‑categories generate high sales but low or negative profit?

Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

Select Category, Sub_Category, CAST(SUM(Sales) AS Decimal(12, 2)) AS Total_Sales, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit, SUM(Quantity) AS Total_Quantity
from SuperstoreSalesProject.dbo.samplesuperstore
Group By Category, Sub_Category
Having SUM(Sales) > 100000 AND SUM(Profit) <= 0
Order BY Total_Sales desc;

-- The category with the highest sales but negative profit is Furniture, specifically the Sub_Category for Tables and Bookcases. 
-- This indicates that while these products are selling well, they are not generating profit, likely driven by discounting and cost structure, which is investigated further in the following analysis..

-- Are losses driven by volume, discounting, or shipping?

Select Category, Sub_Category, Ship_Mode, CAST(SUM(Sales) AS Decimal(12, 2)) AS Total_Sales, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit, 
SUM(Quantity) AS Total_Quantity, CAST(AVG(Discount) AS Decimal(25, 2)) AS Avg_Discount
from SuperstoreSalesProject.dbo.samplesuperstore
Group By Category, Sub_Category, Ship_Mode
Having SUM(Profit) <= 0
Order BY Total_Profit
-- Order By Avg_Discount desc
;

-- Based on the data, it looks like having high quantities and high discounts are the main drivers of losses in the Furniture category, particularly for Tables and Bookcases.
-- Standard and Second Class shipping are associated with losses, likely due to lower margins per order rather than shipping speed alone.
-- We can indicate that high sales volume have weak margins and that the company is over discounting these products, which is eroding profitability.


--------------------------------------------------------------------------------------------------------------------------

/* Discount Impact */
-- How does profit change as discount increases?
-- Does this vary by category?

Select Category, Sub_Category, CAST(AVG(Discount) AS Decimal(25, 2)) AS Avg_Discount, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit
From SuperstoreSalesProject.dbo.samplesuperstore
Group By Category, Sub_Category
--Order By Avg_Discount desc
Order By Total_Profit desc;

-- The data indicates that higher discounts are generally associated with lower profits, where most discounts that are 0.08 to 0.16 provide the most profit.
-- Technology category has the highest profit, with having the top 3 highest profits, ranging average discounts from 0.08 to 0.16, which suggests that moderate discounts may be effective in driving sales while maintaining profitability.
-- The next two categories with the highest profits are Office Supplies and Furniture, which also show a similar trend where moderate discounts are associated with higher profits, while some have very high discounts (0.17 and above) are linked to high profits.


--------------------------------------------------------------------------------------------------------------------------

/* Segment Performance */

Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

-- Which segment generates the most profit?

Select Segment, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit
from SuperstoreSalesProject.dbo.samplesuperstore
Group By Segment
Order By Total_Profit desc;

-- The data indicates that in order the top 3 segments that generate the most profit are:
    -- 1. Consumer
    -- 2. Corporate
    -- 3. Home Office

-- Do higher discounts actually drive segment sales?

Select Segment, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit, CAST(AVG(Discount) AS Decimal(25, 2)) AS Avg_Discount, CAST(SUM(Sales) AS Decimal(25, 2)) AS Total_Sales 
from SuperstoreSalesProject.dbo.samplesuperstore
Group By Segment
Order By Total_Sales desc;

-- Based on the data, it appears that higher discounts do not necessarily drive segment sales with discounts ranging from 0.15 to 0.16
-- Consumer and Coprate both have 0.16 average discount, but Consumer has much higher sales and profits than Corporate, 
-- which suggests that other factors such as customer preferences, product mix, or marketing strategies may also play a significant role in driving sales and profitability for each segment.




--------------------------------------------------------------------------------------------------------------------------

/* Geographic Risk */

Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

-- Which states or cities consistently lose money (Top 5)?

Select Top 5 State_Province, City, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit
From SuperstoreSalesProject.dbo.samplesuperstore
Group BY State_Province, City
Having SUM(Profit) < 0
Order By Total_Profit;

-- The Top 5 states and cities that consistently lose money are:
    -- 1. Pennsylvania, Philadelphia
    -- 2. Texas, Houston
    -- 3. Texas, San Antonio
    -- 4. Ohio, Lacaster
    -- 5. Illinois, Chicago


-- Are losses driven by shipping cost, discounting, or product mix?

Select Top 5 State_Province, City, Ship_Mode, Category, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit, 
CAST(AVG(Discount) AS Decimal(25, 2)) AS Avg_Discount, CAST(SUM(Sales) AS Decimal(25, 2)) AS Total_Sales
From SuperstoreSalesProject.dbo.samplesuperstore
Group BY State_Province, City, Ship_Mode, Category
Order By Total_Profit;

-- Based on the data:
 -- All Ship Modes are Standard Class
 -- Categories are mostly Office Supplies and one Furniture and one Technology, which suggests that the product mix may be a significant factor in driving losses in these locations.
 -- Average Discouunts range from 0.29 to 0.48 which are very high, which suggests that over discounting may also be a significant factor in driving losses in these locations.

 -- So I would conclude that losses in these locations are likely driven by a combination of high discounts and an unfavorable product mix, which may be leading to lower profit margins and overall losses in these areas.





--------------------------------------------------------------------------------------------------------------------------

/* Shipping Strategy */

Select *
from SuperstoreSalesProject.dbo.samplesuperstore;

-- Does faster shipping reduce profit margins?

Select Ship_Mode, CAST(SUM(Profit) AS Decimal(12,2)) AS Total_Profit, CAST(SUM(Sales) AS Decimal(12,2)) AS Total_Sales, CAST((SUM(Profit) / SUM(Sales)) AS Decimal(10,2)) AS Profit_Margin
From SuperstoreSalesProject.dbo.samplesuperstore
Group By Ship_Mode
Order By Profit_Margin desc
-- Order By Total_Profit desc
;

-- Based on the data,
 -- First Class and Same Day shipping modes have the highest profit margins, which suggests that faster shipping modes appear to generate higher margins, while slower modes drive higher total profits through volume..
 -- I can conclude that faster shipping options may be more profitable, potentially due to higher customer satisfaction and willingness to pay for expedited delivery, which can lead to increased sales and profitability.

-- Which ship mode is most profitable overall?

-- Using the same query as above:
    -- Standard Class and Second Class shipping modes have the highest total profits, but the lowest profit margins
    -- which suggests that while they may generate more sales, they may also be associated with higher costs or lower customer satisfaction that can erode profitability.





--------------------------------------------------------------------------------------------------------------------------