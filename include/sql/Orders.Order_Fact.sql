 

DELETE
FROM ORDERS.ORDERS_SILVER.ORDERS AS ord
WHERE ord.WWIORDERID IN (

WITH FACT_ORDERS AS (
    SELECT si.STOCKITEMID
        ,cus.DELIVERYCITYID
        , o.ORDERDATE AS ORDERDATEKEY
        , o.PICKINGCOMPLETEDWHEN AS PICKEDDATEKEY
        ,o.ORDERID AS WWIORDERID
        , o.BACKORDERORDERID AS WWIBACKORDERID
        , o.SALESPERSONPERSONID
        , o.PICKEDBYPERSONID
        , O.CUSTOMERID
        , orl.DESCRIPTION
        , pck.PACKAGETYPENAME AS PACKAGE
        , orl.QUANTITY
        , orl.UNITPRICE
        , orl.TAXRATE
        , ROUND(orl.Quantity * orl.UnitPrice, 2) AS TOTALEXCLUDINGTAX
        , ROUND(orl.Quantity * orl.UnitPrice * orl.TaxRate / 100.0, 2) AS TAXAMOUNT
        , ROUND(orl.Quantity * orl.UnitPrice, 2) + ROUND(orl.Quantity * orl.UnitPrice * orl.TaxRate / 100.0, 2) AS TOTALINCLUDINGTAX
        , CASE WHEN orl.LASTEDITEDWHEN > o.LASTEDITEDWHEN THEN orl.LASTEDITEDWHEN 
        ELSE o.LASTEDITEDWHEN END AS LASTMODIFIEDWHEN
    

        FROM ORDERS.ORDERS_BRONZE.ORDERLINES AS orl
        
        LEFT JOIN ORDERS.ORDERS_BRONZE.ORDERS AS o ON orl.ORDERID = o.ORDERID
        
        LEFT JOIN ORDERS.ORDERS_BRONZE.PACKAGETYPES AS pck ON orl.PACKAGETYPEID = pck.PACKAGETYPEID
        AND LASTMODIFIEDWHEN > pck.ValidFrom
        AND LASTMODIFIEDWHEN <= pck.ValidTo
        
        LEFT JOIN ORDERS.ORDERS_BRONZE.CUSTOMERS AS cus ON o.CUSTOMERID = cus.CUSTOMERID
        AND LASTMODIFIEDWHEN > cus.ValidFrom
        AND LASTMODIFIEDWHEN <= cus.ValidTo
        LEFT JOIN ORDERS.ORDERS_BRONZE.STOCKITEMS AS si ON orl.STOCKITEMID = si.STOCKITEMID
        AND LASTMODIFIEDWHEN > si.ValidFrom
        AND LASTMODIFIEDWHEN <= si.ValidTo
        
    ),

    UPDATE_CUSTOMERKEY AS (
        SELECT CTM.CUSTOMERKEY,
                A.ORDERDATEKEY,
                A.PICKEDDATEKEY,
                A.WWIORDERID,
                A.WWIBACKORDERID,
                A.DESCRIPTION,
                A.PACKAGE,
                A.QUANTITY,
                A.UNITPRICE,
                A.TAXRATE,
                A.TOTALEXCLUDINGTAX,
                A.TAXAMOUNT,
                A.TOTALINCLUDINGTAX,
                A.LASTMODIFIEDWHEN,
                A.DELIVERYCITYID,
                A.STOCKITEMID,
                A.SALESPERSONPERSONID,
                A.PICKEDBYPERSONID
            FROM FACT_ORDERS AS A
        LEFT JOIN ORDERS.ORDERS_SILVER.CUSTOMER AS CTM ON CTM.WWICUSTOMERID = A.CUSTOMERID
        AND A.LASTMODIFIEDWHEN > CTM.ValidFrom
        AND A.LASTMODIFIEDWHEN <= CTM.ValidTo
    ),

    UPDATE_CITYKEY as (
        SELECT  CT.CITYKEY,
                UCK.CUSTOMERKEY,
                UCK.ORDERDATEKEY,
                UCK.PICKEDDATEKEY,
                UCK.WWIORDERID,
                UCK.WWIBACKORDERID,
                UCK.DESCRIPTION,
                UCK.PACKAGE,
                UCK.QUANTITY,
                UCK.UNITPRICE,
                UCK.TAXRATE,
                UCK.TOTALEXCLUDINGTAX,
                UCK.TAXAMOUNT,
                UCK.TOTALINCLUDINGTAX,
                UCK.LASTMODIFIEDWHEN,
                UCK.STOCKITEMID,
                UCK.SALESPERSONPERSONID,
                UCK.PICKEDBYPERSONID
            From UPDATE_CUSTOMERKEY as UCK 
        LEFT JOIN ORDERS.ORDERS_SILVER.CITY as CT on CT.WWICITYID = UCK.DELIVERYCITYID
        AND UCK.LASTMODIFIEDWHEN > CT.ValidFrom
        AND UCK.LASTMODIFIEDWHEN <= CT.ValidTo
    ),

    UPDATE_SALESPERSONKEY AS (
        SELECT  EMP.EMPLOYEEKEY as SALESPERSONKEY,
                UCIK.CUSTOMERKEY,
                UCIK.CITYKEY,
                UCIK.ORDERDATEKEY,
                UCIK.PICKEDDATEKEY,
                UCIK.WWIORDERID,
                UCIK.WWIBACKORDERID,
                UCIK.DESCRIPTION,
                UCIK.PACKAGE,
                UCIK.QUANTITY,
                UCIK.UNITPRICE,
                UCIK.TAXRATE,
                UCIK.TOTALEXCLUDINGTAX,
                UCIK.TAXAMOUNT,
                UCIK.TOTALINCLUDINGTAX,
                UCIK.LASTMODIFIEDWHEN,
                UCIK.STOCKITEMID,
                UCIK.PICKEDBYPERSONID
            From UPDATE_CITYKEY as UCIK 
        LEFT JOIN ORDERS.ORDERS_SILVER.EMPLOYEE as EMP on EMP.WWIEMPLOYEEID = UCIK.SALESPERSONPERSONID
        AND UCIK.LASTMODIFIEDWHEN > EMP.ValidFrom
        AND UCIK.LASTMODIFIEDWHEN <= EMP.ValidTo
    ),

    UPDATE_PICKERKEY AS (
        SELECT  EX.EMPLOYEEKEY as PICKERKEY,
                USPK.CUSTOMERKEY,
                USPK.CITYKEY,
                USPK.SALESPERSONKEY,
                USPK.ORDERDATEKEY,
                USPK.PICKEDDATEKEY,
                USPK.WWIORDERID,
                USPK.WWIBACKORDERID,
                USPK.DESCRIPTION,
                USPK.PACKAGE,
                USPK.QUANTITY,
                USPK.UNITPRICE,
                USPK.TAXRATE,
                USPK.TOTALEXCLUDINGTAX,
                USPK.TAXAMOUNT,
                USPK.TOTALINCLUDINGTAX,
                USPK.LASTMODIFIEDWHEN,
                USPK.STOCKITEMID
            From UPDATE_SALESPERSONKEY as USPK
        LEFT JOIN ORDERS.ORDERS_SILVER.EMPLOYEE as EX on EX.WWIEMPLOYEEID = USPK.PICKEDBYPERSONID
        AND USPK.LASTMODIFIEDWHEN > EX.ValidFrom
        AND USPK.LASTMODIFIEDWHEN <= EX.ValidTo
    ),

    COMPLETE_FACT_ORDERS AS (
        SELECT  SI.STOCKITEMKEY,
                UPK.CUSTOMERKEY,
                UPK.CITYKEY,
                UPK.SALESPERSONKEY,
                UPK.PICKERKEY,
                UPK.ORDERDATEKEY,
                UPK.PICKEDDATEKEY,
                UPK.WWIORDERID,
                UPK.WWIBACKORDERID,
                UPK.DESCRIPTION,
                UPK.PACKAGE,
                UPK.QUANTITY,
                UPK.UNITPRICE,
                UPK.TAXRATE,
                UPK.TOTALEXCLUDINGTAX,
                UPK.TAXAMOUNT,
                UPK.TOTALINCLUDINGTAX,
                UPK.LASTMODIFIEDWHEN
            From UPDATE_PICKERKEY as UPK
        LEFT JOIN ORDERS.ORDERS_SILVER.STOCKITEM as SI on SI.WWISTOCKITEMID = UPK.STOCKITEMID
        AND UPK.LASTMODIFIEDWHEN > SI.ValidFrom
        AND UPK.LASTMODIFIEDWHEN <= SI.ValidTo
    )

SELECT WWIORDERID FROM COMPLETE_FACT_ORDERS
order by WWIORDERID asc
);

-- INSERT STAGE
INSERT INTO ORDERS.ORDERS_SILVER.ORDERS (
    CITYKEY,
	CUSTOMERKEY,
    STOCKITEMKEY,
    ORDERDATEKEY,
    PICKEDDATEKEY,
    SALESPERSONKEY,
    PICKERKEY,
    WWIORDERID,
    WWIBACKORDERID,
    DESCRIPTION,
    PACKAGE,
    QUANTITY,
    UNITPRICE,
    TAXRATE,
    TOTALEXCLUDINGTAX,
    TAXAMOUNT,
    TOTALINCLUDINGTAX
)

WITH FACT_ORDERS AS (
        SELECT si.STOCKITEMID
        , cus.DELIVERYCITYID
        , o.ORDERDATE AS ORDERDATEKEY
        , o.PICKINGCOMPLETEDWHEN AS PICKEDDATEKEY
        , o.ORDERID AS WWIORDERID
        , o.BACKORDERORDERID AS WWIBACKORDERID
        , o.SALESPERSONPERSONID
        , o.PICKEDBYPERSONID
        , O.CUSTOMERID
        , orl.DESCRIPTION
        , pck.PACKAGETYPENAME AS PACKAGE
        , orl.QUANTITY
        , orl.UNITPRICE
        , orl.TAXRATE
        , ROUND(orl.Quantity * orl.UnitPrice, 2) AS TOTALEXCLUDINGTAX
        , ROUND(orl.Quantity * orl.UnitPrice * orl.TaxRate / 100.0, 2) AS TAXAMOUNT
        , ROUND(orl.Quantity * orl.UnitPrice, 2) + ROUND(orl.Quantity * orl.UnitPrice * orl.TaxRate / 100.0, 2) AS TOTALINCLUDINGTAX
        , CASE WHEN orl.LASTEDITEDWHEN > o.LASTEDITEDWHEN THEN orl.LASTEDITEDWHEN 
        ELSE o.LASTEDITEDWHEN END AS LASTMODIFIEDWHEN

        FROM ORDERS.ORDERS_BRONZE.ORDERLINES AS orl
        
        LEFT JOIN ORDERS.ORDERS_BRONZE.ORDERS AS o ON orl.ORDERID = o.ORDERID

        LEFT JOIN ORDERS.ORDERS_BRONZE.PACKAGETYPES AS pck ON orl.PACKAGETYPEID = pck.PACKAGETYPEID
        AND LASTMODIFIEDWHEN > pck.ValidFrom
        AND LASTMODIFIEDWHEN <= pck.ValidTo

        LEFT JOIN ORDERS.ORDERS_BRONZE.CUSTOMERS AS cus ON o.CUSTOMERID = cus.CUSTOMERID
        AND LASTMODIFIEDWHEN > cus.ValidFrom
        AND LASTMODIFIEDWHEN <= cus.ValidTo

        LEFT JOIN ORDERS.ORDERS_BRONZE.STOCKITEMS AS si ON orl.STOCKITEMID = si.STOCKITEMID
        AND LASTMODIFIEDWHEN > si.ValidFrom
        AND LASTMODIFIEDWHEN <= si.ValidTo
    ),

    UPDATE_CUSTOMERKEY AS (
        SELECT CTM.CUSTOMERKEY,
                A.ORDERDATEKEY,
                A.PICKEDDATEKEY,
                A.WWIORDERID,
                A.WWIBACKORDERID,
                A.DESCRIPTION,
                A.PACKAGE,
                A.QUANTITY,
                A.UNITPRICE,
                A.TAXRATE,
                A.TOTALEXCLUDINGTAX,
                A.TAXAMOUNT,
                A.TOTALINCLUDINGTAX,
                A.LASTMODIFIEDWHEN,
                A.DELIVERYCITYID,
                A.STOCKITEMID,
                A.SALESPERSONPERSONID,
                A.PICKEDBYPERSONID
            FROM FACT_ORDERS AS A
        LEFT JOIN ORDERS.ORDERS_SILVER.CUSTOMER AS CTM ON CTM.WWICUSTOMERID = A.CUSTOMERID
        AND A.LASTMODIFIEDWHEN > CTM.ValidFrom
        AND A.LASTMODIFIEDWHEN <= CTM.ValidTo
    ),

    UPDATE_CITYKEY as (
        SELECT  CT.CITYKEY,
                UCK.CUSTOMERKEY,
                UCK.ORDERDATEKEY,
                UCK.PICKEDDATEKEY,
                UCK.WWIORDERID,
                UCK.WWIBACKORDERID,
                UCK.DESCRIPTION,
                UCK.PACKAGE,
                UCK.QUANTITY,
                UCK.UNITPRICE,
                UCK.TAXRATE,
                UCK.TOTALEXCLUDINGTAX,
                UCK.TAXAMOUNT,
                UCK.TOTALINCLUDINGTAX,
                UCK.LASTMODIFIEDWHEN,
                UCK.STOCKITEMID,
                UCK.SALESPERSONPERSONID,
                UCK.PICKEDBYPERSONID
            From UPDATE_CUSTOMERKEY as UCK 
        LEFT JOIN ORDERS.ORDERS_SILVER.CITY as CT on CT.WWICITYID = UCK.DELIVERYCITYID
        AND UCK.LASTMODIFIEDWHEN > CT.ValidFrom
        AND UCK.LASTMODIFIEDWHEN <= CT.ValidTo
    ),

    UPDATE_SALESPERSONKEY AS (
        SELECT  EMP.EMPLOYEEKEY as SALESPERSONKEY,
                UCIK.CUSTOMERKEY,
                UCIK.CITYKEY,
                UCIK.ORDERDATEKEY,
                UCIK.PICKEDDATEKEY,
                UCIK.WWIORDERID,
                UCIK.WWIBACKORDERID,
                UCIK.DESCRIPTION,
                UCIK.PACKAGE,
                UCIK.QUANTITY,
                UCIK.UNITPRICE,
                UCIK.TAXRATE,
                UCIK.TOTALEXCLUDINGTAX,
                UCIK.TAXAMOUNT,
                UCIK.TOTALINCLUDINGTAX,
                UCIK.LASTMODIFIEDWHEN,
                UCIK.STOCKITEMID,
                UCIK.PICKEDBYPERSONID
            From UPDATE_CITYKEY as UCIK 
        LEFT JOIN ORDERS.ORDERS_SILVER.EMPLOYEE as EMP on EMP.WWIEMPLOYEEID = UCIK.SALESPERSONPERSONID
        AND UCIK.LASTMODIFIEDWHEN > EMP.ValidFrom
        AND UCIK.LASTMODIFIEDWHEN <= EMP.ValidTo
    ),

    UPDATE_PICKERKEY AS (
        SELECT  EX.EMPLOYEEKEY as PICKERKEY,
                USPK.CUSTOMERKEY,
                USPK.CITYKEY,
                USPK.SALESPERSONKEY,
                USPK.ORDERDATEKEY,
                USPK.PICKEDDATEKEY,
                USPK.WWIORDERID,
                USPK.WWIBACKORDERID,
                USPK.DESCRIPTION,
                USPK.PACKAGE,
                USPK.QUANTITY,
                USPK.UNITPRICE,
                USPK.TAXRATE,
                USPK.TOTALEXCLUDINGTAX,
                USPK.TAXAMOUNT,
                USPK.TOTALINCLUDINGTAX,
                USPK.LASTMODIFIEDWHEN,
                USPK.STOCKITEMID
            From UPDATE_SALESPERSONKEY as USPK
        LEFT JOIN ORDERS.ORDERS_SILVER.EMPLOYEE as EX on EX.WWIEMPLOYEEID = USPK.PICKEDBYPERSONID
        AND USPK.LASTMODIFIEDWHEN > EX.ValidFrom
        AND USPK.LASTMODIFIEDWHEN <= EX.ValidTo
    ),

    COMPLETE_FACT_ORDERS AS (
        SELECT  SI.STOCKITEMKEY,
                UPK.CUSTOMERKEY,
                UPK.CITYKEY,
                UPK.SALESPERSONKEY,
                UPK.PICKERKEY,
                UPK.ORDERDATEKEY,
                UPK.PICKEDDATEKEY,
                UPK.WWIORDERID,
                UPK.WWIBACKORDERID,
                UPK.DESCRIPTION,
                UPK.PACKAGE,
                UPK.QUANTITY,
                UPK.UNITPRICE,
                UPK.TAXRATE,
                UPK.TOTALEXCLUDINGTAX,
                UPK.TAXAMOUNT,
                UPK.TOTALINCLUDINGTAX,
                UPK.LASTMODIFIEDWHEN
            From UPDATE_PICKERKEY as UPK
        LEFT JOIN ORDERS.ORDERS_SILVER.STOCKITEM as SI on SI.WWISTOCKITEMID = UPK.STOCKITEMID
        AND UPK.LASTMODIFIEDWHEN > SI.ValidFrom
        AND UPK.LASTMODIFIEDWHEN <= SI.ValidTo
    )

    SELECT 
        CITYKEY,
        CUSTOMERKEY,
        STOCKITEMKEY,
        ORDERDATEKEY,
        PICKEDDATEKEY,
        SALESPERSONKEY,
        PICKERKEY,
        WWIORDERID,
        WWIBACKORDERID,
        DESCRIPTION,
        PACKAGE,
        QUANTITY,
        UNITPRICE,
        TAXRATE,
        TOTALEXCLUDINGTAX,
        TAXAMOUNT,
        TOTALINCLUDINGTAX
    FROM COMPLETE_FACT_ORDERS
