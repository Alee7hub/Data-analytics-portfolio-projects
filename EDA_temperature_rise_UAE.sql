The following queries go through the analysis I already did with Python on the global temperature rise. I did the following analysis by PostgreSQL.
Among all those vulnerable places in terms of climate change, I chose UAE as an example. The same analysis can be conducted on other places as well.
I used the dataset provided by Berkeley Earth on Kaggle. The license of this dataset can be found here: https://creativecommons.org/licenses/by-nc-sa/4.0/ 
---------------------------------------------------------------------------------------------------------------------------



/*
Creating an empty table and then importing the contents of the main csv file to that table
*/

CREATE TABLE global_temp_rise (
    dt varchar(40),
    AverageTemperature numeric,
    AverageTemperatureUncertainty numeric,
    Country varchar(60)
);

COPY global_temp_rise
FROM 
'D:/Documents/Learning/Data Analytics/Portfolio projects/Earth Surface Temperature Data/GlobalLandTemperaturesByCountry.csv' 
WITH CSV HEADER;


Select * From global_temp_rise


-- Renaming the columns



ALTER TABLE global_temp_rise
RENAME COLUMN dt TO Date;

ALTER TABLE global_temp_rise
Rename Column averagetemperature To Avg_Temp;

ALTER TABLE global_temp_rise
Rename Column averagetemperatureuncertainty To Avg_Temp_unc;

Select * From global_temp_rise



-- Changing the type of the "Date" column

ALTER TABLE global_temp_rise
ALTER COLUMN date TYPE DATE USING date::DATE;



-- Dropping unused columns

ALTER TABLE global_temp_rise
DROP COLUMN Avg_Temp_unc;



-- Creating the "Year" column

Alter Table global_temp_rise
Add Column Year int;



-- Update the new column with the separated values

UPDATE global_temp_rise
SET Year = EXTRACT(YEAR FROM date) 



-- Reducing the decimal point of the values in Avg_Temp column

UPDATE global_temp_rise
SET Avg_Temp = ROUND(Avg_Temp, 2);



-- Dealing with null values

Select count(*)
From global_temp_rise
Where avg_temp is null;  
/* Turns out 5% of the data is null. It is assumed removing this much of data would not affect the analysis considerably
and hence it is negligible. */

DELETE FROM global_temp_rise
WHERE avg_temp IS NULL;



-- Separating UAE as an example for the analysis.

Select *
From global_temp_rise
Where Country = 'United Arab Emirates' and Year >=1900;
/* Since I want to do some aggregation on the previous table, I should use CTE method. */

-- Using CTE

With uae_temp
as
(
Select *
From global_temp_rise
Where Country = 'United Arab Emirates' and Year >=1900
)
Select Year, Round(avg(avg_temp), 1) as Avg, min(avg_temp) as min, max(avg_temp) as max
From uae_temp
Group by Year;








