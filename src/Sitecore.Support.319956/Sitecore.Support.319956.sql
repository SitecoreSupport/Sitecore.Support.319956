IF type_id('[dbo].[Personalization_Type]') IS NULL

BEGIN

CREATE TYPE [dbo].[Personalization_Type] AS TABLE (
	[Date] [date] NOT NULL,
	[RuleSetId] [uniqueidentifier] NOT NULL,
	[RuleId] [uniqueidentifier] NOT NULL,
	[TestSetId] [uniqueidentifier] NOT NULL,
	[TestValues] [binary](16) NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[Visits] [bigint] NOT NULL,
	[Value] [bigint] NOT NULL,
	[Visitors] [bigint] NOT NULL
)

END

IF type_id('[dbo].[RulesExposure_Type]') IS NULL

BEGIN

CREATE TYPE [dbo].[RulesExposure_Type] AS TABLE (
	[Date] [datetime] NULL,
	[ItemId] [uniqueidentifier] NOT NULL,
	[RuleSetId] [uniqueidentifier] NOT NULL,
	[RuleId] [uniqueidentifier] NOT NULL,
	[Visits] [bigint] NOT NULL,
	[Visitors] [bigint] NOT NULL
)

END

IF EXISTS ( SELECT * 
			FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[Add_RulesExposure_Tvp]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[Add_RulesExposure_Tvp]
END

GO

CREATE PROCEDURE [dbo].[Add_RulesExposure_Tvp]
  @table [dbo].[RulesExposure_Type] READONLY
WITH EXECUTE AS OWNER
AS
BEGIN

  SET NOCOUNT ON;
  
  BEGIN TRY

  MERGE
	[Fact_RulesExposure] AS TARGET
  USING(
	SELECT
	   [Date]
	  ,[ItemId]
	  ,[RuleSetId]
	  ,[RuleId]
	  ,SUM([Visits]) as [Visits]
	  ,SUM([Visitors]) as [Visitors]
	FROM @table
	GROUP BY   
	   [Date]
	  ,[ItemId]
	  ,[RuleSetId]
	  ,[RuleId]
	)
  AS SOURCE
  ON
	(TARGET.[Date] = SOURCE.[Date]) AND
	(TARGET.[ItemId] = SOURCE.[ItemId]) AND
	(TARGET.[RuleSetId] = SOURCE.[RuleSetId]) AND
	(TARGET.[RuleId] = SOURCE.[RuleId]) 

  WHEN MATCHED THEN
	UPDATE
	  SET
		TARGET.[Visits] = (TARGET.[Visits] + SOURCE.[Visits]),
		TARGET.[Visitors] = (TARGET.[Visitors] + SOURCE.[Visitors])

  WHEN NOT MATCHED THEN
	INSERT
	(
	  [Date],
	  [ItemId],
	  [RuleSetId],
	  [RuleId],
	  [Visits],
	  [Visitors]
	)
	VALUES
	(
	  SOURCE.[Date],
	  SOURCE.[ItemId],
	  SOURCE.[RuleSetId],
	  SOURCE.[RuleId],
	  SOURCE.[Visits],
	  SOURCE.[Visitors]
	);
  END TRY
  BEGIN CATCH
	DECLARE @error_number INTEGER = ERROR_NUMBER();
	DECLARE @error_severity INTEGER = ERROR_SEVERITY();
	DECLARE @error_state INTEGER = ERROR_STATE();
	DECLARE @error_message NVARCHAR(4000) = ERROR_MESSAGE();
	DECLARE @error_procedure SYSNAME = ERROR_PROCEDURE();
	DECLARE @error_line INTEGER = ERROR_LINE();
	RAISERROR( N'T-SQL ERROR %d, SEVERITY %d, STATE %d, PROCEDURE %s, LINE %d, MESSAGE: %s', @error_severity, 1, @error_number, @error_severity, @error_state, @error_procedure, @error_line, @error_message ) WITH NOWAIT;
  END CATCH;

END

GO

IF EXISTS ( SELECT * 
			FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[Add_Personalization_Tvp]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[Add_Personalization_Tvp]
END

GO

CREATE PROCEDURE [dbo].[Add_Personalization_Tvp]
  @table [dbo].[Personalization_Type] READONLY
WITH EXECUTE AS OWNER
AS
BEGIN

  SET NOCOUNT ON;
  
  BEGIN TRY

  MERGE
	[Fact_Personalization] AS TARGET
	USING (
	  Select 
	   [Date]
	  ,[RuleSetId]
	  ,[RuleId]
	  ,[TestSetId]
	  ,[TestValues]
	  ,[IsDefault]
	  ,SUM([Visits]) as [Visits]
	  ,SUM([Value]) as [Value]
	  ,SUM([Visitors]) as [Visitors]
	FROM @table
	GROUP BY 
	   [Date]
	  ,[RuleSetId]
	  ,[RuleId]
	  ,[TestSetId]
	  ,[TestValues]
	  ,[IsDefault]
	)
  AS SOURCE
  ON
	(TARGET.[Date] = SOURCE.[Date]) AND
	(TARGET.[RuleSetId] = SOURCE.[RuleSetId]) AND
	(TARGET.[RuleId] = SOURCE.[RuleId]) AND
	(TARGET.[TestSetId] = SOURCE.[TestSetId]) AND
	(TARGET.[TestValues] = SOURCE.[TestValues]) AND
	(TARGET.[IsDefault] = SOURCE.[IsDefault])

  WHEN MATCHED THEN
	UPDATE
	  SET
		TARGET.[Visits] = (TARGET.[Visits] + SOURCE.[Visits]),
		TARGET.[Value] = (TARGET.[Value] + SOURCE.[Value]),
		TARGET.[Visitors] = (TARGET.[Visitors] + SOURCE.[Visitors])

  WHEN NOT MATCHED THEN
	INSERT
	(
	  [Date],
	  [RuleSetId],
	  [RuleId],
	  [TestSetId],
	  [TestValues],
	  [IsDefault],
	  [Visits],
	  [Value],
	  [Visitors]
	)
	VALUES
	(
	  SOURCE.[Date],
	  SOURCE.[RuleSetId],
	  SOURCE.[RuleId],
	  SOURCE.[TestSetId],
	  SOURCE.[TestValues],
	  SOURCE.[IsDefault],
	  SOURCE.[Visits],
	  SOURCE.[Value],
	  SOURCE.[Visitors]
	);
  END TRY
   BEGIN CATCH
	DECLARE @error_number INTEGER = ERROR_NUMBER();
	DECLARE @error_severity INTEGER = ERROR_SEVERITY();
	DECLARE @error_state INTEGER = ERROR_STATE();
	DECLARE @error_message NVARCHAR(4000) = ERROR_MESSAGE();
	DECLARE @error_procedure SYSNAME = ERROR_PROCEDURE();
	DECLARE @error_line INTEGER = ERROR_LINE();
	RAISERROR( N'T-SQL ERROR %d, SEVERITY %d, STATE %d, PROCEDURE %s, LINE %d, MESSAGE: %s', @error_severity, 1, @error_number, @error_severity, @error_state, @error_procedure, @error_line, @error_message ) WITH NOWAIT;
  END CATCH;
  
END;

GO

