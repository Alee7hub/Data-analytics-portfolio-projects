/*
For this project, I created an empty table first (I used a Python script for this CREAT TABLE statement). 
Then I identified the datatypes of each column. And then I used the following code to copy all the data I want from
the CSV (or excel) file that I have to this new empty table that I just created.
*/

CREATE TABLE Nashville_Housing (
    UniqueID  numeric,
    ParcelID varchar(30),
    LandUse varchar(60),
    PropertyAddress varchar(60),
    SaleDate date,
    SalePrice numeric,
    LegalReference varchar(60),
    SoldAsVacant varchar(60),
    OwnerName varchar(60),
    OwnerAddress varchar(60),
    Acreage numeric,
    TaxDistrict varchar(60),
    LandValue numeric,
    BuildingValue numeric,
    TotalValue numeric,
    YearBuilt numeric,
    Bedrooms numeric,
    FullBath numeric,
    HalfBath numeric
);

COPY nashville_housing FROM 
'D:/Documents/Learning/Data Analytics/Portfolio projects/Nashville Housing Data for Data Cleaning/Nashville_Housing.csv' WITH CSV HEADER;

---------------------------------------------------

Select * From nashville_housing

---------------------------------------------------
/*
Standardize Date format: I want to drop the time part of the saledate column. 
As you can see there is no time part in that column because I already removed it unintentionally by
specifying that column' data type as date.  
*/

---------------------------------------------------
/*
Populate Property Address data
*/

Select propertyaddress
From nashville_housing
Where propertyaddress is null;
/* Turns out that we have 29 null values in this column. So what we are gonna do is that we check the ParcelID 
and if for that ParcelID, there is an address, and and if there is another exact ParcelID that does not have
the address, we conclude that this missing address will be the same as the previous one. */

-- Self JOIN

Select h1.parcelid, h1.propertyaddress, h2.parcelid, h2.propertyaddress
From nashville_housing h1
Join nashville_housing h2
	On h1.parcelid = h2.parcelid
Where h1.propertyaddress is null And h2.propertyaddress is not null;
/* We were able to find the same ParcelIDs. One of them has address and the other does not.
Now we can fill the missing address with the one we have for the exact same parcelID.*/

Select h1.parcelid, h1.propertyaddress, h2.parcelid, h2.propertyaddress, Coalesce(h1.propertyaddress, h2.propertyaddress)
From nashville_housing h1
Join nashville_housing h2
	On h1.parcelid = h2.parcelid
Where h1.propertyaddress is null And h2.propertyaddress is not null;

/* Now, it is the time to update the main table and fill those missing address values. */ 
UPDATE nashville_housing h1
SET propertyaddress = COALESCE(h1.propertyaddress, h2.propertyaddress)
FROM nashville_housing h2
WHERE h1.propertyaddress IS NULL AND h2.propertyaddress IS NOT NULL
AND h1.parcelid = h2.parcelid;


---------------------------------------------------
/*
Breaking out Address into Individual Columns (Address, City, State)
*/

Select propertyaddress, position(',' in propertyaddress)
From nashville_housing;

SELECT propertyaddress, 
SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1),
SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 1)
FROM nashville_housing;

-- We have added two new columns, one for the property address and the other for corresponding city.
-- Therefore we have to update our table.

ALTER TABLE nashville_housing
ADD COLUMN PropertySplitAddress VARCHAR(255);

ALTER TABLE nashville_housing
ADD COLUMN PropertySplitCity VARCHAR(100);

UPDATE nashville_housing
SET 
    PropertySplitAddress = SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1),
    PropertySplitCity = SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 1);

-- Drop the original column if you no longer need it: ALTER TABLE your_table DROP COLUMN original_column;
-- Now, we should do the same with owneraddress column as well. In that column there are two commas and hence,
-- we want to separate the address part, the city part and the state part right off of those commas.

ALTER TABLE nashville_housing
ADD COLUMN OwnerSplitAddress VARCHAR(255),
ADD COLUMN OwnerSplitCity VARCHAR(255),
ADD COLUMN OwnerSplitState VARCHAR(255);

UPDATE nashville_housing
SET
    OwnerSplitAddress = SPLIT_PART(owneraddress, ',', 1),
    OwnerSplitCity = SPLIT_PART(owneraddress, ',', 2),
    OwnerSplitState = SPLIT_PART(owneraddress, ',', 3);

-- As can be seen, Split_part is more syntax-friendly than the combination of substring() and position().

---------------------------------------------------
/*
Change Y and N to Yes and No in "Sold as Vacant" field
*/

-- To explore the current situation:
Select distinct soldasvacant, count(soldasvacant)
from nashville_housing
group by soldasvacant
order by 2

-- Now for converting all Y to Yes and all N to No:
UPDATE nashville_housing
SET soldasvacant = 'No'
WHERE soldasvacant = 'N';

UPDATE nashville_housing
SET soldasvacant = 'Yes'
WHERE soldasvacant = 'Y';

---------------------------------------------------
/*
Remove Duplicates
*/

-- First of all we have to identify all the duplicates. But to me, duplicates are those rows whose following
-- fields (columns) are the same (not necessarily all the corresponding columns): 
-- parcelid, propertyaddress, saleprice, saledate, legalreference

SELECT parcelid, propertyaddress, saleprice, saledate, legalreference, COUNT(*)
FROM nashville_housing
GROUP BY parcelid, propertyaddress, saleprice, saledate, legalreference
HAVING COUNT(*) > 1;
-- Now you see all those duplicates (according to our definition).

-- Now we want to remove those duplicates as follows:
DELETE FROM nashville_housing
WHERE (parcelid, propertyaddress, saleprice, saledate, legalreference) IN (
    SELECT parcelid, propertyaddress, saleprice, saledate, legalreference
    FROM nashville_housing
    GROUP BY parcelid, propertyaddress, saleprice, saledate, legalreference
    HAVING COUNT(*) > 1
);
-- Note: The above DELETE statement removes all but one of the duplicate rows.

---------------------------------------------------
/*
Delete Unused Columns
*/

ALTER TABLE nashville_housing
DROP COLUMN owneraddress,
DROP COLUMN taxdistrict,
DROP COLUMN propertyaddress;

