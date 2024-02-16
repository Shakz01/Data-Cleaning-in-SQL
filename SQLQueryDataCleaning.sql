/* 
Data Cleaning in SQL
*/
--Viewing the entire table for visual inspection of the dataset. 
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing
/*
Note: The following were observes
1. the SaleDate column is not in the right datatype
2. PropertyAddress has some Null values
3. The propertyAddress column has the full address that needs to be split into the house adress and the city in which the house is located
4. The OwnerAddress column also has the full address that needs to be split into the house adress and the city, the state in which the owner is located
5. The SoldAsVacant column has some N and Y instead of Yes and No.
*/ 

------------------------------------------------------------------------------------------------------------------------------------------
--1.	Changing SaleDate datatype from 'DATETIME' to 'DATE' format
-- Alter the table to change the data-type of the date column
ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
ALTER COLUMN SaleDate DATE
--SELECT SaleDate, CONVERT(DATE, SaleDate)
--FROM NewPortfolio.dbo.Nashvill_Housing		to first confirm the 'CONVERT' function
-- Update the column to convert the existing data to the new format
UPDATE NewPortfolio.dbo.Nashvill_Housing
SET SaleDate = CONVERT(DATE, SaleDate)

--Re-check the Nashvill Housing table for confirmation
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing    -- Yeah! the date datatype change from DATETIME format to DATE format.

ALTER TABLE Table_Name
ADD NewColumn_Name datatype				--this will add a new column to an existing table in the database
-----------------------------------------------------------------------------------------------------------------------------------------------------


--2.	To populate the NULL values in the PropertyAddress column
/*It is noted that the house unit with the same ParcelID has the same address. Hence we can make use of this to populate the ones with NULL values*/
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing
where PropertyAddress IS NULL		--ther are 29 row with NULL value in the column
ORDER BY ParcelID

-- what we need to do to acieve populating the Null rows in the PropertyAddress 
--column is to run a SELF JOINT script that will return an adress if the ParcilID is the same.

--Running the self join
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NewPortfolio.dbo.Nashvill_Housing		a
JOIN NewPortfolio.dbo.Nashvill_Housing		b
	ON a.ParcelID = b.ParcelID				--the SELF JOIN will show all the correspondent adresses with the same ParcilID
	AND a.[UniqueID ] <>b.[UniqueID ]		-- the addresses that can  be used to populate the rows with the Null values
WHERE b.PropertyAddress IS NULL		

--Using ISNULL function to extract the address base on the same ParcilID and use it to create a new column
--the SELF JOIN will show all the correspondent adresses with the same ParcilID
-- the addresses that can  be used to populate the rows with the Null values

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
	   ISNULL(b.PropertyAddress, a.PropertyAddress) --if b.PropertyAddress is NUll, the return a.PropertyAddress
FROM NewPortfolio.dbo.Nashvill_Housing		a
JOIN NewPortfolio.dbo.Nashvill_Housing		b
	ON a.ParcelID = b.ParcelID				
	AND a.[UniqueID ] <>b.[UniqueID ]		
WHERE b.PropertyAddress IS NULL

--The next step is to populate the table with the ISNULL script
--running this update the 29 rows with the null values on the PropertyAddress column
UPDATE b
SET PropertyAddress = ISNULL(b.PropertyAddress, a.PropertyAddress) --the update condition

FROM NewPortfolio.dbo.Nashvill_Housing		a		--where the condition is coming from
JOIN NewPortfolio.dbo.Nashvill_Housing		b
	ON a.ParcelID = b.ParcelID				
	AND a.[UniqueID ] <>b.[UniqueID ]		
WHERE b.PropertyAddress IS NULL

--checking
--the checking shows that the is no more NULL values in the PropertyAddress column
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress 
	  -- ISNULL(b.PropertyAddress, a.PropertyAddress) --if b.PropertyAddress is NUll, the return a.PropertyAddress
FROM NewPortfolio.dbo.Nashvill_Housing		a
JOIN NewPortfolio.dbo.Nashvill_Housing		b
	ON a.ParcelID = b.ParcelID				
	AND a.[UniqueID ] <>b.[UniqueID ]		
WHERE b.PropertyAddress IS NULL
--OR
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing
WHERE PropertyAddress IS NULL

-------------------------------------------------------------------------------------------------------------------------------------------------------------

--3.	To split the propertyAdress column into the house address and the city
-- Let's first look at the PropertyAddress format in our table
--this shows that the the address is separated by a delimeter (comma)
SELECT PropertyAddress
FROM NewPortfolio.dbo.Nashvill_Housing		

--we can use SUBSTRING function to split the PropertyAddress column into two
--we use the CHARINDEX to specify the condition of the position we want the split to happen
--SUBSTRING (COLUMN_NAME, START FROM, END AT)
--CHARINDEX (POSITION TO PICK, COLUMN NAME)

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) HouseAddress,
--for the city split, we use SUBSTRING AND CHARINDEX  to specify the split position
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 
FROM NewPortfolio.dbo.Nashvill_Housing

--To populate our database with these, we need to create 2 new column and update it accordingly
--Add and update a HouseAddress column
ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
ADD HouseAddress VARCHAR(255)

UPDATE NewPortfolio.dbo.Nashvill_Housing
SET HouseAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

--Add and update a City column
ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
ADD CityAddress VARCHAR(255)

UPDATE NewPortfolio.dbo.Nashvill_Housing
SET CityAddress = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
--checking the table for confirmation
--Yah! it works.
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing

---------------------------------------------------------------------------------------------------------------------------------------------------------------

--4.	To split the OwnerAdress column into the house address, the city and the state
--Note: This time around, we will be using another method which seems simpler than the SUBSTRING method we used in the PropertyAddress

--Here we are using PARSENAME function to split the Owner addresss
--The PARSENAME function is preset to separate a string with a (fullstop) delimiter and it operate from backward
--But we can always use REPLACE function to change the (fullstop) delimiter to the one of our choice
--
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)	ad, -- WE REPLACE THE COMMA WITH A FULLSTOP
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)	CIT,	
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)	STATE
FROM NewPortfolio.dbo.Nashvill_Housing

--The next step is to alter the table, add columns and update it the columns with respective split column
--For OwnerAddress

ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
--DROP COLUMN OwnerHouseAddress
ADD OwnerHouseAddress NVARCHAR(255)

UPDATE NewPortfolio.dbo.Nashvill_Housing
SET OwnerHouseAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

--For OwnerCity
ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
ADD OwnerCity NVARCHAR(255)

UPDATE NewPortfolio.dbo.Nashvill_Housing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

--For OwnerState
ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
ADD OwnerState NVARCHAR(255)

UPDATE NewPortfolio.dbo.Nashvill_Housing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-checking
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--5.	Changing Y and N to Yes and No in the SoldAsVacant column

--viewing the distinct values in the column

SELECT DISTINCT(SoldAsVacant)
FROM NewPortfolio.dbo.Nashvill_Housing 

--look at the count of the unique entries
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NewPortfolio.dbo.Nashvill_Housing 
GROUP BY SoldAsVacant
ORDER BY 2

-- To change Y and N to Yes and No, we make use of a CASE statement.

SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant LIKE '%Y%' THEN 'Yes'
		WHEN SoldAsVacant LIKE '%N%' THEN 'No'
		ELSE SoldAsVacant
	END
FROM NewPortfolio.dbo.Nashvill_Housing 
--Update this in the database
UPDATE NewPortfolio.dbo.Nashvill_Housing 
SET SoldAsVacant = CASE
		WHEN SoldAsVacant LIKE '%Y%' THEN 'Yes'
		WHEN SoldAsVacant LIKE '%N%' THEN 'No'
		ELSE SoldAsVacant
	END
---------------------------------------------------------------------------------------------------------------------------------------------------------------
--6. Checking for Duplicate using WINDON function ROW_NUMBER() to partition the selected table that should be unique
-- We make use of CTE
--By running the CTE script, it will return all the duplicated row.
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM NewPortfolio.dbo.Nashvill_Housing 

)
SELECT *
FROM RowNumCTE
WHERE row_num > 1


--Deleting the duplicate rows from the CTE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM NewPortfolio.dbo.Nashvill_Housing 
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--Checking
SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing   --we notice a reduction in the number of rows of the dataset
---------------------------------------------------------------------------------------------------------------------------------------------------------------

--Deleting Unused Column

ALTER TABLE NewPortfolio.dbo.Nashvill_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


SELECT *
FROM NewPortfolio.dbo.Nashvill_Housing
