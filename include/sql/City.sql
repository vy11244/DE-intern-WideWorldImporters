(SELECT [CityID]
      ,[CityName]
      ,[StateProvinceID]
      ,[Location].STAsText() AS [Location]
      ,[LatestRecordedPopulation]
      ,[LastEditedBy]
      ,CAST([ValidFrom] AS VARCHAR(30)) AS [ValidFrom]
      ,CAST([ValidTo] AS VARCHAR(30)) AS [ValidTo]
FROM [WideWorldImporters].[Application].[Cities_Archive]
WHERE ValidFrom <> ValidTo)
union all
(SELECT [CityID]
      ,[CityName]
      ,[StateProvinceID]
      ,[Location].STAsText() AS [Location]
      ,[LatestRecordedPopulation]
      ,[LastEditedBy]
      ,CAST([ValidFrom] AS VARCHAR(30)) AS [ValidFrom]
      ,CAST([ValidTo] AS VARCHAR(30)) AS [ValidTo]
FROM [WideWorldImporters].[Application].[Cities]
WHERE ValidFrom <> ValidTo)