USE [MMCNF1]
GO
/****** Object:  StoredProcedure [dbo].[spLedgerAccount]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[spLedgerAccount]
@USER VARCHAR(50),
@START DATETIME,
@END DATETIME,
@TRANSCODE VARCHAR(20)
AS
SET CONCAT_NULL_YIELDS_NULL OFF
delete from tblLedger
INSERT INTO [falcon].[dbo].[tblLedger]
           (TRANSDT,[transid]
           ,[description]
           ,[amount]
           ,[balbf]
           ,[balcf]
           ,[client]
           ,StartDate
           ,EndDate
           ,ledger)-- 
SELECT A.TRANSDT,a.[transid],A. [DESCRIPTION], AMOUNT, B.BALBF, B.BALCF, C.COMPANYNAME+' '+C.FIRSTNAME+' '+C.SURNAME AS CLIENT,
@START, @END, substring(@TRANSCODE, 1, 1) FROM TRANSACTIONS A INNER JOIN LEDGERS B ON A.TRANSCODE = B.TRANSCODE
INNER JOIN CLIENTS C ON A.CNO = C.CLIENTNO
WHERE A.TRANSDT >= @Start
AND A.TRANSDT <= @End
AND A.TRANSCODE LIKE @Transcode
AND B.[USER] = @User









GO
/****** Object:  StoredProcedure [dbo].[spPostCharge]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[spPostCharge]
@cno bigint,
@reqid bigint,
@user varchar(20)
as
declare @transcode varchar(10), @amount decimal(34,4), @desc varchar(50), @TransDate datetime

select @transcode = transcode, @amount = chqamt,
@TransDate = chqdt from suppchqs where chqid = @reqid

if @transcode like '%DUE'
begin
 select @desc = case @transcode
 when 'SDDUE' then 'STAMP DUTY DUE'
 when 'VATDUE' then 'VAT DUE'
 when 'WTAXDUE' then 'WITHHOLDING TAX DUE'
 when 'COMMLVDUE' then 'COMMISSIONER LEVY DUE'
 when 'CAPTAXDUE' then 'CAPITAL GAINS DUE'
 when 'INVPROTDUE' then 'INVESTOR PROTECTION DUE'
 when 'COMMDUE' then 'COMMISSION DUE' 
 else ''
 end

 exec Transact @user, @cno, '', @TransCode, @TransDate, @Desc,	@Amount
end 



GO
/****** Object:  StoredProcedure [dbo].[spPostDeal]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
	17-02-2019
	1.	insert deals (both client and broker deal) into dealallocations table
	2.	post the corresponding charges to the charges accounts
	3.	post the corresponding trade transaction to the transactions table
*/

CREATE procedure [dbo].[spPostDeal] -- exec spPostDeal '20190220', '4498MMC', 'SELL', 2581, 96, 'CAIRN-L', '121554', 'bug'
	@dealdate datetime, @clientno varchar(10), @dealtype varchar(10),
	@qty int, @price float, @asset varchar(10), @CSDNumber varchar(10)
	,@user varchar(30)
as
declare @dealno varchar(10), @consideration money, @dealvalue money
declare @category varchar(30), @CDC varchar(10), @charges float, @brokerdealtype varchar(10);

select @category = category from clients
where clientno = @clientno

select @consideration = @qty*@price/100

select @dealno = left(@dealtype, 1) +'/'+ cast(dbo.fnGetDealno() as varchar(10))

--if @category = 'BROKER'
--begin
--	insert into dealallocations (docketno,dealtype,dealno,dealdate,clientno,asset,qty,price,consideration,grosscommission,basiccharges,stampduty,login,approved,sharesout,certdueby,vat,capitalgains,investorprotection,commissionerlevy,zselevy,dealvalue,DateAdded) 
--	values(0, @dealtype, @dealno, @dealdate, @clientno, @asset, @qty, @price, @consideration, 0, 0, 0, @user, 1, 0, dbo.fnGetSettlementDate(@dealdate), 0, 0, 0, 0, 0, @consideration, getdate())
--end
--else
--begin

	if @dealtype = 'SELL'
	begin
		select @dealvalue = @consideration -(dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno))

		select @charges = dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno)

		select @brokerdealtype = 'BUY'
	end
	else if @dealtype = 'BUY'
	begin
		select @dealvalue = @consideration + dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno)

		select @charges = dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno)

		select @brokerdealtype = 'SELL'
    end   

	insert into DEALALLOCATIONS(dealtype, dealno, dealdate, clientno, asset, qty, price, Consideration, StampDuty, approved, sharesout, certdueby, merged, [login], dateadded, vat, capitalgains, investorprotection, commissionerlevy, zselevy, dealvalue, 
	approvedby, grosscommission, csdlevy, csdnumber)
	select @dealtype, @dealno, @dealdate, @clientno, @asset, @qty, @price,
	@qty*@price/100,
	dbo.fnCalculateStampDuty(@consideration, @clientno)
	, 1, 0
	,dbo.fnGetSettlementDate(@dealdate)
	,0, @user, getdate()
	,dbo.fnCalculateVat(@consideration, @clientno)
	,dbo.fnCalculateCapitalGains(@consideration, @clientno)
	,dbo.fnCalculateInvestorProtection(@consideration, @clientno)
	,dbo.fnCalculateSecLevy(@consideration, @clientno)
	,dbo.fnCalculateZSELevy(@consideration, @clientno)
	,@dealvalue
	,@user
	,dbo.fnCalculateCommission(@consideration, @clientno)
	,dbo.fnCalculateCSDLevy(@consideration, @clientno)
	,@CSDNumber

	--post the corresponding broker deal to ATS Trades account
	insert into dealallocations (docketno,dealtype,dealno,dealdate,clientno,asset,qty,price,consideration,grosscommission,basiccharges,stampduty,login,approved,sharesout,certdueby,vat,capitalgains,investorprotection,commissionerlevy,zselevy,dealvalue,DateAdded) 
	values(0, @brokerdealtype, left(@brokerdealtype, 1) +'/'+dbo.fnGetDealNo(), @dealdate, 0, @asset, @qty, @price, @consideration, 0, 0, 0, @user, 1, 0, dbo.fnGetSettlementDate(@dealdate), 0, 0, 0, 0, 0, @consideration, getdate())

	--post the deal's charges to the various charges accounts
	exec DealChargesTransact @DealNo, 'Credit', @User

	--post the deal's charges to the CDC account
	if @charges > 0
	begin
		select @CDC = ControlAccount from tblSystemParams
		insert into cashbooktrans(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'PAY', @dealdate, cast(@qty as varchar(10))+' '+@asset+' @ '+cast(@price as varchar(10)), abs(@consideration-@dealvalue))
	end
--end
GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateCapitalGains]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnCalculateCapitalGains](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.CapitalGains, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateCommission]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnCalculateCommission](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.commission, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

--select dbo.fnCalculateCommission(500, '0')
GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateCSDLevy]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnCalculateCSDLevy](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.CSDLevy, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateInvestorProtection]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnCalculateInvestorProtection](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.InvestorProtection, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateSecLevy]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnCalculateSecLevy](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.CommissionerLevy, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateStampDuty]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnCalculateStampDuty](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.StampDuty, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateVAT]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnCalculateVAT](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.vat, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateZSELevy]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnCalculateZSELevy](
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.ZSELevy, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnGetDealNo]    Script Date: 2019-05-21 01:47:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create function [dbo].[fnGetDealNo]()
returns varchar(10)
BEGIN
	declare @DealNo as varchar(50)
	
	select @DealNo = max(id)+1 from Dealallocations
	if @DealNo is null
		select @DealNo=1
	
	
	return @DealNo
END

GO
