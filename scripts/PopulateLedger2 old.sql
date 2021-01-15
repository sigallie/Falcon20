USE [Newfalcon20]
GO
/****** Object:  StoredProcedure [dbo].[PopulateLedger2]    Script Date: 2020/12/15 9:48:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Gibson Mhlanga
-- Create date: 15 Dec 2020
-- Description:	Populates Ledger Report 
-- =============================================
ALTER PROCEDURE [dbo].[PopulateLedger2]  -- PopulateLedger 'ADEPT','157','20111231','20121209'
	@Login varchar(50)
	,@ClientNo varchar(50)
	,@StartDate datetime
	,@EndDate datetime
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	SET NOCOUNT ON;
	declare @OB decimal(31,9)
	declare @CB decimal(31,9) 
	declare @EndDate1 datetime
	declare @CBOB decimal(31,9)
	declare @OldTxnsBalance float=0
	declare @OldLedgerBalance float=0
	
	declare @LedgerTxns as varchar(50)
	declare @LastTxnDate as datetime
	declare @LedgerPayments as varchar(50)
	declare @ReportName varchar(300)
	
	set @LastTxnDate='20110430' --last date for old Falcon transactions
	
	delete from tblLedgerTemp where [login] = @Login
	/*
	select @EndDate1=DATEADD(d,1,@enddate)
	delete from tblLedgerTemp where [login]=@Login
	delete from tblLedger where [login]=@Login
	
	if(@ClientNo='152')
	begin
	
		select @LedgerTxns='sduty'
		select @LedgerPayments='sdd'
		select @ReportName='Stamp Duty Report'
	end
	if(@ClientNo='158')
	begin
		select @LedgerTxns='bfee'
		select @LedgerPayments='bfeed'
		select @ReportName='Basic Charge Report'
	end	
	if(@ClientNo='151')
	begin
		select @LedgerTxns='vat'
		select @LedgerPayments='vat'
		select @ReportName='Value Added Tax (VAT) Report'
	end
	if(@ClientNo='154')
	begin
		select @LedgerTxns='captax'
		select @LedgerPayments='captax'
		select @ReportName='Capital Gains Tax Report'
	end
	if(@ClientNo='155')
	begin
		select @LedgerTxns='invprot'
		select @LedgerPayments='invprot'
		select @ReportName='Investor Protection Report'
	end

	if(@ClientNo='153')
	begin
		select @LedgerTxns='zselv'
		select @LedgerPayments='zselv'
		select @ReportName='ZSE Levy Report'
	end
	if(@ClientNo='156')
	begin
		select @LedgerTxns='commlv'
		select @LedgerPayments='commlv'
		select @ReportName='S.E.C. Levy Report'
	end
	if(@ClientNo='150')
	begin
		select @LedgerTxns='comms'
		select @LedgerPayments='comms'
		select @ReportName='Commission Report'
	end
	if(@ClientNo='157')
	begin
		select @LedgerTxns='NMI'
		select @LedgerPayments='NMI'
		select @ReportName='NMI Commission Rebate Report'
	end
	
	if(@ClientNo='159')
	begin
		select @LedgerTxns='CSD'
		select @LedgerPayments='CSD'
		select @ReportName='CSD Levy Report'
	end
	
	----------------------------------------------------------------------------------------------------------------------------------
	--1. calculating ledger balance from old falcon.
	select @OldTxnsBalance=SUM(amount) from cashbooktrans where (TRANSCODE like @LedgerPayments+'%') and transdate >= '20190401' and transdate<=@LastTxnDate and clientno = @clientno
	select @OldLedgerBalance=SUM(amount) from Transactions where yon=1 and (TRANSCODE like @LedgerTxns+'%') and transdate >= '20190401' and  transdate<=@LastTxnDate and clientno = @clientno
	and ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker')
	if @OldLedgerBalance is null
		select @OldLedgerBalance=0
	if @OldTxnsBalance is null
		select @OldtxnsBalance=0
	-----------------------------------------------------------------------------------------------------------------------------------
	
    --2. get data from nominal ledger
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select d.ClientNo,x.PostDate,x.DealNo,x.TransDate,x.[Description],x.Amount,@Login,d.consideration,@Reportname,@StartDate,@EndDate
	from transactions x  inner join dealallocations d on x.dealno = d.dealno
    where x.YON=1 and d.yon=1 and(TRANSCODE like(@LedgerTxns+'%') and (x.TransDate>=@StartDate and x.TransDate<=@EndDate))
    and (x.ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker'))
	and x.clientno = @clientno
    order by x.TransDate 

	--3. insert tax payments
	insert into tblLedgerTemp(ClientNo,PostDate,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select x.ClientNo,x.PostDate,x.TransDate,@LedgerTxns+' TAX PAYMENT',-x.Amount,@Login,0,@Reportname,@StartDate,@EndDate
	from transactions x  
    where x.YON=1 and(TRANSCODE like(@LedgerTxns+'%DUE%') and (x.TransDate>=@StartDate and x.TransDate<=@EndDate))
    and (x.ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker'))
	and x.clientno = @clientno
    order by x.TransDate 
    
    
    update tblLedgerTemp set Consideration=-Consideration where [Description] like '%cancellation'
    delete from tblLedgerTemp where Amount=0
   
       
    --4. get data from cashbook 
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],ReportName,StartDate,EndDate)
    select ClientNo,PostDate,DealNo,TransDate,[Description],-Amount,@Login,@ReportName,@StartDate,@EndDate 
	from CASHBOOKTRANS     
    where (TransDate>=@StartDate and TransDate<@EndDate1)--TRANSCODE like(@LedgerPayments+'%') and 
	and clientno = @ClientNo
	order by TransDate
    
    
    
    --5. get Opening Balance (OB) from nominal ledger and cashbook
    select @OB = sum(amount) from transactions
	--where ClientNo=@ClientNo and TransDate < @StartDate 
	where TRANSCODE like(@LedgerTxns+'%')and TransDate < @StartDate and transdate >= '20190401'
	and (ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker'))
	and clientno = @Clientno

	if (@OB is null)
		select @OB=0
		
	select @CBOB = sum(amount) from CASHBOOKTRANS
	--where ClientNo=@ClientNo and TransDate < @StartDate
	where TRANSCODE like(@LedgerPayments+'%')and TransDate < @StartDate and transdate >= '20190401'

	if (@CBOB is null)
		select @CBOB=0
		
	select @OB=@OB+@CBOB--+(@OldTxnsBalance+@OldLedgerBalance)	
	
	--6. get Closing Balance (CB) from nominal ledger and cashbook
	select @CB = @OB+sum(amount) from tblLedgerTemp
	where Login=@Login--TransDate < @StartDate and TransDate<@EndDate1
	if (@CB is null)
		select @CB=0
	
insert into tblLedger(ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate, BalBF, BalCF)
select ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate,@OB,@CB from tblLedgerTemp where [LOGIN]  =@Login order by TransDate,[Description]
    
    if (@ClientNo='157')
    begin
    drop table tblLedgerNames
    SELECT     distinct dbo.tblLedger.DealNo, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName
	into tblLedgerNames
	FROM         dbo.DEALALLOCATIONS INNER JOIN
                      dbo.tblLedger ON dbo.DEALALLOCATIONS.DealNo = dbo.tblLedger.DealNo INNER JOIN
                      dbo.CLIENTS ON dbo.DEALALLOCATIONS.ClientNo = dbo.CLIENTS.ClientNo;
               
                      
    merge into tblledger
	using tblLedgerNames
	on tblLedgerNames.dealno = tblLedger.dealno 
	when matched --and(tblledger.amount>0) and (tblledger.dealno is not null)

	then
	update set tblledger.ClientName=tblLedgerNames.ClientName;
	end
END
*/
--insert tax transactions
insert into tblLedger(ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate, BalBF, BalCF)
select x.clientno, x.postdate, x.dealno, x.transdate, x.[description], x.amount, d.dealvalue, x.[login], d.consideration, '', @StartDate, @EndDate1, 0, 0
from transactions x inner join dealallocations d on x.DealNo = d.DealNo
--where x.clientno = @ClientNo