/*
  The query is done to convert from bronze data into silver data
     Database: WideWorldImporters
     Module: MOVEMENT
     Contributed Bronze Table: MOVEMENT.MOVEMENT_BRONZE.STOCKITEMS,
     MOVEMENT.MOVEMENT_BRONZE.COLORS, MOVEMENT.MOVEMENT_BRONZE.PACKAGETYPES
     Silver table: MOVEMENT.MOVEMENT_SILVER.STOCKITEM
     Done by: DuyNVT4
     Last update when: 2024-03-21 15:20:00.0000000
     Update content: add cmt 
*/


TRUNCATE TABLE MOVEMENT.MOVEMENT_SILVER.STOCKITEM;


INSERT INTO MOVEMENT.MOVEMENT_SILVER.STOCKITEM (
    StockItemKey,
    WWIStockItemID,
    StockItem,
    Color,
    SellingPackage,
    BuyingPackage,
    Brand,
    Size,
    LeadTimeDays,
    QuantityPerOuter,
    IsChillerStock,
    Barcode,
    TaxRate,
    UnitPrice,
    RECOMMENDEDRETAILPRICE,
    TypicalWeightPerUnit,
    Photo,
    ValidFrom,
    ValidTo
)
WITH a AS (

    SELECT
        S.StockItemID,
        S.StockItemName,
        C.ColorName,
        S.UNITPACKAGEID,
        S.OUTERPACKAGEID,
        S.Brand AS Brand,
        S.Size AS Size,
        S.LEADTIMEDAYS AS LeadTimeDays,
        S.QUANTITYPEROUTER AS QuantityPerOuter,
        S.ISCHILLERSTOCK AS IsChillerStock,
        S.BARCODE AS Barcode,
        S.TAXRATE AS TaxRate,
        S.UNITPRICE AS UnitPrice,
        S.RECOMMENDEDRETAILPRICE AS RECOMMENDEDRETAILPRICE,
        S.TYPICALWEIGHTPERUNIT AS TypicalWeightPerUnit,
        S.PHOTO AS Photo,
        CASE
            WHEN S.COLORID IS NOT NULL THEN (
                CASE WHEN S.ValidFrom < C.ValidFrom THEN C.ValidFrom ELSE S.ValidFrom END
            )
            ELSE S.ValidFrom
        END AS ValidFrom,
        CASE
            WHEN S.COLORID IS NOT NULL THEN (
                CASE WHEN S.ValidTo < C.ValidTo THEN S.ValidTo ELSE C.ValidTo END
            )
            ELSE S.ValidTo
        END AS ValidTo
    FROM
        MOVEMENT.MOVEMENT_BRONZE.STOCKITEMS AS S 
        LEFT JOIN MOVEMENT.MOVEMENT_BRONZE.COLORS AS C ON S.COLORID = C.COLORID AND S.VALIDFROM < C.VALIDTO AND S.VALIDTO > C.VALIDFROM
),
b AS (
    SELECT 
        a.StockItemID AS WWIStockItemID,
        a.StockItemName AS StockItem,
        a.ColorName AS Color,
        P1.PackageTypeName AS SellingPackage,
        a.OUTERPACKAGEID,
        a.Brand,
        a.Size,
        a.LeadTimeDays,
        a.QuantityPerOuter,
        a.IsChillerStock,
        a.Barcode,
        a.TaxRate,
        a.UnitPrice,
        a.RecommendedRetailPrice,
        a.TypicalWeightPerUnit,
        a.Photo,
        CASE WHEN a.UNITPACKAGEID IS NOT NULL THEN (
            CASE WHEN a.ValidFrom < P1.ValidFrom THEN P1.ValidFrom ELSE a.ValidFrom END
        )
        ELSE a.ValidFrom END AS ValidFrom,
        CASE WHEN a.UNITPACKAGEID IS NOT NULL THEN (
            CASE WHEN a.ValidTo < P1.ValidTo THEN a.ValidTo ELSE P1.ValidTo END
        )
        ELSE a.ValidTo END AS ValidTo
    FROM 
        a
    LEFT JOIN MOVEMENT.MOVEMENT_BRONZE.PACKAGETYPES AS P1 ON a.UNITPACKAGEID = P1.PACKAGETYPEID AND a.VALIDFROM < P1.ValidTo AND a.VALIDTO > P1.ValidFrom
),
c AS (
    SELECT   
        b.WWIStockItemID,
        b.StockItem,
        b.Color,
        b.SellingPackage,
        P2.PackageTypeName AS BuyingPackage,
        b.Brand,
        b.Size,
        b.LeadTimeDays,
        b.QuantityPerOuter,
        b.IsChillerStock,
        b.Barcode,
        b.TaxRate,
        b.UnitPrice,
        b.RecommendedRetailPrice,
        b.TypicalWeightPerUnit,
        b.Photo,
        CASE WHEN b.OUTERPACKAGEID IS NOT NULL THEN (
            CASE WHEN b.ValidFrom < P2.ValidFrom THEN P2.ValidFrom ELSE b.ValidFrom END
        )
        ELSE b.ValidFrom END AS ValidFrom,
        CASE WHEN b.OUTERPACKAGEID IS NOT NULL THEN (
            CASE WHEN b.ValidTo < P2.ValidTo THEN b.ValidTo ELSE P2.ValidTo END
        )
        ELSE b.ValidTo END AS ValidTo
    FROM 
        b
    LEFT JOIN MOVEMENT.MOVEMENT_BRONZE.PACKAGETYPES AS P2 ON b.OUTERPACKAGEID = P2.PACKAGETYPEID AND b.VALIDFROM < P2.ValidTo AND b.VALIDTO > P2.ValidFrom
)
SELECT
    CONCAT(c.WWIStockItemID, TO_CHAR(c.ValidFrom, 'YYYYMMDDHH24MISSFF7')) AS StockItemKey,
    c.WWIStockItemID AS WWIStockItemID,
    c.StockItem AS StockItem,
    c.Color AS Color,
    c.SellingPackage,
    c.BuyingPackage,
    c.Brand,
    c.Size,
    c.LeadTimeDays,
    c.QuantityPerOuter,
    c.IsChillerStock,
    c.Barcode,
    c.TaxRate,
    c.UnitPrice,
    c.RecommendedRetailPrice,
    c.TypicalWeightPerUnit,
    c.Photo,
    c.ValidFrom,
    c.ValidTo
FROM 
    c;