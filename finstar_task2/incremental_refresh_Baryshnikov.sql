CREATE PROCEDURE incremental_refresh

AS
BEGIN
	
	SET NOCOUNT ON;
	--если нет целевой таблицы, создадим еЄ
    IF NOT EXISTS (SELECT * FROM sys.tables t WHERE t.name = 'ntb_funnel_target')
		CREATE TABLE [dbo].[ntb_funnel_target](
			[TSApplicationId] [nvarchar](50) NOT NULL,
			[TSApplicationCreatedOn] [datetime2](7) NULL,
			[TSApplicationModifiedOn] [datetime2](7) NULL,
			[TSReasonForLoan] [nvarchar](50) NULL,
			[TSCustomerType] [nvarchar](50) NULL,
			[DisbursementType] [nvarchar](50) NULL,
			[TSApplicationStatus] [nvarchar](50) NULL,
			[Product] [nvarchar](50) NULL,
			[DecisionId] [nvarchar](50) NULL,
			[TSAppRejectionReason] [nvarchar](100) NULL,
			[DecisionCreatedOn] [nvarchar](50) NULL,
			[DecisionModifiedOn] [nvarchar](50) NULL,
			[TSAgreementId] [nvarchar](50) NULL,
			[TSAgreementCreatedOn] [nvarchar](50) NULL,
			[TSAgreementModifiedOn] [nvarchar](50) NULL,
			[TSAgreementStatus] [nvarchar](50) NULL,
			[ContactId] [nvarchar](50) NULL,
			[is_completed] [bit] NULL,
			[is_approved] [bit] NULL,
			[is_disbursed] [bit] NULL,
			[duplicatedTSApplication] [tinyint] NOT NULL,
			[is_post_decision_completed] [bit] NULL,
			[BanksListName] [nvarchar](max) NULL,
			[rep_date] [date] NULL,
			[step_name_1] [nvarchar](50) NULL,
			[status_code_1] [nvarchar](50) NULL,
			[step_name_2] [nvarchar](50) NULL,
			[status_code_2] [nvarchar](50) NULL,
			[step_name_3] [nvarchar](50) NULL,
			[status_code_3] [nvarchar](50) NULL,
		 CONSTRAINT [PK_ntb_funnel_target] PRIMARY KEY CLUSTERED 
		(
			[TSApplicationId] ASC,
			[duplicatedTSApplication] ASC
		))
	
	--ntb_funnel - таблица-источник (s - source), ntb_funnel_target - целева€ таблица
	MERGE ntb_funnel_target AS t
	USING (SELECT * FROM ntb_funnel) AS s
	ON t.TSApplicationId = s.TSApplicationId AND t.DecisionId = s.DecisionId
	--≈сли совпадают пол€, обновл€ем флаг дубликата (согласно полученной в ходе анализа логике мен€етс€ лишь этот флаг, данные о новом решении - в новой строке с новым DecisionId)
	WHEN MATCHED AND t.duplicatedTSApplication != s.duplicatedTSApplication THEN UPDATE SET	t.duplicatedTSApplication = s.duplicatedTSApplication
	--≈сли нет совпадающих (по услови€м) строк, добавл€ем новые из источника
	WHEN NOT MATCHED THEN INSERT VALUES (s.TSApplicationId,
		s.TSApplicationCreatedOn,
		s.TSApplicationModifiedOn,
		s.TSReasonForLoan,
		s.TSCustomerType,
		s.DisbursementType,
		s.TSApplicationStatus,
		s.Product,
		s.DecisionId,
		s.TSAppRejectionReason,
		s.DecisionCreatedOn,
		s.DecisionModifiedOn,
		s.TSAgreementId,
		s.TSAgreementCreatedOn,
		s.TSAgreementModifiedOn,
		s.TSAgreementStatus,
		s.ContactId,
		s.is_completed,
		s.is_approved,
		s.is_disbursed,
		s.duplicatedTSApplication,
		s.is_post_decision_completed,
		s.BanksListName,
		s.rep_date,
		s.step_name_1,
		s.status_code_1,
		s.step_name_2,
		s.status_code_2,
		s.step_name_3,
		s.status_code_3)
	--¬ывести изменени€
	OUTPUT $action, inserted.*, deleted.*;
END
GO

--выполнить процедуру
exec incremental_refresh