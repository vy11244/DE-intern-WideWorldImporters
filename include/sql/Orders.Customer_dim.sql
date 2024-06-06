-- test join đúng nhưng không join từng cặp
/*
  The query is done to convert from bronze data into silver data
     Database: WideWorldImporters
     Module: ORDERS
     Contributed Bronze Table: ORDERS.ORDERS_BRONZE.CUSTOMER,ORDERS.ORDERS_BRONZE.BUYINGGROUPS,ORDERS.ORDERS_BRONZE.CUSTOMERCATEGORIES, APPLICATION.PEOPLE
     Contributed Silver table: ORDERS.ORDERS_SILVER.CUSTOMER
     Author: THAOPLT2
     Last update when: 2024-03-21 17:02:00.0000000
     Update content: right join type, fix ValidFrom, ValidTo
*/

truncate table ORDERS.ORDERS_SILVER.CUSTOMER;

INSERT INTO ORDERS.ORDERS_SILVER.CUSTOMER (
    CUSTOMERKEY,
	WWICUSTOMERID,
	CUSTOMER,
	BILLTOCUSTOMER,
	CATEGORY,
	BUYINGGROUP,
	PRIMARYCONTACT,
	POSTALCODE,
	VALIDFROM,
	VALIDTO
)
-- create temp1 table to connect Customers and CustomerCategories
WITH temp1 as(
    SELECT T1.PRIMARYCONTACTPERSONID,
        T1.BILLTOCUSTOMERID AS BILLTOCUSTOMERID,
        T1.BUYINGGROUPID,
        T1.CUSTOMERID AS WWICUSTOMERID,
        T1.CUSTOMERNAME AS CUSTOMER,
        T2.CUSTOMERCATEGORYNAME,
        T1.DELIVERYPOSTALCODE AS POSTALCODE,
        CASE WHEN T1.CUSTOMERCATEGORYID IS NOT NULL THEN (CASE WHEN T1.ValidFrom < T2.ValidFrom THEN T2.ValidFRom ELSE T1.ValidFrom END) ELSE T1.ValidFrom END as ValidFrom,
        CASE WHEN T1.CUSTOMERCATEGORYID IS NOT NULL THEN (CASE WHEN T1.ValidTo < T2.ValidTo THEN T1.ValidTo ELSE T2.ValidTo END) ELSE T1.ValidTo END as ValidTo
    FROM ORDERS.ORDERS_BRONZE.CUSTOMERS T1
    LEFT JOIN ORDERS.ORDERS_BRONZE.CUSTOMERCATEGORIES T2 
        ON T1.CUSTOMERCATEGORYID = T2.CUSTOMERCATEGORYID
        AND T1.VALIDFROM < T2.VALIDTO AND T1.VALIDTO > T2.VALIDFROM
), 
-- create temp2 to connect temp1 and BuyingGroups
temp2 as(
    SELECT temp1.PRIMARYCONTACTPERSONID,
           temp1.BILLTOCUSTOMERID,
           temp1.WWICUSTOMERID,
           temp1.CUSTOMER,
           T3.BUYINGGROUPNAME AS BUYINGGROUP,
           temp1.CUSTOMERCATEGORYNAME AS CATEGORY,
           temp1.POSTALCODE,
           CASE WHEN temp1.BUYINGGROUPID IS NOT NULL THEN (CASE WHEN temp1.ValidFrom < T3.ValidFrom THEN T3.ValidFRom ELSE temp1.ValidFrom END) ELSE temp1.ValidFrom END as ValidFrom,
           CASE WHEN temp1.BUYINGGROUPID IS NOT NULL THEN (CASE WHEN temp1.ValidTo < T3.ValidTo THEN temp1.ValidTo ELSE T3.ValidTo END) ELSE temp1.ValidTo END as ValidTo
    FROM temp1
    LEFT JOIN ORDERS.ORDERS_BRONZE.BUYINGGROUPS T3 
        ON temp1.BUYINGGROUPID = T3.BUYINGGROUPID
        AND temp1.VALIDFROM < T3.VALIDTO AND temp1.VALIDTO > T3.VALIDFROM
), 
-- create temp3 to connect temp2 and Customers
temp3 as(
    SELECT temp2.PRIMARYCONTACTPERSONID,
           temp2.WWICUSTOMERID,
           temp2.CUSTOMER,
           temp2.CATEGORY,
           temp2.BUYINGGROUP,
           T4.CUSTOMERNAME AS BILLTOCUSTOMER,
           temp2.POSTALCODE,
           CASE WHEN temp2.BILLTOCUSTOMERID IS NOT NULL THEN (CASE WHEN temp2.ValidFrom < T4.ValidFrom THEN T4.ValidFRom ELSE temp2.ValidFrom END) ELSE temp2.ValidFrom END as ValidFrom,
           CASE WHEN temp2.BILLTOCUSTOMERID IS NOT NULL THEN (CASE WHEN temp2.ValidTo < T4.ValidTo THEN temp2.ValidTo ELSE T4.ValidTo END) ELSE temp2.ValidTo END as ValidTo
     FROM temp2
     LEFT JOIN ORDERS.ORDERS_BRONZE.CUSTOMERS T4 
        ON temp2.BILLTOCUSTOMERID = T4.CUSTOMERID
        AND temp2.VALIDFROM < T4.VALIDTO AND temp2.VALIDTO > T4.VALIDFROM
), 
-- create temp4 to connect temp3 and People
temp4 as(
    SELECT temp3.WWICUSTOMERID,
           temp3.CUSTOMER,
           temp3.BILLTOCUSTOMER,
           temp3.CATEGORY,
           temp3.BUYINGGROUP,
           T5.FULLNAME AS PRIMARYCONTACT,
           temp3.POSTALCODE,
           CASE WHEN temp3.PRIMARYCONTACTPERSONID IS NOT NULL THEN (CASE WHEN temp3.ValidFrom < T5.ValidFrom THEN T5.ValidFRom ELSE temp3.ValidFrom END) ELSE temp3.ValidFrom END as ValidFrom,
           CASE WHEN temp3.PRIMARYCONTACTPERSONID IS NOT NULL THEN (CASE WHEN temp3.ValidTo < T5.ValidTo THEN temp3.ValidTo ELSE T5.ValidTo END) ELSE temp3.ValidTo END as ValidTo
           FROM temp3
           LEFT JOIN ORDERS.ORDERS_BRONZE.PEOPLE T5 
                ON temp3.PRIMARYCONTACTPERSONID = T5.PERSONID
                AND temp3.VALIDFROM < T5.VALIDTO AND temp3.VALIDTO > T5.VALIDFROM
)
-- select full columns of temp4 and concat WWICUSTOMERID with latest ValidFrom to have Customerkey
SELECT
    CONCAT(temp4.WWICUSTOMERID, TO_CHAR(temp4.ValidFrom, 'YYYYMMDDHH24MISSFF7')) AS CUSTOMERKEY,
    temp4.WWICUSTOMERID,
    temp4.CUSTOMER,
    temp4.BILLTOCUSTOMER,
    temp4.CATEGORY,
    temp4.BUYINGGROUP,
    temp4.PRIMARYCONTACT,
    temp4.POSTALCODE,
    temp4.VALIDFROM,
    temp4.VALIDTO
FROM temp4;
