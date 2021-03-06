USE [PlanetmansDbContext];
GO

SET NOCOUNT ON;

IF EXISTS ( SELECT *
              FROM INFORMATION_SCHEMA.TABLES
              WHERE TABLE_NAME = N'FacilityType' )
BEGIN
    
  CREATE TABLE #Staging_FacilityType
    ( Id          int NOT NULL,
      Description nvarchar(max) );

  INSERT INTO #Staging_FacilityType VALUES
    ( 1, N'Default' ),
    ( 2, N'Amp Station' ),
    ( 3, N'Bio Lab' ),
    ( 4, N'Tech Plant' ),
    ( 5, N'Large Outpost' ),
    ( 6, N'Small Outpost' ),
    ( 7, N'Warpgate' ),
    ( 8, N'Interlink Facility' ),
    ( 9, N'Construction Outpost' ),
    ( 10, N'Relic Outpost (Desolation)' );
  
  MERGE [dbo].[FacilityType] as target
    USING ( SELECT Id, Description FROM #Staging_FacilityType ) as source
      ON ( target.Id = source.Id )
    WHEN MATCHED THEN
      UPDATE SET Description = source.Description
    WHEN NOT MATCHED THEN
      INSERT ( [Id], [Description] )
      VALUES ( source.Id, source.Description );

  DROP TABLE #Staging_FacilityType;

END;