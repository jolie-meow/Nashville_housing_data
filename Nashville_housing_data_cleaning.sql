--PREVIEW
SELECT * 
FROM Portfolio_SQL_Projects .. NashvilleHousing

-----------------------------------------------------------------------------------
--Remove the Time from `SaleDate`, added as new column `SaleDateConverted`
ALTER TABLE NashvilleHousing
ADD SaleDateConverted date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

-----------------------------------------------------------------------------------
--Populate `PropertyAddress` data to replace NULL
--Same `ParcelID` means same `PropertyAddress`
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_SQL_Projects .. NashvilleHousing a
--Join where the rows have the same Parcel ID but different Unique ID
JOIN Portfolio_SQL_Projects .. NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-----------------------------------------------------------------------------------
--Breaking the Property Address into Street Address and City
--Add columns to the table
ALTER TABLE NashvilleHousing
ADD PropertyStreetAddress Nvarchar(255)

ALTER TABLE NashvilleHousing
ADD PropertyCity Nvarchar(255)

--split from position 1 to position before the comma (-1)
UPDATE NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

--split from position after the comma (+1) until the end
UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))



-----------------------------------------------------------------------------------
--Breaking the Owner Address into Street Address and City
--add 3 columns to the table
ALTER TABLE NashvilleHousing
ADD OwnerStreetAddress Nvarchar(255)

ALTER TABLE NashvilleHousing
ADD OwnerCity Nvarchar(255)

ALTER TABLE NashvilleHousing
ADD OwnerState Nvarchar(255);

--replace comma with period as PARSENAME only works with period
UPDATE NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),3)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),2)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),1)


-----------------------------------------------------------------------------------
--Check distinct values in `SoldAsVacant` column
SELECT DISTINCT(SoldAsVacant), COUNT(*) AS count
FROM Portfolio_SQL_Projects .. NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Update the table: Changing Y/N to Yes/No for consistency
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant END


-----------------------------------------------------------------------------------
--Consolidate duplicate values in LandUse
UPDATE Portfolio_SQL_Projects .. NashvilleHousing
SET LandUse = 'VACANT RESIDENTIAL LAND'
WHERE LandUse = 'VACANT RESIENTIAL LAND' OR LandUse = 'VACANT RES LAND'


-----------------------------------------------------------------------------------
-- extract YearSold from Sale Date
ALTER TABLE NashvilleHousing
ADD YearSold int

UPDATE NashvilleHousing
SET YearSold = YEAR(SaleDateConverted)

-- add column PropertyAge: YearSold - YearBuilt
ALTER TABLE NashvilleHousing
ADD PropertyAge int

UPDATE NashvilleHousing
SET PropertyAge = YearSold - YearBuilt

-----------------------------------------------------------------------------------
--Remove duplicates using CTE
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									SaleDate,
									LegalReference
									ORDER BY UniqueID
									) row_num
FROM Portfolio_SQL_Projects .. NashvilleHousing
)
--delete duplicates from the table
DELETE
FROM RowNumCTE
WHERE row_num > 1


-----------------------------------------------------------------------------------
--Delete unused columns
ALTER TABLE Portfolio_SQL_Projects .. NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate



-----------------------------------------------------------------------------------
--QUERIES FOR VISUALISATION IN TABLEAU--

--Table1: Number of houses that are sold as vacant
SELECT DISTINCT(SoldAsVacant), COUNT(*) AS Total_Houses
FROM Portfolio_SQL_Projects .. NashvilleHousing
WHERE PropertyCity = 'NASHVILLE'
GROUP BY SoldAsVacant
ORDER BY 2

--Table2: Top 5 Land Use in Nashville 
SELECT DISTINCT(LandUse), COUNT(*) AS Total_Houses
FROM Portfolio_SQL_Projects .. NashvilleHousing
WHERE PropertyCity = 'NASHVILLE'
GROUP BY LandUse
ORDER BY Total_Houses DESC
OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY


--Table3: Number of houses sold in Nashville based on number of bedrooms
SELECT Bedrooms, SaleDateConverted, COUNT(SaleDateConverted) AS Total_Houses
FROM Portfolio_SQL_Projects .. NashvilleHousing
WHERE PropertyCity = 'NASHVILLE'
GROUP BY Bedrooms, SaleDateConverted
HAVING Bedrooms IS NOT NULL 
	AND Bedrooms > 0
ORDER BY Bedrooms, SaleDateConverted 


SELECT Bedrooms, count(*)
FROM Portfolio_SQL_Projects .. NashvilleHousing
GROUP BY Bedrooms
ORDER BY Bedrooms

--Table4: Median Sale price vs Property Age in Nashville
SELECT DISTINCT PropertyAge,
	 PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY SalePrice) 
        OVER (PARTITION BY PropertyAge)
        AS MedianSalePrice
FROM Portfolio_SQL_Projects .. NashvilleHousing
--remove NULL and negative values
WHERE PropertyAge IS NOT NULL 
	AND PropertyAge > 0
	AND PropertyCity = 'NASHVILLE'
ORDER BY PropertyAge


