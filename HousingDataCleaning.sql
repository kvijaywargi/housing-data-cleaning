/*
Data Cleaning Project - MySQL
Dataset - Publicly available Housing Data 
*/

SELECT count(*) FROM da_project.HousingDataCleaning;
SELECT * FROM da_project.HousingDataCleaning;

-- ************************
-- Formatting Date field
-- *************************
-- Date field is currently of String type and dd-mon-yy format. Changing it to Date format

select SaleDate, str_to_date(SaleDate, '%e-%M-%y') from HousingDataCleaning;

update HousingDataCleaning
set SaleDate = str_to_date(SaleDate, '%e-%M-%y');

-- ************************
-- Populating missing PropertyAddress  
-- ************************
-- upon looking at data closely, same parcelID has same PropertyAddress. 
-- So we can populate the propertyAddress when its matching parcelID has existing ProertyAddress

select ParcelID, PropertyAddress 
from HousingDataCleaning
where PropertyAddress is null;

-- self joining the table to find out the value of propertyaddress when parcelID is same but with unique occurences
select t1.ParcelID, t1.PropertyAddress, t2.ParcelID, t2.PropertyAddress
from HousingDataCleaning t1
join HousingDataCleaning t2
on t1.ParcelID = t2.ParcelID
and t1.UniqueID != t2.UniqueID
where t1.propertyAddress is null; 

update HousingDataCleaning t1
left join HousingDataCleaning t2
on t1.ParcelID = t2.ParcelID
and t1.UniqueID != t2.UniqueID
set t1.propertyAddress = t2.propertyAddress
where t1.propertyAddress is null;

-- Below query now returns 0 rows as all the null propertyAddress fields found the matching parcelID
select ParcelID, PropertyAddress 
from HousingDataCleaning
where PropertyAddress is null;

-- ************************
-- Formatting the Address field 
-- *************************

-- Splitting the PropertyAddress into address and city
-- it has only one delimeter "," between address and city
-- using substring_index()
select propertyAddress, 
substring_index(propertyAddress, ',' , 1) splitAdd1,
substring_index(propertyAddress, ',' , -1) splitAdd2
from HousingDataCleaning;

-- using substring()
select propertyAddress, 
substring(propertyAddress, 1, instr(propertyAddress,',')-1) splitAdd,
substring(propertyAddress, instr(propertyAddress,',')+1 ) splitAddCity
from HousingDataCleaning;

-- Adding new split columns
Alter table HousingDataCleaning
add propertyAdd1 varchar(100);
update HousingDataCleaning
set propertyAdd1 = substring_index(propertyAddress, ',' , 1);

Alter table HousingDataCleaning
add propertyAdd2 varchar(100);
update HousingDataCleaning
set propertyAdd2 = substring_index(propertyAddress, ',' , -1);

-- Splitting OwnerAddress into Address, City and State
-- it has two occurences of delimeter ","

select OwnerAddress,
substring_index(OwnerAddress, ',' , 1) splitAdd,
substring_index(substring_index(OwnerAddress, ',', -2),',', 1) splitAddCity,
substring_index(OwnerAddress, ',' , -1) splitAddState
from HousingDataCleaning;

select count(OwnerAddress) from HousingDataCleaning;
-- Adding new split columns
Alter table HousingDataCleaning
add OwnerAdd1 varchar(100);

update HousingDataCleaning
set OwnerAdd1 = substring_index(OwnerAddress, ',' , 1);

Alter table HousingDataCleaning
add OwnerAdd2 varchar(100);

update HousingDataCleaning
set OwnerAdd2 = substring_index(substring_index(OwnerAddress, ',', -2),',', 1);

Alter table HousingDataCleaning
add OwnerAdd3 varchar(100);

update HousingDataCleaning
set OwnerAdd3 = substring_index(OwnerAddress, ',' , -1);


-- ************************
-- SoldAsVacant Field - Y/N/Yes/No 
-- ************************

select distinct(SoldAsVacant), count( SoldAsVacant)
from HousingDataCleaning
group by SoldAsVacant;

-- less occurences of Y and N. Changing it to Yes and No for Uniformity

Select SoldAsVacant,
case when SoldAsVacant='Y' then 'Yes'
	when SoldAsVacant='N' then 'No'
    else SoldAsVacant
end
from HousingDataCleaning;

update HousingDataCleaning
set SoldAsVacant = 
case when SoldAsVacant='Y' then 'Yes'
	when SoldAsVacant='N' then 'No'
    else SoldAsVacant
end
;

-- ************************
-- Remove Duplicates 
-- ************************

-- taking into consideration that a unique row would be something that will not have same snap of 
-- parcelID, Address, Date, Price and Legal number. Identifying all the occurences with that logic

with occurenceTable as (
select *,
row_number() over (
	partition by ParcelID, PropertyAddress,
					SaleDate, SalePrice, LegalReference
	order by UniqueID) occurence
from HousingDataCleaning)
-- select * from occurenceTable where occurence>1 ;
delete from HousingDataCleaning 
using HousingDataCleaning
join occurenceTable
on HousingDataCleaning.UniqueID = occurenceTable.UniqueID
where occurence>1;

-- ************************
-- Delete Unused Columns
-- ************************

Alter table HousingDataCleaning
drop column PropertyAddress;
Alter table HousingDataCleaning
drop column OwnerAddress;

