  SELECT [OrderLineID]
      ,[OrderID]
      ,[StockItemID]
      ,[Description]
      ,[PackageTypeID]
      ,[Quantity]
      ,[UnitPrice]
      ,[TaxRate]
      ,[PickedQuantity]
      ,CAST (PickingCompletedWhen AS VARCHAR(30)) AS PickingCompletedWhen
      ,[LastEditedBy]
      ,CAST ([LastEditedWhen] AS VARCHAR(30)) AS LastEditedWhen
FROM {table_name}
WHERE CAST([LastEditedWhen] AS datetime2(0)) >= '{last_execution_date}'