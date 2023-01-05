--PREVIEW
SELECT * 
FROM Portfolio_SQL_Projects .. Nashville_housing

-----------------------------------------------------------------------------------


--Remove the Time from `SaleDate`, added as new column `SaleDate2`
ALTER TABLE Nashville_housing
ADD SaleDate2 date

UPDATE Nashville_housing
SET SaleDate2 = CONVERT(date, SaleDate)


-----------------------------------------------------------------------------------

--Populate `PropertyAddress` data to replace NULL
--Same `ParcelID` means same `PropertyAddress`
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_SQL_Projects .. Nashville_housing a
--Join where the rows have the same Parcel ID but different Unique ID
JOIN Portfolio_SQL_Projects .. Nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-----------------------------------------------------------------------------------


--Breaking the Property Address into Street Address and City
SELECT PropertyAddress,
	--split from position 1 to position before the comma (-1)
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS StreetAddress,
	--split from position after the comma (+1) until the end
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM Portfolio_SQL_Projects .. Nashville_housing

--Add columns to the table
ALTER TABLE Nashville_housing
ADD PropertyStreetAddress Nvarchar(255)

ALTER TABLE Nashville_housing
ADD PropertyCity Nvarchar(255)

UPDATE Nashville_housing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE Nashville_housing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


-----------------------------------------------------------------------------------


--Breaking the Owner Address into Street Address and City
SELECT OwnerAddress
FROM Portfolio_SQL_Projects .. Nashville_housing

--replace comma with period as PARSENAME only works with period
SELECT
PARSENAME(REPLACE(OwnerAddress, ',' , '.'),3) AS OwnerStreetAddress,
PARSENAME(REPLACE(OwnerAddress, ',' , '.'),2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',' , '.'),1) AS OwnerState
FROM Portfolio_SQL_Projects .. Nashville_housing

--add 3 columns to the table
ALTER TABLE Nashville_housing
ADD OwnerStreetAddress Nvarchar(255)

ALTER TABLE Nashville_housing
ADD OwnerCity Nvarchar(255)

ALTER TABLE Nashville_housing
ADD OwnerState Nvarchar(255);

UPDATE Nashville_housing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),3)

UPDATE Nashville_housing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),2)

UPDATE Nashville_housing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'),1)



-----------------------------------------------------------------------------------


--Check distinct values in `SoldAsVacant` column
SELECT DISTINCT(SoldAsVacant), COUNT(*) AS count
FROM Portfolio_SQL_Projects .. Nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2

--Update the table: Changing Y/N to Yes/No for consistency
UPDATE Nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant END



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
FROM Portfolio_SQL_Projects .. Nashville_housing
)
--delete duplicates from the table
DELETE
FROM RowNumCTE
WHERE row_num > 1


-----------------------------------------------------------------------------------

--Delete unused columns
ALTER TABLE Portfolio_SQL_Projects .. Nashville_housing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate
