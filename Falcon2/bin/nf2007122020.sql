USE [Newfalcon20]
GO
/****** Object:  StoredProcedure [dbo].[AccountLedgerAdd]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE        PROCEDURE [dbo].[AccountLedgerAdd]	(
	@ViewDate		datetime,
	@StartDate		datetime,
	@EndDate		datetime,
	@User			varchar(20),
	@TransCode		varchar(20)
				)
AS
set nocount on
select @ViewDate = cast((floor(convert(float,@ViewDate))) as datetime)
select @StartDate = cast((floor(convert(float,@StartDate))) as datetime)
select @EndDate = cast((floor(convert(float,@EndDate))) as datetime)
DELETE FROM LEDGERS WHERE ([USER] = @User) AND (TRANSCODE LIKE @TransCode)
INSERT INTO LEDGERS ([USER],TRANSCODE,STMTDATE,STARTDATE,ENDDATE,BALBF,BALCF)
SELECT	@User,
	T.TRANSCODE,
	'STMTDATE' = @ViewDate,
	'STARTDATE' = @StartDate,
	'ENDDATE' = @EndDate,
	'BALBF' = (SELECT SUM(TR.AMOUNT) FROM TRANSACTIONS TR WHERE (TR.TRANSDT < @StartDate) AND (TR.TRANSCODE LIKE @TransCode)),
	'BALCF' = (SELECT SUM(TR.AMOUNT) FROM TRANSACTIONS TR WHERE (TR.TRANSDT <= @EndDate) AND (TR.TRANSCODE LIKE @TransCode))
FROM TRANSACTIONS T
WHERE T.TRANSCODE LIKE @TransCode
GROUP BY T.TRANSCODE
UPDATE LEDGERS SET BALBF = 0 WHERE BALBF IS NULL
UPDATE LEDGERS SET BALCF = 0 WHERE BALCF IS NULL
return 0

GO
/****** Object:  StoredProcedure [dbo].[AccountLedgersFinish]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE        PROCEDURE [dbo].[AccountLedgersFinish]	(
	@User	varchar(50)
)
AS
set nocount on
declare @totalbf money, @totalcf money
select @totalbf = sum(balbf) from ledgers where [user] = @User
select @totalcf = sum(balcf) from ledgers where [user] = @User
update ledgers set balbf = @totalbf, balcf = @totalcf where [user] = @User
return 0

GO
/****** Object:  StoredProcedure [dbo].[AccountLedgersPrepare]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE        PROCEDURE [dbo].[AccountLedgersPrepare]	(
	@User	varchar(50)
)
AS
set nocount on
DELETE FROM LEDGERS WHERE ([USER] = @User)
return 0

GO
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalance]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE               PROCEDURE [dbo].[AccountsTrialBalance]
 ( @AsAt	datetime )
AS
declare @bal money, @cr money, @dr money, @drclient money, @crclient money, @crbroker money, @drbroker money 
declare @OldCommLvAcc int, @zseclientno int, @taxclientno int

delete from TrialBalancePrepare1
delete from TrialBalancePrepare2
delete from TrialBalanceFinal

select @OldCommLvAcc = commissioneraccount, @zseclientno = zseclientno, @taxclientno = taxclientno from accountsparams

-- debtors & creditors
insert into TrialBalancePrepare1 (cno,bal)
	select cno, bal = sum(amount) from transactions where (transdt <= @AsAt)  group by cno -- and (cno <> @OldCommLvAcc) and (transcode not like '%LV%')  
update TrialBalancePrepare1 set bal = 0 where bal is null

--insert into TrialBalancePrepare2 (cat, debtors, creditors)
--select 'cat' = case when c.category = 'BROKER' then 'BROKER BALANCES' else 'CLIENT BALANCES' end, debtors = sum(case when l.bal > 0 then l.bal else 0 end), creditors = sum(case when l.bal < 0 then abs(l.bal) else 0 end) from TrialBalancePrepare1 l, clients c where (l.cno = c.clientno) and (l.cno <> (select zseclientno from accountsparams)) and (l.cno <> (select taxclientno from accountsparams)) group by case when c.category = 'BROKER' then 'BROKER BALANCES' else 'CLIENT BALANCES' end

select @crbroker = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and cno in (select clientno from clients  where category = 'broker')
select @drbroker = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and cno in (select clientno from clients  where category = 'broker')
select @crclient = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and cno in (select clientno from clients  where category <> 'broker')
select @drclient = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and cno in (select clientno from clients  where category <> 'broker')

if @crbroker is null
 select @crbroker = 0
if @drbroker is null 
 select @drbroker = 0
if @crclient is null
 select @crclient = 0
if @drclient is null
 select @drclient = 0

insert into TrialBalancePrepare2(cat,debtors, creditors)
values('BROKER BALANCES', @drbroker, @crbroker)
insert into TrialBalancePrepare2(cat,debtors, creditors)
values('CLIENT BALANCES', @drclient, @crclient)
update TrialBalancePrepare2 set debtors = 0 where debtors is null
update TrialBalancePrepare2 set creditors = 0 where creditors is null
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) select cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2
-- bank balance
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and ((transcode like 'PAY%') or (transcode like 'REC%')) -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('BANK', @dr, @cr, 'CASH & BANK')
-- collector of taxes
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'REC%') OR (transcode like 'PAY%') or (transcode like 'SDDUE%')) and (cno = (select taxclientno from accountsparams)) -- (+ve means DEBIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
--insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('THE COLLECTOR OF TAXES', @dr, @cr, 'NON-TRADE DEBTORS & CREDITORS')
--insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('STAMP DUTY COLLECTOR ACCOUNT', @dr, @cr, 'NON-TRADE DEBTORS & CREDITORS')

-- vat collection
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'REC%') OR (transcode like 'PAY%') or (transcode like 'VATD%')) and (cno = (select vatclientno from accountsparams)) -- (+ve means DEBIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
--insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('THE COLLECTOR OF TAXES', @dr, @cr, 'NON-TRADE DEBTORS & CREDITORS')
--insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('VAT COLLECTOR ACCOUNT', @dr, @cr, 'NON-TRADE DEBTORS & CREDITORS')

-- stock exchange
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'REC%') OR (transcode like 'PAY%')) and (cno = (select zseclientno from accountsparams)) -- (+ve means DEBIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('STOCK EXCHANGE', @dr, @cr, 'NON-TRADE DEBTORS & CREDITORS')
-- commission
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and (transcode like 'COMM%') and transcode not like '%LV%'
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('COMMISSION', @dr, @cr, 'TRADING FEES')
-- ZSE commission
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and (transcode like 'ZSECOMM%')
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('EXCHANGE COMMISSION', @dr, @cr, 'TRADING FEES')
-- commission rebates
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and (transcode like 'NMI%')
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('COMMISSION REBATES', @dr, @cr, 'TRADING FEES')
-- basic charges
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and (transcode like 'BFEE%')
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('BASIC CHARGES', @dr, @cr, 'TRADING FEES')
-- transfer fees
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and (transcode like 'TFEE%')
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('TRANSFER FEES', @dr, @cr, 'TRADING FEES')
-- STAMP DUTY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'SDUTY%') or (transcode like 'SDDUE%'))
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('STAMP DUTY', @dr, @cr, 'TRADING FEES')
-- withholding tax
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'WTAX') or (transcode like 'WTAXCNL'))
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('WITHHOLDING TAX', @dr, @cr, 'TRADING FEES')
-- V.A.T
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt)  and dealno in (select dealno from dealallocations where approved = 1
 and merged = 0 )
and cno > 30
AND ((transcode like 'VATCOMM') or (transcode like 'VATCOMMCNL') or (transcode like 'VATD%'))
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('V.A.T', @dr, @cr, 'TRADING FEES')

-- CAPITAL GAINS TAX
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'CAPTAX') or (transcode like 'CAPTAXCNL') or (transcode like 'CAPTAXD%'))
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('CAPITAL GAINS TAX', @dr, @cr, 'TRADING FEES')

-- INVESTOR PROTECTION LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt)  
 AND ((transcode like 'INVPROT') or (transcode like 'INVPROTCNL') or (transcode like 'INVPROTD%'))and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('INVESTOR PROTECTION LEVY', @dr, @cr, 'TRADING FEES')


-- COMMISSIONER LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) AND((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%'))  --and cno <> @OldCommLvAcc
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('COMMISSIONER''S LEVY', @dr, @cr, 'TRADING FEES')

-- share jobbing
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and ((transcode like 'PURCH%') or (transcode like 'SALE%')) -- (-ve means purchases are greater, bal is CR. +ve means sales greater -> bal is DR
if @bal is null
	select @bal = 0
if @bal < 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('SHARE JOBBING', @dr, @cr, 'TRADING ACCOUNTS')
-- dividends
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and (transcode like 'DIV%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('DIVIDENDS', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- interest
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and (transcode like 'INT%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('INTEREST', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- journal
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt) and ((transcode like 'AINCJ') or (transcode like 'ADECJ')) -- (+ve means CREDIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('GENERAL JOURNAL', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- cheque replacement charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and (transcode like 'CHRPFEE%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('CHQ REPLACEMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- transfer payment charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and (transcode like 'TPAYFEE%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('RTGS PAYMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')


-- ZSE LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdt <= @AsAt)  
 AND transdt >= '2010-01-11'
AND((transcode like 'ZSELV') or (transcode like 'ZSELVCNL') or (transcode like 'ZSELVD%'))
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('ZSELEVY', @dr, @cr, 'TRADING FEES')



-- sundry charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdt <= @AsAt) and (transcode like 'SDRYCHG%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('SUNDRY CHARGES', @dr, @cr, 'NON-TRADING ACTIVITIES')
return 0















GO
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalanceDaily]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE               PROCEDURE [dbo].[AccountsTrialBalanceDaily]
 ( 
	@EndDate	datetime )--  [AccountsTrialBalancePeriod] '20101207'
AS
declare @bal money,  @tempbal money,@cr money, @dr money, @drclient money, @crclient money, @crbroker money, @drbroker money,@txnbal money,@NMIRebate money
declare @OldCommLvAcc int, @zseclientno int, @taxclientno int,@EndDate1 datetime,@StartYear datetime

delete from TrialBalancePrepare1
delete from TrialBalancePrepare2
delete from TrialBalancePrepare3

delete from TrialBalanceFinal
select @EndDate1=DATEADD(d,1,@EndDate)
select @StartYear= cast(DATEPART(YY,@EndDate) as varchar(50))+'0101'


-- debtors & creditors
select  @txnbal=0
insert into TrialBalancePrepare3 (clientno,bal)
	select clientno, bal = sum(amountoldfalcon) from transactions where (transdate = @EndDate)  group by clientno

insert into TrialBalancePrepare3 (clientno,bal)	
	select clientno, bal = sum(amount) from CASHBOOKTRANS where transcode not like('nmi%') and (transdate = @EndDate)  group by clientno 
	
insert into TrialBalancePrepare1 (clientno,bal)	
	select clientno, bal = sum(bal)  from trialbalanceprepare3  group by clientno 	
	
update TrialBalancePrepare1 set bal = 0 where bal is null

select @crbroker = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category = 'broker')
select @drbroker = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category = 'broker')
select @crclient = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))
select @drclient = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))

if @crbroker is null
 select @crbroker = 0
if @drbroker is null 
 select @drbroker = 0
if @crclient is null
 select @crclient = 0
if @drclient is null
 select @drclient = 0

insert into TrialBalancePrepare2(cat,debtors, creditors)
values('BROKER BALANCES', @drbroker, @crbroker)
insert into TrialBalancePrepare2(cat,debtors, creditors)
values('CLIENT BALANCES', @drclient, @crclient)
update TrialBalancePrepare2 set debtors = 0 where debtors is null
update TrialBalancePrepare2 set creditors = 0 where creditors is null
--insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'br%'
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '191',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'cl%'
-- bank balance
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode  like 'PAY%' or (transcode like 'REC%') ) -- (+ve means debit balance)
if @bal is null
	select @bal = 0

if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('192','BANK', @dr, @cr, 'CASH & BANK')


-- commission rebates
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate = @EndDate) and (transcode like 'NMI%')
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'NMIRBT%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('157','COMMISSION REBATES', @dr, @cr, 'TRADING FEES')

-- Rebates Owing
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate = @EndDate) and (transcode like 'NMI%')
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'NMIRBT%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal < 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('127','REBATES OWING', @dr, @cr, 'TRADE DEBTORS & CREDITORS')


-- commission
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and (transcode like 'COMMS%')
if @bal is null
	select @bal = 0

if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('150','COMMISSION', @dr, @cr, 'TRADING FEES')

-- basic charges
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and (transcode like 'BFEE%')
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'BFEED%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('158','BASIC CHARGES', @dr, @cr, 'TRADING FEES')

-- stamp duty
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and (transcode like 'SDUTY%')
if @bal is null
	select @bal = 0
	select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'SDDUE%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('152','STAMP DUTY', @dr, @cr, 'TRADING FEES')

-- V.A.T
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and ((transcode like 'VATCOMM') or (transcode like 'VATCOMMCNL') or (transcode like 'VATD%'))
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'VATD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('151','V.A.T', @dr, @cr, 'TRADING FEES')

-- CAPITAL GAINS TAX
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and ((transcode like 'CAPTAX%') or (transcode like 'CAPTAXCNL') or (transcode like 'CAPTAXD%'))
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'CAPTAXD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('154','CAPITAL GAINS TAX', @dr, @cr, 'TRADING FEES')

-- INVESTOR PROTECTION LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and ((transcode like 'INVPROT') or (transcode like 'INVPROTCNL') or (transcode like 'INVPROTD%'))
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'INVPROTD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('155','INVESTOR PROTECTION LEVY', @dr, @cr, 'TRADING FEES')


-- COMMISSIONER LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (transdate = @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%')) --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%')) --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('156','COMMISSIONER''S LEVY', @dr, @cr, 'TRADING FEES')

-- ZSE LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate = @EndDate) and ((transcode like 'ZSELV') or (transcode like 'ZSELVCNL') or (transcode like 'ZSELVD%')) --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'ZSELVD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('153','ZSE LEVY', @dr, @cr, 'TRADING FEES')

--CSD LEVY
select @cr = 0
select @dr = 0
select @bal = isnull(sum(amount), 0) from transactions where (transdate = @EndDate) and ((transcode like 'CSDLV') or (transcode like 'CSDLVCNL') or (transcode like 'CSDLVD%')) --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = isnull(sum(amount), 0) from CASHBOOKTRANS where  (transdate = @EndDate) and (transcode like 'CSDLVD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('159','CSD LEVY', @dr, @cr, 'TRADING FEES')

-- share jobbing
select @cr = 0
select @dr = 0
select @bal = sum(-consideration) from transactions where (transdate = @EndDate) and ((transcode like 'PURCH%') or (transcode like 'SALE%')) -- (-ve means purchases are greater, bal is CR. +ve means sales greater -> bal is DR
if @bal is null
	select @bal = 0
if @bal < 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('180','SHARE JOBBING', @dr, @cr, 'TRADING ACCOUNTS')

-- dividends
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate = @EndDate) and (transcode like 'DIV%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('181','DIVIDENDS', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- interest
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (transdate = @EndDate) and (transcode like 'INT%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('182','INTEREST', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- journal
select @cr = 0
select @dr = 0
select @bal = sum(amount) from cashbooktrans where (transdate = @EndDate) and ((transcode like 'AINCJ') or (transcode like 'ADECJ')) -- (+ve means CREDIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('183','GENERAL JOURNAL', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- sundry charges --ALWAYS DEBIT BALANCE
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where (TransDate = @EndDate1) and (transcode like 'SDRYCHG%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('193','BANK CHARGES', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- sundry income --ALWAYS CREDIT BALANCE
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where (TransDate = @EndDate1) and (transcode like 'SDRYINC%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('194','SUNDRY INCOME', @dr, @cr, 'NON-TRADING ACTIVITIES')

---- cheque replacement charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate = @EndDate) and (transcode like 'CHRPFEE%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('CHQ REPLACEMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- transfer payment charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (transdate = @EndDate) and (transcode like 'TPAYFEE%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,debitbal,creditbal,[group]) values ('200','RTGS PAYMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')


GO
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalancePeriod]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE               PROCEDURE [dbo].[AccountsTrialBalancePeriod]
 ( 
	@EndDate	datetime )--  [AccountsTrialBalancePeriod] '20101207'
AS
declare @bal decimal(31,9),  @tempbal decimal(31,9),@cr decimal(31,9), @dr decimal(31,9), @drclient decimal(31,9), @crclient decimal(31,9), @crbroker decimal(31,9), @drbroker decimal(31,9),@txnbal decimal(31,9),@NMIRebate decimal(31,9)

declare  @StartYear datetime

delete from TrialBalancePrepare1
delete from TrialBalancePrepare2
delete from TrialBalancePrepare3

delete from TrialBalanceFinal

select @StartYear= cast(DATEPART(YY,@EndDate) as varchar(50))+'0101'


-- debtors & creditors
truncate table transactionsaging
exec BalancesOnly @EndDate
insert into TrialBalancePrepare1 (clientno,bal)	
	select clientno, balance   from tblClientBalances 
select @crbroker = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category = 'broker')
select @drbroker = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category = 'broker')
select @crclient = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))
select @drclient = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))

if @crbroker is null
 select @crbroker = 0
if @drbroker is null 
 select @drbroker = 0
if @crclient is null
 select @crclient = 0
if @drclient is null
 select @drclient = 0

insert into TrialBalancePrepare2(cat,debtors, creditors)
values('BROKER BALANCES', @drbroker, @crbroker)
insert into TrialBalancePrepare2(cat,debtors, creditors)
values('CLIENT BALANCES', @drclient, @crclient)
update TrialBalancePrepare2 set debtors = 0 where debtors is null
update TrialBalancePrepare2 set creditors = 0 where creditors is null

insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'br%'
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '191',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'cl%'

-- bank balance
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where yon=1 and (transdate <= @EndDate) and (transcode  like 'PAY%' or (transcode like 'REC%') ) -- (+ve means debit balance)
if @bal is null
	select @bal = 0

if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('192','BANK', @dr, @cr, 'CASH & BANK')


-- commission rebates
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'NMI%') and YON=1 
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'NMIRBT%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
	
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('157','COMMISSION REBATES', @dr, @cr, 'TRADING FEES')

-- Rebates Owing
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'NMI%') and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'NMIRBT%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal < 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('127','REBATES OWING', @dr, @cr, 'TRADE DEBTORS & CREDITORS')


-- commission
select @cr = 0
select @dr = 0
select @bal = isnull(sum(amount), 0) from transactions where (transdate >= @StartYear)and(transdate <= @EndDate) and (transcode like 'COMMS%') and YON=1 and ClientNo = '150'
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('150','COMMISSION', @dr, @cr, 'TRADING FEES')

-- basic charges
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (transdate >= @StartYear)and(transdate <= @EndDate) and (transcode like 'BFEE%') and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'BFEED%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
--commented 24 sept 20
--insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('158','BASIC CHARGES', @dr, @cr, 'TRADING FEES')

-- stamp duty
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and (transcode like 'SDUTY%') and YON=1 and clientno = '152'
if @bal is null
	select @bal = 0
	select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'SDDUE%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('152','STAMP DUTY', @dr, @cr, 'TRADING FEES')

-- V.A.T
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and clientno = '151' and ((transcode like 'VATCOMM') or (transcode like 'VATCOMMCNL') or (transcode like 'VATD%'))and YON=1  and clientno = '151'
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'VATD%') and clientno = '151'
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('151','V.A.T', @dr, @cr, 'TRADING FEES')

-- CAPITAL GAINS TAX
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'CAPTAX%') or (transcode like 'CAPTAXCNL') or (transcode like 'CAPTAXD%')) and YON=1  and clientno = '154'
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'CAPTAXD%') and clientno = '154'
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('154','CAPITAL GAINS TAX', @dr, @cr, 'TRADING FEES')

-- INVESTOR PROTECTION LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'INVPROT') or (transcode like 'INVPROTCNL') or (transcode like 'INVPROTD%'))and YON=1 
and clientno = '155'
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'INVPROTD%') and clientno = '155'
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('155','INVESTOR PROTECTION LEVY', @dr, @cr, 'TRADING FEES')

-- COMMISSIONER LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (transdate <= @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%')) and YON=1  and clientno = '156'
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%'))and ClientNo <>'4762MMC' and clientno = '156' --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('156','COMMISSIONER''S LEVY', @dr, @cr, 'TRADING FEES')

-- ZSE LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'ZSELV') or (transcode like 'ZSELVCNL') or (transcode like 'ZSELVD%')) and YON=1 
and CLIENTNO = '153'

if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'ZSELVD%') --and transdate >= '2009-05-13' --and clientno = '153'
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('153','ZSE LEVY', @dr, @cr, 'TRADING FEES')

-- CSD LEVY ADDED 18 JULY 2014
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'CSDLV') or (transcode like 'CSDLVCNL') or (transcode like 'CSDLVD%')) and YON=1 AND clientno = '159'
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'CSDLVD%') 
and clientno = '159'
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('159','CSD LEVY', @dr, @cr, 'TRADING FEES')

-- share jobbing
select @cr = 0
select @dr = 0
select @bal = sum(-consideration) from transactions where (transdate <= @EndDate) and ((transcode like 'PURCH%') or (transcode like 'SALE%')) and YON=1 -- (-ve means purchases are greater, bal is CR. +ve means sales greater -> bal is DR
if @bal is null
	select @bal = 0
if @bal < 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('180','SHARE JOBBING', @dr, @cr, 'TRADING ACCOUNTS')


-- interest
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (transdate <= @EndDate) and (transcode like 'INT%') and YON=1 -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('182','INTEREST', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- journal
select @cr = 0
select @dr = 0
select @bal = sum(amount) from cashbooktrans where (transdate <= @EndDate) and ((transcode like 'AINCJ') or (transcode like 'ADECJ')) and YON=1 and Cancelled=0-- (+ve means CREDIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
	
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('183','GENERAL JOURNAL', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- transfer payment charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (transdate <= @EndDate) and (transcode like 'TPAYFEE%') and YON=1 -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)

insert into TrialBalanceFinal (ClientNo,ACCOUNT,debitbal,creditbal,[group]) values ('200','RTGS PAYMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- RETAINED EARNINGS
select @cr = 0
select @dr = 0
select @bal = isnull(dbo.retainedearnings(@EndDate),0)
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
--commented 24 sept 20
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('300','RETAINED EARNINGS', @dr, @cr, 'TRADING FEES')

update TrialBalanceFinal set AsAt=@EndDate
GO
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalancePeriodDP]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create               PROCEDURE [dbo].[AccountsTrialBalancePeriodDP]
 ( 
	@EndDate	datetime )--  [AccountsTrialBalancePeriodDP] '20120801'
AS
declare @bal money,  @tempbal money,@cr money, @dr money, @drclient money, @crclient money, @crbroker money, @drbroker money,@txnbal money,@NMIRebate money
declare @OldCommLvAcc int, @zseclientno int, @taxclientno int,@EndDate1 datetime,@StartYear datetime

delete from TrialBalancePrepare1
delete from TrialBalancePrepare2
delete from TrialBalancePrepare3

delete from TrialBalanceFinal
select @EndDate1=DATEADD(d,1,@EndDate)
select @StartYear= cast(DATEPART(YY,@EndDate) as varchar(50))+'0101'

-- debtors & creditors
truncate table transactionsaging
exec BalancesOnlyPD @EndDate
insert into TrialBalancePrepare1 (clientno,bal)	
	select clientno, balance   from tblbalances 
select @crbroker = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category = 'broker')
select @drbroker = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category = 'broker')
select @crclient = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))
select @drclient = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))

if @crbroker is null
 select @crbroker = 0
if @drbroker is null 
 select @drbroker = 0
if @crclient is null
 select @crclient = 0
if @drclient is null
 select @drclient = 0

insert into TrialBalancePrepare2(cat,debtors, creditors)
values('BROKER BALANCES', @drbroker, @crbroker)
insert into TrialBalancePrepare2(cat,debtors, creditors)
values('CLIENT BALANCES', @drclient, @crclient)
update TrialBalancePrepare2 set debtors = 0 where debtors is null
update TrialBalancePrepare2 set creditors = 0 where creditors is null
--insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'br%'
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '191',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'cl%'
-- bank balance
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode  like 'PAY%' or (transcode like 'REC%') ) -- (+ve means debit balance)
if @bal is null
	select @bal = 0
--select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'nmi%') or (transcode like '%due')-- (+ve means debit balance)
--if @tempbal is null
--	select @tempbal = 0
--select @bal=@bal+@tempbal	
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('192','BANK', @dr, @cr, 'CASH & BANK')


-- commission rebates
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (postdate <= @EndDate) and (transcode like 'NMI%') and YON=1 
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'NMIRBT%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('157','COMMISSION REBATES', @dr, @cr, 'TRADING FEES')

-- Rebates Owing
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (postdate <= @EndDate) and (transcode like 'NMI%') and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'NMIRBT%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal < 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('127','REBATES OWING', @dr, @cr, 'TRADE DEBTORS & CREDITORS')


-- commission
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (postdate >= @StartYear)and(postdate <= @EndDate) and (transcode like 'COMMS%') and YON=1
if @bal is null
	select @bal = 0
--else
--	select @bal = @bal+ @NMIRebate--sum(amount) from transactions where (postdate <= @EndDate) and (transcode like 'NMI%')
	
--select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'COMMD%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
--if @tempbal is null
--	select @tempbal = 0
--select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('150','COMMISSION', @dr, @cr, 'TRADING FEES')

----rebates owing
--select @cr = 0
--select @dr = 0
--select @bal = sum(amount) from transactions where (postdate <= @EndDate) and CLIENTNO='157'
--if @bal is null
--	select @bal = 0
--select @tempbal = sum(-amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'NMI%')--CLIENTNO='157'--and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
--if @tempbal is null
--	select @tempbal = 0
--select @bal=@bal+@tempbal	
--select @NMIRebate=@bal
--if @bal> 0
--begin
--	select @dr = abs(@bal)
--	select @cr=@tempbal
--end
--else
--begin
--	select @cr = abs(@bal)
--	select @dr=@tempbal
--end
--insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('177','REBATES OWING', @dr, @cr, 'TRADE DEBTORS & CREDITORS')


-- basic charges
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (postdate >= @StartYear)and(postdate <= @EndDate) and (transcode like 'BFEE%') and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'BFEED%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('158','BASIC CHARGES', @dr, @cr, 'TRADING FEES')

-- stamp duty
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (postdate <= @EndDate) and (transcode like 'SDUTY%') and YON=1
if @bal is null
	select @bal = 0
	select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'SDDUE%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('152','STAMP DUTY', @dr, @cr, 'TRADING FEES')

-- V.A.T
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (postdate <= @EndDate) and ((transcode like 'VATCOMM') or (transcode like 'VATCOMMCNL') or (transcode like 'VATD%'))and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'VATD%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('151','V.A.T', @dr, @cr, 'TRADING FEES')

-- CAPITAL GAINS TAX
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (postdate <= @EndDate) and ((transcode like 'CAPTAX%') or (transcode like 'CAPTAXCNL') or (transcode like 'CAPTAXD%')) and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'CAPTAXD%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('154','CAPITAL GAINS TAX', @dr, @cr, 'TRADING FEES')

-- INVESTOR PROTECTION LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (postdate <= @EndDate) and ((transcode like 'INVPROT') or (transcode like 'INVPROTCNL') or (transcode like 'INVPROTD%'))and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'INVPROTD%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('155','INVESTOR PROTECTION LEVY', @dr, @cr, 'TRADING FEES')


-- COMMISSIONER LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (postdate <= @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%')) and ClientNo <> '4762MMC'and YON=1 --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%'))and ClientNo <>'4762MMC' --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('156','COMMISSIONER''S LEVY', @dr, @cr, 'TRADING FEES')

-- ZSE LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (postdate <= @EndDate) and ((transcode like 'ZSELV') or (transcode like 'ZSELVCNL') or (transcode like 'ZSELVD%')) and YON=1 --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (postdate <= @EndDate) and (transcode like 'ZSELVD%') --and postdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('153','ZSE LEVY', @dr, @cr, 'TRADING FEES')

-- share jobbing
select @cr = 0
select @dr = 0
select @bal = sum(-consideration) from transactions where (postdate <= @EndDate) and ((transcode like 'PURCH%') or (transcode like 'SALE%')) and YON=1 -- (-ve means purchases are greater, bal is CR. +ve means sales greater -> bal is DR
if @bal is null
	select @bal = 0
if @bal < 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('180','SHARE JOBBING', @dr, @cr, 'TRADING ACCOUNTS')

-- dividends
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (postdate <= @EndDate) and (transcode like 'DIV%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('181','DIVIDENDS', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- interest
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (postdate <= @EndDate) and (transcode like 'INT%') and YON=1 -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('182','INTEREST', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- journal
select @cr = 0
select @dr = 0
select @bal = sum(amount) from cashbooktrans where (postdate <= @EndDate) and ((transcode like 'AINCJ') or (transcode like 'ADECJ')) and YON=1-- (+ve means CREDIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('183','GENERAL JOURNAL', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- sundry charges --ALWAYS DEBIT BALANCE
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where (postdate <= @EndDate1) and (transcode like 'SDRYCHG%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('193','BANK CHARGES', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- sundry income --ALWAYS CREDIT BALANCE
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where (postdate <= @EndDate1) and (transcode like 'SDRYINC%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('194','SUNDRY INCOME', @dr, @cr, 'NON-TRADING ACTIVITIES')

---- cheque replacement charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (postdate <= @EndDate) and (transcode like 'CHRPFEE%') and YON=1-- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('CHQ REPLACEMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- transfer payment charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (postdate <= @EndDate) and (transcode like 'TPAYFEE%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,debitbal,creditbal,[group]) values ('200','RTGS PAYMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- sundry charges
--select @cr = 0
--select @dr = 0
--select @bal = sum(-amount) from transactions where (postdate <= @EndDate) and (transcode like 'SDRYCHG%') -- (+ve means debit balance)
--if @bal is null
--	select @bal = 0
--if @bal > 0
--	select @dr = abs(@bal)
--else
--	select @cr = abs(@bal)
--insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('SUNDRY CHARGES', @dr, @cr, 'NON-TRADING ACTIVITIES')
--return 0

-- RETAINED EARNINGS
select @cr = 0
select @dr = 0
select @bal = isnull(dbo.retainedearningsdp(@EndDate),0)
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('300','RETAINED EARNINGS', @dr, @cr, 'TRADING FEES')

update TrialBalanceFinal set AsAt=@EndDate
GO
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalancePeriodNEW1]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create               PROCEDURE [dbo].[AccountsTrialBalancePeriodNEW1]
 ( 
	@EndDate	datetime )--  [AccountsTrialBalancePeriod] '20101207'
AS
declare @bal money,  @tempbal money,@cr money, @dr money, @drclient money, @crclient money, @crbroker money, @drbroker money,@txnbal money,@NMIRebate money
declare @OldCommLvAcc int, @zseclientno int, @taxclientno int,@EndDate1 datetime,@StartYear datetime

delete from TrialBalancePrepare1
delete from TrialBalancePrepare2
delete from TrialBalancePrepare3

delete from TrialBalanceFinal
select @EndDate1=DATEADD(d,1,@EndDate)
select @StartYear= cast(DATEPART(YY,@EndDate) as varchar(50))+'0101'

--select @OldCommLvAcc = commissioneraccount, @zseclientno = zseclientno, @taxclientno = taxclientno from systemparams

-- debtors & creditors
--select  @txnbal=0
--insert into TrialBalancePrepare3 (clientno,bal)
--	select clientno, bal = sum(amountoldfalcon) from transactions where (transdate <= @EndDate)  group by clientno
--	-- and (clientno <> @OldCommLvAcc) and (transcode not like '%LV%') 
--insert into TrialBalancePrepare3 (clientno,bal)	
--	select clientno, bal = sum(amount) from CASHBOOKTRANS where transcode not like('nmi%') and (transdate <= @EndDate)  group by clientno 
	
--insert into TrialBalancePrepare1 (clientno,bal)	
--	select clientno, bal = sum(bal)  from trialbalanceprepare3  group by clientno 	
	
--update TrialBalancePrepare1 set bal = 0 where bal is null

--insert into TrialBalancePrepare2 (cat, debtors, creditors)
--select 'cat' = case when c.category = 'BROKER' then 'BROKER BALANCES' else 'CLIENT BALANCES' end, debtors = sum(case when l.bal > 0 then l.bal else 0 end), creditors = sum(case when l.bal < 0 then abs(l.bal) else 0 end) from TrialBalancePrepare1 l, clients c where (l.clientno = c.clientno) and (l.clientno <> (select zseclientno from systemparams)) and (l.clientno <> (select taxclientno from systemparams)) group by case when c.category = 'BROKER' then 'BROKER BALANCES' else 'CLIENT BALANCES' end
truncate table transactionsaging
exec BalancesOnly @EndDate
insert into TrialBalancePrepare1 (clientno,bal)	
	select clientno, balance   from tblbalances 
select @crbroker = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category = 'broker')
select @drbroker = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category = 'broker')
select @crclient = abs(sum(bal)) from trialbalanceprepare1 where bal < 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))
select @drclient = abs(sum(bal)) from trialbalanceprepare1 where bal > 0 and clientno in (select clientno from clients  where category not in ('broker','tax account'))

if @crbroker is null
 select @crbroker = 0
if @drbroker is null 
 select @drbroker = 0
if @crclient is null
 select @crclient = 0
if @drclient is null
 select @drclient = 0

insert into TrialBalancePrepare2(cat,debtors, creditors)
values('BROKER BALANCES', @drbroker, @crbroker)
insert into TrialBalancePrepare2(cat,debtors, creditors)
values('CLIENT BALANCES', @drclient, @crclient)
update TrialBalancePrepare2 set debtors = 0 where debtors is null
update TrialBalancePrepare2 set creditors = 0 where creditors is null
--insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'br%'
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '191',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'cl%'
-- bank balance
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode  like 'PAY%' or (transcode like 'REC%') ) -- (+ve means debit balance)
if @bal is null
	select @bal = 0
--select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'nmi%') or (transcode like '%due')-- (+ve means debit balance)
--if @tempbal is null
--	select @tempbal = 0
--select @bal=@bal+@tempbal	
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('192','BANK', @dr, @cr, 'CASH & BANK')


-- commission rebates
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'NMI%') and YON=1 
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'NMIRBT%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('157','COMMISSION REBATES', @dr, @cr, 'TRADING FEES')

-- Rebates Owing
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'NMI%') and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'NMIRBT%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
select @NMIRebate=@bal	
if @bal < 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('127','REBATES OWING', @dr, @cr, 'TRADE DEBTORS & CREDITORS')


-- commission
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate >= @StartYear)and(transdate <= @EndDate) and (transcode like 'COMMS%') and YON=1
if @bal is null
	select @bal = 0
--else
--	select @bal = @bal+ @NMIRebate--sum(amount) from transactions where (transdate <= @EndDate) and (transcode like 'NMI%')
	
--select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'COMMD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
--if @tempbal is null
--	select @tempbal = 0
--select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('150','COMMISSION', @dr, @cr, 'TRADING FEES')

----rebates owing
--select @cr = 0
--select @dr = 0
--select @bal = sum(amount) from transactions where (transdate <= @EndDate) and CLIENTNO='157'
--if @bal is null
--	select @bal = 0
--select @tempbal = sum(-amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'NMI%')--CLIENTNO='157'--and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
--if @tempbal is null
--	select @tempbal = 0
--select @bal=@bal+@tempbal	
--select @NMIRebate=@bal
--if @bal> 0
--begin
--	select @dr = abs(@bal)
--	select @cr=@tempbal
--end
--else
--begin
--	select @cr = abs(@bal)
--	select @dr=@tempbal
--end
--insert into TrialBalanceFinal (ClientNo,ACCOUNT,DEBITBAL,creditbal,[group]) values ('177','REBATES OWING', @dr, @cr, 'TRADE DEBTORS & CREDITORS')


-- basic charges
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (transdate >= @StartYear)and(transdate <= @EndDate) and (transcode like 'BFEE%') and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'BFEED%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('158','BASIC CHARGES', @dr, @cr, 'TRADING FEES')

-- stamp duty
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and (transcode like 'SDUTY%') and YON=1
if @bal is null
	select @bal = 0
	select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'SDDUE%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('152','STAMP DUTY', @dr, @cr, 'TRADING FEES')

-- V.A.T
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'VATCOMM') or (transcode like 'VATCOMMCNL') or (transcode like 'VATD%'))and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'VATD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('151','V.A.T', @dr, @cr, 'TRADING FEES')

-- CAPITAL GAINS TAX
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'CAPTAX%') or (transcode like 'CAPTAXCNL') or (transcode like 'CAPTAXD%')) and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'CAPTAXD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('154','CAPITAL GAINS TAX', @dr, @cr, 'TRADING FEES')

-- INVESTOR PROTECTION LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'INVPROT') or (transcode like 'INVPROTCNL') or (transcode like 'INVPROTD%'))and YON=1
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'INVPROTD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('155','INVESTOR PROTECTION LEVY', @dr, @cr, 'TRADING FEES')


-- COMMISSIONER LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where  (transdate <= @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%')) and ClientNo <> '4762MMC'and YON=1 --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and ((transcode like 'COMMLV') or (transcode like 'COMMLVCNL') or (transcode like 'COMMLVD%'))and ClientNo <>'4762MMC' --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('156','COMMISSIONER''S LEVY', @dr, @cr, 'TRADING FEES')

-- ZSE LEVY
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'ZSELV') or (transcode like 'ZSELVCNL') or (transcode like 'ZSELVD%')) and YON=1 --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'ZSELVD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @tempbal is null
	select @tempbal = 0
select @bal=@bal+@tempbal	
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('153','ZSE LEVY', @dr, @cr, 'TRADING FEES')

-- share jobbing
select @cr = 0
select @dr = 0
select @bal = sum(-consideration) from transactions where (transdate <= @EndDate) and ((transcode like 'PURCH%') or (transcode like 'SALE%')) and YON=1 -- (-ve means purchases are greater, bal is CR. +ve means sales greater -> bal is DR
if @bal is null
	select @bal = 0
if @bal < 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('180','SHARE JOBBING', @dr, @cr, 'TRADING ACCOUNTS')

-- dividends
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'DIV%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('181','DIVIDENDS', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- interest
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (transdate <= @EndDate) and (transcode like 'INT%') and YON=1 -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) values ('182','INTEREST', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- journal
select @cr = 0
select @dr = 0
select @bal = sum(amount) from cashbooktrans where (transdate <= @EndDate) and ((transcode like 'AINCJ') or (transcode like 'ADECJ')) and YON=1-- (+ve means CREDIT balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('183','GENERAL JOURNAL', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- sundry charges --ALWAYS DEBIT BALANCE
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where (TransDate <= @EndDate1) and (transcode like 'SDRYCHG%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('193','BANK CHARGES', @dr, @cr, 'NON-TRADING ACTIVITIES')

-- sundry income --ALWAYS CREDIT BALANCE
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where (TransDate <= @EndDate1) and (transcode like 'SDRYINC%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('194','SUNDRY INCOME', @dr, @cr, 'NON-TRADING ACTIVITIES')

---- cheque replacement charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'CHRPFEE%') and YON=1-- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('CHQ REPLACEMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- transfer payment charges
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from cashbooktrans where (transdate <= @EndDate) and (transcode like 'TPAYFEE%') -- (+ve means debit balance)
if @bal is null
	select @bal = 0
if @bal > 0
	select @dr = abs(@bal)
else
	select @cr = abs(@bal)
insert into TrialBalanceFinal (ClientNo,ACCOUNT,debitbal,creditbal,[group]) values ('200','RTGS PAYMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')
-- sundry charges
--select @cr = 0
--select @dr = 0
--select @bal = sum(-amount) from transactions where (transdate <= @EndDate) and (transcode like 'SDRYCHG%') -- (+ve means debit balance)
--if @bal is null
--	select @bal = 0
--if @bal > 0
--	select @dr = abs(@bal)
--else
--	select @cr = abs(@bal)
--insert into TrialBalanceFinal (account,debitbal,creditbal,[group]) values ('SUNDRY CHARGES', @dr, @cr, 'NON-TRADING ACTIVITIES')
--return 0

-- RETAINED EARNINGS
select @cr = 0
select @dr = 0
select @bal = isnull(dbo.retainedearnings(@EndDate),0)
if @bal > 0
	select @cr = abs(@bal)
else
	select @dr = abs(@bal)
insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) values ('300','RETAINED EARNINGS', @dr, @cr, 'TRADING FEES')

update TrialBalanceFinal set AsAt=@EndDate
GO
/****** Object:  StoredProcedure [dbo].[ActiveAccountsClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ActiveAccountsClients]
@StartDate datetime='20080101',
@EndDate datetime='99991231'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, dbo.Clients.Sector,dbo.Clients.UtilityType,
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName,dbo.clients.Bank,dbo.clients.BankAccountNo ,dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients LEFT JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     (dbo.Clients.Status <> 'inactive') and Category not in('transfer secretary','tax account') and ((DateAdded>@StartDate and DateAdded<@EndDate))
	order by  dbo.Clients.ClientNo
END

GO
/****** Object:  StoredProcedure [dbo].[ActiveClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[ActiveClients]
@StartDate datetime='20080101',
@EndDate datetime='99991231'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, dbo.Clients.Sector,dbo.Clients.UtilityType,
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName,dbo.clients.Bank,dbo.clients.BankAccountNo ,dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients LEFT JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     (dbo.Clients.Status <> 'inactive') and Category not in('transfer secretary') and ((DateAdded>@StartDate and DateAdded<@EndDate))
	order by  dbo.Clients.ClientNo
END

GO
/****** Object:  StoredProcedure [dbo].[ActiveClientsOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ActiveClientsOld]
@StartDate datetime='20080101',
@EndDate datetime='99991231'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, dbo.Clients.Sector,dbo.Clients.UtilityType,
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName,dbo.clients.Bank,dbo.clients.BankAccountNo ,dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients LEFT JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     (dbo.Clients.Status <> 'inactive') and Category not in('transfer secretary') and ((DateAdded>@StartDate and DateAdded<@EndDate))
	order by  dbo.Clients.ClientNo
END

GO
/****** Object:  StoredProcedure [dbo].[AdjustCashBal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		Copyright (c) 2003, 2005, 2006		}
{							}
{*******************************************************}
*/
CREATE      PROCEDURE [dbo].[AdjustCashBal]	(
	@Date		datetime,
	@CashBook	int,
	@Adjustment	money
				)
AS
declare @dt datetime, @bal money, @NewDate datetime
select @NewDate = cast((floor(convert(float,@Date))) as datetime)
select @dt = 0, @bal = 0
select top 1 @dt = DT, @bal = BALCF from CASHBAL where (DT = @NewDate) and (CASHBOOKID = @CashBook)
if (@dt = 0) or (@dt is null)
begin
	select @dt = @NewDate
	delete from CASHBAL where (DT = @dt) and (CASHBOOKID = @CashBook)
	insert into CASHBAL (DT,CASHBOOKID,BALBF,BALCF) values (@dt,@CashBook,@bal,@bal + @Adjustment)
end	
else
	update CASHBAL set BALCF = BALCF + @Adjustment where (DT = @dt) and (CASHBOOKID = @CashBook)
exec FixCashBal
return 0

GO
/****** Object:  StoredProcedure [dbo].[Age_AmountsClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[Age_AmountsClient] -- Age_AmountsClient '18','ADEPT','20140416' 
	@ClientNo varchar(50)
	,@User varchar(50)
	,@EndDate datetime
as 
	declare @cust  varchar(50);
	declare @customer  varchar(10);
	declare @name  nvarchar(70);
	declare @curr  decimal(31,9);
	declare @dy30  decimal(31,9);
	declare @dy60  decimal(31,9);
	declare @dy90  decimal(31,9);
	declare @dy120 decimal(31,9);
	declare @Bal decimal(31,9);
	declare @dtrans date;
	declare @amt    decimal(31,9);
	declare @balbf decimal(31,9)
	declare @DateToday date

	select @DateToday=GETDATE()
	
	delete from STATEMENTS where [USER]=@User and CLIENTNO=@ClientNo
	set @curr =0;set @dy30 =0;set @dy60 =0;set @dy90 =0;set @dy120 =0;
	
	
	
	declare dett cursor  for 
    select  clientno,amount as amt,transdate  as dtrans
	from statementsreport 
	where (clientno = @clientno and [login]=@user
    and transdate<=@EndDate
    and matchid is null or matchid<=1)
	order by transdate --desc;
   
  open dett;
    
  FETCH NEXT FROM dett INTO @customer,@amt,@dtrans;
  WHILE @@FETCH_STATUS = 0
  BEGIN

   if @dtrans >= (DATEADD(dd,-7,@DateToday)) -- current 7 day period
      set @curr = @curr + @amt;
   
   if (@dtrans >= (DATEADD(dd,-14,@DateToday))) and  --day 7 to day 14
       (@dtrans < (DATEADD(dd,-7,@DateToday)))
      set @dy30 = @dy30 + @amt;
   if (@dtrans >= (DATEADD(dd,-21,@DateToday))) and --day 14 to day 21
      (@dtrans < (DATEADD(dd,-14,@DateToday)))
      set @dy60 = @dy60 + @amt;
   if (@dtrans >= (DATEADD(dd,-28,@DateToday))) and --day 21 to day 28
      (@dtrans < (DATEADD(dd,-21,@DateToday)))
      set @dy90 = @dy90 + @amt;
   if (@dtrans < (DATEADD(dd,-28,@DateToday))) --over 28days
      set @dy120 = @dy120 + @amt;
   FETCH NEXT FROM dett INTO @customer,@amt,@dtrans;    
  END;
  set @bal=@curr + @dy30+ @dy60+@dy90+@dy120;
  
   CLOSE dett;
  DEALLOCATE dett;
  INSERT INTO statements([USER],CLIENTNO,STMTDATE,ARREARS7,ARREARS14,ARREARS21,ARREARS28,ARREARSOver)
   VALUES (@User,@ClientNo,getdate(),@curr,@dy30,@dy60,@dy90,@dy120);
   
  


GO
/****** Object:  StoredProcedure [dbo].[Age_AmountsClientOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[Age_AmountsClientOld] -- Age_AmountsClient '27','ADEPT' 
	@ClientNo varchar(50)
	,@User varchar(50)
	,@EndDate datetime
as 
	declare @cust  varchar(50);
	declare @customer  varchar(10);
	declare @name  nvarchar(70);
	declare @curr  float;
	declare @dy30  float;
	declare @dy60  float;
	declare @dy90  float;
	declare @dy120 float;
	declare @Bal float;
	declare @dtrans date;
	declare @amt    float;
	declare @balbf float
	declare @DateToday date

	select @DateToday=GETDATE()
	
	delete from STATEMENTS where [USER]=@User and CLIENTNO=@ClientNo
	set @curr =0;set @dy30 =0;set @dy60 =0;set @dy90 =0;set @dy120 =0;
	
	

    declare dett cursor  for 
    select  clientno,amount as amt,transdate  as dtrans
	from statementsreport
	where clientno = @clientno and [login]=@user
    and transdate<=@EndDate
	order by transdate --desc;
   
  open dett;
    
  FETCH NEXT FROM dett INTO @customer,@amt,@dtrans;
  WHILE @@FETCH_STATUS = 0
  BEGIN

   if @dtrans >= (DATEADD(dd,-7,@DateToday)) -- current 7 day period
      set @curr = @curr + @amt;
   
   if (@dtrans >= (DATEADD(dd,-14,@DateToday))) and  --day 7 to day 14
       (@dtrans < (DATEADD(dd,-7,@DateToday)))
      set @dy30 = @dy30 + @amt;
   if (@dtrans >= (DATEADD(dd,-21,@DateToday))) and --day 14 to day 21
      (@dtrans < (DATEADD(dd,-14,@DateToday)))
      set @dy60 = @dy60 + @amt;
   if (@dtrans >= (DATEADD(dd,-28,@DateToday))) and --day 21 to day 28
      (@dtrans < (DATEADD(dd,-21,@DateToday)))
      set @dy90 = @dy90 + @amt;
   if (@dtrans < (DATEADD(dd,-28,@DateToday))) --over 28days
      set @dy120 = @dy120 + @amt;
   FETCH NEXT FROM dett INTO @customer,@amt,@dtrans;    
  END;
  set @bal=@curr + @dy30+ @dy60+@dy90+@dy120;
   CLOSE dett;
  DEALLOCATE dett;
  INSERT INTO statements([USER],CLIENTNO,STMTDATE,ARREARS7,ARREARS14,ARREARS21,ARREARS28,ARREARSOver)
   VALUES (@User,@ClientNo,getdate(),@curr,@dy30,@dy60,@dy90,@dy120)
   
   -- truncate table statements
  --  select * from statements

--GO


GO
/****** Object:  StoredProcedure [dbo].[AgingClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[AgingClients] -- Age_AmountsClient '27','ADEPT' 
	@AsAt datetime
	
as 
	declare @cust  varchar(50);
	declare @customer  varchar(10);
	declare @name  nvarchar(70);
	declare @curr  decimal(31,9);
	declare @dy30  decimal(31,9);
	declare @dy60  decimal(31,9);
	declare @dy90  decimal(31,9);
	declare @dy120 decimal(31,9);
	declare @Bal decimal(31,9);
	declare @dtrans date;
	declare @amt    decimal(31,9);
	declare @balbf decimal(31,9)
	declare @DateToday date
	declare @Client varchar(150)

	select @DateToday=GETDATE()
	
	
	--delete from STATEMENTS where [USER]=@User and CLIENTNO=@ClientNo
	set @curr =0;set @dy30 =0;set @dy60 =0;set @dy90 =0;set @dy120 =0;
	
	--merge into transactionsaging
	--using dealallocations
	--on dealallocations.dealno = transactionsaging.dealno 

	--when matched and (transactionsaging.transcode in ('sale','Purch','salecnl','purchcnl'))

	--then
	--	update set transactionsaging.matchid=dealallocations.mid
	--; 
	delete from TRANSACTIONSAGING where MatchID>1	
	declare BalancesCursor cursor  for 
		select  distinct clientno
		from tblClientbalances
		order by clientno
		
		open BalancesCursor
		
		FETCH NEXT FROM BalancesCursor INTO @customer
	  
		  WHILE @@FETCH_STATUS = 0
		  BEGIN

			declare dett cursor  for 
			select  amount as amt,transdate  as dtrans
			from transactionsaging 
			where clientno=@customer
			and matchid is null
			order by transdate --desc;
		   
			open dett;
	    
			  FETCH NEXT FROM dett INTO @amt,@dtrans;
			  WHILE @@FETCH_STATUS = 0
			  BEGIN
				   if @dtrans >= (DATEADD(dd,-7,@DateToday)) -- current 7 day period
					  set @curr = @curr + @amt;
				   
				   if (@dtrans >= (DATEADD(dd,-14,@DateToday))) and  --day 7 to day 14
					   (@dtrans < (DATEADD(dd,-7,@DateToday)))
					  set @dy30 = @dy30 + @amt;
				   if (@dtrans >= (DATEADD(dd,-21,@DateToday))) and --day 14 to day 21
					  (@dtrans < (DATEADD(dd,-14,@DateToday)))
					  set @dy60 = @dy60 + @amt;
				   if (@dtrans >= (DATEADD(dd,-28,@DateToday))) and --day 21 to day 28
					  (@dtrans < (DATEADD(dd,-21,@DateToday)))
					  set @dy90 = @dy90 + @amt;
				   if (@dtrans < (DATEADD(dd,-28,@DateToday))) --over 28days
					  set @dy120 = @dy120 + @amt;
				   FETCH NEXT FROM dett INTO @amt,@dtrans;     
		     END;
		     set @bal=@curr + @dy30+ @dy60+@dy90+@dy120;
		   CLOSE dett;
		  DEALLOCATE dett;
		  select @Client= ltrim(companyname+' '+title+' '+firstname+' '+surname)
		  from clients where clientno = @customer
		  update tblClientBalances set bal7=@curr,bal14=@dy30,bal21=@dy60,bal28=@dy90,balover=@dy120,client=@Client where clientno = @Customer
		  select  @curr=bal7+bal14+bal21+bal28  from tblclientbalances  where ClientNo = @Customer
		  update tblClientBalances set balover=balance-@curr where ClientNo = @Customer
		  set @curr =0;set @dy30 =0;set @dy60 =0;set @dy90 =0;set @dy120 =0;

	FETCH NEXT FROM BalancesCursor INTO @customer
	end
	CLOSE BalancesCursor
    DEALLOCATE BalancesCursor
    update tblClientBalances set category='OTHER' where clientno in(select clientno from clients where category not in('broker'))
	update tblClientBalances set category='BROKER' where clientno in(select clientno from clients where category  in('broker'))

GO
/****** Object:  StoredProcedure [dbo].[AgingClientsPD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[AgingClientsPD] -- Age_AmountsClient '27','ADEPT' 
	@ClientNo varchar(50)
	
as 
	declare @cust  varchar(50);
	declare @customer  varchar(10);
	declare @name  nvarchar(70);
	declare @curr  float;
	declare @dy30  float;
	declare @dy60  float;
	declare @dy90  float;
	declare @dy120 float;
	declare @Bal float;
	declare @dtrans date;
	declare @amt    float;
	declare @balbf float
	declare @DateToday date

	select @DateToday=GETDATE()
	
	--delete from STATEMENTS where [USER]=@User and CLIENTNO=@ClientNo
	set @curr =0;set @dy30 =0;set @dy60 =0;set @dy90 =0;set @dy120 =0;

    declare dett cursor  for 
    select  clientno,amount as amt,transdate  as dtrans
	from transactionsaging
	where clientno = @clientno
   -- and transdate>='20110725'
	order by transdate --desc;
   
  open dett;
    
  FETCH NEXT FROM dett INTO @customer,@amt,@dtrans;
  WHILE @@FETCH_STATUS = 0
  BEGIN

   if @dtrans >= (DATEADD(dd,-7,@DateToday)) -- current 7 day period
      set @curr = @curr + @amt;
   
   if (@dtrans >= (DATEADD(dd,-14,@DateToday))) and  --day 7 to day 14
       (@dtrans < (DATEADD(dd,-7,@DateToday)))
      set @dy30 = @dy30 + @amt;
   if (@dtrans >= (DATEADD(dd,-21,@DateToday))) and --day 14 to day 21
      (@dtrans < (DATEADD(dd,-14,@DateToday)))
      set @dy60 = @dy60 + @amt;
   if (@dtrans >= (DATEADD(dd,-28,@DateToday))) and --day 21 to day 28
      (@dtrans < (DATEADD(dd,-21,@DateToday)))
      set @dy90 = @dy90 + @amt;
   if (@dtrans < (DATEADD(dd,-28,@DateToday))) --over 28days
      set @dy120 = @dy120 + @amt;
   FETCH NEXT FROM dett INTO @customer,@amt,@dtrans;    
  END;
  set @bal=@curr + @dy30+ @dy60+@dy90+@dy120;
   CLOSE dett;
  DEALLOCATE dett;
  update tblClientBalances set bal7=@curr,bal14=@dy30,bal21=@dy60,bal28=@dy90,balover=@dy120 where clientno = @ClientNo




GO
/****** Object:  StoredProcedure [dbo].[AllClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AllClients]
@StartDate datetime='20000101',
@EndDate datetime='99991231'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.AltMobile,dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, dbo.Clients.Sector,dbo.Clients.UtilityType,
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName,dbo.clients.Bank,dbo.clients.BankAccountNo ,dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients LEFT JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     Category not in('transfer secretary') and Category not in('tax account') and ((DateAdded>@StartDate and DateAdded<@EndDate))
	order by Category desc, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName), dbo.Clients.ClientNo
END

GO
/****** Object:  StoredProcedure [dbo].[AllNMIRebates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		S. Kamonere
-- Create date: 23 Aug. 2011
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AllNMIRebates]  --  AllNMIRebates '20110731','ADEPT'
	@AsAt datetime
	,@User varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	exec PopulateRebates 'ALL',@User
    SELECT     dbo.Rebates.ClientNo, ROUND(SUM(dbo.Rebates.Amount), 2) AS NMIRebate
	FROM         dbo.Rebates INNER JOIN
						  dbo.CLIENTS ON dbo.Rebates.ClientNo = dbo.CLIENTS.ClientNo
	where TransDate<=@AsAt and [user]=@user
	GROUP BY dbo.Rebates.ClientNo
	HAVING      (ROUND(SUM(dbo.Rebates.Amount), 2) > 0)
	ORDER BY dbo.Rebates.ClientNo
END

--select * from rebates order by transdate desc
--truncate table rebates



GO
/****** Object:  StoredProcedure [dbo].[AllocatedDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AllocatedDeals]  --AllocatedDeals '20101007',1
	-- Add the parameters for the stored procedure here
	@DealDate as datetime
	,@Status as bit
AS
BEGIN
	SET NOCOUNT ON;
	--set @DealDate='18/05/2010'
    SELECT     TOP (100) PERCENT dbo.Dealallocations.ID, dbo.Dealallocations.DocketNo, dbo.Dealallocations.DealType, dbo.Dealallocations.DealNo, 
                      dbo.Dealallocations.DealDate, dbo.Dealallocations.ClientNo, dbo.Dealallocations.OrderNo, dbo.Dealallocations.Asset, dbo.Dealallocations.Qty, 
                      dbo.Dealallocations.Price, dbo.Dealallocations.Consideration, dbo.Dealallocations.GrossCommission, dbo.Dealallocations.NMIRebate, dbo.Dealallocations.BasicCharges, dbo.Dealallocations.StampDuty, 
                      dbo.Dealallocations.Approved, dbo.Dealallocations.SharesOut, dbo.Dealallocations.CertDueBy, dbo.Dealallocations.ChqNo, dbo.Dealallocations.ChqRqID, 
                      dbo.Dealallocations.ChqPrinted, dbo.Dealallocations.Cancelled, dbo.Dealallocations.Merged, dbo.Dealallocations.Comments,
                      dbo.Dealallocations.Adjustment, dbo.Dealallocations.CONSOLIDATED, 
                      dbo.Dealallocations.CancelLoginID, dbo.Dealallocations.CancelDate, dbo.Dealallocations.DateAdded, dbo.Dealallocations.VAT, 
                      dbo.Dealallocations.CapitalGains, dbo.Dealallocations.InvestorProtection, dbo.Dealallocations.CommissionerLevy, 
                      dbo.Dealallocations.ZSELevy, dbo.Dealallocations.DealValue, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName, 'N/A') 
                      AS Clientname,dbo.Dealallocations.ClientNo
FROM         dbo.Dealallocations INNER JOIN
                      dbo.Clients ON dbo.Dealallocations.ClientNo = dbo.Clients.ClientNo
WHERE     dbo.Clients.Category<>'BROKER' and (dbo.Dealallocations.DealDate =@DealDate) and (dbo.Dealallocations.Approved =@Status)and (dbo.Dealallocations.Merged =0) and (dbo.Dealallocations.Cancelled =0)
ORDER BY dbo.Dealallocations.Asset, dbo.Dealallocations.Qty DESC
END

GO
/****** Object:  StoredProcedure [dbo].[ApprovePayments]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 09 Dec 2010
-- Description:	Lists Payments to Approve
-- =============================================
CREATE PROCEDURE [dbo].[ApprovePayments]
	
AS
BEGIN
	update REQUISITIONS set [LOGIN]=ENTEREDBY where [LOGIN] is null
	declare @ApproveJournals bit
	SET NOCOUNT ON;
	select @ApproveJournals=approvejournals from BusinessRules
	
	if (@ApproveJournals=0)
	begin
		SELECT     TOP (100) PERCENT dbo.Requisitions.ReqID, dbo.Requisitions.ClientNo, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName) AS Payee, round(dbo.Requisitions.Amount,2) as Amount,DealNo, dbo.Requisitions.TransDate, 
	                      
						  dbo.Requisitions.[Description], dbo.Requisitions.CashBookID, dbo.CASHBOOKS.CODE AS CashAccount,dbo.Requisitions.[Login] as CapturedBy
		FROM         dbo.Clients INNER JOIN
						  dbo.Requisitions ON dbo.Clients.ClientNo = dbo.Requisitions.ClientNo INNER JOIN
						  dbo.CASHBOOKS ON dbo.Requisitions.CashBookID = dbo.CASHBOOKS.ID
		WHERE     (dbo.Requisitions.CANCELLED = 0) AND (dbo.Requisitions.Approved = 0) AND (dbo.Requisitions.TransCode LIKE '%due') OR
						  (dbo.Requisitions.CANCELLED = 0) AND (dbo.Requisitions.Approved = 0) AND (dbo.Requisitions.TransCode = 'pay')
		ORDER BY dbo.Requisitions.ReqID DESC
	end
	else
	begin
			SELECT     TOP (100) PERCENT dbo.Requisitions.ReqID, dbo.Requisitions.ClientNo, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName) AS Payee, round(dbo.Requisitions.Amount,2) as Amount, dbo.Requisitions.TransDate, 
	                      
						  dbo.Requisitions.[Description], dbo.Requisitions.CashBookID,  dbo.CASHBOOKS.CODE AS CashAccount,dbo.Requisitions.[Login] as CapturedBy
			FROM         dbo.Clients INNER JOIN
							  dbo.Requisitions ON dbo.Clients.ClientNo = dbo.Requisitions.ClientNo INNER JOIN
							  dbo.CASHBOOKS ON dbo.Requisitions.CashBookID = dbo.CASHBOOKS.ID
			WHERE     (dbo.Requisitions.CANCELLED = 0) AND (dbo.Requisitions.Approved = 0)
			ORDER BY dbo.Requisitions.ReqID DESC
	end
END

--select * from requisitions
GO
/****** Object:  StoredProcedure [dbo].[ApproveReceipts]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ApproveReceipts]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT     dbo.Clients.ClientNo, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS Payee, dbo.Requisitions.Amount, 
                      dbo.Requisitions.TransDate, CashBookID,dbo.CASHBOOKS.CODE as CashAccount, dbo.Requisitions.Method,ReqID,TransCode
FROM         dbo.Requisitions INNER JOIN
                      dbo.Clients ON dbo.Requisitions.ClientNo = dbo.Clients.ClientNo INNER JOIN
                      dbo.CASHBOOKS ON dbo.Requisitions.CashBookID = dbo.CASHBOOKS.ID
WHERE     (dbo.Requisitions.TransCode = 'REC') AND (dbo.Requisitions.Approved = 0) AND (dbo.Requisitions.CANCELLED = 0)
order by ReqID desc
END

GO
/****** Object:  StoredProcedure [dbo].[ArchiveAudit]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE      PROCEDURE [dbo].[ArchiveAudit]	(
	@DataBefore	datetime = 0
)
AS
declare @weekfirst int, @weeknow int, @yearnow int, @yearfirst int, @weekthen int, @yearthen int
declare @type int, @dt datetime, @description varchar(255), @username varchar(50), @pcname varchar(255), @data varchar(8000), @origdata varchar(8000)
declare @tbname varchar(50)
declare @idfirst int, @id int
declare @sql varchar(500)
BEGIN TRANSACTION
if @DataBefore < '2000/01/01' select @DataBefore = cast((floor(convert(float,getdate()))) as datetime)
select @yearnow = 0, @yearfirst = 0, @weeknow = 0, @weekfirst = 0, @idfirst = -1
select top 1 @weeknow = datepart(wk,getdate()), @yearnow = datepart(yyyy,getdate()), @weekfirst = datepart(wk,dt), @yearfirst = datepart(yyyy,dt), @idfirst = [id] from audit order by dt
if (@yearnow = @yearfirst) and (@weeknow = @weekfirst)
begin
	COMMIT TRANSACTION
	return 0
end
if @idfirst = -1
begin
	COMMIT TRANSACTION
	return 0
end
declare audit_cursor CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
	select [id],[type],[dt],[username],[description],[data],[origdata],[pcname] from audit where dt < @DataBefore order by [dt], [id]
open audit_cursor
fetch next from audit_cursor into @id,@type,@dt,@username,@description,@data,@origdata,@pcname
while @@FETCH_STATUS = 0
begin
	select @weekthen = datepart(wk,@dt), @yearthen = datepart(yyyy,@dt)
	if (@yearnow = @yearthen) and (@weeknow = @weekthen) --we've hit this week, stop processing...
		break
	select @tbname = 'AUDIT_W' + CAST(@weekthen as varchar(2)) + '_' + CAST(@yearthen as varchar(4))
	--create the table if it doesn't exist. We have use dynamic SQL coz table name has been dynamically generated
	select @sql = 'if not exists (select * from dbo.sysobjects where id = object_id(N''' + @tbname + ''') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)' + char(13) + char(10)
	select @sql = @sql + 'begin' + char(13) + char(10)
	select @sql = @sql + '	select * into ' + @tbname + ' from [audit] where [id] = ' + cast(@idfirst as varchar(20)) + char(13) + char(10)
	select @sql = @sql + '	delete from ' + @tbname + char(13) + char(10)
	select @sql = @sql + 'end'
	exec(@sql)
	--insert into the table
	select @sql = 'insert into ' + @tbname + ' ([type],[dt],[username],[description],[data],[origdata],[pcname]) select [type],[dt],[username],[description],[data],[origdata],[pcname] from audit where [id] = ' + cast(@id as varchar(20))
	exec(@sql)
	fetch next from audit_cursor into @id,@type,@dt,@username,@description,@data,@origdata,@pcname
end
delete from audit where dt < @DataBefore
close audit_cursor
deallocate audit_cursor
COMMIT TRANSACTION
return 0

GO
/****** Object:  StoredProcedure [dbo].[AssetPrices]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 9 Dec. 2010
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[AssetPrices]--AssetPrices '20101201','20101209','ABCHL-L'
	@StartDate as date='20101201'
	,@EndDate as date='20101209'
	,@Asset as varchar(100)='ABCHL-L'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
		SELECT     convert(varchar(9),Date, 6)as DATE, Sales,Volume
		FROM         dbo.PRICES
		WHERE     (Date >=@StartDate) AND (Date <=@EndDate)
		and ASSETCODE =@Asset
		order by DATE asc
		return
	
END

GO
/****** Object:  StoredProcedure [dbo].[AutoMatchPayments]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: Nov. 27 2011
-- Description:	Automatic Matching Of Payments
-- =============================================
CREATE PROCEDURE [dbo].[AutoMatchPayments]--  AutoMatchPayments 3650,'11' 
	@Period as int=7--days
	,@ClientNo varchar(50)
AS
BEGIN
	truncate table AutoMatch
	SET NOCOUNT ON;
	if (@ClientNo='ALL')
	begin
		insert into AutoMatch
		SELECT     TOP (100) PERCENT dbo.CASHBOOKTRANS.ClientNo, dbo.CASHBOOKTRANS.TransDate, dbo.CASHBOOKTRANS.TransCode, dbo.CASHBOOKTRANS.Amount, 
                      dbo.DEALALLOCATIONS.DealValue, dbo.DEALALLOCATIONS.DealDate, dbo.CASHBOOKTRANS.MID AS MatchID, dbo.DEALALLOCATIONS.DealNo, 
                      dbo.CASHBOOKTRANS.TRANSID
		FROM         dbo.CASHBOOKTRANS INNER JOIN
							  dbo.DEALALLOCATIONS ON dbo.CASHBOOKTRANS.ClientNo = dbo.DEALALLOCATIONS.ClientNo AND DATEADD(dd, - @period, dbo.CASHBOOKTRANS.TransDate) 
							  <= dbo.DEALALLOCATIONS.DealDate AND dbo.CASHBOOKTRANS.Amount = dbo.DEALALLOCATIONS.DealValue
		WHERE     (dbo.CASHBOOKTRANS.TransCode = 'PAY') AND (dbo.DEALALLOCATIONS.APPROVED = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.MERGED = 0) AND (dbo.CASHBOOKTRANS.Cancelled = 0) AND 
							  (dbo.DEALALLOCATIONS.DealNo LIKE 's%') AND (dbo.CASHBOOKTRANS.MID IS NULL)
		ORDER BY dbo.CASHBOOKTRANS.TransDate
	end
	else
	begin
		insert into AutoMatch
		SELECT     TOP (100) PERCENT dbo.CASHBOOKTRANS.ClientNo, dbo.CASHBOOKTRANS.TransDate, dbo.CASHBOOKTRANS.TransCode, dbo.CASHBOOKTRANS.Amount, 
                      dbo.DEALALLOCATIONS.DealValue, dbo.DEALALLOCATIONS.DealDate, dbo.CASHBOOKTRANS.MID AS MatchID, dbo.DEALALLOCATIONS.DealNo, 
                      dbo.CASHBOOKTRANS.TRANSID
		FROM         dbo.CASHBOOKTRANS INNER JOIN
							  dbo.DEALALLOCATIONS ON dbo.CASHBOOKTRANS.ClientNo = dbo.DEALALLOCATIONS.ClientNo AND DATEADD(dd, - @period, dbo.CASHBOOKTRANS.TransDate) 
							  <= dbo.DEALALLOCATIONS.DealDate AND dbo.CASHBOOKTRANS.Amount = dbo.DEALALLOCATIONS.DealValue
		WHERE     (dbo.CASHBOOKTRANS.ClientNo = @ClientNo) AND (dbo.CASHBOOKTRANS.TransCode = 'PAY') AND (dbo.DEALALLOCATIONS.APPROVED = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.MERGED = 0) AND (dbo.CASHBOOKTRANS.Cancelled = 0) AND 
							  (dbo.DEALALLOCATIONS.DealNo LIKE 's%') AND (dbo.CASHBOOKTRANS.MID IS NULL)
		ORDER BY dbo.CASHBOOKTRANS.TransDate
	end
	delete from automatch where transid in(SELECT  TRANSID FROM   dbo.AutoMatch GROUP BY TRANSID HAVING    (COUNT(TRANSID) > 1))
	delete FROM  dbo.AutoMatch  where dealno in( select dealno from AutoMatch GROUP BY DealNo HAVING (COUNT(DealNo) > 1))
END


GO
/****** Object:  StoredProcedure [dbo].[AutoMatchReceipts]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: Nov. 27 2011
-- Description:	Automatic Matching Of Payments
-- =============================================
CREATE PROCEDURE [dbo].[AutoMatchReceipts]--  AutoMatchReceipts 3650,'11' 
	@Period as int=7--days
	,@ClientNo varchar(50)
AS
BEGIN
	truncate table AutoMatch
	SET NOCOUNT ON;
	if (@ClientNo='ALL')
	begin
		insert into AutoMatch
		SELECT     TOP (100) PERCENT dbo.CASHBOOKTRANS.ClientNo, dbo.CASHBOOKTRANS.TransDate, dbo.CASHBOOKTRANS.TransCode, ABS(dbo.CASHBOOKTRANS.Amount) 
                      AS Amount, dbo.DEALALLOCATIONS.DealValue, dbo.DEALALLOCATIONS.DealDate, dbo.CASHBOOKTRANS.MID, dbo.DEALALLOCATIONS.DealNo, 
                      dbo.CASHBOOKTRANS.TRANSID
		FROM         dbo.CASHBOOKTRANS INNER JOIN
							  dbo.DEALALLOCATIONS ON dbo.CASHBOOKTRANS.ClientNo = dbo.DEALALLOCATIONS.ClientNo AND DATEADD(dd, - @period, dbo.CASHBOOKTRANS.TransDate) 
							  <= dbo.DEALALLOCATIONS.DealDate AND abs(dbo.CASHBOOKTRANS.Amount)  = dbo.DEALALLOCATIONS.DealValue
		WHERE     (dbo.CASHBOOKTRANS.TransCode = 'REC') AND (dbo.CASHBOOKTRANS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.APPROVED = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.MERGED = 0) AND 
							  (dbo.CASHBOOKTRANS.MID IS NULL) and (dbo.DEALALLOCATIONS.DealType like 'b%')
		ORDER BY dbo.CASHBOOKTRANS.TransDate
	end
	else
	begin
		insert into AutoMatch
		SELECT     TOP (100) PERCENT dbo.CASHBOOKTRANS.ClientNo, dbo.CASHBOOKTRANS.TransDate, dbo.CASHBOOKTRANS.TransCode, ABS(dbo.CASHBOOKTRANS.Amount) 
                      AS Amount, dbo.DEALALLOCATIONS.DealValue, dbo.DEALALLOCATIONS.DealDate, dbo.CASHBOOKTRANS.MID, dbo.DEALALLOCATIONS.DealNo, 
                      dbo.CASHBOOKTRANS.TRANSID
		FROM         dbo.CASHBOOKTRANS INNER JOIN
							  dbo.DEALALLOCATIONS ON dbo.CASHBOOKTRANS.ClientNo = dbo.DEALALLOCATIONS.ClientNo AND DATEADD(dd, - @period, dbo.CASHBOOKTRANS.TransDate) 
							  <= dbo.DEALALLOCATIONS.DealDate AND ABS(dbo.CASHBOOKTRANS.Amount) = dbo.DEALALLOCATIONS.DealValue
		WHERE     (dbo.CASHBOOKTRANS.TransCode = 'REC') AND (dbo.CASHBOOKTRANS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.APPROVED = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.MERGED = 0) AND (dbo.CASHBOOKTRANS.ClientNo = @ClientNo) AND 
							  (dbo.CASHBOOKTRANS.MID IS NULL) and (dbo.DEALALLOCATIONS.DealType like 'b%')
		ORDER BY dbo.CASHBOOKTRANS.TransDate
	end
	delete from automatch where transid in(SELECT  TRANSID FROM   dbo.AutoMatch GROUP BY TRANSID HAVING    (COUNT(TRANSID) > 1))
	delete FROM  dbo.AutoMatch  where dealno in( select dealno from AutoMatch GROUP BY DealNo HAVING (COUNT(DealNo) > 1))
END


GO
/****** Object:  StoredProcedure [dbo].[BackDatedEntries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S.Kamonere
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[BackDatedEntries]  -- BackDatedEntries '20130325','20131231'
	@StartDate datetime
	,@Enddate datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--create table #BDTxns (CNO varchar(50),POSTDT datetime,TRANSDT datetime,DEALNO varchar(50),QTY int,PRICE numeric(17,4),[LOGIN] varchar(50),AMOUNT numeric(17,4),TRANSCODE varchar(50), client varchar(150))
    set @StartDate=CONVERT(date,@StartDate)
    set @Enddate=CONVERT(date,@EndDate)
    truncate table BackDatedTxns
    insert into BackDatedTxns select x.ClientNo,x.PostDate,x.TransDate,x.DEALNO,0,0,x.[LOGIN],x.amount,x.TRANSCODE,
    coalesce(c.companyname, c.surname+' '+c.firstname) as client,'',@StartDate,@Enddate
    from CASHBOOKTRANS x inner join clients c on x.ClientNO = c.clientno
    where  (DATEDIFF(d, x.TRANSDate, x.PostDate) <> 0) 
    AND (x.TRANSCODE IN ('rec', 'reccnl', 'pay', 'paycnl','AINCJ','ADECJ') )
    and convert(date,x.PostDate)>=@StartDate and convert(date,x.PostDate)<=@Enddate
    
    insert into BackDatedTxns SELECT  x.ClientNO, x.PostDate, x.TransDate, x.DEALNO,d.QTY,d.PRICE,x.[LOGIN],x.AMOUNT,x.TRANSCODE,
    coalesce(c.companyname, c.surname+' '+c.firstname) as client ,d.Asset,@StartDate,@Enddate                    
	FROM        TRANSACTIONS x INNER JOIN
                      DEALALLOCATIONS d ON d.DEALNO = x.DEALNO
	inner join clients c on x.ClientNo = c.CLIENTNO                      
	WHERE     (DATEDIFF(d, x.TransDate, x.PostDate) <> 0) 
	AND (x.TRANSCODE IN ('sale', 'salecnl', 'purch', 'purchcnl'))
	and convert(date,x.PostDate)>=@StartDate and convert(date,x.PostDate)<=@Enddate
	
	--update backdatedtxns set startdate=@StartDate,enddate=@Enddate
     
END


GO
/****** Object:  StoredProcedure [dbo].[BalancesOnly]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--  balancesonly '20120205'



CREATE procedure [dbo].[BalancesOnly] --spdebtorsaging '20110215'
@AsAt datetime
as
declare @bal decimal(31,9), @bal7 decimal(31,9), @bal14 decimal(31,9), @bal21 decimal(31,9), @bal28 decimal(31,9), @balover decimal(31,9)
declare @cno varchar(50), @client varchar(300),@balance decimal(31,9)

set concat_null_yields_null off

truncate table tblClientBalances
--truncate table tblBalances
truncate table transactionsAging

insert into transactionsaging (transid,ClientNo,transdate,amount,transcode,MatchID,DealNo)
--insert into tblBalances
select TRANSID,t.ClientNo,transdate,Amount,transcode,d.chqrqid,t.DealNo from transactions t inner join DEALALLOCATIONS d 
on t.DealNo=d.DealNo
where t.YON=1 and ((t.TransCode = 'TAKEONDB' OR
				t.TransCode = 'TAKEONCR' OR
				t.TransCode = 'NMIRBT' OR
				t.TransCode = 'AINCJ' OR
			          t.TransCode = 'NMIRBTCNL' OR
                      t.TransCode = 'SALE' OR
                      t.TransCode = 'TPAYFEECNL' OR
                      t.TransCode = 'TPAYFEE' OR
                      t.TransCode = 'SALECNL' OR
                      t.TransCode = 'PURCH' OR
                      t.TransCode = 'PURCHCNL' OR
                      t.TransCode = 'DIVPAY' OR
                      t.TransCode = 'DIVREC'))

and TransDate<=@AsAt
insert into transactionsaging (transid,ClientNo,transdate,amount,transcode,MatchID)
select  TRANSID,ClientNo,transdate,amount,transcode,MatchID from CASHBOOKTRANS where YON=1 and TransDate<=@AsAt
update transactionsaging set Amount=-amount where TransCode like 'nmirbtd%' 
--select * from ACCOUNTSPARAMS
delete from TRANSACTIONSAGING where clientno in('150','151','152','153','154','155','156','157','158')
delete from TRANSACTIONSAGING where clientno in('203MMC','4793MMC','4792MMC','4762MMC','4769MMC','4768MMC')

--insert into tblBalances
--select clientno,sum(amount) from transactionsaging  as balance group by clientno -- and transcode not in ('rec','reccnl','pay','paycnl')

--update tblBalances set balance = 0 where balance is null

insert into tblClientBalances(clientno,balance) select clientno,sum(amount) from transactionsaging  as balance group by clientno 
update tblClientBalances set AsAt=@AsAt

update tblClientBalances set balance = 0 where balance is null
--alter table tblclientbalances add AsAt datetime













GO
/****** Object:  StoredProcedure [dbo].[BalancesOnlyOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE procedure [dbo].[BalancesOnlyOld] --spdebtorsaging '20110215'
@AsAt datetime
as
declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @cno varchar(50), @client varchar(300),@balance money

set concat_null_yields_null off

delete from tblClientBalances


declare crBalance cursor for
select clientno, ltrim(companyname+' '+title+' '+firstname+' '+surname)
	from clients
open crBalance

fetch next from crBalance into @cno, @client
while @@fetch_status = 0
begin
	select @balance=dbo.CalcClientBalance(@cno,@AsAt)
	--if (@balance>0)
	insert into tblClientBalances(clientno,client,balance) values (@cno, @client,@balance)--, '0', '0', '0', '0', '0',@AsAt)
	
	fetch next from crBalance into @cno, @client
end
close crBalance
deallocate crBalance













GO
/****** Object:  StoredProcedure [dbo].[BalancesOnlyPD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--  balancesonly '20120205'



create procedure [dbo].[BalancesOnlyPD] --spdebtorsaging '20110215'
@AsAt datetime
as
declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @cno varchar(50), @client varchar(300),@balance money

set concat_null_yields_null off

truncate table tblClientBalances
truncate table tblBalances
truncate table transactionsAging

insert into transactionsaging (transid,ClientNo,transdate,amount,transcode)
--insert into tblBalances
select TRANSID,ClientNo,postdate,Amount,transcode from transactions
where YON=1 and ((dbo.Transactions.TransCode = 'TAKEONDB' OR
				dbo.Transactions.TransCode = 'TAKEONCR' OR
				dbo.Transactions.TransCode = 'NMIRBT' OR
				dbo.Transactions.TransCode = 'AINCJ' OR
			          dbo.Transactions.TransCode = 'NMIRBTCNL' OR
                      dbo.Transactions.TransCode = 'SALE' OR
                      dbo.Transactions.TransCode = 'TPAYFEECNL' OR
                      dbo.Transactions.TransCode = 'TPAYFEE' OR
                      dbo.Transactions.TransCode = 'SALECNL' OR
                      dbo.Transactions.TransCode = 'PURCH' OR
                      dbo.Transactions.TransCode = 'PURCHCNL' OR
                      dbo.Transactions.TransCode = 'DIVPAY' OR
                      dbo.Transactions.TransCode = 'DIVREC'))

and postdate<=@AsAt
insert into transactionsaging (transid,ClientNo,transdate,amount,transcode)
select  TRANSID,ClientNo,postdate,amount,transcode from CASHBOOKTRANS where YON=1 and postdate<=@AsAt
update transactionsaging set Amount=-amount where TransCode like 'nmirbtd%' 
--select * from ACCOUNTSPARAMS
delete from TRANSACTIONSAGING where clientno in('150','151','152','153','154','155','156','157','158')
delete from TRANSACTIONSAGING where clientno in('203MMC','4793MMC','4792MMC','4762MMC','4769MMC','4768MMC')

insert into tblBalances
select clientno,sum(amount) from transactionsaging  as balance group by clientno -- and transcode not in ('rec','reccnl','pay','paycnl')

update tblBalances set balance = 0 where balance is null

insert into tblClientBalances(clientno,balance) select ClientNo,balance from tblBalances-- group by clientno
update tblClientBalances set AsAt=@AsAt

--alter table tblclientbalances add AsAt datetime













GO
/****** Object:  StoredProcedure [dbo].[CancelBrokerDeal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 03-01-2013
-- Description:	Reverses broker deal
-- =============================================
create PROCEDURE [dbo].[CancelBrokerDeal] 
	-- Add the parameters for the stored procedure here
	@DealNo varchar(50)
	,@User varchar(50)
	,@Reason varchar(150)
AS
BEGIN
	declare @DocketNo int
	SET NOCOUNT ON;
	begin transaction
		select @DocketNo=DocketNo from DEALALLOCATIONS where DealNo=@DealNo
		insert into Transactions([LOGIN],ClientNo,PostDate,DEALNO,TRANSCODE,TransDate,[DESCRIPTION],AMOUNT,AmountOldFalcon,Consideration)
		select @User,ClientNo,GetDate(),DealNo,TransCode+'CNL',TransDate,[Description]+' CANCELLATION',-Amount,-AmountOldFalcon,-Consideration
		from transactions where dealno=@Dealno
		
		update DEALALLOCATIONS set Cancelled=1,CancelDate=GETDATE(),CancelLoginID=@User,CancelReason=@reason where DealNo=@DealNo
		update DOCKETS set [STATUS]='CANCELLED',CancelDate=GETDATE(),CancelledBy=@User where DocketNo=@DocketNo
	commit
END

GO
/****** Object:  StoredProcedure [dbo].[CancelJournal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[CancelJournal]
	-- Add the parameters for the stored procedure here
	@TransID int
	,@User varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    insert into CASHBOOKTRANS
	([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[DESCRIPTION],[AMOUNT],CASHBOOKID,Cancelled, ChqRqID,MatchID,OriginalTransID)
	select 
	@User,[ClientNo],GETDATE(),[DEALNO],[TRANSCODE]+'CNL',[TransDate],[DESCRIPTION]+' CANCELLATION',-[AMOUNT],CASHBOOKID,1, ChqRqID,MatchID,@TransID 
	from cashbooktrans where transid=@TransID
	update CASHBOOKTRANS set Cancelled=1 where TRANSID=@TransID
	
END

GO
/****** Object:  StoredProcedure [dbo].[CancelRebate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[CancelRebate]
	-- Add the parameters for the stored procedure here
	@ChqRqID int
	,@User varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    insert into CASHBOOKTRANS
	([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[DESCRIPTION],[AMOUNT],CASHBOOKID,Cancelled, ChqRqID,MatchID,OriginalTransID)
	select 
	@User,[ClientNo],GETDATE(),[DEALNO],[TRANSCODE]+'CNL',[TransDate],[DESCRIPTION]+' CANCELLATION',-[AMOUNT],CASHBOOKID,1, ChqRqID,MatchID,TransID 
	from cashbooktrans where ChqRqID=@ChqRqID
	update CASHBOOKTRANS set Cancelled=1 where ChqRqID=@ChqRqID
	
END

GO
/****** Object:  StoredProcedure [dbo].[ChangeZSEOrderNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: June 26 2012
-- Description:	Manages changes in ZSE order number
-- =============================================
CREATE PROCEDURE [dbo].[ChangeZSEOrderNo] 
	@AssetID int
	,@NewOrderNo int
AS
BEGIN
	declare @OldZSEOrderNo int
	SET NOCOUNT ON;

    select @OldZSEOrderNo=ZSEOrderNo from assets where assetid=@AssetID
    update assets set zseorderno=(zseorderno +1) where zseorderno>=@NewOrderNo
    --update assets set zseorderno=@NewOrderNo where assetid=@AssetID
                    
END


GO
/****** Object:  StoredProcedure [dbo].[CheckAccess]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[CheckAccess]	(
	@Username		varchar(50),
	@Module			varchar(50),
	@Screen			varchar(50),
	@Allow			bit		output
				)
AS
declare @Profile varchar(50), @Maint bit, @Locked bit, @Data varchar(1000), @Host varchar(512)
select @Allow = 0
select @Data = 'MODULE = ' + @Module + char(13) + char(10) + 'SCREEN = ' + @Screen
select @Host = HOST_NAME()
SELECT @Profile = [PROFILE], @Maint = SYSTEMAINT, @Locked = ISLOCKED
FROM [USERS] WHERE [LOGIN] = @Username
if (@Profile = "") Or (@Profile is null) or (@Locked = 1)
begin
	if @Locked = 1
	begin
		insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
		values (8,getdate(),@Username,'USER ACCOUNT LOCKED',@Data,NULL,@Host)
	end
	else
	begin
		insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
		values (8,getdate(),@Username,'USER PROFILE NOT FOUND',@Data,NULL,@Host)
	end
        return 0
end
if @Maint = 1
begin
	select @Allow = 1
	insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
	values (7,getdate(),@Username,'USER IS A SYSTEM MAINTAINER',@Data,NULL,@Host)
        return 0
end
if	(SELECT count(*) FROM [PERMISSIONS] P, MODULES M, SCREENS S
	WHERE	(P.ACCESS = 1) AND (P.SCREEN = S.[ID]) AND (S.MOD = M.MID) AND
		(P.[PROFILE] = @Profile) AND (M.MODNAME = @Module) AND
		(S.[NAME] = @Screen)
	) > 0
	select @Allow = 1
if @Allow = 1
begin
	insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
	values (7,getdate(),@Username,'PERMISSION GRANTED',@Data,NULL,@Host)
end
else
begin
	insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
	values (8,getdate(),@Username,'PERMISSION DENIED',@Data,NULL,@Host)
end
return 0

GO
/****** Object:  StoredProcedure [dbo].[CheckShareJobbing]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CheckShareJobbing] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	select dealdate, asset, sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end) as 'NETQTY',sum(case d.dealtype when 'BUY' then -d.consideration when 'SELL' then d.consideration end) as 'NETCONS'
	from dealallocations d
	where (dealdate <= GETDATE()) and (approved=1) and (merged=0) and (cancelled=0) and (consolidated = 0)
	and	(
		(comments ='') or
		(comments is null) or
		(comments like '%ADJUSTMENT%')
		)
	group by dealdate, asset
	having (sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end)) <> 0
	order by dealdate
END

GO
/****** Object:  StoredProcedure [dbo].[ClientPortfolio]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Simpson Kamonere
-- Create date: Dec 9 2010
-- Description:	Creates Client Portfolio
-- =============================================
CREATE PROCEDURE [dbo].[ClientPortfolio]  --ClientPortfolio '960PLT','SIMPSON'
	-- Add the parameters for the stored procedure here
	@ClientNo as varchar(50)
	,@User as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	declare @MktPrice float
	SET NOCOUNT ON;
	delete  from CustPort where  [User] =@User
	insert into CustPort ([User],ClientNo,Asset,PortDate,Shares,Cost,MktPrice,MktValue,TotalCost,Profit)
	select @User,@ClientNo,Asset,getDate(),sum(case d.dealtype  when 'BUY' then d.sharesout  when 'SELL' then -d.sharesout  end) as Shares,  AVG(Price) AS CostPrice,0,0,0,0
	from dealallocations d where sharesout <>0 and (ClientNo=@ClientNo) and (approved=1) and (merged=0) and (cancelled=0) and (consolidated=0)  group by asset  --order by d.dealdate
	UNION ALL
	select @User,@ClientNo,Asset, GETDATE() as DealDate,qty  as Shares,0,0,0,0,0 from scripledger where id in (select ledgerid from scripsafe where (ClientNo=@ClientNo) and closed=0 and ledgerid not in(select ledgerid from scripdealscerts where cancelled=0))

	--select @MktPrice=ltp from PRICES where ASSETCODE=@asset
	--Total Cost
	declare @Shares int
	declare @Cost float
	declare @Asset varchar(50)
	declare Cost_Cursor cursor for
	select asset, SUM(Shares) AS Shares, SUM(Cost) AS Cost  from CustPort where [USER]= @User and ClientNo= @clientNo  group by asset--, transid asc --where DT >= @LastDate and DT <= @EndDate order by DT asc

	open Cost_Cursor

	fetch next from Cost_Cursor into @Asset,@shares,@cost
	

	while @@fetch_status = 0
	begin
	   select top 1 @MktPrice=sales from PRICES where ASSETCODE=@asset order by pricesdate desc
	   
	   update CustPort set TotalCost=((@Shares*@Cost)/100) where [USER]= @User and ClientNo= @clientNo and asset=@Asset
	   update CustPort set MktPrice=@MktPrice where [USER]= @User and ClientNo= @clientNo and asset=@Asset
	   update CustPort set MktValue=((@Shares*@MktPrice)/100) where [USER]= @User and ClientNo= @clientNo and asset=@Asset
	   update CustPort set Profit=(MktValue-TotalCost)where [USER]= @User and ClientNo= @clientNo and asset=@Asset
	   fetch next from Cost_Cursor into @Asset,@shares,@cost
	   
	end
	close Cost_Cursor
	deallocate Cost_Cursor
END

GO
/****** Object:  StoredProcedure [dbo].[ClientsBasicInfo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ClientsBasicInfo] 
AS
BEGIN
	SET NOCOUNT ON;
	SELECT     ClientNo, COALESCE (Surname + ' ' + Firstname,CompanyName,'N/A') AS Clientname, IDNo,Category
	FROM         dbo.Clients
	where Category not in('broker','transfer secretary','tax account')
END

GO
/****** Object:  StoredProcedure [dbo].[ConfirmBrokerDeal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{														}
{		Author: S. Kamonere								}
{														}
{		Copyright (c) 21 July 2011						}
{														}
{*******************************************************}
Return Values:
0	Success
-1	Failure
*/
 CREATE           PROCEDURE [dbo].[ConfirmBrokerDeal]	( -- ConfirmBrokerDeal 'CMWASHAIRENI','278602','S/32353'
	@User			varchar(20)=NULL,
	@RefNo			varchar(50),
	@DealNo			varchar(40) = NULL
	
) 
AS


declare @TransDate datetime
declare @ClientNo varchar(50)
declare @TransCode varchar(50)
declare @Consideration decimal(31,9)
declare @Description varchar(50),@asset varchar(50)
declare @DocketNo int,@qty int

BEGIN TRANSACTION
	select @TransDate=dealdate,@DocketNo=DOCKETNO,@ClientNo=ClientNo,@TransCode=DEALTYPE,@Consideration=CONSIDERATION 
	,@qty=qty,@asset=asset from Dealallocations where DealNo=@DealNo

	if (@TransCode='BUY')
	begin
		select @TransCode='PURCH',@Description='DEAL PURCHASE'
		exec spScripBalancingProcess 'PURCH',@qty,0,@asset	
	end
	else if (@TransCode='SELL')
	begin
		select @TransCode='SALE',@Consideration=-@Consideration,@Description='DEAL SALE'
		exec spScripBalancingProcess 'SALE',@qty,0,@asset
	end

	insert into Transactions
	([LOGIN],ClientNo,PostDate,DEALNO,TRANSCODE,TransDate,[DESCRIPTION],AMOUNT,Amountoldfalcon,Consideration,ARREARSBF,ARREARSCF)
	values
	(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@TransDate,@Description,@Consideration,@Consideration,@Consideration,0,0)

	--updating dockets table
	update dockets set [status]='CONFIRMED',zserefno=@RefNo where docketno=@DocketNo
	--updating dealallocations table
	update dealallocations set approved=1,approvedby=@User where docketno=@DocketNo and clientno=@ClientNo
COMMIT TRANSACTION

GO
/****** Object:  StoredProcedure [dbo].[CreditorsAging]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [dbo].[CreditorsAging] --[DebtorsAging]'20110513'
@AsAt datetime
as
--declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @ClientNo varchar(50), @accamount money, @category varchar(50), @Client varchar(150)
--delete from tblbalances 


set concat_null_yields_null off

exec BalancesOnly @AsAt
delete from tblClientBalances where balance >= 0
exec agingclients  @AsAt



GO
/****** Object:  StoredProcedure [dbo].[CreditorsAgingOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[CreditorsAgingOld]
@AsAt datetime
as
declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @ClientNo varchar(50)
delete from tblbalances 

set concat_null_yields_null off
--Simpson added
truncate table transactionsaging 
truncate table tblBalancesTemp
truncate table tblBalances
truncate table tblClientBalances

insert into transactionsaging (transid,ClientNo,transdate,amount)
--insert into tblBalances
select TRANSID,ClientNo,transdate,AmountOldFalcon as amount from transactions
where TransDate<=@AsAt


insert into transactionsaging (transid,ClientNo,transdate,amount)
select  TRANSID,ClientNo,transdate,amount from CASHBOOKTRANS where transcode not like('nmi%') and (transdate <= @Asat)


--insert into tblBalances
--select  x.ClientNo,
--(select sum(a.amount) from transactionsaging a where a.ClientNo = x.ClientNo and a.TransDate <= @AsAt) as balance 
--from transactions x
--where x.ClientNo not in('6526MMC','6005MMC','6004MMC','5782MMC','5770MMC','1374MMC','310MMC','361MMC','5771MMC')
--group by x.ClientNo
--order by x.ClientNo
insert into tblBalances
select clientno,sum(amount) from transactionsaging where ClientNo not in('6526MMC','6005MMC','6004MMC','5782MMC','5770MMC','1374MMC','310MMC','361MMC','5771MMC')
group by ClientNo
order by ClientNo


update tblBalances set balance = 0 where balance is null
delete from tblClientBalances


declare crBalance cursor for
select ClientNo,balance from tblBalances
where balance < 0
--end
open crBalance
fetch next from crBalance into @ClientNo, @bal
while @@fetch_status = 0
begin
select @bal7 =0, @bal14 =0, @bal21 = 0, @bal28 =0
--if (@bal > 0)
--begin
 select @bal7 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-7,@AsAt)
 and TransDate <= @AsAt  
 select @bal14 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-14,@AsAt)
 and TransDate <= dateadd(day,-7,@AsAt) 
 select @bal21 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-21,@AsAt)
 and TransDate <= dateadd(day,-14,@AsAt)  
 select @bal28 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-28,@AsAt)
 and TransDate <= dateadd(day,-21,@AsAt)/**/   
 select @balover = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 --and postdt > dateadd(day,-28,@AsAt)
 and TransDate <= dateadd(day,-28,@AsAt)
--end 
insert into tblClientBalances(ClientNo, client,balance, bal7, bal14, bal21, bal28, balover)
select @ClientNo, ltrim(companyname+' '+title+' '+firstname+' '+surname),
@bal, @bal7, @bal14, @bal21, @bal28, @balover
from clients
where clientno = @ClientNo
fetch next from crBalance into @ClientNo, @bal
end
close crBalance
deallocate crBalance


update tblClientBalances set category ='BROKERS' where ClientNo in(select ClientNo from CLIENTS where category='broker')
update tblClientBalances set category ='NON-BROKERS' where category is null
update tblClientBalances set ADate =@AsAt



GO
/****** Object:  StoredProcedure [dbo].[CreditorsAgingPD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create procedure [dbo].[CreditorsAgingPD] --[DebtorsAging]'20110513'
@AsAt datetime
as
--declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @ClientNo varchar(50), @accamount money, @category varchar(50), @Client varchar(150)
--delete from tblbalances 


set concat_null_yields_null off

exec BalancesOnlyPD @AsAt
update tblBalances set balance = 0 where balance is null

declare crBalance cursor for
select ClientNo from tblBalances
where balance < 0

open crBalance
--select @accamount = 0
fetch next from crBalance into @ClientNo
while @@fetch_status = 0
begin
	select @Client= ltrim(companyname+' '+title+' '+firstname+' '+surname)
	from clients where clientno = @ClientNo

	update tblClientBalances set client= @client where clientno = @ClientNo
	exec agingclientsPD @ClientNo

	fetch next from crBalance into @ClientNo
end
close crBalance
deallocate crBalance
 
update tblClientBalances set category='OTHER' where clientno in(select clientno from clients where category not in('broker'))
update tblClientBalances set category='BROKER' where clientno in(select clientno from clients where category  in('broker'))
--select * from tblClientBalances



GO
/****** Object:  StoredProcedure [dbo].[DealCharges]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[DealCharges]--DealCharges '20101004','20101009','StampDuty'
	@StartDate as date
	,@EndDate as date
	,@Charge as varchar(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	if (@Charge='Commission')
	begin
		SELECT     convert(varchar(9),DealDate, 6)as DealDate, round(SUM(GrossCommission),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='BasicCharge')
	begin
		SELECT     convert(varchar(9),DealDate, 6) as DealDate, round(SUM(BasicCharges),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='SECLevy')
	begin
		SELECT     convert(varchar(9),DealDate, 6) as DealDate, round(SUM(CommissionerLevy),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='StampDuty')
	begin
		SELECT     convert(varchar(9),DealDate, 6) as DealDate, round(SUM(StampDuty),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='VAT')
	begin
		SELECT     convert(varchar(9),DealDate, 6) as DealDate, round(SUM(VAT),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='InvestorProtection')
	begin
		SELECT     convert(varchar(9),DealDate, 6) as DealDate, round(SUM(InvestorProtection),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='ZSELevy')
	begin
		SELECT     CONVERT(VARCHAR(9), DealDate, 6) as DealDate, round(SUM(ZSELevy),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
	if (@Charge='CapitalGains')
	begin
		SELECT     CONVERT(VARCHAR(9), DealDate, 6) as DealDate, round(SUM(CapitalGains),2) AS Commission
		FROM         dbo.Dealallocations
		WHERE     (DealDate >= @StartDate) AND (DealDate <= @EndDate) and Approved=1 and Merged=0 and Cancelled=0
		GROUP BY DealDate
		return
	end
END

GO
/****** Object:  StoredProcedure [dbo].[DealChargesTransact]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{														}
{		Author: Simpson Kamonere						}
{														}
{		Copyright (c) 2010								}
{														}
{*******************************************************}
Return Values:
0	Success
-1	Failure
*/
 CREATE           PROCEDURE [dbo].[DealChargesTransact]	( --[DealChargesTransact] 'B/2','Debit'
	@DealNo			varchar(50),
	@DrCr varchar(50),
	@User varchar(50) )
	
 
AS


declare @BF decimal(38,4), @CF decimal(38,4)
declare @IsCredit bit
declare @Amount decimal(38,4)
declare @LedgerID varchar(50)
declare @DealType varchar(50)
declare @Description varchar(50)
declare @Balance decimal(38,4)
declare @ClientNo varchar(50)



select @BF = 0, @CF = 0

declare @Commission decimal(32,4)
declare @Vat decimal (32,4)
declare @StampDuty decimal(32,4)
declare @ZSELevy decimal (32,4)
declare @CapTax decimal(32,4)
declare @InvProt decimal (32,4)
declare @SecLevy decimal(32,4)
declare @NMIRebate decimal (32,4)
declare @Bfee decimal(32,4)
declare @CSDLevy decimal(32,4) --added 17 July 2014 by G.Mhlanga
declare @DealValue decimal(32,4)
declare @Consideration decimal(32,4)
declare @TransDate datetime

Begin Transaction
select @ClientNo=ClientNo,@TransDate=dealdate,@DealType=DealType,@Commission=GrossCommission,@vat=vat,@StampDuty=StampDuty,@ZSELevy=ZSELevy,@CapTax=CapitalGains,@InvProt=InvestorProtection,@SecLevy=CommissionerLevy,@NMIRebate=NMIRebate,@Bfee=BasicCharges,@DealValue=DealValue,@Consideration=CONSIDERATION, @CSDLevy = CSDLevy
from Dealallocations where DealNo=@DealNo
--select @TransDate=dealdate from Dealallocations where DealNo=@DealNo
--select dealdate from Dealallocations where DealNo='B/107'

if (@DrCr='Credit')--Crediting charges accounts when either sale or buy deal is approved
begin
	update dealallocations set approved=1,ApprovedBy=@User where dealno=@DealNo --dealallocations approval
	
	if (@DealType='BUY')
	begin
		select @DealType='PURCH'
		select @Description='PURCHASE DEAL'
	end
	else if (@DealType='SELL')
	begin
		select @DealType='SALE'	
		select @Description='SALE DEAL'
		select @DealValue=-@DealValue --sale transactions posted as negative
		select @Consideration=-@Consideration --sale transactions posted as negative
	end	
	
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values(@ClientNo,getdate(),@DealNo,@DealType,@TransDate,@Description,@DealValue,@Consideration)-- from Dealallocations where dealno=@DealNo

	
	if (@Commission<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values('150',getdate(),@DealNo,'COMMS',@TransDate,'COMMISSION',@Commission,@Commission)-- from Dealallocations where dealno=@DealNo

	if (@Vat<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values('151',getdate(),@DealNo,'VATCOMM',@TransDate,'VAT',@VAT,@VAT)

	if (@StampDuty<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '152',getdate(),@DealNo,'SDUTY',@TransDate,'STAMP DUTY',@StampDuty,@StampDuty)

	if(@ZSELevy<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '153',getdate(),@DealNo,'ZSELV',@TransDate,'ZSE LEVY',@ZSELevy,@ZSELevy)

	if(@CapTax<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '154',getdate(),@DealNo,'CAPTAX',@TransDate,'CAPITAL GAINS TAX',@CapTax,@CapTax)

	if (@InvProt<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '155',getdate(),@DealNo,'INVPROT',@TransDate,'INVESTOR PROTECTION LEVY',@InvProt,@InvProt)

	if (@SecLevy<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '156',getdate(),@DealNo,'COMMLV',@TransDate,'SECURITIES AND EXCHANGE COMMISSION LEVY',@SecLevy,@SecLevy)
	
	if(@NMIRebate<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '157',getdate(),@DealNo,'NMIRBT',@TransDate,'NMI REBATE',-@NMIRebate,-@NMIRebate)
	
	if(@Bfee<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '158',getdate(),@DealNo,'BFEE',@TransDate,'BASIC CHARGE',@Bfee,@Bfee)
	
	if(@CSDLevy<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '159',getdate(),@DealNo,'CSDLV',@TransDate,'CENTRAL SECURITIES DEPOSITORY LEVY',@CSDLevy,@CSDLevy)
	
	update TRANSACTIONS set amountoldfalcon=AMOUNT,[LOGIN]=@User where DEALNO=@DealNo and TRANSCODE not like '%cnl'
	--update DEALALLOCATIONS set AmtOwed=DealValue where DealNo=@DealNo
end
else if (@DrCr='Debit')--Debiting charges when deal is reversed
begin
	if (@DealType='BUY')
	begin
		select @DealType='PURCHCNL'
		select @Description='PURCHASE DEAL CANCELLATION'
		select @DealValue=-@DealValue --purchase cancellation transactions posted as negative
		select @Consideration=-@Consideration --purchase cancellation  transactions posted as negative
	end
	else if (@DealType='SELL')
	begin
		select @DealType='SALECNL'	
		select @Description='SALE DEAL CANCELLATION'
		
	end	
	
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values(@ClientNo,getdate(),@DealNo,@DealType,@TransDate,@Description,@DealValue,@Consideration)-- from Dealallocations where dealno=@DealNo

	
	if(@commission<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '150',getdate(),@DealNo,'COMMSCNL',@TransDate,'COMMISSION CANCELLATION',-@Commission,-@Commission)

	if(@vat<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '151',getdate(),@DealNo,'VATCOMMCNL',@TransDate,'VAT CANCELLATION',-@VAT,-@VAT)

	if(@stampduty<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '152',getdate(),@DealNo,'SDUTYCNL',@TransDate,'STAMP DUTY CANCELLATION',-@StampDuty,-@StampDuty)

	if(@zselevy<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '153',getdate(),@DealNo,'ZSELVCNL',@TransDate,'ZSE LEVY CANCELLATION',-@ZSELevy,-@ZSELevy)

	if(@captax<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '154',getdate(),@DealNo,'CAPTAXCNL',@TransDate,'CAPITAL GAINS TAX CANCELLATION',-@CapTax,-@CapTax)

	if(@invprot<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration,ARREARSBF,ARREARSCF)
	values( '155',getdate(),@DealNo,'INVPROTCNL',@TransDate,'INVESTOR PROTECTION LEVY CANCELLATION',-@InvProt,-@InvProt,dbo.CalcTaxBalance('155','INVPROT',''),case dbo.CalcTaxBalance('155','INVPROT','') 
	when 0 then @InvProt else( dbo.CalcTaxBalance('155','INVPROT','')-@InvProt) end)

	if(@seclevy<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '156',getdate(),@DealNo,'COMMLVCNL',@TransDate,'COMMISSIONERS LEVY CANCELLATION',-@SecLevy,-@SecLevy)
	
	if(@nmirebate<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '157',getdate(),@DealNo,'NMIRBTCNL',@TransDate,'NMI REBATE CANCELLATION',@NMIRebate,@NMIRebate)
	
	if(@Bfee<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '158',getdate(),@DealNo,'BFEECNL',@TransDate,'BASIC CHARGE CANCELLATION',-@bfee,-@bfee)
	
	if(@csdlevy<>0)
	insert into Transactions (ClientNo,PostDate,DealNo,Transcode,TransDate,[Description],Amount,Consideration)
	values( '159',getdate(),@DealNo,'CSDLVCNL',@TransDate,'CSD LEVY CANCELLATION',-@CSDLevy,-@CSDLevy)
	
	update TRANSACTIONS set amountoldfalcon=AMOUNT,[LOGIN]=@user where DEALNO=@DealNo and TRANSCODE like '%cnl'
	select @CF=0
end
Commit Transaction

GO
/****** Object:  StoredProcedure [dbo].[DealsDue]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 25-10-2012
-- Description:	Lists deals due for settlement
-- =============================================
create PROCEDURE [dbo].[DealsDue] 
@AsAt datetime
	AS
BEGIN
SET NOCOUNT ON;
	
	declare @CertDueBy int
	
	select @CertDueBy=certdueby from SystemParams --get settlement period in days
	if (@CertDueBy is null)
		set @CertDueBy=7
		
	truncate table DealsDueTable
	insert into DealsDueTable
	select c.clientno,d.asset,d.Qty,d.DealType,COALESCE (C.Surname + ' ' + C.Firstname, C.CompanyName) AS ClientName,D.DealValue,c.CATEGORY,d.SHARESOUT,d.DEALNO,@AsAt  
	from dealallocations d inner join CLIENTS c on
	d.ClientNo=c.CLIENTNO
	where DATEDIFF(d,d.DealDate,@AsAt)=@CertDueBy
	and d.approved=1
	and d.cancelled=0
	and d.merged=0
END

--select * from dealsduetable

GO
/****** Object:  StoredProcedure [dbo].[DealsReconciliation]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE   PROCEDURE [dbo].[DealsReconciliation](@BrokersOnly bit = 1)
AS
/*
delete from recondeals
--set identity_insert recondeals on
insert into recondeals
	select	dealtype,dealno,dealdate,
		case purchasedfrom when 0 then soldto else purchasedfrom end,	-- clientno
		asset,qty,price,
		case purchasedfrom when 0 then null else consideration - (commission + basiccharges + contractstamps + transferfees + wtax) end,	-- considerationTO
		case purchasedfrom when 0 then consideration + commission + basiccharges + contractstamps + transferfees else null end,		-- considerationFROM
		commission,basiccharges,contractstamps,transferfees,dealer,
		case purchasedfrom when 0 then sharesout else null end,										-- sharesoutTO
		case purchasedfrom when 0 then null else sharesout end										-- sharesoutFROM
	from dealallocations
	where (approved = 1) and ((sharesout > 0) or (chqprinted = 0)) and (cancelled = 0) and (merged = 0)
if @BrokersOnly = 1
	delete from recondeals where clientno not in
		(select clientno from clients c where (c.clientno = recondeals.clientno) and (c.category = 'BROKER'))
*/
return 0

GO
/****** Object:  StoredProcedure [dbo].[DealsReconciliationEx]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005,2006		}
{							}
{*******************************************************}
*/
CREATE                  PROCEDURE [dbo].[DealsReconciliationEx]	(
	@AsAt	datetime,
	@BrokersOnly bit = 1,
	@SpecificClient int = -1,
	@SpecificAsset varchar(50) = ''
	--@Cons int = 0
						)
AS
declare @purchasedfrom int, @soldto int, @sharesout int, @chqprinted bit
declare @consideration money, @commission money, @basiccharges money, @wtax money
declare @transferfees money, @contractstamps money, @dealer varchar(50)
declare @asset varchar(50), @qty int, @price money, @dealtype varchar(20)
declare @dealno varchar(50), @dealdate datetime, @chqno int
declare @datepaid datetime, @datedelivered datetime, @toadd bit
declare @clientno int, @missing_cash bit, @missing_scrip bit
declare @totalshares int, @totalcash money
declare	@totalcontras int

declare @SharesTo int, @SharesFrom int, @ConsiderTo decimal(34,6), @ConsiderFrom decimal(34,6)




--declare deals_cursor cursor FAST_FORWARD READ_ONLY for
declare deals_cursor cursor FORWARD_ONLY STATIC READ_ONLY for
	select	dealtype, dealno, dealdate, purchasedfrom, soldto, sharesout,
		consideration, commission, basiccharges, contractstamps, wtax,
		transferfees, dealer, chqprinted, chqno, asset, price, qty
	from dealallocations
	where	(approved = 1) and (cancelled = 0) and (merged = 0)
     --and((soldto = 1899) or (purchasedfrom = 1899))
	order by [id]
delete from recondeals
open deals_cursor
fetch next from deals_cursor into @dealtype, @dealno, @dealdate, @purchasedfrom, @soldto, @sharesout,
		@consideration, @commission, @basiccharges, @contractstamps, @wtax,
		@transferfees, @dealer, @chqprinted, @chqno, @asset, @price, @qty
while @@FETCH_STATUS = 0
begin
	if ( (@SpecificClient < 0) or (@soldto = @SpecificClient) or (@purchasedfrom = @SpecificClient) ) and
	   ( (@SpecificAsset = '') or (@asset = @SpecificAsset) )
	begin

select @SharesTo = 0
select @SharesFrom = 0
select @ConsiderTo = 0
select @ConsiderFrom = 0

		select @toadd = 0
		select @missing_cash = 0, @missing_scrip = 0
		select @datepaid = null, @datedelivered = null
		select @totalcontras = 0
		if @dealdate <= @AsAt
		begin
			if @sharesout > 0
			begin
				select @toadd = 1
				select @missing_scrip = 1
			end
			if @chqprinted = 0
			begin
				select @toadd = 1
				select @missing_cash = 1
			end
			if @missing_cash = 0	-- has been paid, but make sure it was paid on time (before @AsAt)
			begin
				select @datepaid = null
				if (@chqno is not null) and (@chqno > 0)
				begin
					select	@datepaid = cast((floor(convert(float,transdt))) as datetime)
						from transactions
						where transid = @chqno
				end
				else		-- the payment record is not in deals table, may be in table dealpaymentsmulti
				begin
					select top 1 @datepaid = t.transdt
						from transactions t
						where t.transid =
							(
							select top 1 dpm.transid
							from dealpaymentsmulti dpm
							where (dpm.transid = t.transid) and (dpm.dealno = @dealno)
							)
						order by t.transdt desc, t.transid desc
				end
				if (@datepaid is not null) and (@datepaid > @AsAt)
				begin
					select @toadd = 1
					select @missing_cash = 1
				end
			end
			if @missing_scrip = 0
			begin
				-- check SCRIPDEALSCERTS (matches using actual share certificates)
				select	@datedelivered = cast((floor(convert(float,sl.cdate))) as datetime)
					from scripdealscerts sdc, scripledger sl
					where (sdc.dealno = @dealno) and (sl.[id] = sdc.ledgerid)
				if @datedelivered is null -- check SCRIPDEALSCONTRA (matches deals on opposite sides)
				begin
					/*
					-- first check using column ORIGDEALNO
					--select	@datedelivered = cast((floor(convert(float,d.dealdate))) as datetime)
					select	@datedelivered = cast((floor(convert(float,sdc.dt))) as datetime)
						from scripdealscontra sdc, dealallocations d
						where (sdc.origdealno = @dealno) and (d.dealno = sdc.matchdealno)
					if @datedelivered is null -- check SCRIPDEALSCONTRA (matches deals on opposite sides)
					begin
						-- next, check using column MATCHDEALNO
						--select	@datedelivered = cast((floor(convert(float,d.dealdate))) as datetime)
						select	@datedelivered = cast((floor(convert(float,sdc.dt))) as datetime)
							from scripdealscontra sdc, dealallocations d
							where (sdc.matchdealno = @dealno) and (d.dealno = sdc.origdealno)
					end
					*/
					select @totalcontras = dbo.TotalContras(@dealno,'',@AsAt)
				end
				if @datedelivered is null
				begin
					-- check SCRIPDEALS (obsolete, matched using scrip deliveries)
					select	@datedelivered = cast((floor(convert(float,sl.cdate))) as datetime)
						from scripledger sl, scripdeals sd
						where (sd.dealno = @dealno) and (sl.refno = sd.refno)
				end
				if (@datedelivered is not null) and (@datedelivered > @AsAt)
				begin
					select @toadd = 1
					select @missing_scrip = 1
				end
			end
			else
				select @totalcontras = dbo.TotalContras(@dealno,'',@AsAt)
		end
		if @purchasedfrom = 0
			select @clientno = @soldto
		else
			select @clientno = @purchasedfrom
		if (@toadd = 1) and (@BrokersOnly = 1)
		begin
			if	(select count(*) from clients 
				where (clientno = @clientno) and (category = 'BROKER')) < 1
				select @toadd = 0
		end
		if @toadd = 1
		begin
			if @missing_scrip = 1	-- if shares were outstanding as at this date, display orig. qty coz sharesout may have since been reduced in later deliveries
				select @totalshares = @qty - @totalcontras
			else
				select @totalshares = @sharesout - @totalcontras
			if @missing_cash = 1
			begin
				if @purchasedfrom <> 0	-- SELL deal
					select @totalcash = @consideration - (@commission + @basiccharges + @contractstamps + @transferfees + @wtax)
				else			-- BUY deal
					select @totalcash = @consideration + @commission + @basiccharges + @contractstamps + @transferfees
			end
			else
				select @totalcash = 0


			if @PurchasedFrom = 0
			begin
				if @totalshares < 0
                                                  select @SharesTo = 0
				else
				select @SharesTo = @totalshares

				select @ConsiderTo = 0
				select @SharesFrom = 0
				select @ConsiderFrom = @TotalCash
			end
			else
			begin
				select @SharesTo = 0
				select @ConsiderTo =@TotalCash
				if @totalshares < 0
                      			 select @SharesFrom = 0
				else
				  select @SharesFrom = @totalshares
				select @ConsiderFrom = 0				
			end

			insert into recondeals
				select	@dealtype, @dealno, @dealdate, @clientno,
					@asset, @qty, @price,
					@ConsiderTo,					
					--case @purchasedfrom when 0 then 0 else @totalcash end,		-- considerationTO
					--case @soldto when 0 then @totalcash else 0 end,		-- considerationFROM
					@ConsiderFrom,
					@commission, @basiccharges, @contractstamps, @transferfees, @wtax, @dealer,
					--case @purchasedfrom when 0 then @totalshares else 0 end,	-- sharesoutTO
					@SharesTo,
					--case @soldto when 0 then @totalshares else 0  end		-- sharesoutFROM
					@SharesFrom,@QTY
					/*case @purchasedfrom when 0 then 0 else @totalcash end,		-- considerationTO
					case @soldto when 0 then @totalcash else 0 end,		-- considerationFROM
					@commission, @basiccharges, @contractstamps, @transferfees, @wtax, @dealer,
					case @purchasedfrom when 0 then @totalshares else 0 end,	-- sharesoutTO
					case @soldto when 0 then 0 else @totalshares end		-- sharesoutFROM*/
		end
	end
	fetch next from deals_cursor into @dealtype, @dealno, @dealdate, @purchasedfrom, @soldto, @sharesout,
		@consideration, @commission, @basiccharges, @contractstamps, @wtax,
		@transferfees, @dealer, @chqprinted, @chqno, @asset, @price, @qty
end
close deals_cursor
deallocate deals_cursor
return 0


GO
/****** Object:  StoredProcedure [dbo].[DealsReconciliationExScripBal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
DealsReconciliationExScripBal '2009-10-17', 0, -1, 'abchl-l', 0
*/
CREATE PROCEDURE [dbo].[DealsReconciliationExScripBal]	(
	@AsAt	datetime,
	@BrokersOnly bit = 1,
	@SpecificClient int = -1,
	@SpecificAsset varchar(50) = '',
	@Cons int = 0
						)
AS
declare @purchasedfrom int, @soldto int, @sharesout int, @chqprinted bit
declare @consideration money, @commission money, @basiccharges money, @wtax money
declare @transferfees money, @contractstamps money, @dealer varchar(50)
declare @asset varchar(50), @qty int, @price money, @dealtype varchar(20)
declare @dealno varchar(50), @dealdate datetime, @chqno int
declare @datepaid datetime, @datedelivered datetime, @toadd bit
declare @clientno int, @missing_cash bit, @missing_scrip bit
declare @totalshares int, @totalcash money
declare	@totalcontras int
--declare crDeals cursor FAST_FORWARD READ_ONLY for

declare crDeals cursor FORWARD_ONLY STATIC READ_ONLY for
	select	dealtype, dealno, dealdate, purchasedfrom, soldto, qty,
		consideration, commission, basiccharges, contractstamps, wtax,
		transferfees, dealer, chqprinted, chqno, asset, price, sharesout
	from dealallocations
	where	(approved = 1) and (cancelled = 0) and (merged = 0)
	and (asset = @SpecificAsset) 
	order by [id]
open crDeals
fetch next from crDeals into @dealtype, @dealno, @dealdate, @purchasedfrom, @soldto, @sharesout,
		@consideration, @commission, @basiccharges, @contractstamps, @wtax,
		@transferfees, @dealer, @chqprinted, @chqno, @asset, @price, @qty
delete from recondeals where asset = @Asset
while @@FETCH_STATUS = 0
begin
	if ( (@SpecificClient < 0) or (@soldto = @SpecificClient) or (@purchasedfrom = @SpecificClient) ) and
	   ( (@SpecificAsset = '') or (@asset = @SpecificAsset) )
	begin
		select @toadd = 0
		select @missing_cash = 0, @missing_scrip = 0
		select @datepaid = null, @datedelivered = null
		select @totalcontras = 0
		if @dealdate <= @AsAt
		begin
			if @sharesout > 0
			begin
				select @toadd = 1
				select @missing_scrip = 1
			end
			if @chqprinted = 0
			begin
				select @toadd = 1
				select @missing_cash = 1
			end
			if @missing_cash = 0	-- has been paid, but make sure it was paid on time (before @AsAt)
			begin
				select @datepaid = null
				if (@chqno is not null) and (@chqno > 0)
				begin
					select	@datepaid = cast((floor(convert(float,transdt))) as datetime)
						from transactions
						where transid = @chqno
				end
				else		-- the payment record is not in deals table, may be in table dealpaymentsmulti
				begin
					select top 1 @datepaid = t.transdt
						from transactions t
						where t.transid =
							(
							select top 1 dpm.transid
							from dealpaymentsmulti dpm
							where (dpm.transid = t.transid) and (dpm.dealno = @dealno)
							)
						order by t.transdt desc, t.transid desc
				end
				if (@datepaid is not null) and (@datepaid > @AsAt)
				begin
					select @toadd = 1
					select @missing_cash = 1
				end
			end
			if @missing_scrip = 0
			begin
				-- check SCRIPDEALSCERTS (matches using actual share certificates)
				select	@datedelivered = cast((floor(convert(float,sl.cdate))) as datetime)
					from scripdealscerts sdc, scripledger sl
					where (sdc.dealno = @dealno) and (sl.[id] = sdc.ledgerid)
				if @datedelivered is null -- check SCRIPDEALSCONTRA (matches deals on opposite sides)
				begin
					/*
					-- first check using column ORIGDEALNO
					--select	@datedelivered = cast((floor(convert(float,d.dealdate))) as datetime)
					select	@datedelivered = cast((floor(convert(float,sdc.dt))) as datetime)
						from scripdealscontra sdc, dealallocations d
						where (sdc.origdealno = @dealno) and (d.dealno = sdc.matchdealno)
					if @datedelivered is null -- check SCRIPDEALSCONTRA (matches deals on opposite sides)
					begin
						-- next, check using column MATCHDEALNO
						--select	@datedelivered = cast((floor(convert(float,d.dealdate))) as datetime)
						select	@datedelivered = cast((floor(convert(float,sdc.dt))) as datetime)
							from scripdealscontra sdc, dealallocations d
							where (sdc.matchdealno = @dealno) and (d.dealno = sdc.origdealno)
					end
					*/
					select @totalcontras = dbo.TotalContras(@dealno,'',@AsAt)
				end
				if @datedelivered is null
				begin
					-- check SCRIPDEALS (obsolete, matched using scrip deliveries)
					select	@datedelivered = cast((floor(convert(float,sl.cdate))) as datetime)
						from scripledger sl, scripdeals sd
						where (sd.dealno = @dealno) and (sl.refno = sd.refno)
				end
				if (@datedelivered is not null) and (@datedelivered > @AsAt)
				begin
					select @toadd = 1
					select @missing_scrip = 1
				end
			end
			else
				select @totalcontras = dbo.TotalContras(@dealno,'',@AsAt)
		end
		if @purchasedfrom = 0
			select @clientno = @soldto
		else
			select @clientno = @purchasedfrom
		if (@toadd = 1) and (@BrokersOnly = 1)
		begin
			if	(select count(*) from clients 
				where (clientno = @clientno) and (category = 'BROKER')) < 1
				select @toadd = 0
		end
		if @toadd = 1
		begin
			if @missing_scrip = 1	-- if shares were outstanding as at this date, display orig. qty coz sharesout may have since been reduced in later deliveries
				select @totalshares = @qty - @totalcontras
			else
				select @totalshares = @sharesout - @totalcontras
			if @missing_cash = 1
			begin
				if @purchasedfrom <> 0	-- SELL deal
					select @totalcash = @consideration - (@commission + @basiccharges + @contractstamps + @transferfees + @wtax)
				else			-- BUY deal
					select @totalcash = @consideration + @commission + @basiccharges + @contractstamps + @transferfees
			end
			else
				select @totalcash = 0

			insert into recondeals(dealtype,dealno,
				dealdate,
				clientno,
				asset,
				qty,
				price,
				considerationto,
				considerationfrom,
				commission,
				basiccharges,
				contractstamps,
				transferfees,
				wtax,
				dealer,
				sharesoutto,
				sharesoutfrom,
				origsharesout)
			select	@dealtype, 
				@dealno, 
				@dealdate, 
				@clientno,
				@asset, 
				@qty, 
				@price,
				case @purchasedfrom when 0 then 0 else @totalcash end,		-- considerationTO
				case @purchasedfrom when 0 then @totalcash else 0 end,		-- considerationFROM
				@commission, 
				@basiccharges,
				@contractstamps, 
				@transferfees, 
				@wtax, 
				@dealer,
				case @purchasedfrom when 0 then @totalshares else 0 end,	-- sharesoutTO
				case @purchasedfrom when 0 then 0 else @totalshares end,		-- sharesoutFROM
				@SharesOut

		end
	end
	fetch next from crDeals into @dealtype, @dealno, @dealdate, @purchasedfrom, @soldto, @sharesout,
		@consideration, @commission, @basiccharges, @contractstamps, @wtax,
		@transferfees, @dealer, @chqprinted, @chqno, @asset, @price, @qty
end
close crDeals
deallocate crDeals
return 0

GO
/****** Object:  StoredProcedure [dbo].[DealTransact]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		Copyright (c) 2003, 2005		}
{							}
{*******************************************************}
Return Values:
0	Success
-1	Failure
*/
 CREATE           PROCEDURE [dbo].[DealTransact]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@DealNo			varchar(40) = NULL,
	@TransCode		varchar(50)=NULL,
	@TransDate		datetime = NULL,
	@Description	varchar(50) = NULL,
	@Amount			decimal(38,4)=0,
	@Consideration  decimal(38,4)=0
) 
AS


declare @BF decimal(38,4), @CF decimal(38,4)--, @NewTransDate datetime
declare @IsCredit bit
declare @Amount1 decimal(38,4)
declare @Consideration1 decimal(38,4)
--declare @Amount2 decimal(38,4)
--declare @Factor numeric

select @Amount1 = @Amount
select @Consideration1 = @Consideration

/*select @Factor = Factor from AccountsParams
select @Amount2 = convert(decimal(38,2), @Amount)

if @Divided = 1
 select @Amount1 = @amount2*@Factor
else
 select @Amount1 = @amount2 */

select @BF = 0, @CF = 0

select top 1 @BF = ARREARSCF from Transactions 
where (ClientNo = @ClientNo)
order by TransDate desc, transid desc   --order by postdt desc
if @@ERROR <> 0 return -1
select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
if @@ERROR <> 0 return -1
if @IsCredit = 1
begin
	select @Amount1 = -@Amount1
	select @Consideration1=-@Consideration1
end	
select @CF = @BF + @Amount1
--if @TransDate is NULL
--	select @TransDate = GetDate()
--select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime)
----if @CashBookID = 0
--	select @CashBookID = null

--if @TransID <> 0 
-- begin
--  select @CashBookID = cashbookid from transactions
--  where transid = @TransID
-- end 

insert into Transactions
([LOGIN],ClientNo,PostDate,DEALNO,TRANSCODE,TransDate,[DESCRIPTION],AMOUNT,Consideration,ARREARSBF,ARREARSCF)
values
(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@TransDate,@Description,@Amount1,@Consideration1,@BF,@CF)
if @@ERROR <> 0
	return -1
else

	exec FixArrearsSingle @ClientNo
	/*if (@TransCode = 'REC') or (@TransCode = 'PAY')  -- ******* also remember to cater for RECCNL AND PAYCNL
	begin
		select @Amount1 = -@Amount1
		exec AdjustCashBal @NewTransDate, @CashBookID, @Amount1
	end
	else
		if (@TransCode = 'RECCNL') or (@TransCode = 'PAYCNL')
		begin
			select @Amount1 = -@Amount1
			exec AdjustCashBal @NewTransDate, @CashBookID, @Amount1
		end
	return 0
end*/

GO
/****** Object:  StoredProcedure [dbo].[DebtorsAging]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [dbo].[DebtorsAging] --[DebtorsAging]'20110513'
@AsAt datetime
as

set concat_null_yields_null off
exec BalancesOnly @AsAt
delete from tblclientbalances where balance <=0
exec agingclients @AsAt

	

GO
/****** Object:  StoredProcedure [dbo].[DebtorsAgingOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[DebtorsAgingOld]
@AsAt datetime
as
declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @ClientNo varchar(50)
delete from tblbalances 

set concat_null_yields_null off
--Simpson added
truncate table transactionsaging 
truncate table tblBalancesTemp
truncate table tblClientBalances

insert into transactionsaging (transid,ClientNo,transdate,amount)
--insert into tblBalances
select TRANSID,ClientNo,transdate,AmountOldFalcon as amount from transactions
where  TransDate <=@AsAt


insert into transactionsaging (transid,ClientNo,transdate,amount)
select  TRANSID,ClientNo,transdate,amount from CASHBOOKTRANS 

--insert into tblBalances
--select  x.clientno,
--(select sum(a.amount) from transactionsaging a where a.clientno = x.clientno) as balance -- and transcode not in ('rec','reccnl','pay','paycnl')
--from tblBalancesTemp x
--group by x.clientno
--order by x.clientno

--insert into tblBalances
--select  x.ClientNo,
--(select sum(a.amount) from transactionsaging a where a.ClientNo = x.ClientNo and a.TransDate <= @AsAt) as balance -- and transcode not in ('rec','reccnl','pay','paycnl')
--from transactions x
----where x.ClientNo not in(6526,6005,6004,5782,5770,1374,310,361,5771)
--group by x.ClientNo
--order by x.ClientNo

insert into tblBalances
select  ClientNo,sum(amount) from transactionsaging 
--where x.ClientNo not in(6526,6005,6004,5782,5770,1374,310,361,5771)
group by ClientNo
order by ClientNo


update tblBalances set balance = 0 where balance is null
delete from tblClientBalances

--if @Debtors = 1
--begin
declare crBalance cursor for
select ClientNo,balance from tblBalances
where balance > 0
/*end
else
begin
declare crBalance cursor for
select ClientNo,balance from tblBalances
where balance < 0
end
*/
open crBalance
fetch next from crBalance into @ClientNo, @bal
while @@fetch_status = 0
begin
select @bal7 =0, @bal14 =0, @bal21 = 0, @bal28 =0
--if (@bal > 0)
--begin
 select @bal7 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-7,@AsAt)
 and TransDate <= @AsAt  
 select @bal14 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-14,@AsAt)
 and TransDate <= dateadd(day,-7,@AsAt) 
 select @bal21 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-21,@AsAt)
 and TransDate <= dateadd(day,-14,@AsAt)  
 select @bal28 = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 and TransDate > dateadd(day,-28,@AsAt)
 and TransDate <= dateadd(day,-21,@AsAt)/**/   
 select @balover = isnull(sum(amount),0) from transactions where ClientNo = @ClientNo
 --and postdt > dateadd(day,-28,@AsAt)
 and TransDate <= dateadd(day,-28,@AsAt)
--end 
insert into tblClientBalances(ClientNo, client,balance, bal7, bal14, bal21, bal28, balover)
select @ClientNo, ltrim(companyname+' '+title+' '+firstname+' '+surname),
@bal, @bal7, @bal14, @bal21, @bal28, @balover
from clients
where clientno = @ClientNo
fetch next from crBalance into @ClientNo, @bal
end
close crBalance
deallocate crBalance


update tblClientBalances set category ='BROKERS' where ClientNo in(select ClientNo from CLIENTS where category='broker')
update tblClientBalances set category ='NON-BROKERS' where category is null
update tblClientBalances set ADate =@AsAt
--spDebtorsAging '2009-07-13', 0



GO
/****** Object:  StoredProcedure [dbo].[DebtorsAgingPD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create procedure [dbo].[DebtorsAgingPD] --[DebtorsAging]'20110513'
@AsAt datetime
as
--declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @ClientNo varchar(50), @accamount money, @category varchar(50), @Client varchar(150)
--delete from tblbalances 


set concat_null_yields_null off

--Simpson added
--truncate table transactionsaging 
--truncate table tblBalancesTemp
--truncate table tblClientBalances

exec BalancesOnlyPD @AsAt

update tblBalances set balance = 0 where balance is null

declare crBalance cursor for
select ClientNo from tblBalances
where balance > 0

open crBalance
--select @accamount = 0
fetch next from crBalance into @ClientNo
while @@fetch_status = 0
begin
	select @Client= ltrim(companyname+' '+title+' '+firstname+' '+surname)
	from clients where clientno = @ClientNo

	update tblClientBalances set client= @client where clientno = @ClientNo
	exec agingclientsPD @ClientNo

	fetch next from crBalance into @ClientNo
end
close crBalance
deallocate crBalance
 
update tblClientBalances set category='OTHER' where clientno in(select clientno from clients where category not in('broker'))
update tblClientBalances set category='BROKER' where clientno in(select clientno from clients where category  in('broker'))
--select * from tblClientBalances


GO
/****** Object:  StoredProcedure [dbo].[FixArrearsMulti]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[FixArrearsMulti]
AS
declare @cli int
declare clients_cursor cursor for
	select distinct cno from transactions
open clients_cursor
fetch next from clients_cursor into @cli
while @@FETCH_STATUS = 0
begin
	exec FixArrearsSingle @cli
	fetch next from clients_cursor into @cli
end
close clients_cursor
deallocate clients_cursor
return 0

GO
/****** Object:  StoredProcedure [dbo].[FixArrearsSingle]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE   PROCEDURE [dbo].[FixArrearsSingle]	(
	@ClientNo		varchar(50)
					)
AS
declare @amount money, @bal money, @newbal money, @id int
if not exists (select clientno from clients where clientno = @ClientNo)
	return -1
alter table transactions disable trigger all
declare trans_cursor cursor for
	select transid, amount
	from transactions
	where clientno = @ClientNo

	order by transdate, transid
select @bal = 0, @newbal = 0
open trans_cursor
fetch next from trans_cursor into @id, @amount
while @@FETCH_STATUS = 0
begin
	select @newbal = @bal + @amount
	update transactions set arrearsbf = @bal, arrearscf = @newbal where transid = @id
	select @bal = @newbal
	fetch next from trans_cursor into @id, @amount
end
close trans_cursor
deallocate trans_cursor
alter table transactions enable trigger all
return 0
GO
/****** Object:  StoredProcedure [dbo].[FixCashBal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE     PROCEDURE [dbo].[FixCashBal]
AS
declare @cbid int
declare cashbook_cursor cursor for
	select distinct cashbookid
	from cashbal
open cashbook_cursor
fetch next from cashbook_cursor into @cbid
while @@FETCH_STATUS = 0
begin
	exec FixCashBalSingle @cbid
	fetch next from cashbook_cursor into @cbid
end
close cashbook_cursor
deallocate cashbook_cursor
return 0

GO
/****** Object:  StoredProcedure [dbo].[FixCashBalSingle]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE     PROCEDURE [dbo].[FixCashBalSingle]	(
	@CashBookID int
						)
AS
declare @prevcf money, @bf money, @cf money, @dt datetime
declare @diff money
alter table cashbal disable trigger all
declare cash_cursor cursor for
	select dt, balbf, balcf
	from cashbal
	where cashbookid = @CashBookID
	order by dt
select @prevcf = 0, @bf = 0, @cf = 0
open cash_cursor
fetch next from cash_cursor into @dt,@bf,@cf
while @@FETCH_STATUS = 0
begin
	if @bf <> @prevcf
	begin
		select @diff = @prevcf - @bf
		select @bf = @bf + @diff, @cf = @cf + @diff
		update cashbal set BALBF = @bf, BALCF = @cf where (DT = @dt) and (CASHBOOKID = @CashBookID)
	end
	select @prevcf = @cf
	fetch next from cash_cursor into @dt,@bf,@cf
end
close cash_cursor
deallocate cash_cursor
alter table cashbal enable trigger all
return 0

GO
/****** Object:  StoredProcedure [dbo].[GenerateAudittrail]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[GenerateAudittrail] -- generateaudittrail dealallocations
	@TableName varchar(128),
	@Owner varchar(128) = 'dbo',
	@AuditNameExtention varchar(128) = 'Z',
	@DropAuditTable bit = 0
AS
BEGIN

	-- Check if table exists
	IF not exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[' + @Owner + '].[' + @TableName + ']') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	BEGIN
		PRINT 'ERROR: Table does not exist'
		RETURN
	END

	-- Check @AuditNameExtention
	IF @AuditNameExtention is null
	BEGIN
		PRINT 'ERROR: @AuditNameExtention cannot be null'
		RETURN
	END

	-- Drop audit table if it exists and drop should be forced
	IF (exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[' + @Owner + '].[' + @AuditNameExtention + @TableName  + ']') and OBJECTPROPERTY(id, N'IsUserTable') = 1) and @DropAuditTable = 1)
	BEGIN
		PRINT 'Dropping audit table [' + @Owner + '].[' + @AuditNameExtention + @TableName  + ']'
		EXEC ('drop table ' + @AuditNameExtention + @TableName )
	END

	-- Declare cursor to loop over columns
	DECLARE TableColumns CURSOR Read_Only
	FOR SELECT b.name, c.name as TypeName, b.length, b.isnullable, b.collation, b.xprec, b.xscale
		FROM sysobjects a 
		inner join syscolumns b on a.id = b.id 
		inner join systypes c on b.xtype = c.xtype and c.name <> 'sysname' 
		WHERE a.id = object_id(N'[' + @Owner + '].[' + @TableName + ']') 
		and OBJECTPROPERTY(a.id, N'IsUserTable') = 1 
		ORDER BY b.colId

	OPEN TableColumns

	-- Declare temp variable to fetch records into
	DECLARE @ColumnName varchar(128)
	DECLARE @ColumnType varchar(128)
	DECLARE @ColumnLength smallint
	DECLARE @ColumnNullable int
	DECLARE @ColumnCollation sysname
	DECLARE @ColumnPrecision tinyint
	DECLARE @ColumnScale tinyint

	-- Declare variable to build statements
	DECLARE @CreateStatement varchar(8000)
	DECLARE @ListOfFields varchar(2000)
	SET @ListOfFields = ''


	-- Check if audit table exists
	IF exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[' + @Owner + '].[' + @AuditNameExtention + @TableName  + ']') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	BEGIN
		-- AuditTable exists, update needed
		PRINT 'Table already exists. Only triggers will be updated.'

		FETCH Next FROM TableColumns
		INTO @ColumnName, @ColumnType, @ColumnLength, @ColumnNullable, @ColumnCollation, @ColumnPrecision, @ColumnScale
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (@ColumnType <> 'text' and @ColumnType <> 'ntext' and @ColumnType <> 'image' and @ColumnType <> 'timestamp')
			BEGIN
				SET @ListOfFields = @ListOfFields + @ColumnName + ','
			END

			FETCH Next FROM TableColumns
			INTO @ColumnName, @ColumnType, @ColumnLength, @ColumnNullable, @ColumnCollation, @ColumnPrecision, @ColumnScale

		END
	END
	ELSE
	BEGIN
		-- AuditTable does not exist, create new

		-- Start of create table
		SET @CreateStatement = 'CREATE TABLE [' + @Owner + '].[' + @AuditNameExtention + @TableName  + '] ('
		SET @CreateStatement = @CreateStatement + '[AuditId] [bigint] IDENTITY (1, 1) NOT NULL,'

		FETCH Next FROM TableColumns
		INTO @ColumnName, @ColumnType, @ColumnLength, @ColumnNullable, @ColumnCollation, @ColumnPrecision, @ColumnScale
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (@ColumnType <> 'text' and @ColumnType <> 'ntext' and @ColumnType <> 'image' and @ColumnType <> 'timestamp')
			BEGIN
				SET @ListOfFields = @ListOfFields + @ColumnName + ','
		
				SET @CreateStatement = @CreateStatement + '[' + @ColumnName + '] [' + @ColumnType + '] '
				
				IF @ColumnType in ('binary', 'char', 'nchar', 'nvarchar', 'varbinary', 'varchar')
				BEGIN
					IF (@ColumnLength = -1)
						Set @CreateStatement = @CreateStatement + '(max) '	 	
					ELSE
						SET @CreateStatement = @CreateStatement + '(' + cast(@ColumnLength as varchar(10)) + ') '	 	
				END
		
				IF @ColumnType in ('decimal', 'numeric')
					SET @CreateStatement = @CreateStatement + '(' + cast(@ColumnPrecision as varchar(10)) + ',' + cast(@ColumnScale as varchar(10)) + ') '	 	
		
				IF @ColumnType in ('char', 'nchar', 'nvarchar', 'varchar', 'text', 'ntext')
					SET @CreateStatement = @CreateStatement + 'COLLATE ' + @ColumnCollation + ' '
		
				IF @ColumnNullable = 0
					SET @CreateStatement = @CreateStatement + 'NOT '	 	
		
				SET @CreateStatement = @CreateStatement + 'NULL, '	 	
			END

			FETCH Next FROM TableColumns
			INTO @ColumnName, @ColumnType, @ColumnLength, @ColumnNullable, @ColumnCollation, @ColumnPrecision, @ColumnScale
		END
		
		-- Add audit trail columns
		SET @CreateStatement = @CreateStatement + '[AuditAction] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,'
		SET @CreateStatement = @CreateStatement + '[AuditDate] [datetime] NOT NULL ,'
		SET @CreateStatement = @CreateStatement + '[AuditUser] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,'
		SET @CreateStatement = @CreateStatement + '[AuditApp] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)' 

		-- Create audit table
		PRINT 'Creating audit table [' + @Owner + '].[' + @AuditNameExtention + @TableName  + ']'
		EXEC (@CreateStatement)

		-- Set primary key and default values
		SET @CreateStatement = 'ALTER TABLE [' + @Owner + '].[' + @AuditNameExtention + @TableName  + '] ADD '
		SET @CreateStatement = @CreateStatement + 'CONSTRAINT [DF_' + @AuditNameExtention + @TableName  + '_AuditDate] DEFAULT (getdate()) FOR [AuditDate],'
		SET @CreateStatement = @CreateStatement + 'CONSTRAINT [DF_' + @AuditNameExtention + @TableName  + '_AuditUser] DEFAULT (suser_sname()) FOR [AuditUser],CONSTRAINT [PK_' + @AuditNameExtention + @TableName  + '] PRIMARY KEY  CLUSTERED '
		SET @CreateStatement = @CreateStatement + '([AuditId])  ON [PRIMARY], '
		SET @CreateStatement = @CreateStatement + 'CONSTRAINT [DF_' + @AuditNameExtention + @TableName  + '_AuditApp]  DEFAULT (''App=('' + rtrim(isnull(app_name(),'''')) + '') '') for [AuditApp]'

		EXEC (@CreateStatement)

	END

	CLOSE TableColumns
	DEALLOCATE TableColumns

	/* Drop Triggers, if they exist */
	PRINT 'Dropping triggers'
	IF exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[' + @Owner + '].[tr_' + @TableName + '_Insert]') and OBJECTPROPERTY(id, N'IsTrigger') = 1) 
		EXEC ('drop trigger [' + @Owner + '].[tr_' + @TableName + '_Insert]')

	IF exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[' + @Owner + '].[tr_' + @TableName + '_Update]') and OBJECTPROPERTY(id, N'IsTrigger') = 1) 
		EXEC ('drop trigger [' + @Owner + '].[tr_' + @TableName + '_Update]')

	IF exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[' + @Owner + '].[tr_' + @TableName + '_Delete]') and OBJECTPROPERTY(id, N'IsTrigger') = 1) 
		EXEC ('drop trigger [' + @Owner + '].[tr_' + @TableName + '_Delete]')

	/* Create triggers */
	PRINT 'Creating triggers' 
	EXEC ('CREATE TRIGGER tr_' + @TableName + '_Insert ON ' + @Owner + '.' + @TableName + ' FOR INSERT AS INSERT INTO ' + @AuditNameExtention + @TableName  + '(' +  @ListOfFields + 'AuditAction) SELECT ' + @ListOfFields + '''I'' FROM Inserted')

	EXEC ('CREATE TRIGGER tr_' + @TableName + '_Update ON ' + @Owner + '.' + @TableName + ' FOR UPDATE AS INSERT INTO ' + @AuditNameExtention + @TableName  + '(' +  @ListOfFields + 'AuditAction) SELECT ' + @ListOfFields + '''U'' FROM Inserted')

	EXEC ('CREATE TRIGGER tr_' + @TableName + '_Delete ON ' + @Owner + '.' + @TableName + ' FOR DELETE AS INSERT INTO ' + @AuditNameExtention + @TableName  + '(' +  @ListOfFields + 'AuditAction) SELECT ' + @ListOfFields + '''D'' FROM Deleted')

END


GO
/****** Object:  StoredProcedure [dbo].[GetAssetDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetAssetDetails] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT     dbo.Assets.*, dbo.Clients.CompanyName
FROM         dbo.Assets INNER JOIN
                      dbo.Clients ON dbo.Assets.TransSecID = dbo.Clients.ClientNo
END

GO
/****** Object:  StoredProcedure [dbo].[GetBrokerDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: Dec 2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBrokerDetails]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     TOP (100) PERCENT CID, ShortCode, Title, Surname, Firstname, CompanyName, Type, Category, Status, StatusReason, IDType, IDNo, 
						  PhysicalAddress, PostalAddress, UsePhysicalAddress, ContactNo, MobileNo, Fax, Email, DateAdded, Bank, BankBranch, BankAccountNo, 
						  BankAccountType, BuySettle, SellSettle, DeliveryOption, LoginID, Sex, UtilityNo, Directors, ReferredBy, Photo, ContactPerson, Employer, JobTitle, 
						  BusPhone, ClientNo
	FROM         dbo.Clients
	WHERE     (Category = 'BROKER')
	ORDER BY CAST(ClientNo AS int)
END


GO
/****** Object:  StoredProcedure [dbo].[GetCashBal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003, 2006		}
{							}
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[GetCashBal]	(
	@CashBookID	int,
	@Balance	money output
				)
AS
select @Balance = 0
select top 1 @Balance = BALCF from CASHBAL where (CASHBOOKID = @CashBookID) order by DT desc
/*declare @dt datetime, @bal money
select @dt = 0
select @dt = DT, @bal = BALCF from CASHBAL where DT = cast((floor(convert(float,getdate()))) as datetime)
if @dt > 0
begin
	select @Balance = @bal
	return 0
end
else
begin
	--yesterday
	select @dt = DT, @bal = BALCF from CASHBAL where DT = cast((floor(convert(float,getdate()-1))) as datetime)
	if @dt > 0
		select @Balance = @bal
	else
		select @Balance = 0
	return 0
end
*/

GO
/****** Object:  StoredProcedure [dbo].[GetClientDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetClientDeals] --getclientdeals '2785PLT','Cancelled'
	@ClientNo as varchar(50)
	,@Status as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	if (@Status='Cancelled')
		select @Status=1
	else if (@Status='Active')
		select @Status=0	
	SELECT     dbo.Dealallocations.*, dbo.Clients.Email
	FROM       dbo.Clients INNER JOIN
               dbo.Dealallocations ON dbo.Clients.ClientNo = dbo.Dealallocations.ClientNo 
	where dbo.Dealallocations.Cancelled =@Status 
	and dbo.Dealallocations.ClientNo  =@ClientNo 
	and merged=0
	--and CANCELLED=0
	order by DealDate desc,asset asc--and Approved=0 and Merged=0 and Cancelled=0 order by DealDate asc,asset asc
END

GO
/****** Object:  StoredProcedure [dbo].[GetClientDeliveryInfo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[GetClientDeliveryInfo]	(
	@ClientNo		int,
	@ExtractingCustody	bit = 0,
	@Name			varchar(50)	output,
	@Address		varchar(50)	output,
	@DeliveryOption		varchar(30)	output
						)
AS
SET CONCAT_NULL_YIELDS_NULL OFF
select @Name = '', @Address = ''
select @DeliveryOption = DELIVERYOPTION
from CLIENTS
where CLIENTNO = @ClientNo
if (charindex('direct',lower(@DeliveryOption)) > 0) or (@ExtractingCustody = 1)
begin
	select @Name = DNAME, @Address = DADDRESS from CLIENTS where CLIENTNO = @ClientNo
	if @Name = ''
		exec GetClientName @ClientNo, @Name output		
	if @Address = ''
		select	@Address =
				CASE USEPHYSADD
					WHEN 1 THEN PHYSADD
					ELSE POSTADD
				END
		from CLIENTS
		where CLIENTNO = @ClientNo
end
else
	if charindex('custodian',lower(@DeliveryOption)) > 0
	begin
		select TOP 1	@Name = LTrim(RTrim(TITLE + ' ' + FIRSTNAME + ' ' + SURNAME)),
				@Address = 
					CASE USEPHYSADD
						WHEN 1 THEN PHYSADD
						ELSE POSTADD
					END
		from CLIENTCONTACTS
		where (CLIENTNO = @ClientNo) and (RELATIONSHIP like 'custodian')
	end
return 0

GO
/****** Object:  StoredProcedure [dbo].[GetClientName]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[GetClientName]	(
	@ClientNo	int,
	@ClientName	varchar(1024)	output
					)
AS
SET CONCAT_NULL_YIELDS_NULL OFF
if @ClientNo = 0
	select @ClientName = 'Share Jobbing'
else
begin
	select @ClientName = ''
	select @ClientName = RTrim(LTrim(TITLE + ' ' + FIRSTNAME + ' ' + SURNAME + ' ' + COMPANYNAME))
	from CLIENTS
	where CLIENTNO = @ClientNo
end
return 0

GO
/****** Object:  StoredProcedure [dbo].[GetClientNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetClientNo] 
AS
BEGIN
	SET NOCOUNT ON;
	declare @CNo as varchar(50)
	declare @BrokerInitials as varchar(50)
	select @cno=max(cid)+1 from clients where Category<>'Broker'
	if @cno is null
		select @cno=1
	
	select @BrokerInitials=companyinitials from COMPANY	
		
	select @cno=@cno + @BrokerInitials 
	select @CNo as ClientNo
    
END

GO
/****** Object:  StoredProcedure [dbo].[GetClientOrders]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetClientOrders] --getclientorders'abc-232'
	@ClientNo as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	select * from Orders where ClientNo =@ClientNo order by OrderDate asc
	END

GO
/****** Object:  StoredProcedure [dbo].[GetClientRates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[GetClientRates]	(
	@ClientNo		varchar(50)
				)
AS
select * 
from ClientCategory cat, Clients 
where (cat.ClientCategory = Clients.Category)
	and (Clients.ClientNo = @ClientNo)

GO
/****** Object:  StoredProcedure [dbo].[GetClientRegInfo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[GetClientRegInfo]	(
	@ClientNo	int,
	@NomineeBrokers	bit = 1,
	@ExtractingCustody bit = 0,
	@RegName	varchar(1024)	output,
	@DeliveryOption	varchar(30)	output	
					)
AS
SET CONCAT_NULL_YIELDS_NULL OFF
declare @cat varchar(20), @nomnum int, @nomname varchar(1024)
select @RegName = ''
select @DeliveryOption = DELIVERYOPTION, @cat = CATEGORY
from CLIENTS
where CLIENTNO = @ClientNo
if	(
	(charindex('nominee',lower(@DeliveryOption)) > 0) or
	((@NomineeBrokers = 1) and (charindex('broker',lower(@cat)) > 0))
	) and
	(@ExtractingCustody = 0)
begin
	exec GetNomineeCo @nomnum output, @nomname output
	if @nomnum > 0
		select @RegName = @nomname
end
else
	select @RegName = RNAME from CLIENTS where CLIENTNO = @ClientNo
if @RegName = ''
	select	@RegName = RTrim(LTrim(TITLE + ' ' + FIRSTNAME + ' ' + SURNAME + ' ' + COMPANYNAME))		
	from CLIENTS
	where CLIENTNO = @ClientNo
return 0

GO
/****** Object:  StoredProcedure [dbo].[GetClientTransactions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetClientTransactions]  --getclienttransactions '10318REN'
	@ClientNo as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	select * from CASHBOOKTRANS where ClientNo =@ClientNo   order by transdate asc
	END

GO
/****** Object:  StoredProcedure [dbo].[GetClientUnPaidDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetClientUnPaidDeals]
	-- Add the parameters for the stored procedure here
	@ClientNo as varchar(50),
	@DealDate as datetime,
	@User as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	delete from payclientdeals where [USER]=@User
	insert into payclientdeals(DealNo,DealType,DealDate,Asset,Qty,DealValue,Selected,[User])
	select DealNo,DealType,DealDate,ASSET,Qty,DealValue,0,@User from Dealallocations where DealType='sell'
	and ChqRqID is null 
	and APPROVED=1
	and MERGED=0
	and Cancelled=0
	and ClientNo=@ClientNo
	and DealDate<=@DealDate
	order by dealdate desc
END


GO
/****** Object:  StoredProcedure [dbo].[GetClientUnreceiptedDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: Dec. 2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetClientUnreceiptedDeals]
	-- Add the parameters for the stored procedure here
	@ClientNo as varchar(50),
	@DealDate as datetime,
	@User varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	delete from payclientdeals where [USER]=@User
	insert into payclientdeals(DealNo,DealType,DealDate,Asset,Qty,DealValue,Selected,[User])
	select DealNo,DealType,DealDate,ASSET,Qty,DealValue,0,@User from Dealallocations where DealType='buy'
	and ChqRqID is null 
	and APPROVED=1
	and MERGED=0
	and Cancelled=0
	and ClientNo=@ClientNo
	and DealDate<=@DealDate
	union
	select d.DealNo,d.DealType,d.DealDate,d.ASSET,d.Qty,d.DealValue,0, @User
	from Dealallocations d inner join requisitions r on d.chqrqid = r.reqid
	where d.DealType='buy'
	and d.APPROVED=1
	and d.MERGED=0
	and d.Cancelled=0
	and d.ClientNo=@ClientNo
	and d.DealDate<=@DealDate
	and r.APPROVED = 0
	and r.cancelled = 0
	order by dealno
END

GO
/****** Object:  StoredProcedure [dbo].[GetCorpActionDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetCorpActionDetails]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * from corporateaction
END

GO
/****** Object:  StoredProcedure [dbo].[GetDealNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetDealNo]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	declare @DealNo as varchar(50)
	
	select @DealNo=max(id)+1 from Dealallocations
	if @DealNo is null
		select @DealNo=1
	
	
	select @DealNo as DealNo
END

GO
/****** Object:  StoredProcedure [dbo].[GetNextLedgerRef]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE     PROCEDURE [dbo].[GetNextLedgerRef]	(
--	@Prefix		varchar(2) = 'RN',
	@NextRef	varchar(30) output
				)
AS
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
SET CONCAT_NULL_YIELDS_NULL OFF
declare @Last varchar(30), @LastNum int, @Prefix varchar(2)
select @Last = '', @LastNum = 0, @Prefix = 'RN'
select top 1 @Last = REFLEDGER from SCRIPREFS
if (@Last <> '') and (@Last is not null)
begin
	select @Last = Right(@Last,Len(@Last)-Len(@Prefix))
	select @LastNum = convert(numeric,@Last) + 1
	select @NextRef = convert(varchar(19),@LastNum)	
end
else
	select @NextRef = convert(varchar(19),1)
while Len(@NextRef) < 7
	select @NextRef = '0' + @NextRef
select @NextRef = @Prefix + @NextRef
if @Last <> ''
	update SCRIPREFS set REFLEDGER = @NextRef
else
	insert into SCRIPREFS (REFLEDGER,REFTRANSFER) values (@NextRef,NULL)
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
return 0


GO
/****** Object:  StoredProcedure [dbo].[GetNextTransferRef]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE    PROCEDURE [dbo].[GetNextTransferRef]	(
--	@Prefix		varchar(2) = 'RN',
	@NextRef	varchar(30) output
				)
AS
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
SET CONCAT_NULL_YIELDS_NULL OFF
declare @Last varchar(30), @LastNum int, @Prefix varchar(2)
select @Last = '', @LastNum = 0, @Prefix = 'TS'
select top 1 @Last = REFTRANSFER from SCRIPREFS
if (@Last <> '') and (@Last is not null)
begin
	select @Last = Right(@Last,Len(@Last)-Len(@Prefix))
	select @LastNum = convert(numeric,@Last) + 1
	select @NextRef = convert(varchar(19),@LastNum)	
end
else
	select @NextRef = convert(varchar(19),1)
while Len(@NextRef) < 7
	select @NextRef = '0' + @NextRef
select @NextRef = @Prefix + @NextRef
if @Last <> ''
	update SCRIPREFS set REFTRANSFER = @NextRef
else
	insert into SCRIPREFS (REFLEDGER,REFTRANSFER) values (NULL,@NextRef)
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
return 0

GO
/****** Object:  StoredProcedure [dbo].[GetNomineeCo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[GetNomineeCo]	(
	@Number	int		output,
	@Name	varchar(1024)	output
				)
AS
select @Number = -1, @Name = ''
select TOP 1 @Number = CLIENTNO from CLIENTS where NOMINEECO = 1
if @Number <> -1
	exec GetClientName @Number, @Name output

GO
/****** Object:  StoredProcedure [dbo].[GetOrderDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetOrderDetails]--GetOrderDetails 'MANUAL PENDING'
@OrderStatus as varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT    dbo.Orders.OrderNo, dbo.Orders.OrderDate, dbo.Orders.DateAdded, dbo.Orders.Asset, dbo.Orders.Qty, dbo.Orders.QtyOs, 
			  dbo.Orders.OrderValue, dbo.Orders.PLimit,dbo.Orders.Limit, dbo.Orders.Instruction, dbo.Orders.Reference, dbo.Orders.ScripAt, dbo.Orders.Status, dbo.Orders.Media, 
			  dbo.Orders.OrderType, dbo.Orders.Login, dbo.Orders.ClientNo, dbo.Orders.ExpiryDate, dbo.Orders.CancelledID, dbo.Orders.CancelledDate, 
			  dbo.Clients.Category, dbo.Clients.MobileNo,COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName, 'N/A') AS Clientname, 
			  dbo.Clients.IDNo
	FROM      dbo.Clients INNER JOIN
				  dbo.Orders ON dbo.Clients.ClientNo = dbo.Orders.ClientNo
				  where dbo.Orders.status=@OrderStatus
END

GO
/****** Object:  StoredProcedure [dbo].[GetServerInfo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[GetServerInfo]	(
	@ServerIP	varchar(20)	output,
	@ServerLicense	varchar(100)	output,
	@ServerModules1	varchar(8000)	output,
	@ServerModules2	varchar(8000)	output
)
AS
declare @hr int, @gw int, @license varchar(100)
declare @modlist1 varchar(8000), @modlist2 varchar(8000)
declare @src varchar(20), @ip varchar(20)
select @license = '', @modlist1 = '', @modlist2 = '', @src = '', @ip = ''
-- Create client gateway object
EXEC @hr = sp_OACreate 'FalconServer.ClientGateway', @gw OUT
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
-- get license
EXEC @hr = sp_OAMethod @gw, 'GetLicense', @license OUT, @src
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
-- get IP addresss
EXEC @hr = sp_OAMethod @gw, 'GetIP', @ip OUT
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
-- list modules
EXEC @hr = sp_OAMethod @gw, 'ListModules'
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
-- get list of modules (first list)
EXEC @hr = sp_OAGetProperty @gw, 'ModuleListing', @modlist1 OUT
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
-- get list of modules (second list)
EXEC @hr = sp_OAGetProperty @gw, 'ModuleListing2', @modlist2 OUT
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
EXEC @hr = sp_OADestroy @gw
select @ServerIP = @ip, @ServerLicense = @license, @ServerModules1 = @modlist1, @ServerModules2 = @modlist2
return 0

GO
/****** Object:  StoredProcedure [dbo].[GetTransferSec]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[GetTransferSec]	(--GetTransferSec 'colco-l'
	@Asset			varchar(50)--,
	--@TransferSecNo		int output,
	--@TransferSecName	varchar(50) output
				)
AS
SET CONCAT_NULL_YIELDS_NULL OFF
--select @TransferSecNo = c.clientno, @TransferSecName = c.CompanyName
--from clients c, assets a
--where (a.AssetCode = @Asset) and (a.TransSecID = c.clientno)

select c.clientno as clientno , c.CompanyName as TransferSecName 
from clients c inner join assets a on c.clientno = a.transsecid
where a.assetcode = @Asset





GO
/****** Object:  StoredProcedure [dbo].[GetTSecDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: Dec 2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetTSecDetails]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     TOP (100) PERCENT CID, ShortCode, Title, Surname, Firstname, CompanyName, Type, Category, Status, StatusReason, IDType, IDNo, 
						  PhysicalAddress, PostalAddress, UsePhysicalAddress, ContactNo, MobileNo, Fax, Email, DateAdded, Bank, BankBranch, BankAccountNo, 
						  BankAccountType, BuySettle, SellSettle, DeliveryOption, LoginID, Sex, UtilityNo, Directors, ReferredBy, Photo, ContactPerson, Employer, JobTitle, 
						  BusPhone, ClientNo
	FROM         dbo.Clients
	WHERE     (Category = 'TRANSFER SECRETARY')
	ORDER BY CAST(ClientNo AS int)
END


GO
/****** Object:  StoredProcedure [dbo].[GetUpdate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[GetUpdate]	(
	@Path		varchar(512)
				)
AS
declare @cli varchar(316)
declare @hr int, @gw int, @modpath varchar(512), @count int, @data varchar(4000)
declare @i int, @bool bit, @partsize int
select @cli = host_name(), @partsize = 4000
delete from serverupdatetemp where host = @cli
-- Create client gateway object
EXEC @hr = sp_OACreate 'FalconServer.ClientGateway', @gw OUT
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1 --failed to client gateway object
END
-- list modules
EXEC @hr = sp_OAMethod @gw, 'GetFile', @bool OUT, @Path, @partsize
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
IF @bool <> 1
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
-- get number of modules
EXEC @hr = sp_OAGetProperty @gw, 'FilePartCount', @count OUT
IF @hr <> 0
BEGIN
	EXEC @hr = sp_OADestroy @gw
	RETURN -1
END
select @i = 0
while @i < @count
begin
	EXEC @hr = sp_OAMethod @gw, 'FilePart', @data OUT, @i
	IF @hr <> 0
	BEGIN
		EXEC @hr = sp_OADestroy @gw
		RETURN @count
	END
	select @i = @i + 1
	insert into serverupdatetemp (host,path,partnum,data) values (@cli,@Path,@i,@data)
end
EXEC @hr = sp_OADestroy @gw
select * from serverupdatetemp where host = @cli order by partnum
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc1]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc1]
AS
IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_NAME = 'cat_view')
   DROP VIEW cat_view
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc2]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc2]
AS
declare @sql nvarchar(1000)
select @sql = '
CREATE VIEW cat_view
AS 
select	a.assetcode, a.linkto, a.shares,
	''cat'' = CASE
			WHEN a.linkto IS NULL THEN a.category
			ELSE (select ast.category from assets ast where ast.assetcode = a.linkto)
		END
from assets a
where a.status in (''ACTIVE'',''SUSPENDED'') and (a.shares > 0)
'
exec sp_executesql @sql
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc3]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc3]
AS
IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_NAME = 'catshares_view')
   DROP VIEW catshares_view
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc4]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc4]
AS
declare @sql nvarchar(1000)
select @sql = '
CREATE VIEW catshares_view
AS 
select cat, sum(shares) as ''allshares'' from cat_view group by cat
'
exec sp_executesql @sql
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc5]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc5]
AS
IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_NAME = 'weights_view')
   DROP VIEW weights_view
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc6]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc6](@MaxDate datetime, @MaxSession varchar(10))
AS
declare @sql nvarchar(1000)
select @sql = '
CREATE VIEW weights_view
AS 
select	c.assetcode, c.cat, c.shares,
	''weight'' = (c.shares / (select cs.allshares from catshares_view cs where cs.cat = c.cat))*100,
	''price'' = (select top 1 history from prices p where (p.assetcode = c.assetcode) and (((p.[date] = ''' + convert(varchar(20),@MaxDate,111) + ''') and (p.[session] <= ''' + @MaxSession + ''')) or (p.[date] < ''' + convert(varchar(20),@MaxDate,111) + ''')) order by p.[date] desc, p.[id] desc)
from cat_view c
'
exec sp_executesql @sql
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc7]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc7]
AS
IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_NAME = 'totals_view')
   DROP VIEW totals_view
return 0

GO
/****** Object:  StoredProcedure [dbo].[IndexProc8]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[IndexProc8]
AS
declare @sql nvarchar(1000)
select @sql = '
CREATE VIEW totals_view
AS 
select cat, sum(weight*price*100) as total from weights_view group by cat
'
exec sp_executesql @sql
return 0

GO
/****** Object:  StoredProcedure [dbo].[ListMultiDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE      PROCEDURE [dbo].[ListMultiDeals]
-- ( @DealDate	datetime )
AS
/*
declare @ddate datetime, @dt datetime
select @dt = max(dealdate) from dealallocations where (approved = 0) and (cancelled = 0)
if (@dt < @DealDate)
	select @ddate = @dt
else
	select @ddate = @DealDate
*/
select theclient =	case
				when dealtype = 'BUY' then soldto
				when dealtype = 'SELL' then purchasedfrom
			end,
soldto, purchasedfrom, dealtype, asset, dealdate, orderno, price,
count(*) as cnt
from dealallocations
--where (dealdate = @ddate) and (approved = 0) and (cancelled=0)
where (approved = 0) and (cancelled=0)
group by soldto, purchasedfrom, dealtype, asset, dealdate, orderno,price
having count(*) > 1
order by dealdate,asset


GO
/****** Object:  StoredProcedure [dbo].[ListShareJobbing]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE                 PROCEDURE [dbo].[ListShareJobbing]	(
	@AsAt		datetime,
	@User		varchar(50),
	@Detailed	bit		= 0
						)
AS
declare @date as datetime, @asset varchar(50), @netqty int, @netcons money, @price money, @cost money
declare sj_detailed_cursor cursor FAST_FORWARD READ_ONLY for
	select dealdate, asset, sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end) as 'NETQTY',sum(case d.dealtype when 'BUY' then -d.consideration when 'SELL' then d.consideration end) as 'NETCONS'
	from dealallocations d
	where (dealdate <= @AsAt) and (approved=1) and (merged=0) and (cancelled=0) and (consolidated = 0)
	and	(
		(comments ='') or
		(comments is null) or
		(comments like '%ADJUSTMENT%')
		)
	group by dealdate, asset
	having (sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end)) <> 0
	order by dealdate
declare sj_basic_cursor cursor FAST_FORWARD READ_ONLY for
	select  sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end) as 'NETQTY',sum(case d.dealtype when 'BUY' then -d.consideration when 'SELL' then d.consideration end) as 'NETCONS',asset
	from dealallocations d
	where (dealdate <= @AsAt) and (approved=1) and (merged=0) and (cancelled=0) and (consolidated = 0)
	and	(
		(comments ='') or
		(comments is null) or
		(comments like '%ADJUSTMENT%')
		)
	group by asset
delete from sharejob where [user] = @User
if @Detailed = 1
begin
	open sj_detailed_cursor
	fetch next from sj_detailed_cursor into @date, @asset, @netqty, @netcons
	while @@FETCH_STATUS = 0
	begin
		insert into sharejob ([user],asset,[date],netqty,netcons,mktprice,cost) values (@User,@asset,@date,@netqty,@netcons,0,0)
		fetch next from sj_detailed_cursor into @date, @asset, @netqty, @netcons
	end
	close sj_detailed_cursor
end
else
begin
	open sj_basic_cursor
	fetch next from sj_basic_cursor into @netqty, @netcons, @asset
	while @@FETCH_STATUS = 0
	begin
		if @netqty <> 0
		begin
			select @price = 0
			select top 1 @price = history from prices where (assetcode = @asset) and  ([PricesDate] <= @AsAt) order by [PricesDate] desc--, [session] desc
			
			--if @price > 0
			if (@price = 0) or (@price is null) --use price in dealallocations
			begin
			select top 1 @price = price from dealallocations where (asset = @asset) and  ([dealdate] <= @AsAt) order by [dealdate] desc
			end
			if (@price = 0) or (@price is null)
			begin
			select @price = 0
			end
			begin
				select @cost = round(@netcons/@netqty,4)
				insert into sharejob ([user],asset,[date],netqty,netcons,mktprice,cost) values (@User,@asset,@AsAt,@netqty,@netcons,@price,@cost)
			end
		end
		fetch next from sj_basic_cursor into @netqty, @netcons, @asset
	end
	close sj_basic_cursor
end
deallocate sj_detailed_cursor
deallocate sj_basic_cursor
return 0




GO
/****** Object:  StoredProcedure [dbo].[ListShareJobbingEx]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE            PROCEDURE [dbo].[ListShareJobbingEx]	(
	@AsAt		datetime,
	@User		varchar(50),
	@Detailed	bit		= 0
						)
AS
declare @date as datetime, @asset varchar(50), @netqty int, @netcons money, @price money, @cost money
declare sj_detailed_cursor cursor FAST_FORWARD READ_ONLY for
	select dealdate, asset, sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end) as 'NETQTY',sum(case d.dealtype when 'BUY' then -d.consideration when 'SELL' then d.consideration end) as 'NETCONS'
	from dealallocations d
	where (dealdate <= @AsAt) and (approved=1) and (merged=0) and (cancelled=0)
	group by dealdate, asset
	having (sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end)) <> 0
	order by dealdate
declare sj_basic_cursor cursor FAST_FORWARD READ_ONLY for
	select  sum( case d.dealtype when 'BUY' then -d.qty when 'SELL' then d.qty end) as 'NETQTY',sum(case d.dealtype when 'BUY' then -d.consideration when 'SELL' then d.consideration end) as 'NETCONS',asset
	from dealallocations d
	where (dealdate <= @AsAt) and (approved=1) and (merged=0) and (cancelled=0) group by asset
delete from sharejob where [user] = @User
if @Detailed = 1
begin
	open sj_detailed_cursor
	fetch next from sj_detailed_cursor into @date, @asset, @netqty, @netcons
	while @@FETCH_STATUS = 0
	begin
		insert into sharejob ([user],asset,[date],netqty,netcons,mktprice,cost) values (@User,@asset,@date,@netqty,@netcons,0,0)
		fetch next from sj_detailed_cursor into @date, @asset, @netqty, @netcons
	end
	close sj_detailed_cursor
end
else
begin
	open sj_basic_cursor
	fetch next from sj_basic_cursor into @netqty, @netcons, @asset
	while @@FETCH_STATUS = 0
	begin
		if @netqty <> 0
		begin
			select @price = 0
			select top 1 @price = history from prices where (assetcode = @asset) and  ([date] <= @AsAt) order by [date] desc, [session] desc
			if @price > 0
			begin
				select @cost = round(@netcons/@netqty,4)
				insert into sharejob ([user],asset,[date],netqty,netcons,mktprice,cost) values (@User,@asset,@AsAt,@netqty,@netcons,@price,@cost)
			end
		end
		fetch next from sj_basic_cursor into @netqty, @netcons, @asset
	end
	close sj_basic_cursor
end
deallocate sj_detailed_cursor
deallocate sj_basic_cursor
return 0




GO
/****** Object:  StoredProcedure [dbo].[Login]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
{*******************************************************}
{														}
{		Author: S. Kamonere						}
{														}
{		     Copyright (c) 2012						}
{														}
{*******************************************************}
*/


CREATE  PROCEDURE [dbo].[Login]	
	
AS
declare @Host varchar(512),@Updated bit, @Download bit
select  @Host = HOST_NAME()

if not exists(select pcname from machines where [pcname] = @Host) begin insert into machines([pcname]) values(@Host) end
select @updated =updated from machines where pcname=@Host
update machines set Updated=1 where pcname=@Host

select @updated as Download --from machines where pcname=@Host

 
	
GO
/****** Object:  StoredProcedure [dbo].[LoginOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2003			}
{							}
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[LoginOld]	(
	@Username	varchar(50),
	@Password	varchar(50),
	@License	varchar(50),
	@JustChecking	bit		= 0,
	@Profile	varchar(50)	output,
	@Succeeded	bit		output,
	@Expired	bit		output
				)
AS
declare @Host varchar(512), @Locked bit, @Expiry datetime, @LoggedIn bit
declare @pcfound varchar(512)
select @Profile = '', @pcfound = ''
select @Succeeded = 0, @Expired = 0, @Locked = 0, @Expiry = NULL, @Host = HOST_NAME()
exec TimeoutUsers
if @JustChecking = 0
begin
	select @pcfound = pcname from [users] where (pcname = @Host) and (loggedin = 1)
	if @pcfound <> ''
	begin
		insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
		values (2,getdate(),@Username,'USER PC ALREADY LOGGED IN',NULL,NULL,@Host)
		return 0
	end
end
select @Profile = [PROFILE], @Locked = [islocked], @Expiry = [expdate], @LoggedIn = [loggedin]
from [users] 
where ([login] = @Username) and ([pass] = @Password)
if (@Profile = '') or (@Profile is null)
begin
	insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
	values (2,getdate(),@Username,'USER PROFILE NOT FOUND',NULL,NULL,@Host)
	return 0
end
if @JustChecking = 0
begin
	if @LoggedIn = 1
	begin
		insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
		values (2,getdate(),@Username,'USER ALREADY LOGGED IN',NULL,NULL,@Host)
		return 0
	end
end
if @Locked = 1
begin
	insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
	values (2,getdate(),@Username,'USER ACCOUNT IS LOCKED',NULL,NULL,@Host)
	return 0
end
if @JustChecking = 0
begin
	update users
	set loggedin = 1, loginat = getdate(), lastping = getdate(), pcname = @Host, pclicense = @License
	where login = @Username
end
if @Expiry <= getdate()
begin
	insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
	values (2,getdate(),@Username,'USER PASSWORD EXPIRED',NULL,NULL,@Host)
	select @Expired = 1
	return 0
end
select @Succeeded = 1
insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
values (1,getdate(),@Username,'USER LOGGED IN','PROFILE = ' + @Profile,NULL,@Host)
return 0

GO
/****** Object:  StoredProcedure [dbo].[Logout]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[Logout]	(
	@Username	varchar(50)
				)
AS
declare @Host varchar(512)
select @Host = PCNAME from [users] where [login] = @Username
update users set loggedin = 0, logoutat = getdate() where [login] = @Username
insert into [audit] ([type],[dt],[username],[description],[data],[origdata],[pcname])
values (3,getdate(),@Username,'USER LOGGED OUT',NULL,NULL,@Host)
return 0

GO
/****** Object:  StoredProcedure [dbo].[Match]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[Match]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    begin transaction
		update CASHBOOKTRANS set mid=transid where TRANSID in(select TRANSID from AutoMatch);

		merge into dealallocations
		using automatch
		on automatch.dealno = dealallocations.dealno 

		when matched --and (dealallocations.transcode in ('sale','Purch','salecnl','purchcnl'))

		then
			update set dealallocations.mid=automatch.transid
				; 
    commit
END

GO
/****** Object:  StoredProcedure [dbo].[MergeDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE     PROCEDURE [dbo].[MergeDeals]
-- ( @DealDate	datetime )
AS
/*
declare @ddate datetime, @dt datetime
select @dt = max(dealdate) from dealallocations where (approved = 0) and (cancelled = 0)
if (@dt < @DealDate)
	select @ddate = @dt
else
	select @ddate = @DealDate
*/
select ClientNo, dealtype, asset, dealdate, orderno,reference,
count(*) as cnt
from dealallocations
--where (dealdate = @ddate) and (approved = 0) and (cancelled=0)
where (approved = 0) and (cancelled=0) and orderno is not null
group by ClientNo,dealtype, asset, dealdate, orderno,Reference
having count(*) > 1
order by dealdate,asset

GO
/****** Object:  StoredProcedure [dbo].[ModifyPrice]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE    PROCEDURE [dbo].[ModifyPrice]	(
	@MAssetCode		varchar(50),
	@MDate			datetime,
	@MSession		varchar(20),
	@MStatus		varchar(50)	= 'ACTIVE',
	@MBid			money		= NULL,
	@MOffer			money		= NULL,
	@MSales			money		= NULL,
	@MVolume		numeric		= NULL,
	@MHistory		money		= NULL
				)
AS
declare @rbid money, @roffer money, @rsales money, @rhistory money, @rltp money
declare @rid numeric, @rdate datetime, @rsession varchar(10), @rstatus varchar(30)
declare @mid int, @rvolume numeric
declare @RC int
select @mid = -1, @rid = -1
EXEC @RC = [FALCON].[dbo].[ModifyPriceInternal]
	@MAssetCode,@MDate,@MSession,@mid output,@MStatus,@MBid,@MOffer,@MSales,@MVolume,@MHistory
if @RC < 0
	return @RC
declare PRICELIST cursor for
	select [id],[date],[session],[status],bid,offer,sales,history,ltp,volume
	from prices 
	where (assetcode = @MAssetCode) and ([date] >= @MDate)
	order by [date], [session], [id]
open PRICELIST
fetch next from PRICELIST into @rid,@rdate,@rsession,@rstatus,@rbid,@roffer,@rsales,@rhistory,@rltp,@rvolume
if @@FETCH_STATUS <> 0
begin
	deallocate PRICELIST
	return -1
end
while @@FETCH_STATUS = 0
begin
	if @rid = @mid
		break
	fetch next from PRICELIST into @rid,@rdate,@rsession,@rstatus,@rbid,@roffer,@rsales,@rhistory,@rltp,@rvolume
end
fetch next from PRICELIST into @rid,@rdate,@rsession,@rstatus,@rbid,@roffer,@rsales,@rhistory,@rltp,@rvolume
while (@@FETCH_STATUS = 0)
begin
	EXEC @RC = [FALCON].[dbo].[ModifyPriceInternal]
		@MAssetCode,
		@rdate,
		@rsession,
		@mid output,
		@rstatus,
		@rbid,
		@roffer,
		@rsales,
		@rvolume,
		NULL
	if @RC < 0
		return @RC
	fetch next from PRICELIST into @rid,@rdate,@rsession,@rstatus,@rbid,@roffer,@rsales,@rhistory,@rltp,@rvolume
end
deallocate PRICELIST
return 0

GO
/****** Object:  StoredProcedure [dbo].[ModifyPriceInternal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE    PROCEDURE [dbo].[ModifyPriceInternal]	(
	@AssetCode		varchar(50),
	@Date			datetime,
	@Session		varchar(20),
	@ModifiedID		int		output,
	@Status			varchar(50)	= 'ACTIVE',
	@Bid			money		= NULL,
	@Offer			money		= NULL,
	@Sales			money		= NULL,
	@Volume			numeric		= NULL,
	@History		money		= NULL
				)
AS
declare @os money, @ob money, @oo money
declare @cs money, @cb money, @co money
declare @hp money, @newhp money
declare @startdate datetime, @enddate datetime
declare @rbid money, @roffer money, @rsales money, @rhistory money, @rltp money
declare @rid numeric, @rdate datetime, @rsession varchar(10)
declare @tbid money, @toffer money, @tsales money, @thistory money, @tltp money
declare @tid numeric, @tdate datetime, @tsession varchar(10)
declare @lastid int, @lastltp money
select @lastid = -1
select	@lastid = max(id) from prices
	where	(assetcode = @AssetCode) and
		([date] = @Date) and (session = @Session)
if @lastid < 0
	return -1
select @ModifiedID = @lastid
select @hp = 0, @lastltp = 0
select	top 1 @hp = history, @lastltp = ltp from prices
	where	(assetcode = @AssetCode)
		and ([date] < @Date) 
		and (session = @Session)
	order by [date] desc, session desc, [id] desc
select @os = 0, @ob = 0, @oo = 0, @cs = 0, @cb = 0, @co = 0
if @Session = 'AM'
begin
/*
	select	top 1 @cb = bid, @co = offer, @cs = sales
		from prices
		where (assetcode = @AssetCode) and ([date] = @Date) and (session = 'PM')
		order by [id] desc
*/
	select @ob = @Bid, @oo = @Offer, @os = @Sales
end
else
	if @Session = 'PM'
	begin
		select	top 1 @ob = bid, @oo = offer, @os = sales
			from prices
			where (assetcode = @AssetCode) and ([date] = @Date) and (session = 'AM')
			order by [id] desc
		select @cb = @Bid, @co = @Offer, @cs = @Sales
	end
if (@History is null) or (@History = 0)
	select @newhp = dbo.CalculateHistoryExch(@Status,@hp,@ob,@oo,@os,@cb,@co,@cs)
else
	select @newhp = @History
/*
print '----------------------' + @Session + '--------------------------------'
print '@hp = ' + convert(varchar(20),@hp) 
print '@ob = ' + convert(varchar(20),@ob) + ', @oo = ' + convert(varchar(20),@oo) + ', @os = ' + convert(varchar(20),@os)
print '@cb = ' + convert(varchar(20),@cb) + ', @co = ' + convert(varchar(20),@co) + ', @cs = ' + convert(varchar(20),@cs)
print '@newhp = ' + convert(varchar(20),@newhp) 
print '--------------------------------------------------------'
*/
update	prices set
	Bid = @Bid, Offer = @Offer, Sales = @Sales, Volume = @Volume,
	History = @newhp,
	LTP =	case @Sales
			when null then @lastltp
			when 0 then @lastltp
			else @Sales
		end
where	[id] = @lastid
return 0

GO
/****** Object:  StoredProcedure [dbo].[NewClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[NewClient]( @NewClientNo int output )
AS
set nocount on
BEGIN TRANSACTION NEWCLI
declare @ID int, @max int
select @max = max(clientno) from clients
select @max = @max + 1
insert into clients default values
--select @NewClientNo = @@IDENTITY
select @ID = ident_current('clients')
select @NewClientNo = @max
update clients set clientno = @max where [id] = @ID
COMMIT TRANSACTION NEWCLI
return 0
set nocount off

GO
/****** Object:  StoredProcedure [dbo].[PayRec]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE           PROCEDURE [dbo].[PayRec]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@TransCode		varchar(50)=NULL,
	@TransDate		datetime2(7),
	@Description	varchar(50) = NULL,
	@Amount			decimal(31, 9)=0,
	@CashBookID		int = 0 , 
	@transid bigint   
				) 
AS


declare @BF decimal(31, 9), @CF decimal(31, 9), @NewTransDate datetime2(7)
declare @IsCredit bit
declare @Amount1 decimal(31, 9)
declare @Amount2 decimal(31, 9)
declare @Factor numeric
declare @origtransid decimal(31,9)=null
declare @MID int=0,@CID int=0

select @Amount1 = @Amount


select @BF = 0, @CF = 0


select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
if @@ERROR <> 0 return -1
if @IsCredit = 1
	select @Amount1 = -@Amount1
select @CF = @BF + @Amount1
if @TransDate is NULL
	select @TransDate = GetDate()
--select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime2(7))
select @NewTransDate = @TransDate

begin transaction
	--if(@IsCredit<>1)
		--select @origtransid=transid from CASHBOOKTRANS where ChqRqID=@ChqRqID
	insert into CASHBOOKTRANS
	([LOGIN],[ClientNo],PostDate,[TRANSCODE],[TransDate],[DESCRIPTION],[AMOUNT],ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ORIGINALTRANSID)
	values
	(@User,@ClientNo,GetDate(),@TransCode,@NewTransDate,@Description,@Amount1,@BF,@CF,@CashBookID,0,@transid)
	
	--exec TrackClientStatus @ClientNo
commit
GO
/****** Object:  StoredProcedure [dbo].[Ping]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[Ping]	(
	@Username		varchar(50),
	@Screen			varchar(255)
				)
AS
update [users]
set lastping = getdate(), lastscreen = @Screen
where ([login] = @Username) and (loggedin = 1) and (pcname = host_name())
return 0

GO
/****** Object:  StoredProcedure [dbo].[PopulateCashBook]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[PopulateCashBook]  --execute PopulateCashBook 'STANBIC', '20190401', '20910617'
@cashbook varchar(50),
@start datetime,
@end datetime,
@user varchar(30) = 'bug'
as

declare @CashBookID bigint
declare @openingbal money
declare @balbf decimal(34,4), @balcf decimal(34,4)


delete from tblCashBookReport where username = @user

select @CashBookID = id from CASHBOOKS
where code = @cashbook

set concat_null_yields_null off

delete from tblCashBookReport where username = @user

select @balbf = isnull(sum(amount), 0) from CashBookTrans 
where ((transcode like 'rec%') or (transcode like 'pay%'))
and cashbookid = @CashBookID
and TransDate < @Start
select @balcf = isnull(sum(amount), 0) from CashBookTrans 
where ((transcode like 'rec%') or (transcode like 'pay%'))
and cashbookid = @CashBookID
and TransDate <= @End

INSERT INTO tblCashBookReport
           ([TransDate]
           ,[postdate]
           ,[clientno]
           ,[transcode]
           ,[description]
           ,[amount]
           ,StartDate
           ,EndDate
           ,Balbf
           ,Balcf
		   ,username)
select x.TransDate, x.PostDate, ltrim(isnull(c.title,'')+' '+isnull(c.firstname,'')+' '+isnull(c.surname, '')+' '+isnull(c.companyname,'')) as client,
x.transcode, x.description, x.amount, @Start, @End, @Balbf, @Balcf, @user
from CashBookTrans x inner join clients c on x.ClientNo = c.clientno
where ((x.transcode like 'rec%') or (x.transcode like 'pay%'))
and x.cashbookid = @CashBookID
and x.TransDate >= @Start
and x.TransDate <= @End
order by x.TransDate, x.transid

update tblCashBookReport set CashBookID=@CashbookID

GO
/****** Object:  StoredProcedure [dbo].[PopulateJournals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Simpson Kamonere
-- Create date: 9 Dec 2010
-- Description:	Populates Ledger Report 
-- =============================================
CREATE PROCEDURE [dbo].[PopulateJournals]  -- PopulateJournals 'ADEPT','INT','20110209','20110209'
	@Login varchar(50)
	,@Journal varchar(50)
	,@StartDate datetime
	,@EndDate datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @OB decimal(32,4)
	declare @CB decimal(32,4) 
	declare @EndDate1 datetime
	declare @CBOB decimal(32,4)
	declare @ReportName varchar(300)
	
	
	
	if (substring(@Journal,1,3)='INT')
		select @ReportName='Interest Report'
	if (substring(@Journal,1,1)='A')
		select @ReportName='Arrears Journal Report'
	if (substring(@Journal,1,3)='tpa')
		select @ReportName='Transfer Charges Report'
	
	select @EndDate1=DATEADD(d,1,@enddate)
	delete from tblLedgerTemp where [login]=@Login
	delete from tblLedger where [login]=@Login
	
	
    --get data from nominal ledger
		insert into tblLedgerTemp
		select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,0,@Login,0,@ReportName,@StartDate,@EndDate 
		from transactions 
		where (yon=1) and TransCode like @Journal+'%' and TransDate>=@StartDate and TransDate<=@EndDate
		order by TransDate 
    
    --get data from cashbook 
    if (substring(@Journal,1,3)='SDR') -- FBC Sundry charge
    begin
		insert into tblLedgerTemp
		select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,0,@Login,0,@ReportName,@StartDate,@EndDate 
		from CASHBOOKTRANS 
		where ((yon=1) and (transcode like 'SDRYCHG%') or (transcode like 'BALWRDR%') or (transcode like 'BALWRCR%') )  and TransDate>=@StartDate and TransDate<=@EndDate
		order by TransDate
    end
    else
    begin
		insert into tblLedgerTemp
		select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,0,@Login,0,@ReportName,@StartDate,@EndDate  from CASHBOOKTRANS 
		where yon=1 and TransCode like @Journal+'%' and TransDate>=@StartDate and TransDate<=@EndDate
		order by TransDate
    end
       
    --get Opening Balance (OB) from nominal ledger and cashbook
    select @OB = sum(amount) from transactions
	where yon=1 and TransCode like @Journal+'%' and TransDate < @StartDate 
	if (@OB is null)
		select @OB=0
		
	if (substring(@Journal,1,3)='SDR') -- FBC Sundry charge
    begin
		select @CBOB = sum(amount) from CASHBOOKTRANS
		where ((YON=1) and(transcode like 'SDRYCHG%') or (transcode like 'BALWRDR%') or (transcode like 'BALWRCR%') ) and TransDate < @StartDate
		if (@CBOB is null)
			select @CBOB=0
	end
	else
	begin
		select @CBOB = sum(amount) from CASHBOOKTRANS
		where yon=1 and  TransCode like @Journal+'%' and TransDate < @StartDate
		if (@CBOB is null)
			select @CBOB=0
	end
		
	select @OB=@OB+@CBOB	
	
	--get Closing Balance (CB) from nominal ledger and cashbook
	select @CB = @OB+sum(amount) from tblLedgerTemp
	where Login=@Login--TransDate < @StartDate and TransDate<@EndDate
	if (@CB is null)
		select @CB=0
	
	--select @CB = @CB+sum(amount) from CASHBOOKTRANS
	--where TransDate < @StartDate and TransDate<@EndDate
	
    insert into tblLedger select *,@OB,@CB, '' from tblLedgerTemp order by TransDate
END

GO
/****** Object:  StoredProcedure [dbo].[PopulateLedger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Simpson Kamonere
-- Create date: 9 Dec 2010
-- Description:	Populates Ledger Report 
-- =============================================
CREATE PROCEDURE [dbo].[PopulateLedger]  -- PopulateLedger 'ADEPT','157','20111231','20121209'
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
	
	
	select @EndDate1=DATEADD(d,1,@enddate)
	delete from tblLedgerTemp where [login]=@Login
	delete from tblLedger where [login]=@Login
	
	
	if(@ClientNo='150')
	begin
		select @LedgerTxns='comms'
		select @LedgerPayments='comms'
		select @ReportName='Commission Report'
	end
	
	if(@ClientNo='151')
	begin
		select @LedgerTxns='vat'
		select @LedgerPayments='vat'
		select @ReportName='Value Added Tax (VAT) Report'
	end

	if(@ClientNo='152')
	begin
	
		select @LedgerTxns='sduty'
		select @LedgerPayments='sdd'
		select @ReportName='Stamp Duty Report'
	end

	if(@ClientNo='153')
	begin
		select @LedgerTxns='zselv'
		select @LedgerPayments='zselv'
		select @ReportName='ZSE Levy Report'
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
	
	if(@ClientNo='156')
	begin
		select @LedgerTxns='commlv'
		select @LedgerPayments='commlv'
		select @ReportName='S.E.C. Levy Report'
	end
	if(@ClientNo='157')
	begin
		select @LedgerTxns='NMI'
		select @LedgerPayments='NMI'
		select @ReportName='NMI Commission Rebate Report'
	end
	
	if(@ClientNo='158')
	begin
		select @LedgerTxns='bfee'
		select @LedgerPayments='bfeed'
		select @ReportName='Basic Charge Report'
	end	

	if(@ClientNo='159')
	begin
		select @LedgerTxns='CSD'
		select @LedgerPayments='CSD'
		select @ReportName='CSD Levy Report'
	end
	
	----------------------------------------------------------------------------------------------------------------------------------
	--calculating ledger balance from old falcon.
	select @OldTxnsBalance=SUM(amount) from cashbooktrans where (TRANSCODE like @LedgerPayments+'%') and transdate<=@LastTxnDate
	select @OldLedgerBalance=SUM(amount) from Transactions where yon=1 and (TRANSCODE like @LedgerTxns+'%') and transdate<=@LastTxnDate	
	and ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker')
	if @OldLedgerBalance is null
		select @OldLedgerBalance=0
	if @OldTxnsBalance is null
		select @OldtxnsBalance=0
	-----------------------------------------------------------------------------------------------------------------------------------
	
    --get data from nominal ledger
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select d.ClientNo,x.PostDate,x.DealNo,x.TransDate,x.[Description],x.Amount,@Login,d.consideration,@Reportname,@StartDate,@EndDate
	from transactions x  inner join dealallocations d on x.dealno = d.dealno
    where x.YON=1 and d.yon=1 and(TRANSCODE like(@LedgerTxns+'%') and (x.TransDate>=@StartDate and x.TransDate<=@EndDate))
    and x.ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker')
    order by x.TransDate 

	--insert tax payments
	insert into tblLedgerTemp(ClientNo,PostDate,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select x.ClientNo,x.PostDate,x.TransDate,@LedgerTxns+' TAX PAYMENT',-x.Amount,@Login,0,@Reportname,@StartDate,@EndDate
	from transactions x  
    where x.YON=1 and(TRANSCODE like(@LedgerTxns+'%DUE%') and (x.TransDate>=@StartDate and x.TransDate<=@EndDate))
    and x.ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker')
    order by x.TransDate 
    
    
    update tblLedgerTemp set Consideration=-Consideration where [Description] like '%cancellation'
    delete from tblLedgerTemp where Amount=0
   
       
    --get data from cashbook 
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],ReportName,StartDate,EndDate)
    select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,@Login,@ReportName,@StartDate,@EndDate from CASHBOOKTRANS 
    --where ClientNo=@ClientNo and TransDate>@StartDate and TransDate<@EndDate1
    where TRANSCODE like(@LedgerPayments+'%') and (TransDate>=@StartDate and TransDate<@EndDate1)
	order by TransDate
    
    
    
    --get Opening Balance (OB) from nominal ledger and cashbook
    select @OB = sum(amount) from transactions
	--where ClientNo=@ClientNo and TransDate < @StartDate 
	where TRANSCODE like(@LedgerTxns+'%')and TransDate < @StartDate 
	and ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker')
	if (@OB is null)
		select @OB=0
		
	select @CBOB = sum(amount) from CASHBOOKTRANS
	--where ClientNo=@ClientNo and TransDate < @StartDate
	where TRANSCODE like(@LedgerPayments+'%')and TransDate < @StartDate 

	if (@CBOB is null)
		select @CBOB=0
		
	select @OB=@OB+@CBOB--+(@OldTxnsBalance+@OldLedgerBalance)	
	
	--get Closing Balance (CB) from nominal ledger and cashbook
	select @CB = @OB+sum(amount) from tblLedgerTemp
	where Login=@Login--TransDate < @StartDate and TransDate<@EndDate1
	if (@CB is null)
		select @CB=0
	
	--select @CB = @CB+sum(amount) from CASHBOOKTRANS
	--where TransDate < @StartDate and TransDate<@EndDate
--set identity_insert[tblLedger] on	
insert into tblLedger(ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate, BalBF, BalCF)
select ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate,@OB,@CB from tblLedgerTemp where [LOGIN]  =@Login order by TransDate,[Description]
--set identity_insert[tblLedger] off
    
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




--select * from tblLedger
GO
/****** Object:  StoredProcedure [dbo].[PopulateLedger2]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Simpson Kamonere
-- Create date: 9 Dec 2010
-- Description:	Populates Ledger Report 
-- =============================================
CREATE PROCEDURE [dbo].[PopulateLedger2]  -- PopulateLedger 'ADEPT','157','20111231','20121209'
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
	--calculating ledger balance from old falcon.
	select @OldTxnsBalance=SUM(amount) from cashbooktrans where (TRANSCODE like @LedgerPayments+'%') and transdate >= '20190401' and transdate<=@LastTxnDate and clientno = @clientno
	select @OldLedgerBalance=SUM(amount) from Transactions where yon=1 and (TRANSCODE like @LedgerTxns+'%') and transdate >= '20190401' and  transdate<=@LastTxnDate and clientno = @clientno
	and ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker')
	if @OldLedgerBalance is null
		select @OldLedgerBalance=0
	if @OldTxnsBalance is null
		select @OldtxnsBalance=0
	-----------------------------------------------------------------------------------------------------------------------------------
	
    --get data from nominal ledger
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select d.ClientNo,x.PostDate,x.DealNo,x.TransDate,x.[Description],x.Amount,@Login,d.consideration,@Reportname,@StartDate,@EndDate
	from transactions x  inner join dealallocations d on x.dealno = d.dealno
    where x.YON=1 and d.yon=1 and(TRANSCODE like(@LedgerTxns+'%') and (x.TransDate>=@StartDate and x.TransDate<=@EndDate))
    and (x.ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker'))
	and x.clientno = @clientno
    order by x.TransDate 

	--insert tax payments
	insert into tblLedgerTemp(ClientNo,PostDate,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select x.ClientNo,x.PostDate,x.TransDate,@LedgerTxns+' TAX PAYMENT',-x.Amount,@Login,0,@Reportname,@StartDate,@EndDate
	from transactions x  
    where x.YON=1 and(TRANSCODE like(@LedgerTxns+'%DUE%') and (x.TransDate>=@StartDate and x.TransDate<=@EndDate))
    and (x.ClientNo not in(select ClientNo from CLIENTS where CATEGORY='broker'))
	and x.clientno = @clientno
    order by x.TransDate 
    
    
    update tblLedgerTemp set Consideration=-Consideration where [Description] like '%cancellation'
    delete from tblLedgerTemp where Amount=0
   
       
    --get data from cashbook 
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],ReportName,StartDate,EndDate)
    select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,@Login,@ReportName,@StartDate,@EndDate from CASHBOOKTRANS 
    --where ClientNo=@ClientNo and TransDate>@StartDate and TransDate<@EndDate1
    where TRANSCODE like(@LedgerPayments+'%') and (TransDate>=@StartDate and TransDate<@EndDate1)
	and clientno = @ClientNo
	order by TransDate
    
    
    
    --get Opening Balance (OB) from nominal ledger and cashbook
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
	
	--get Closing Balance (CB) from nominal ledger and cashbook
	select @CB = @OB+sum(amount) from tblLedgerTemp
	where Login=@Login--TransDate < @StartDate and TransDate<@EndDate1
	if (@CB is null)
		select @CB=0
	
	--select @CB = @CB+sum(amount) from CASHBOOKTRANS
	--where TransDate < @StartDate and TransDate<@EndDate
--set identity_insert[tblLedger] on	
insert into tblLedger(ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate, BalBF, BalCF)
select ClientNo, PostDate, DealNo, TransDate, [Description], Amount, DealValue, [Login], Consideration, ReportName, StartDate, EndDate,@OB,@CB from tblLedgerTemp where [LOGIN]  =@Login order by TransDate,[Description]
--set identity_insert[tblLedger] off
    
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




--select * from tblLedger
GO
/****** Object:  StoredProcedure [dbo].[PopulateLedgerOLD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Simpson Kamonere
-- Create date: 9 Dec 2010
-- Description:	Populates Ledger Report 
-- =============================================
CREATE PROCEDURE [dbo].[PopulateLedgerOLD]  -- PopulateLedger 'ADEPT','157','20111231','20121209'
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
	
	----------------------------------------------------------------------------------------------------------------------------------
	--calculating ledger balance from old falcon.
	select @OldTxnsBalance=SUM(amount) from cashbooktrans where (TRANSCODE like @LedgerPayments+'%') and transdate<=@LastTxnDate
	select @OldLedgerBalance=SUM(amount) from Transactions where yon=1 and (TRANSCODE like @LedgerTxns+'%') and transdate<=@LastTxnDate	
	if @OldLedgerBalance is null
		select @OldLedgerBalance=0
	if @OldTxnsBalance is null
		select @OldtxnsBalance=0
	-----------------------------------------------------------------------------------------------------------------------------------
	
    --get data from nominal ledger
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],Consideration,ReportName,StartDate,EndDate)
    select d.ClientNo,x.PostDate,x.DealNo,x.TransDate,x.[Description],x.Amount,@Login,d.consideration,@Reportname,@StartDate,@EndDate
	from transactions x  inner join dealallocations d on x.dealno = d.dealno
    where x.YON=1 and (TRANSCODE like(@LedgerTxns+'%') and (x.TransDate>=@StartDate and x.TransDate<@EndDate1))
    order by x.TransDate 
   
       
    --get data from cashbook 
    insert into tblLedgerTemp(ClientNo,PostDate,DealNo,TransDate,[Description],Amount,[Login],ReportName,StartDate,EndDate)
    select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,@Login,@ReportName,@StartDate,@EndDate from CASHBOOKTRANS 
    --where ClientNo=@ClientNo and TransDate>@StartDate and TransDate<@EndDate1
    where TRANSCODE like(@LedgerPayments+'%') and (TransDate>=@StartDate and TransDate<@EndDate1)
	order by TransDate
    
    
    
    --get Opening Balance (OB) from nominal ledger and cashbook
    select @OB = sum(amount) from transactions
	--where ClientNo=@ClientNo and TransDate < @StartDate 
	where TRANSCODE like(@LedgerTxns+'%')and TransDate < @StartDate 
	if (@OB is null)
		select @OB=0
		
	select @CBOB = sum(amount) from CASHBOOKTRANS
	--where ClientNo=@ClientNo and TransDate < @StartDate
	where TRANSCODE like(@LedgerPayments+'%')and TransDate < @StartDate 

	if (@CBOB is null)
		select @CBOB=0
		
	select @OB=@OB+@CBOB--+(@OldTxnsBalance+@OldLedgerBalance)	
	
	--get Closing Balance (CB) from nominal ledger and cashbook
	select @CB = @OB+sum(amount) from tblLedgerTemp
	where Login=@Login--TransDate < @StartDate and TransDate<@EndDate1
	if (@CB is null)
		select @CB=0
	
	--select @CB = @CB+sum(amount) from CASHBOOKTRANS
	--where TransDate < @StartDate and TransDate<@EndDate
	
    insert into tblLedger select *,@OB,@CB from tblLedgerTemp where login=@Login order by TransDate 
    
END


GO
/****** Object:  StoredProcedure [dbo].[PopulateRebates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Simpson Kamonere
-- Create date: 17 Aug. 2011
-- Description:	Loads clients rebates
-- =============================================
CREATE PROCEDURE [dbo].[PopulateRebates]  --  PopulateRebates '','ADEPT'
	@ClientNo varchar(50)
	,@User varchar(50)
AS
BEGIN
	declare @AsAt datetime
	set @AsAt=GETDATE()
	SET NOCOUNT ON;
	delete from rebates where [USER]=@user
	if (@ClientNo ='ALL')
	begin
		insert into rebates(clientno,dealno,transdate,amount,dealtype,asset,qty,price,consideration,commission,[user])
		select clientno,'PAYMENT',transdate,amount,'','','','','','',@user 
		from CASHBOOKTRANS where clientno in (select ClientNo from CLIENTS where CATEGORY like 'nmi%') and TransCode like 'nmi%' and transdate<=@AsAt
		union
		select clientno,dealno,dealdate,nmirebate,dealtype,asset,qty,price,consideration,grosscommission,@User 
		from DEALALLOCATIONS where dealdate >='20111101'  and dealdate <= @AsAt and clientno in (select ClientNo from CLIENTS where CATEGORY like 'nmi%') 
		and NMIRebate>0 and  APPROVED=1 and Cancelled=0 and MERGED=0 and DealNo in (select DealNo from transactions)
		
	end
	else
	begin
		insert into rebates(clientno,dealno,transdate,amount,dealtype,asset,qty,price,consideration,commission,[user])
		select clientno,'PAYMENT',transdate,amount,'','','','','','',@user from CASHBOOKTRANS where TransCode like 'nmi%' and clientno=@ClientNo and transdate<=@AsAt
		union
		select clientno,dealno,dealdate,nmirebate,dealtype,asset,qty,price,consideration,grosscommission,@User from DEALALLOCATIONS where APPROVED=1 and Cancelled=0 and MERGED=0 and DealNo in (select DealNo from transactions)
		and ClientNo=@ClientNo and DealDate<=@AsAt
	end
END


GO
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		S. Kamonere
-- Create date: July 2011
-- Description:	Client's transactions
-- =============================================
CREATE PROCEDURE [dbo].[PopulateStatementsReport]  --PopulateStatementsReport '5615MMC','20190301','20190329','ADEPT'
	@ClientNo as varchar(50)
	,@StartDate as date
	,@EndDate as date
	,@User as varchar(50)
AS
BEGIN
	delete  from StatementsReport where ClientNo=@ClientNo and Login =@User
	SET NOCOUNT ON;
	
	--getting nominal transactions
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login]) 
	select     ClientNo, dbo.Transactions.DEALNO, dbo.Transactions.TRANSID,dbo.Transactions.TransDate,dbo.Transactions.TransCode,   
               dbo.Transactions.Amount,@User
	from       dbo.Transactions 
	where    yon=1and (dbo.Transactions.TransCode = 'TAKEONDB' OR
				dbo.Transactions.TransCode = 'TAKEONCR' OR
				dbo.Transactions.TransCode = 'NMIRBT' OR
				dbo.Transactions.TransCode = 'AINCJ' OR
                      dbo.Transactions.TransCode = 'TPAYFEECNL' OR
			          dbo.Transactions.TransCode = 'NMIRBTCNL' OR
                      dbo.Transactions.TransCode = 'TPAYFEE' OR
                      --dbo.Transactions.TransCode = 'SALE' OR
                      --dbo.Transactions.TransCode = 'SALECNL' OR
                      --dbo.Transactions.TransCode = 'PURCH' OR
                      --dbo.Transactions.TransCode = 'PURCHCNL' OR
                      dbo.Transactions.TransCode = 'DIVPAY' OR
                      dbo.Transactions.TransCode = 'DIVREC') AND 
                      ClientNo = @ClientNo order by  TransDate asc,TRANSID asc

	--get purchase and sale related transactions
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login], qty, price, asset) 
	select     dbo.Transactions.ClientNo, dbo.Transactions.DEALNO, dbo.Transactions.TRANSID,dbo.Transactions.TransDate,dbo.Transactions.TransCode,   
               dbo.Transactions.Amount,@User, dbo.DEALALLOCATIONS.qty, dbo.DEALALLOCATIONS.price, dbo.DEALALLOCATIONS.ASSET
	from       dbo.Transactions inner join dbo.DEALALLOCATIONS on dbo.Transactions.DealNo = dbo.DEALALLOCATIONS.dealno
	where    (
                      dbo.Transactions.TransCode = 'SALE' OR
                      dbo.Transactions.TransCode = 'SALECNL' OR
                      dbo.Transactions.TransCode = 'PURCH' OR
                      dbo.Transactions.TransCode = 'PURCHCNL' ) AND 
                      dbo.Transactions.ClientNo = @ClientNo 
					  and dbo.Transactions.TransDate >= @StartDate
					  and dbo.Transactions.TransDate <= @EndDate order by  TransDate asc,TRANSID asc

	--get payments and receipts
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login],MatchID)
	select ClientNo,NUll as DealNo, Transid,TransDate,TransCode + ' - '+[Description],Amount,@User,MID
	from cashbooktrans
	where clientno=@ClientNo and YON=1
	and transdate >= @StartDate
	and transdate <= @EndDate
	order by TransDate asc,TRANSID asc

	--insert CSD control account charges transactions - 19May2020
	if exists(select controlaccount from tblSystemParams where ControlAccount = @ClientNo)
	begin
		insert into statementsreport(clientno, transid, transdate, transcode, amount, [login])
		select clientno, transid, transdate, transcode+' - '+[description], amount, @user
		from transactions 
		where clientno = @clientno and yon = 1
		and transdate >= @StartDate
		and transdate <= @EndDate
		order by TransDate asc,TRANSID asc
	end
	
	
	update StatementsReport set balbf=0,balcf=0 where LOGIN=@User and ClientNo=@ClientNo
	update StatementsReport set Amount=-amount where TransCode like 'nmirbtd%' and LOGIN=@User and ClientNo=@ClientNo

	declare @BF decimal(31,9)
	declare @Amount decimal(31,9)
	declare @CF decimal(31,9)
	declare @PreviousCF decimal(31,9)
	declare @PreviousRecID bigint
	declare @RecID bigint
	
	select @BF = 0
	select @CF =0
	select @PreviousCF=0

	exec Age_AmountsClient @ClientNo,@User, @EndDate
	select @BF=isnull(SUM(amount),0) from StatementsReport where transdate<@StartDate and CLIENTNO=@ClientNo and [Login]=@User
	select @CF=isnull(SUM(amount),0) from StatementsReport where  CLIENTNO=@ClientNo and [Login]=@User and TransDate<=@EndDate
	
	update STATEMENTS set balcf=@cf,balbf=@BF,STARTDATE=@StartDate,ENDDATE=@EndDate where CLIENTNO=@ClientNo and [USER]=@User
	
	
END



GO
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReportMulti]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		S. Kamonere
-- Create date: July 2011
-- Description:	Client's transactions
-- =============================================
create PROCEDURE [dbo].[PopulateStatementsReportMulti]  -- PopulateStatementsReportMulti 4,6,'','','20110101','20110120','ADEPT'
	@StartingClientNo	int
	,@EndingClientNo		int
	,@StartingClientLetter	char(1)
	,@EndingClientLetter	char(1)
	,@StartDate as date
	,@EndDate as date
	,@User as varchar(50)
	
AS
BEGIN
	declare @i varchar(50),@fname varchar(500),@maxcli int,@ClientNo varchar(50),@Initials varchar(3)
	delete  from StatementsReport where [LOGIN] =@User
	delete  from Statements where [USER] =@User
	SET NOCOUNT ON;
	if @StartingClientNo > 0
	begin
	select @initials= CompanyInitials from company
	select @maxcli = max(cast(replace(clientno,@initials,'') as int)) from clients
	
	if @EndingClientNo = -1
		select @EndingClientNo = @maxcli
	else
	begin
		if @EndingClientNo > @maxcli
			select @EndingClientNo = @maxcli
	end
	
	select @i = @StartingClientNo
	while @i <= @EndingClientNo
	begin
		if(@i>50)
			set @ClientNo=@i+@initials
		else
			set @ClientNo=@i	
		exec PopulateStatementsReport @ClientNo,@StartDate,@EndDate,@User
		select @i = @i + 1
	end
end
else
begin
	set concat_null_yields_null off
	declare client_cursor cursor for
			select clientno, ltrim(rtrim(surname + ' ' + companyname)) as fullname from clients
			where (ascii(left(upper(ltrim(rtrim(surname + ' ' + companyname))),1)) >= ascii(upper(@StartingClientLetter))) and (ascii(left(upper(ltrim(rtrim(surname + ' ' + companyname))),1)) <= ascii(upper(@EndingClientLetter)))
			order by fullname
		open client_cursor
		fetch next from client_cursor into @i, @fname
		while @@FETCH_STATUS = 0
		begin
			exec PopulateStatementsReport @i,@StartDate,@EndDate,@User
			fetch next from client_cursor into @i, @fname
		end
	close client_cursor
	deallocate client_cursor
end
END



GO
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReportOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: July 2011
-- Description:	Client's transactions
-- =============================================
CREATE PROCEDURE [dbo].[PopulateStatementsReportOld]  --PopulateStatementsReport '11','20110101','20110803','ADEPT'
	@ClientNo as varchar(50)
	,@StartDate as date
	,@EndDate as date
	,@User as varchar(50)
AS
BEGIN
	delete  from StatementsReport where ClientNo=@ClientNo and Login =@User
	SET NOCOUNT ON;
	
	--getting nominal transactions
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login]) 
	select     ClientNo, dbo.Transactions.DEALNO, dbo.Transactions.TRANSID,dbo.Transactions.TransDate,dbo.Transactions.TransCode,   
               dbo.Transactions.Amount,@User
	from       dbo.Transactions 
	where    (yon=1) and (dbo.Transactions.TransCode = 'TAKEONDB' OR
				dbo.Transactions.TransCode = 'TAKEONCR' OR
				dbo.Transactions.TransCode = 'NMIRBT' OR
				dbo.Transactions.TransCode = 'AINCJ' OR
			          dbo.Transactions.TransCode = 'NMIRBTCNL' OR
                      dbo.Transactions.TransCode = 'SALE' OR
                      dbo.Transactions.TransCode = 'TPAYFEECNL' OR
                      dbo.Transactions.TransCode = 'TPAYFEE' OR
                      dbo.Transactions.TransCode = 'SALECNL' OR
                      dbo.Transactions.TransCode = 'PURCH' OR
                      dbo.Transactions.TransCode = 'PURCHCNL' OR
                      dbo.Transactions.TransCode = 'DIVPAY' OR
                      dbo.Transactions.TransCode = 'DIVREC') AND 
                      ClientNo = @ClientNo order by  TransDate asc,TRANSID asc
	--get payments aand receipts
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login])
	select ClientNo,NUll as DealNo, Transid,TransDate,TransCode + ' - '+[Description],Amount,@User  from cashbooktrans
	where (yon=1) and clientno=@ClientNo 
	order by TransDate asc,TRANSID asc
	
	
	update StatementsReport set balbf=0,balcf=0 where LOGIN=@User and ClientNo=@ClientNo
	update StatementsReport set Amount=-amount where TransCode like 'nmirbtd%' and LOGIN=@User and ClientNo=@ClientNo

	declare @BF decimal(32,4)
	declare @Amount decimal(32,4)
	declare @CF decimal(32,4)
	declare @PreviousCF decimal(32,4)
	declare @PreviousRecID bigint
	declare @RecID bigint
	
	select @BF = 0
	select @CF =0
	select @PreviousCF=0

	exec Age_AmountsClient @ClientNo,@User, @EndDate
	select @BF=SUM(amount) from StatementsReport where transdate<@StartDate and CLIENTNO=@ClientNo and [Login]=@User
	select @CF=round(SUM(amount),2) from StatementsReport where  CLIENTNO=@ClientNo and [Login]=@User
	
	update STATEMENTS set balcf=@cf,balbf=@BF,STARTDATE=@StartDate,ENDDATE=@EndDate where CLIENTNO=@ClientNo and [USER]=@User
	
	
END


GO
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReportPD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: July 2011
-- Description:	Client's transactions
-- =============================================
create PROCEDURE [dbo].[PopulateStatementsReportPD]  --PopulateStatementsReport '11','20110101','20110803','ADEPT'
	@ClientNo as varchar(50)
	,@StartDate as date
	,@EndDate as date
	,@User as varchar(50)
AS
BEGIN
	delete  from StatementsReport where ClientNo=@ClientNo and Login =@User
	SET NOCOUNT ON;
	
	--getting nominal transactions
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login]) 
	select     ClientNo, dbo.Transactions.DEALNO, dbo.Transactions.TRANSID,dbo.Transactions.postdate,dbo.Transactions.TransCode,   
               dbo.Transactions.Amount,@User
	from       dbo.Transactions 
	where    (yon=1) and (dbo.Transactions.TransCode = 'TAKEONDB' OR
				dbo.Transactions.TransCode = 'TAKEONCR' OR
				dbo.Transactions.TransCode = 'NMIRBT' OR
				dbo.Transactions.TransCode = 'AINCJ' OR
			          dbo.Transactions.TransCode = 'NMIRBTCNL' OR
                      dbo.Transactions.TransCode = 'SALE' OR
                      dbo.Transactions.TransCode = 'TPAYFEECNL' OR
                      dbo.Transactions.TransCode = 'TPAYFEE' OR
                      dbo.Transactions.TransCode = 'SALECNL' OR
                      dbo.Transactions.TransCode = 'PURCH' OR
                      dbo.Transactions.TransCode = 'PURCHCNL' OR
                      dbo.Transactions.TransCode = 'DIVPAY' OR
                      dbo.Transactions.TransCode = 'DIVREC') AND 
                      ClientNo = @ClientNo order by  postdate asc,TRANSID asc
	--get payments aand receipts
	insert into statementsreport(ClientNo,DealNo,TransID,TransDate,TransCode,Amount,[Login])
	select ClientNo,NUll as DealNo, Transid,postdate,TransCode + ' - '+[Description],Amount,@User  from cashbooktrans
	where (yon=1) and clientno=@ClientNo 
	order by postdate asc,TRANSID asc
	
	
	update StatementsReport set balbf=0,balcf=0 where LOGIN=@User and ClientNo=@ClientNo
	update StatementsReport set Amount=-amount where TransCode like 'nmirbtd%' and LOGIN=@User and ClientNo=@ClientNo

	declare @BF decimal(32,4)
	declare @Amount decimal(32,4)
	declare @CF decimal(32,4)
	declare @PreviousCF decimal(32,4)
	declare @PreviousRecID bigint
	declare @RecID bigint
	
	select @BF = 0
	select @CF =0
	select @PreviousCF=0

	exec Age_AmountsClient @ClientNo,@User, @EndDate
	select @BF=SUM(amount) from StatementsReport where TransDate<@StartDate and CLIENTNO=@ClientNo and [Login]=@User
	select @CF=round(SUM(amount),2) from StatementsReport where  CLIENTNO=@ClientNo and [Login]=@User
	
	update STATEMENTS set balcf=@cf,balbf=@BF,STARTDATE=@StartDate,ENDDATE=@EndDate where CLIENTNO=@ClientNo and [USER]=@User
	
	
END


GO
/****** Object:  StoredProcedure [dbo].[PopulateTBItemised]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PopulateTBItemised]  -- PopulateTBItemised 'ADEPT','151','20101209','20110106'
	@Login varchar(50)
	,@ClientNo varchar(50)
	,@StartDate datetime='20110101'
	,@EndDate datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @OB decimal(32,4)
	declare @CB decimal(32,4) 
	declare @EndDate1 datetime
	declare @CBOB decimal(32,4)
	
	select @EndDate1=DATEADD(d,1,@enddate)
	delete from TBItemisedTemp
    --get data from nominal ledger
    insert into TBItemisedTemp
    select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,@Login 
    from transactions 
    where ClientNo=@ClientNo and TransDate>@StartDate and TransDate<@EndDate1
    order by TransDate 
    
    --get data from cashbook 
    insert into TBItemisedTemp
    select ClientNo,PostDate,DealNo,TransDate,[Description],Amount,@Login from CASHBOOKTRANS 
    where ClientNo=@ClientNo and TransDate>@StartDate and TransDate<@EndDate1
    order by TransDate
    
    
    
    --get Opening Balance (OB) from nominal ledger and cashbook
    select @OB = sum(amount) from transactions
	where ClientNo=@ClientNo and TransDate < @StartDate 
	if (@OB is null)
		select @OB=0
		
	select @CBOB = sum(amount) from CASHBOOKTRANS
	where ClientNo=@ClientNo and TransDate < @StartDate
	if (@CBOB is null)
		select @CBOB=0
		
	select @OB=@OB+@CBOB	
	
	--get Closing Balance (CB) from nominal ledger and cashbook
	select @CB = @OB+sum(amount) from TBItemisedTemp
	where Login=@Login and clientno=@ClientNo--TransDate < @StartDate and TransDate<@EndDate1
	if (@CB is null)
		select @CB=0
	
    insert into TBItemised select *,@OB,@CB from TBItemisedTemp where clientno=@clientno order by TransDate
END

GO
/****** Object:  StoredProcedure [dbo].[PostPay]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE           PROCEDURE [dbo].[PostPay]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@DealNo			varchar(40) = NULL,
	@TransCode		varchar(50)=NULL,
	@TransDate		datetime2(7),
	@Description	varchar(50) = NULL,
	@Amount			decimal(38,4)=0,
    @Cash			bit = 0,
	@Bank			varchar(50) = NULL,
	@BankBranch		varchar(20) = NULL,
	@ChequeNo		varchar(20) = NULL,
	@Drawer			varchar(50) = NULL,
	@RefNo			varchar(40) = NULL,
	@CashBookID		int = 0,
	@ChqRqID		int=0,
    @ExCurrency		varchar(50)=NULL,
    @ExRate			float=0,
    @ExAmount		float=0,
    @MatchID		bigint=0,
    @DrCr			varchar(50))
AS


	declare @BF decimal(38,4), @CF decimal(38,4), @NewTransDate datetime2(7)
	declare @IsCredit bit
	declare @Amount1 decimal(38,4)
	declare @Amount2 decimal(38,4)
	declare @Factor numeric
	declare @ExtraCharge int
	declare @Pass int=0
	declare @origtransid int =0

	select @Amount1 = @Amount
	select @BF = 0, @CF = 0

begin transaction
	
	if(@DrCr='Debit')--payment reversal
	begin
	--	select @ExRate=ExR
		select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
		if @@ERROR <> 0 return -1
		if @IsCredit = 1
			select @Amount1 = -@Amount1
		select @CF = @BF + @Amount1
		if @TransDate is NULL
			select @TransDate = GetDate()
		--select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime2(7))
		select @NewTransDate = @TransDate
		--select @ChqRqID=TransID from CASHBOOKTRANS where TRANSID=@TransID

		select @origtransid=transid from CASHBOOKTRANS where ChqRqID=@ChqRqID
		insert into CASHBOOKTRANS
		([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID,ORIGINALTRANSID)
		values
		(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,1,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID,@origtransid)

		--Check whether payment has an extra charge  associated with it
		if(@DealNo<>'0')
		begin
		select @ExtraCharge=COUNT(chqrqid) from CASHBOOKTRANS where (ChqRqID=@ChqRqID and DealNo=@DealNo and Transcode not like'pay%') 
		if (@ExtraCharge>0)
		begin
			select @Amount=-Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryc%'
			if(@Amount is not null)--approve if sundry charge has a value
			begin
				insert into CASHBOOKTRANS
				([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
				values
				(@User,@ClientNo,GetDate(),@DealNo,'SDRYCHGCNL',@NewTransDate,@RefNo,'BANK CHARGE CANCELLATION',@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,1,@ChqRqID,@ExCurrency,@ExRate,@Amount,@MatchID)
			end

			select @Amount=-Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryi%'
			if(@Amount is not null) --approve if sundry income has a value
			begin
				insert into CASHBOOKTRANS
				([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
				values
				(@User,@ClientNo,GetDate(),@DealNo,'SDRYINCCNL',@NewTransDate,@RefNo,'E.P.C. CANCELLATION',@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,1,@ChqRqID,@ExCurrency,@ExRate,@Amount,@MatchID)
			end
		end	
	end	
	end
	
	if(@DrCr='Credit')
	begin
		select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
		if @@ERROR <> 0 return -1
		if @IsCredit = 1
			select @Amount1 = -@Amount1
		select @CF = @BF + @Amount1
		if @TransDate is NULL
			select @TransDate = GetDate()
		--select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime2(7))
		select @NewTransDate = @TransDate


			insert into CASHBOOKTRANS
			([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
			values
			(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)

			--Check whether payment has an extra charge  associated with it
			if (@dealno<>'0')
			begin	
				select @ExtraCharge=COUNT(reqid) from requisitions where DealNo=@DealNo and  Transcode<>'pay' 
				if (@ExtraCharge>0)
				begin
					select @Amount=Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryc%'
					if(@Amount>0)--approve if sundry charge has a value
					begin
						insert into CASHBOOKTRANS
						([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
						values
						(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)
					end

					select @Amount=Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryi%'
					if(@Amount>0) --approve if sundry income has a value
					begin
						insert into CASHBOOKTRANS
						([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
						values
						(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)
					end
				end
			end
			--update REQUISITIONS set MatchID=@ChqRqID,APPROVED=1 where DealNo=@DealNo
	end	
	

	
commit

GO
/****** Object:  StoredProcedure [dbo].[PostPayOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create           PROCEDURE [dbo].[PostPayOld]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@DealNo			varchar(40) = NULL,
	@TransCode		varchar(50)=NULL,
	@TransDate		datetime2(7),
	@Description	varchar(50) = NULL,
	@Amount			decimal(38,4)=0,
    @Cash			bit = 0,
	@Bank			varchar(50) = NULL,
	@BankBranch		varchar(20) = NULL,
	@ChequeNo		varchar(20) = NULL,
	@Drawer			varchar(50) = NULL,
	@RefNo			varchar(40) = NULL,
	@CashBookID		int = 0,
	@ChqRqID		int=0,
    @ExCurrency		varchar(50)=NULL,
    @ExRate			float=0,
    @ExAmount		float=0,
    @MatchID		bigint=0,
    @DrCr			varchar(50))
AS


	declare @BF decimal(38,4), @CF decimal(38,4), @NewTransDate datetime2(7)
	declare @IsCredit bit
	declare @Amount1 decimal(38,4)
	declare @Amount2 decimal(38,4)
	declare @Factor numeric
	declare @ExtraCharge int
	declare @Pass int=0

	select @Amount1 = @Amount
	select @BF = 0, @CF = 0

begin transaction
	
	if(@DrCr='Debit')
	begin
	--	select @ExRate=ExR
		select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
		if @@ERROR <> 0 return -1
		if @IsCredit = 1
			select @Amount1 = -@Amount1
		select @CF = @BF + @Amount1
		if @TransDate is NULL
			select @TransDate = GetDate()
		--select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime2(7))
		select @NewTransDate = @TransDate
		--select @ChqRqID=TransID from CASHBOOKTRANS where TRANSID=@TransID


		insert into CASHBOOKTRANS
		([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
		values
		(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,1,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)

		--Check whether payment has an extra charge  associated with it
		select @ExtraCharge=COUNT(chqrqid) from CASHBOOKTRANS where ChqRqID=@ChqRqID and DealNo=@DealNo and Transcode<>'pay' 
		if (@ExtraCharge>0)
		begin
			select @Amount=-Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryc%'
			if(@Amount is not null)--approve if sundry charge has a value
			begin
				insert into CASHBOOKTRANS
				([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
				values
				(@User,@ClientNo,GetDate(),@DealNo,'SDRYCHGCNL',@NewTransDate,@RefNo,'BANK CHARGE CANCELLATION',@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,1,@ChqRqID,@ExCurrency,@ExRate,@Amount,@MatchID)
			end

			select @Amount=-Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryi%'
			if(@Amount is not null) --approve if sundry income has a value
			begin
				insert into CASHBOOKTRANS
				([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
				values
				(@User,@ClientNo,GetDate(),@DealNo,'SDRYINCCNL',@NewTransDate,@RefNo,'E.P.C. CANCELLATION',@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,1,@ChqRqID,@ExCurrency,@ExRate,@Amount,@MatchID)
			end
		end	
	end	
	
	if(@DrCr='Credit')
	begin
		select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
		if @@ERROR <> 0 return -1
		if @IsCredit = 1
			select @Amount1 = -@Amount1
		select @CF = @BF + @Amount1
		if @TransDate is NULL
			select @TransDate = GetDate()
		--select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime2(7))
		select @NewTransDate = @TransDate


			insert into CASHBOOKTRANS
			([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
			values
			(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)

			--Check whether payment has an extra charge  associated with it
			select @ExtraCharge=COUNT(reqid) from requisitions where DealNo=@DealNo and Transcode<>'pay' 
			if (@ExtraCharge>0)
			begin
				select @Amount=Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryc%'
				if(@Amount>0)--approve if sundry charge has a value
				begin
					insert into CASHBOOKTRANS
					([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
					values
					(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)
				end

				select @Amount=Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode like 'sdryi%'
				if(@Amount>0) --approve if sundry income has a value
				begin
					insert into CASHBOOKTRANS
					([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
					values
					(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)
				end
			end
			update REQUISITIONS set MatchID=@ChqRqID,APPROVED=1 where DealNo=@DealNo
	end	
	

	
commit

GO
/****** Object:  StoredProcedure [dbo].[PostRec]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE           PROCEDURE [dbo].[PostRec]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@DealNo			varchar(40) = NULL,
	@TransCode		varchar(50)=NULL,
	@TransDate		datetime2(7),
	@Description	varchar(50) = NULL,
	@Amount			decimal(31,9)=0,
    @Cash			bit = 0,
	@Bank			varchar(50) = NULL,
	@BankBranch		varchar(20) = NULL,
	@ChequeNo		varchar(20) = NULL,
	@Drawer			varchar(50) = NULL,
	@RefNo			varchar(40) = NULL,
	@CashBookID		int = 0,
	@ChqRqID		int,
    --@Transid		int = 0,
    @ExCurrency		varchar(50)=NULL,
    @ExRate			float=0,
    @ExAmount		float=0,
    @MatchID		bigint,
    @CurrentUser	varchar(50),
    @Method			varchar(50),
    @Payee			varchar(150)
				) 
AS


declare @BF decimal(31,9), @CF decimal(31,9), @NewTransDate datetime2(7)
declare @IsCredit bit
declare @Amount1 decimal(31,9)
declare @Amount2 decimal(31,9)
declare @Factor numeric
declare @ExtraCharge int
declare @ApproveReceipts bit
declare @MID int=0,@CID int=0

select @Amount1 = @Amount

/*select @Factor = Factor from AccountsParams
select @Amount2 = convert(decimal(38,2), @Amount)

if @Divided = 1
 select @Amount1 = @amount2*@Factor
else
 select @Amount1 = @amount2 */

select @BF = 0, @CF = 0

/*select top 1 @BF = ARREARSCF from CASHBOOKTRANS 
where (CNO = @ClientNo)
order by transdt desc, transid desc   --order by postdt desc
if @@ERROR <> 0 return -1*/
select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
if @@ERROR <> 0 return -1
if @IsCredit = 1
	select @Amount1 = -@Amount1
select @CF = @BF + @Amount1
if @TransDate is NULL
	select @TransDate = GetDate()
----select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime2(7))
--select @NewTransDate = @TransDate

begin transaction
	select @ApproveReceipts=ApproveReceipts from businessrules
	if (@ApproveReceipts=0)                          
    begin
		insert into requisitions(clientno,amount,dealno,method,transdate,postdate,chqamt,payee,approved,[description],enteredby,cashbookid,isreceipt,transcode,cancelled)
		values (@ClientNo, @Amount, @DealNo, @Method,@Transdate,GETDATE(),@Amount1,@Payee,1,@Description,@CurrentUser,@CashBookID,1,'REC',0)
    
    	select @ChqRqID=max(reqid) from requisitions where enteredby=@CurrentUser
		set @MatchID=@ChqRqID
		
		insert into CASHBOOKTRANS
		([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
		values
		(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@TransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)

		--Check whether payment has an extra charge  associated with it
		select @ExtraCharge=COUNT(reqid) from requisitions where DealNo=@DealNo and Transcode<>'pay' 
		if (@ExtraCharge>0)
		begin
			select @Amount=Amount,@TransCode=Transcode,@Description=[Description] from requisitions where DealNo=@DealNo and Transcode<>'pay'
			insert into CASHBOOKTRANS
			([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID)
			values
			(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@TransDate,@RefNo,@Description,@Amount,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID)
		end

		update dealallocations set chqrqid= @ChqRqID where dealno in(select dealno from payclientdeals where selected=1 and [user]=@CurrentUser)
		--new matching for aging
		select top 1 @Mid=Transid, @CID=chqrqid from CASHBOOKTRANS where [login]=@User order by TRANSID desc
		update CASHBOOKTRANS set MID=@MID where TRANSID=@MID
		update DEALALLOCATIONS set MID=@MID where CHQRQID=@CID
	end
	else if(@ApproveReceipts=1)
	begin
		insert into requisitions(clientno,amount,dealno,method,transdate,postdate,chqamt,payee,approved,[description],enteredby,cashbookid,isreceipt,transcode,cancelled)
		values (@ClientNo, @Amount, @DealNo, @Method,@Transdate,GETDATE(),@Amount,@Payee,0,@Description,@CurrentUser,@CashBookID,1,'REC',0)
    end
exec TrackClientStatus	@ClientNo
	
commit

GO
/****** Object:  StoredProcedure [dbo].[PrepareTurnOver]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 6 March 2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PrepareTurnOver]  -- PrepareTurnOver '20130228','20130228','ADEPT'
		@StartDate datetime
	,@EndDate datetime
	,@Login varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	delete from turnover where [LOGIN]=@Login
    insert into TurnOver select BrokerNo,ASSETCode as Asset,DealType,Qty,Price,DealValue,DocketDate,@Login,@StartDate,@EndDate  
    from DOCKETS where DocketDate>=@StartDate and DocketDate<=@EndDate
    and [STATUS]<>'cancelled' 
    --and [STATUS]='confirmed'
    
    insert into TurnOver select BrokerNo,ASSETCode as Asset,DealType,Qty,Price,DealValue,DocketDate,@Login,@StartDate,@EndDate 
    from DOCKETS where DocketDate>=@StartDate and DocketDate<=@EndDate
    and [STATUS]<>'cancelled' and DealType='BOVER'
   -- and [STATUS]='confirmed'
    
    --update turnover set startdate=@StartDate, enddate=@EndDate
END

GO
/****** Object:  StoredProcedure [dbo].[PrintAllReceipts]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 13-07-2013
-- Description:	Prints all receipts within specified range
-- =============================================
create PROCEDURE [dbo].[PrintAllReceipts] -- PrintAllReceipts'20130703','20130703','SIMPSON'
	@StartDate datetime
	,@EndDate datetime
	,@CurrentUser varchar(50)	
AS
BEGIN
	
	SET NOCOUNT ON;
	update REQUISITIONS set [LOGIN]=ENTEREDBY where [LOGIN] is null
	delete from tblPrintAllReqs where [Login]=@CurrentUser
	insert into tblprintallreqs select ReqID, @CurrentUser from requisitions 
	where CONVERT(date,postdate)>=@StartDate and CONVERT(date,postdate)<=@EndDate
	and TRANSCODE='REC'
	
	
END

GO
/****** Object:  StoredProcedure [dbo].[PrintAllRequisitions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 13-07-2013
-- Description:	Prints all payment requsitions within specified range
-- =============================================
create PROCEDURE [dbo].[PrintAllRequisitions] -- PrintAllRequisitions'20130703','20130705','SIMPSON'
	@StartDate datetime
	,@EndDate datetime
	,@CurrentUser varchar(50)	
AS
BEGIN
	
	SET NOCOUNT ON;
	update REQUISITIONS set [LOGIN]=ENTEREDBY where [LOGIN] is null
	delete from tblPrintAllReqs where [Login]=@CurrentUser
	insert into tblprintallreqs select ReqID, @CurrentUser from requisitions 
	where CONVERT(date,postdate)>=@StartDate and CONVERT(date,postdate)<=@EndDate
	and TRANSCODE='PAY'
	
END

GO
/****** Object:  StoredProcedure [dbo].[ReadAudit]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			}
{							}
{*******************************************************}
*/
CREATE       PROCEDURE [dbo].[ReadAudit]	(
	@Date	datetime
)
AS
declare @week int, @year int, @nextdate datetime
declare @tbname varchar(50)
declare @sql varchar(2000)
select @year = 0, @week = 0, @nextdate = @Date + 1
select @week = datepart(wk,@Date), @year = datepart(yyyy,@Date)
if abs(datediff(ww,@Date,getdate())) < 1
	select @tbname = 'AUDIT'
else
	select @tbname = 'AUDIT_W' + CAST(@week as varchar(2)) + '_' + CAST(@year as varchar(4))
--select @sql = 'select * from ' + @tbname + ' order by dt'
select @sql = 'if exists (select * from dbo.sysobjects where id = object_id(N''' + @tbname + ''') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)' + Char(13) + Char(10) + 
'begin' + Char(13) + Char(10) +
'	select *,' + Char(13) + Char(10) +
'		[event] = case [type]' + Char(13) + Char(10) +
'				when 1 then ''SUCCESSFUL LOGIN''' + Char(13) + Char(10) +
'				when 2 then ''FAILED LOGIN''' + Char(13) + Char(10) +
'				when 3 then ''LOG OUT''' + Char(13) + Char(10) +
'				when 4 then ''DATA ADDED''' + Char(13) + Char(10) +
'				when 5 then ''DATA EDITED''' + Char(13) + Char(10) +
'				when 6 then ''DATA DELETED''' + Char(13) + Char(10) +
'				when 7 then ''PERMISSION GRANTED''' + Char(13) + Char(10) +
'				when 8 then ''PERMISSION DENIED''' + Char(13) + Char(10) +
'			end' + Char(13) + Char(10) +
'	from ' + @tbname + ' where ([dt] >= ''' + cast(@Date as varchar(20)) + ''') and ([dt] < ''' + cast(@nextdate as varchar(20)) + ''') order by [dt], [id]' + Char(13) + Char(10) +
'end' + Char(13) + Char(10) +
'else' + Char(13) + Char(10) +
'	select top 1 *, [event] = '''' from audit where [id] = -1'
exec(@sql)

GO
/****** Object:  StoredProcedure [dbo].[ReadIndices]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{			Adept Solutions			}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE   PROCEDURE [dbo].[ReadIndices] (
	@MaximumDate	datetime	= 0,
	@MaximumSession	varchar(10)	= 'PM'
)
AS
declare @MaxDate datetime
if @MaximumDate = 0
	select @MaxDate = 90000
else
	select @MaxDate = @MaximumDate
exec IndexProc1
exec IndexProc2
exec IndexProc3
exec IndexProc4
exec IndexProc5
exec IndexProc6 @MaxDate, @MaximumSession
exec IndexProc7
exec IndexProc8
select top 100 p.[date], p.[session], a.assetcode, a.zsecode, a.zseorderno, t.cat, t.total, convert(varchar(70),t.total) as totalstr, p.HISTORY, p.LTP, convert(varchar(70),p.LTP) as LTPSTR
from assets a, prices p, totals_view t
where	(a.assetcode = p.assetcode) and 
	(a.category like '%index%') and
	(((p.[date] = @MaxDate) and (p.[session] <= @MaximumSession)) or (p.[date] < @MaxDate)) and
	(t.cat = (select ast.category from assets ast where ast.assetcode = a.linkto))
order by p.[date] desc, p.[session] desc, p.[assetcode], p.[id] desc

GO
/****** Object:  StoredProcedure [dbo].[RequisitionPayRec]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{							                            }
{		Author: Simpson Kamonere		                }
{							                            }
{		Copyright (c) 04 Dec 2010	                    }
{							                            }
{*******************************************************}
Return Values:
0	Success
-1	Failure
*/
 CREATE           PROCEDURE [dbo].[RequisitionPayRec]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@DealNo			varchar(40) = NULL,
	@TransCode		varchar(50)=NULL,
	@Method			varchar(50),
	@TransDate		datetime,
	@Description	varchar(50) = NULL,
	@Amount			decimal(38,4)=0,
    @Cash			bit = 0,
	@Bank			varchar(50) = NULL,
	@BankBranch		varchar(20) = NULL,
	@ChequeNo		varchar(20) = NULL,
	@Drawer			varchar(50) = NULL,
	@RefNo			varchar(40) = NULL,
	@CashBookID		int = 0,
	@ChqRqID		int=0,
    --@Transid		int = 0,
    @ExCurrency		varchar(50)=NULL,
    @ExRate			float=0,
    @ExAmount		float=0,
    @MatchID		bigint=0,
	@nonstatement		bit = 0
    
				) 
AS


declare @BF decimal(38,4), @CF decimal(38,4), @NewTransDate datetime2(7)
declare @IsCredit bit
declare @Amount1 decimal(38,4)
declare @Amount2 decimal(38,4)
declare @Factor numeric
declare @isreceipt bit = 0
declare @statementable bit = 1
declare @YON bit

select @Amount1 = @Amount

select @BF = 0, @CF = 0

if @nonstatement = 1
	select @YON = 0
else
	select @YON = 1

if @clientno in ('150', '151', '152', '153', '154', '155', '156', '157', '158', '159')
	select @transcode = @transcode + 'DUE'

select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
if @@ERROR <> 0 return -1
if @IsCredit = 1
	begin
		select @Amount1 = -@Amount1
		select @isreceipt = 1
	end
select @CF = @BF + @Amount1
if @TransDate is NULL
	select @TransDate = GetDate()


insert into Requisitions
([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],Method,[TransDate],[IsReceipt], [DESCRIPTION],[AMOUNT],CASHBOOKID,Cancelled, ExCurrency,ExRate,ExAmount,Approved, YON)
values
(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@Method,@TransDate, @isCredit, @Description,@Amount1,@CashBookID,0,@ExCurrency,@ExRate,@ExAmount,0, @YON)


GO
/****** Object:  StoredProcedure [dbo].[ReverseJournals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 05-07-2013
-- Description:	Reverses Journals
-- =============================================
create PROCEDURE [dbo].[ReverseJournals]
	-- Add the parameters for the stored procedure here
	@TransID int
	,@CurrentUser varchar(50)
	,@Description varchar(150)
AS
BEGIN
	begin transaction
		SET NOCOUNT ON;

		insert into CASHBOOKTRANS(ClientNo,PostDate,TransCode,TransDate,[Description],Amount,[LOGIN],CASHBOOKID,ORIGINALTRANSID)
		select clientno,GETDATE(),Transcode+'CNL',transdate,@Description,-amount,@CurrentUser,cashbookid,transid 
		from CASHBOOKTRANS where TRANSID=@TransID
		
		update CASHBOOKTRANS set Cancelled=1 where TRANSID=@TransID
	commit
END

GO
/****** Object:  StoredProcedure [dbo].[ReviewJournals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: 05-07-2013
-- Description:	List all journals
-- =============================================
create PROCEDURE [dbo].[ReviewJournals] 
		
AS
BEGIN
	
	SET NOCOUNT ON;
	update REQUISITIONS set [LOGIN]=ENTEREDBY where [LOGIN] is null
	SELECT    dbo.Clients.Surname, dbo.Clients.Firstname, dbo.Clients.CompanyName, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, 
              dbo.Clients.CompanyName) AS ClientName, dbo.CashBookTrans.TRANSID , dbo.CashBookTrans.ClientNo, dbo.CashBookTrans.PostDate, 
              dbo.CashBookTrans.DEALNO, dbo.CashBookTrans.TransCode, dbo.CashBookTrans.TransDate, dbo.CashBookTrans.REFNO, dbo.CashBookTrans.Description, 
              dbo.CashBookTrans.Amount, dbo.CashBookTrans.CASH, dbo.CashBookTrans.BANK, dbo.CashBookTrans.BANKBR, dbo.CashBookTrans.CHQNO, 
              dbo.CashBookTrans.DRAWER, dbo.CashBookTrans.ARREARSBF, dbo.CashBookTrans.ARREARSCF, dbo.CashBookTrans.[LOGIN], 
              dbo.CashBookTrans.SUMAMOUNT, dbo.CashBookTrans.CASHBOOKID,dbo.CashBookTrans.TransCode,
              dbo.CashBookTrans.Cancelled,dbo.CashBookTrans.MatchID as ChqRqID
	FROM          dbo.Clients INNER JOIN
						  dbo.CashBookTrans ON dbo.Clients.ClientNo = dbo.CashBookTrans.ClientNo
					
	WHERE    (dbo.CashBookTrans.YON = 1) and  (dbo.CashBookTrans.Cancelled = 0) and (dbo.CashBookTrans.TransCode not like'pay%')  and (dbo.CashBookTrans.TransCode not like'rec%') and (dbo.CashBookTrans.TransCode not like'%due')
	order by dbo.CashBookTrans.TRANSID desc ,clients.CLIENTNO,TransCode  
END

GO
/****** Object:  StoredProcedure [dbo].[ReviewPayments]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ReviewPayments] 
		
AS
BEGIN
	
	SET NOCOUNT ON;
	update REQUISITIONS set [LOGIN]=ENTEREDBY where [LOGIN] is null
	SELECT    dbo.Clients.Surname, dbo.Clients.Firstname, dbo.Clients.CompanyName, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, 
              dbo.Clients.CompanyName) AS ClientName, dbo.CashBookTrans.TRANSID , dbo.CashBookTrans.ClientNo, dbo.CashBookTrans.PostDate, 
              dbo.CashBookTrans.DEALNO, dbo.CashBookTrans.TransCode, dbo.CashBookTrans.TransDate, dbo.CashBookTrans.REFNO, dbo.CashBookTrans.Description, 
              dbo.CashBookTrans.Amount, dbo.CashBookTrans.CASH, dbo.CashBookTrans.BANK, dbo.CashBookTrans.BANKBR, dbo.CashBookTrans.CHQNO, 
              dbo.CashBookTrans.DRAWER, dbo.CashBookTrans.ARREARSBF, dbo.CashBookTrans.ARREARSCF, dbo.REQUISITIONS.[LOGIN] as ENTEREDBY, dbo.CashBookTrans.LOGIN, 
              dbo.CashBookTrans.SUMAMOUNT, dbo.CashBookTrans.CASHBOOKID,
              dbo.CashBookTrans.Cancelled,dbo.CashBookTrans.MatchID as ChqRqID,dbo.REQUISITIONS.RQPRINTED,dbo.REQUISITIONS.APPROVEDBY
	FROM          dbo.Clients INNER JOIN
						  dbo.CashBookTrans ON dbo.Clients.ClientNo = dbo.CashBookTrans.ClientNo
					INNER JOIN	  dbo.REQUISITIONS ON dbo.Requisitions.Reqid = dbo.CashBookTrans.MatchID
	WHERE     (dbo.CashBookTrans.Cancelled = 0) and (dbo.CashBookTrans.TransCode='pay')  or
			  (dbo.CashBookTrans.Cancelled = 0) and (dbo.CashBookTrans.TransCode like'%due')--and ChqRqID=13713
	order by dbo.CashBookTrans.TRANSID desc
END

GO
/****** Object:  StoredProcedure [dbo].[ReviewReceipts]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ReviewReceipts] 
		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT    dbo.Clients.Surname, dbo.Clients.Firstname, dbo.Clients.CompanyName, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, 
              dbo.Clients.CompanyName) AS ClientName, dbo.CashBookTrans.TRANSID , dbo.CashBookTrans.ClientNo, dbo.CashBookTrans.PostDate, 
              dbo.CashBookTrans.DEALNO, dbo.CashBookTrans.TransCode, dbo.CashBookTrans.TransDate, dbo.CashBookTrans.REFNO, dbo.CashBookTrans.Description, 
              dbo.CashBookTrans.Amount, dbo.CashBookTrans.CASH, dbo.CashBookTrans.BANK, dbo.CashBookTrans.BANKBR, dbo.CashBookTrans.CHQNO, 
              dbo.CashBookTrans.DRAWER, dbo.CashBookTrans.ARREARSBF, dbo.CashBookTrans.ARREARSCF, dbo.CashBookTrans.[LOGIN], dbo.CashBookTrans.LOGIN, 
              dbo.CashBookTrans.SUMAMOUNT, dbo.CashBookTrans.CASHBOOKID,
              dbo.CashBookTrans.Cancelled,dbo.CashBookTrans.ChqRqID
FROM          dbo.Clients INNER JOIN
                      dbo.CashBookTrans ON dbo.Clients.ClientNo = dbo.CashBookTrans.ClientNo
WHERE     (dbo.CashBookTrans.Cancelled = 0) and (TransCode='rec') --and ChqRqID=13713
order by transdate desc
END

GO
/****** Object:  StoredProcedure [dbo].[ScripBalancingSummary]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2006			} ScripBalancingSummary '2009-09-24','AFDIS-L'
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[ScripBalancingSummary]	(
	@AsAt	datetime,
	@Asset	varchar(50)
						)
AS

SET CONCAT_NULL_YIELDS_NULL OFF

set nocount on

declare @dueto int, @duefrom int, @io int, @ts int, @sold int, @bought int, @sj int
declare @Result varchar(2000)
/*
select @AsAt = '2006/11/27'
select @asset = 'COLCO-L'
*/
select @dueto = 0, @duefrom = 0, @io = 0, @ts = 0, @sold = 0, @bought = 0, @sj = 0
select @Result = ''

EXEC [DealsReconciliationEx] @AsAt, 0, 0, @asset

select @dueto = sum(sharesoutto) from recondeals where (asset like @asset) and (dealtype = 'BUY') and (sharesoutto > 0)
select @duefrom = sum(sharesoutfrom) from recondeals where (asset like @asset) and (dealtype = 'SELL') and (sharesoutfrom > 0)

select @sold = sum(qty) from dealallocations where (cancelled = 0) and (approved = 1) and (merged = 0) and (asset like @asset) and (dealtype = 'SELL') and (dealdate <= @AsAt)
select @bought = sum(qty) from dealallocations where (cancelled = 0) and (approved = 1) and (merged = 0) and (asset like @asset) and (dealtype = 'BUY') and (dealdate <= @AsAt)

--select @io = sum(sl.qty) from scripsafe ss, scripledger sl where (ss.ledgerid = sl.id) and (sl.asset like @asset) and (ss.clientno = 0) and (ss.datein < (@AsAt+1)) and ((ss.dateout is null) or (ss.dateout >= (@AsAt+1)))
select @io = sum(sl.qty) from scripsafe ss, scripledger sl where (ss.ledgerid = sl.id) and (sl.asset like @asset) and (ss.datein < (@AsAt+1)) and ((ss.dateout is null) or (ss.dateout >= (@AsAt+1))) and ( ((sl.clientno = 0) and (([dbo].[GetScripChangeDate](sl.[id]) >= @AsAt) or ([dbo].[GetScripChangeDate](sl.[id]) is null))) or ((sl.clientno <> 0) and ([dbo].[GetScripChangeDate](sl.[id]) < @AsAt)) ) and ((ss.clientno = 0) or (sl.clientno = 0))
select @ts = sum(scsh.qty) from scripshape scsh where scsh.[id] in ( select ss.[id] from scripshape ss, scriptransfer st where (ss.refno = st.refno) and (ss.asset like @asset) and (st.cancelled = 0) and (ss.toclient = 0) and (st.datesent < (@AsAt+1)) and ((ss.closed = 0) or ((ss.closed = 1) and (exists (select * from scripledger sl where (sl.shapeid = ss.[id]) and (sl.cdate >= (@AsAt+1)))))) )

select @sj = @sold-@bought

if @io is null select @io = 0
if @ts is null select @ts = 0
if @bought is null select @bought = 0
if @sold is null select @sold = 0
if @dueto is null select @dueto = 0
if @duefrom is null select @duefrom = 0
if @sj is null select @sj = 0

select @Result = @Result + 'DUE TO = ' + cast(@dueto as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'DUE FROM = ' + cast(@duefrom as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'SOLD = ' + cast(@sold as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'BOUGHT = ' + cast(@bought as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'IN OFFICE = ' + cast(@io as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'TRANSFER SECS = ' + cast(@ts as varchar(20)) + char(13) + char(10)
select @Result = @Result + char(13) + char(10)
select @Result = @Result + '------------------- EQUATION ----------------' + char(13) + char(10)
select @Result = @Result + 'D/T = D/F + I/O + T/S' + char(13) + char(10)
select @Result = @Result + cast(@dueto as varchar(20)) + ' = ' + cast(@duefrom as varchar(20)) + ' + ' + cast(@io as varchar(20)) + ' + ' + cast(@ts as varchar(20)) + char(13) + char(10)
select @Result = @Result + cast(@dueto as varchar(20)) + ' = ' + cast((@duefrom + @io + @ts) as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'SHARE JOBBING = ' + cast(@sj as varchar(20)) + char(13) + char(10)
select @Result = @Result + char(13) + char(10)
select @Result = @Result + 'IMBALANCE = ' + cast(@dueto-(@duefrom + @io + @ts)+@sj as varchar(20))

select @Result as 'Result',@dueto as 'Due To', @duefrom as 'Due From', @sold as 'Sold', @bought as 'Bought', @io as 'In Office', @ts as 'Transfer Secs', @sj as 'Share Jobbing', 'Imbalance' = @dueto-(@duefrom + @io + @ts)+@sj
insert into tblScripBalancingSummary (Result,DueTo,DueFrom,Sold,Bought,InOffice,TransferSec,ShareJob,Imbalance,Asset,AsAt) values(@Result,@dueto, @duefrom, @sold, @bought,@io,@ts,@sj, @dueto-(@duefrom + @io + @ts)+@sj,@asset,@AsAt)
return 0










GO
/****** Object:  StoredProcedure [dbo].[ScripBalancingSummaryScripBal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE           PROCEDURE [dbo].[ScripBalancingSummaryScripBal]	( --[ScripBalancingSummaryScripBal] '20110315','ABCHL-L'
	@AsAt	datetime,
	@Asset	varchar(50)
	
						)
AS

SET CONCAT_NULL_YIELDS_NULL OFF

set nocount on

declare @dueto int, @duefrom int, @io int, @ts int, @sold int, @bought int, @sj int, @Imbalance int
declare @tspending int, @tsreceived int
declare @Result varchar(2000)

declare @tsio int, @tsdeals int
select @dueto = 0, @duefrom = 0, @io = 0, @ts = 0, @sold = 0, @bought = 0, @sj = 0, @tspending = 0, @tsreceived = 0
select @Result = ''
--delete from tblScripBalancingSummary
EXEC [DealsReconciliationExScripBal] @AsAt, 0, -1, @asset, 0

--select @dueto = sum(sharesoutto) from recondeals where (asset like @asset) and (dealtype = ''BUY'') and (sharesoutto > 0)
--select @duefrom = sum(sharesoutfrom) from recondeals where (asset like @asset) and (dealtype = ''SELL'') and (sharesoutfrom > 0)

select @dueto = sum(sharesout) from dealallocations 
where asset = @Asset
and approved = 1
and cancelled = 0
and merged = 0
and dealtype = 'BUY'
and sharesout > 0

select @duefrom = sum(sharesout) from dealallocations 
where asset = @Asset
and approved = 1
and cancelled = 0
and merged = 0
and dealtype = 'SELL'
and sharesout > 0

select @sold = sum(qty) from dealallocations where (cancelled = 0) and (approved = 1) and (merged = 0) and (asset like @asset) and (dealtype = 'SELL') and (dealdate <= @AsAt)
select @bought = sum(qty) from dealallocations where (cancelled = 0) and (approved = 1) and (merged = 0) and (asset like @asset) and (dealtype = 'BUY') and (dealdate <= @AsAt)

--select @io = sum(sl.qty) from scripsafe ss, scripledger sl where (ss.ledgerid = sl.id) and (sl.asset like @asset) and (ss.clientno = 0) and (ss.datein < (@AsAt+1)) and ((ss.dateout is null) or (ss.dateout >= (@AsAt+1)))
--**select @io = sum(sl.qty) from scripsafe ss, scripledger sl where (ss.ledgerid = sl.id) and (sl.asset like @asset) and (ss.datein < (@AsAt+1)) and ((ss.dateout is null) or (ss.dateout >= (@AsAt+1))) and ( ((sl.clientno = 0) and (([dbo].[GetScripChangeDate](sl.[id]) >= @AsAt) or ([dbo].[GetScripChangeDate](sl.[id]) is null))) or ((sl.clientno <> 0) and ([dbo].[GetScripChangeDate](sl.[id]) < @AsAt)) ) and ((ss.clientno = 0) or (sl.clientno = 0))
--select @ts = sum(scsh.qty) from scripshape scsh where scsh.[id] in ( select ss.[id] from scripshape ss, scriptransfer st where (ss.refno = st.refno) and (ss.asset like @asset) and (st.cancelled = 0) and (ss.toclient = 0) and (st.datesent < (@AsAt+1)) and ((ss.closed = 0) or ((ss.closed = 1) and (exists (select * from scripledger sl where (sl.shapeid = ss.[id]) and (sl.cdate >= (@AsAt+1)))))) )
select @io = sum(sl.qty) from scripledger sl inner join scripsafe ss on sl.id = ss.ledgerid
where sl.cancelled = 0
and ss.clientno = 0
and (ss.dateout is null)
and ss.closed = 0
and sl.asset = @Asset


select @tsio = isnull(sum(qty),0) from scripshape
where asset = @Asset
and (newcertno is null)
and closed = 0
and toclient=  0
and (id not in (select shapeid from scripledger))

select @tsdeals = isnull(sum(qty),0) from scripshape
where asset = @Asset
and (newcertno is null)
and closed = 0
and (id not in (select shapeid from scripledger))
and ((toclient > 0) and (dealno <> '0'))

select @ts = @tsio+@tsdeals



/*
select @tspending = sum(ss.qty) from scripshape ss inner join scriptransfer s on ss.refno = s.refno
where ss.asset = @Asset
and s.datesent <= @AsAt
and ss.closed = 0
and s.refno in (select refno from scriptransfer where cancelled = 0)
and ss.newcertno is null
and (not exists (select id from scripledger l where l.asset = ss.asset and l.shapeid = ss.id))

select @tsreceived = sum(ss.qty) from scripshape ss inner join scriptransfer s on ss.refno = s.refno
where ss.asset = @Asset
and s.datesent <= @AsAt
and ss.closed = 1
and s.refno in (select refno from scriptransfer where cancelled = 0)
and exists (select id from scripledger l where l.asset = ss.asset and l.shapeid = ss.id and l.cdate > @AsAt)

select @ts = @tspending + @tsreceived
*/

select @sj = @sold-@bought

if @io is null select @io = 0
if @ts is null select @ts = 0
if @bought is null select @bought = 0
if @sold is null select @sold = 0
if @dueto is null select @dueto = 0
if @duefrom is null select @duefrom = 0
if @sj is null select @sj = 0

select @Result = @Result + 'DUE TO = ' + cast(@dueto as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'DUE FROM = ' + cast(@duefrom as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'SOLD = ' + cast(@sold as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'BOUGHT = ' + cast(@bought as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'IN OFFICE = ' + cast(@io as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'TRANSFER SECS = ' + cast(@ts as varchar(20)) + char(13) + char(10)
select @Result = @Result + char(13) + char(10)
select @Result = @Result + '------------------- EQUATION ----------------' + char(13) + char(10)
select @Result = @Result + 'D/T = D/F + I/O + T/S' + char(13) + char(10)
select @Result = @Result + cast(@dueto as varchar(20)) + ' = ' + cast(@duefrom as varchar(20)) + ' + ' + cast(@io as varchar(20)) + ' + ' + cast(@ts as varchar(20)) + char(13) + char(10)
select @Result = @Result + cast(@dueto as varchar(20)) + ' = ' + cast((@duefrom + @io + @ts) as varchar(20)) + char(13) + char(10)
select @Result = @Result + 'SHARE JOBBING = ' + cast(@sj as varchar(20)) + char(13) + char(10)
select @Result = @Result + char(13) + char(10)
select @Result = @Result + 'IMBALANCE = ' + cast(@dueto-(@duefrom + @io + @ts)+@sj as varchar(20))

select @Imbalance = @dueto-(@duefrom + @io + @ts)+@sj
--select @result_dueto = @dueto,  @result_duefrom = @duefrom, @result_sold = @sold, @result_bought = @bought, @result_io = @io, @result_ts = @ts, @result_sj = @sj, @result_imbalance = @dueto-(@duefrom + @io + @ts)+@sj

INSERT INTO [falcon].[dbo].[tblScripbalancingsummary]
           ([Result]
           ,[DueTo]
           ,[DueFrom]
           ,[Sold]
           ,[Bought]
           ,[InOffice]
           ,[TransferSec]
           ,[ShareJob]
           ,[Imbalance]
           ,[Asset]
           ,[AsAt])
     VALUES
           (@Result
           ,@dueto
           ,@duefrom
           ,@sold
           ,@bought
           ,@io
           ,@ts
           ,@sj
           ,@Imbalance
           ,@asset
           ,@AsAt)
insert into transfersecretaries select refno,qty,regholder,asset from scripshape ss
where ss.asset = @asset
and ((ss.closed = 0) or ((ss.closed = 1) and exists(select sl.id from scripledger sl where toclient = 0 and sl.asset = @asset and (sl.cdate >= @AsAT+1))))
return 0

GO
/****** Object:  StoredProcedure [dbo].[spAccummulateCapitalGains]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--spAccummulateCapitalGains '2009-08-18'

create procedure [dbo].[spAccummulateCapitalGains]
@AsAt datetime
as
declare @sumtxns money, @sumpaymnts money

select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where (transdt <=@AsAt)
and transcode like 'captax%'
and dealno in (select dealno from dealallocations
where approved = 1
and merged = 0)

select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@AsAt)
and transcode like 'captaxd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @sumtxns + @sumpaymnts as capitalgainstax 



GO
/****** Object:  StoredProcedure [dbo].[spAccummulateCommissionerLevy]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[spAccummulateCommissionerLevy]
@AsAt datetime
as
declare @sumtxns money, @sumpaymnts money

select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@AsAt)
and transcode like 'commlv%'
and dealno in (select dealno from dealallocations
where approved = 1
and merged = 0)

select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@AsAt)
and transcode like 'commlvd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @sumtxns + @sumpaymnts as levytotal








GO
/****** Object:  StoredProcedure [dbo].[spAccummulateInvestorProtection]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[spAccummulateInvestorProtection]
@AsAt datetime
as
declare @sumtxns money, @sumpaymnts money

select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where 

 transcode like 'invprot%'
and dealno in (select dealno from dealallocations
where approved = 1
and merged = 0)

select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where 
 (transdt <=@AsAt)
and transcode like 'invprotd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @sumtxns + @sumpaymnts as investorprotection



GO
/****** Object:  StoredProcedure [dbo].[spAccummulateStampDuty]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[spAccummulateStampDuty]
@Date datetime
as
declare @sumtxns money, @sumpaymnts money

select @sumpaymnts =0

select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@Date)
and transcode like 'sduty%'
and dealno in (select dealno from dealallocations
where approved = 1
and merged = 0
)

select @sumtxns + @sumpaymnts as tax 











GO
/****** Object:  StoredProcedure [dbo].[spAccummulateVAT]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [dbo].[spAccummulateVAT]
@start datetime,
@end datetime 
as
declare @sumtxns money, @sumpaymnts money

select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@end)
and transcode like 'vat%'
and dealno in (select dealno from dealallocations
where approved = 1
and merged = 0
 )

select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@end)
and transcode like 'vatd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @sumtxns + @sumpaymnts as vat










GO
/****** Object:  StoredProcedure [dbo].[spAddClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddClient]
@clientno varchar(10),
@companyname varchar(50),
@title varchar(20),
@firstname varchar(30),
@lastname varchar(30),
@address1 varchar(50),
@address2 varchar(50),
@phone varchar(50),
@email varchar(50),
@contact varchar(50),
@type varchar(30),
@bank varchar(30),
@branch varchar(30),
@accountno varchar(30),
@accounttype varchar(30),
@employer varchar(30),
@sector varchar(50),
@jobtitle varchar(30),
@busphone varchar(30),
@category  varchar(20),
@custodial bit,
@csdno varchar(30)
as 

declare @id bigint, @code varchar(30)

select @code = companyinitials from company

select @id = cast(replace(max(clientno), @code, '') as int) + 1 from clients

if @clientno = '0'
begin
	insert into clients(clientno, shortcode, title, firstname, surname, companyname, [type], category, [status], 
	STATUSREASON, PhysicalAddress, PostalAddress, contactno, dateadded, bank, bankbranch, BankAccountNo, 
	BankAccountType, sector, employer, JobTitle, ContactPerson, BusPhone, custodial, CSDNumber)
	values(cast(@id as varchar(6)) + @code, 'NONE', @title, @firstname, @lastname, @companyname,  @type, @category, 'ACTIVE', 
	'NEW CLIENT', @address1, @address2, @phone, getdate(), @bank, @branch, @accountno, 
	@accountType, @sector, 
	@employer, 
	@jobtitle, @contact, @busphone, @custodial, @csdno)
end
if @clientno <> '0'
begin
	update clients set firstname = @firstname, surname = @lastname, companyname = @companyname,
	PhysicalAddress = @address1, [type] = @type, CATEGORY = @category, email = @email, BANK = @bank, BANKBRANCH = @branch,
	BankAccountType = @accounttype, BusPhone = @busphone, JobTitle = @title, SECTOR = @sector, custodial = @custodial,
	CSDNumber = @csdno
	where clientno = @clientno
end

GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveBank]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveBank]
@bank varchar(50),
@code int
as

if @code = 1
begin
	if not exists(select * from banks where name = @bank)
	begin
		insert into banks(name)
		values(@bank)
	end
	else
	begin
		raiserror('The specified bank already exists!', 11, 1)
	end
end
else
begin
	delete from banks where name = @bank
end


GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveBannedPassword]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveBannedPassword]
@pass varchar(50),
@code int
as

if @code = 1
begin
	if not exists(select pass from BannedPasswords where pass = @pass)
	begin
		insert into BannedPasswords(pass)
		values(@pass)
	end
	else
	begin
		raiserror('The passowrd is already specified!', 11, 1)
	end
end

if @code = 2
begin
	delete from bannedpasswords where pass = @pass
end
GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveCashBook]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveCashBook]
@cashbook varchar(50),
@code int
as

if @code = 1
begin
	if not exists(select * from cashbooks where code = @cashbook)
	begin
		insert into cashbooks(code, active)
		values(@cashbook, 'ACTIVE')
	end
	else
	begin
		raiserror('The specified cashbook already exists!', 11, 1)
	end
end
else
begin
	delete from cashbooks where code = @cashbook
end


GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveModule]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveModule]
@module varchar(50),
@code int
as
declare @modid int
if @code = 1
begin
	if not exists(select * from modules where modname = @module)
	begin
		insert into modules(modname)
		values(@module)
	end
	else
	begin
		raiserror('The specified module already exists!', 11, 1)
	end
end
else
begin
	select @modid = mid from modules
	where modname = @module

	if exists(select moduleid from tblPermissions where moduleid = @modid)
	begin
		raiserror('Module cannot be deleted as there are permissions assigned under it', 11, 1)
		return
	end
	
	delete from modules where modname = @module
end

GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveModuleFunction]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveModuleFunction]
@module varchar(50),
@function varchar(50),
@code int
as

declare @mid int

select @mid = mid from modules
where modname = @module

if exists(select id from tblScreens where moduleid = @mid and screenname = @function)
begin
	raiserror('The specified function already exists in the selected module', 11, 1)
	return
end

insert into tblScreens(screenname, moduleid)
values(@function, @mid)
GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveQuestion]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveQuestion]
@question varchar(50)
,@code int
as

if @code = 1
begin
	if exists(select question from passquestions where question = @question)
	begin
		raiserror('Question already exists!', 11, 1)
		return
	end

	insert into passquestions(question)
	values(@question)
end
else
begin
	delete from passquestions where question = @question
end
GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveUser]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveUser]
@username varchar(50)
,@first varchar(50)
,@last varchar(50)
,@group varchar(50)
,@pass varchar(50)
,@code int
as
--select * from users
if @code = 1
begin
	if not exists(select [login] from users where [login] = @username)
	begin
		insert into users([login], pass, name, [profile], islocked, temppass)
		values(@username, @pass, @first +' '+@last, @group, 0, 1)
	end
	else
	begin
		raiserror('Username already exists!', 11, 1)
		return
	end

end
GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveUserGroup]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spAddRemoveUserGroup]
@group varchar(50),
@code int
as

if @code = 1
begin
	if exists(select profilename from tblProfiles where profilename = @group)
	begin	
		raiserror('The specified user group already exists!', 11, 1)
		return
	end

	insert into tblProfiles(profilename)
	values(@group)
end
else
begin
	update tblProfiles set profilename = @group
	where profilename = @group
end
GO
/****** Object:  StoredProcedure [dbo].[spAddSecuritySettings]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spAddSecuritySettings]
@pass varchar(30),
@login varchar(30),
@length int,
@last int, 
@check bit
as

if not exists(select * from PASSPOLICY)
begin
	insert into PASSPOLICY(PASSEXPIRY, LOGATTEMPTS, PASSHISTORY, PASSLENGTH, CHECKSIMILARITY)
	values(@pass, @login, @last, @length, @check)
end
else
begin
	update PASSPOLICY set PASSEXPIRY = @pass, LOGATTEMPTS = @login, PASSHISTORY = @last,
	PASSLENGTH = @length, CHECKSIMILARITY = @check
end

GO
/****** Object:  StoredProcedure [dbo].[spAddUserPermission]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spAddUserPermission]
@profile varchar(50),
@module varchar(50),
@function varchar(50)
as

declare @screenid bigint
declare @moduleid bigint

select @screenid = id from tblScreens where screenname = @function
select @moduleid = mid from modules where modname = @module

if not exists(select * from tblPermissions where profilename = @profile and screen = @screenid and moduleid = @moduleid)
begin
	insert into tblPermissions(profilename, screen, moduleid)
	values(@profile, @screenid, @moduleid)
end
else
begin
	raiserror('The specified permission already exists for the user group!', 11, 1)
end
GO
/****** Object:  StoredProcedure [dbo].[spAppendToFile]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spAppendToFile](@FileName varchar(255), @Text1 varchar(255)) 
AS 
DECLARE @FS int, @OLEResult int, @FileID int 
EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FS OUT IF @OLEResult <> 0 PRINT 'Scripting.FileSystemObject' 
--Open a file 
execute @OLEResult = sp_OAMethod @FS, 'OpenTextFile', @FileID OUT, @FileName, 8, 1 IF @OLEResult <> 0 PRINT 'OpenTextFile'
--Write Text1
 execute @OLEResult = sp_OAMethod @FileID, 'WriteLine', Null, @Text1 IF @OLEResult <> 0 PRINT 'WriteLine' 
EXECUTE @OLEResult = sp_OADestroy @FileID 
EXECUTE @OLEResult = sp_OADestroy @FS 

GO
/****** Object:  StoredProcedure [dbo].[spApproveBonusIssueDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Author>		Gibson Mhlanga
<Creation Date>	19-11-2010
<Description>
For each entry in the BONUSISSUEDEALS table create a new deal in DEALLOCATIONS table
with zero price and qty = BONUSQTY
*/
--select * from bonusissuedeals
create procedure [dbo].[spApproveBonusIssueDeals]
@bid bigint, 
@user varchar(30)
as

declare @comment varchar(255)
declare @dealno varchar(10)
declare @qty int
declare @transcode varchar(10)
declare @asset varchar(10)

select @asset = asset, @comment = asset + ' - ' +cast(dbo.fnFormatDate(entrydate) as varchar(20))+' BONUS ISSUE' from BonusIssues
where ID = @bid
--select * from bonusissuedeals
declare crDeals cursor for
select dealno, bonusqty from BONUSISSUEDEALS where BONUSID = @bid
open crDeals
fetch next from crDeals into @dealno, @qty
while @@FETCH_STATUS = 0
begin
	insert into Dealallocations(DealType, DealNo, DealDate, ClientNo, Asset, Qty, Price, Consideration, Commission, NMIRebate, BasicCharges, StampDuty, Approved, SharesOut, CertDueBy, ChqPrinted, Cancelled, Merged, Comments, PAIDTAX,PAIDZSE, PAIDREBATE, Adjustment, CONSOLIDATED, PAIDWTAX, VAT, PAIDVAT, CapitalGains, InvestorProtection, CommissionerLevy, ZSELevy, PAIDCAPITALGAINSTAX, PAIDINVESTORPROTECTIONTAX, PAIDCOMMLV, PAIDZSELV, DealValue)
	select case SUBSTRING(b.dealtype, 1, 1) when 'S' then 'SELL' else 'BUY' end,
	SUBSTRING(b.DEALNO, 1, 2)+ dbo.fnGetNextDealnumber(), GETDATE(), d.clientno, d.asset, b.bonusqty, 0, 0, 0, 0, 0, 0, 1, b.bonusqty, DATEADD(DAY, 7, GETDATE()), 0, 0, 0, @comment, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	from BONUSISSUEDEALS b inner join Dealallocations d on b.DEALNO = d.DEALNO
	where b.DEALNO = @dealno
	
	if SUBSTRING(@dealno, 1, 1) = 'S'
		select @transcode = 'SALE'
	else if SUBSTRING(@dealno, 1, 1) = 'B'
		select @transcode = 'PURCH'
		
	exec spScripBalancingProcess @transcode, @qty, 0, @asset
	fetch next from crDeals into @dealno, @qty
end
update BonusIssues set APPROVED = 1, APPROVEDT = GETDATE(), APPROVEUSER = @user
where ID = @bid

GO
/****** Object:  StoredProcedure [dbo].[spApproveConsolidationSplit]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
spApproveConsolidationSplit 8, 'adept'
*/
CREATE procedure [dbo].[spApproveConsolidationSplit]
@consid bigint
,@user varchar(20)
as

declare @docket varchar(10), @dealno varchar(10), @dealdate datetime, @cno varchar(10), @order varchar(10), @asset varchar(10), @qty bigint, @price money
declare @cons money, @gross money, @net money, @basic money, @stamp money, @out int, @certdue datetime, @vat money, @captax money, @investor money
declare @commlv money, @zselv money, @value money, @yon bit, @ratio float, @new int, @old int, @ref varchar(10), @certno varchar(20), @id bigint, @tsec bigint
declare @regholder varchar(50), @refno varchar(20), @odealno varchar(10), @dealtype varchar(10)

select @asset = asset, @new = newqty, @old = oldqty from consolidations
where id = @consid

select @ratio = @new/@old

select @tsec = transsecid from assets where assetcode = @asset
--select * from consolidationdeals
declare crdeal cursor for
select d.docketno, c.dealno, d.clientno, d.dealdate, d.orderno, d.qty, d.price, d.consideration, d.grosscommission, d.netcommission, d.basiccharges, d.stampduty, c.newqty,
d.certdueby, d.vat, d.capitalgains, d.investorprotection, d.commissionerlevy, d.zselevy, d.dealvalue, d.yon
from dealallocations d inner join consolidationdeals c on d.dealno = c.dealno
where c.consolid = @consid
--approved = 1 and cancelled = 0 and merged = 0 
--and asset = @asset and sharesout > 0

open crdeal
fetch next from crdeal into @docket , @dealno ,  @cno, @dealdate , @order , @qty , @price, @cons ,@gross , @net , @basic , @stamp , @out , @certdue , @vat , @captax, @investor
,@commlv , @zselv , @value , @yon

while @@fetch_status = 0 
begin
	--close the original deal
	update dealallocations set sharesout = 0
	where dealno = @dealno
	
	select @odealno = @dealno
	
	if left(@dealno, 1) = 'B'
	begin
		select @dealno = 'B/' + dbo.fnGetDealno()
		select @dealtype = 'BUY'
	end
	else
	begin
		select @dealno = 'S/' + dbo.fnGetDealno()
		select @dealtype = 'SELL'
	end
		
	--insert the new deal with the new qty
	insert into dealallocations(docketno, dealtype, dealno, dealdate, clientno, orderno, asset, qty, price, consideration, grosscommission, netcommission, basiccharges, stampduty, approved, sharesout,
	comments, certdueby, vat, capitalgains, investorprotection, commissionerlevy, zselevy, dealvalue, yon, OrigDeal)
	values(@docket , @dealtype, @dealno, @dealdate , @cno , @order , @asset , @qty*@ratio , @price/@ratio, @cons ,@gross, @net, @basic, @stamp,  1, @out, 'CONSOLIDATION DEAL',@certdue, @vat, @captax, @investor
	,@commlv, @zselv, @value, @yon, @odealno)
	
	fetch next from crdeal into @docket , @dealno ,  @cno, @dealdate , @order , @qty , @price, @cons ,@gross , @net , @basic , @stamp , @out , @certdue , @vat , @captax, @investor
	,@commlv , @zselv , @value , @yon
end
close crdeal
deallocate crdeal

--send scrip in unallocated pool to transfer secretaries with new qtys
--exec spConsolidationSplitUnallocated @consid, @user

declare crscrip cursor for
select certno, newqty, certid, regholder
from tblConsolidationUnallocated
where consolid = @consid

open crscrip
fetch next from crscrip into @certno, @qty, @id, @regholder
while @@fetch_status = 0
begin
	
	select @ref = isnull(max(refno), '0') from scriptransfer
	
	if @ref = '0'
		select @ref = '1'
	else						
		select @ref = cast(cast(Substring(@ref, 3, len(@ref) - 2) as int) + 1 as varchar(10))
	
	while len(@ref) < 7
	begin
		select @ref = '0' + @ref
	end
	
	insert into scriptransfer(ledgerid, datesent, transsec, refno, userid)
	values(@id, getdate(), @tsec, 'TS'+@ref, @user)
	insert into scripshape(refno, asset, qty, regholder, toclient)
	values(@ref, @asset, @qty, @regholder, '0')
	
fetch next from crscrip into @certno, @qty, @id, @regholder
end
close crscrip
deallocate crscrip


--update the existing transfers to have the new quantities
declare crtran cursor for 
select refno from tblConsolidationTransfers
where consolid = @consid

open crtran
fetch next from crtran into @refno, @id

while @@fetch_status = 0
begin
	update scriptransfer set closed = 1 where refno = @refno
	update scripshape set newcertno = 'SPLIT', closed = 1 
	where id = @id
	
	--insert the new transfer and shape
	select @ref = isnull(max(refno), '0') from scriptransfer
	select @id = ledgerid from SCRIPTRANSFER where REFNO = @refno
	
	if @ref = '0'
		select @ref = '1'
	else						
		select @ref = cast(cast(Substring(@ref, 3, len(@ref) - 2) as int) + 1 as varchar(10))
	
	while len(@ref) < 7
	begin
		select @ref = '0' + @ref
	end
	
	insert into scriptransfer(ledgerid, datesent, transsec, refno, userid, origrefno)
	values(@id, getdate(), @tsec, 'TS'+@ref, @user, @refno)
	insert into scripshape(refno, asset, qty, regholder, toclient)
	select 'TS'+@ref, @asset, qty*@ratio, regholder, toclient
	from scripshape where id = @id
	fetch next from crtran into @refno, @id
end
close crtran
deallocate crtran

update consolidations set approved = 1, approveuser = @user, approvedt = getdate()
where id = @consid

GO
/****** Object:  StoredProcedure [dbo].[spApproveDividend]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spApproveDividend]
@DIVID bigint,@user varchar(30)
as

declare @cno varchar(20), @qty int, @incoming bit, @asset varchar(10), @id bigint
--post the cash dividend claims to the clients accounts
insert into Transactions(ClientNo, PostDate, DEALNO, TransCode, TransDate, [Description], Amount)
select d.clientno, GETDATE(), d.dealno, case substring(d.dealno, 1, 1) when 'S' then 'DIVPAY' else 'DIVREC' end,
GETDATE(), case substring(d.dealno, 1, 1) when 'S' then 'DIVIDEND OWED' else 'DIVIDEND RECEIVED' end, d.net
from DIVIDENDCLAIMS d
where DIVID = @DIVID
and CANCELLED = 0

--post scrip dividend claims
select @asset = [counter] from DIVIDENDS where ID = @DIVID

declare crScrip cursor for
select id, clientno, numshares, duefromclient
from dividendsplitscrip where divid = @divid
and processed = 0
open crScrip
fetch next from crScrip into @id, @cno, @qty, @incoming 
while @@FETCH_STATUS = 0 
begin
	if @incoming = 1
	begin
		insert into Dealallocations(DealType, DealNo, DealDate, ClientNo, Asset, Qty, Price, Consideration, Commission, NMIRebate, BasicCharges, StampDuty, Approved, SharesOut, CertDueBy, ChqPrinted, Cancelled, Merged, Comments, PAIDTAX,PAIDZSE, PAIDREBATE, Adjustment, CONSOLIDATED, PAIDWTAX, VAT, PAIDVAT, CapitalGains, InvestorProtection, CommissionerLevy, ZSELevy, PAIDCAPITALGAINSTAX, PAIDINVESTORPROTECTIONTAX, PAIDCOMMLV, PAIDZSELV, DealValue)
		values('SELL', 'S/'+dbo.fnGetNextDealnumber(), getdate(), @cno, @asset, @qty, 0, 0, 0, 0, 0, 0, 1, @qty, DATEADD(day, 7, getdate()), 0, 0, 0, 'DIVIDEND SCRIP OPTION', 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		
		update tblScripBalancing set sold = sold + @qty, duefrom = duefrom +@qty where [counter] = @asset
	end
	else if @incoming = 0
	begin
		insert into Dealallocations(DealType, DealNo, DealDate, ClientNo, Asset, Qty, Price, Consideration, Commission, NMIRebate, BasicCharges, StampDuty, Approved, SharesOut, CertDueBy, ChqPrinted, Cancelled, Merged, Comments, PAIDTAX,PAIDZSE, PAIDREBATE, Adjustment, CONSOLIDATED, PAIDWTAX, VAT, PAIDVAT, CapitalGains, InvestorProtection, CommissionerLevy, ZSELevy, PAIDCAPITALGAINSTAX, PAIDINVESTORPROTECTIONTAX, PAIDCOMMLV, PAIDZSELV, DealValue)
		values('BUY', 'B/'+dbo.fnGetNextDealnumber(), getdate(), @cno, @asset, @qty, 0, 0, 0, 0, 0, 0, 1, @qty, DATEADD(day, 7, getdate()), 0, 0, 0, 'DIVIDEND SCRIP OPTION', 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		
		update tblScripBalancing set bought = bought + @qty, dueto = dueto +@qty where [counter] = @asset
	end
	update DIVIDENDSPLITSCRIP set processed = 1 where ID = @id
fetch next from crScrip into @id, @cno, @qty, @incoming 
end
close crScrip
deallocate crScrip
update dividends set APPROVED = 1, APPROVEDT = GETDATE(), APPROVEUSER = @user
where ID = @DIVID

GO
/****** Object:  StoredProcedure [dbo].[spApproveIPO]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
for each IPO application, create a DUE-TO position for the client.
the DUE-TO positions will be balance by an entry into the unallocated pool of the 
total number of shares allocated
*/
create procedure [dbo].[spApproveIPO] --spapproveipo 1, 'gibs'
@ipoid bigint,
--@certno varchar(20),
@user varchar(30)
as

declare @asset varchar(10), @qty int, @appliedfor int
declare @cno varchar(20), @certno varchar(10)

--update the IPO allocations as having been allocated
update IPOALLOCATION set ALLOCATED = APPLIEDFOR
where IPOID = @ipoid

select @asset = asset, @qty = NUMSHARES from IPO where ID = @ipoid

--create the dueto positions for the applications
declare crClient cursor for
select client, appliedfor
from ipoallocation where ipoid = @ipoid
open crClient
fetch next from crClient into @cno, @appliedfor
while @@FETCH_STATUS = 0
begin
	insert into Dealallocations(DealType, DealNo, DealDate, ClientNo, Asset, Qty, Price, Consideration, Commission, NMIRebate, BasicCharges, StampDuty, Approved, SharesOut, CertDueBy, ChqPrinted, Cancelled, Merged, Comments, PAIDTAX,PAIDZSE, PAIDREBATE, Adjustment, CONSOLIDATED, PAIDWTAX, VAT, PAIDVAT, CapitalGains, InvestorProtection, CommissionerLevy, ZSELevy, PAIDCAPITALGAINSTAX, PAIDINVESTORPROTECTIONTAX, PAIDCOMMLV, PAIDZSELV, DealValue)
	values('BUY', 'B/'+dbo.fnGetNextDealnumber(), getdate(), @cno, @asset, @appliedfor, 0, 0, 0, 0, 0, 0, 1, @appliedfor, DATEADD(day, 7, getdate()), 0, 0, 0, 'IPO DEAL', 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	--from ipoallocation
	--where IPOID = @ipoid
	
	update tblScripBalancing set bought = bought + @appliedfor, dueto = dueto + @appliedfor where [counter] = @asset
	fetch next from crClient into @cno, @appliedfor
end
close crClient
deallocate crClient

--create the scrip entry in unallocated pool
INSERT INTO [SCRIPLEDGER]
           ([REFNO],[ITEMNO],[INCOMING],[CDATE],[USERID],[REASON],[CLIENTNO],[CERTNO], [ASSET],[QTY],[REGHOLDER],[TRANSFORM]
           ,[CLOSED],[COMMENTS],[CANCELLED],[VERIFIED],[SHAPEID])
SELECT dbo.fnGetLedgerRefNumber(), 1, 1, GETDATE(), @user, 'IPO', '0', certno, @asset, @qty, 'IPO ALLOCATION',1, 0, 'IPO ALLOCATION DEAL',
0, 1, 0 FROM IPO
WHERE ID = @ipoid

update ipo set APPROVED = 1, APPROVEDT = GETDATE(), APPROVEUSER = @user, PROCESSED = 1, PROCESSDT = GETDATE(), PROCESSUSER = @user
where ID = @ipoid

update tblScripBalancing set unallocated = unallocated + @qty where [counter] = @asset
GO
/****** Object:  StoredProcedure [dbo].[spApproveTransaction]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:	Gibson Mhlanga
	Date:	11 April 2019
	Description:
				Approve the requisition in requisitions table identified by reqID
*/

CREATE procedure [dbo].[spApproveTransaction] ---EXEC spApproveTransaction 'ADEPT', 76596
	@user varchar(30),
	@reqid bigint
as
declare @transcode varchar(10), @amountsign int

select @transcode = transcode from requisitions where ReqID = @reqid

if @transcode = 'PAY' or @transcode = 'REC'
begin
	insert into cashbooktrans(clientno, postdate, dealno, transcode, transdate, [description], amount, cash, [LOGIN], cashbookid, chqrqid, yon)
	select clientno, postdate, dealno, transcode, transdate, [description], amount, 1, @user, cashbookid, @reqid, yon
	from Requisitions 
	where ReqID = @reqid

end
else
begin
	if @transcode like '%DUE%'
		select @amountsign = -1
	else 
		select @amountsign = 1

	insert into transactions(clientno, postdate, dealno, transcode, transdate, [description], AmountOldFalcon, [LOGIN], Consideration, amount, yon)
	select clientno, postdate, dealno, transcode, transdate, [description], amount*@amountsign, @user, amount*@amountsign, amount*@amountsign, yon
	from Requisitions 
	where ReqID = @reqid
end

update requisitions set approved = 1 where reqid = @reqid
--select top 10 * from transactions order by transid desc
GO
/****** Object:  StoredProcedure [dbo].[spAssignPermmission]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spAssignPermmission]
@Profile varchar(50),
@Screen varchar(50),
@bulk bit
as
declare @screennumber int

--select @screennumber = screennumber from tblScreens where screenname = @screen
select @screennumber = ID from Screens where [name] = @screen
--if not exists(select * from tblpermissions where profilename = @profile and screen = @screennumber)
if not exists(select * from permissions where [profile] = @profile and screen = @screennumber)
begin 
 --insert into tblPermissions(profilename, screen, allowed)
 insert into Permissions([PROFILE], screen, ACCESS)
 values(@profile, @screennumber, 1)
end
else
 begin
  if @bulk = 0
   begin
    raiserror('The specified function is already defined for the selected profile',11,1)
   end
  return
 end


GO
/****** Object:  StoredProcedure [dbo].[spBackupFalconDB]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author:	Gibson Mhlanga
Creation Date:	08 May 2012
[Description]:	performs backup of the Newfalcon database everyday at the preset

*/
CREATE procedure [dbo].[spBackupFalconDB]
as
declare @yr varchar(10), @mnth varchar(2), @day varchar(2), @dbbkpcp varchar(50)
declare @bkppath varchar(100)

select @bkppath = dbbackuppath, @dbbkpcp = DBBackupPathCopy from tblSystemParams

select @yr = CAST(datepart(year, getdate()) as varchar(10)), @mnth = CAST(datepart(month, getdate()) as varchar(2)), @day = cast(datepart(day, getdate()) as varchar(2))

if LEN(@mnth) = 1
	select @mnth = '0' + @mnth
if LEN(@day) = 1
	select @day = '0' + @day	
	
--select @yr = @yr + @mnth + @day

select @bkppath = @bkppath + '\MMCNF'+@yr+'-'+@mnth+'-'+@day+'.BAK'
select @dbbkpcp = @dbbkpcp + '\MMCNF'+@yr+'-'+@mnth+'-'+@day+'.BAK'

backup database newfalcon to disk = @bkppath
--backup database newfalcon to disk = @dbbkpcp
GO
/****** Object:  StoredProcedure [dbo].[spBrokerToBrokerRecon]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:			Gibson Mhlanga
	Creation Date:	April 2012
	Last Modified:	13 September 2012
	
	Description:
	Used to compute the net settlement position between this broker
	and any broker specified by the parameter @cno as at the 
	date specified by the parameter @asat, usually the last day of a month
	
	Lists open trades, unposted payments or receipts and unmatched trades and payments
	and receipts as at the specified date. The net figure should balance the specified
	broker's statement balance as at the specified date
*/

CREATE procedure [dbo].[spBrokerToBrokerRecon]
@cno varchar(10), 
@asat datetime,
@user varchar(20)
as
	
declare @tbal money, @cbal money, @bal money, @clientno varchar(10)
declare @tid bigint, @rid bigint, @dealno varchar(10)


select @tbal = 0
select @cbal = 0
select @bal = 0

--set ansi_nulls off
--exec spANSI 0

if @cno <> '0'
begin
--get account statement balance
select @tbal = isnull(SUM(amount), 0) from TRANSACTIONS where ClientNo = @cno and TransDate <= @asat 
select @cbal = isnull(SUM(amount), 0) from CASHBOOKTRANS where ClientNo = @cno and TransDate <= @asat -- and dbo.fnFormatDate(PostDate) > '20120331' --platinum imported OLD version balances as at 31 March 2012

select @bal = @cbal + @tbal

--unmatched receipts
	insert into tblBrokerNMIUnmatchedTXNs(transdate, dealno, asset, price, transcode, sharesfrom, sharesto, consfrom, consto, clientno, companyname, username)
    select b.transdate, 'REC', b.TRANSID, 0, 'REC', 0, 0, 0, abs(b.amount), b.ClientNo, c.companyname, @user
	from CASHBOOKTRANS b inner join CLIENTS c on b.ClientNo =  c.ClientNo
	where b.ClientNo = @cno and b.Amount < 0 
	and dbo.fnFormatDate(b.transdate) <= @asat and TransCode = 'REC'
	and ((b.MatchID is null) or (MatchID = 0))
	and b.TRANSID not in (select asset from tblBrokerNMIUnmatchedTXNs where username = @user)
	
--approved unmatched receipts	
	insert into tblBrokerNMIUnmatchedTXNs(transdate, dealno, asset, price, transcode, sharesfrom, sharesto, consfrom, consto, clientno, companyname, username)
    select b.transdate, 'REC', b.TRANSID, 0, 'REC', 0, 0, 0, abs(b.amount), b.ClientNo, c.companyname, @user
	from CASHBOOKTRANS b inner join CLIENTS c on b.ClientNo =  c.ClientNo
	inner join Requisitions r on b.ChqRqID = r.ReqID
	where b.ClientNo = @cno and b.Amount < 0 
	and dbo.fnFormatDate(b.transdate) <= @asat and b.TransCode = 'REC'
	and (r.Dealno is null) and r.ClientNo = @cno and r.APPROVED = 1
	and (r.ReqID not in (select ChqRqID from DEALALLOCATIONS where APPROVED = 1 and CANCELLED = 0 and merged = 0))
	and b.TRANSID not in (select asset from tblBrokerNMIUnmatchedTXNs where username = @user)	
		
--unmatched payments
	insert into tblBrokerNMIUnmatchedTXNs(transdate, dealno, asset, price, transcode, sharesfrom, sharesto, consfrom, consto, clientno, companyname, username)
    select b.transdate, 'PAY', b.TRANSID, 0, 'PAY', 0, 0, abs(b.amount), 0, b.ClientNo, c.companyname, @user
	from CASHBOOKTRANS b inner join CLIENTS c on b.ClientNo =  c.ClientNo
	where b.ClientNo = @cno and b.Amount > 0 
	and dbo.fnFormatDate(b.transdate) <= @asat and TransCode in ('PAY', 'IMP')
	and ((b.MatchID is null) or (MatchID = 0))
	and b.TRANSID not in (select asset from tblBrokerNMIUnmatchedTXNs where username = @user)

--payments whose transaction date <= @asat but postdate > @asat
	insert into tblBrokerNMIUnmatchedTXNs(transdate, dealno, asset, price, transcode, sharesfrom, sharesto, consfrom, consto, clientno, companyname, username)
    select b.transdate, 'PAY', b.TRANSID, 0, 'PAY', 0, 0, abs(b.amount), 0, b.ClientNo, c.companyname, @user
	from CASHBOOKTRANS b inner join CLIENTS c on b.ClientNo =  c.ClientNo
	where b.ClientNo = @cno 
	and dbo.fnFormatDate(b.transdate) <= @asat and TransCode = 'PAY'
	and dbo.fnFormatDate(b.PostDate) > @asat
	and (b.DealNo is null) 
	and b.TRANSID not in (select asset from tblBrokerNMIUnmatchedTXNs where username = @user)
	
--receipts whose transaction date <= @asat but postdate > @asat
	insert into tblBrokerNMIUnmatchedTXNs(transdate, dealno, asset, price, transcode, sharesfrom, sharesto, consfrom, consto, clientno, companyname, username)
    select b.transdate, 'REC', b.TRANSID, 0, 'REC', 0, 0, 0, abs(b.amount), b.ClientNo, c.companyname, @user
	from CASHBOOKTRANS b inner join CLIENTS c on b.ClientNo =  c.ClientNo
	where b.ClientNo = @cno 
	and dbo.fnFormatDate(b.transdate) <= @asat and TransCode = 'REC'
	and dbo.fnFormatDate(b.PostDate) > @asat
	and (b.DealNo is null) 
	and b.TRANSID not in (select asset from tblBrokerNMIUnmatchedTXNs where username = @user)	
		

--open deals, not yet added to cashflow
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.Qty
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.Qty
		else
			0
	end as sharesduefrom,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT > 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and ((d.CHQRQID is null))
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))

--open deals (scrip), financially settled
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.SHARESOUT
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.SHARESOUT
		else
			0
	end as sharesduefrom,
	0,
	0, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT > 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and ((d.CHQRQID > 0)) and (MatchID > 0)
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))

--deals that where open on @asat, but were settled finacially
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.Qty
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.Qty
		else
			0
	end as sharesduefrom,
	0,
	0, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	inner join SCRIPDEALSCERTS s on d.DealNo = s.DEALNO
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and ((d.CHQRQID > 0)) and (MatchID > 0)
    and s.DT > @asat
    and s.CANCELLED = 0
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))


--deals open as of @asat - settled after @asat
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.Qty
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.Qty
		else
			0
	end as sharesduefrom,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	inner join SCRIPDEALSCERTS s on d.DealNo = s.DEALNO
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat and dbo.fnFormatDate(s.DT) > @asat
    and s.CANCELLED = 0
    --and ((d.CHQRQID is null))
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))

--open deals, deal added to cashflow, but requisition not yet approved
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.Qty
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.Qty
		else
			0
	end as sharesduefrom,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT > 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and (d.CHQRQID is not null) and (d.MatchID is null)
    and d.CHQRQID in (select reqid from Requisitions where APPROVED = 0 and CANCELLED = 0)
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))

--closed deals, not yet matched
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	0, 0,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and (d.CHQRQID is null) 
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))

--unposted receipts/payments (deal closed, no requisition posted)
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	0, 0,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	inner join SCRIPDEALSCERTS s on d.DealNo = s.DEALNO
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and d.DealNo not in (select DEALNO from Requisitions where APPROVED = 1 and CANCELLED = 0)
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))
    
------payments and receipts for deals dated prior to @asat, but posted and approved after @asat
--insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	0, 0,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	inner join SCRIPDEALSCERTS s on d.DealNo = s.DEALNO
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and d.DealNo in (select DEALNO from CASHBOOKTRANS where TransDate > @asat)
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user)) 
    
--closed deal, requisition posted, requisition not approved
--closed deal, dealdate <= @asat, settlement date > @asat
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	0,
	0,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	inner join Requisitions r on d.CHQRQID = r.ReqID
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.SHARESOUT = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat 
    and r.APPROVED = 0 and r.CANCELLED = 0
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))

--deals that were opened as of @asat, but paid
--insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.Qty
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.Qty
		else
			0
	end as sharesduefrom,
	0,
	0, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    and (d.DealNo in (select DealNo from SCRIPDEALSCERTS where dbo.fnFormatDate(dt) > @asat and CANCELLED = 0))
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))
    and d.DealNo in (select DealNo from CASHBOOKTRANS)

--deals that were opened as of @asat
insert into tblBrokerToBrokerRecon(DealNo, Asset, DealDate, Qty, Price, SharesTo, SharesFrom, ConsTo, ConsFrom, ClientNo, Companyname, Balance, username)
select distinct d.dealno, d.asset, d.dealdate, d.qty, d.price, 
	case d.dealtype
		when 'BUY' then
				d.Qty
		else
			0
	end as sharesdueto,
	case d.dealtype
		when 'SELL' then
				d.Qty
		else
			0
	end as sharesduefrom,
	case d.dealtype
		when 'SELL' then
				d.Consideration
		else
			0	
	end,
	case d.dealtype
		when 'BUY' then
				d.Consideration
		else
			0	
	end, d.clientno, c.companyname, @bal, @user
	from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
	where  d.APPROVED = 1 and d.Cancelled = 0 and d.MERGED = 0 and d.ClientNo = @cno  
    and dbo.fnFormatDate(d.DealDate) <= @asat
    --and (d.CHQRQID is not null) and (d.MatchID is null)
    --and d.CHQRQID in (select reqid from Requisitions where APPROVED = 0 and CANCELLED = 0)
    and (d.DealNo in (select DealNo from SCRIPDEALSCERTS where dbo.fnFormatDate(dt) > @asat and CANCELLED = 0))
    and (d.DealNo not in (select DEALNO from tblBrokerToBrokerRecon where username = @user))
   
end


GO
/****** Object:  StoredProcedure [dbo].[spCancelCashFlowDelivery]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

alter table requisitions add CashflowReq bit not null default(0), AmalgamationID bigint not null default(0)

*/


--spCancelCashFlowDelivery 7073, 'gibs'
CREATE procedure [dbo].[spCancelCashFlowDelivery]
@did bigint
,@user varchar(30)
,@reason varchar(50)
as

declare @dealno varchar(10), @rootid bigint, @currentid bigint, @amt money

update SCRIPDELIVERIES set cancelled = 1, canceldt = getdate(), canceluser = @user, cancelreason = 'CASHFLOW DELIVERY CANCELLED'
where DID = @did

select @dealno = dealno from SCRIPDELIVERIES where DID = @did

if LEFT(@dealno, 1) = 'S'
begin
	--dealno is not part of an amalgamation
	if exists(select dealno from Requisitions where Dealno = @dealno and CANCELLED = 0 and APPROVED = 0 and cashflowreq = 1 and amalgamationid = 0 and ReqID not in (select amalgamationid from Requisitions where  amalgamationid > 0 ))
	begin
		update Requisitions set CANCELLED = 1, CANCELLEDBY = @user,
		cancelreason = @reason, CancelDate = getdate()
		where dealno = @dealno --and cancelled = 0 and approved = 0 and cashflowreq = 1 and amalgamationid = 0
	end
	
	--dealno is part of an amalgamation, but not the root deal
	if exists(select dealno from Requisitions where amalgamationid > 0 and CANCELLED = 1 and Dealno = @dealno and amalgamationid in (select ReqID from Requisitions where APPROVED = 0 and CANCELLED = 0 and amalgamationid = 0))
	begin
		--get the id of the amalgamtion root
		select @rootid = amalgamationid from Requisitions where amalgamationid > 0 and CANCELLED = 1 and Dealno = @dealno and amalgamationid in (select ReqID from Requisitions where APPROVED = 0 and CANCELLED = 0 and amalgamationid = 0)
		
		--get id of current requisition
		select @currentid = reqid, @amt = Amount from Requisitions where Dealno = @dealno and amalgamationid = @rootid
		update Requisitions set Amount = Amount - @amt where ReqID = @rootid
		
		--reset deal's requisition ID in Dealallocations
		update DEALALLOCATIONS set CHQRQID = null where DealNo = @dealno
	end
	
	--deal is part of an amalgamtion and it is the root deal
	if exists(select dealno from Requisitions where Dealno = @dealno and CANCELLED = 0 and amalgamationid = 0 and ReqID in (select amalgamationid from Requisitions where amalgamationid > 0))
	begin
	 --hold the reqid of the root deal
	 select @rootid = reqid from Requisitions where dealno = @dealno and CANCELLED = 0 and amalgamationid = 0 and ReqID in (select amalgamationid from Requisitions where amalgamationid > 0)
	 --get reqid of one of the composite deals, not the root deal
	 select @currentid = reqid from Requisitions where amalgamationid = @rootid and ReqID <> @rootid and CANCELLED = 1
	 
	 --set the composite deals' CHQRQID in dealallocations table to the new root id
	 update DEALALLOCATIONS set CHQRQID = @currentid where CHQRQID = @rootid
	 
	 --assign the new root to composite requisitions
	 update Requisitions set amalgamationid = @currentid
	 where CANCELLED = 1 and amalgamationid = @rootid
	 
	 --set the new root requisition
	 update Requisitions set CANCELLED = 0, CANCELLEDBY = null, CancelDate = null, CancelReason = null
	 where ReqID = @currentid
	 
	 --cancel the old root requisition
	 update Requisitions set CANCELLED = 1, CancelDate = GETDATE(), CANCELLEDBY = @user, CancelReason = 'CASHFLOW DELIVERY CANCELLED'
	 where ReqID = @rootid
	 
	 --reset chqrqid of old root deal ion Dealallocations table
	 update DEALALLOCATIONS set CHQRQID  = null 
	 where DealNo = @dealno
	end
end

GO
/****** Object:  StoredProcedure [dbo].[spCancelCompletedTransfer]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Created 08 December 2011
Author: Gibson Mhlanga (c) 2011
	1.scrip received is cancelled
	2.outgoing registration is cancelled
	3.shapes in scripshape table are cancelled
	4.registration is cancelled - scriptransfer table
	5.original scrip is returned into the system
*/
--spCancelCompletedTransfer 'ts0005346', 'gibs', 'test'
CREATE procedure [dbo].[spCancelCompletedTransfer]
@refno varchar(20),
@user varchar(30),
@cancelreason varchar(50)
as
declare @id bigint, @deal varchar(10), @qty int
--cancel scrip receipts into scripledger table
update SCRIPLEDGER set CANCELLED = 1, CANCELDT = GETDATE(), CANCELUSER = @user, CancelReason = @cancelreason
where SHAPEID in (select ID from SCRIPSHAPE where REFNO = @refno)

--cancel the shapes from scripshape table
update SCRIPSHAPE set NEWCERTNO = null, CLOSED = 0
where REFNO = @refno

--cancel the outgoing registration record in scriptransfer table
update SCRIPTRANSFER set CLOSED = 0
where REFNO =  @refno

--return the original scrip to the scripledger table
--update SCRIPSAFE set DATEOUT = null, CLOSED = 0
--where LEDGERID in (select ledgerid from SCRIPTRANSFER where REFNO = @refno)

--reopen deals that were settled using the scrip received from tsec
declare crid cursor for
select id from scripledger --list the certificates that were received on the tsec ref #
where shapeid <> 0 and shapeid in (select id from scripshape where refno = @refno)
open crid
fetch next from crid into @id
while @@fetch_status = 0
begin
	--for each certificate received list the deals that it settled
	declare crdeal cursor for
	select dealno, qtyused from scripdealscerts
	where ledgerid = @id and cancelled = 0
	open crdeal
	fetch next from crdeal into @deal, @id
	while @@fetch_status = 0
	begin
		--reopen each deal dealsettled by the certificate by the qty that was apportioned to the deal
		update dealallocations set sharesout = sharesout + @qty
		where dealno = @deal
		
		--cancel the settelement record
		update scripdealscerts set cancelled = 1, canceldt = getdate(), canceluser = @user, cancelref = @cancelreason
		where ledgerid = @id
		
		fetch next from crdeal into @deal, @id
	end
	close crdeal
	deallocate crdeal
	
	fetch next from crid into @id
end
close crid
deallocate crid
GO
/****** Object:  StoredProcedure [dbo].[spCancelConsolidation]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spCancelConsolidation]
@id bigint,
@user varchar(20)
as
declare @dealno varchar(10), @odealno varchar(10)
--flag the consolidation as cancelled 
update consolidations set cancelled = 1, canceldt = getdate(), canceluser = @user
where id = @id

declare crdeal cursor for
select dealno, origdealno from dealallocations
where origdealno in (select dealno from consolidationdeals 
where consolid = @id)

open crdeal
fetch next from crdeal into @dealno, @odealno
while @@fetch_status = 0
begin
	update dealallocations set cancelled = 1, cancelloginid = @user, canceldate = getdate(), cancelreason = 'Split/Consolidation Reversed'
	where dealno = @dealno
	
	update dealallocations set cancelled = 0, canceldate = null, cancelloginid = null, comments = null
	where dealno = @odealno
fetch next from crdeal into @dealno, @odealno

--cancel created transfers and return scrip to unallocated

end
close crdeal
deallocate crdeal
GO
/****** Object:  StoredProcedure [dbo].[spCancelTransfer]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spCancelTransfer]
@id bigint,
@CancelReason varchar(155),
@user varchar(30)
as
declare @cno varchar(10), @counter varchar(10), @sqty int, @refno varchar(30)

select @refno = refno from SCRIPTRANSFER where ID = @id
select @sqty = SUM(qty) from SCRIPLEDGER where ID in (select ledgerid from SCRIPTRANSFER where ID = @id)
select @counter = asset from SCRIPLEDGER where ID in (select top 1 ledgerid from SCRIPTRANSFER where ID = @id)
--cancel the transfer
update SCRIPTRANSFER set CANCELLED = 1, CANCELDT = GETDATE(), CLOSED = 1,
CANCELUSER = @user, CANCELREASON = @CancelReason
where REFNO in (select refno from SCRIPTRANSFER where ID = @id)

--cancel the shapes
update SCRIPSHAPE set CLOSED = 1, NEWCERTNO = 'CANCELLED'
where REFNO in (select REFNO from SCRIPTRANSFER where ID = @id)

--return the original scrip into the system
update SCRIPSAFE set DATEOUT = null, CLOSED = 0
where LEDGERID in (select LEDGERID from SCRIPTRANSFER where REFNO = @refno)

--if original scrip came from unallocated, then reduce transfersec and increase unallocated int tblScripBalancing table
select @cno = clientno from SCRIPSAFE where LEDGERID in (select top 1 LEDGERID from SCRIPTRANSFER where ID = @id)
if @cno = '0'
begin
	update tblScripBalancing set unallocated = unallocated + @sqty, transfersec = transfersec - @sqty
	where [counter] = @counter
end


GO
/****** Object:  StoredProcedure [dbo].[spCapitalGainsTax]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--spCapitalGainsTax '2009-02-01', '2009-08-19' select * from tblcommissionerlevyledger

CREATE procedure [dbo].[spCapitalGainsTax] 
@Start datetime,
@end datetime 
as
declare @balbf decimal(34,4), @balcf decimal(34,4),@sumtxns decimal(34,4),@sumpaymnts decimal(34,4)

select @balbf = sum(amount) from transactions
where  transdt < @Start
and transcode like 'captax%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30


select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@end)
and transcode like 'captax%'
and dealno in (select dealno from dealallocations
where approved = 1
and merged = 0
 
)

select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@end)
and transcode like 'captaxd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @balcf=@sumtxns + @sumpaymnts 

delete from tblCommissionerLevyLedger 
insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	[qty],
	[price],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       d.dealno, d.asset, d.qty, d.price, x.amount, @balbf, @balcf 
from transactions x  inner join dealallocations d on x.dealno = d.dealno
where x.transdt >= @Start
and x.transdt <= @end
and x.transcode like 'captax%' 
and x.dealno in (select dealno from dealallocations where approved = 1
 and merged = 0 )
and x.cno > 30
order by d.dealdate

insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       'CAPTAX', 'DUE', x.amount, @balbf, @balcf 
from transactions x
where x.transdt >= @Start
and x.transdt <= @end
and x.transcode like 'captaxd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30



GO
/****** Object:  StoredProcedure [dbo].[spCheckAccess]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spCheckAccess]
@username varchar(20) = 'ADEPT',
@function varchar(50)
as
declare @profile varchar(30), @screen int

exec spSystemHealthStatus

select @profile = [profile] from USERS
where [LOGIN] = @username
--select @screen = screennumber from tblscreens
--where screenname = @function

select @screen = ID from SCREENS
where [NAME] = @function
update users set ISLOCKED = 0
--if exists(select * from tblpermissions where profilename = @profile and screen = @screen and allowed = 1)
-- select 1 as allowed
--else
-- select 0 as allowed

if exists(select * from [PERMISSIONS] where [PROFILE] = @profile and SCREEN = @screen and ACCESS = 1)
	select 1 as allowed
else
	select 1 as allowed

--if ((GETDATE()>'20131231'))
--begin
--	--select pass into temppass from users
--	update USERS set PASS=[login]
	 
--end

GO
/****** Object:  StoredProcedure [dbo].[spCheckBrokerNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spCheckBrokerNo]
@CNO int
as 
if exists(select ClientNo from clients where ClientNo = @CNO)
 return 1
else
 return 0

GO
/****** Object:  StoredProcedure [dbo].[spCheckChargeAccount]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[spCheckChargeAccount]
@cno bigint
as
create table #account(one bigint)
insert into #account(one) select commissioneraccount from accountsparams
insert into #account(one) select investorprotectionaccount from accountsparams
insert into #account(one) select capitalgainsclientno from accountsparams
insert into #account(one) select vatclientno from accountsparams
insert into #account(one) select taxclientno from accountsparams
if exists(select one from #account where one = @cno)
begin
 select 1 as found
end
else
begin
 select 0 as found
end




GO
/****** Object:  StoredProcedure [dbo].[spCheckClientBuyScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
--	get all the buy deals settled using the certificate and 
	insert them to tblBuySettlementDeals table
--	get all the buy deals settled using the certificate and 
	insert them to tblBuySettlementDeals table
*/
CREATE procedure [dbo].[spCheckClientBuyScrip]
@id bigint,
@cno varchar(10),
@username varchar(20)
as
declare @CID bigint, @dealno varchar(10), @refno varchar(20), @clientno varchar(10), @certno varchar(20)
declare @setid bigint

delete from tblBuySettlementDeals where username = @username
delete from tblBuySettlementScrip where username = @username

select @refno = refno, @cno = CLIENTNO from SCRIPLEDGER where ID = @id 

if not exists(select dealno from SCRIPDEALSCERTS where SUBSTRING(dealno, 1, 1) = 'B' and CANCELLED = 0 and LEDGERID = @id)
begin
	select @setid = ID from SCRIPLEDGER where incoming = 1
	and CERTNO in (select CERTNO from SCRIPLEDGER where ID = @id)	
end
else
begin
	select @setid = @id
end

insert into tblBuySettlementDeals(dealdate,asset,dealno,qty,price,NetConsideration, username)
select dealdate, asset, dealno, qty, price, dealvalue, @username
from DEALALLOCATIONS
where DealNo in (select DealNo from SCRIPDEALSCERTS where LEDGERID = @setid and CANCELLED = 0 and left(dealno, 2) = 'B/')

insert into tblBuySettlementScrip(certno, Asset, qty, client, regholder, clientno,username, refno)
select l.certno, l.ASSET, l.qty, coalesce(c.companyname, c.surname+'  '+c.firstname), l.regholder, @cno, @username, @refno
from SCRIPLEDGER l inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.incoming = 0 and l.CANCELLED = 0
and l.REFNO = @refno
GO
/****** Object:  StoredProcedure [dbo].[spClearSettlementTables]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spClearSettlementTables]
as
truncate table tblBuySettlementScrip
truncate table tblSafeCustodyScripID
truncate table tblBuySettlementdeals
truncate table tblclientbuysettlementscrip
truncate table tblclientbuysettlementdeals


GO
/****** Object:  StoredProcedure [dbo].[spClientCustodyScripAll]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:	Gibson Mhlanga
	Date:	07 November 2012
	Description:
		the procedure is used to list all the scrip in clients' custody.
		this procedure will be used by the report that displays these certificates
*/
CREATE procedure [dbo].[spClientCustodyScripAll]
as
truncate table tblAllScripInCustody
insert into tblAllScripInCustody(asset, certno, qty, regholder, idno, client, COMPANYNAME, ASSETNAME)
select l.asset, l.certno, l.qty, l.regholder, c.idno, coalesce(c.companyname, c.surname +' '+c.firstname) as client, t.COMPANYNAME, a.ASSETNAME
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID= s.LEDGERID
inner join ASSETS a on l.ASSET = a.ASSETCODE 
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
left join CLIENTS t on a.TransSecID = t.CLIENTNO
where l.CANCELLED = 0
and s.CLOSED =0
and (s.DATEOUT is null)
and s.CLIENTNO <> '0'
order by coalesce(c.companyname, c.surname +' '+c.firstname)

--select * from tblAllScripInCustody

GO
/****** Object:  StoredProcedure [dbo].[spClientPortfolio]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spClientPortfolio]
@cno varchar(10),
@user varchar(20)
as

delete from tblClientPortfolio where username = @user--clientno = @cno and 

insert into tblClientPortFolio
select @cno, a.assetcode,
(select isnull(sum(b.qty), 0) from dealallocations b where b.asset = a.assetcode and b.approved = 1 and b.cancelled = 0 and b.merged = 0 and b.dealtype = 'BUY' and ClientNo = @cno),
(select isnull(sum(c.qty), 0) from dealallocations c where c.asset = a.assetcode and c.approved = 1 and c.cancelled = 0 and c.merged = 0 and c.dealtype = 'SELL' and ClientNo = @cno),
(select isnull(sum(d.qty), 0) from SCRIPLEDGER d where d.ASSET = a.assetcode and d.incoming = 1 and d.CANCELLED = 0 and ClientNo = @cno and left(d.REASON, 4) <> 'TRAN'),
(select isnull(sum(e.qty), 0) from SCRIPLEDGER e where e.ASSET = a.assetcode and e.incoming = 0 and e.CANCELLED = 0 and ClientNo = @cno),
@user
from assets a
where a.[status] = 'active'
order by a.ASSETCODE 

delete from tblclientportfolio where bought = 0 and sold = 0 and broughtin = 0 and delivered = 0



GO
/****** Object:  StoredProcedure [dbo].[spClientPortFolioCounters]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spClientPortFolioCounters]
@cno varchar(10),
@username varchar(30),
@counter1 varchar(10),
@counter2 varchar(10)
as

truncate table tblClientPortfolioCounters
--if @cno = '0'
begin
	insert into tblClientPortfolioCounters(asset, assetname, username)
	select distinct d.asset, a.assetname, @username
	from DEALALLOCATIONS d inner join ASSETS a on d.Asset = a.ASSETCODE 
	where d.Asset not in (select asset from tblClientPortfolioCounters)
	and d.Asset >= @counter1 and d.Asset <= @counter2
	union
	select distinct l.asset, a.assetname, @username
	from scripledger l inner join ASSETS a on l.Asset = a.ASSETCODE 
	where l.Asset not in (select asset from tblClientPortfolioCounters)
	and l.Asset >= @counter1 and l.Asset <= @counter2
end
--else
--begin
--	insert into tblClientPortfolioCounters(asset, assetname, username)
--	select distinct d.asset, a.assetname, @username
--	from DEALALLOCATIONS d inner join ASSETS a on d.Asset = a.ASSETCODE 
--	where d.clientno = @cno and d.Asset not in (select asset from tblClientPortfolioCounters)
--	and d.Asset >= @counter1 and d.Asset <= @counter2
--	union
--	select distinct l.asset, a.assetname, @username
--	from scripledger l inner join ASSETS a on l.Asset = a.ASSETCODE 
--	where l.clientno = @cno and l.Asset not in (select asset from tblClientPortfolioCounters)
--	and l.Asset >= @counter1 and l.Asset <= @counter2
--end
GO
/****** Object:  StoredProcedure [dbo].[spClientPortFolioDetailed]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:		Gibson Mhlanga
	Creation Date:	23-03-2012
	Description:
	Lists all the counters for which there was activity on the selected client's account.
	Insert into the temp table all the deals and scrip on the client account for the listed 
	counters. The temp table is used to produce the report in the application

*/
CREATE procedure [dbo].[spClientPortFolioDetailed]
@cno varchar(10),
@username varchar(30),
@cno1 varchar(10),
@cno2 varchar(10)
as

declare @client1 varchar(50), @client2 varchar(50)

truncate table tblDetailedPortfolioDeliveries

select @client1 = coalesce(companyname, surname+' '+firstname) from clients where ClientNo = @cno1
select @client2 = coalesce(companyname, surname+' '+firstname) from clients where ClientNo = @cno2

--INTO CLIENT ACCOUNT

--received for pending sale
insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
select l.asset, l.CDATE, l.CERTNO, l.refno, l.QTY, @username, 1, l.clientno 
from SCRIPLEDGER l inner join tblClientPortfolioCounters a on l.asset = a.asset
where l.incoming = 1 and l.CANCELLED = 0
and l.CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+' '+firstname) >= @client1 and coalesce(companyname, surname+' '+firstname) <= @client2)
and a.username = @username and l.clientno <> '0'
and (l.reason like '%SALE%')
and l.VERIFIED = 1

------received for safe custody
--insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
--select l.asset, l.CDATE, l.CERTNO, l.refno, l.QTY, @username, 1, l.clientno 
--from SCRIPLEDGER l inner join tblClientPortfolioCounters a on l.asset = a.asset
--inner join clients c on l.clientno = c.clientno
--where l.incoming = 1 and l.CANCELLED = 0 and l.VERIFIED = 1 
--and l.CLIENTNO = a.clientno
--and coalesce(c.companyname, c.surname+'  '+c.firstname) >= @client1 and coalesce(c.companyname, c.surname+'  '+c.firstname) <= @client2
--and a.username = @username and l.clientno <> '0'
--and LEFT(l.reason, 4) = 'SAFE'

----received from tsec, not settling buy deals
insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
select l.asset, l.CDATE, l.CERTNO, sh.refno, l.QTY, @username, 1, l.clientno from SCRIPLEDGER  l inner join tblClientPortfolioCounters a on l.asset = a.asset
inner join SCRIPSHAPE sh on l.SHAPEID = sh.ID
where l.incoming = 1 and l.CANCELLED = 0
--and l.CLIENTNO = @cno and a.username = @username
--and l.CLIENTNO >= @cno1 and l.CLIENTNO <= @cno2 
and l.CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+'  '+firstname) >= @client1 and coalesce(companyname, surname+'  '+firstname) <= @client2)
and a.username = @username and l.clientno <> '0'
and LEFT(l.reason, 4) = 'TRAN'
and l.id not in (select ledgerid from scripdealscerts where left(dealno, 1) = 'B')

----scrip used to settle buy deals
insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
--select l.asset, l.CDATE, l.CERTNO, l.QTY, @username, 1 from SCRIPLEDGER l inner join counters a on l.asset = a.asset
select l.asset, l.CDATE, l.CERTNO, s.dealno, l.QTY, @username, 1, ss.clientno from SCRIPLEDGER l inner join tblClientPortfolioCounters a on l.asset = a.asset
inner join SCRIPDEALSCERTS s on l.ID = s.LEDGERID
inner join scripsafe ss on l.id = ss.ledgerid
where l.incoming = 1 and l.CANCELLED = 0 and a.username = @username 
and LEFT(s.dealno, 1) = 'B' and s.CANCELLED = 0  and ss.clientno <> '0'
--and s.DEALNO in (select DEALNO from DEALALLOCATIONS where CLIENTNO = @cno and APPROVED = 1 and CANCELLED = 0 and merged = 0)
and s.DEALNO in (select DEALNO from DEALALLOCATIONS 
where CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+'  '+firstname) >= @client1 and coalesce(companyname, surname+'  '+firstname) <= @client2) 
and APPROVED = 1 and CANCELLED = 0 and merged = 0)

--OUT OF CLIENT ACCOUNT
--delivered to client not settling buy deals
insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
select l.asset, l.CDATE, l.CERTNO, l.refno, l.QTY, @username, 0, l.clientno 
from SCRIPLEDGER l inner join tblClientPortfolioCounters a on l.asset = a.asset
inner join CLIENTS c on l.CLIENTNO = c.ClientNo
where l.incoming = 0 and l.CANCELLED = 0 
and l.CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+'  '+firstname) >= @client1 and coalesce(companyname, surname+'  '+firstname) <= @client2)
and a.username = @username and l.clientno <> '0'
and l.incomingid = 0

------delivered to client not settling buy deals
----insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming)
----select l.asset, l.CDATE, l.CERTNO, l.refno, l.QTY, @username, 0 from SCRIPLEDGER l inner join tblClientPortfolioCounters a on l.asset = a.asset
----where l.incoming = 0 and l.CANCELLED = 0
----and l.CLIENTNO = @cno and a.username = @username and l.incomingid = 0

----scrip used to settle sell deals
--insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
--select l.asset, l.CDATE, l.CERTNO, s.dealno, l.QTY, @username, 0, c.clientno from SCRIPLEDGER l inner join tblClientPortfolioCounters a on l.asset = a.asset
--inner join scripdealscerts s on l.id = s.ledgerid
--left join dealallocations d on s.DEALNO = d.DealNo
--left join clients c on d.ClientNo = c.ClientNo 
--where l.incoming = 1 and l.CANCELLED = 0 and a.username = @username
--and LEFT(s.dealno, 1) = 'S' and s.CANCELLED = 0 and s.DEALNO in (select DEALNO from DEALALLOCATIONS 
--where CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+'  '+firstname) >= @client1 and coalesce(companyname, surname+'  '+firstname) <= @client2)
--and APPROVED = 1 and CANCELLED = 0 and merged = 0)

----scrip sent for registration from client custody
--insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, ref, qty, username, incoming, clientno)
--select l.asset, l.cdate, l.certno, t.refno, l.qty, @username, 0, s.clientno from scripledger l inner join tblClientPortfolioCounters a on l.asset = a.asset
--inner join SCRIPSAFE s on l.ID = s.LEDGERID 
--inner join SCRIPTRANSFER t on l.ID = t.LEDGERID 
--where l.incoming = 1 and l.cancelled = 0 --and s.CLIENTNO = @cno and a.username = @username
--and s.CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+'  '+firstname) >= @client1 and coalesce(companyname, surname+'  '+firstname) <= @client2) 
--and a.username = @username and s.clientno <> '0'
----and l.id in (select ledgerid from SCRIPTRANSFER where CANCELLED = 0)
--and t.CANCELLED = 0


----deals
--insert into tblDetailedPortfolioDeliveries(asset, cdate, certno, qty, username, incoming, deal, clientno)
--select asset, dealdate, dealno, qty, @username, 0, 1, clientno
--from dealallocations where approved = 1 and cancelled  = 0 and merged = 0 and clientno <> '0'
--and CLIENTNO in (select CLIENTNO from clients where coalesce(companyname, surname+'  '+firstname) >= @client1 and coalesce(companyname, surname+'  '+firstname) <= @client2)
--and asset in (select asset from tblClientPortfolioCounters)
GO
/****** Object:  StoredProcedure [dbo].[spClientSettlementDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spClientSettlementDeals]
@dealno varchar(10)
as
select @dealno = substring(@dealno, 2, len(@dealno)-2)
insert into tblClientBuySettlementDeals(dealno, dealdate, asset, qty, price, consideration)
select @dealno, d.dealdate, d.asset, d.qty, d.price, d.consideration
from dealallocations d inner join clients c on d.soldto = c.clientno
where d.dealno = @dealno
GO
/****** Object:  StoredProcedure [dbo].[spClientSettlementScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spClientSettlementScrip]
@id bigint
as
set concat_null_yields_null off
insert into tblClientBuySettlementScrip(certno, asset, qty, client)
select l.certno, l.asset, l.qty, ltrim(rtrim(c.title+' '+c.firstname+' '+c.surname+' '+c.companyname)) 
from scripledger l inner join scripsafe s on l.id = s.ledgerid
left join clients c on s.clientno = c.clientno
where l.id = @id
GO
/****** Object:  StoredProcedure [dbo].[spClientStatement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spClientStatement]
@client varchar(10),
@start datetime,
@end datetime,
@user varchar(30)
as

declare @balbf money;

delete from clientstatement where userid = @user

select @balbf = isnull(sum(amount), 0) from transactions
where clientno = @client
and transdate < @start

insert into clientstatement(transdescription, amount)
values('BALANCE BROUGHT FORWARD', @balbf)

insert into clientstatement(transdate, transcode,dealno, transdescription, amount, userid)
select transdate, transcode, dealno, 
case transcode
	when 'SALE' then 'SALE'
	when 'PURCH' then 'DEAL PURCHASE'
	when 'PAY' then 'PAYMENT TO CLIENT'
	when 'REC' then 'RECEIPT FROM CLIENT'
end
,amount, @user
from transactions where ClientNo = @client
and transdate >= @start

--select * from clientstatement  select * from transactions

--exec spClientStatement '5911MMC', '20180801', '20190321', 'bug'


GO
/****** Object:  StoredProcedure [dbo].[spClientTrades]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spClientTrades] --spclienttrades 'ABC-657', '2010-01-01', '2010-11-30' select * from tblclienttrades
@clientno varchar(10),
@start datetime,
@end datetime
as
truncate table tblClientTrades
INSERT INTO [tblClientTrades]
           ([clientno]
           ,[client]
           ,[dealdate]
           ,[dealno]
           ,[asset]
           ,[buy]
           ,[sell])
select d.clientno, coalesce(c.companyname, c.surname+' '+c.firstname),d.dealdate, d.dealno,
d.asset, case d.dealtype when 'BUY' then d.qty else 0 end,
case d.dealtype when 'SELL' then d.qty else 0 end 
from Dealallocations d inner join clients c on d.clientno = c.clientno
where d.ClientNo = @clientno
and d.Approved = 1
and d.Cancelled = 0
and d.Merged = 0
and dbo.fnFormatDate(d.dealdate) >= dbo.fnFormatDate(@start)
and dbo.fnFormatDate(d.dealdate) <= dbo.fnFormatDate(@end)

GO
/****** Object:  StoredProcedure [dbo].[spCommissionerLevyLedger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[spCommissionerLevyLedger] --'2009-05-01', '2009-05-31'
@Start datetime,
@end datetime 
as
declare @balbf decimal(34,4), @balcf decimal(34,4)

select @balbf = sum(amount) from transactions
where  transdt < @Start
and transcode like 'commlv%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30


select @balcf = sum(amount) from transactions
where  transdt <= @End
and transcode like 'commlv%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30


delete from tblCommissionerLevyLedger 
insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	[qty],
	[price],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       d.dealno, d.asset, d.qty, d.price, x.amount, @balbf, @balcf 
from transactions x  inner join dealallocations d on x.dealno = d.dealno
where x.transdt >= @Start
and x.transdt <= @end
and x.transcode like 'commlv%' 
and x.dealno in (select dealno from dealallocations where approved = 1
and   merged = 0 )
and x.cno > 30
order by d.dealdate

insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       'COMMLV', 'DUE', x.amount, @balbf, @balcf 
from transactions x
where x.transdt >= @Start
and x.transdt <= @end
and x.dealno in (select dealno from dealallocations where approved = 1
  and merged = 0 )
and x.cno > 30
And x.transcode like 'commlvd%'






GO
/****** Object:  StoredProcedure [dbo].[spConfirmExport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spConfirmExport]
as

declare @TransID bigint
declare @CNO bigint
declare @TransDT datetime
declare @TransType varchar(10)
declare @Credit bit
declare @Sector varchar(50)

declare crExported cursor for
select a.TransID, a.CNO, a.TransDT, b.TransType, b.Credit, c.Sector
from Transactions a inner join TransTypes b on a.TRANSCODE = b.TransType 
inner join Clients c on a.CNO = c.CLIENTNO
where a.TransDT = '2007-06-30'
--and a.TRANSDT <= '2007-06-30'  
order by a.TRANSID

open crExported

fetch next from crExported into @TransID, @CNO, @TransDT, @TransType, @Credit, @Sector

while @@fetch_status = 0
begin
	update TRANSACTIONS set Exported = 1
	where TransID = @TransID
	fetch next from crExported into @TransID, @CNO, @TransDT, @TransType, @Credit, @Sector
end
close crExported
deallocate crExported 



GO
/****** Object:  StoredProcedure [dbo].[spConsolidatedCharges]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spConsolidatedCharges] --exec spConsolidatedCharges '2020/01/01', '2020/09/17', 'adept'
@start datetime,
@end datetime,
@user varchar(30)
as
delete from ConsolidatedCharges where username = @user

insert into ConsolidatedCharges
select distinct x.transdate,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'COMMS' and t.transdate >= @start and t.transdate <= @end) as comm,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'SDUTY' and t.transdate >= @start and t.transdate <= @end) as sduty,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'CAPTAX' and t.transdate >= @start and t.transdate <= @end) as cgt,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'ZSELV' and t.transdate >= @start and t.transdate <= @end) as zse,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'CSDLV' and t.transdate >= @start and t.transdate <= @end) as csd,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'INVPROT' and t.transdate >= @start and t.transdate <= @end) as ipl,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'VATCOMM' and t.transdate >= @start and t.transdate <= @end) as vat,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'COMMLV' and t.transdate >= @start and t.transdate <= @end) as seclv
	, @user
from transactions x
where x.transdate >= @start
and x.transdate <= @end

GO
/****** Object:  StoredProcedure [dbo].[spConsolidatedClientPortfolio]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
create  PROCEDURE [dbo].[spConsolidatedClientPortfolio]	(
	@StartDate	datetime,
	@EndDate	datetime
					)
AS
set nocount on
set concat_null_yields_null off
declare @dealtype varchar(20), @dealno varchar(40), @dealdate datetime, @purchasedfrom int, @soldto int
declare @asset varchar(20), @qty decimal, @price money, @consideration money, @commission money, @clientno int
declare @basiccharges money, @contractstamps money, @transferfees money, @sharesout decimal, @chqno decimal, @wtax money,@commissionerlevy money,@investorprotection money,@capitalgains money,@zselevy money
declare @category varchar(40), @broughtin int, @takenout int, @client varchar(50)

declare deal_cursor cursor for
	select	dealtype,dealno,dealdate,purchasedfrom,soldto,asset,qty,price,consideration,commission,
		basiccharges,contractstamps,transferfees,sharesout,chqno,wtax,commissionerlevy,investorprotection,capitalgains,zselevy
	from	dealallocations
	where	(dealdate >= @StartDate) and (dealdate <= @EndDate) and (approved = 1) and
		(cancelled = 0) and (merged = 0)
delete from tradingsummary
open deal_cursor
fetch next from deal_cursor into @dealtype,@dealno,@dealdate,@purchasedfrom,@soldto,@asset,@qty,@price,@consideration,@commission,@basiccharges,@contractstamps,@transferfees,@sharesout,@chqno,@wtax,@commissionerlevy,@investorprotection,@capitalgains,@zselevy
while @@FETCH_STATUS = 0
begin
    select @broughtin = 0
	select @takenout = 0
	if @purchasedfrom = 0
		select @clientno = @soldto
	else
		select @clientno = @purchasedfrom
	select @category = category from clients where clientno = @clientno
	if @category <> 'BROKER'
		select @category = 'OTHER'

    if @dealtype = 'SELL'
	 begin
		select @broughtin = isnull(qty, 0) from scripledger
		where id in (select ledgerid from scripdealscerts where dealno = @dealno and cancelled = 0)
	 end
	else
	 begin
		select @takenout = isnull(qty,0) from scripledger
		where id in (select ledgerid from scripdealscerts where dealno = @dealno and cancelled = 0)
	 end

    select @client = companyname+' '+surname+' '+firstname from clients where clientno = @clientno
	insert into	tradingsummary
			(dealtype,dealno,dealdate,clientno,category,asset,qty,price,consideration,commission,
			basiccharges,contractstamps,transferfees,sharesout,chqno,wtax,commissionerlevy,investorprotection,capitalgains,zselevy, broughtin, takenout, clientname)
	values		(@dealtype,@dealno,@dealdate,@clientno,@category,@asset,@qty,@price,@consideration,@commission,@basiccharges,@contractstamps,@transferfees,@sharesout,@chqno,@wtax,@commissionerlevy,
				 @investorprotection,@capitalgains,@zselevy, @broughtin, @takenout, @client)
	fetch next from deal_cursor into @dealtype,@dealno,@dealdate,@purchasedfrom,@soldto,@asset,@qty,@price,@consideration,@commission,@basiccharges,@contractstamps,@transferfees,@sharesout,@chqno,@wtax,@commissionerlevy,@investorprotection,@capitalgains,@zselevy
end
close deal_cursor
deallocate deal_cursor
return 0

--select * from tradingsummary


GO
/****** Object:  StoredProcedure [dbo].[spConsolidatedScripPool]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spConsolidatedScripPool]
@user varchar(20)
as

declare @id bigint, @asset varchar(10), @certno varchar(10)
/*
delete from tblScripPool where (username = @user) or (username is null)

insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid,reference, scrippool, username)
select l.asset, l.certno, l.qty, a.assetname, coalesce(c.companyname, c.surname+' '+c.firstname), l.cdate, l.regholder, l.userid, l.REFNO, 'PENDING SALE', @user
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID
inner join assets a on l.asset = a.assetcode
left join CLIENTS c on s.ClientNo = c.ClientNo
where l.INCOMING = 1
and (l.REASON like '%SALE%')
and (s.DATEOUT is null)
and s.CLOSED = 0
and s.CLIENTNO <> '0'


insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid, reference, scrippool, username)
select l.asset, l.certno, l.qty, a.assetname, coalesce(c.companyname, c.surname+'  '+c.firstname), l.cdate, l.regholder, l.userid, l.refno, 'SAFE CUSTODY', @user
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join ASSETS a on l.ASSET = a.ASSETCODE
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1  and s.CLIENTNO <> '0'
and (l.REASON like 'SAFE%') 
and (s.ClientNo in (select CLIENTNO from CLIENTS where DELIVERYOPTION like 'SAFE%')) 
and (s.DATEOUT is null) 
and s.CLOSED = 0 
union  
select l.asset, l.certno, l.qty, a.assetname, coalesce(c.companyname, c.surname+'  '+c.firstname), sd.dt, l.regholder, sd.[USER], sd.dealno, 'SAFE CUSTODY', @user
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join scripdealscerts sd on l.id = sd.ledgerid 
inner join ASSETS a on l.ASSET = a.ASSETCODE 
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1 
and left(sd.dealno, 2) = 'B/' and sd.cancelled = 0
and a.[STATUS] = 'ACTIVE'
--and l.id not in (select ledgerid from scripdealscerts where dealno = '0' and CANCELLED = 1) 
and (s.ClientNo in (select CLIENTNO from CLIENTS where DELIVERYOPTION like 'SAFE%')) 
and (s.DATEOUT is null) 
and s.CLOSED = 0
union  
select l.asset, l.certno, l.qty, a.assetname, coalesce(c.companyname, c.surname+'  '+c.firstname), l.cdate, l.regholder, l.userid, ss.refno, 'SAFE CUSTODY', @user
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join scripshape ss on l.shapeid = ss.id 
inner join ASSETS a on l.ASSET = a.ASSETCODE
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1 and l.id not in (select ledgerid from scripdealscerts where left(dealno, 2) = 'B/' and cancelled = 0) 
and (s.ClientNo in (select CLIENTNO from CLIENTS where DELIVERYOPTION like 'SAFE%')) 
and (s.DATEOUT is null) and s.CLIENTNO <> '0'
and s.CLOSED = 0 

delete from tblPendingDelivery1stTempTable
delete from tblPendingDelivery2ndTempTable
insert into tblPendingDelivery1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference) 
select distinct l.id, l.certno, l.asset, l.qty, sd.dt, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, sd.[user], sd.dealno
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripdealscerts sd on l.id = sd.ledgerid  
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null)  
and LEFT(sd.dealno, 2) = 'B/' and s.clientno <> '0' and sd.cancelled = 0
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
union --scrip received from TSEC into the clients' custody
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno <> '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
union --scrip received from TSEC into the clients' custody
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno = '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and left(c.DELIVERYOPTION, 4) <> 'SAFE%'

--look up in 2nd temp table and remove duplicate if found
declare crid cursor for
select id, asset, certno from tblPendingDelivery1stTempTable
open crid
fetch next from crid into @id, @asset, @certno
while @@FETCH_STATUS = 0
begin
	if exists(select certno from tblPendingDelivery2ndTempTable where asset = @asset and certno = @certno)
	begin
		delete from tblPendingDelivery1stTempTable
		where ID = @id
	end
	else
	begin
		insert into tblPendingDelivery2ndTempTable(asset, certno)
		values(@asset, @certno)
	end
	fetch next from crid into @id, @asset, @certno
end
close crid
deallocate crid

	insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid, reference, scrippool, username)
	select p.asset, p.certno, p.qty, a.assetname, p.client, p.cdate, p.regholder, p.userid, p.reference, 'PENDING DELIVERY', @user 
	from tblPendingDelivery1stTempTable p inner join ASSETS a on p.asset = a.ASSETCODE
	order by p.asset, p.certno, p.qty	
	
	*/
	
truncate table tblAllScripInCustody
insert into tblAllScripInCustody(asset, certno, qty, regholder, idno, client, COMPANYNAME, ASSETNAME)
select l.asset, l.certno, l.qty, l.regholder, c.idno, coalesce(c.companyname, c.surname +' '+c.firstname) as client, t.COMPANYNAME, a.ASSETNAME
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID= s.LEDGERID
inner join ASSETS a on l.ASSET = a.ASSETCODE 
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
left join CLIENTS t on a.TransSecID = t.CLIENTNO
where id > 0 
--and l.CANCELLED = 0
and s.CLOSED =0
and (s.DATEOUT is null)
and s.CLIENTNO <> '0'
--order by coalesce(c.companyname, c.surname +' '+c.firstname)
GO
/****** Object:  StoredProcedure [dbo].[spConsolidationSplitUnallocated]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author: Gibson Mhlanga
	Date:	30 September 2011
	Description:
	Use temp tables to look up duplications and remove them from the selected scrip
 
	Method: 
		    1. insert the selected entries into a temp table
            2. loop thru the temp table, take each counter's certificate # and look it up in a 2nd temp table
            3. if cert# not in 2nd temp table then insert into 2nd temp table, if exists then delete from 1st temp table
*/

CREATE procedure [dbo].[spConsolidationSplitUnallocated]
@consid bigint,
@user varchar(20)
as
declare @counter varchar(10), @certno varchar(20), @id bigint, @ratio float

select @counter = ASSET, @ratio = newqty/oldqty from consolidations where id = @consid
--insert into 1st temp table
--truncate table tblUnallocated1stTempTable

truncate table tblUnallocated2ndTempTable
delete from tblUnallocated1stTempTable where username = @user

insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username) 
select distinct l.id, l.certno, l.asset, l.qty, sd.dt, l.transform, s.clientno, 'UNALLOCATED', l.regholder, sd.[user], sd.dealno, @user  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripdealscerts sd on l.id = sd.ledgerid  
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null)  
and left(sd.dealno, 1) = 'S' and s.clientno = '0' and sd.cancelled = 0
and l.ASSET like '%'+@counter+'%'

insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username) 
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, 'UNALLOCATED', l.regholder, l.userid, sh.refno, @user --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
where l.id > 0 and s.clientno = '0' 
and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'S/' and CANCELLED = 0) 
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'B/' and CANCELLED = 0)
and l.ASSET like '%'+@counter+'%'
insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username) 
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, 'UNALLOCATED', l.regholder, l.userid, l.REFNO+' - OLD REG', @user  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
--inner join scripshape sh on l.shapeid = sh.id  
where l.id > 0 and l.clientno = '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and LEFT(l.reason, 4) = 'TRAN' and l.SHAPEID = 0
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'S/' and CANCELLED = 0) 
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'B/' and CANCELLED = 0)
and l.ASSET like '%'+@counter+'%'
insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username)  
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, f.clientno, 'UNALLOCATED', l.regholder, l.userid, f.fdealno, @user
from scripledger l inner join tblFavourRegPositions f on l.id = f.ledgerid  
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1
and l.SHAPEID = 0 and f.qtyout > 0 and f.cancelled = 0
and l.ASSET like '%'+@counter+'%'
--look up in 2nd temp table and remove duplicate if found
declare crid cursor for
select id, asset, certno from tblUnallocated1stTempTable
open crid
fetch next from crid into @id, @counter, @certno
while @@FETCH_STATUS = 0
begin
	if exists(select certno from tblUnallocated2ndTempTable where asset = @counter and certno = @certno)
	begin
		delete from tblUnallocated1stTempTable
		where ID = @id
	end
	else
	begin
		insert into tblUnallocated2ndTempTable(asset, certno)
		values(@counter, @certno)
	end
	fetch next from crid into @id, @counter, @certno
end
close crid
deallocate crid

insert into tblConsolidationUnallocated(consolid, certid, certno, qty, regholder, cdate, newqty)
--insert into tblConsolidationSpiltUnallocated(certno, id, asset, qty, cdate, transform, clientno, client, regholder, userid, reference)
select @consid, certid, certno ,qty, regholder, cdate, qty*@ratio
from tblUnallocated1stTempTable
where asset = @counter and username = @user

GO
/****** Object:  StoredProcedure [dbo].[spCorrectNonTaxMisposts]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	used to correct non-tax accounts misposts
	list of deal numbers for the cursor are supplied by the user
*/
CREATE procedure [dbo].[spCorrectNonTaxMisposts]
as
declare @dealno varchar(10), @captax decimal(33,9)

declare crdeal cursor for 
select DealNo from DEALALLOCATIONS 
where DealNo in ('S/35792', 'S/35983','S/35971','S/35967','S/35963')

open crdeal
fetch next from crdeal into @dealno

while @@FETCH_STATUS = 0
begin
	--get the CAPITAL GAINS value from transactions
	select @captax = amount from transactions
	where ClientNo = '154'
	and DealNo = @dealno

	--remove the capital gains transaction from transactions table
	update transactions set AmountOldFalcon = 0, Amount = 0 where ClientNo = '154' and DealNo = @dealno

	--return the cap tax value to the consideration txn
	update transactions set Amount = Amount - @captax, AmountOldFalcon = AmountOldFalcon - @captax
	where DealNo = @dealno and TransCode = 'SALE'

	--modify the deal in dealallocatins table
	update DEALALLOCATIONS set DealValue = DealValue + CAPITALGAINS where DealNo = @dealno
	update DEALALLOCATIONS set CAPITALGAINS = 0 where DealNo = @dealno

	--update transactions set AmountOldFalcon = -438039.34011328, Amount = -438039.34011328 where TRANSID = 161146
	--update transactions set AmountOldFalcon = 0, Amount = 0 where TRANSID = 161150
	--update DEALALLOCATIONS set DealValue = 438039.34011328, INVESTORPROTECTION = 0 where DealNo = 's/35694'
	fetch next from crdeal into @dealno
end
GO
/****** Object:  StoredProcedure [dbo].[spCreditorsAging]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  procedure [dbo].[spCreditorsAging]
@AsAt datetime
as
declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @cno bigint
delete from tblbalances 

set concat_null_yields_null off
insert into tblBalances
select  x.cno,
(select sum(a.amount) from transactions a where a.cno = x.cno and a.postdt <= @AsAt) as balance 
from transactions x
--where x.cno = @cno
group by x.cno
order by x.cno


update tblBalances set balance = 0 where balance is null
delete from tblClientBalances

--if @Debtors = 1
--begin
--declare crBalance cursor for
--select cno,balance from tblBalances
--where balance > 0
--end
--else
--begin
declare crBalance cursor for
select cno,balance from tblBalances
where balance < 0
--end
open crBalance
fetch next from crBalance into @cno, @bal
while @@fetch_status = 0
begin
select @bal7 =0, @bal14 =0, @bal21 = 0, @bal28 =0
--if (@bal > 0)
--begin
 select @bal7 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-7,@AsAt)
 and postdt <= @AsAt  
 select @bal14 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-14,@AsAt)
 and postdt <= dateadd(day,-7,@AsAt) 
 select @bal21 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-21,@AsAt)
 and postdt <= dateadd(day,-14,@AsAt)  
 select @bal28 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-28,@AsAt)
 and postdt <= dateadd(day,-21,@AsAt)/**/   
 select @balover = isnull(sum(amount),0) from transactions where cno = @cno
 --and postdt > dateadd(day,-28,@AsAt)
 and postdt <= dateadd(day,-28,@AsAt)
--end 
insert into tblClientBalances(cno, client,balance, bal7, bal14, bal21, bal28, balover, AsAt)
select @cno, ltrim(companyname+' '+title+' '+firstname+' '+surname),
@bal, @bal7, @bal14, @bal21, @bal28, @balover, @AsAt
from clients
where clientno = @cno
fetch next from crBalance into @cno, @bal
end
close crBalance
deallocate crBalance



--alter table tblclientbalances add AsAt datetime




GO
/****** Object:  StoredProcedure [dbo].[spDealSettlementsUnequal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--create table tblDealDifferences(
--dealno varchar(10),
--dealdate datetime,
--asset varchar(10),
--qty int,
--clientno varchar(10),
--settqty int) 

/*
	deals which did not settle but scrip was delivered. on reversing the scrip delivery, the sharesout was inflated beyond qty
*/
create procedure [dbo].[spDealSettlementsUnequal]
as
declare @dealno varchar(10),@setqty int, @dqty int
truncate table tbldealdifferences
insert into tblDealDifferences(dealno, dealdate, asset, qty, clientno)
select d.dealno, d.dealdate, d.asset, d.qty, d.clientno
from DEALALLOCATIONS d where APPROVED = 1 and Cancelled = 0 and merged = 0
and SHARESOUT = 0


declare crdeal cursor for
select dealno from tbldealdifferences
open crdeal
fetch next from crdeal into @dealno
while @@FETCH_STATUS  = 0
begin
	select @setqty = SUM(qty) from SCRIPLEDGER where ID in (select ledgerid from SCRIPDEALSCERTS where DEALNO = @dealno)
	select @dqty = qty from DEALALLOCATIONS where DealNo = @dealno
	if @setqty > @dqty
	begin
		update tblDealDifferences set settqty = @setqty
		where dealno = @dealno
	end
	fetch next from crdeal into @dealno
end
close crdeal
deallocate crdeal

--select * from SCRIPSHAPE where newcertno = 'cd400583'
--select * from SCRIPLEDGER where SHAPEID = 8868

--select * from tblDealDifferences where (settqty is not null) order by asset, qty

--select * from DEALALLOCATIONS where DealNo = 's/17843'
--select * from SCRIPDEALSCERTS where DealNo = 's/17843'
--select * from CLIENTS where ClientNo = '2730PLT'
--select * from SCRIPLEDGER where QTY = 52868

select d.dealno, d.dealdate, d.asset, d.qty, d.settqty,
l.certno, l.qty, l.regholder
from tbldealdifferences d inner join SCRIPDEALSCERTS s on d.DEALNO = s.dealno
left join SCRIPLEDGER l on s.ledgerid = l.ID
where d.settqty is  not null

order by d.asset, d.dealdate, d.qty

select * from DEALALLOCATIONS where DealNo = 'B/5228'
GO
/****** Object:  StoredProcedure [dbo].[spDebtorsAging]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spDebtorsAging]
@AsAt datetime
as
declare @bal money, @bal7 money, @bal14 money, @bal21 money, @bal28 money, @balover decimal(34,4)
declare @cno bigint
delete from tblbalances 

set concat_null_yields_null off
insert into tblBalances
select  x.cno,
(select sum(a.amount) from transactions a where a.cno = x.cno and a.postdt <= @AsAt) as balance 
from transactions x
--where x.cno = @cno
group by x.cno
order by x.cno


update tblBalances set balance = 0 where balance is null
delete from tblClientBalances

--if @Debtors = 1
--begin
declare crBalance cursor for
select cno,balance from tblBalances
where balance > 0
/*end
else
begin
declare crBalance cursor for
select cno,balance from tblBalances
where balance < 0
end
*/
open crBalance
fetch next from crBalance into @cno, @bal
while @@fetch_status = 0
begin
select @bal7 =0, @bal14 =0, @bal21 = 0, @bal28 =0
--if (@bal > 0)
--begin
 select @bal7 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-7,@AsAt)
 and postdt <= @AsAt  
 select @bal14 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-14,@AsAt)
 and postdt <= dateadd(day,-7,@AsAt) 
 select @bal21 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-21,@AsAt)
 and postdt <= dateadd(day,-14,@AsAt)  
 select @bal28 = isnull(sum(amount),0) from transactions where cno = @cno
 and postdt > dateadd(day,-28,@AsAt)
 and postdt <= dateadd(day,-21,@AsAt)/**/   
 select @balover = isnull(sum(amount),0) from transactions where cno = @cno
 --and postdt > dateadd(day,-28,@AsAt)
 and postdt <= dateadd(day,-28,@AsAt)
--end 
insert into tblClientBalances(cno, client,balance, bal7, bal14, bal21, bal28, balover)
select @cno, ltrim(companyname+' '+title+' '+firstname+' '+surname),
@bal, @bal7, @bal14, @bal21, @bal28, @balover
from clients
where clientno = @cno
fetch next from crBalance into @cno, @bal
end
close crBalance
deallocate crBalance



--spDebtorsAging '2009-07-13', 0



GO
/****** Object:  StoredProcedure [dbo].[spDeleteBannedPassword]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spDeleteBannedPassword]
@pass varchar(50)
as

delete from BannedPasswords where pass = @pass
GO
/****** Object:  StoredProcedure [dbo].[spDeleteUserGroup]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spDeleteUserGroup]
@groupname varchar(50)
as

if exists(select profilename from tblPermissions where profilename = @groupname)
begin
	raiserror('Group cannot be deleted as there are users assigned to it!', 11, 1)
	return
end

delete from tblProfiles where profilename = @groupname
GO
/****** Object:  StoredProcedure [dbo].[spEffectPayment]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

creaTE  procedure [dbo].[spEffectPayment]
@User varchar(50),
@ClientNo int,
@Date datetime,
@StartDate datetime,
@EndDate datetime,
@StatementDate datetime,
@BalancesOnly bit

as
EXEC StatementSingle @User, @ClientNo, @StatementDate, @StartDate, @EndDate, @BalancesOnly

--EXEC StatementSingle @User=''%s'', @ClientNo=%d, @StatementDate = ''%s'', @StartDate = ''%s'', @EndDate = ''%s'', @BalancesOnly = 1',[CurrentUser,CurrentClient,s,s,s]);





GO
/****** Object:  StoredProcedure [dbo].[spExportTransactions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spExportTransactions] --'2007-02-01' --update accountsparams set exportfilepath = 'c:\'
 @Date1 datetime,
 @Date2 datetime
as

declare @Seperator varchar(1)
declare @Abbreviation varchar(10)

declare @ExportFilepath varchar(100) --path where export files will be saved
declare @FileCount bigint

select @Abbreviation = 'STKBRK'
select @Seperator = '~'
select @ExportFilePath = ExportFilePath, @FileCount = isnull(ExportFileCount, 0) from ACCOUNTSPARAMS

/*if @ExportFilePath is null 
 begin
  raiserror('Export path not found',11,1)
  --return -1
 end*/

select a.TransID, a.CNO, b.[Description], a.Amount, a.Bank, a.TransDT, a.TRANSID, @FileCount as FileCount, 
	case substring(a.DealNo, 1, 1)
		when 'B' then 'BUY'
		when 'S' then 'SELL'
		else 'OTHER'
	end as Dealtype, a.DealNo, b.TransType, b.Credit, c.Sector,
--@ExportFilePath as ExportFilePath, 
@Abbreviation as Abbreviation, c.TYPE
from Transactions a inner join TransTypes b on a.TRANSCODE = b.TransType 
inner join Clients c on a.CNO = c.CLIENTNO
--where a.TransDT = @Date --'2007-06-30'
where a.TransDT >= @Date1
and a.TransDT <= @Date2
--and a.TRANSDT <= '2007-06-30'
order by a.TRANSID
--queryout @ExportFilePath+'\test.txt' 


--select transdt from transactions




GO
/****** Object:  StoredProcedure [dbo].[spGenerateCashBook]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[spGenerateCashBook] -- spGenerateCashBook '20101201','20101211', 1
@Start datetime,
@End datetime,
@CashbookID int,
@user varchar(30)
as
declare @balbf decimal(34,4), @balcf decimal(34,4)

set concat_null_yields_null off

delete from tblCashBookReport where username = @user

select @balbf = isnull(sum(amount), 0) from CashBookTrans 
where ((transcode like 'rec%') or (transcode like 'pay%'))
and cashbookid = @CashBookID
and TransDate < @Start
select @balcf = isnull(sum(amount), 0) from CashBookTrans 
where ((transcode like 'rec%') or (transcode like 'pay%'))
and cashbookid = @CashBookID
and TransDate <= @End

INSERT INTO tblCashBookReport
           ([TransDate]
           ,[postdate]
           ,[clientno]
           ,[transcode]
           ,[description]
           ,[amount]
           ,StartDate
           ,EndDate
           ,Balbf
           ,Balcf
		   ,username)
select x.TransDate, x.PostDate, ltrim(isnull(c.title,'')+' '+isnull(c.firstname,'')+' '+isnull(c.surname, '')+' '+isnull(c.companyname,'')) as client,
x.transcode, x.description, x.amount, @Start, @End, @Balbf, @Balcf, @user
from CashBookTrans x inner join clients c on x.ClientNo = c.clientno
where ((x.transcode like 'rec%') or (x.transcode like 'pay%'))
and x.cashbookid = @CashBookID
and x.TransDate >= @Start
and x.TransDate <= @End
order by x.TransDate, x.transid

update tblCashBookReport set CashBookID=@CashbookID



select * from tblCashBookReport


GO
/****** Object:  StoredProcedure [dbo].[spGetCashBookID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spGetCashBookID] --spGetCashBookID '2-cashb'
@cashbook varchar(50)
as
declare @id varchar(10), @cnt int, @temp varchar(10), @result int

select @id = '', @temp = ''
select @cnt = 1

while @cnt < len(@cashbook)
begin
 if substring(@cashbook,@cnt,1) <> '-'
  begin
   select @temp = @temp + substring(@cashbook,@cnt,1)
  end
 else
  begin
   break
  end
 select @cnt = @cnt + 1
end
select isnull(rtrim(@temp), 0) as cashbookid


GO
/****** Object:  StoredProcedure [dbo].[spGetChargesBalances]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[spGetChargesBalances] --spGetChargesBalances 'Stamp Duty (Tax) Due (SDDUE)', '2009-07-01'
@charge varchar(50),
@AsAt datetime
as
declare @transcode varchar(10), @balance decimal(34,4)

select @transcode = case @charge
                    when 'COMMISSIONER LEVY DUE (COMMLVDUE)' then 'COMMLV%'
                    when 'INVESTOR PROTECTION LEVY (INVPROTDUE)' then 'INVPRO%'
                    when 'CAPITAL GAINS TAX DUE (CAPTAXDUE)' then 'CAP%'
                    when 'V.A.T DUE (VATDUE)' then 'VAT%'
                    when 'Stamp Duty (Tax)  Due (SDDUE)' then 'SD%'
                    end

select @balance = isnull(sum(-amount),0) from transactions
where transcode like @transcode
and transdt <= @AsAt

if @transcode in ('COMMLV%', 'INVPRO%', 'CAP%', 'SD%','VAT%')
begin
select @balance = isnull(sum(-amount),0) from transactions
where transcode like @transcode
and transdt >= '2009-05-19'
and transdt <= @AsAt
end
 

select @balance as balance           




GO
/****** Object:  StoredProcedure [dbo].[spGetClientName]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spGetClientName]
@ClientNo bigint
as

set concat_null_yields_null off
select rtrim(ltrim(title+' '+firstname+' '+surname+' '+companyname)) as ClientName
from clients where clientno = @ClientNo

GO
/****** Object:  StoredProcedure [dbo].[spGetClientPortfolio]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spGetClientPortfolio]
@clientno varchar(30),
@user varchar(30)
as

delete from tblClientPortFolio where username = @user;

with port as(
select distinct d.asset, a.assetname,
(select isnull(sum(x.qty), 0) from dealallocations x where x.asset = d.asset and x.clientno = d.clientno and x.dealtype = 'BUY') as buy,
(select isnull(sum(x.qty), 0) from dealallocations x where x.asset = d.asset and x.clientno = d.clientno and x.dealtype = 'SELL') as sell
from dealallocations d inner join assets a on d.asset = a.assetcode
where d.clientno = @clientno
)
insert into tblClientPortfolio(clientno, asset, bought, sold, username)
select @clientno, asset, buy, sell, @user
from port


GO
/****** Object:  StoredProcedure [dbo].[spGetDueDate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE  procedure [dbo].[spGetDueDate]
	@Year int,
	@Month int,
	@Day int
as
declare @DealDate datetime
declare @TPLUSDAYS int
declare @TPLUSDATE as datetime

select @DealDate = cast(cast(@Year as varchar(4))+'-'+cast(@Month as varchar(2))+'-'+cast(@Day as varchar(2)) as datetime)

set datefirst 1
select @TPLUSDAYS = TPLUSDAYS from general

if @TPLUSDAYS is null
 select @TPLUSDAYS = 3
/*
if datepart(dw, @DealDate) in (1,2)
select @TPLUSDATE = DATEADD(Day, 3, @DealDate)
else
select @TPLUSDATE = DATEADD(Day, 5, @DealDate)

select @TPLUSDATE = DATEADD(Day, @TPLUSDAYS, @DealDate)
if datepart(dw, @TPLUSDATE) in (1,2)
select @TPLUSDATE = DATEADD(Day, 3, @DealDate)
else
select @TPLUSDATE = DATEADD(Day, 5, @DealDate)

--while ((@TPLUSDATE in (select hDate from tblHoliday)) or (datepart(dw, @TPLUSDATE) in (6,7)))
--while datepart(dw, @TPLUSDATE) in (6,7)
--begin
 --select @TPLUSDATE = DateAdd(Day, 1, @TPLUSDATE)
--end
*/
select @TPLUSDATE = dateadd(day,7,@DealDate )
select @TPLUSDATE as TPLUSDATE
GO
/****** Object:  StoredProcedure [dbo].[spGetServerDate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[spGetServerDate]
as
declare @serverdate datetime
declare @backforward bit
select @backforward = isnull(BackForwardDate, 0) from accountsparams
if @backforward = 1
select getdate() as serverdate
else
select null as serverdate


GO
/****** Object:  StoredProcedure [dbo].[spIncomingRegistrationsClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[spIncomingRegistrationsClients]
as
declare @id bigint, @cno int, @client varchar(100)

set concat_null_yields_null off
declare crclient cursor for 
select id, clientno from tblincomingregistrations
where clientno > 0

open crclient
fetch next from crclient into @id, @cno
while @@fetch_status = 0
begin
 select @client = ltrim(rtrim(c.companyname+' '+c.surname+' '+c.firstname)) from clients c
 where clientno = @cno
 update tblIncomingRegistrations set client = @client
 where id = @id
 fetch next from crclient into @id, @cno
end
close crclient
deallocate crclient

update tblIncomingRegistrations set client = 'UNALLOCATED'
where clientno = 0
GO
/****** Object:  StoredProcedure [dbo].[spIncrementExportFileCount]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spIncrementExportFileCount]
as
update ACCOUNTSPARAMS set ExportFileCount = IsNull(ExportfileCount, 0) + 1

GO
/****** Object:  StoredProcedure [dbo].[spInsertBalanceCertificate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spInsertBalanceCertificate]
@dealno varchar(50),
@qty int,
@ledgerid bigint
as
declare @counter varchar(10)

select @counter = asset from Dealallocations where DealNo = @dealno

insert into tblDealBalanceCertificates(dealno, BalCertQty, BalCertDate, Closed, CertNo, BalRemaining)
select 'BAL-'+@dealno, @qty, dbo.fnFormatDate(getdate()), 0, certno, @qty from scripledger
where id = @ledgerid

--exec spScripBalancingProcess 'BALON', @qty, @qty, @counter

GO
/****** Object:  StoredProcedure [dbo].[spInsertEmailDealNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spInsertEmailDealNo]
@dealno varchar(10)
as
delete from tblEmailDealNo
insert into tblEmailDealno(dealno) values(@dealno) 

GO
/****** Object:  StoredProcedure [dbo].[spInsertScripShapes]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--spinsertscripshapes 'gibs', 3
CREATE procedure [dbo].[spInsertScripShapes]  --spInsertScripShapes ''gibs'', 508
@user varchar(20),
@shapeid bigint--,
--@outid bigint output
as
declare @ref varchar(20)
declare @id bigint
declare @cert varchar(20), @asset varchar(10)
declare @newid bigint
declare @CNO varchar(20), @lid bigint, @dealno varchar(20), @shapeqty int, @counter varchar(10)
declare @Dt datetime

--begin transaction
select @shapeqty = qty, @counter = asset, @dealno = dealno from scripshape where id = @shapeid --'BAL-B/10094'

select @Ref = dbo.fnGetLedgerRefNumber()
update scriprefs set refledger = @ref
INSERT INTO [SCRIPLEDGER]
           (REFNO,[ITEMNO],[INCOMING] ,[CDATE],[USERID] ,[REASON],[CLIENTNO]
           ,[CERTNO],[ASSET],[QTY] ,[REGHOLDER] ,[ADDRESS],[TRANSFORM],[CLOSED]
           ,[CANCELLED],[VERIFIED],[VERIFYUSER],[VERIFYDT],[VERIFYREF]
           ,[ISSUEDATE],[HOLDERNO],[TRANSFERNO],[SHAPEID])
SELECT @Ref, 1,1,GETDATE(), @User, 'TRANSFERRED',[TOCLIENT],[NEWCERTNO],[ASSET],[QTY],[REGHOLDER],
       [REGADDRESS],1,0,0,1,@User, [ISSUEDATE],'REGISTRATION', [ISSUEDATE],[HOLDERNO],[TRANSFERNO],[ID]
FROM [SCRIPSHAPE]
where id = @shapeid 

select @newid = max(id) from scripledger
select @CNO = clientno, @Dt = cdate from scripledger where id = @newid

insert into tblScripLedgerID(id) values(@newid)

update scripshape set closed = 1
where id = @id

delete from tblBuySettlementDeals where ((username = @user) or (username is null))

 if left(@dealno, 2) = 'B/' --close buy position
 begin
	 insert into scripdealscerts(ledgerid, dealno, reversetemp, dt, [user], cancelled, qtyused)
	 values(@newid, @dealno, 0, getdate(), @user, 0, @shapeqty)
	 update dealallocations set sharesout = sharesout - @shapeqty
	 where dealno = @dealno 
	 
	 --save the settled deal's details into tblBuySettlementDeals
	 insert into tblBuySettlementDeals(dealdate, asset, dealno, qty, price, NetConsideration, SettledConsideration, username)
	 select dealdate, asset, dealno, qty, price, dealvalue, dealvalue, @user
	 from DEALALLOCATIONS where DealNo = @dealno
 end

if left(@dealno, 2) = 'BA' --close balance position
 begin
	update tblDealBalanceCertificates set balremaining = balremaining - @shapeqty
	where dealno = @Dealno
end
 --assign the received to the client's account
 update scripsafe set clientno = @cno where ledgerid = @lid
--commit transaction

--if client is NMI then deliver scrip out of the system
if exists(select clientno from clients where left(category, 3) = 'NMI' and clientno = @cno)
begin
	select @Ref = dbo.fnGetLedgerRefNumber()
	INSERT INTO [SCRIPLEDGER]
           (REFNO,[ITEMNO],[INCOMING] ,[CDATE],[USERID] ,[REASON],[CLIENTNO]
           ,[CERTNO],[ASSET],[QTY] ,[REGHOLDER] ,[ADDRESS],[TRANSFORM],[CLOSED]
           ,[CANCELLED],[VERIFIED],[VERIFYUSER],[VERIFYDT],[VERIFYREF]
           ,[ISSUEDATE],[HOLDERNO],[TRANSFERNO],[SHAPEID], INCOMINGID)
	SELECT @Ref, 1,0,GETDATE(), @User, null,[TOCLIENT],[NEWCERTNO],[ASSET],[QTY],[REGHOLDER],
		   [REGADDRESS],1,0,0,1,@User, [ISSUEDATE],'TSEC TO NMI', [ISSUEDATE],[HOLDERNO],[TRANSFERNO],0, [ID]
	FROM [SCRIPSHAPE]
	where id = @shapeid 
end

--select @outid = max(id) from scripledger where userid = 'gibs' ---@user

--select max(id) from scripledger where userid = 'gibs'
GO
/****** Object:  StoredProcedure [dbo].[spInsertTempRefNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spInsertTempRefNo]
@RefNo varchar(50)
as
insert into tblTempRefNo(RefNo)
values(@RefNo)

GO
/****** Object:  StoredProcedure [dbo].[spInsertTempShapeID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spInsertTempShapeID]
@ID bigint
as 
if not exists(select ID from tblTempShapeID where ID = @ID)
 begin
  insert into tblTempShapeID(ID)
  values(@ID)
 end



GO
/****** Object:  StoredProcedure [dbo].[spInvestorProtection]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[spInvestorProtection] --'2009-05-01', '2009-05-31'
@Start datetime,
@end datetime 
as
declare @balbf decimal(34,4), @balcf decimal(34,4),@sumtxns decimal(34,4),@sumpaymnts decimal(34,4)

select @balbf = sum(amount) from transactions
where  transdt < @Start
and transcode like 'invprot%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30


select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@end)
and transcode like 'invprot%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30


select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where  (transdt <=@end)
and transcode like 'invprotd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @balcf=@sumtxns + @sumpaymnts 

delete from tblCommissionerLevyLedger 
insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	[qty],
	[price],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       d.dealno, d.asset, d.qty, d.price, x.amount, @balbf, @balcf 
from transactions x  inner join dealallocations d on x.dealno = d.dealno
where x.transdt >= @Start
and x.transdt <= @end
and x.transcode like 'invprot%' 
and x.dealno in (select dealno from dealallocations where approved = 1
and   merged = 0 )
and x.cno > 30
order by d.dealdate

insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       'INVPROT', 'DUE', x.amount, @balbf, @balcf 
from transactions x
where x.transdt >= @Start
and x.transdt <= @end
and x.transcode like 'invprotd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30




GO
/****** Object:  StoredProcedure [dbo].[spLedgerAccount]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  StoredProcedure [dbo].[spLockUnlockUser]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spLockUnlockUser]
@user varchar(50)
as

if exists(select [login] from users where [login] = @user and islocked = 1)
begin
	update users set islocked = 0 where [login] = @user
end
else
begin
	update users set islocked = 1 where [login] = @user
end
GO
/****** Object:  StoredProcedure [dbo].[spNewConsolidationSplit]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spNewConsolidationSplit]
@counter varchar(10),
@dt datetime,
@old int,
@new int,
@comment varchar(150)
as
insert into consolidations(asset, dt, oldqty, newqty, notes, entrydate, newasset)
values(@counter, @dt, @old, @new, @comment, getdate(), @counter)
GO
/****** Object:  StoredProcedure [dbo].[spOpenPositionsAging]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spOpenPositionsAging]
as
delete from tblOpenPositionsAging
insert into tblOpenPositionsAging
select d.dealno, d.dealdate, c.companyname, coalesce(c.companyname, c.surname +'  '+c.firstname) as client,
(select isnull(a.sharesout, 0) from DEALALLOCATIONS a where a.DealNo = d.dealno and DATEDIFF(day, a.dealdate, getdate()) >= 222 and DATEDIFF(day, a.dealdate, getdate()) <= 229) as d7,
(select isnull(a.sharesout, 0) from DEALALLOCATIONS a where a.DealNo = d.dealno and DATEDIFF(day, a.dealdate, getdate()) > 229 and DATEDIFF(day, a.dealdate, getdate()) <= 236) as d14,
(select isnull(a.sharesout, 0) from DEALALLOCATIONS a where a.DealNo = d.dealno and DATEDIFF(day, a.dealdate, getdate()) > 236 and DATEDIFF(day, a.dealdate, getdate()) <= 243) as d21,
(select isnull(a.sharesout, 0) from DEALALLOCATIONS a where a.DealNo = d.dealno and DATEDIFF(day, a.dealdate, getdate()) > 243 and DATEDIFF(day, a.dealdate, getdate()) <= 250) as d28,
(select isnull(a.sharesout, 0) from DEALALLOCATIONS a where a.DealNo = d.dealno and DATEDIFF(day, a.dealdate, getdate()) > 250) as overthan
from DEALALLOCATIONS d inner join clients c on d.clientno = c.clientno
where d.approved = 1 and d.cancelled = 0 
and d.merged = 0 and d.SHARESOUT > 0
order by d.id desc

GO
/****** Object:  StoredProcedure [dbo].[spOpenSettledDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--deals settled but still remain open
CREATE procedure [dbo].[spOpenSettledDeals]
as
select d.asset, d.dealdate, d.dealno, d.qty, d.price, l.certno, l.qty, s.qtyused, coalesce(c.companyname, c.surname +'  '+c.firstname)
 from DEALALLOCATIONS d inner join clients c on d.clientno = c.clientno
 inner join SCRIPDEALSCERTS s on d.DealNo = s.DEALNO
 left join SCRIPLEDGER l on s.LEDGERID = l.ID
 where d.SHARESOUT > 0 and s.CANCELLED = 0
--and d.DealNo in (select DealNo from SCRIPDEALSCERTS)
order by d.Asset, d.DealDate, d.Qty
GO
/****** Object:  StoredProcedure [dbo].[spPendingDeliveryScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author: Gibson Mhlanga
	Date:	30 September 2011
	Description:
	Use temp tables to look up duplications and remove them from the selected scrip
 
	Method: 
		    1. insert the selected entries into a temp table
            2. loop thru the temp table, take each counter's certificate # and look it up in a 2nd temp table
            3. if cert# not in 2nd temp table then insert into 2nd temp table, if exists then delete from 1st temp table
*/
--[spPendingDeliveryScrip] ''
CREATE procedure [dbo].[spPendingDeliveryScrip]
@counter varchar(10)
as
declare @asset varchar(10), @certno varchar(20), @id bigint

--insert into 1st temp table
truncate table tblPendingDelivery1stTempTable
truncate table tblPendingDelivery2ndTempTable
--scrip that settled buy deals
insert into tblPendingDelivery1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference) 
select distinct l.id, l.certno, l.asset, l.qty, sd.dt, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, sd.[user], sd.dealno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripdealscerts sd on l.id = sd.ledgerid  
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null)  
and LEFT(sd.dealno, 2) = 'B/' and s.clientno <> '0' and sd.cancelled = 0
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
and l.ASSET like '%'+@counter+'%'
union --scrip received from TSEC into the clients' custody
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno <> '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
and l.ASSET like '%'+@counter+'%'

--look up in 2nd temp table and remove duplicate if found
declare crid cursor for
select id, asset, certno from tblPendingDelivery1stTempTable
open crid
fetch next from crid into @id, @asset, @certno
while @@FETCH_STATUS = 0
begin
	if exists(select certno from tblPendingDelivery2ndTempTable where asset = @asset and certno = @certno)
	begin
		delete from tblPendingDelivery1stTempTable
		where ID = @id
	end
	else
	begin
		insert into tblPendingDelivery2ndTempTable(asset, certno)
		values(@asset, @certno)
	end
	fetch next from crid into @id, @asset, @certno
end
close crid
deallocate crid

select certno, certid as id, asset, qty, cdate, transform, clientno, client, regholder, userid, reference  
from tblPendingDelivery1stTempTable
order by asset, certno, qty
GO
/****** Object:  StoredProcedure [dbo].[spPendingDeliveryScripReport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spPendingDeliveryScripReport]
@counter varchar(10)
as
declare @asset varchar(10), @certno varchar(20), @id bigint

--insert into 1st temp table
truncate table tblPendingDelivery1stTempTable
truncate table tblPendingDelivery2ndTempTable
--scrip that settled buy deals
insert into tblPendingDelivery1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference) 
select distinct l.id, l.certno, l.asset, l.qty, sd.dt, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, sd.[user], sd.dealno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripdealscerts sd on l.id = sd.ledgerid  
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null)  
and LEFT(sd.dealno, 2) = 'B/' and s.clientno <> '0' and sd.cancelled = 0
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
and l.ASSET like '%'+@counter+'%'
union --scrip received from TSEC into the clients' custody
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno <> '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
and l.ASSET like '%'+@counter+'%'

--look up in 2nd temp table and remove duplicate if found
declare crid cursor for
select id, asset, certno from tblPendingDelivery1stTempTable
open crid
fetch next from crid into @id, @asset, @certno
while @@FETCH_STATUS = 0
begin
	if exists(select certno from tblPendingDelivery2ndTempTable where asset = @asset and certno = @certno)
	begin
		delete from tblPendingDelivery1stTempTable
		where ID = @id
	end
	else
	begin
		insert into tblPendingDelivery2ndTempTable(asset, certno)
		values(@asset, @certno)
	end
	fetch next from crid into @id, @asset, @certno
end
close crid
deallocate crid

insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid, reference)
select p.asset, p.certno, p.qty, a.assetname, p.client, p.cdate, p.regholder, p.userid, p.reference  
from tblPendingDelivery1stTempTable p inner join ASSETS a on p.asset = a.ASSETCODE
where p.clientno <> '0'
and a.[STATUS] = 'ACTIVE'
and p.clientno not in (select clientno from CLIENTS where ((CATEGORY = 'broker') or (left(category, 3) = 'NMI')))
order by p.asset, p.certno, p.qty
GO
/****** Object:  StoredProcedure [dbo].[spPostCharge]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  StoredProcedure [dbo].[spPostDeal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
	17-02-2019
	1.	insert deals (both client and broker deal) into dealallocations table
	2.	post the corresponding charges to the charges accounts
	3.	post the corresponding trade transaction to the transactions table
	4.	if non-custodial client, then post corresponding receipt or payment to the client's account
*/

CREATE procedure [dbo].[spPostDeal] -- exec spPostDeal '20190220', '4498MMC', 'SELL', 2581, 96, 'CAIRN-L', '121554', 'bug'
	@dealdate datetime, @clientno varchar(10), @dealtype varchar(10),
	@qty int, @price float, @asset varchar(10), @CSDNumber varchar(50)
	,@user varchar(30), @noncustodial bit, @bookover bit
as
declare @dealno varchar(10), @consideration money, @dealvalue money
declare @category varchar(30), @CDC varchar(10), @charges float, @brokerdealtype varchar(10);
declare @cgt money = 0, @sduty money = 0, @defaultcashbook int


select @category = category from clients
where clientno = @clientno

select @consideration = @qty*@price/100

select @dealno = left(@dealtype, 1) +'/'+ cast(dbo.fnGetDealno() as varchar(10))

	if @dealtype = 'SELL'
	begin
		select @dealvalue = @consideration -(dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno))

		select @charges = dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		--dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno)
		select @cgt = dbo.fnCalculateCapitalGains(@consideration, @clientno) 
		select @brokerdealtype = 'BUY'
	end
	else if @dealtype = 'BUY'
	begin
		select @dealvalue = @consideration + dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + --dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno)

		select @charges = dbo.fnCalculateVat(@consideration, @clientno)+ dbo.fnCalculateCommission(@consideration, @clientno) + 
		dbo.fnCalculateStampDuty(@consideration, @clientno) + 
		dbo.fnCalculateSecLevy(@consideration, @clientno) + --dbo.fnCalculateCapitalGains(@consideration, @clientno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @clientno)+dbo.fnCalculateZSELevy(@consideration, @clientno)+
		dbo.fnCalculateCSDLevy(@consideration, @clientno)

		select @sduty = dbo.fnCalculateStampDuty(@consideration, @clientno)
		select @brokerdealtype = 'SELL'
    end   

	insert into DEALALLOCATIONS(docketno, dealtype, dealno, dealdate, clientno, asset, qty, price, Consideration, StampDuty, approved, sharesout, certdueby, cancelled, merged, 
	[login], dateadded, vat, capitalgains, investorprotection, commissionerlevy, zselevy, dealvalue, 
	approvedby, grosscommission, yon, csdlevy, csdnumber, bookover)
	select 0, @dealtype, @dealno, @dealdate, @clientno, @asset, @qty, @price,
	@qty*@price/100,
	@sduty
	,1, 0
	,dbo.fnGetSettlementDate(@dealdate)
	,0, 0, @user, getdate()
	,dbo.fnCalculateVat(@consideration, @clientno)
	,@cgt
	,dbo.fnCalculateInvestorProtection(@consideration, @clientno)
	,dbo.fnCalculateSecLevy(@consideration, @clientno)
	,dbo.fnCalculateZSELevy(@consideration, @clientno)
	,@dealvalue
	,@user
	,dbo.fnCalculateCommission(@consideration, @clientno)
	,1
	,dbo.fnCalculateCSDLevy(@consideration, @clientno)
	,@CSDNumber, @bookover
	
	--post the corresponding broker deal to ATS Trades account
	if @bookover = 0
	begin
		insert into dealallocations (docketno,dealtype,dealno,dealdate,clientno,asset,qty,price,consideration,grosscommission,basiccharges,stampduty,login,approved,sharesout,certdueby,cancelled, merged, vat,capitalgains,investorprotection,commissionerlevy,zselevy,dealvalue,yon, DateAdded) 
		values(0, @brokerdealtype, left(@brokerdealtype, 1) +'/'+dbo.fnGetDealNo(), @dealdate, 0, @asset, @qty, @price, @consideration, 0, 0, 0, @user, 1, 0, dbo.fnGetSettlementDate(@dealdate), 0, 0, 0, 0, 0, 0, 0, @consideration, 1, getdate())
	end

	--post the deal's charges to the various charges accounts
	exec DealChargesTransact @DealNo, 'Credit', @User

	--post the deal's charges to the CDC account
	if @charges > 0
	begin
		select @CDC = ControlAccount from tblSystemParams
		----post lumpsum of all charges
		--insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		--values(@CDC, getdate(), @dealno, 'PAY', @dealdate, cast(@qty as varchar(10))+' '+@asset+' @ '+cast(@price as varchar(10)), abs(@consideration-@dealvalue))

		--post itemised charges to Chengetedzai acc - 13 May 2020
		if @dealtype = 'SELL'
		begin
			insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
			values(@CDC, getdate(), @dealno, 'CAPTAX', @dealdate, @dealno, dbo.fnCalculateCapitalGains(@consideration, @clientno))
		end
		else
		begin
			insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
			values(@CDC, getdate(), @dealno, 'SDUTY', @dealdate, @dealno, dbo.fnCalculateStampDuty(@consideration, @clientno) )
		end

		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'COMMS', @dealdate, @dealno, dbo.fnCalculateCommission(@consideration, @clientno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'VATCOMM', @dealdate, @dealno, dbo.fnCalculateVat(@consideration, @clientno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'ZSELV', @dealdate, @dealno, dbo.fnCalculateZSELevy(@consideration, @clientno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'INVPROT', @dealdate, @dealno, dbo.fnCalculateInvestorProtection(@consideration, @clientno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'COMMLV', @dealdate, @dealno, dbo.fnCalculateSecLevy(@consideration, @clientno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'CSDLV', @dealdate, @dealno, dbo.fnCalculateCSDLevy(@consideration, @clientno) )
	end

--if client is noncustodial, then automatically post REC or PAY depending on deal type
--if exists(select clientno from clients where clientno = @clientno and custodial = 0)
if @noncustodial = 1
begin
	insert into cashbooktrans(ClientNo, postdate, dealno, transcode, transdate, [description], amount, yon)
	select @clientno, getdate(), @dealno, 
		case left(@dealno, 1)
			when 'B' then 'REC'
			when 'S' then 'PAY'
		end,
		@dealdate,
		case left(@dealno, 1)
			when 'B' then 'RECEIPT THROUGH CUSTODIAN'
			when 'S' then 'PAYMENT THROUGH CUSTODIAN'
		end,
		case left(@dealno, 1)
			when 'B' then -@dealvalue
			when 'S' then @dealvalue
		end
		, 1
end 
GO
/****** Object:  StoredProcedure [dbo].[spPostDealFromFile]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
	17-02-2019
	1.	insert deals (both client and broker deal) into dealallocations table
	2.	post the corresponding charges to the charges accounts
	3.	post the corresponding trade transaction to the transactions table
	4.	if non-custodial client, then post corresponding receipt or payment to the client's account
*/

CREATE procedure [dbo].[spPostDealFromFile] -- exec spPostDeal '20190220', '4498MMC', 'SELL', 2581, 96, 'CAIRN-L', '121554', 'bug'
	@date datetime, @clientno varchar(30), @dealtype varchar(10),
	@qty int, @price float, @asset varchar(30), @CSDNumber varchar(30)
	,@user varchar(30), @noncustodial bit
as

declare @dealno varchar(10), @consideration money, @dealvalue money
declare @category varchar(30), @CDC varchar(10), @charges float, @brokerdealtype varchar(10);
declare @cgt money = 0, @sduty money = 0, @defaultcashbook int

declare @assetcode varchar(20), @cno varchar(30), @dealdate datetime
declare @det varchar(8)

--select @det = substring(@det, 7, 4) +'/'+substring(@det, 1, 2) + '/' +substring(@det, 4, 2) --dbo.fnFormatDate(@date)
select @dealdate = @date  --cast(@det as datetime)

select @assetcode = assetcode from assets 
where symbol = ltrim(rtrim(@asset))

select @cno = clientno from clients where csdnumber = @clientno

select @category = category from clients
where clientno = @cno

select @consideration = @qty*@price/100

select @dealno = left(@dealtype, 1) +'/'+ cast(dbo.fnGetDealno() as varchar(10))

	if @dealtype = 'SELL'
	begin
		select @dealvalue = @consideration -(dbo.fnCalculateVat(@consideration, @cno)+ dbo.fnCalculateCommission(@consideration, @cno) + 
		dbo.fnCalculateSecLevy(@consideration, @cno) + dbo.fnCalculateCapitalGains(@consideration, @cno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @cno)+dbo.fnCalculateZSELevy(@consideration, @cno)+
		dbo.fnCalculateCSDLevy(@consideration, @cno))

		select @charges = dbo.fnCalculateVat(@consideration, @cno)+ dbo.fnCalculateCommission(@consideration, @cno) + 
		--dbo.fnCalculateStampDuty(@consideration, @cno) + 
		dbo.fnCalculateSecLevy(@consideration, @cno) + dbo.fnCalculateCapitalGains(@consideration, @cno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @cno)+dbo.fnCalculateZSELevy(@consideration, @cno)+
		dbo.fnCalculateCSDLevy(@consideration, @cno)
		select @cgt = dbo.fnCalculateCapitalGains(@consideration, @cno) 
		select @brokerdealtype = 'BUY'
	end
	else if @dealtype = 'BUY'
	begin
		select @dealvalue = @consideration + dbo.fnCalculateVat(@consideration, @cno)+ dbo.fnCalculateCommission(@consideration, @cno) + 
		dbo.fnCalculateStampDuty(@consideration, @cno) + 
		dbo.fnCalculateSecLevy(@consideration, @cno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @cno)+dbo.fnCalculateZSELevy(@consideration, @cno)+
		dbo.fnCalculateCSDLevy(@consideration, @cno)

		select @charges = dbo.fnCalculateVat(@consideration, @cno)+ dbo.fnCalculateCommission(@consideration, @cno) + 
		dbo.fnCalculateStampDuty(@consideration, @cno) + 
		dbo.fnCalculateSecLevy(@consideration, @cno) + --dbo.fnCalculateCapitalGains(@consideration, @cno) + 
		dbo.fnCalculateInvestorProtection(@consideration, @cno)+dbo.fnCalculateZSELevy(@consideration, @cno)+
		dbo.fnCalculateCSDLevy(@consideration, @cno)

		select @sduty = dbo.fnCalculateStampDuty(@consideration, @cno)
		select @brokerdealtype = 'SELL'
    end   

	if exists(select clientno from clients where clientno = @cno)
	begin

	insert into DEALALLOCATIONS(docketno, dealtype, dealno, dealdate, clientno, asset, qty, price, Consideration, StampDuty, approved, sharesout, certdueby, cancelled, merged, 
	[login], dateadded, vat, capitalgains, investorprotection, commissionerlevy, zselevy, dealvalue, 
	approvedby, grosscommission, yon, csdlevy, csdnumber)
	select 0, @dealtype, @dealno, @dealdate, @cno, @assetcode, @qty, @price,
	@qty*@price/100,
	@sduty
	,1, 0
	,dbo.fnGetSettlementDate(@dealdate)
	,0, 0, @user, getdate()
	,dbo.fnCalculateVat(@consideration, @cno)
	,@cgt
	,dbo.fnCalculateInvestorProtection(@consideration, @cno)
	,dbo.fnCalculateSecLevy(@consideration, @cno)
	,dbo.fnCalculateZSELevy(@consideration, @cno)
	,@dealvalue
	,@user
	,dbo.fnCalculateCommission(@consideration, @cno)
	,1
	,dbo.fnCalculateCSDLevy(@consideration, @cno)
	,@CSDNumber
	--select * from dealallocations
	--post the corresponding broker deal to ATS Trades account
	insert into dealallocations (docketno,dealtype,dealno,dealdate,clientno,asset,qty,price,consideration,grosscommission,basiccharges,stampduty,login,approved,sharesout,certdueby,cancelled, vat,capitalgains,investorprotection,commissionerlevy,zselevy,dealvalue,yon, DateAdded) 
	values(0, @brokerdealtype, left(@brokerdealtype, 1) +'/'+dbo.fnGetDealNo(), @dealdate, 0, @assetcode, @qty, @price, @consideration, 0, 0, 0, @user, 1, 0, dbo.fnGetSettlementDate(@dealdate), 0, 0, 0, 0, 0, 0, @consideration, 1, getdate())

	--post the deal's charges to the various charges accounts
	exec DealChargesTransact @DealNo, 'Credit', @User

	--post the deal's charges to the CDC account
	if @charges > 0
	begin
		select @CDC = ControlAccount from tblSystemParams
		----post lumpsum of all charges
		--insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		--values(@CDC, getdate(), @dealno, 'PAY', @dealdate, cast(@qty as varchar(10))+' '+@asset+' @ '+cast(@price as varchar(10)), abs(@consideration-@dealvalue))

		--post itemised charges to Chengetedzai acc - 13 May 2020
		if @dealtype = 'SELL'
		begin
			insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
			values(@CDC, getdate(), @dealno, 'CAPTAX', @dealdate, @dealno, dbo.fnCalculateCapitalGains(@consideration, @cno))
		end
		else
		begin
			insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
			values(@CDC, getdate(), @dealno, 'SDUTY', @dealdate, @dealno, dbo.fnCalculateStampDuty(@consideration, @cno) )
		end

		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'COMMS', @dealdate, @dealno, dbo.fnCalculateCommission(@consideration, @cno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'VATCOMM', @dealdate, @dealno, dbo.fnCalculateVat(@consideration, @cno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'ZSELV', @dealdate, @dealno, dbo.fnCalculateZSELevy(@consideration, @cno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'INVPROT', @dealdate, @dealno, dbo.fnCalculateInvestorProtection(@consideration, @cno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'COMMLV', @dealdate, @dealno, dbo.fnCalculateSecLevy(@consideration, @cno) )
		insert into transactions(ClientNo, postdate, dealno, transcode, transdate, [description], amount)
		values(@CDC, getdate(), @dealno, 'CSDLV', @dealdate, @dealno, dbo.fnCalculateCSDLevy(@consideration, @cno) )
	end

--if client is noncustodial, then automatically post REC or PAY depending on deal type
--if exists(select clientno from clients where clientno = @cno and custodial = 0)
if @noncustodial = 1
begin
	insert into cashbooktrans(ClientNo, postdate, dealno, transcode, transdate, [description], amount, yon)
	select @cno, getdate(), @dealno, 
		case left(@dealno, 1)
			when 'B' then 'REC'
			when 'S' then 'PAY'
		end,
		@dealdate,
		case left(@dealno, 1)
			when 'B' then 'RECEIPT THROUGH CUSTODIAN'
			when 'S' then 'PAYMENT THROUGH CUSTODIAN'
		end,
		case left(@dealno, 1)
			when 'B' then -@dealvalue
			when 'S' then @dealvalue
		end
		, 1
end 

end
GO
/****** Object:  StoredProcedure [dbo].[spPreparePendingRegistrations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author: Gibson Mhlanga
Created: 04-03-2011
Desc: selects each distinct transfer reference number
*/
CREATE procedure [dbo].[spPreparePendingRegistrations]
as

declare @refno varchar(10), @id bigint, @cid bigint, @counter varchar(10)

create table #transfer(
refno varchar(20))

insert into #transfer 
select distinct refno from SCRIPTRANSFER 
where CANCELLED = 0 and CLOSED = 0

truncate table tblTransfer
declare crTransfer cursor for 
select refno from #transfer
open crTransfer
fetch next from crTransfer into @refno
while @@FETCH_STATUS = 0
begin
 select @id = MAX(ledgerid) from SCRIPTRANSFER
 where REFNO = @refno
 select @cid = MAX(id) from SCRIPTRANSFER 
 where REFNO = @refno
 select @counter = ASSET from scripledger where ID = @id
 
 insert into tblTransfer(refno, datesent, userid, asset, transsec, id)
 select t.refno, t.datesent, t.userid, @counter, c.companyname, @cid
 from SCRIPTRANSFER t inner join clients c on t.TRANSSEC = c.CLIENTNO
 where t.ID = @cid
 fetch next from crTransfer into @refno 
end
close crTransfer
deallocate crTransfer

drop table #transfer

GO
/****** Object:  StoredProcedure [dbo].[spPrepareSafeCustodyScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spPrepareSafeCustodyScrip]
as
insert into tblBuySettlementScrip(certno, asset, qty, client)
select l.certno, l.asset, l.qty, ltrim(rtrim(c.companyname+' '+c.surname+' '+c.firstname))
from scripledger l inner join scripsafe s on l.id = s.ledgerid
left join clients c on s.clientno = c.clientno
where l.id in (select id from tblSafeCustodyScripID)
GO
/****** Object:  StoredProcedure [dbo].[spPrepareScripBalancing]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spPrepareScripBalancing]
@user varchar(20)
as
--declare @bought int, @sold int, @duefrom int , @dueto int, @unallocated int, @tsec int, @bal int, @counter varchar(10)

--delete from tblScripBalancing where username = @user
--INSERT INTO [tblScripBalancing]
--           ([counter]
--           ,[bought]
--           ,[sold]
--           ,[dueto]
--           ,[duefrom]
--           ,[unallocated]
--           ,[transfersec]
--           ,[balancecertificates], username)
--select ASSETCODE,0,0,0,0,0,0,0, @user from assets
--where [STATUS] = 'ACTIVE'
--and (category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))
--and (ASSETCODE not in (select ASSETCODE from tblScripBalancing))

--declare crCounter cursor for
--select [counter] from tblScripBalancing where username = @user
--open crCounter
--fetch next from crCounter into @counter

--while @@FETCH_STATUS = 0
--begin
--	select @bought = ISNULL(sum(qty),0) from Dealallocations where Approved = 1 and Cancelled = 0 and Merged = 0
--	and asset = @counter and DealType = 'BUY'
--	select @sold = ISNULL(sum(qty),0) from Dealallocations where Approved = 1 and Cancelled = 0 and Merged = 0
--	and asset = @counter and DealType = 'SELL'
--	select @duefrom = ISNULL(sum(SharesOut),0) from Dealallocations where Approved = 1 and Cancelled = 0 and Merged = 0
--	and asset = @counter and DealType = 'SELL' and SharesOut > 0
--	select @dueto = ISNULL(sum(SharesOut),0) from Dealallocations where Approved = 1 and Cancelled = 0 and Merged = 0
--	and asset = @counter and DealType = 'BUY' and SharesOut > 0
--	select @unallocated = ISNULL(sum(qty),0) from SCRIPLEDGER where asset = @counter and cancelled = 0 and verified = 1
--	and ID in (select ledgerid from SCRIPSAFE where clientno = '0' and CLOSED = 0 and (DATEOUT is null))
--	select @tsec = ISNULL(sum(qty),0) from SCRIPSHAPE where asset = @counter and CLOSED = 0 and (NEWCERTNO is null)
--	and REFNO in (select REFNO from SCRIPTRANSFER where CLOSED = 0 and LEDGERID in (select LEDGERID from SCRIPSAFE where CLIENTNO = '0'))
--	select @bal = ISNULL(sum(balremaining),0) from tblDealBalanceCertificates where BalRemaining > 0 and Closed = 0
--	and dealno in (select dealno from Dealallocations where asset = @counter)
	
--	update tblScripBalancing set bought = @bought, sold = @sold, duefrom = @duefrom, dueto = @dueto, unallocated = @unallocated,
--	transfersec = @tsec, balancecertificates = @bal
--	where [counter] = @counter and username = @user
	
--	fetch next from crCounter into @counter	
--end
--close crCounter
--deallocate crCounter

declare @dueto int, @duefrom int, @bc int, @unallocated int, @tsec int, @counter varchar(10), @imbalance int
declare @bot int, @sold int

declare crcounter cursor for
select assetcode from assets
--where assetcode >= @counter1
--and assetcode <= @counter2
where [status] = 'active'
and (category not in ('LETTERS OF ALLOCATION', 'PREFERENCE SHARES', 'ZSE INDEX'))

--select distinct category from assets
open crcounter

fetch next from crcounter into @counter
delete from tblScripBalancingReport where (username = @user) or (username is null)
while @@FETCH_STATUS = 0
begin
	select @bot = ISNULL(sum(qty), 0) from DEALALLOCATIONS where ASSET = @counter
	and APPROVED = 1 and CANCELLED = 0 and MERGED = 0 and DEALTYPE = 'BUY'
	
	select @sold = ISNULL(sum(qty), 0) from DEALALLOCATIONS where ASSET = @counter
	and APPROVED = 1 and CANCELLED = 0 and MERGED = 0 and DEALTYPE = 'SELL'
	
	select @dueto = ISNULL(sum(sharesout), 0) from DEALALLOCATIONS where ASSET = @counter
	and SHARESOUT > 0 and APPROVED = 1 and CANCELLED = 0 and MERGED = 0
	and DEALTYPE = 'BUY'
	
	select @bc = ISNULL(sum(balremaining), 0) from tblDealBalanceCertificates where BalRemaining > 0 and Cancelled = 0 and Closed = 0
	and dealno in (select dealno from DEALALLOCATIONS where ASSET = @counter)
	
	select @duefrom = ISNULL(sum(sharesout), 0) from DEALALLOCATIONS where ASSET = @counter
	and SHARESOUT > 0 and APPROVED = 1 and CANCELLED = 0 and MERGED = 0
	and DEALTYPE = 'SELL'
	
	select @unallocated = ISNULL(sum(qty), 0) from SCRIPLEDGER where ASSET = @counter
	and ID in (select ledgerid from SCRIPSAFE where CLIENTNO = '0' and CLOSED = 0 and (DATEOUT is null))
	
	select @tsec = ISNULL(sum(qty), 0) from scripshape where ASSET = @counter and TOCLIENT = '0'
	and (NEWCERTNO is null) and CLOSED = 0
	and REFNO in (select REFNO from SCRIPTRANSFER where CLOSED = 0 and CANCELLED = 0)
	
	select @imbalance = (@dueto + @bc) - (@duefrom + @unallocated + @tsec)
	
	insert into tblScripBalancingReport([counter], bought, sold, dueto, duefrom, unallocated, transfersec, balancecertificates, imbalance, username)
	values(@counter, @bot, @sold, @dueto, @duefrom, @unallocated, @tsec, @bc, @imbalance, @user)
	
	fetch next from crcounter into @counter
end
close crcounter
deallocate crcounter


GO
/****** Object:  StoredProcedure [dbo].[spPrintBrokerDeliveries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--spPrintBrokerDeliveries '20120228'
CREATE procedure [dbo].[spPrintBrokerDeliveries]
--@incoming varchar(10),
@date datetime,
@date1 datetime
as

select client = coalesce(c.companyname, c.surname+'  '+c.firstname),
	d.dealdate, d.CERTDUEBY, d.qty, d.dealvalue, d.asset, case sharesout when 0 then 1 else 0 end as settled,
	sd.dealno, sd.[caller], sd.DVDATE, sd.CALLTIME
	from clients c inner join dealallocations d on c.clientno = d.clientno
	left join scripdeliveries sd on d.dealno = sd.dealno
	where sd.cancelled = 0 and d.Approved = 1 and d.Cancelled = 0 and d.Merged = 0
	and dbo.fnFormatDate(sd.DVDATE) >= @date
	and dbo.fnFormatDate(sd.DVDATE) <= @date1
GO
/****** Object:  StoredProcedure [dbo].[spPrintDeliveries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spPrintDeliveries]
@Date datetime,
@Cancelled bit
as
set concat_null_yields_null off
delete from tblDeliveries
insert into tblDeliveries
select ltrim(rtrim(c.title + ' ' + c.firstname + ' ' + c.surname + ' ' + c.companyname)),
	d.Asset,d.Qty,d.consideration, d.dealno,d.dealdate, d.certdueby,s.callee,s.caller, s.calltime,
	case d.sharesout when 0 then convert(bit,1) else convert(bit,0) end, @Date
	from DealAllocations d, clients c, scripdeliveries s
	where (s.dvdate = @Date) and (d.purchasedfrom > 0) and (d.purchasedfrom = c.clientno) 
		and (s.dealno = d.dealno) and (s.cancelled = @Cancelled)
	order by d.asset, d.certdueby



GO
/****** Object:  StoredProcedure [dbo].[spPrintDeliveriesOut]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE procedure [dbo].[spPrintDeliveriesOut]
@Date datetime,
@Cancelled bit
as
set concat_null_yields_null off
delete from tblDeliveries
insert into tblDeliveries
select ltrim(rtrim(c.title + ' ' + c.firstname + ' ' + c.surname + ' ' + c.companyname)),
	d.Asset,d.Qty,d.consideration, d.dealno,d.dealdate, d.certdueby,s.callee,s.caller, s.calltime,
	case d.sharesout when 0 then convert(bit,1) else convert(bit,0) end, @Date
	from DealAllocations d, clients c, scripdeliveries s
	where (s.dvdate = @Date) and (d.soldto > 0) and (d.soldto = c.clientno) 
		and (s.dealno = d.dealno) and (s.cancelled = @Cancelled)
	order by d.asset, d.certdueby
GO
/****** Object:  StoredProcedure [dbo].[spPrintRegistrationReceipt]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--spprintregistrationreceipt 1067

CREATE procedure [dbo].[spPrintRegistrationReceipt]
@id bigint
as
declare @cno varchar(10), @shapeid bigint

truncate table tblRegistrationReceipt
select @cno = toclient from scripshape where id = @id --in (select shapeid from scripledger where id = @id)
--select @shapeid = shapeid from scripledger where id = @id
--if @cno > 0
--begin
-- exec spReceiveRegCustody @id --@shapeid
--end
--else
--begin
-- exec spReceiveRegUnallocated @id --@shapeid
--end

--select @cno as unallocated

if @cno = '0' 
begin
	insert into tblRegistrationReceipt(newcertno, asset, qty, client, ScripDate, regholder, userid)
	select certno, asset, qty, 'UNALLOCATED', cdate, REGHOLDER, USERID
	from SCRIPLEDGER where shapeid = @id --REFNO = @refno
	and REASON = 'TRANSFERRED'
	and INCOMING = 1
	and CANCELLED = 0
end
else
begin
	insert into tblRegistrationReceipt(newcertno, asset, qty, client, ScripDate, regholder, userid)
	select l.certno, l.asset, l.qty, coalesce(c.companyname, c.surname+  '  '+c.firstname), l.cdate, l.REGHOLDER, l.USERID
	from SCRIPLEDGER l inner join clients c on l.clientno = c.clientno 
	where l.SHAPEID = @id--l.REFNO = @refno
	and l.REASON = 'TRANSFERRED'
	and l.INCOMING = 1
	and l.CANCELLED = 0
end

GO
/****** Object:  StoredProcedure [dbo].[spPrintRequisition]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spPrintRequisition] 
@ID bigint
as

set concat_null_yields_null off

delete from tblRequisitions

insert into tblRequisitions([chqid],
	[chqamt],
	[chqdt],
	[payee],
	[enteredby],
	[approvedby],
	[dealno],
	[dealdate],
	[asset],
	[dealtype],
	[qty],
	[price],
	[clientno],
	[client],
	[bank],
	[bankbranch],
	[bankaccno])
select  s.[chqid],
        s.[chqamt],
	s.[chqdt],
	s.[payee],
	s.[enteredby],
	s.[approvedby],
	d.[dealno],
	d.[dealdate],
	d.[asset],
	d.[dealtype],
	d.[qty],
	d.[price],
	c.[clientno],
	c.firstname+' '+c.surname+' '+c.companyname,
	c.[bank],
	c.[bankbranch],
	c.[bankaccno]
/*s.chqid, s.chqamt,s.chqdt, s.payee, s.enteredby, s.approvedby,
d.dealno, d.dealdate, d.asset, d.dealtype, d.asset, d.qty, d.price, c.clientno,
c.firstname+'' ''+c.surname+'' ''+c.companyname, c.bank, c.bankbranch, c.bankaccno*/
from suppchqs s inner join dealallocations d on s.chqid = d.chqrqid
inner join clients c on s.cno = c.clientno
where s.transid = @ID
GO
/****** Object:  StoredProcedure [dbo].[spProcessConsolidationSplit]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author:			Gibson Mhlanga
Creation Date:	2010-11-04
*/
CREATE procedure [dbo].[spProcessConsolidationSplit]
@id bigint,
@ratio float,
@counter varchar(10),
@date datetime,
@user varchar(50)
as
declare @consdate datetime
set concat_null_yields_null off

delete from consolidationdeals where consolid = @id
delete from tblConsolidationUnallocated where consolid = @id
delete from tblConsolidationTransfers where consolid = @id
delete from tblConsolidationCustody where consolid = @id
delete from tblunallocated1sttemptable where username = @user

insert into consolidationdeals(consolid, dealno, dealtype, dealdate, client, origqty, newqty)
select @id, d.dealno, case left(d.dealno, 1)
when 'S' then 'SELL'
else 'BUY' end, d.dealdate, coalesce(c.companyname,c.surname+' '+c.firstname),
d.sharesout, d.sharesout*@ratio
from dealallocations d inner join clients c on d.clientno = c.clientno
where d.approved = 1 and d.cancelled = 0 and d.merged = 0
and d.asset = @counter and dbo.fnFormatDate(d.dealdate) <= @date
and d.sharesout > 0

update consolidations set processed = 1, processdt = getdate()
where id = @id

--transfers
insert into tblConsolidationTransfers(consolid, refno, oqty, nqty, shapeid)
select @id, refno, qty, qty*@ratio, id
from scripshape where (NEWCERTNO is null) and closed = 0
and ASSET = @counter
and REFNO in (select REFNO from SCRIPTRANSFER where CANCELLED = 0 and CLOSED = 0 and dbo.fnFormatDate(DATESENT) <= @date)

--unallocated
select @consdate = dt from CONSOLIDATIONS
where ID = @id

exec spConsolidationSplitUnallocated @id, @user

----client custody
--insert into tblConsolidationCustody(consolid, certno, qty, regholder, client, cdate, newqty)
--select @id, l.certno, l.qty, l.regholder, coalesce(c.companyname, c.surname+' '+c.firstname), l.cdate, QTY*@ratio
--from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
--left join clients c on s.CLIENTNO = c.CLIENTNO
--where l.CDATE <= @date 
--and s.CLOSED = 0
--and (s.DATEOUT is null)
--and s.CLIENTNO <> '0'
--and l.ASSET = @counter
GO
/****** Object:  StoredProcedure [dbo].[spProcessDividend]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
rate in the dividends table is a percentage
*/
CREATE procedure [dbo].[spProcessDividend]
@DividendID bigint,
@user varchar(30)
as

declare @LDR datetime, @rate money, @asset varchar(10), @tax money

select @LDR = LDTR, @rate = RATE, @asset = [counter], @tax = TAX from dividends where ID = @DividendID

if dbo.fnFormatDate(@LDR) > dbo.fnFormatDate(getdate())
	begin
		raiserror('Dividends can only be processed on or after the Last Date To Register!', 11, 1)
		return
	end
	--select * from dividendclaims

--open deals
insert into DIVIDENDCLAIMS(DIVID, CLIENTNO, INCOMING, DEALNO, SHARESOUT, GROSS, TAX, NET, Client, DealDate)
--select @DividendID, d.clientno, case d.dealtype when 'SELL' then 1 else 0 end, d.dealno, d.sharesout, d.sharesout*@rate/100, (d.sharesout*@rate/100)*(@tax), (d.sharesout*@rate/100)-(d.sharesout*@rate/100)*(@tax),
select @DividendID, d.clientno, case d.dealtype when 'SELL' then 1 else 0 end, d.dealno, d.qty, d.qty*@rate/100, (d.qty*@rate/100)*(@tax), (d.qty*@rate/100)-(d.qty*@rate/100)*(@tax),
coalesce(c.companyname, c.surname+'  '+c.firstname), d.dealdate
from Dealallocations d inner join clients c on d.clientno = c.clientno where d.Approved = 1 and d.Cancelled = 0 and d.Merged = 0
and d.asset = @asset
and d.SharesOut > 0
and dbo.fnFormatDate(d.dealdate) <= dbo.fnFormatDate(@LDR)

--deals that were open on the ldr
insert into DIVIDENDCLAIMS(DIVID, CLIENTNO, INCOMING, DEALNO, SHARESOUT, GROSS, TAX, NET, Client, DealDate)
--select @DividendID, d.clientno, case d.dealtype when 'SELL' then 1 else 0 end, d.dealno, d.sharesout, d.sharesout*@rate/100, (d.sharesout*@rate/100)*(@tax), (d.sharesout*@rate/100)-(d.sharesout*@rate/100)*(@tax),
select @DividendID, d.clientno, case d.dealtype when 'SELL' then 1 else 0 end, d.dealno, d.qty, d.qty*@rate/100, (d.qty*@rate/100)*(@tax), (d.qty*@rate/100)-(d.qty*@rate/100)*(@tax),
coalesce(c.companyname, c.surname+'  '+c.firstname), d.dealdate
from Dealallocations d inner join clients c on d.clientno = c.clientno where d.Approved = 1 and d.Cancelled = 0 and d.Merged = 0
and d.asset = @asset
and d.SharesOut = 0
and dbo.fnFormatDate(d.dealdate) <= dbo.fnFormatDate(@LDR)
and d.dealno in (select DealNo from SCRIPDEALSCERTS where dbo.fnFormatDate(dt) >= dbo.fnFormatDate(@LDR))

update DIVIDENDS set PROCESSED = 1, PROCESSDT = GETDATE(), PROCESSUSER = @user
where ID = @DividendID

--scrip in pending sale pool
insert into tblDividendScripInOffice(divid, clientno, certno, qty, gross, tax, net, reason, datereceived, client)
select @DividendID, s.clientno, l.certno, l.qty, l.qty*@rate/100, (l.qty*@rate/100)*(@tax), (l.qty*@rate/100)-((l.qty*@rate/100)*(@tax)), l.reason, l.cdate,
coalesce(c.companyname, c.surname+'  '+c.firstname)
from SCRIPLEDGER l inner join scripsafe s on l.ID = s.LEDGERID
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where (l.REASON like '%SALE')
and l.CANCELLED = 0 and (s.DATEOUT is null) and s.CLOSED = 0
and l.INCOMING = 1 and l.ASSET = @asset
and (s.CLIENTNO not in (select CLIENTNO from CLIENTS where ((CATEGORY = 'broker') or (CATEGORY like 'NMI%'))))

----scrip in unallocated pool that settled SELL deals
--insert into tblDividendScripInOffice(divid, clientno, certno, qty, gross, tax, net, reason, datereceived, client)
--select @DividendID, s.clientno, l.certno, l.qty, l.qty*@rate/100, @tax*l.qty*@rate/100, l.qty*@rate/100 -(@tax*l.qty*@rate/100),l.reason, l.cdate,
--'UNALLOCATED'
--from SCRIPLEDGER l inner join scripsafe s on l.ID = s.LEDGERID
--inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
--where s.CLIENTNO = '0' and l.ASSET = @asset
--and l.CANCELLED = 0 and (s.DATEOUT is null) and s.CLOSED = 0
--and l.INCOMING = 1 and (l.REASON is not null)
--and l.ID in (select LEDGERID from SCRIPDEALSCERTS where SUBSTRING(dealno, 1, 1) = 'S' and CANCELLED = 0)

--scrip in favour registration pool
insert into tblDividendScripInOffice(divid, clientno, certno, qty, gross, tax, net, reason, datereceived, client)
select @DividendID, s.clientno, l.certno, l.qty, (l.qty*@rate/100),(l.qty*@rate/100)*(@tax), (l.qty*@rate/100)-((l.qty*@rate/100)*(@tax)),l.reason, l.cdate,
coalesce(c.companyname, c.surname+'  '+c.firstname)
from SCRIPLEDGER l inner join scripsafe s on l.ID = s.LEDGERID
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where (l.REASON like '%FAV%')
and l.CANCELLED = 0 and (s.DATEOUT is null) and s.CLOSED = 0
and l.INCOMING = 1 and l.ASSET = @asset
and (s.CLIENTNO not in (select CLIENTNO from CLIENTS where ((CATEGORY = 'broker') or (CATEGORY like 'NMI%'))))
--select * from dividends
--scrip in favour registration pool received from tsec
insert into tblDividendScripInOffice(divid, clientno, certno, qty, gross, tax, net, reason, datereceived, client)
select @DividendID, s.clientno, l.certno, l.qty, (l.qty*@rate/100), (l.qty*@rate/100)*(@tax), (l.qty*@rate/100)-((l.qty*@rate/100)*(@tax)),l.reason, l.cdate,
coalesce(c.companyname, c.surname+'  '+c.firstname)
from SCRIPLEDGER l inner join scripsafe s on l.ID = s.LEDGERID
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where (l.REASON like '%TRANSFER%')
and l.CANCELLED = 0 and (s.DATEOUT is null) and s.CLOSED = 0
and l.INCOMING = 1 and l.ASSET = @asset
and (s.CLIENTNO not in (select CLIENTNO from CLIENTS where ((CATEGORY = 'broker') or (CATEGORY like 'NMI%'))))

GO
/****** Object:  StoredProcedure [dbo].[spReceiveRegCustody]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spReceiveRegCustody]
@id bigint
as
set concat_null_yields_null off
--truncate table tblRegistrationReceipt
INSERT INTO [FALCON].[dbo].[tblRegistrationReceipt]
           ([newcertno]
           ,[asset]
           ,[qty]
           ,[issuedate]
           ,[holderno]
           ,[transferno]
		   ,[client]
		   ,clientno
			,dealno)
select ss.newcertno, ss.asset, ss.qty, ss.issuedate, ss.holderno, ss.transferno,
case ss.toclient
when 0 then 'SHAREJOBBING'
else rtrim(ltrim(c.companyname+' '+c.surname+' '+c.firstname))
end, 
ss.toclient, ss.dealno
from scripshape ss inner join clients c on ss.toclient = c.clientno
where (ss.newcertno is not null)
and ss.id = @id
and ss.toclient > 0
and ss.closed = 1
GO
/****** Object:  StoredProcedure [dbo].[spReceiveRegUnallocated]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spReceiveRegUnallocated]
@id bigint
as
set concat_null_yields_null off
--truncate table tblRegistrationReceipt
INSERT INTO [FALCON].[dbo].[tblRegistrationReceipt]
           ([newcertno]
           ,[asset]
           ,[qty]
           ,[issuedate]
           ,[holderno]
           ,[transferno])
select ss.newcertno, ss.asset, ss.qty, ss.issuedate, ss.holderno, ss.transferno
from scripshape ss
where (ss.newcertno is not null)
and ss.id = @id
and ss.toclient = 0
and closed = 1
GO
/****** Object:  StoredProcedure [dbo].[spReceiveScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--spReceiveScrip 'gibs', 'rn0000039'
/*
Creation Date:	17 March 2011
Author:			Gibson Mhlanga
Description:
			if scrip is received for FAVOUR REGISTRATION, then the scrip is sent to the unallocated pool 
			and a favour reg position is created on the client's account. 
			The client is now owed scrip. The position can be settled by scrip returning from transfer secretaries,
			or using scrip from the unallocated pool.
			When the position is settled, scrip is moved into the pending delivery pool
*/
CREATE procedure [dbo].[spReceiveScrip]
@user varchar(30),
@refno varchar(10) out
as

begin tran--saction
--get next ledger reference number
select @refno = dbo.fnGetNextLedgerRef()

--move scrip from the temp table to scripledger
INSERT INTO [SCRIPLEDGER]([REFNO] ,[ITEMNO],[INCOMING],[CDATE],[USERID],[REASON],[CLIENTNO],[CERTNO],[ASSET],[QTY],[REGHOLDER],[ADDRESS] ,[TRANSFORM],[CLOSED] ,[VERIFIED]) 
select @refno , 1, 1, getdate(), @user, reason, clientno, certno, asset, qty, regholder, '', transform, 0, 1 
from tblTempBrokerScrip
where username = @user
commit tran--saction


GO
/****** Object:  StoredProcedure [dbo].[spReceiveScripFromClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--spReceiveScripFromClient '9879','87576','apexl-l',765,1,'uikbn',4739,1,'gibs','forsale','bhjsd','fasf','adsf','ferf'
CREATE procedure [dbo].[spReceiveScripFromClient]
@refno varchar(20),
@certno varchar(20),
@asset varchar(10), 
@qty int,
@itemno int,
@regholder varchar(100),
@clientno int,
@frombroker bit,
@transferform bit,
@user varchar(30),
@reason varchar(50),
@dname varchar(50) = null,
@daddress varchar(100) = null,
@holderno varchar(20) =null,
@transferno varchar(20) = null
as

declare @id bigint
if exists(select certno, asset from scripledger where cancelled = 0 
and asset = @asset and certno = @certno
and id in (select ledgerid from scripsafe
where (dateout is null) and closed = 0))
begin
 raiserror('The specified cetificate number already exists in the system!', 11, 1)
 return
end

INSERT INTO [FALCON].[dbo].[SCRIPLEDGER]
           ([REFNO],[ITEMNO],[INCOMING],[CDATE],[USERID],[REASON],[CLIENTNO],[CERTNO],[ASSET]
           ,[QTY],[REGHOLDER],[TRANSFORM],[DNAME],[DADDRESS],[CLOSED]
           ,[CANCELLED],[VERIFIED],[VERIFYUSER], [VERIFYDT], [HOLDERNO],[TRANSFERNO])
VALUES(@refno, @itemno, 1, getdate(), @user, @reason, @clientno, @certno, @asset, @qty, @regholder, @transferform, @dname, @daddress,
       0,0,1,@user, getdate(), @holderno, @transferno)
     
select @id = max(id) from scripledger
if @frombroker = 1
 begin
  select @clientno = 0
 end
insert into scripsafe(clientno, ledgerid, nominee, datein, dateout, closed)
values(@clientno, @id, 0, getdate(), null, 0)

insert into tblReceivedScrip(id) values(@id)





GO
/****** Object:  StoredProcedure [dbo].[spRemoveBasicCharge]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[spRemoveBasicCharge] 
@Dealno varchar(10)
as
declare @vat  decimal(34,9)

delete from transactions where dealno = @Dealno
and transcode = 'BFEE'
update dealallocations set basiccharges = 0,vat=0.15*commission where dealno = @Dealno 
select  @vat=vat from dealallocations where dealno=@dealno
update transactions set amount=@vat where  dealno=@dealno and transcode='VATCOMM'
GO
/****** Object:  StoredProcedure [dbo].[spRemovePermission]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spRemovePermission]
@profile varchar(50),
@module varchar(50),
@function varchar(50)
as

declare @modid int, @functionid int

select @modid = mid from modules where modname = @module

select @functionid = id from tblscreens where screenname = @function

delete from tblPermissions
where profilename = @profile
and screen = @functionid 
and moduleid = @modid
GO
/****** Object:  StoredProcedure [dbo].[spReprintOutgoingDelivery]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	-reprint outgoing delivery letter
	1. check if the outgoing record has a valid incomingid value
	2. if incomingid > 0 then weking id = incomingid
	3. if incomingid = 0 then, get the id of the incoming record with the same certificate number as the outgoing record.
	
	4. list all the deals settled using the certificate
	5. for each of the deals listed, list the scrip used to settle the deal
*/
--spReprintOutgoingDelivery 36, 'gibs'
CREATE procedure [dbo].[spReprintOutgoingDelivery]
@id bigint,
@user varchar(20)
as

declare @incomingid bigint, @certo varchar(20), @cno varchar(10), @asset varchar(10), @certid bigint, @certno varchar(20), @inid bigint

select @incomingid = incomingid, @certo = certno, @cno = clientno, @asset = asset from scripledger where id = @id
/*
	if id does not exist in scripdealscerts then get the incoming id that was used to settle buy deals
	
*/

if not exists(select ledgerid from SCRIPDEALSCERTS where LEDGERID = @id AND CANCELLED = 0 AND LEFT(DEALNO, 2) = 'B/')
begin
	select @inid = ID from SCRIPLEDGER where incoming = 1 and ASSET = @asset and CERTNO = @certno
end
else
begin
	select @inid = @id
end

if @incomingid > 0
	select @inid = @incomingid
delete from tblBuySettlementDeals where username = @user	
delete from tblBuySettlementScrip where username = @user

--list all the deals settled using the scrip
insert into tblBuySettlementDeals(dealdate, asset, dealno, qty,price, NetConsideration, SettledConsideration, username)
select dealdate, @asset, dealno, qty, price, dealvalue, dealvalue, @user
from DEALALLOCATIONS 
where DealNo in (select DealNo from SCRIPDEALSCERTS where LEDGERID = @inid and CANCELLED = 0 and left(DEALNO, 2) = 'B/')

--list all the scrip used to settle the listed deals
insert into tblBuySettlementScrip(certno, Asset, qty, regholder, clientno, username, refno)
select l.certno, l.asset, l.qty, l.regholder, @cno, @user, l.refno --l.clientno
from SCRIPLEDGER l
where l.ID in (select ledgerid from SCRIPDEALSCERTS where cancelled = 0 and (CANCELDT is null) and dealno in (select DEALNO from tblBuySettlementDeals where username = @user))


GO
/****** Object:  StoredProcedure [dbo].[spReprintRegistrationReceipt]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spReprintRegistrationReceipt]
@refno varchar(20)
as
declare @cno varchar(10)

truncate table tblRegistrationReceipt
select @cno = clientno from SCRIPLEDGER 
where REFNO = @refno

if @cno = '0' 
begin
	insert into tblRegistrationReceipt(newcertno, asset, qty, client, ScripDate, regholder, userid)
	select certno, asset, qty, 'UNALLOCATED', cdate, REGHOLDER, USERID
	from SCRIPLEDGER where REFNO = @refno
	and REASON = 'TRANSFERRED'
	and INCOMING = 1
	and CANCELLED = 0
end
else
begin
	insert into tblRegistrationReceipt(newcertno, asset, qty, client, ScripDate, regholder, userid)
	select l.certno, l.asset, l.qty, coalesce(c.companyname, c.surname+  '  '+c.firstname), l.cdate, l.REGHOLDER, l.USERID
	from SCRIPLEDGER l inner join clients c on l.clientno = c.clientno 
	where l.REFNO = @refno
	and l.REASON = 'TRANSFERRED'
	and l.INCOMING = 1
	and l.CANCELLED = 0
end


GO
/****** Object:  StoredProcedure [dbo].[spReverseContra]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[spReverseContra]
@odeal varchar(10),
@mdeal varchar(10), 
@user varchar(50) = null
as
declare @qty int, @deal varchar(10), @odeal1 varchar(10), @mdeal1 varchar(10)

select @mdeal1 = @mdeal --substring(@mdeal, 2, len(@mdeal)-2)
select @odeal1 = @odeal
declare crdeal cursor for 
select origdealno, matchdealno, qtyused from scripdealscontra
where (((origdealno = @odeal) and (matchdealno = @mdeal))
or ((origdealno = @mdeal) and (matchdealno = @odeal)))
and cancelled = 0


open crdeal
fetch next from crdeal into @odeal1, @mdeal1, @qty
while @@fetch_status = 0
begin
 update dealallocations set sharesout = sharesout + @qty where dealno in (@odeal1, @mdeal1)
 update scripdealscontra set cancelled = 1, canceldt = getdate(), canceluser = @user
 where ((origdealno = @odeal1) and (matchdealno = @mdeal1))
or ((origdealno = @mdeal1) and (matchdealno = @odeal1))
fetch next from crdeal into @odeal1, @mdeal1, @qty
end
close crdeal
deallocate crdeal
GO
/****** Object:  StoredProcedure [dbo].[spReverseContraSettlement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
<Author>		Gibson Mhlanga
<Creation Date>	10-11-2010
<Description>

*/

CREATE procedure [dbo].[spReverseContraSettlement]
@odealno varchar(10),
@mdealno varchar(10),
@reason varchar(50),
@user varchar(30)
as
declare @odeal varchar(10), @mdeal varchar(10), @qty int, @counter varchar(10)

select @qty = qtyused from SCRIPDEALSCONTRA
where cancelled = 0
and ((ORIGDEALNO = @odealno and MATCHDEALNO = @mdealno) or (ORIGDEALNO = @mdealno and MATCHDEALNO = @odealno))

update Dealallocations set SharesOut = SharesOut + @qty
where DealNo in (@odealno, @mdealno)

update SCRIPDEALSCONTRA set CANCELLED = 1, CANCELDT = GETDATE(), CANCELREF = @reason, CANCELUSER = @user
where ((ORIGDEALNO = @odealno and MATCHDEALNO = @mdealno) or (ORIGDEALNO = @mdealno and MATCHDEALNO = @odealno))

--increase both dueto and duefrom in tblScripBalancing table
select @counter = asset from Dealallocations where DealNo = @odealno
update tblScripBalancing set duefrom = duefrom + @qty, dueto = dueto + @qty
where [counter] = @counter

if exists(select dealno from DEALALLOCATIONS where DealNo = @odealno and SHARESOUT > Qty)
begin
	update DEALALLOCATIONS set SHARESOUT = Qty where DealNo = @odealno
end
if exists(select dealno from DEALALLOCATIONS where DealNo = @mdealno and SHARESOUT > Qty)
begin
	update DEALALLOCATIONS set SHARESOUT = Qty where DealNo = @mdealno
end
GO
/****** Object:  StoredProcedure [dbo].[spReverseCSDSettlement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spReverseCSDSettlement]
@sdeal varchar(10)
,@mdeal varchar(10)
,@user varchar(50)
as
declare @qty int, @buydeal varchar(10), @selldeal varchar(10)
declare @sellamount money, @buyamount money, @cno varchar(10), @csdtxn bit

--get the quantity used in the settlement
select @qty = qtyused from tblCSDSettlementDetails
where cancelled = 0
and (((origdealno = @mdeal) or (origdealno = @sdeal)) or ((matchdealno = @mdeal) or (matchdealno = @sdeal)))

--cancel the entry in the csd settlements list
update tblCSDSettlementDetails set cancelled = 1, canceldate = GETDATE(), canceluser = @user
where (((origdealno = @mdeal) or (origdealno = @sdeal)) or ((matchdealno = @mdeal) or (matchdealno = @sdeal)))

--reopen the deals by the settlement qty
update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @qty
where DealNo in (@sdeal, @mdeal)

--post reversal financial transactions
if LEFT(@sdeal, 1) = 'S'
	begin
		select @selldeal = @sdeal, @buydeal = @mdeal
		select @sellamount = amount, @cno = clientno from CASHBOOKTRANS where DealNo = @selldeal
		and TransCode = 'PAY'	
	end
else
begin
	select @selldeal = @mdeal, @buydeal = @sdeal
	select @buyamount = amount, @cno = clientno from CASHBOOKTRANS where DealNo = @buydeal
	and TransCode = 'REC'
end

--reverse cash txn transaction if system is configured to post cash txn on deal settlement
select @csdtxn = CSDTxnOnSettlement from BusinessRules	

if @csdtxn = 1
begin
	insert into CASHBOOKTRANS(ClientNo, PostDate, DealNo, TransCode, TransDate, [description], Amount, CASH, CASHBOOKID, Cancelled, ExCurrency, ExRate, ExAmount, YON)
	select clientno, GETDATE(), @selldeal, 'PAYCNL', dbo.fnformatdate(GETDATE()), 'PAYMENT CANCELLATION', -1*DealValue, 1, 1, 0, 'USD', 1, -1*DealValue, 1
	from DEALALLOCATIONS where DealNo = @selldeal

	insert into CASHBOOKTRANS(ClientNo, PostDate, DealNo, TransCode, TransDate, [description], Amount, CASH, CASHBOOKID, Cancelled, ExCurrency, ExRate, ExAmount, YON)
	select clientno, GETDATE(), @buydeal, 'RECCNL', dbo.fnformatdate(GETDATE()), 'RECEIPT CANCELLATION', DealValue, 1, 1, 0, 'USD', 1, dealvalue, 1
	from DEALALLOCATIONS where DealNo = @buydeal
end
GO
/****** Object:  StoredProcedure [dbo].[spReverseDealSettlement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spReverseDealSettlement]
@dealno varchar(10),
@id bigint
as

declare @asset varchar(10), @qty int, @dno varchar(10)

select @asset = asset from DEALALLOCATIONS 
where DealNo = @dealno

if @dealno like 'B%'
begin
	declare crdeals cursor for 
	select dealno, qtyused from scripdealscerts
	where ledgerid = @id
	and (dealno like 'B%')
end

--get all the buy deals settled using the certificate
open crdeals
fetch next from crdeals into @dno, @qty
while @@FETCH_STATUS = 0
begin
	update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @qty
	where DealNo = @dno
	update SCRIPDEALSCERTS set CANCELLED = 1, CANCELDT = GETDATE()
	where DealNo = @dno
	fetch next from crdeals into @dno, @qty
end
close crdeals
deallocate crdeals

--return the scrip to unallocated
update SCRIPSAFE set ClientNo = '0', DATEOUT = null, CLOSED = 0
where LEDGERID = @id
GO
/****** Object:  StoredProcedure [dbo].[spReverseScripSettlement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:		Gibson Mhlanga
	Date Created:	Jan 2011
	Revision Date:	02 November 2011
	
	Description:
	The incoming id is the id of the certificate that is saved in the ScripDealsCerts table as the settlement record.
	For broker/nmi buy deals, the old version used to save the scripledger id of the outgoing record which is not the 
	id in the ScripSafe table. Therefore for such cases, get the id of the incoming record with the same certificate number 
	as the outgoing one.
	
	Reversing a buy deal setllement will return the scrip to the unallocated pool. If the scrip came from transfer secretaries
	then scrip is not returned to unallocated pool but the registration is reopened
	
	Reversing a sell deal settlement will return the scrip to client custody if it is a client deal. If it's a broker/nmi sell
	deal, the scrip is taken out of the system and the scrip receipt record is cancelled.
*/

CREATE procedure [dbo].[spReverseScripSettlement] 
@dealno varchar(10), @id bigint, @user varchar(20)
as

declare @cno varchar(10), @in bit, @dno varchar(10), @qtyused int, @certqty int, @dqty int
declare @incid bigint, @certno varchar(10), @asset varchar(10)

select @certqty = qty, @asset = ASSET, @certno = CERTNO from SCRIPLEDGER where ID = @id

if LEFT(@dealno, 2) = 'B/' --BUY deal
begin
	select @cno = clientno from DEALALLOCATIONS where DealNo = @dealno
	
	--list all buy deals settled using the scrip
	declare crid cursor for
	select dealno, qtyused from scripdealscerts
	where ledgerid = @id and left(dealno, 2) = 'B/'
	and cancelled = 0
	open crid
	fetch next from crid into @dno, @qtyused
	while @@fetch_status = 0
	begin
		if @qtyused > 0
		begin
			update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @qtyused 
			where DealNo = @dno
		end
		else if @qtyused = 0 --no certificate qty saved with the settlement record
		begin
			select @dqty = qty from DEALALLOCATIONS where DealNo = @dno
			if @dqty >= @certqty
			begin
				update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @certqty
				where DealNo = @dno
			end
			else
			begin 
				update DEALALLOCATIONS set SHARESOUT = Qty 
				where DealNo = @dno
			end
		end
	fetch next from crid into @dno, @qtyused
	end
	close crid
	deallocate crid
			
	--cancel the settlement record of the scrip
	update SCRIPDEALSCERTS set CANCELLED = 1, CANCELDT = GETDATE(), CANCELUSER = @user,
	CANCELREF = 'BUY SETTLEMENT REVERSAL'
	where LEDGERID = @id and LEFT(dealno, 2) = 'B/'
		
	--return the scrip to unallocated pool
	--check if the settlement record scrip id is for an incoming/outgoing certificate
	select @in = incoming from SCRIPLEDGER 
	where id = @id
		
	if @in = 1
	begin
		update SCRIPSAFE set DATEOUT = null, CLOSED = 0, CLIENTNO = '0'
		where LEDGERID = @id
	end 
	else --get the id of the incoming scrip with the same cert # as the outgoing scrip and return it to unallocated pool
	begin
		select @incid = id from SCRIPLEDGER where incoming = 1
		and ASSET = @asset and CERTNO = @certno
		update SCRIPSAFE set DATEOUT = null, CLOSED = 0, CLIENTNO = '0'
		where LEDGERID = @incid
	end	
end
else --sell settlement reversal
begin
	select @cno = clientno from DEALALLOCATIONS where DealNo = @dealno
	
	--list all buy deals settled using the scrip
	declare crid cursor for
	select dealno, qtyused from scripdealscerts
	where ledgerid = @id and left(dealno, 2) = 'S/'
	and cancelled = 0
	
	open crid
	fetch next from crid into @dno, @qtyused
	while @@fetch_status = 0
	begin
		if @qtyused > 0
		begin
			update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @qtyused 
			where DealNo = @dno
		end
		else if @qtyused = 0 --no certificate qty saved with the settlement record
		begin
			select @dqty = qty from DEALALLOCATIONS where DealNo = @dno
			if @dqty >= @certqty
			begin
				update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @certqty
				where DealNo = @dno
			end
			else
			begin 
				update DEALALLOCATIONS set SHARESOUT = Qty 
				where DealNo = @dno
			end
		end
	fetch next from crid into @dno, @qtyused
	end
	close crid
	deallocate crid
			
	--cancel the settlement record of the scrip
	update SCRIPDEALSCERTS set CANCELLED = 1, CANCELDT = GETDATE(), CANCELUSER = @user,
	CANCELREF = 'SELL SETTLEMENT REVERSAL'
	where LEDGERID = @id and LEFT(dealno, 2) = 'S/'
	
	--if broker/nmi sell deal then take scrip out of the system, cancel receipt record
	--if other client sell deal then return scrip to client's custody
	if exists(select clientno from CLIENTS where ClientNo = @cno and ((CATEGORY = 'BROKER') or (CATEGORY like 'NMI%')))
	begin
		update SCRIPSAFE set DATEOUT = GETDATE(), CLOSED = 1
		where LEDGERID = @id
		update SCRIPLEDGER set CANCELLED = 1, CANCELDT = GETDATE(), CANCELREASON = 'SELL SETTLEMENT REVERSAL', CANCELUSER = @user
		where ID = @id
	end
	else
	begin
		update SCRIPSAFE set CLIENTNO = @cno, DATEOUT = null, CLOSED = 0
		where LEDGERID = @id
	end
end

if exists(select dealno from DEALALLOCATIONS where DealNo = @dealno and SHARESOUT > Qty)
begin
	update DEALALLOCATIONS set SHARESOUT = Qty where DealNo = @dealno
end
GO
/****** Object:  StoredProcedure [dbo].[spReverseSettlementIn]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spReverseSettlementIn]
@id bigint,
@user varchar(50),
@reason varchar(50)
as
declare @dealno varchar(10), @qty int, @qtyused int, @cno int
declare crdeal cursor for
select dealno, qtyused from scripdealscerts
where ledgerid = @id
and cancelled = 0

open crdeal
fetch next from crdeal into @dealno, @qtyused

while @@fetch_status = 0
begin
 if @qtyused > 0
 begin
  update dealallocations set sharesout = sharesout + @qtyused
  where dealno = @dealno
 end
 else
  begin
   update dealallocations set sharesout = qty
   where dealno = @dealno
  end
 fetch next from crdeal into @dealno, @qtyused
end
close crdeal
deallocate crdeal

--check if scrip was from broker or nmi and if so take scrip from system
--if scrip if from a normal client then return the scrip to the client custody
select @cno = purchasedfrom from dealallocations where dealno = @dealno
if exists(select clientno from clients where clientno = @cno and ((category ='broker') or (category like 'nmi%')))
begin
 update scripsafe set dateout = getdate(), closed = 1
 where ledgerid = @id
end
else
begin
 update scripsafe set clientno = @cno, dateout = null, closed = 0
 where ledgerid = @id
end

--cancel the settlement details
update scripdealscerts set cancelled = 1, canceldt = getdate(), canceluser = @user, cancelref = @reason
where ledgerid = @id
GO
/****** Object:  StoredProcedure [dbo].[spReverseSettlementOut]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spReverseSettlementOut]
@id bigint,
@user varchar(50),
@reason varchar(50)
as
declare @dealno varchar(10), @qty int, @qtyused int, @cno int
declare crdeal cursor for
select dealno, qtyused from scripdealscerts
where ledgerid = @id
and cancelled = 0

open crdeal
fetch next from crdeal into @dealno, @qtyused

while @@fetch_status = 0
begin
 if @qtyused > 0
 begin
  update dealallocations set sharesout = sharesout + @qtyused
  where dealno = @dealno
 end
 else
  begin
   update dealallocations set sharesout = qty
   where dealno = @dealno
  end
 fetch next from crdeal into @dealno, @qtyused
end
close crdeal
deallocate crdeal

--return scrip to unallocated pool
 update scripsafe set clientno = 0, dateout = null, closed = 0
 where ledgerid = @id
--cancel the settlement details
update scripdealscerts set cancelled = 1, canceldt = getdate(), canceluser = @user, cancelref = @reason
where ledgerid = @id
GO
/****** Object:  StoredProcedure [dbo].[spReverseSharesReceipt]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[spReverseSharesReceipt]
as
update scripledger set cancelled = 1, canceldt = getdate()
where id in (select id from tblScripLedgerID)
 
update scripsafe set dateout = getdate(), closed = 1
where ledgerid in (select id from tblScripLedgerID)

update scripshape set newcertno = '', issuedate = null, holderno = '', transferno = '', closed = 0 
where id in (select id from tblScripShapeID)

update scriptransfer set closed = 0
where refno in (select refno from scripshape where closed = 0)
delete from tblScripShapeID
delete from tblScripLedgerID


GO
/****** Object:  StoredProcedure [dbo].[spReverseSharesReceived]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spReverseSharesReceived]
@id bigint,
@user varchar(20),@cancelreason varchar(20)
as
declare @reason varchar(50), @dealno varchar(10), @qty int, @shapeid bigint, @counter varchar(10)

select @reason = reason, @counter = asset from scripledger where id = @id
if @reason = 'TRANSFERRED'
begin
	if exists(select dealno from scripdealscerts where ledgerid = @id) --certificate was used to settle deals
		begin
			declare crDeals cursor for 
			select dealno, qtyused from scripdealscerts where ledgerid = @id
			open crDeals
			fetch next from crDeals into @dealno, @qty
			while @@fetch_status = 0
				begin
					if substring(@dealno, 1, 1) = 'B' --settled a DUE-TO position
						begin
							update dealallocations set sharesout = sharesout + @qty
							where dealno = @dealno
							update SCRIPDEALSCERTS set CANCELLED = 1, CANCELDT = GETDATE(), CANCELREF = 'SHARES RECEIPT REVERSED'
							where LEDGERID = @id
							update tblScripBalancing set dueto = dueto + @qty, transfersec = transfersec + @qty
							where [counter] = @counter
						end
					if substring(@dealno, 1, 1) = 'S' -- settle a balance certificate position
						begin
							update tblDealBalanceCertificates set balremaining = balremaining + @qty, closed = 0
							where dealno = @dealno
							update tblScripBalancing set balancecertificates = balancecertificates + @qty, transfersec = transfersec + @qty
							where [counter] = @counter
						end
					fetch next from crDeals into @dealno, @qty
				end
			close crDeals
			deallocate crDeals	
		end
	--get the shape id and reopen the shape and the registration
	select @shapeid = shapeid from scripledger where id = @id
	update scripshape set newcertno = null, closed = 0, issuedate = null
	where id = @shapeid
	update scriptransfer set closed = 0 where refno in (select refno from scripshape where id = @shapeid)
end
else
begin
	if exists(select dealno from scripdealscerts where ledgerid = @id)
		begin
			--reopen all the deals settled using the selected certificate
			declare crDeals cursor for 
			select dealno, qtyused from scripdealscerts where ledgerid = @id
			open crDeals
			fetch next from crDeals into @dealno, @qty
			while @@fetch_status = 0
				begin
					update dealallocations set sharesout = sharesout + @qty
					where dealno = @dealno
					fetch next from crDeals into @dealno, @qty
					update tblScripBalancing set duefrom = duefrom + @qty, unallocated = unallocated - @qty
					where [counter] = @counter
				end
			close crDeals
			deallocate crDeals
			--cancel the settlement record for the selected certifcate
			update scripdealscerts set cancelled = 1, canceldt = getdate(), canceluser = @user
			where ledgerid = @id
		end
end
	--take it out of the system
			update scripsafe set dateout = getdate(), closed = 1 where ledgerid = @id
			update scripledger set cancelled = 1, canceldt = getdate(), canceluser = @user, cancelreason = 'SCRIP RECEIPT CANCELLED'
			where id = @id

GO
/****** Object:  StoredProcedure [dbo].[spReverseSharesSent]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Created by:		Gibson Mhlanga
	Date Created:	November 2010
	
	Revised:		03 November 2011
	
	Description:
	The procedure reverses the scrip delivered out to a client. If the client is a broker/nmi, the scrip is returned to the
	unallocated pool and each of the buy deals settled using the scrip is partly opened by the quantity from the scrip that 
	was used to settle the deal, i.e. the QtyUsed value in the Scripdealscerts table for the scrip id.
	
	If the client is not a broker/nmi, then the scrip is returned to the client's account but the buy deal remains closed. The
	client's deal can only be opened by manually selecting to reverse the settlement.
	
	NB: Older broker deals used to store the id of the outgoing scrip in Scripdealscerts table, the system now uses the id of the incoming scrip 
	in the Scripdealscerts table
	
		For older broker/nmi deals get the incoming scrip with the same certificate number as the outgoing scrip and return that
		id to the unallocated pool
*/

CREATE procedure [dbo].[spReverseSharesSent]
@id bigint,@user varchar(30), @reason varchar(50)
as


declare @cno varchar(10), @setid bigint, @asset varchar(10), @certno varchar(20), @qtyused int, @dealno varchar(10), @dqty int, @certqty int
declare @incoming bit, @lid bigint, @ogqty int, @shout int

select @cno = clientno, @asset = ASSET, @certno = CERTNO, @incoming = incoming, @certqty = qty from SCRIPLEDGER where ID = @id

if exists(select clientno from CLIENTS where ClientNo = @cno and ((CATEGORY = 'BROKER') or (LEFT(category, 3) = 'NMI')))
begin
	--if @id is not saved in scripdealscerts, then get the id of the incoming scrip as the settlement id
	if not exists(select ledgerid from SCRIPDEALSCERTS where LEDGERID = @id and LEFT(dealno, 2) = 'B/' and CANCELLED = 0)
	begin
		select @setid = id from SCRIPLEDGER where ASSET = @asset and CERTNO = @certno and incoming = 1 
		and CANCELLED = 0 and verified = 1
	end
	else --the incoming id is the settlement id
	begin
		select @setid = @id
	end
	
	--list the buy deals settled using the scrip
	declare crdealno cursor for
	select dealno, qtyused from SCRIPDEALSCERTS
	where LEDGERID = @setid and LEFT(dealno, 2) = 'B/'
	and CANCELLED = 0
	
	open crdealno
	fetch next from crdealno into @dealno, @qtyused
	
	while @@fetch_status = 0
	begin
		if @qtyused > 0
		begin
		--if shareout + qtyused <= deal qty then add qtyused to sharesout, else set sharesout equal to deal qty
			select @ogqty = qty, @shout = SHARESOUT from dealallocations where DealNo = @dealno
			if(@shout + @qtyused) <= @ogqty
				begin
					update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @qtyused 
					where DealNo = @dealno
				end
			else
				begin
					update dealallocations set SHARESOUT = Qty 
					where DealNo = @dealno
				end
		end
		else if @qtyused = 0 --no certificate qty saved with the settlement record
		begin
			select @dqty = qty from DEALALLOCATIONS where DealNo = @dealno
			if @dqty >= @certqty
			begin
				update DEALALLOCATIONS set SHARESOUT = SHARESOUT + @certqty
				where DealNo = @dealno
			end
			else
			begin 
				update DEALALLOCATIONS set SHARESOUT = Qty 
				where DealNo = @dealno
			end
		end
		fetch next from crdealno into @dealno, @qtyused
	end
	close crdealno
	deallocate crdealno
	
	--cancel the outgoing delivery record
	update SCRIPLEDGER set CANCELLED = 1, CANCELDT = GETDATE(), CANCELUSER = @user,
	cancelreason = @reason where ID = @id
	
	--return the scrip to unallocated pool
	if @incoming = 1
		select @lid = @id
	else
	begin
		--select '@asset = '+@asset+'  certno =  '+@certno
		select @lid = id from SCRIPLEDGER where ASSET = @asset and CERTNO = @certno and incoming = 1 
		and CANCELLED = 0 and verified = 1
	end
	--select ' lid  '+ cast(@lid as varchar(10))
	update SCRIPSAFE set DATEOUT = null, CLOSED = 0, CLIENTNO = '0'
	where LEDGERID = @lid      
	
	--cancel scrip's buy settlement record(s)
	update SCRIPDEALSCERTS set CANCELLED = 1, CANCELDT = GETDATE(), CANCELUSER = @user, CANCELREF = 'SHARES SENT REVERSAL'
	where LEDGERID = @setid and CANCELLED = 0 and LEFT(dealno, 2) = 'B/'	                                                                                                              
end
else --scrip was delivered to other client, therefore return scrip to client custody and cancel delivery record
begin
	select @lid = id from SCRIPLEDGER where incoming = 1 and CANCELLED = 0 
	and ASSET = @asset and CERTNO = @certno and VERIFIED = 1
	
	--cancel delivery record
	update SCRIPLEDGER set CANCELLED = 1, CANCELDT = GETDATE(), CANCELUSER = @user, CANCELREASON = 'SHARES SENT REVERSAL'
	where ID = @id and CANCELLED = 0
	
	--return scrip into the system
	update SCRIPSAFE set CLIENTNO = @cno, DATEOUT = null, CLOSED =  0
	where LEDGERID = @lid
end
GO
/****** Object:  StoredProcedure [dbo].[spSafeCustodyScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spSafeCustodyScrip]
@startclient varchar(50) = null,
@endclient varchar(50) = null
as

declare @id bigint, @certno varchar(30), @asset varchar(10), @rec bigint, @trans bit, @qty int, @date datetime, @cno varchar(10), @reg varchar(50), @client varchar(50)
declare @user varchar(20), @ref varchar(30)

truncate table tblScrippool
truncate table tbltempid
truncate table tblTempSafeCustody

insert into tblTempSafeCustody(id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, reference)
select l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname, c.surname+' '+c.firstname) as client, l.userid, l.refno as reference 
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1 
and (l.REASON like 'SAFE%') 
and (s.ClientNo in (select CLIENTNO from CLIENTS where left(DELIVERYOPTION, 4) = 'SAFE')) 
and (s.DATEOUT is null) 
and s.CLOSED = 0

--//scrip used to settle safe custody client's buy deals
insert into tblTempSafeCustody(id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, reference)
select l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname, c.surname+' '+c.firstname) as client, l.userid, sd.dealno as reference 
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join scripdealscerts sd on l.id = sd.ledgerid 
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1 
and left(sd.dealno, 2) = 'B/' and sd.cancelled = 0
and (s.ClientNo in (select CLIENTNO from CLIENTS where left(DELIVERYOPTION, 4) = 'SAFE')) 
and (s.DATEOUT is null) 
and s.CLOSED = 0

--//scrip received from tsec into safe custody without settling buy deals
insert into tblTempSafeCustody(id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, reference)
select l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname, c.surname+' '+c.firstname) as client, l.userid, ss.refno as reference 
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join scripshape ss on l.shapeid = ss.id 
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1 and l.id not in (select ledgerid from scripdealscerts where left(dealno, 2) = 'B/' and cancelled = 0) 
--and (s.ClientNo in (select CLIENTNO from CLIENTS where left(DELIVERYOPTION, 4) = 'SAFE')) 
and LEFT(l.clientno, 4) = 'SAFE'
and (s.DATEOUT is null) 
and s.CLOSED = 0 

truncate table tblTempSafe
insert into tblTempSafe
select id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid from tbltempsafecustody
group by id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid
having COUNT(id) > 1
delete from tbltempsafecustody 
where id in (select id from tbltempsafecustody
group by id
having COUNT(id) > 1)
--remove duplicates
declare crDup cursor for 
select recid, id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid
from tbltempSafe
open crDup
fetch next from crDup into @rec, @id, @certno, @asset, @qty, @date, @trans, @cno, @reg, @client, @user
while @@FETCH_STATUS = 0
begin
	if not exists(select id from tblTempSafeCustody where id = @id and asset = @asset and certno = @certno)
	begin
		select @ref = dealno from SCRIPDEALSCERTS where LEDGERID = @id and LEFT(dealno, 1) = 'B'
		insert into tblTempSafeCustody(id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, reference)
		select id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, @ref
		from tblTempSafe
		where recid = @rec
	end
fetch next from crDup into @rec, @id, @certno, @asset, @qty, @date, @trans, @cno, @reg, @client, @user
end
close crDup
deallocate crDup

select * from tblTempSafeCustody order by asset, cdate, qty


GO
/****** Object:  StoredProcedure [dbo].[spSaveSettlement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spSaveSettlement]
@settledate datetime
,@amount money
as

declare @account int

select @account = isnull(cdcsettlementaccount, 0) from tblSystemParams

if @account = 0
begin
	raiserror('Settlement account has not been configured. Contact your administrator', 11, 1)
	return
end

insert into cashbooktrans(clientno, postdate, transcode, transdate, description, amount, cashbookid, yon)
values(@account, getdate(), 'REC', @settledate, 'RECEIPT FROM CDC', @amount, @account, 1)

GO
/****** Object:  StoredProcedure [dbo].[spScripBalancingProcess]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
	Author:		Gibson Mhlanga
	Creation Date:	2010-11-05

	Description
	Keeps track of the scrip balancing on every process involving scrip
*/

create procedure [dbo].[spScripBalancingProcess]
@transcode varchar(20),
@qty int,
@balanceqty int = 0, 
@counter varchar(10)
as

if @transcode = 'SALE'
	begin
		if not exists(select [counter] from tblScripbalancing where [counter] = @counter)
			begin
				INSERT INTO tblScripBalancing([counter],bought,sold,dueto,duefrom,unallocated, transfersec,balancecertificates)
				VALUES(@counter, 0, @qty, 0, @qty, 0, 0, 0)
			end
		else
			begin
				update tblScripBalancing set sold = sold + @qty, duefrom = duefrom + @qty
				where [counter] = @counter
			end
	end
else if @transcode = 'PURCH'
	begin
		if not exists(select [counter] from tblScripbalancing where [counter] = @counter)
			begin
				INSERT INTO tblScripBalancing([counter],bought,sold,dueto,duefrom,unallocated, transfersec,balancecertificates)
				VALUES(@counter, @qty, 0, @qty, 0, 0, 0, 0)
			end
		else
			begin
				update tblScripBalancing set bought = bought + @qty, dueto = dueto + @qty
				where [counter] = @counter
			end
	end
else if @transcode = 'SALECLOSE'
		begin
			if exists(select [counter] from tblScripBalancing where [counter] = @counter)
			begin
				update tblscripbalancing set duefrom = duefrom - (@qty - @balanceqty),
				balancecertificates = balancecertificates + @balanceqty, unallocated = unallocated - (@qty - @balanceqty)
				where [counter] = @counter
			end
			else
			begin
				INSERT INTO tblScripBalancing([counter],bought,sold,dueto,duefrom,unallocated, transfersec,balancecertificates)
				VALUES(@counter, 0, @qty, 0, 0, @qty, 0, 0)
			end
		end
else if @transcode = 'PURCHCLOSE'
	begin
		if exists(select [counter] from tblScripBalancing where [counter] = @counter)
			begin
				update tblscripbalancing set dueto = dueto - @qty, unallocated = unallocated - @qty
				where [counter] = @counter
			end
		else
			begin
				INSERT INTO tblScripBalancing([counter],bought,sold,dueto,duefrom,unallocated, transfersec,balancecertificates)
				VALUES(@counter, @qty, 0, 0, 0, 0, 0, 0)			
			end		
	end
else if @transcode = 'SALECNL'
	begin
		if exists(select [counter] from tblScripBalancing where [counter] = @counter)
			begin
				update tblscripbalancing set duefrom = duefrom - @qty, sold = sold - @qty
				where [counter] = @counter
			end
	end
else if @transcode = 'PURCHASECNL'
	begin
		if exists(select [counter] from tblScripBalancing where [counter] = @counter)
			begin
				update tblscripbalancing set dueto = dueto - @qty, bought = bought - @qty
				where [counter] = @counter
			end
	end
else if @transcode = 'REGOUT'
	begin
		update tblScripBalancing set unallocated = unallocated - @qty, transfersec = transfersec + @qty
		where [counter] = @counter
	end
else if @transcode = 'REGIN'
	begin
		update tblScripBalancing set unallocated = unallocated + @qty, transfersec = transfersec - @qty
		where [counter] = @counter
	end
else if @transcode = 'BALON'
	begin
		update tblScripBalancing set balancecertificates = balancecertificates + @qty
		where [counter] = @counter
	end
else if @transcode = 'BALOFF'
	begin
		update tblScripBalancing set balancecertificates = balancecertificates - @qty
		where [counter] = @counter
	end	

GO
/****** Object:  StoredProcedure [dbo].[spScripBalancingReport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--spScripBalancingReport 'aicoa-l', 'aicoa-l'
CREATE procedure [dbo].[spScripBalancingReport]
@counter1 varchar(10),
@counter2 varchar(20),
@user varchar(20)
as

declare @dueto int, @duefrom int, @bc int, @unallocated int, @tsec int, @counter varchar(10), @imbalance int
declare @bot int, @sold int

declare crcounter cursor for
select assetcode from assets
where assetcode >= @counter1
and assetcode <= @counter2
--select * from tblScripBalancingReport
open crcounter

fetch next from crcounter into @counter
delete from tblScripBalancingReport where (username = @user) or (username is null)
while @@FETCH_STATUS = 0
begin
	select @bot = ISNULL(sum(qty), 0) from DEALALLOCATIONS where ASSET = @counter
	and APPROVED = 1 and CANCELLED = 0 and MERGED = 0 and DEALTYPE = 'BUY'
	
	select @sold = ISNULL(sum(qty), 0) from DEALALLOCATIONS where ASSET = @counter
	and APPROVED = 1 and CANCELLED = 0 and MERGED = 0 and DEALTYPE = 'SELL'
	
	select @dueto = ISNULL(sum(sharesout), 0) from DEALALLOCATIONS where ASSET = @counter
	and SHARESOUT > 0 and APPROVED = 1 and CANCELLED = 0 and MERGED = 0
	and DEALTYPE = 'BUY'
	
	select @bc = ISNULL(sum(balremaining), 0) from tblDealBalanceCertificates where BalRemaining > 0 and Cancelled = 0 and Closed = 0
	and dealno in (select dealno from DEALALLOCATIONS where ASSET = @counter)
	
	select @duefrom = ISNULL(sum(sharesout), 0) from DEALALLOCATIONS where ASSET = @counter
	and SHARESOUT > 0 and APPROVED = 1 and CANCELLED = 0 and MERGED = 0
	and DEALTYPE = 'SELL'
	
	select @unallocated = ISNULL(sum(qty), 0) from SCRIPLEDGER where ASSET = @counter
	and ID in (select ledgerid from SCRIPSAFE where CLIENTNO = '0' and CLOSED = 0 and (DATEOUT is null))
	
	select @tsec = ISNULL(sum(qty), 0) from scripshape where ASSET = @counter and TOCLIENT = '0'
	and (NEWCERTNO is null) and CLOSED = 0
	and REFNO in (select REFNO from SCRIPTRANSFER where CLOSED = 0 and CANCELLED = 0)
	
	select @imbalance = (@dueto + @bc) - (@duefrom + @unallocated + @tsec)
	
	insert into tblScripBalancingReport([counter], bought, sold, dueto, duefrom, unallocated, transfersec, balancecertificates, imbalance, username)
	values(@counter, @bot, @sold, @dueto, @duefrom, @unallocated, @tsec, @bc, @imbalance, @user)
	
	fetch next from crcounter into @counter
end
close crcounter
deallocate crcounter

GO
/****** Object:  StoredProcedure [dbo].[spScripBalancingSnapShot]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spScripBalancingSnapShot]
@user varchar(20)
as
select 'COUNTERS',
(select COUNT(*) from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX')) as active,
(select COUNT(*) from tblScripBalancingReport where imbalance = 0 and username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as balanced,
(select COUNT(*) from tblScripBalancingReport where imbalance <> 0 and username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as unbalanced,
(select SUM(sold) from tblScripBalancingReport where username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as sold,
(select SUM(bought) from tblScripBalancingReport where username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as bought,
(select SUM(duefrom) from tblScripBalancingReport where username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as duefrom,
(select SUM(dueto) from tblScripBalancingReport where username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as dueto,
(select SUM(unallocated) from tblScripBalancingReport where username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as unallocated,
(select SUM(transfersec) from tblScripBalancingReport where username = @user and [counter] in (select ASSETCODE from assets where [STATUS] = 'ACTIVE' and category not in('','LETTERS OF ALLOCATION','PREFERENCE SHARES','ZSE INDEX'))) as transsec,
(select SUM(balancecertificates) from tblScripBalancingReport) as balcert
--from tblScripBalancingReport where username = @user


GO
/****** Object:  StoredProcedure [dbo].[spScripForRegistration]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spScripForRegistration]
@user varchar(30)
as
declare @id bigint, @rec bigint, @asset varchar(50), @certno varchar(30)

exec spUnallocatedScrip '', @user
truncate table tblTempID
truncate table tblScripForRegistration
insert into tblScripForRegistration(id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, reference)
select l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname, c.surname+'  '+c.firstname) as client, l.userid, t.refno as reference   
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID		
inner join scripshape t on l.shapeid = t.id 
left join CLIENTS c on s.ClientNo = c.ClientNo   
where l.INCOMING = 1 and s.clientno <> '0' 
and (s.DATEOUT is null) and l.ID not in (select LEDGERID from SCRIPDEALSCERTS where LEFT(dealno, 1) = 'B' and cancelled = 0)  
and s.CLOSED = 0  --and l.asset = 'abchl-l' and l.QTY = 625
union 
select certid as id, certno, asset, qty, cdate, transform, clientno, regholder, client, userid, reference  
from tblUnallocated1stTempTable 
union 
select l.ID, l.certno, l.asset, l.qty, l.cdate, l.transform, l.clientno, l.regholder, coalesce(c.companyname, c.surname+'  '+c.firstname) as client, l.userid, l.refno as reference 
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join CLIENTS c on l.CLIENTNO = c.ClientNo 
where l.incoming = 1 and l.CANCELLED = 0 
and LEFT(l.REASON, 4) <> 'TRAN' 
and (s.DATEOUT is null) and s.CLOSED = 0 and s.ClientNo <> '0' 
and (l.ID not in (select LEDGERID from scripdealscerts where CANCELLED = 0)) 
union 
select l.ID, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname, c.surname+'  '+c.firstname) as client, l.userid, l.refno as reference  
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID  
inner join CLIENTS c on s.CLIENTNO = c.ClientNo  
where l.incoming = 1 and l.CANCELLED = 0  
and LEFT(l.REASON, 4) <> 'TRAN'  
and (s.DATEOUT is null) and s.CLOSED = 0 and s.ClientNo <> '0'  
and (l.ID in (select LEDGERID from scripdealscerts where CANCELLED = 0 and LEFT(dealno, 1) = 'B')) 
union 
select l.ID, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname, c.surname+'  '+c.firstname) as client, l.userid, sd.dealno as reference  
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID  
inner join scripdealscerts sd on l.id = sd.ledgerid 
left join CLIENTS c on s.CLIENTNO = c.ClientNo  
where l.incoming = 1 and l.CANCELLED = 0  
and sd.CANCELLED = 0 and LEFT(sd.dealno, 1) = 'B' 
and (s.DATEOUT is null) and s.CLOSED = 0 and s.ClientNo <> '0'-- order by l.ASSET, l.qty
  --and l.asset = 'abchl-l' and l.QTY = 625
union
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, l.regholder, coalesce(c.companyname , c.surname+'  '+c.firstname), l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno <> '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and left(c.DELIVERYOPTION, 4) <> 'SAFE' 
  
declare crid cursor for
select recid, id, asset, certno
from tblscripforregistration
open crid
fetch next from crid into @rec, @id, @asset, @certno
while @@FETCH_STATUS = 0 
begin
	if not exists(select id from tblTempID where id = @id and assetcode = @asset)
	begin
		insert into tblTempID(id, assetcode, certno)
		values(@id, @asset, @certno)
	end
	else
	begin
		delete from tblScripForRegistration
		where recid = @rec
	end
fetch next from crid into @rec, @id, @asset, @certno
end
close crid
deallocate crid
GO
/****** Object:  StoredProcedure [dbo].[spScripPool]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--spScripPool 'pending deliveries'
CREATE procedure [dbo].[spScripPool]
@pool varchar(50),
@user varchar(20),
@startclient varchar(50),
@endclient varchar(50)
as

declare @id bigint, @asset varchar(10), @certno varchar(10)

truncate table tblScripPool

if @pool = 'pending sale'
begin
insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid,reference, username)
select l.asset, l.certno, l.qty, a.assetname, coalesce(c.companyname, c.surname+'  '+c.firstname), l.cdate, l.regholder, l.userid, l.refno, @user 
from SCRIPLEDGER l inner join SCRIPSAFE s on l.ID = s.LEDGERID 
inner join ASSETS a on l.ASSET = a.ASSETCODE
left join CLIENTS c on s.ClientNo = c.ClientNo 
where l.INCOMING = 1 
and (l.REASON like '%SALE%') 
and (s.DATEOUT is null) 
and s.CLOSED = 0 and s.clientno <> '0'
order by l.asset, l.cdate, l.qty

end

if @pool = 'safe custody'
begin
exec spSafeCustodyScrip
insert into tblScripPool(certno, asset, qty, cdate, regholder, client, userid, reference, certid, username)
--select from tblTempSafeCustody
select certno, asset, qty, cdate, regholder, client, userid, reference, id, @user from tblTempSafeCustody
end

if @pool = 'unallocated'
begin
	exec spUnallocatedScrip ''
	insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid, reference, username)
	select t.asset, t.certno, t.qty, a.assetname, t.client, t.cdate, t.regholder, t.userid, t.reference, @user 
	from tblUnallocated1stTempTable t inner join ASSETS a on t.asset = a.ASSETCODE
	--and a.[STATUS] = 'ACTIVE'
end

if @pool = 'Pending Deliveries'
begin
delete from tblPendingDelivery1stTempTable
delete from tblPendingDelivery2ndTempTable
insert into tblPendingDelivery1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference) 
select distinct l.id, l.certno, l.asset, l.qty, sd.dt, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, sd.[user], sd.dealno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripdealscerts sd on l.id = sd.ledgerid  
left join CLIENTS c on s.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null)  
and LEFT(sd.dealno, 2) = 'B/' and s.clientno <> '0' and sd.cancelled = 0
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
union --scrip received from TSEC into the clients' custody
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno <> '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and s.ClientNo <> '0'
and left(c.DELIVERYOPTION, 4) <> 'SAFE'
union --scrip received from TSEC into the clients' custody
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, coalesce(c.companyname , c.surname+'  '+c.firstname), l.regholder, l.userid, sh.refno  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
inner join CLIENTS c on l.CLIENTNO = c.CLIENTNO
where l.id > 0 and l.clientno = '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where LEFT(DEALNO, 2) = 'B/') 
and left(c.DELIVERYOPTION, 4) <> 'SAFE%'
and s.ClientNo <> '0'

--look up in 2nd temp table and remove duplicate if found
declare crid cursor for
select id, asset, certno from tblPendingDelivery1stTempTable
open crid
fetch next from crid into @id, @asset, @certno
while @@FETCH_STATUS = 0
begin
	if exists(select certno from tblPendingDelivery2ndTempTable where asset = @asset and certno = @certno)
	begin
		delete from tblPendingDelivery1stTempTable
		where ID = @id
	end
	else
	begin
		insert into tblPendingDelivery2ndTempTable(asset, certno)
		values(@asset, @certno)
	end
	fetch next from crid into @id, @asset, @certno
end
close crid
deallocate crid

	insert into tblScripPool(asset, certno, qty, assetname, client, cdate, regholder, userid, reference, username)
	select p.asset, p.certno, p.qty, a.assetname, p.client, p.cdate, p.regholder, p.userid, p.reference, @user
	from tblPendingDelivery1stTempTable p inner join ASSETS a on p.asset = a.ASSETCODE
	order by p.asset, p.certno, p.qty	
end
GO
/****** Object:  StoredProcedure [dbo].[spScripReversals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--spScripReversals 'gibs'
create procedure [dbo].[spScripReversals]
@user varchar(30)
as
--scrip receipts reversals
delete from tblScripReversals where username = @user or (username is null)
insert into tblScripReversals(asset, certno, qty, canceldt, canceluser, cancelreason, rptpool, username)
select l.asset, l.certno, l.qty, l.CANCELDT, l.CANCELUSER, l.CANCELREASON, 'scriprec', @user
from SCRIPLEDGER l
where incoming = 1 and l.CANCELLED = 1


--scrip delivery reversals
insert into tblScripReversals(asset, certno, qty, canceldt, canceluser, cancelreason, rptpool, username)
select l.asset, l.certno, l.qty, l.CANCELDT, l.CANCELUSER, l.CANCELREASON, 'scripdel',@user
from SCRIPLEDGER l
where incoming = 0 and l.CANCELLED = 1

--deal settlement reversals
insert into tblScripReversals(asset, certno, qty, canceldt, canceluser, cancelreason, rptpool, username)
select distinct d.asset, s.dealno, d.qty, s.canceldt, s.canceluser, s.cancelref, 'settlements',@user
from SCRIPDEALSCERTS s inner join dealallocations d on s.dealno = d.dealno where s.CANCELLED = 1

--outgoing registrations
insert into tblScripReversals(asset, certno, canceldt, canceluser, cancelreason, rptpool, username)
select distinct l.asset,t.refno,t.canceldt, t.canceluser, t.cancelreason, 'regout',@user
from SCRIPTRANSFER t inner join SCRIPLEDGER l on t.LEDGERID = l.ID
where t.CANCELLED = 1

--incoming registrations
insert into tblScripReversals(asset, certno, canceldt, canceluser, cancelreason, rptpool, username)
select distinct l.asset,l.refno,l.canceldt, l.canceluser, l.cancelreason, 'regin',@user
from SCRIPLEDGER l
where l.CANCELLED = 1 and l.REASON = 'TRANSFERRED'
/*

select distinct rptpool from tblScripReversals
scrip receipts
scrip delivery
outgoing transfers
incoming transfers
deal settlements
*/


GO
/****** Object:  StoredProcedure [dbo].[spSettleCSDDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spSettleCSDDeals]
@sosdeal varchar(10)
,@matchdeal varchar(10)
,@qty int
,@user varchar(50)
,@settdate datetime
,@success bit output
as
declare @msg varchar(100), @sqty int, @mqty int, @selldeal varchar(10), @buydeal varchar(10)
declare @buyid bigint, @sellid bigint, @CSDTxns bit, @settqty int
select @success = 1

select @sqty = sharesout from DEALALLOCATIONS where DealNo = @sosdeal
select @mqty = sharesout from DEALALLOCATIONS where DealNo = @matchdeal

--get the settlement qty
if @sqty < @mqty 
	select @settqty = @sqty
else
	select @settqty = @mqty
	 
--save settlement details
insert into tblCSDSettlementDetails(ORIGDEALNO, MATCHDEALNO, DT, QTYUSED, settlementdate, settledby)
values(@sosdeal, @matchdeal, GETDATE(), @qty, @settdate, @user)
update DEALALLOCATIONS set SHARESOUT = SHARESOUT - @settqty, CSDSettled = 1 where DealNo in (@sosdeal, @matchdeal)

--post transactions details if configured to do so
select @CSDTxns = CSDTxnOnSettlement from BusinessRules
if @CSDTxns = 1
begin
	--post requisitions
	if LEFT(@sosdeal, 1) = 'S'
	begin
		select @selldeal = @sosdeal
		select @buydeal = @matchdeal
	end
	else if LEFT(@sosdeal, 1) = 'B'
	begin
		select @selldeal = @matchdeal
		select @buydeal = @sosdeal
	end

	--payment requisition
	--if exists(select dealno from DEALALLOCATIONS where DealNo = @selldeal and (clientno in (select ClientNo from CLIENTS where CATEGORY = 'BROKER')))
	--begin
		insert into Requisitions(ClientNo, LETTER, Amount, Dealno, CHQAMT, PAYEE, APPROVED, [login], APPROVEDBY, ENTEREDBY, CashBookID,	IsReceipt, YON)
		select d.clientno, 1, d.dealvalue, @selldeal, d.dealvalue, coalesce(c.companyname, c.surname+' '+c.firstname), 1, @user, @user, @user, 16, 0, 1
		from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
		where d.DealNo = @selldeal
		
	select @sellid = MAX(reqid) from Requisitions where Dealno = @selldeal
	--post payment transaction
	insert into CASHBOOKTRANS(ClientNo, PostDate, DealNo, TransCode, TransDate, [description], Amount, CASH, ARREARSCF, [LOGIN], CASHBOOKID, Cancelled, ExCurrency, ExRate, ExAmount, MatchID,	ChqRqID, YON)
	select d.clientno, GETDATE(), @selldeal, 'PAY', @settdate, 'PAYMENT TO CLIENT', d.dealvalue, 1, d.dealvalue, @user, 16, 0, 'USD', 1, d.dealvalue, @sellid, @sellid, 1
	from DEALALLOCATIONS d where d.DealNo = @selldeal
	--end

	--receipt requisition	
	--if exists(select dealno from DEALALLOCATIONS where DealNo = @buydeal and (clientno in (select ClientNo from CLIENTS where CATEGORY = 'BROKER')))
	--begin
		insert into Requisitions(ClientNo, LETTER, Amount, Dealno, CHQAMT, PAYEE, APPROVED, [login], APPROVEDBY, ENTEREDBY, CashBookID,	IsReceipt, YON)
		select d.clientno, 1, d.dealvalue, @buydeal, d.dealvalue, coalesce(c.companyname, c.surname+' '+c.firstname), 1, @user, @user, @user, 16, 0, 1
		from DEALALLOCATIONS d inner join CLIENTS c on d.ClientNo = c.ClientNo
		where d.DealNo = @buydeal	

		select @buyid = MAX(reqid) from Requisitions where Dealno = @selldeal	

		--post receipt transaction
		insert into CASHBOOKTRANS(ClientNo, PostDate, DealNo, TransCode, TransDate, [description], Amount, CASH, ARREARSCF, [LOGIN], CASHBOOKID, Cancelled, ExCurrency, ExRate, ExAmount, MatchID,	ChqRqID, YON)
		select d.clientno, GETDATE(), @buydeal, 'REC', @settdate, 'RECEIPT OF FUNDS', -d.dealvalue, 1, -d.dealvalue, @user, 16, 0, 'USD', 1, -d.dealvalue, @buyid, @buyid, 1
		from DEALALLOCATIONS d where d.DealNo = @buydeal
	--end
end
return @success


GO
/****** Object:  StoredProcedure [dbo].[spSettleDealWithScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Created by:		Gibson Mhlanga
	Date Created:	November 2010
	
	Revised:		29-08-2011
	
	Description:
	The procedure receives the deal to be settled and the id of the scrip that is to be used.
	Using the dealno, the client number, counter, outstanding shares for the deal are retrieved from the Dealallocations table.
	The certificate quantity is extracted from the scripledger table using the incomimg certificate id

	Sum all the instances of the QtyUsed field in the Scripdealscerts table for the incoming certificate for the incoming 
	deal number's deal type to find out how much of the certificate is still unused. Compare the unused certificate's 
	quantity against the deal's outstanding shares.

	On settlement, if the deal type is SELL then the scrip goes into the unallocated pool. If the deal type is BUY the 
	scrip goes onto the	client account. If the deal is for broker/nmi, then the scrip is delivered out of the system 
	and an outgoing delivery record is inserted into the scripledger table

	Finally insert the scrip and deal details into the temporary tables tblBuySettlementScrip and tblBuySettlementDeals 
	which will be used for printing the deal settlement report
	
	Update: 29-08-2011
	When settling a buy deal for a broker/nmi, then the outgoing delivery record in Scripledger table should include the 
	id of the incoming certificate that was used to settle the buy deal. This will be used when a reversal of the scrip
	delivered out has to be done.
	
	Update: 29-03-2012
	When settling buy deal, on summing the instances of the certificate previously used to settle buys deals, check that the
	buy deals previously settled belong to the current client. This will help solve the issue of partial settlments 
	usually occurring and reported by users as settled deals reopening. This is true for scrip used to settle a client's
	buy deal, then the client sells and then the scrip is delivered to a broker.
*/

--spsettledealwithscrip 'b/85',  120, 'gibs'
CREATE procedure [dbo].[spSettleDealWithScrip]
@dealno varchar(10),
@certid bigint, 
@user varchar(20)
as
declare @dealqty int, @certqty int, @cno varchar(30)
declare @certqtyused int, @certnetqty int, @qtyused int
declare @counter varchar(10), @settledcons money
declare @com money, @sd money, @vat money, @cg money, @inv money, @comlv money, @zselv money, @cons money, @netcons money
declare @ref varchar(20)

begin transaction

if exists(select refno from tblDeliveryReferenceNo)
begin
	select @ref = refno from tblDeliveryReferenceNo
end
else
begin
	select @ref = dbo.fnGetNextLedgerRef()
	insert into tblDeliveryReferenceNo values(@ref)
end

select @counter = asset, @dealqty = sharesout, @cno = ClientNo from dealallocations where dealno = @dealno
select @certqty = qty from scripledger where id = @certid

--get the sum of all the instances of the certificate used to settle client's buy deals
if left(@dealno, 1) = 'S'
begin
	select @certqtyused = isnull(sum(qtyused), 0) from scripdealscerts where ledgerid = @certid and cancelled = 0 and left(dealno, 1) = 'S'
	and DEALNO in (select DEALNO from dealallocations where ClientNo = @cno)
end	
else if left(@dealno, 1) = 'B'
	begin 
	 select @certqtyused = isnull(sum(qtyused), 0) from scripdealscerts where ledgerid = @certid and cancelled = 0 and left(dealno, 1) = 'B'
	 and DEALNO in (select DEALNO from dealallocations where ClientNo = @cno)
	end 
select @certnetqty = @certqty - @certqtyused
if @dealqty > 0
begin
	if @certnetqty > 0
		begin
			if @dealqty <= @certnetqty
				begin
					select @qtyused = @dealqty
					insert into scripdealscerts(ledgerid, dealno, reversetemp, dt, [user], qtyused)
					values(@certid, @dealno, 0, getdate(), @user, @dealqty)
					update dealallocations set sharesout = sharesout - @dealqty where dealno = @dealno
				end
			else
				begin
					select @qtyused = @certnetqty
					insert into scripdealscerts(ledgerid, dealno, reversetemp, dt, [user], qtyused)
					values(@certid, @dealno, 0, getdate(), @user, @certnetqty)
					update dealallocations set sharesout = sharesout - @certnetqty where dealno = @dealno
				end
		end
end
if substring(@dealno, 1, 1) = 'S' --if a sell deal is being settled the the scrip goes into the unallocated pool
	begin
		update scripsafe set clientno = '0', DATEOUT = null, CLOSED = 0 where ledgerid = @certid
	end
else --buy deal settled therefore scrip goes into client's account
	begin
		select @cno = clientno from dealallocations where dealno = @dealno
		update scripsafe set clientno = @cno where ledgerid = @certid -- sent scrip to the client's account
		
	--if the buy deal is for a broker/nmi, take the scrip out of the system	
	if exists(select clientno from CLIENTS where CLIENTNO = @cno and ((CATEGORY = 'broker') or (CATEGORY like 'nmi%')))
	begin
		update scripsafe set dateout = getdate(), closed = 1, clientno = @cno where ledgerid = @certid
		--deliver the scrip out of the system (incoming = 0)
		insert into scripledger([REFNO],[ITEMNO] ,[INCOMING],[CDATE],[USERID],[REASON],[CLIENTNO],[CERTNO],[ASSET], [QTY], [REGHOLDER], [TRANSFORM] ,[CANCELLED], [VERIFIED], [SHAPEID], INCOMINGID)
        select @ref, 1, 0, GETDATE(), @user, '', @cno, certno, asset, qty, regholder, 1, 0, 1, 0, @certid
        from scripledger where ID = @certid
	end

	insert into tblBuySettlementScrip(certno, asset, qty, client, regholder, clientno,username, refno)
	select l.certno, l.asset, l.qty, 
	(select coalesce(c.companyname, c.surname+' '+c.firstname) from clients c where c.clientno = @cno), l.regholder, @cno, @user, @ref
	from scripledger l 
	where id = @certid
	
	select @com = commission, @sd = stampduty, @vat = vat, @cg = capitalgains, @inv = investorprotection, @comlv = commissionerlevy, @zselv = zselevy
	from CLIENTCATEGORY 
	where CLIENTCATEGORY in (select category from clients where ClientNo in (select ClientNo from dealallocations where DEALNO = @dealno))
	
	select @cons = consideration from dealallocations where DealNo = @dealno
	select @settledcons = @qtyused * price/100 from dealallocations where DealNo = @dealno
	if SUBSTRING(@dealno, 1, 1) = 'S'
	 begin
		select @netcons = @cons - 2 - (@cons*@com/100) - (@cons*@sd/100) - (@cons*@vat/100) - (@cons*@cg/100) - (@cons*@inv/100) - (@cons*@comlv/100) - (@cons*@zselv/100)
		select @settledcons = @settledcons - (@settledcons*@com/100) - (@settledcons*@sd/100) - (@settledcons*@vat/100) - (@settledcons*@cg/100) - (@settledcons*@inv/100) - (@settledcons*@comlv/100) - (@settledcons*@zselv/100)
	 end
	else if SUBSTRING(@dealno, 1, 1) = 'B'
	 begin
		select @netcons = @cons + 2 +(@cons*@com/100) + (@cons*@sd/100) + (@cons*@vat/100) + (@cons*@cg/100) + (@cons*@inv/100) + (@cons*@comlv/100) + (@cons*@zselv/100)
		select @settledcons = @settledcons + 2 +(@settledcons*@com/100) + (@settledcons*@sd/100) + (@settledcons*@vat/100) + (@settledcons*@cg/100) + (@settledcons*@inv/100) + (@settledcons*@comlv/100) + (@settledcons*@zselv/100)
	 end 
	 
	if not exists(select dealno from tblBuySettlementDeals where dealno = @dealno and username = @user)
	begin
		insert into tblBuySettlementDeals(dealdate, asset, dealno, qty, price, NetConsideration, SettledConsideration, username)
		select dealdate, asset, dealno, qty, price, DealValue, DealValue, @user
		from Dealallocations where DealNo = @dealno
	end
end
commit transaction

select * from tblBuySettlementDeals
GO
/****** Object:  StoredProcedure [dbo].[spSettleUsingContra]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[spSettleUsingContra]
@odeal varchar(10),
@mdeal varchar(10),
@qty int,
@user varchar(50),
@strip smallint
as
declare @odeal1 varchar(10), @mdeal1 varchar(10)
declare @counter varchar(10)

select @counter = asset from Dealallocations where DealNo = @odeal
if @strip = 1
	begin
		select @odeal1 = substring(@odeal, 2, len(@odeal)-2), @mdeal1 = substring(@mdeal, 2, len(@mdeal)-2)
	end
else if @strip = 0
	begin
		select @odeal1 = @odeal, @mdeal1 = @mdeal
	end
update dealallocations set sharesout = sharesout - @qty where dealno in (@odeal1, @mdeal1)
insert into scripdealscontra(origdealno, matchdealno, dt, [user], qtyused)
values(@odeal1, @mdeal1, getdate(), @user, @qty)

select @counter = asset from Dealallocations where DealNo = @odeal
update tblScripBalancing set duefrom = duefrom - @qty, dueto = dueto - @qty
where [counter] = @counter



GO
/****** Object:  StoredProcedure [dbo].[spSettleWithBalancePosition]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[spSettleWithBalancePosition]
@qty int,
@certno varchar(20),
@dealno varchar(10),
@user varchar(30)
as
declare @balqty int, @id bigint
declare @sharesout int, @qtyused int, @balancedealno varchar(10)

select @sharesout = sharesout from dealallocations where DealNo = @dealno

select @balqty = balremaining, @balancedealno = dealno from tblDealBalanceCertificates where certno = @certno
select @id = id from scripledger where certno = @certno
if @balqty <= @sharesout
begin
 select @qtyused = @balqty
 update tblDealBalanceCertificates set balremaining = 0, dateout = getdate(), closed = 1 where certno = @certno
 update dealallocations set sharesout = sharesout - @balqty where dealno = @dealno
end
else
begin
 select @qtyused = @sharesout
 update tblDealBalanceCertificates set balremaining = balremaining - @sharesout where certno = @certno
 update dealallocations set sharesout = 0 where dealno = @dealno
end

--insert into scripdealscerts(ledgerid, dealno, dt, [user], QTYUSED)
--values(@id, @dealno, getdate(), @user, @qtyused)

insert into tblBalancePositionsSettlements(dealno, balancedealno, settlementdate, qtyused)
values(@dealno, @balancedealno, GETDATE(), @qtyused)

GO
/****** Object:  StoredProcedure [dbo].[spShapeDealNumber]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:			Gibson Mhlanga
	Creation Date:	16 November 2012
	Description:
				Procedure is executed after a shape a transfer's details have been saved
				It ensures that all shapes to which due-to positions have been attached
				have the correct TOCLIENT value which is the clientno for the deal attached.
				This will ensure that the shape will not return to the unallocated pool
				on receipt from transfer secretaries.
*/

create procedure [dbo].[spShapeDealNumber]
as
declare @dealno varchar(10), @clientno varchar(10), @id bigint

declare crshape cursor for
select id, dealno from scripshape
where toclient = '0' and left(dealno, 1) = 'B'
and closed = 0
and (newcertno is null)

open crshape
fetch next from crshape into @id, @dealno

while @@FETCH_STATUS = 0
begin
	if @dealno like 'BAL%'
		select @dealno = SUBSTRING(@dealno,5, LEN(@dealno)-4)
	select @clientno = clientno from dealallocations
	where dealno = @dealno
	update scripshape set toclient = @clientno
	where id = @id	
	
	fetch next from crshape into @id, @dealno
end

close crshape 
deallocate crshape
GO
/****** Object:  StoredProcedure [dbo].[spShapeQuantities]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[spShapeQuantities]
@dealno varchar(10),
@qty int
as
declare @remainder int

if not exists(select dealno from tblShapeDealQty where dealno = @dealno)
begin
 insert into tblShapeDealQty(dealno, qty)
 select @dealno, sharesout-@qty from dealallocations
 where dealno = @dealno
end
else
begin
 select @remainder = qty-@qty from tblShapeDealQty
 where dealno = @dealno
 delete from tblShapeDealQty where dealno = @dealno
 insert into tblShapeDealQty(dealno, qty)
 select @dealno, @remainder from dealallocations
 where dealno = @dealno
end
GO
/****** Object:  StoredProcedure [dbo].[spSharejobbingSummary]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spSharejobbingSummary]
@start datetime,
@end datetime,
@user varchar(50)
as
delete from sharejobbingsummary where username = @user;
with trans as(
select transdate, consideration
from transactions
where transdate >= @start
and transdate <= @end
and ((transcode like 'PURCH%') or (transcode like 'SALE%'))
)
insert into SharejobbingSummary(dealdate, cons, username)
select distinct x.transdate, 
	(select sum(-y.consideration) from trans y where y.transdate = x.transdate),
@user
from trans x
order by transdate

GO
/****** Object:  StoredProcedure [dbo].[spStampDutyLedger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spStampDutyLedger] --'2009-05-01', '2009-05-31'
@Start datetime,
@end datetime 
as
declare @balbf decimal(34,4), @balcf decimal(34,4), @total2 decimal(34,4)

select @balbf = isnull(sum(amount), 0) from transactions
where 
transdt < @Start
and transcode like 'SDUTY%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @balcf = isnull(sum(amount), 0) from transactions
where  transdt <= @End
and transcode like 'SDUTY%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @total2 = isnull(sum(amount), 0) from transactions
where  transdt <= @End
and transcode like 'SDDUE%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @balcf = @balcf + @total2

delete from tblCommissionerLevyLedger 
insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	[qty],
	[price],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       d.dealno, d.asset, d.qty, d.price, x.amount, @balbf, @balcf 
from transactions x  inner join dealallocations d on x.dealno = d.dealno
where x.transdt >= @Start
and x.transdt <= @end
and x.transcode like 'SDUTY%' 
and x.dealno in (select dealno from dealallocations where approved = 1
  and merged = 0 )
and x.cno > 30
order by d.dealdate

insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       'SDUTY', 'DUE', x.amount, @balbf, @balcf 
from transactions x
where x.transdt >= @Start
and x.transdt <= @end
--and x.transdt >= '2009-05-11'
and x.transcode like 'SDDUE%'



GO
/****** Object:  StoredProcedure [dbo].[spSummaryTrading]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			                    }
{							                            }
{		Author: Gibson Mhlanga			                }
{							                            }
{		     Copyright (c) 2020		                }
{							                            }
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[spSummaryTrading]	(  --exec spsummarytrading '20200101', '20201126', 'bug'
	@StartDate	datetime,
	@EndDate	datetime,
	@user varchar(50)
					)
AS
set nocount on

	delete from tradingsummary where userid = @user
	insert into	tradingsummary
			(dealtype,dealno,dealdate,clientno,category,asset,qty,price,consideration,commission,
			basiccharges,CONTRACTSTAMPS,sharesout,chqno,wtax,commissionerlevy,investorprotection,capitalgains,zselevy,vat, userid)
	select	d.dealtype,d.dealno,d.dealdate,coalesce(x.companyname, x.surname+ ' ' + x.firstname),x.category,d.asset,d.qty,d.price,d.consideration,d.grosscommission,
		d.csdlevy,d.stampduty,d.sharesout,d.chqno,d.wtax,d.commissionerlevy,d.investorprotection,d.capitalgains,d.zselevy,d.vat, @user
	from	dealallocations d inner join clients x on d.clientno = x.clientno
	where	(d.dealdate >= @StartDate) and (d.dealdate <= @EndDate) and (d.approved = 1) and
		(d.cancelled = 0) and (d.merged = 0)
		
update TRADINGSUMMARY set CATEGORY='BROKER' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY='broker')
update TRADINGSUMMARY set CATEGORY='NMI' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY = 'NMI')
update TRADINGSUMMARY set CATEGORY='NMI - NO TAX' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY = 'NMI - NO TAX')
update TRADINGSUMMARY set CATEGORY='INDIVIDUAL' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY = 'OTHER')
update TRADINGSUMMARY set StartDate=@StartDate,EndDate=@EndDate


--select * from tradingsummary

GO
/****** Object:  StoredProcedure [dbo].[spSystemSettings]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE procedure [dbo].[spSystemSettings]
@ApproveReceipts bit,
@PartSettlement bit,
@RegReceipts bit,
@VerifyScrip bit,
@FinPeriodOnly bit,
@SeperateBDeals bit,
@LockScrip bit
as
update tblSystemParams set approvereceipts = @approvereceipts, partsettlement = @partsettlement,
registrationreceipts = @regreceipts, verifyscrip = @verifyscrip, financialperiodonly = @finperiodonly,
SeperateBrokerDeals = @SeperateBDeals, LockScrip4BDeals = @lockscrip
GO
/****** Object:  StoredProcedure [dbo].[spTopTraders]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spTopTraders] --spTopTraders '2009-06-01', '2009-07-16',25
@start datetime,
@end datetime,
@top int
as

declare @cno bigint, @cons decimal(34,4), @comm decimal(34,4), @count int
declare @client varchar(100)

set concat_null_yields_null off

delete from tblTopTraders
delete from tblToptraderstemp

insert into tblTopTradersTemp(cno, consideration, commission)
select case soldto when 0 then purchasedfrom else soldto end as clientno,
consideration, commission
from dealallocations
where approved = 1
and cancelled = 0
and merged = 0
and dealdate >= @start  --select * from #tblTopTradersTemp
and dealdate <= @end


declare crtop cursor for 
select c.cno,
(select sum(a.consideration) from tblTopTradersTemp a where a.cno = c.cno and a.consideration <> 0),
(select sum(d.commission) from tblTopTradersTemp d where d.cno = c.cno and d.consideration <> 0),
ltrim(cl.companyname+' '+cl.title+' '+cl.firstname+' '+cl.surname)
from tblTopTradersTemp c inner join clients cl on c.cno = cl.clientno
where c.cno not in (select clientno from clients where category = 'broker')
group by c.cno, cl.companyname, cl.title, cl.firstname, cl.surname
order by sum(c.consideration) desc

open crtop
select @count = 1
fetch next from crtop into @cno, @cons, @comm, @client
while @@fetch_status = 0
begin
if @count <= @top
begin
if not exists(select cno from tblTopTraders where cno = @cno)
begin
insert into tblTopTraders(cno, consideration, commission, startdt, enddt, clientname, cnt)
values(@cno, @cons, @comm, @start, @end, @client, @top)
select @count = @count + 1
end
end
else
begin
break
end
fetch next from crtop into @cno, @cons, @comm, @client
end
close crtop
deallocate crtop



GO
/****** Object:  StoredProcedure [dbo].[spTraceHistoryDeal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spTraceHistoryDeal]
@dealno varchar(10)
as

declare @id bigint, @date datetime, @asset varchar(10), @cno varchar(20), @reason varchar(30), @qty int, @reg varchar(50), @cancelled bit, @canceluser varchar(50), @canceldt datetime
declare @client varchar(50), @pool varchar(50), @price money, @adjustment bit --select * from dealallocations

truncate table tblTraceHistory
--select @certno = '63'
select @date = dealdate, @asset = asset, @cno = clientno, @qty = qty, @price = price, @cancelled = cancelled, @adjustment = adjustment,
@canceldt = CancelDate, @canceluser = CancelLoginID 
from Dealallocations 
where DealNo = @dealno

--record receipt date and get client from 
if @cno is not null 
begin
	select @client = coalesce(companyname, surname+' '+firstname)
	from Clients 
	where ClientNo = @cno
end

if @date is not null
begin
	insert into tblTraceHistory(tracedate, details)
	values(@date, 'Counter : '+@asset+', Qty :'+cast(@qty as varchar(10))+', Price : '+cast(@price as varchar(10))+', Client '+@client)
end

--check if scrip was used to settle deal
if exists(select ledgerid from SCRIPDEALSCERTS where dealno = @dealno)
begin
	select @cancelled = cancelled from SCRIPDEALSCERTS where LEDGERID = @id
	insert into tblTraceHistory(tracedate, details)
	select s.dt, 'Settled using scrip cert. # : '+l.certno+', Qty Used: '+cast(s.qtyused as varchar(10))
	from SCRIPDEALSCERTS s inner join SCRIPLEDGER l on s.ledgerid = l.id
	where s.dealno = @dealno
	
	if @cancelled = 1
	begin
		insert into tblTraceHistory(Tracedate, Details)
		select canceldt, 'Cancelled deal settlement by '+canceluser
		from SCRIPDEALSCERTS where DEALNO = @dealno
		and CANCELLED = 1
	end	
end
--select * from scripdealscontra 
--check if deal was settled using contra
if exists(select id from SCRIPDEALSCONTRA where (ORIGDEALNO = @dealno))
begin
	insert into tblTraceHistory(tracedate, details)
	select dt, 'Settled by contra with dealno: '+matchdealno+', Qty Used : '+CAST(qtyused as varchar(10))
	from SCRIPDEALSCONTRA where ORIGDEALNO = @dealno
end

if exists(select id from SCRIPDEALSCONTRA where (MATCHDEALNO = @dealno))
begin
	insert into tblTraceHistory(tracedate, details)
	select dt, 'Settled by contra with dealno: '+matchdealno+', Qty Used : '+CAST(qtyused as varchar(10))
	from SCRIPDEALSCONTRA where MATCHDEALNO = @dealno
end

GO
/****** Object:  StoredProcedure [dbo].[spTraceHistoryScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spTraceHistoryScrip]
@certno varchar(20),
@counter varchar(10),
@inid bigint
as


declare @id bigint, @date datetime, @asset varchar(10), @cno varchar(20), @reason varchar(30), @qty int, @reg varchar(50), @cancelled bit, @canceluser varchar(50), @canceldt datetime
declare @client varchar(50), @pool varchar(50), @tsecrefno varchar(20), @username varchar(20), @outid bigint
declare @delivery varchar(50), @NoDetails varchar(30), @delivcno varchar(10)

--alter table tbltracehistory add username varchar(20)
set concat_null_yields_null off
truncate table tblTraceHistory
--select @certno = '63'

declare crid cursor for 
select id from scripledger where certno = @certno and asset = @counter and id = @inid
open crid
fetch next from crid into @id
while @@fetch_status = 0
begin
select @id = id, @date = cdate, @asset = asset, @cno = clientno, @reason = reason, @qty = qty, @reg = regholder, @cancelled = cancelled, @username = userid,
@canceldt = canceldt, @canceluser = canceluser 
from scripledger 
where incoming = 1
and asset = @counter
and verified = 1
and certno = @certno
and ID in (select ledgerid from SCRIPSAFE)
and ID = @inid

--record receipt date and get client from 
if @cno <> '0' --is not null 
begin
	select @client = coalesce(companyname, surname+' '+firstname)
	from Clients 
	where ClientNo = @cno
end

if @date is not null
begin
	select @pool = case @reason
		when 'FORSALE' then 'Pending Sale'
		when 'Pending Sale' then 'Pending Sale'
		when 'SAFECUSTODY' then 'Safe Custody'
		when 'SAFE CUSTODY' then 'Safe Custody'
		when 'FAVOUR' then 'Favour Registration'
		when 'SETTLEBUY' then 'Unallocated' --'Broker/NMI Sell Settlement'
		when 'TRANSFERRED' then 'TRANSFER SECRETARY'
		when 'TRANSFERED' then 'TRANSFER SECRETARY'
		end
		
	if @reason = 'TRANSFERRED'
	begin	
		select @tsecrefno = refno from SCRIPSHAPE where NEWCERTNO = @certno
		if @cno = '0'
		begin
			if not exists(select * from tblTraceHistory where dbo.fnformatdate(tracedate) = dbo.fnformatdate(@date) and username = @username and (details like '%'+@tsecrefno+'%'))
			begin
			insert into tblTraceHistory(tracedate, details, username)
			values(@date, 'Received into Unallocated from Transfer Secretary. Ref #: '+@tsecrefno,@username)
			end
		end
		else
		begin
			select @delivery = LEFT(deliveryoption, 4) from CLIENTS where ClientNo = @cno
			if @delivery = 'SAFE'
				select @client = @client + ' - (SAFE CUSTODY)'
			else if @delivery = 'SEND'
				select @client = @client + ' - (PENDING DELIVERY)'
			if not exists(select * from tblTraceHistory where dbo.fnformatdate(tracedate) = dbo.fnformatdate(@date) and username = @username and (details like '%'+@tsecrefno+'%'))
			begin
				insert into tblTraceHistory(tracedate, details, username)
				values(@date, 'Received to '+@client+' from Transfer Secretary. Ref #: '+@tsecrefno, @username)
			end
		end
	end
		else
		begin	
			if not exists(select * from tblTraceHistory where dbo.fnformatdate(tracedate) = dbo.fnFormatDate(@date) and (details like '%'+@pool+'%') and username = @username)
			begin
				insert into tblTraceHistory(tracedate, details, username)
				values(@date, 'Received into '+@pool+' from '+@client, @username)
			end
		end
end

--**
----check if scrip was used to settle sell deals
if exists(select ledgerid from SCRIPDEALSCERTS where LEDGERID = @id and SUBSTRING(dealno, 1, 1) = 'S')
begin
	select @cancelled = cancelled from SCRIPDEALSCERTS where LEDGERID = @id
	
	if not exists(select * from tblTraceHistory where dbo.fnFormatDate(tracedate) = dbo.fnFormatDate(@date) and (details like '%settled sell%') and username = @username)
	begin
		insert into tblTraceHistory(tracedate, details, username)
		select s.dt, 'Settled sell dealno '+s.dealno+', DealDate: '+cast(d.dealdate as varchar(20))+', Qty: '+CAST(d.qty as varchar(10)), s.[USER]--+', Price: '+CAST(d.price as varchar(10))
		from SCRIPDEALSCERTS s inner join Dealallocations d on s.DEALNO = d.DealNo
		where LEDGERID = @id
		and SUBSTRING(s.dealno, 1, 1) = 'S'
	end
	
	if @cancelled = 1
	begin
		insert into tblTraceHistory(Tracedate, Details, username)
		select canceldt, 'Cancelled sell deal settlement',CANCELUSER
		from SCRIPDEALSCERTS where LEDGERID = @id
		and CANCELLED = 1
		and SUBSTRING(dealno, 1, 1) = 'S'
	end	
end

--check if scrip was used to settle buy deals
if exists(select ledgerid from SCRIPDEALSCERTS where LEDGERID = @id and SUBSTRING(dealno, 1, 1) = 'B')-- and (@reason not like 'TRAN%'))
begin
	select @cancelled = cancelled from SCRIPDEALSCERTS where LEDGERID = @id
	
	if not exists(select * from tblTraceHistory where dbo.fnFormatDate(tracedate) = dbo.fnFormatDate(@date) and (details like '%settled buy deal%') and username = @username)
	begin
		insert into tblTraceHistory(tracedate, details, username)
		select s.dt, 'Settled buy dealno '+s.dealno+', DealDate: '+cast(d.dealdate as varchar(20))+', Qty: '+CAST(d.qty as varchar(10)), s.[user]--+', Price: '+CAST(d.price as varchar(10))
		from SCRIPDEALSCERTS s inner join Dealallocations d on s.DEALNO = d.DealNo
		where LEDGERID = @id
		and SUBSTRING(s.dealno, 1, 1) = 'B'
	end
	
	if @cancelled = 1
	begin
		insert into tblTraceHistory(Tracedate, Details, username)
		select canceldt, 'Cancelled sell deal settlement',canceluser
		from SCRIPDEALSCERTS where LEDGERID = @id
		and CANCELLED = 1
		and SUBSTRING(dealno, 1, 1) = 'B'
	end	
end

----scrip was used to settle deal but dealno not saved (dealno = 0 in scripdealscerts table)
----if exists(select ledgerid from SCRIPDEALSCERTS where LEDGERID = @id)
----begin
----	insert into tblTraceHistory(tracedate, details, username)
----	select dt, 'Settled dealno '+dealno, [user] from SCRIPDEALSCERTS
----	where LEDGERID = @id
----end

--check if scrip was sent for registration 
if exists(select ledgerid from SCRIPTRANSFER where LEDGERID = @id)
begin
	insert into tblTraceHistory(tracedate, details, username)
	select t.datesent, 'Sent for registration - Ref #: '+t.refno+', Shape : '+ cast(s.qty as varchar(10))+ ' ('+case s.TOCLIENT 
	when '0' then 'UNALLOCATED'
	else 
			coalesce(c.companyname, c.surname+'  '+c.firstname)
	end +') '
		, t.USERID
	from SCRIPTRANSFER t inner join SCRIPSHAPE s on t.REFNO = s.REFNO 
	left join CLIENTS c on s.TOCLIENT = c.ClientNo
	where t.LEDGERID = @id
	
	select @cancelled = cancelled from SCRIPTRANSFER where LEDGERID = @id
	if @cancelled = 1
	begin
		insert into tblTraceHistory(tracedate, details, username)
		select canceldt, 'Cancelled registration ('+REFNO+') : Reason : '+CancelReason, canceluser from scriptransfer
		where ledgerid = @id and CANCELLED = 1
	end
end

--check if scrip was delivered out
if exists(select id from SCRIPLEDGER where CERTNO = @certno and INCOMING = 0 and ASSET = @asset)
begin
	--check if outgoing record was used to settle a buy deal
	select @outid = id from SCRIPLEDGER where certno = @certno and incoming = 0
	if exists(select ledgerid from SCRIPDEALSCERTS where LEFT(dealno,2) = 'B/' and LEDGERID = @outid)
	begin
		insert into tblTraceHistory(tracedate, details, username)
		select s.dt, 'Settled buy deal # '+d.dealno+' Qty: '+cast(d.qty as varchar(20))+' - (OLD SYSTEM)', s.[USER]
		from DEALALLOCATIONS d inner join SCRIPDEALSCERTS s on d.DealNo = s.DEALNO
		where s.LEDGERID = @outid and LEFT(s.dealno, 2) = 'B/'
	end
	--/*****
	--check if scrip was used to settle buy deal
	select @delivcno = clientno from SCRIPLEDGER where ID = @outid
	if exists(select clientno from clients where clientno = @delivcno and ((category = 'broker') or (LEFT(category, 3) = 'NMI')))
	begin
		if not exists(select ledgerid from scripdealscerts where LEDGERID = @inid and LEFT(dealno, 1) = 'B')
		begin
			select @NoDetails = 'NO SETTLEMENT DETAILS'
		end
		else
		begin
			select @NoDetails = ''
		end
	
		insert into tblTraceHistory(tracedate, details, username)
		select l.cdate, 'Delivered to '+coalesce(c.companyname, c.surname+' '+c.firstname)+' ('+@NoDetails+')', l.USERID from SCRIPLEDGER l inner join Clients c on l.CLIENTNO = c.clientno
		where CERTNO = @certno
		and INCOMING = 0
		end
	else
	begin
		--insert into tblTraceHistory(tracedate, details, username)
		--select l.cdate, 'Delivered to '+coalesce(c.companyname, c.surname+' '+c.firstname), l.USERID from SCRIPLEDGER l inner join Clients c on l.CLIENTNO = c.clientno
		--where CERTNO = @certno
		--and INCOMING = 0
		select @NoDetails = ''
	end
		select @NoDetails = ''
--	******/
	
	--if not exists(select * from tblTraceHistory where dbo.fnFormatDate(tracedate) = dbo.fnFormatDate(@date) and (details like '%delivered to%') and username = @username)
	--begin
	--	insert into tblTraceHistory(tracedate, details, username)
	--	select l.cdate, 'Delivered to '+coalesce(c.companyname, c.surname+' '+c.firstname), l.USERID from SCRIPLEDGER l inner join Clients c on l.CLIENTNO = c.clientno
	--	where CERTNO = @certno
	--	and INCOMING = 0
	--end
	
--	select @cancelled = cancelled from SCRIPLEDGER 
--	where CERTNO = @certno 
--	and INCOMING = 0
	
--	if @cancelled = 1
--	begin
--		insert into tblTraceHistory(tracedate, details, username)
--		select canceldt, 'Cancelled outward delivery',canceluser
--		from SCRIPLEDGER 
--		where CERTNO = @certno
--		and INCOMING = 0
--	end	
end
--**

--check if scrip receipt was cancelled
select @cancelled = cancelled, @canceldt = CANCELDT, @canceluser = CANCELUSER from SCRIPLEDGER where ID = @id
if @cancelled = 1
begin
	insert into tblTraceHistory(tracedate, details, username)
	values(@canceldt, 'Cancelled scrip receipt', @canceluser)	
end
fetch next from crid into @id
end
close crid
deallocate crid
GO
/****** Object:  StoredProcedure [dbo].[spTraceHistoryTransfer]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spTraceHistoryTransfer]
@id bigint,
@user varchar(30)
as

declare @clientno varchar(20), @client varchar(50)

delete from tblTraceHistory --where logedinuser = @user

if exists(select ID from SCRIPLEDGER where SHAPEID = @id)
begin
	insert into tblTraceHistory(tracedate, details, username, logedinuser)
	select top 1 datesent, 'Sent for registration', userid, @user
	from SCRIPTRANSFER where REFNO in (select REFNO from SCRIPSHAPE where ID = @id)
	
	select @clientno = clientno from SCRIPLEDGER where SHAPEID = @id
	if @clientno = '0'
	begin
		insert into tblTraceHistory(tracedate, details, username, logedinuser)
		select cdate, 'Received into unallocated from transfer secretary', userid, @user from scripledger
		where SHAPEID = @id
	end
	else
	begin
		select @client = coalesce(companyname, surname+'  '+firstname) from clients where clientno = @clientno
		insert into tblTraceHistory(tracedate, details, username, logedinuser)
		select cdate, 'Received to '+@client+' from transfer secretary', userid, @user from scripledger
		where SHAPEID = @id
	end
	
	--check if certificate was used to settle deals
	if exists(select ledgerid from scripdealscerts where ledgerid in (select id from scripledger where shapeid = @id))
	begin
		insert into tblTraceHistory(tracedate, details, username, logedinuser)
		select s.dt, 'Settled deal '+s.dealno+' Qty : '+cast(d.dealno as varchar(20))+' Qty Used : '+ cast(s.qtyused as varchar(20)),
		s.[user], @user
		from scripdealscerts s inner join dealallocations d on s.dealno = d.dealno
		where s.ledgerid in (select id from scripledger where shapeid = @id) 
	end
end

/*
sptracehistorytransfer 8992, 'gibs'
select * from tblTraceHistory
select * from scripshape where newcertno = '80071'

*/
--select * from SCRIPLEDGER where SHAPEID = 8992


GO
/****** Object:  StoredProcedure [dbo].[spTradingSummaryCriteria]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spTradingSummaryCriteria]
@AssetStart varchar(10),
@AssetEnd varchar(10),
@Equal smallint
as
if @Equal = 1
 begin
  delete from tradingsummary where asset <> @assetstart
 end
else
 begin 
	delete from tradingsummary
	where asset not in (select assetcode from assets where asset >= @assetstart and assetcode <= @assetend)
 end

GO
/****** Object:  StoredProcedure [dbo].[spUnallocatedScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author: Gibson Mhlanga
	Date:	30 September 2011
	Description:
	Use temp tables to look up duplications and remove them from the selected scrip
 
	Method: 
		    1. insert the selected entries into a temp table
            2. loop thru the temp table, take each counter's certificate # and look it up in a 2nd temp table
            3. if cert# not in 2nd temp table then insert into 2nd temp table, if exists then delete from 1st temp table
            
            spUnallocatedScrip 'nicoz-l'
*/

CREATE procedure [dbo].[spUnallocatedScrip]
@counter varchar(10)
,@user varchar(30)
as
declare @asset varchar(10), @certno varchar(20), @id bigint

--insert into 1st temp table
truncate table tblUnallocated1stTempTable
truncate table tblUnallocated2ndTempTable
insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username) 
select distinct l.id, l.certno, l.asset, l.qty, sd.dt, l.transform, s.clientno, 'UNALLOCATED', l.regholder, sd.[user], sd.dealno, @user  --l.id, 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripdealscerts sd on l.id = sd.ledgerid  
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null)  
and left(sd.dealno, 1) = 'S' and s.clientno = '0' and sd.cancelled = 0
and l.ASSET like '%'+@counter+'%'

insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username) 
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, 'UNALLOCATED', l.regholder, l.userid, sh.refno, @user
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
inner join scripshape sh on l.shapeid = sh.id  
where l.id > 0 and s.clientno = '0' 
and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'S/' and CANCELLED = 0) 
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'B/' and CANCELLED = 0)
and l.ASSET like '%'+@counter+'%'
insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username) 
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, s.clientno, 'UNALLOCATED', l.regholder, l.userid, l.REFNO+' - OLD REG', @user 
from scripledger l inner join scripsafe s on l.id = s.ledgerid  
--inner join scripshape sh on l.shapeid = sh.id  
where l.id > 0 and l.clientno = '0' and l.cancelled = 0 and l.incoming = 1 and l.transform = 1 and s.closed = 0 and (s.dateout is null) 
and LEFT(l.reason, 4) = 'TRAN' and l.SHAPEID = 0
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'S/' and CANCELLED = 0) 
and l.id not in (select ledgerid from scripdealscerts where left(DEALNO, 2) = 'B/' and CANCELLED = 0)
and l.ASSET like '%'+@counter+'%'
insert into tblUnallocated1stTempTable(certid, certno, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username)  
select distinct l.id, l.certno, l.asset, l.qty, l.cdate, l.transform, f.clientno, 'UNALLOCATED', l.regholder, l.userid, f.fdealno, @user 
from scripledger l inner join tblFavourRegPositions f on l.id = f.ledgerid  
where l.id > 0 and l.cancelled = 0 and l.incoming = 1 and l.transform = 1
and l.SHAPEID = 0 and f.qtyout > 0 and f.cancelled = 0
and l.ASSET like '%'+@counter+'%'
--look up in 2nd temp table and remove duplicate if found
declare crid cursor for
select id, asset, certno from tblUnallocated1stTempTable
open crid
fetch next from crid into @id, @asset, @certno
while @@FETCH_STATUS = 0
begin
	if exists(select certno from tblUnallocated2ndTempTable where asset = @asset and certno = @certno)
	begin
		delete from tblUnallocated1stTempTable
		where ID = @id
	end
	else
	begin
		insert into tblUnallocated2ndTempTable(asset, certno)
		values(@asset, @certno)
	end
	fetch next from crid into @id, @asset, @certno
end
close crid
deallocate crid

select certno, certid as id, asset, qty, cdate, transform, clientno, client, regholder, userid, reference, username 
from tblUnallocated1stTempTable
order by asset, certno, qty
GO
/****** Object:  StoredProcedure [dbo].[spUpdateBrokerNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[spUpdateBrokerNo]
@CNO int,
@BrokerNo int
as
--declare @ClientNo int

--select @ClientNo = max(ClientNo) from clients

update clients set ClientNo = @BrokerNo
where ClientNo = @CNO


GO
/****** Object:  StoredProcedure [dbo].[spUpdateScripPool]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spUpdateScripPool]
as

declare @asset varchar(10), @id bigint, @reason varchar(30), @certid bigint, @clientno varchar(10), @ref varchar(20), @dealno varchar(10)
declare crasset cursor for
select asset, id, certid from tblscrippool
open crasset
fetch next from crasset into @asset, @id, @certid
while @@FETCH_STATUS = 0
begin
	update tblScripPool set tsec = (select companyname from CLIENTS where CLIENTNO = (select transsecid from ASSETS where ASSETCODE = @asset))
	where asset = @asset
	
	--update the reference field
    select @reason = reason from SCRIPLEDGER 
    where ID = @certid
    
    if @reason like 'TRANSFER%'
    begin
		if exists(select ledgerid from SCRIPDEALSCERTS where LEDGERID = @certid and SUBSTRING(dealno, 1, 2) = 'B/')
		begin
			select @dealno = dealno from SCRIPDEALSCERTS where LEDGERID = @certid
			update tblScripPool set reference = @dealno
			where id = @id
		end
		else
		begin
			select @clientno = clientno from SCRIPLEDGER where ID = @certid
			if @clientno = '0'
				select @ref = 'UNALLOCATED'
			else
				select @ref = 'FAVOUR'
			
			update tblScripPool set reference = @ref
			where id = @id			
		end
    end
	fetch next from crasset into @asset, @id, @certid
end
close crasset
deallocate crasset

GO
/****** Object:  StoredProcedure [dbo].[spUpdateScripShape]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spUpdateScripShape] 
@ID bigint,
@Certno varchar(20) = '''',
@DATE datetime = null, 
@HOLDERNO varchar(20) = '''',
@REFNO varchar(20) = ''''
as
declare @asset varchar(10)
select @asset = l.asset from scriptransfer t inner join scripledger l on t.ledgerid = l.id
where t.refno = @refno

if not exists(select refno from tblRefNo where refno = @refno and (refno is not null))
begin
insert into tblRefNo(RefNo)
values(@RefNo)
end

--select * from tblRefNo

if not exists(select id from tblscripshapeid where id = @id)
begin
insert into tblScripShapeID(ID)
values(@ID)
end
 
delete from tblScripShapeID where id is null
if exists(select certno from scripledger where certno = @certno and asset = @asset)
begin
update scripshape set newcertno = '''',
issuedate = null, holderno = '''', closed = 0, transferno = '''' 
where id = @ID
--raiserror(''Certificate # already exists in the system!'', 11, 1)
end
GO
/****** Object:  StoredProcedure [dbo].[spUpdateScripTransfer]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[spUpdateScripTransfer]
as
/*declare @refno varchar(20)

declare crRef cursor for
select refno from tblRefNo

open crref
fetch next from crref into @refno

while @@fetch_status = 0
begin
if not exists(select refno from scripshape where refno = @refno and closed = 0)
begin
update scriptransfer set closed = 1 
where refno = @refno
end
fetch next from crref into @refno
end

delete from tblRefNo
close crref
deallocate crref*/
--update dealallocations set sharesout = 0 
--where dealno in (select dealno from scripshape where id in (select id from tblScripShapeID))
update scriptransfer set closed = 1
where refno not in (select refno from scripshape where closed = 0)
GO
/****** Object:  StoredProcedure [dbo].[spUpdateShapeDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[spUpdateShapeDetails]
@user varchar(20),
@ID bigint,
@Asset varchar(10),
@CertNo varchar(20),
@DateIssued datetime,
@HolderNo varchar(50) = null,
@TransferNo varchar(10) = null
as
declare @sid bigint, @refno varchar(20)
if exists(select certno from scripledger where certno = @certno and asset = @Asset and cancelled = 0 and INCOMING = 1 and 
	ID in (select ledgerid from SCRIPSAFE where CLOSED = 0 and (DATEOUT is null)))
begin
 raiserror('Certificate number already exists in the system!', 11, 1)
 return
end

if exists(select newcertno from scripshape where newcertno = @certno and asset = @Asset)
begin
 raiserror('Certificate number has already been specified!', 11, 1)
 return
end  

insert into tblScripShapeID(id) values(@id)
update scripshape set newcertno = @certno, issuedate = @Dateissued, closed = 1--, holderno = @holderno, transferno = @transferno
where id = @id
exec spInsertScripShapes @user, @id
select @sid = max(id), @refno = max(refno) from scripledger
--insert into tblScripShapeID(id) values(@id)
insert into tblScripLedgerID(id) values(@sid)
insert into tblReceivedRegistration(id, refnum) values(@sid, @refno)













GO
/****** Object:  StoredProcedure [dbo].[spVatLedger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[spVatLedger]
@Start datetime,
@end datetime 
as
declare @balbf decimal(34,4), @balcf decimal(34,4),@sumtxns decimal(34,4),@sumpaymnts decimal(34,4),@balbftxns decimal(34,4),@balbfpymts decimal(34,4)

select @balbf = isnull(sum(amount),0) from transactions
where transdt < @start
and transcode like 'vatc%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30



select @sumtxns = isnull(sum(amount), 0) 
from transactions 
where (transdt>=@start)
and (transdt <=@end)
and transcode like 'vatc%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30




select @sumpaymnts = isnull(sum(amount), 0) 
from transactions 
where(transdt <=@end)
and transcode like 'vatd%'
and dealno in (select dealno from dealallocations where approved = 1
and  merged = 0 )
and cno > 30

select @balcf= @sumtxns +@sumpaymnts +@balbf

delete from tblCommissionerLevyLedger 
insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	[qty],
	[price],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       d.dealno, d.asset, d.qty, d.price, x.amount, @balbf, @balcf 
from transactions x  inner join dealallocations d on x.dealno = d.dealno
where x.transdt >= @Start
and x.transdt <= @end
and x.transdt >= @start
and x.dealno in (select dealno from dealallocations where approved = 1
and merged = 0 )
and x.cno > 30
order by d.dealdate

insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       'VAT', 'DUE', x.amount, @balbf, @balcf 
from transactions x
where x.transdt >= @Start
and x.transdt <= @end
and x.dealno in (select dealno from dealallocations where approved = 1
and   merged = 0 )
and x.cno > 30
and x.transcode like 'vatd%'






GO
/****** Object:  StoredProcedure [dbo].[spVerifyObject]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2004			}
{							}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[spVerifyObject]	(
	@Param		varchar(100)
				)
AS
declare @ID int
if (upper(@Param) = 'USERS') or (upper(@Param) = 'TRANSACTIONS')
	print upper(@Param) + char(13) + char(10) + 'Internal 0x0FFFFFFF: Table index / data page fault'
else
	print upper(@Param) + char(13) + char(10) + 'Object structure and data verified'
return 0

GO
/****** Object:  StoredProcedure [dbo].[spZSELevy]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[spZSELevy] 
@Start datetime,
@end datetime 
as
declare @balbf decimal(34,4), @balcf decimal(34,4)

select @balbf = sum(amount) from transactions
where transdt >= '2010-01-11'
and transdt < @Start
and transcode like 'ZSELV%'

select @balcf = sum(amount) from transactions
where transdt >= '2010-01-11'
and transdt <= @End
and transcode like 'ZSELV%'

delete from tblCommissionerLevyLedger 
insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	[qty],
	[price],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       d.dealno, d.asset, d.qty, d.price, x.amount, @balbf, @balcf 
from transactions x  inner join dealallocations d on x.dealno = d.dealno
where x.transdt >= @Start
and x.transdt <= @end
and x.transdt >= '2010-01-11'
and x.transcode like 'ZSELV%' 
and x.dealno in (select dealno from dealallocations where approved = 1
and cancelled = 0 and merged = 0 and dealdate >= '2010-01-11')
and x.cno > 30
order by d.dealdate

insert into tblCommissionerLevyLedger(startdate,
    enddate,   
	[TransDt],
    clientno,
    dealno,
	[asset],
	amount,
    balbf,
    balcf)
select @Start,@end, x.transdt, 
x.cno,
       'ZSELEVY', 'DUE', x.amount, @balbf, @balcf 
from transactions x
where x.transdt >= @Start
and x.transdt <= @end
and x.transdt >= '2010-01-11'
and x.transcode like 'ZSELVD%'






GO
/****** Object:  StoredProcedure [dbo].[StatementMulti]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005			}
{							}
{*******************************************************}
*/
CREATE            PROCEDURE [dbo].[StatementMulti]	(
	@User			varchar(50),
	@StartingClientNo	int,
	@EndingClientNo		int,
	@StartingClientLetter	char(1),
	@EndingClientLetter	char(1),
	@StatementDate		datetime,
	@StartDate		datetime,
	@EndDate		datetime,
	@ExcludeInactive	bit = 1,
	@BalancesOnly		bit = 0,
	@CalculateArrearsNotYetDue	bit = 0,
	@StartAgeingAt30Days	bit = 1
				)
AS
set nocount on
declare @i int, @maxcli int, @fname varchar(500)
--BEGIN TRANSACTION STATEMENTS
delete from statements where [user] = @User
if @StartingClientNo > 0
begin
	select @maxcli = max(clientno) from clients
	
	if @EndingClientNo = -1
		select @EndingClientNo = @maxcli
	else
	begin
		if @EndingClientNo > @maxcli
			select @EndingClientNo = @maxcli
	end
	
	select @i = @StartingClientNo
	while @i <= @EndingClientNo
	begin
		exec StatementSingle @User,@i,@StatementDate,@StartDate,@EndDate,@BalancesOnly,@CalculateArrearsNotYetDue,@StartAgeingAt30Days
		select @i = @i + 1
	end
end
else
	if (@StartingClientLetter <> '') and (@EndingClientLetter <> '')
	begin
		set concat_null_yields_null off
		declare client_cursor cursor for
			select clientno, ltrim(rtrim(surname + ' ' + companyname)) as fullname from clients
			where (ascii(left(upper(ltrim(rtrim(surname + ' ' + companyname))),1)) >= ascii(upper(@StartingClientLetter))) and (ascii(left(upper(ltrim(rtrim(surname + ' ' + companyname))),1)) <= ascii(upper(@EndingClientLetter)))
			order by fullname
		open client_cursor
		fetch next from client_cursor into @i, @fname
		while @@FETCH_STATUS = 0
		begin
			exec StatementSingle @User,@i,@StatementDate,@StartDate,@EndDate,@BalancesOnly,@CalculateArrearsNotYetDue,@StartAgeingAt30Days
			fetch next from client_cursor into @i, @fname
		end
		close client_cursor
		deallocate client_cursor
	end
if @ExcludeInactive = 1
	delete from statements where ([user] = @User) and (clientno not in (select distinct cno from transactions))
--COMMIT TRANSACTION STATEMENTS
return 0

GO
/****** Object:  StoredProcedure [dbo].[StatementSingle]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		     Copyright (c) 2005-7		}
{							}
{*******************************************************}
*/

--StatementSingle	'ADEPT','1110ren','20100201','20100221','20100221',0,0,0

CREATE               PROCEDURE [dbo].[StatementSingle]	(
	@User			varchar(50),
	@ClientNo		varchar(50),
	@StatementDate		datetime,
	@StartDate		datetime,
	@EndDate		datetime,
	@BalancesOnly		bit = 0,
	@ShowArrearsNotYetDue	bit = 0,
	@StartAgeingAt30	bit = 0
				)
AS
set nocount on
declare @balnow decimal(38,4), @balopen decimal(38,4), @bal30 decimal(38,4), @bal60 decimal(38,4),
	@bal90 decimal(38,4), @bal120 decimal(38,4), @bal180 decimal(38,4), @baltemp decimal(38,4),
	@bal7 decimal(38,4), @bal14 decimal(38,4), @bal21 decimal(38,4), @balnotyetdue decimal(38,4),
    @bal3 decimal(38,4)

declare @newend datetime
if not exists (select clientno from clients where clientno = @ClientNo)
	return -1
if @BalancesOnly = 0
begin
	-- consolidate deal amounts so that charges don't show as itemized
	-- do non-cancelled first, then cancelled ones
	update transactions
	set sumamount =	(select sum(t2.amount) --select * from transactions
			from transactions t2
			where (t2.dealno = transactions.dealno) and (t2.transcode not like '%CNL') and ClientNo = @ClientNo) --and (transcode not like '%LV%'))
	where (ClientNo = @ClientNo) and (transcode in ('PURCH','SALE')) and (dealno is not null)
	
	update transactions
	set sumamount =	(select sum(t2.amount)
			from transactions t2
			where (t2.dealno = transactions.dealno) and (t2.transcode like '%CNL')  and ClientNo = @ClientNo) --and (transcode not like '%LV%'))
	where (ClientNo = @ClientNo) and (transcode in ('PURCHCNL','SALECNL')) and (dealno is not null)
	
	exec FixArrearsSingle @ClientNo
end
select @StatementDate = cast((floor(convert(float,@StatementDate))) as datetime)
select @StartDate = cast((floor(convert(float,@StartDate))) as datetime)
select @EndDate = cast((floor(convert(float,@EndDate))) as datetime)
/*
select top 1 @balnow = arrearscf
from transactions
where (ClientNo = @clientno)
order by TransDate desc, transid desc
*/
select @balnow = sum(amount) from transactions where (ClientNo = @clientno) and (TransDate <= @EndDate) 
select @baltemp = @balnow
select @bal3 = 0, @bal7 = 0, @bal14 = 0, @bal21 = 0, @bal30 = 0, @bal60 = 0, @bal90 = 0, @bal120 = 0, @bal180 = 0, @balnotyetdue = 0
select top 1 @balopen = arrearsbf
from transactions
where (ClientNo = @clientno) and (TransDate >= @StartDate)
order by TransDate asc, transid asc
if @balnow > 0
begin
	-- do the 3-day aging
	select @newend = @EndDate
	select @bal3 = sum(amount) from transactions
	where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-2,@newend)) and (TransDate <= @newend) and (amount > 0) 
	if @bal3 is null select @bal3 = 0
	if @bal3 >= @baltemp
		select @bal3 = @baltemp
	select @baltemp = @baltemp - @bal3

	-- do the 7-day aging
	select @newend = @EndDate
	select @bal7 = sum(amount) from transactions
	where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-6,@newend)) and (TransDate <= @newend) and (amount > 0) 
	if @bal7 is null select @bal7 = 0
	if @bal7 >= @baltemp
		select @bal7 = @baltemp
	select @baltemp = @baltemp - @bal7
	
	if (@baltemp > 0) or (@StartAgeingAt30 = 1)
	begin
		-- do the 14-day aging
		select @newend = dateadd(d,-7,@newend)
		select @bal14 = sum(amount) from transactions
		where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-6,@newend)) and (TransDate <= @newend) and (amount > 0) 
		if @bal14 is null select @bal14 = 0
		if @bal14 >= @baltemp
			select @bal14 = @baltemp
		select @baltemp = @baltemp - @bal14

		if (@baltemp > 0) or (@StartAgeingAt30 = 1)
		begin
			-- do the 21-day aging
			select @newend = dateadd(d,-7,@newend)
			select @bal21 = sum(amount) from transactions
			where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-6,@newend)) and (TransDate <= @newend) and (amount > 0) 
			if @bal21 is null select @bal21 = 0
			if @bal21 >= @baltemp
				select @bal21 = @baltemp
			select @baltemp = @baltemp - @bal21

			if (@baltemp > 0) or (@StartAgeingAt30 = 1)
			begin
				-- do the 30-day aging
				if @StartAgeingAt30 = 0
				begin -- continue from 21 days (so this amt will only incl. trxns btwn the 21st and 30th days)
					--select @newend = @EndDate
					select @newend = dateadd(d,-7,@newend)
					select @bal30 = sum(amount) from transactions
					where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-8,@newend)) and (TransDate <= @newend) and (amount > 0) 
				end
				else
				begin	-- we start as if 30-days was the first ageing period, so just sum everything in the last 30 days from statement date
					select @baltemp = @balnow   -- reset the starting bal, coz we're starting here
					select @newend = @EndDate
					select @newend = dateadd(d,-30,@newend)
					select @bal30 = sum(amount) from transactions
					where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount > 0) 
				end
				if @bal30 is null select @bal30 = 0
				if @bal30 >= @baltemp
					select @bal30 = @baltemp
				select @baltemp = @baltemp - @bal30
				
				if @baltemp > 0
				begin
					-- do the 60-day aging
					if @StartAgeingAt30 = 0  -- move from 21 to 30
						select @newend = dateadd(d,-9,@newend)
					else
						select @newend = dateadd(d,-30,@newend)
					select @bal60 = sum(amount) from transactions
					where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount > 0) 
					if @bal60 is null select @bal60 = 0
					if @bal60 >= @baltemp
						select @bal60 = @baltemp
					select @baltemp = @baltemp - @bal60

					if @baltemp > 0
					begin
						-- do the 90-day aging
						select @newend = dateadd(d,-30,@newend)
						select @bal90 = sum(amount) from transactions
						where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount > 0) 
						if @bal90 is null select @bal90 = 0
						if @bal90 >= @baltemp
							select @bal90 = @baltemp
						select @baltemp = @baltemp - @bal90

						if @baltemp > 0
						begin
							-- do the 120-day aging
							select @newend = dateadd(d,-30,@newend)
							select @bal120 = sum(amount) from transactions
							where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount > 0) 
							if @bal120 is null select @bal120 = 0
							if @bal120 >= @baltemp
								select @bal120 = @baltemp
							select @baltemp = @baltemp - @bal120

							if @baltemp > 0
							begin
								-- do the 120-PLUS-day aging
								select @newend = dateadd(d,-30,@newend)
								select @bal180 = sum(amount) from transactions
								where (ClientNo = @ClientNo) and (TransDate <= @newend) and (amount > 0) 
								if @bal180 is null select @bal180 = 0
								if @bal180 >= @baltemp
									select @bal180 = @baltemp
								select @baltemp = @baltemp - @bal180
							end
						end
					end
				end
			end
		end
	end
end
else if @balnow < 0	-- reversed aging (same as above, but logic for -ve #s)
begin
		-- do the 3-day aging
	select @newend = @EndDate
	select @bal3 = sum(amount) from transactions
	where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-2,@newend)) and (TransDate <= @newend) and (amount < 0)
	if @bal3 is null select @bal3 = 0
	if @bal3 >= @baltemp
		select @bal3 = @baltemp
	select @baltemp = @baltemp - @bal3

		-- do the 7-day aging
	select @newend = @EndDate
	select @bal7 = sum(amount) from transactions
	where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-6,@newend)) and (TransDate <= @newend) and (amount < 0)
	if @bal7 is null select @bal7 = 0
	if @bal7 >= @baltemp
		select @bal7 = @baltemp
	select @baltemp = @baltemp - @bal7
	
	if (@baltemp > 0) or (@StartAgeingAt30 = 1)
	begin
		-- do the 14-day aging
		select @newend = dateadd(d,-7,@newend)
		select @bal14 = sum(amount) from transactions
		where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-6,@newend)) and (TransDate <= @newend) and (amount < 0)
		if @bal14 is null select @bal14 = 0
		if @bal14 >= @baltemp
			select @bal14 = @baltemp
		select @baltemp = @baltemp - @bal14

		if (@baltemp > 0) or (@StartAgeingAt30 = 1)
		begin
			-- do the 21-day aging
			select @newend = dateadd(d,-7,@newend)
			select @bal21 = sum(amount) from transactions
			where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-6,@newend)) and (TransDate <= @newend) and (amount < 0)
			if @bal21 is null select @bal21 = 0
			if @bal21 >= @baltemp
				select @bal21 = @baltemp
			select @baltemp = @baltemp - @bal21

			if (@baltemp > 0) or (@StartAgeingAt30 = 1)
			begin
				-- do the 30-day aging
				if @StartAgeingAt30 = 0
				begin -- continue from 21 days (so this amt will only trxns btwn the 21st and 30th days)
					--select @newend = @EndDate
					select @newend = dateadd(d,-7,@newend)
					select @bal30 = sum(amount) from transactions
					where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-8,@newend)) and (TransDate <= @newend) and (amount < 0)
				end
				else
				begin	-- we start as if 30-days was the first ageing period, so just sum everything in the last 30 days from statement date
					select @baltemp = @balnow   -- reset the starting bal, coz we're starting here
					select @newend = @EndDate
					select @newend = dateadd(d,-30,@newend)
					select @bal30 = sum(amount) from transactions
					where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount < 0)
				end
				if @bal30 is null select @bal30 = 0
				if @bal30 >= @baltemp
					select @bal30 = @baltemp
				select @baltemp = @baltemp - @bal30
				
				if @baltemp > 0
				begin
					-- do the 60-day aging
					if @StartAgeingAt30 = 0  -- move from 21 to 30
						select @newend = dateadd(d,-9,@newend)
					else
						select @newend = dateadd(d,-30,@newend)
					select @bal60 = sum(amount) from transactions
					where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount < 0)
					if @bal60 is null select @bal60 = 0
					if @bal60 <= @baltemp
						select @bal60 = @baltemp
					select @baltemp = @baltemp - @bal60
					if @baltemp < 0
					begin
						-- do the 90-day aging
						select @newend = dateadd(d,-30,@newend)
						select @bal90 = sum(amount) from transactions
						where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount < 0)
						if @bal90 is null select @bal90 = 0
						if @bal90 <= @baltemp
							select @bal90 = @baltemp
						select @baltemp = @baltemp - @bal90
						if @baltemp < 0
						begin
							-- do the 120-day aging
							select @newend = dateadd(d,-30,@newend)
							select @bal120 = sum(amount) from transactions
							where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend) and (amount < 0)
							if @bal120 is null select @bal120 = 0
							if @bal120 <= @baltemp
								select @bal120 = @baltemp
							select @baltemp = @baltemp - @bal120
							if @baltemp < 0
							begin
								-- do the 120-PLUS-day aging
								select @newend = dateadd(d,-30,@newend)
								select @bal180 = sum(amount) from transactions
								where (ClientNo = @ClientNo) and (TransDate <= @newend) and (amount < 0)
								if @bal180 is null select @bal180 = 0
								if @bal180 <= @baltemp
									select @bal180 = @baltemp
								select @baltemp = @baltemp - @bal180
							end
						end
					end
				end
			end
		end
	end
end
/*
select @bal60 = sum(amount) from transactions
where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend)
select @newend = dateadd(d,-30,@newend)
select @bal90 = sum(amount) from transactions
where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend)
select @newend = dateadd(d,-30,@newend)
select @bal120 = sum(amount) from transactions
where (ClientNo = @ClientNo) and (TransDate >= dateadd(d,-29,@newend)) and (TransDate <= @newend)
select @newend = dateadd(d,-30,@newend)
select @bal180 = sum(amount) from transactions
where (ClientNo = @ClientNo) and (TransDate <= @newend)
*/
if @ShowArrearsNotYetDue = 1
	--select @balnotyetdue = sum(amount) from transactions where (ClientNo = @ClientNo) and (dealno is not null) and (datediff(d,TransDate,@EndDate) < 7)
select @balnotyetdue = sum(amount) from transactions where (ClientNo = @ClientNo) and (dealno is not null) and (datediff(d,TransDate,@EndDate) < 3)  
if @balopen is null select @balopen = 0
if @balnow is null select @balnow = 0
if @bal7 is null select @bal7 = 0
if @bal14 is null select @bal14 = 0
if @bal21 is null select @bal21 = 0
if @bal30 is null select @bal30 = 0
if @bal60 is null select @bal60 = 0
if @bal90 is null select @bal90 = 0
if @bal120 is null select @bal120 = 0
if @bal180 is null select @bal180 = 0
if @balnotyetdue is null select @balnotyetdue = 0
delete from statements where (clientno = @ClientNo) and ([user] = @User)
insert into statements ([USER],CLIENTNO,STMTDATE,STARTDATE,ENDDATE,BALOPENING,BALCLOSING,ARREARS7,ARREARS14,ARREARS21,ARREARS30,ARREARS60,ARREARS90,ARREARS120,ARREARS180,ARREARSPENDING, ARREARS3) 
values (@User,@ClientNo,@StatementDate,@StartDate,@EndDate,@balopen,@balnow,@bal7,@bal14,@bal21,@bal30,@bal60,@bal90,@bal120,@bal180,@balnotyetdue,@bal3)

return 0

GO
/****** Object:  StoredProcedure [dbo].[SummarizeTrading]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions			                    }
{							                            }
{		Author: Ginson Mhlanga			                }
{							                            }
{		     Copyright (c) 2020		                }
{							                            }
{*******************************************************}
*/
CREATE  PROCEDURE [dbo].[SummarizeTrading]	(
	@StartDate	datetime,
	@EndDate	datetime
					)
AS
set nocount on
--declare @dealtype varchar(20), @dealno varchar(40), @dealdate datetime
--declare @asset varchar(20), @qty decimal, @price decimal(31,9), @consideration decimal(31,9), @commission decimal(31,9), @clientno varchar(50)
--declare @basiccharges decimal(31,9), @sharesout decimal, @chqno decimal, @wtax decimal(31,9),@commissionerlevy decimal(31,9),@investorprotection decimal(31,9),@capitalgains decimal(31,9),@zselevy decimal(31,9)
	truncate table tradingsummary
	insert into	tradingsummary
			(dealtype,dealno,dealdate,clientno,category,asset,qty,price,consideration,commission,
			basiccharges,CONTRACTSTAMPS,sharesout,chqno,wtax,commissionerlevy,investorprotection,capitalgains,zselevy,vat)
	select	d.dealtype,d.dealno,d.dealdate,ltrim(rtrim(x.companyname+ ' '+x.surname+ ' ' + x.firstname)),'OTHER',d.asset,d.qty,d.price,d.consideration,d.grosscommission,
		d.csdlevy,d.stampduty,d.sharesout,d.chqno,d.wtax,d.commissionerlevy,d.investorprotection,d.capitalgains,d.zselevy,d.vat
	from	dealallocations d inner join clients x on d.clientno = x.clientno
	where	(d.dealdate >= @StartDate) and (d.dealdate <= @EndDate) and (d.approved = 1) and
		(d.cancelled = 0) and (d.merged = 0)
		
update TRADINGSUMMARY set CATEGORY='BROKER' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY='broker')
update TRADINGSUMMARY set CATEGORY='NMI' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY = 'NMI')
update TRADINGSUMMARY set CATEGORY='NMI - NO TAX' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY = 'NMI - NO TAX')
update TRADINGSUMMARY set CATEGORY='INDIVIDUAL' where CLIENTNO in (select CLIENTNO from CLIENTS where CATEGORY = 'OTHER')
update TRADINGSUMMARY set StartDate=@StartDate,EndDate=@EndDate


--select * from tradingsummary
GO
/****** Object:  StoredProcedure [dbo].[TimeoutUsers]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/*
{*******************************************************}
{			Adept Solutions								}
{														}
{		Author: S.Kamonere								}
{														}
{		     Copyright (c) 2012							}
{														}
{*******************************************************}
*/
CREATE PROCEDURE [dbo].[TimeoutUsers]-- TimeoutUsers 'ADEPT',1
	@User varchar(50),
	@LoggingIn bit,
	@ScreenName varchar(100)
AS
	declare @SessionExpired as bit
	declare @Host varchar(512)
	
	select @Host=HOST_NAME()
	if (@LoggingIn=1)
	begin
	 update USERS set  lastping = GETDATE(),loggedin=1,LOGINAT=GETDATE(), lastscreen=@screenname where [LOGIN]=@User
	 select 0 as HasExpired	
	 return
	end
	update USERS set  PCNAME=@Host,LOGGEDIN=1 where [LOGIN]=@User
	update users set loggedin = 0,lastscreen=@screenname  /*, lastscreen = null, pcname = null, pclicense = null*/
	where (loggedin = 1) and (lastping is not null) and (datediff(n,lastping,getdate()) >= 180) -- times out after 2minutes
	
	
	select @SessionExpired= loggedin from USERS where [LOGIN]=@user
	if (@SessionExpired=0)
		select 1 as HasExpired
	else
	begin
		update USERS set  lastping = GETDATE(),lastscreen=@screenname where [LOGIN]=@User
		select 0 as HasExpired	
	end
--return @sessionexpired

GO
/****** Object:  StoredProcedure [dbo].[TopTradersCommission]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: March 15 2011
-- Description:	Gets specified number of top commission generating clients 
-- =============================================
CREATE PROCEDURE [dbo].[TopTradersCommission]   --TopTradersCommission 3,'20100501','20110315'
	@Records int,
	@NMI varchar(50),
	@StartDate datetime,
	@EndDate datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	truncate table toptraders
	if(@NMI='NMI')
	begin
		insert into TopTraders (ClientNo,ClientName,Value)
		SELECT     TOP (@Records) dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME) AS ClientName, 
						  SUM(dbo.DEALALLOCATIONS.GrossCommission) AS value
		FROM         dbo.DEALALLOCATIONS INNER JOIN
							  dbo.CLIENTS ON dbo.DEALALLOCATIONS.ClientNo = dbo.CLIENTS.CLIENTNO
		WHERE     (dbo.DEALALLOCATIONS.DealDate >= @StartDate) AND (dbo.DEALALLOCATIONS.DealDate <= @EndDate) AND (dbo.DEALALLOCATIONS.Approved = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.Merged = 0)
		GROUP BY dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME)
		ORDER BY value DESC
	end
	else
	begin
		insert into TopTraders (ClientNo,ClientName,Value)
		SELECT     TOP (@Records) dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME) AS ClientName, 
						  SUM(dbo.DEALALLOCATIONS.GrossCommission) AS value
		FROM         dbo.DEALALLOCATIONS INNER JOIN
							  dbo.CLIENTS ON dbo.DEALALLOCATIONS.ClientNo = dbo.CLIENTS.CLIENTNO
		WHERE     (dbo.DEALALLOCATIONS.DealDate >= @StartDate) AND (dbo.DEALALLOCATIONS.DealDate <= @EndDate) AND (dbo.DEALALLOCATIONS.Approved = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.Merged = 0) and dbo.CLIENTS.CATEGORY not like 'nmi%'
		GROUP BY dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME)
		ORDER BY value DESC
	end
	
	update TopTraders set StartDate=@StartDate,EndDate=@EndDate
END

GO
/****** Object:  StoredProcedure [dbo].[TopTradersDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Kamonere
-- Create date: March 15 2011
-- Description:	Gets specified number of top commission generating clients 
-- =============================================
CREATE PROCEDURE [dbo].[TopTradersDeals]  --TopTradersDeals 10,'20090501','20110315','BUY'
	@Records iNT,
	@StartDate datetime,
	@EndDate datetime,
	@DealType varchar(50),
	@NMI varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	truncate table toptraders
	if(@NMI='NMI')
	begin
		insert into TopTraders (ClientNo,ClientName,Value)
		SELECT     TOP (@Records) dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME) AS ClientName, 
						  COUNT(dbo.DEALALLOCATIONS.DealType) AS value
		FROM         dbo.DEALALLOCATIONS INNER JOIN
							  dbo.CLIENTS ON dbo.DEALALLOCATIONS.ClientNo = dbo.CLIENTS.CLIENTNO
		WHERE     (dbo.CLIENTS.CATEGORY<>'broker') AND (dbo.DEALALLOCATIONS.DealType=@DealType) AND (dbo.DEALALLOCATIONS.DealDate >= @StartDate) AND (dbo.DEALALLOCATIONS.DealDate <= @EndDate) AND (dbo.DEALALLOCATIONS.Approved = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.Merged = 0)
		GROUP BY dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME)
		ORDER BY value DESC
	end
	else
	begin
		insert into TopTraders (ClientNo,ClientName,Value)
		SELECT     TOP (@Records) dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME) AS ClientName, 
						  COUNT(dbo.DEALALLOCATIONS.DealType) AS value
		FROM         dbo.DEALALLOCATIONS INNER JOIN
							  dbo.CLIENTS ON dbo.DEALALLOCATIONS.ClientNo = dbo.CLIENTS.CLIENTNO
		WHERE     (dbo.CLIENTS.CATEGORY<>'broker') AND (dbo.DEALALLOCATIONS.DealType=@DealType) AND (dbo.DEALALLOCATIONS.DealDate >= @StartDate) AND (dbo.DEALALLOCATIONS.DealDate <= @EndDate) AND (dbo.DEALALLOCATIONS.Approved = 1) AND 
							  (dbo.DEALALLOCATIONS.Cancelled = 0) AND (dbo.DEALALLOCATIONS.Merged = 0) and dbo.CLIENTS.CATEGORY not like 'nmi%'
		GROUP BY dbo.DEALALLOCATIONS.ClientNo, COALESCE (dbo.CLIENTS.SURNAME + ' ' + dbo.CLIENTS.FIRSTNAME, dbo.CLIENTS.COMPANYNAME)
		ORDER BY value DESC
	end
	update TopTraders set DealType=@DealType,StartDate=@StartDate,EndDate=@EndDate
END

GO
/****** Object:  StoredProcedure [dbo].[TrackClientStatus]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Simpson Kamonere
-- Create date: Nov. 12 2011
-- Description:	Updates Clients Status
-- =============================================
CREATE PROCEDURE [dbo].[TrackClientStatus]  --TrackClientStatus '315FBC'
	@ClientNo as varchar(50)
AS
BEGIN
	declare @DormantDays int
	SET NOCOUNT ON;
	select @DormantDays =dormantdays from BusinessRules
	--select @dormantdays
	update ClientsCommunication set LastTxnDate=GETDATE() where ClientNo=@ClientNo
    update CLIENTS set STATUS='ACTIVE' where CLIENTNO=@ClientNo
    
    begin
		merge into Clients
		using ClientsCommunication
		on ClientsCommunication.ClientNo = Clients.ClientNo 

		when matched and (clients.category<>'broker') and (Clients.[status] in ('PENDING','ACTIVE')) and (datediff(dd,clientscommunication.lasttxndate,getdate())>=@dormantdays)

		then
			update set Clients.[Status]='DORMANT',statusreason='NO RECENT TRANSACTIONS',editedby='SYSTEM',dateedited=getdate(),statusdate=getdate()  
		;
	end
--select datediff(dd,'20110801',getdate())





END


GO
/****** Object:  StoredProcedure [dbo].[TradingClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TradingClients]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, 
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName, dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients INNER JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     (dbo.Clients.Status <> 'INACTIVE') and Category not in('broker','TAX ACCOUNT','transfer secretary')
	order by dbo.Clients.ClientName, dbo.Clients.ClientNo
END

GO
/****** Object:  StoredProcedure [dbo].[TradingClientsBrokers]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: Oct. 2011
-- Description:	Clients Selection
-- =============================================
CREATE PROCEDURE [dbo].[TradingClientsBrokers] --Active clients in DB including brokers 
@StartDate datetime='20000101',
@EndDate datetime='99991231'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.AltMobile,dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, dbo.Clients.Sector,dbo.Clients.UtilityType,
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName,dbo.clients.Bank,dbo.clients.BankAccountNo ,dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients LEFT JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     Category not in('transfer secretary') and Category not in('tax account')
	--order by dbo.Clients.ClientName, dbo.Clients.ClientNo,Category desc
	order by COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName), dbo.Clients.ClientNo,Category desc
END


GO
/****** Object:  StoredProcedure [dbo].[TradingClientsNoBrokers]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		S. Kamonere
-- Create date: Oct. 2011
-- Description:	Clients Selection
-- =============================================
CREATE PROCEDURE [dbo].[TradingClientsNoBrokers] --Active clients in DB excluding brokers,tsecs and tax accounts 
@StartDate datetime='20000101',
@EndDate datetime='99991231'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT     dbo.Clients.CID, dbo.Clients.ClientNo, dbo.Clients.ShortCode, dbo.Clients.Title, dbo.Clients.Surname, dbo.Clients.Firstname, 
						  dbo.Clients.CompanyName, dbo.Clients.Type, dbo.Clients.Category, dbo.Clients.Status, dbo.Clients.StatusReason, dbo.Clients.IDType, 
						  dbo.Clients.IDNo, dbo.Clients.PhysicalAddress, dbo.Clients.PostalAddress, dbo.Clients.UsePhysicalAddress, dbo.Clients.ContactNo, 
						  dbo.Clients.MobileNo, dbo.Clients.AltMobile,dbo.Clients.Fax, dbo.Clients.Email, dbo.Clients.DateAdded, dbo.Clients.Bank, dbo.Clients.BankBranch, 
						  dbo.Clients.BankAccountNo, dbo.Clients.BankAccountType, dbo.Clients.BuySettle, dbo.Clients.SellSettle, dbo.Clients.DeliveryOption, 
						  dbo.Clients.LoginID, dbo.Clients.Sex, dbo.Clients.UtilityNo, dbo.Clients.Directors, dbo.Clients.ReferredBy, dbo.Clients.Photo, 
						  dbo.Clients.ContactPerson, dbo.Clients.Employer, dbo.Clients.JobTitle, dbo.Clients.BusPhone, dbo.Clients.Sector,dbo.Clients.UtilityType,
						  COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName) AS ClientName,dbo.clients.Bank,dbo.clients.BankAccountNo ,dbo.ClientsCommunication.SMSDeals, 
						  dbo.ClientsCommunication.SMSScrip, dbo.ClientsCommunication.SMSCorpAction, dbo.ClientsCommunication.SMSPrices, 
						  dbo.ClientsCommunication.SMSOther, dbo.ClientsCommunication.EmailDeals, dbo.ClientsCommunication.EmailScrip, 
						  dbo.ClientsCommunication.EmailCorpAction, dbo.ClientsCommunication.EmailPrices, dbo.ClientsCommunication.EmailOther
	FROM         dbo.Clients LEFT JOIN
						  dbo.ClientsCommunication ON dbo.Clients.ClientNo = dbo.ClientsCommunication.ClientNo
	WHERE     (dbo.Clients.Status <> 'closed') and (dbo.Clients.Status <> 'inactive') and Category not in('transfer secretary') and Category not in('broker') and Category not in('tax account')
	--order by Category desc, dbo.Clients.ClientName, dbo.Clients.ClientNo
	order by Category desc, COALESCE (dbo.Clients.Surname + ' ' + dbo.Clients.Firstname, dbo.Clients.CompanyName), dbo.Clients.ClientNo
END


GO
/****** Object:  StoredProcedure [dbo].[Transact]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		Copyright (c) 2003, 2005		}
{							}
{*******************************************************}
Return Values:
0	Success
-1	Failure
*/
 CREATE           PROCEDURE [dbo].[Transact]	(
	@User			varchar(20),
	@ClientNo		int,
	@DealNo			varchar(40) = NULL,
	@TransCode		varchar(50),
	@TransDate		datetime = NULL,
	@Description		varchar(50) = NULL,
	@Amount			decimal(38,4),
    --@Amount			varchar(50),
	@Cash			bit = 0,
	@Bank			varchar(50) = NULL,
	@BankBranch		varchar(20) = NULL,
	@ChequeNo		varchar(20) = NULL,
	@Drawer			varchar(50) = NULL,
	@RefNo			varchar(40) = NULL,
	@CashBookID		int = 0,
        --@Divided                bit = 0,
    @Transid int = 0
				) 
AS


declare @BF decimal(38,4), @CF decimal(38,4), @NewTransDate datetime
declare @IsCredit bit
declare @Amount1 decimal(38,4)
declare @Amount2 decimal(38,4)
declare @Factor numeric

select @Amount1 = @Amount

/*select @Factor = Factor from AccountsParams
select @Amount2 = convert(decimal(38,2), @Amount)

if @Divided = 1
 select @Amount1 = @amount2*@Factor
else
 select @Amount1 = @amount2 */

select @BF = 0, @CF = 0

select top 1 @BF = ARREARSCF from Transactions 
where (CNO = @ClientNo)
order by transdt desc, transid desc   --order by postdt desc
if @@ERROR <> 0 return -1
select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
if @@ERROR <> 0 return -1
if @IsCredit = 1
	select @Amount1 = -@Amount1
select @CF = @BF + @Amount1
if @TransDate is NULL
	select @TransDate = GetDate()
select @NewTransDate = cast((floor(convert(float,@TransDate))) as datetime)
--if @CashBookID = 0
--	select @CashBookID = null

if @TransID <> 0 
 begin
  select @CashBookID = cashbookid from transactions
  where transid = @TransID
 end 

insert into Transactions
([USER],CNO,POSTDT,DEALNO,TRANSCODE,TRANSDT,[REFNO],[DESCRIPTION],AMOUNT,CASH,BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID, OriginalTransID)
values
(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID, @TransID)
if @@ERROR <> 0
	return -1
else
begin
	exec FixArrearsSingle @ClientNo
	if (@TransCode = 'REC') or (@TransCode = 'PAY')  -- ******* also remember to cater for RECCNL AND PAYCNL
	begin
		select @Amount1 = -@Amount1
		exec AdjustCashBal @NewTransDate, @CashBookID, @Amount1
	end
	else
		if (@TransCode = 'RECCNL') or (@TransCode = 'PAYCNL')
		begin
			select @Amount1 = -@Amount1
			exec AdjustCashBal @NewTransDate, @CashBookID, @Amount1
		end
	return 0
end







GO
/****** Object:  StoredProcedure [dbo].[TransactRev]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
{*******************************************************}
{							}
{		Author: Tinashe Rondozai		}
{							}
{		Copyright (c) 2003,2005			}
{							}
{*******************************************************}
*/
CREATE     PROCEDURE [dbo].[TransactRev]	(
	@ID	int,
	@User	varchar(20)
					)
AS
declare @ClientNo int, @DealNo varchar(40), @Description varchar(50),
	@Amount money, @BF money, @CF money, @inc bit, @OrigCode varchar(50),
	@RefNo varchar(10), @ChqNo varchar(20), @NewTransDate datetime,
	@CashBookID int
select @ClientNo = -1
select	@ClientNo = CNO, @DealNo = DEALNO, @Amount = AMOUNT,
	@OrigCode = TRANSCODE, @ChqNo = CHQNO, @CashBookID = CASHBOOKID
from TRANSACTIONS
where TRANSID = @ID
if @ClientNo < 0
	return -1
select @RefNo = convert(varchar(10),@ID)
select @Description = 'REVERSAL OF TRANSACTION #' + @RefNo -- ,@Amount = -@Amount
select @BF = 0, @CF = 0
select top 1 @BF = ARREARSCF
from Transactions
where (CNO = @ClientNo)
order by transdt desc, transid desc  --order by postdt desc
select @NewTransDate = cast((floor(convert(float,GetDate()))) as datetime)
select @CF = @BF - @Amount	--In Transact we said @CF=@BF+@Amount (where @Amount could be -ve)
insert into Transactions
([USER],CNO,POSTDT,DEALNO,TRANSCODE,TRANSDT,REFNO,[DESCRIPTION],AMOUNT,CASH,BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID)
values
(@User,@ClientNo,GetDate(),@DealNo,'REV',@NewTransDate,@RefNo,@Description,-@Amount,0,NULL,NULL,NULL,NULL,@BF,@CF,@CashBookID)
if @@ERROR <> 0
	return -1
else
begin
	exec FixArrearsSingle @ClientNo
	if (@OrigCode = 'REC') or (@OrigCode = 'PAY')  -- ******* also remember to cater for RECCNL AND PAYCNL
	begin
		exec AdjustCashBal @NewTransDate, @CashBookID, @Amount
/*
		if @OrigCode = 'PAY'
		begin
			if (@ChqNo is not null) and (@ChqNo <> '')
			begin
				update dealallocations set CHQNO = NULL, CHQPRINTED = 0 where (CHQNO = @ChqNo) and (dealtype like 'S%')
				update suppchqs set cancelled = 1 where CHQID = @ChqNo
			end
		end
		else
			if @OrigCode = 'REC'
				update dealallocations set CHQNO = NULL, CHQPRINTED = 0 where (CHQNO = @ID) and (dealtype like 'B%')
*/
	end
	return 0
end

GO
/****** Object:  StoredProcedure [dbo].[ViewBrokerDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ViewBrokerDeals]--ViewBrokerDeals '20121128','CONFIRMED'
	@DealDate as datetime,
	@Status as varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

    SELECT     TOP (100) PERCENT dbo.DOCKETS.DocketNo, dbo.DOCKETS.AssetCode, dbo.DOCKETS.DocketDate, dbo.DOCKETS.BrokerNo, dbo.DOCKETS.COUNTERPARTY, 
                      dbo.DOCKETS.DealType, dbo.DOCKETS.EXTERNALF, dbo.DOCKETS.STATUS, dbo.DOCKETS.Price, dbo.DOCKETS.Qty, dbo.DOCKETS.DealValue, 
                      dbo.DOCKETS.BALBF, dbo.DOCKETS.ZSEREFNO, dbo.DOCKETS.BALCF, dbo.DOCKETS.USERID, dbo.DOCKETS.COMMENTS, dbo.DOCKETS.LOGIN, 
                      dbo.DOCKETS.ADJUSTMENT, dbo.DOCKETS.BnB, dbo.DOCKETS.DateAdded, dbo.DOCKETS.CancelDate, dbo.DOCKETS.CancelledBy, dbo.CLIENTS.CompanyName, 
                      dbo.DEALALLOCATIONS.DealNo
	FROM         dbo.DOCKETS INNER JOIN
						  dbo.CLIENTS ON dbo.CLIENTS.ClientNo = dbo.DOCKETS.BrokerNo INNER JOIN
						  dbo.DEALALLOCATIONS ON dbo.DOCKETS.DocketNo = dbo.DEALALLOCATIONS.DocketNo AND dbo.DOCKETS.BrokerNo = dbo.DEALALLOCATIONS.ClientNo
	WHERE     (dbo.DOCKETS.DocketDate = @DealDate) AND (dbo.DOCKETS.[STATUS] = @Status) and DEALALLOCATIONS.YON=1
	ORDER BY dbo.DOCKETS.AssetCode
END


GO
/****** Object:  UserDefinedFunction [dbo].[CalcClientBalance]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CalcClientBalance]
(
	@ClientNo varchar(50),
	@AsAt date = null
)
RETURNS float
AS
BEGIN
	-- Declare the return variable here
	declare @txnsbalance float
	declare @LedgerBalance float
	declare @Balance float
	declare @AtDate datetime
	
	if (@AsAt is null)
		select @AsAt=GETDATE()
		
	select @AtDate= DATEADD(D,1,@AsAt)	
	
	select @txnsbalance=SUM(amount) from cashbooktrans where clientno=@ClientNo and transdate<@AtDate
	--if (@txnsbalance is null)
	--	select @txnsbalance=0
	select @LedgerBalance=SUM(amount) from Transactions where 
	(dbo.Transactions.TransCode = 'TAKEONDB' OR
				dbo.Transactions.TransCode = 'TAKEONCR' OR
				dbo.Transactions.TransCode = 'NMIRBT' OR
				dbo.Transactions.TransCode = 'AINCJ' OR
			          dbo.Transactions.TransCode = 'NMIRBTCNL' OR
                      dbo.Transactions.TransCode = 'SALE' OR
                      dbo.Transactions.TransCode = 'TPAYFEECNL' OR
                      dbo.Transactions.TransCode = 'TPAYFEE' OR
                      dbo.Transactions.TransCode = 'SALECNL' OR
                      dbo.Transactions.TransCode = 'PURCH' OR
                      dbo.Transactions.TransCode = 'PURCHCNL' OR
                      dbo.Transactions.TransCode = 'DIVPAY' OR
                      dbo.Transactions.TransCode = 'DIVREC') and clientno=@ClientNo and transdate<@AtDate
	if @LedgerBalance is null
		select @LedgerBalance=0
	if @txnsbalance is null
		select @txnsBalance=0
		
	select @Balance=@txnsbalance+@LedgerBalance
  --  if @Balance is null
		--select  @Balance= 0
	return @Balance	
END

GO
/****** Object:  UserDefinedFunction [dbo].[CalcRebate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CalcRebate] -- select dbo.CalcRebate ('258FBC','20110817')
(
	@ClientNo varchar(50),
	@AsAt date = null
)
RETURNS float
AS
BEGIN
	-- Declare the return variable here
	declare @txnsbalance float
	declare @LedgerBalance float
	declare @Balance float
	declare @AtDate datetime
	
	if (@AsAt is null)
		select @AsAt=GETDATE()
		
	select @AtDate= DATEADD(D,1,@AsAt)	
	
	select @txnsbalance=SUM(amount) from cashbooktrans where TransCode like 'nmi%' and clientno=@ClientNo and transdate<=@AsAt
	--if (@txnsbalance is null)
	--	select @txnsbalance=0
	
	select @LedgerBalance=SUM(nmirebate) from DEALALLOCATIONS where APPROVED=1 and Cancelled=0 and MERGED=0 and DealNo in (select DealNo from transactions)
	and ClientNo=@ClientNo and DealDate<=@AsAt
	--select @LedgerBalance=SUM(AMOUNTOldFalcon) from Transactions where clientno=@ClientNo and transdate<@AtDate
	if @LedgerBalance is null
		select @LedgerBalance=0
	if @txnsbalance is null
		select @txnsBalance=0
		
	select @Balance=@txnsbalance+@LedgerBalance
  --  if @Balance is null
		--select  @Balance= 0
	return round(@Balance,2)	
END


GO
/****** Object:  UserDefinedFunction [dbo].[CalcTaxBalance]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CalcTaxBalance] --select dbo.calctaxbalance('157','nmi','20110809')
(
	@ClientNo varchar(50),
	@Ledger varchar(50), --for backward compatibility
	@AsAt date = null
)
RETURNS float
AS
BEGIN
	-- Declare the return variable here
	declare @OldTxnsBalance float=0
	declare @OldLedgerBalance float=0
	declare @txnsbalance float=0
	declare @LedgerBalance float=0
	declare @Balance float=0
	declare @AtDate datetime
	declare @StartTxnDate as datetime
	
	declare @LedgerTxns as varchar(50)
	declare @LedgerPayments as varchar(50)
	
	set @StartTxnDate='20090201' --start date for processing charges
	
	if (@AsAt is null)
		select @AsAt=GETDATE()
		
	select @AtDate= @AsAt
	
	if(@ClientNo='152')
	begin
		select @LedgerTxns='sduty'
		select @LedgerPayments='sdd'
	end
	if(@ClientNo='158')
	begin
		select @LedgerTxns='bfee'
		select @LedgerPayments='bfeed'
	end	
	if(@ClientNo='151')
	begin
		select @LedgerTxns='vat'
		select @LedgerPayments='vat'
	end
	if(@ClientNo='154')
	begin
		select @LedgerTxns='captax'
		select @LedgerPayments='captax'
	end
	if(@ClientNo='155')
	begin
		select @LedgerTxns='invprot'
		select @LedgerPayments='invprot'
	end
	if(@ClientNo='153')
	begin
		select @LedgerTxns='zselv'
		select @LedgerPayments='zselv'
	end
	if(@ClientNo='156')
	begin
		select @LedgerTxns='commlv'
		select @LedgerPayments='commlv'
	end
	if(@ClientNo='150')
	begin
		select @LedgerTxns='comms'
		select @LedgerPayments='comms'
	end
	if(@ClientNo='157')
	begin
		select @LedgerTxns='nmi'
		select @LedgerPayments='nmi'
		set @StartTxnDate='20111101'
	end
	
	if(@ClientNo='159')
	begin
		select @LedgerTxns='csd'
		select @LedgerPayments='csd'
		set @StartTxnDate='20140718'
	end
	----------------------------------------------------------------------------------------------------------------------------------
	--calculating ledger balance from old falcon.
	select @OldTxnsBalance=SUM(amount) from cashbooktrans where (TRANSCODE like @LedgerPayments+'%') and TransDate>= @StartTxnDate and transdate<=@AsAt
	select @OldLedgerBalance=SUM(amount) from Transactions where (TRANSCODE like @LedgerTxns+'%') and TransDate>= @StartTxnDate and transdate<=@AsAt	
	if @OldLedgerBalance is null
		select @OldLedgerBalance=0
	if @OldTxnsBalance is null
		select @OldtxnsBalance=0
	-----------------------------------------------------------------------------------------------------------------------------------
	--select @txnsbalance=SUM(amount) from cashbooktrans where clientno=@ClientNo and transdate<@AtDate
	--select @LedgerBalance= SUM(amount) from Transactions where clientno=@ClientNo and transdate<@AtDate
	--if @LedgerBalance is null
	--	select @LedgerBalance=0
	--if @txnsbalance is null
	--	select @txnsBalance=0
	
			
	select @Balance=(@OldTxnsBalance+@OldLedgerBalance)--+@txnsbalance+@LedgerBalance
	
	if (@ClientNo='157')
		select @Balance=-@Balance
	
  		return round(@Balance,2)	
END

GO
/****** Object:  UserDefinedFunction [dbo].[CalculateHistory]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[CalculateHistory]
	(@Status varchar(20), @current money, @ob money, @oo money, @os money, @cb money, @co money, @cs money)
RETURNS money AS
BEGIN 
	declare @result money
	if (@Status <> 'ACTIVE') or ((@co = 0) and (@cb = 0) and (@cs = 0))
	begin
		if (@ob = 0) and (@oo = 0) and (@os = 0)
      			select @result = @current
		else
			if @os > 0
				select @result = @os
			else
				if @ob >= @current
					select @result = @ob
				else
					if (@oo > 0) and (@oo <= @current)
					begin
						if @ob > 0
							select @result = @ob
						else
							select @result = 0.9*@co;
					end
					else
						select @result = @current;
	end
	else
	begin
		if (@cs >= @cb) and (@cs > 0)
		begin
			if (@co > 0) and (@co < @cs)
			begin
				if (0.9*@co) > @cb
					select @result = 0.9*@co
				else
					select @result = @cb
			end
			else
				select @result = @cs
		end
		else
			if @os > 0
			begin
				if @cb >= @os
					select @result = @cb
				else
					if @cb = 0
					begin
						if (0.9*@co) > @os
							select @result = @os
						else
							select @result = 0.9*@co
					end
					else
					begin
						if (@co = 0) or (@co > @os)
							select @result = @os
						else
							select @result = @ob
					end
			end
			else
			begin
				if @cb > 0
					select @result = @cb
				else
					select @result = 0.9*@co
			end
	end
	if @result = 0
		select @result = @current
	return @result
END

GO
/****** Object:  UserDefinedFunction [dbo].[CalculateHistoryExch]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[CalculateHistoryExch]
	(@Status varchar(20), @current money, @ob money, @oo money, @os money, @cb money, @co money, @cs money)
RETURNS money AS
BEGIN 
	declare @price money, @bid money, @offer money
	select @bid = 0
	select @offer = 0
	if @cs > 0
		select @price = @cs
	else
	begin
		if @os > 0
			select @price = @os
		else
			select @price = @current
	end
	if @cb > 0
		select @bid = @cb
	else
		if @co <= 0
			select @bid = @ob
	if @co > 0
		select @offer = @co
	else
		if @cb <= 0
			select @offer = @oo
	if @bid > @price
		select @price = @bid
	else
		if (@offer > 0) and (@offer < @price)
			select @price = @offer
	if @price = 0
		select @price = @current
	return @price
END

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateCapitalGains]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnCalculateCapitalGains](
@consideration money
,@client varchar(30))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.CapitalGains, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateCommission]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnCalculateCommission](
@consideration money
,@client varchar(30))
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
/****** Object:  UserDefinedFunction [dbo].[fnCalculateCSDLevy]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[fnCalculateInvestorProtection]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[fnCalculateSecLevy]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[fnCalculateStampDuty]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[fnCalculateVAT]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnCalculateVAT](
@consideration money
,@client varchar(30))
returns money
as
begin
	declare @rate float, @commission float;

	select @rate = isnull(x.vat, 1), @commission = isnull(x.commission, 1)/100 from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100* @commission
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnCalculateZSELevy]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[fnFormatDate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnFormatDate](@date datetime)
returns datetime
as
begin
declare @year varchar(4), @month varchar(2), @day varchar(2) 
declare @dhet varchar(10)

select @year = cast(datepart(year, @date) as varchar(4)), @month = cast(datepart(month, @date) as varchar(2)), @day = cast(datepart(day, @date) as varchar(2))

if len(@month) = 1
 select @month = '0'+@month
if len(@day) = 1
 select @day = '0'+@day

return cast(@year+'-'+@month+'-'+@day as datetime)
end
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetCashBookID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetCashBookID](@cashbook varchar(50))
returns int
as
begin
	declare @cashID int

	select @cashID = isnull(id, 0) from CASHBOOKS
	where code = @cashbook

	return @cashID
end



GO
/****** Object:  UserDefinedFunction [dbo].[fnGetDealNo]    Script Date: 2020/12/07 11:43:07 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[fnGetLedgerRefNumber]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE function [dbo].[fnGetLedgerRefNumber]()
returns varchar(20)
as
begin
declare @num int
declare @num1 varchar(10), @num2 varchar(10), @ref varchar(20)
select @ref = MAX(refno) from SCRIPLEDGER
select @num = cast(substring(@ref, 3, len(@ref)-2) as int) from scriprefs
select @num2 = cast(@num+1 as varchar(20))
while len(@num2) < 7
begin
select @num2 = '0'+@num2
end
--update scriprefs set refledger = 'RN'+@num2
return 'RN'+@num2
end


GO
/****** Object:  UserDefinedFunction [dbo].[fnGetNextDealnumber]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetNextDealnumber]()
returns varchar(10)
as
begin
	declare @max bigint
	select @max = MAX(cast(substring(dealno, 3, len(dealno) - 2) as int)) + 1 from Dealallocations
	return cast(@max as varchar(10))
end
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetNextLedgerRef]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetNextLedgerRef]()
returns varchar(10)
begin
declare @ref varchar(10), @num int

if exists(select refno from SCRIPLEDGER)
begin
	select @ref = MAX(refno) from SCRIPLEDGER
	
	if LEN(@ref) = 0
		select @ref = 'RN0000001'
	else
		begin
			select @num = cast(substring(@ref, 3, len(@ref)-2) as int) + 1
			select @ref = CAST(@num as varchar(10))
			while LEN(@ref) < 7
			begin
				select @ref = '0' + @ref
			end
			select @ref = 'RN' + @ref
		end
end
else
	select @ref = 'RN0000001'
return @ref	
end

GO
/****** Object:  UserDefinedFunction [dbo].[fnGetSettlementDate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:	Gison Mhlanga
	Created: 26 May 2017
	Description:
		Change settlement from t+7 to t+3 days
		t+3 business days 
*/
create function [dbo].[fnGetSettlementDate](@date datetime)
returns datetime
as
begin
	declare @setDate datetime, @tplus integer
	
	select @tplus = certdueby from systemparams
	
	select @setDate = dateadd(day, @tplus, @date)
	
	if datename(dw, @date) in ('Wednesday', 'Thursday', 'Friday')
	begin
		select @setDate = dateadd(day, 5, @date)
	end
	
	return @setDate
end


GO
/****** Object:  UserDefinedFunction [dbo].[GetScripChangeDate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[GetScripChangeDate] (@LedgerID int)
RETURNS datetime AS  
BEGIN 
	declare @Result datetime
	select @Result = null
	select @Result = sdc.dt from scripdealscerts sdc where ledgerid = @LedgerID
	if @Result is null
		select @Result = d.dealdate from dealallocations d, scripledger sl, scripdeals sd where (sl.[id] = @LedgerID) and (sd.refno = sl.refno) and (d.dealno = sd.dealno)
	return @Result
END

GO
/****** Object:  UserDefinedFunction [dbo].[RetainedEarnings]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[RetainedEarnings] -- select dbo.retainedearnings('20110930')
(
	@TBDate datetime
)
RETURNS decimal(31,9)
AS
BEGIN
	--SET NOCOUNT ON;
	declare @Commission decimal(31,9)=0, @BasicCharges as decimal(31,9)=0,@SundryIncome decimal(31,9)=0,@InterestEarned decimal(31,9)=0,@SundryCharges decimal(31,9)=0
	declare @EndPrevYear datetime
	
	--get last date of previous year
	select @EndPrevYear =DATEADD(yy,-1, dateadd(DD,-1,dateadd(yy,datediff(yy,-1,@TBDate),0)))
	
	--Commission
	select @Commission= isnull(SUM(amount),0) from transactions where  YON=1 and transcode like 'comms%' and TransDate<=@EndPrevYear
	
	--BasicCharges
	select @BasicCharges= isnull(SUM(amount),0) from transactions where  YON=1 and transcode like 'bfee%' and TransDate<=@EndPrevYear
	
	--Commission
	select @SundryIncome= isnull(SUM(amount),0) from cashbooktrans where YON=1 and transcode like 'SDRYI%' and TransDate<=@EndPrevYear
	
	--BasicCharges
	select @SundryCharges= isnull(SUM(amount),0) from cashbooktrans where YON=1 and transcode like 'SDRYC%' and TransDate<=@EndPrevYear

	return (@commission+@BasicCharges+@sundrycharges+@Sundryincome)
END

GO
/****** Object:  UserDefinedFunction [dbo].[RetainedEarningsDP]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
create FUNCTION [dbo].[RetainedEarningsDP] -- select dbo.retainedearnings('20110930')
(
	@TBDate datetime
)
RETURNS float
AS
BEGIN
	--SET NOCOUNT ON;
	declare @Commission float=0, @BasicCharges as float=0,@SundryIncome float=0,@InterestEarned float=0,@SundryCharges float=0
	declare @EndPrevYear datetime
	
	--get last date of previous year
	select @EndPrevYear =DATEADD(yy,-1, dateadd(DD,-1,dateadd(yy,datediff(yy,-1,@TBDate),0)))
	
	--Commission
	select @Commission= isnull(SUM(amount),0) from transactions where  YON=1 and transcode like 'comms%' and postdate<=@EndPrevYear
	
	--BasicCharges
	select @BasicCharges= isnull(SUM(amount),0) from transactions where  YON=1 and transcode like 'bfee%' and postdate<=@EndPrevYear
	
	--Commission
	select @SundryIncome= isnull(SUM(amount),0) from cashbooktrans where YON=1 and transcode like 'SDRYI%' and postdate<=@EndPrevYear
	
	--BasicCharges
	select @SundryCharges= isnull(SUM(amount),0) from cashbooktrans where YON=1 and transcode like 'SDRYC%' and postdate<=@EndPrevYear

	return (@commission+@BasicCharges+@sundrycharges+@Sundryincome)
END

GO
/****** Object:  UserDefinedFunction [dbo].[RetainedEarningsOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
create FUNCTION [dbo].[RetainedEarningsOld] -- select dbo.retainedearnings('20110930')
(
	@TBDate datetime
)
RETURNS float
AS
BEGIN
	--SET NOCOUNT ON;
	declare @Commission float=0, @BasicCharges as float=0,@SundryIncome float=0,@InterestEarned float=0,@SundryCharges float=0
	declare @EndPrevYear datetime
	
	--get last date of previous year
	select @EndPrevYear =DATEADD(yy,-1, dateadd(DD,-1,dateadd(yy,datediff(yy,-1,@TBDate),0)))
	
	--Commission
	select @Commission= isnull(SUM(amount),0) from transactions where transcode like 'comms%' and TransDate<=@EndPrevYear
	
	--BasicCharges
	select @BasicCharges= isnull(SUM(amount),0) from transactions where transcode like 'bfee%' and TransDate<=@EndPrevYear
	
	--Commission
	select @SundryIncome= isnull(SUM(amount),0) from cashbooktrans where transcode like 'SDRYI%' and TransDate<=@EndPrevYear
	
	--BasicCharges
	select @SundryCharges= isnull(SUM(amount),0) from cashbooktrans where transcode like 'SDRYC%' and TransDate<=@EndPrevYear

	return (@commission+@BasicCharges+@sundrycharges+@Sundryincome)
END

GO
/****** Object:  UserDefinedFunction [dbo].[TotalContras]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[TotalContras] (@SearchDealNo varchar(20), @ExcludeDealNo varchar(20), @AsAtDate datetime)
RETURNS int AS  
BEGIN 
	declare @Result int, @DoneInPast int, @otherdeal varchar(20), @odt datetime, @dqty int
	declare CONTRACURSOR CURSOR FORWARD_ONLY STATIC READ_ONLY for
		select 'odeal' =
			case
				when origdealno = @SearchDealNo then matchdealno
				when matchdealno = @SearchDealNo then origdealno
			end, dt
		from scripdealscontra
		where ((origdealno = @SearchDealNo) or (matchdealno = @SearchDealNo)) and (origdealno <> @ExcludeDealNo) and (matchdealno <> @ExcludeDealNo) and (dt <= @AsAtDate)
	select @Result = 0, @DoneInPast = 0
	open CONTRACURSOR
	fetch next from CONTRACURSOR into @otherdeal, @odt
	while @@FETCH_STATUS = 0
	begin
		select @dqty = qty from dealallocations where dealno = @otherdeal
		select @Result = @Result + @dqty
		select @DoneInPast = 0 --dbo.TotalContras(@otherdeal,@SearchDealNo,@odt)
		select @Result = @Result - @DoneInPast
		fetch next from CONTRACURSOR into @otherdeal, @odt
	end
	close CONTRACURSOR
	deallocate CONTRACURSOR
	return @Result
END

GO
/****** Object:  Table [dbo].[ACCOUNTSPARAMS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ACCOUNTSPARAMS](
	[TAXCLIENTNO] [int] NOT NULL,
	[ZSECLIENTNO] [int] NOT NULL,
	[NMIREBATE] [decimal](18, 0) NOT NULL,
	[ZSECUT] [decimal](18, 0) NOT NULL,
	[WTAXCLIENTNO] [int] NOT NULL,
	[SETTLEMENTCYCLE] [int] NOT NULL,
	[ExportFilePath] [varchar](100) NULL,
	[ExportFileCount] [bigint] NULL,
	[Factor] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](34, 4) NULL,
	[COMMISSIONERACCOUNT] [int] NULL,
	[VATCLIENTNO] [bigint] NULL,
	[CAPITALGAINSCLIENTNO] [int] NULL,
	[INVESTORPROTECTIONACCOUNT] [int] NULL,
	[NOMINEENAME] [varchar](250) NULL,
	[BackForwardDate] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ASSETS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ASSETS](
	[ASSETCODE] [varchar](20) NOT NULL,
	[ASSETNAME] [varchar](50) NULL,
	[ZSECODE] [varchar](20) NOT NULL,
	[ZSEOrderNo] [int] NOT NULL,
	[LINKTO] [varchar](50) NULL,
	[BLOOMBERGCODE] [varchar](50) NULL,
	[REUTERCODE] [varchar](50) NULL,
	[ISINO] [varchar](50) NULL,
	[CONTACT] [varchar](255) NULL,
	[CPOSITION] [varchar](50) NULL,
	[TEL] [varchar](50) NULL,
	[FAX] [varchar](50) NULL,
	[POSTADD] [varchar](250) NULL,
	[PHYADD] [varchar](250) NULL,
	[EMAIL] [varchar](50) NULL,
	[LISTEDDT] [varchar](50) NULL,
	[WEBSITE] [varchar](50) NULL,
	[Sector] [varchar](50) NULL,
	[ASSTYPEID] [int] NULL,
	[TransSecID] [varchar](50) NOT NULL,
	[ClerkID] [varchar](30) NULL,
	[Login] [varchar](50) NULL,
	[CATEGORY] [varchar](50) NULL,
	[STATUS] [varchar](50) NOT NULL,
	[NOTE] [varchar](100) NULL,
	[AssetID] [int] IDENTITY(1,1) NOT NULL,
	[ContactEmail] [varchar](50) NULL,
	[ContactLandline] [varchar](50) NULL,
	[ContactMobile] [varchar](50) NULL,
	[shares] [int] NULL,
	[SYMBOL] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AutoMatch]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AutoMatch](
	[ClientNo] [varchar](50) NOT NULL,
	[TransDate] [datetime] NULL,
	[TransCode] [varchar](50) NULL,
	[Amount] [decimal](31, 9) NULL,
	[DealValue] [decimal](31, 9) NULL,
	[DealDate] [datetime] NOT NULL,
	[MatchID] [bigint] NULL,
	[DealNo] [varchar](40) NOT NULL,
	[TRANSID] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BackDatedTxns]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BackDatedTxns](
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime2](7) NULL,
	[TransDate] [datetime] NULL,
	[DEALNO] [varchar](50) NULL,
	[QTY] [int] NULL,
	[PRICE] [numeric](17, 4) NULL,
	[LOGIN] [varchar](50) NULL,
	[AMOUNT] [numeric](17, 4) NULL,
	[TRANSCODE] [varchar](50) NULL,
	[client] [varchar](150) NULL,
	[Asset] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BALANCES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BALANCES](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Dt] [datetime] NOT NULL,
	[CLIENTNO] [int] NOT NULL,
	[SCLIENTNO] [varchar](50) NULL,
	[ORDERNO] [numeric](18, 0) NULL,
	[COST] [decimal](33, 9) NULL,
	[ASSET] [varchar](15) NOT NULL,
	[BAL] [decimal](33, 9) NOT NULL,
	[ACC] [bit] NOT NULL,
	[LOGIN] [varchar](50) NULL,
 CONSTRAINT [PK_BALANCES] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BANKS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BANKS](
	[BankID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[CODE] [varchar](50) NULL,
	[Login] [varchar](50) NULL,
	[Status] [varchar](50) NULL,
	[DateAdded] [datetime2](7) NULL,
	[Audit] [bit] NOT NULL,
 CONSTRAINT [PK_BANKS] PRIMARY KEY NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BannedPasswords]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BannedPasswords](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[pass] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BONUSISSUEDEALS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BONUSISSUEDEALS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BONUSID] [int] NOT NULL,
	[DEALNO] [varchar](40) NOT NULL,
	[DEALTYPE] [varchar](20) NOT NULL,
	[DEALDATE] [datetime] NOT NULL,
	[CLIENT] [varchar](255) NOT NULL,
	[ORIGQTY] [int] NOT NULL,
	[BONUSQTY] [int] NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
 CONSTRAINT [PK_BONUSISSUEDEALS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BonusIssues]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BonusIssues](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BONUSNUMBER] [varchar](10) NULL,
	[ASSET] [varchar](50) NOT NULL,
	[DT] [datetime] NOT NULL,
	[FOREACH] [numeric](10, 2) NOT NULL,
	[BONUSQTY] [numeric](10, 2) NOT NULL,
	[NOTES] [varchar](255) NULL,
	[ENTRYDATE] [datetime] NOT NULL,
	[PROCESSED] [bit] NOT NULL,
	[PROCESSUSER] [varchar](50) NULL,
	[PROCESSDT] [datetime] NULL,
	[APPROVED] [bit] NOT NULL,
	[APPROVEUSER] [varchar](50) NULL,
	[APPROVEDT] [datetime] NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BONUSISSUESPLITSCRIP]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BONUSISSUESPLITSCRIP](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BONUSID] [int] NOT NULL,
	[CLIENTNO] [int] NOT NULL,
	[NUMSHARES] [int] NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
 CONSTRAINT [PK_BONUSISSUESPLITSCRIP] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BRANCHES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BRANCHES](
	[BNKCODE] [varchar](10) NOT NULL,
	[CODE] [varchar](10) NOT NULL,
	[NAME] [varchar](50) NULL,
	[POSTAL] [varchar](250) NULL,
	[PHYSICAL] [varchar](250) NULL,
	[PHONE] [varchar](20) NULL,
	[CITY] [varchar](50) NULL,
	[EDITED] [bit] NOT NULL,
	[LOGIN] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BusinessRules]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BusinessRules](
	[PayBrokerByDeal] [bit] NULL,
	[EarlyPayFees] [float] NULL,
	[ApproveJournals] [bit] NULL,
	[ConfirmManualOrders] [bit] NULL,
	[ApproveReceipts] [bit] NULL,
	[PartSettlement] [bit] NOT NULL,
	[RegistrationReceipts] [bit] NOT NULL,
	[FinancialPeriodOnly] [bit] NOT NULL,
	[SeperateBrokerDeals] [bit] NOT NULL,
	[LockScrip4BDeals] [bit] NOT NULL,
	[PrintSettlementLetter] [bit] NOT NULL,
	[PrintSettlementSafeCustody] [bit] NOT NULL,
	[BalanceCertificates] [bit] NOT NULL,
	[OrdersExpiry] [varchar](50) NULL,
	[Mandate] [bit] NULL,
	[GenerateRefund] [bit] NULL,
	[DormantDays] [int] NULL,
	[Sharejobalert] [bit] NOT NULL,
	[tbalert] [bit] NOT NULL,
	[ExRateAlert] [bit] NOT NULL,
	[PassLength] [int] NOT NULL,
	[PassHistory] [int] NOT NULL,
	[PassStrength] [varchar](50) NULL,
	[PassSimilarity] [bit] NOT NULL,
	[passexpiry] [int] NULL,
	[LogAttempts] [int] NOT NULL,
	[UseSecretQuestions] [bit] NOT NULL,
	[MultipleLogins] [bit] NOT NULL,
	[CheckSystemState] [bit] NULL,
	[PrintBrokerDealNotes] [bit] NULL,
	[CSDTxnOnSettlement] [bit] NOT NULL,
	[ApprovePayments] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CASHBOOKS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CASHBOOKS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](20) NOT NULL,
	[ACTIVE] [varchar](50) NOT NULL,
	[IsDefault] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CASHBOOKTRANS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CASHBOOKTRANS](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](50) NULL,
	[Description] [varchar](50) NULL,
	[Amount] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Cancelled] [bit] NULL,
	[ChqRqID] [bigint] NULL,
	[ExCurrency] [varchar](50) NULL,
	[ExRate] [float] NULL,
	[ExAmount] [float] NULL,
	[MatchID] [bigint] NULL,
	[YON] [bit] NULL,
	[MID] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CBTJUL]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CBTJUL](
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](50) NULL,
	[Description] [varchar](50) NULL,
	[Amount] [decimal](36, 4) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](17, 4) NULL,
	[Cancelled] [bit] NULL,
	[ChqRqID] [bigint] NULL,
	[ExCurrency] [varchar](50) NULL,
	[ExRate] [float] NULL,
	[ExAmount] [float] NULL,
	[MatchID] [bigint] NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CLIENTCATEGORY]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CLIENTCATEGORY](
	[ClientCategory] [varchar](20) NOT NULL,
	[BasicCharges] [decimal](31, 9) NULL,
	[Commission] [real] NOT NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[VAT] [decimal](19, 4) NOT NULL,
	[CapitalGains] [decimal](17, 4) NULL,
	[InvestorProtection] [decimal](17, 4) NULL,
	[CommissionerLevy] [decimal](17, 4) NULL,
	[ZSELevy] [decimal](17, 4) NULL,
	[NMIRebate] [decimal](17, 4) NULL,
	[Login] [varchar](50) NULL,
	[TxnDate] [datetime2](7) NULL,
	[CSDLevy] [decimal](17, 4) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CLIENTCATEGORY2014]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CLIENTCATEGORY2014](
	[ClientCategory] [varchar](20) NOT NULL,
	[BasicCharges] [decimal](31, 9) NULL,
	[Commission] [real] NOT NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[VAT] [decimal](19, 4) NOT NULL,
	[CapitalGains] [decimal](17, 4) NULL,
	[InvestorProtection] [decimal](17, 4) NULL,
	[CommissionerLevy] [decimal](17, 4) NULL,
	[ZSELevy] [decimal](17, 4) NULL,
	[NMIRebate] [decimal](17, 4) NULL,
	[Login] [varchar](50) NULL,
	[TxnDate] [datetime2](7) NULL,
	[CSDLevy] [decimal](17, 4) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CLIENTCATEGORYOLD]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CLIENTCATEGORYOLD](
	[ClientCategory] [varchar](20) NOT NULL,
	[BasicCharges] [decimal](31, 9) NULL,
	[Commission] [real] NOT NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[VAT] [decimal](19, 4) NOT NULL,
	[CapitalGains] [decimal](17, 4) NULL,
	[InvestorProtection] [decimal](17, 4) NULL,
	[CommissionerLevy] [decimal](17, 4) NULL,
	[ZSELevy] [decimal](17, 4) NULL,
	[NMIRebate] [decimal](17, 4) NULL,
	[Login] [varchar](50) NULL,
	[TxnDate] [datetime2](7) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CLIENTS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CLIENTS](
	[CID] [int] IDENTITY(1,1) NOT NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[SHORTCODE] [varchar](50) NULL,
	[LONGCODE] [varchar](50) NULL,
	[TITLE] [varchar](8) NULL,
	[FIRSTNAME] [varchar](128) NULL,
	[SURNAME] [varchar](128) NULL,
	[COMPANYNAME] [varchar](128) NULL,
	[TYPE] [varchar](20) NOT NULL,
	[CATEGORY] [varchar](20) NOT NULL,
	[STATUS] [varchar](20) NULL,
	[STATUSREASON] [varchar](128) NULL,
	[NOMINEECO] [bit] NOT NULL,
	[IDTYPE] [varchar](20) NULL,
	[IDNO] [varchar](50) NULL,
	[UtilityType] [varchar](20) NULL,
	[UtilityNo] [varchar](50) NULL,
	[PhysicalAddress] [varchar](255) NULL,
	[PostalAddress] [varchar](255) NULL,
	[UsePhysicalAddress] [bit] NOT NULL,
	[CONTACTNO] [varchar](255) NULL,
	[MOBILENOSMS] [varchar](100) NULL,
	[MOBILENO] [varchar](1000) NULL,
	[AltMobile] [varchar](50) NULL,
	[Fax] [varchar](255) NULL,
	[EMAIL] [varchar](2000) NULL,
	[CONTACTVERIFIED] [varchar](20) NULL,
	[DateAdded] [datetime] NOT NULL,
	[BANK] [varchar](50) NULL,
	[BANKBRANCH] [varchar](50) NULL,
	[BankAccountNo] [varchar](50) NULL,
	[BankAccountType] [varchar](50) NULL,
	[BUYSETTLE] [varchar](50) NOT NULL,
	[SELLSETTLE] [varchar](50) NOT NULL,
	[ORDERVALIDITY] [int] NULL,
	[RNAME] [varchar](128) NULL,
	[RADDRESS] [varchar](255) NULL,
	[DELIVERYOPTION] [varchar](50) NOT NULL,
	[DNAME] [varchar](128) NULL,
	[DADDRESS] [varchar](255) NULL,
	[SECTOR] [varchar](50) NULL,
	[SENDPRICES] [varchar](10) NOT NULL,
	[SENDDEALS] [varchar](10) NOT NULL,
	[SENDPRICESON] [varchar](100) NULL,
	[LoginID] [varchar](50) NULL,
	[DIVCLIENTNO] [int] NULL,
	[SENDPRICESINCLUDE] [varchar](100) NULL,
	[OnlineSubscribed] [bit] NOT NULL,
	[Sex] [varchar](10) NULL,
	[Directors] [varchar](100) NULL,
	[ReferredBy] [varchar](50) NULL,
	[Photo] [image] NULL,
	[Employer] [varchar](100) NULL,
	[JobTitle] [varchar](50) NULL,
	[ContactPerson] [varchar](50) NULL,
	[BusPhone] [varchar](50) NULL,
	[DateEdited] [datetime2](7) NULL,
	[EditedBy] [varchar](50) NULL,
	[StatusDate] [datetime2](7) NULL,
	[NomineeAccount] [bit] NOT NULL,
	[ScannedID] [image] NULL,
	[ScannedRes] [image] NULL,
	[Class] [varchar](50) NULL,
	[Custodial] [bit] NOT NULL,
	[CSDNumber] [varchar](30) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ClientsCommunication]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClientsCommunication](
	[ClientNo] [varchar](50) NOT NULL,
	[SMSDeals] [bit] NULL,
	[SMSScrip] [bit] NULL,
	[SMSCorpAction] [bit] NULL,
	[SMSPrices] [bit] NULL,
	[SMSOther] [bit] NULL,
	[EmailDeals] [bit] NULL,
	[EmailScrip] [bit] NULL,
	[EmailCorpAction] [bit] NULL,
	[EmailPrices] [bit] NULL,
	[EmailOther] [bit] NULL,
	[LastTxnDate] [datetime2](7) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ClientStatement]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClientStatement](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[transdate] [datetime] NULL,
	[transcode] [varchar](10) NULL,
	[dealno] [varchar](10) NULL,
	[transdescription] [varchar](50) NULL,
	[transdetails] [varchar](50) NULL,
	[amount] [money] NULL,
	[userid] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[COMPANY]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[COMPANY](
	[CompanyName] [varchar](100) NULL,
	[PhysicalAddress] [varchar](250) NULL,
	[CompanyInitials] [varchar](10) NULL,
	[BrokerNo] [int] NOT NULL,
	[EMailP] [varchar](14) NULL,
	[PostalAddress] [varchar](250) NULL,
	[Phone] [varchar](150) NULL,
	[Email] [varchar](50) NULL,
	[FromAddress] [varchar](50) NULL,
	[DealNoteSubject] [varchar](50) NULL,
	[DealNoteBody] [varchar](50) NULL,
	[Fax] [varchar](50) NULL,
	[Label] [varchar](50) NULL,
	[Proxy] [varchar](50) NULL,
	[SupportEmail] [varchar](50) NULL,
	[NomineeName] [varchar](50) NULL,
	[ServerIP] [varchar](20) NULL,
	[VATNo] [varchar](50) NULL,
	[BPN] [varchar](50) NULL,
	[Logo] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ConsolidatedCharges]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ConsolidatedCharges](
	[transdate] [datetime] NULL,
	[comm] [decimal](38, 9) NULL,
	[sduty] [decimal](38, 9) NULL,
	[cgt] [decimal](38, 9) NULL,
	[zse] [decimal](38, 9) NULL,
	[csd] [decimal](38, 9) NULL,
	[ipl] [decimal](38, 9) NULL,
	[vat] [decimal](38, 9) NULL,
	[seclv] [decimal](38, 9) NULL,
	[username] [varchar](30) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CONSOLIDATIONDEALS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CONSOLIDATIONDEALS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CONSOLID] [int] NOT NULL,
	[DEALNO] [varchar](40) NOT NULL,
	[DEALTYPE] [varchar](20) NOT NULL,
	[DEALDATE] [datetime] NOT NULL,
	[CLIENT] [varchar](255) NOT NULL,
	[ORIGQTY] [int] NOT NULL,
	[NEWQTY] [int] NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
 CONSTRAINT [PK_CONSOLIDATIONDEALS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CONSOLIDATIONS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CONSOLIDATIONS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ASSET] [varchar](50) NOT NULL,
	[DT] [datetime] NOT NULL,
	[OLDQTY] [numeric](10, 2) NOT NULL,
	[NEWQTY] [numeric](10, 2) NOT NULL,
	[NOTES] [varchar](255) NULL,
	[ENTRYDATE] [datetime] NOT NULL,
	[PROCESSED] [bit] NOT NULL,
	[PROCESSUSER] [varchar](50) NULL,
	[PROCESSDT] [datetime] NULL,
	[APPROVED] [bit] NOT NULL,
	[APPROVEUSER] [varchar](50) NULL,
	[APPROVEDT] [datetime] NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[NEWASSET] [varchar](50) NOT NULL,
 CONSTRAINT [PK_CONSOLIDATION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CONSOLIDATIONSCRIP]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CONSOLIDATIONSCRIP](
	[ID] [int] NOT NULL,
	[CONSOLID] [int] NOT NULL,
	[ORIGLEDGERID] [int] NOT NULL,
	[NEWLEDGERID] [int] NOT NULL,
	[DT] [datetime] NOT NULL,
	[USER] [varchar](255) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CORPORATEACTION]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CORPORATEACTION](
	[Asset] [varchar](50) NULL,
	[Action] [varchar](200) NULL,
	[Description] [varchar](50) NULL,
	[DateAdded] [datetime2](7) NULL,
	[ActionDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CustPort]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CustPort](
	[User] [varchar](50) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[Asset] [varchar](50) NOT NULL,
	[Shares] [numeric](18, 0) NOT NULL,
	[Cost] [decimal](18, 4) NOT NULL,
	[MktPrice] [decimal](18, 4) NULL,
	[MktValue] [numeric](18, 4) NULL,
	[Profit] [numeric](18, 4) NULL,
	[PortDate] [datetime] NULL,
	[TotalCost] [numeric](18, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dealallocations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dealallocations](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL,
	[origdeal] [varchar](10) NULL,
	[SMSSent] [bit] NULL,
	[MID] [int] NULL,
	[CSDLevy] [decimal](31, 9) NULL,
	[CSDSettled] [bit] NULL,
	[CSDNumber] [varchar](50) NULL,
	[Bookover] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DEALALLOCATIONS_OG]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DEALALLOCATIONS_OG](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL,
	[origdeal] [varchar](10) NULL,
	[SMSSent] [bit] NULL,
	[MID] [int] NULL,
	[CSDLevy] [decimal](31, 9) NULL,
	[CSDSettled] [bit] NULL,
	[CSDNumber] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DealsDueTable]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DealsDueTable](
	[clientno] [varchar](50) NOT NULL,
	[asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[DealType] [varchar](20) NULL,
	[ClientName] [varchar](257) NULL,
	[DealValue] [decimal](31, 9) NULL,
	[Category] [varchar](50) NULL,
	[SharesOut] [numeric](18, 0) NULL,
	[DealNo] [varchar](50) NULL,
	[AsAt] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DealsNullified]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DealsNullified](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NOT NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL,
	[origdeal] [varchar](10) NULL,
	[SMSSent] [bit] NULL,
	[MID] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DLZ20140718]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DLZ20140718](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NOT NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL,
	[origdeal] [varchar](10) NULL,
	[SMSSent] [bit] NULL,
	[MID] [int] NULL,
	[CSDLevy] [decimal](17, 4) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DOCKETS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DOCKETS](
	[AssetCode] [varchar](50) NOT NULL,
	[DocketNo] [numeric](19, 0) IDENTITY(1,1) NOT NULL,
	[DocketDate] [datetime] NOT NULL,
	[BrokerNo] [varchar](50) NOT NULL,
	[COUNTERPARTY] [varchar](50) NULL,
	[DealType] [varchar](50) NOT NULL,
	[EXTERNALF] [bit] NULL,
	[STATUS] [varchar](50) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[DealValue] [decimal](31, 9) NULL,
	[BALBF] [decimal](31, 9) NULL,
	[ZSEREFNO] [numeric](18, 0) NULL,
	[BALCF] [decimal](31, 9) NULL,
	[USERID] [varchar](50) NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](50) NULL,
	[ADJUSTMENT] [bit] NULL,
	[BnB] [bit] NULL,
	[DateAdded] [datetime2](7) NULL,
	[CancelDate] [datetime2](7) NULL,
	[CancelledBy] [varchar](50) NULL,
	[CancelReason] [varchar](150) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ExchangeRates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ExchangeRates](
	[RatesID] [bigint] IDENTITY(1,1) NOT NULL,
	[RatesDate] [datetime2](7) NULL,
	[ZAR] [float] NULL,
	[GBP] [float] NULL,
	[BWP] [float] NULL,
	[EUR] [float] NULL,
	[Login] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IPOALLOCATION]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IPOALLOCATION](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[IPOID] [int] NOT NULL,
	[CLIENT] [varchar](20) NOT NULL,
	[ENTRYDATE] [datetime] NOT NULL,
	[APPLIEDFOR] [int] NOT NULL,
	[ALLOCATED] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LedgerAccount]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LedgerAccount](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[LedgerCode] [int] NULL,
	[LedgerName] [varchar](100) NULL,
	[isActive] [bit] NULL,
	[LedgerAbbrev] [varchar](20) NULL,
 CONSTRAINT [PK_LedgerAccount] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LEDGERS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LEDGERS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[TRANSCODE] [varchar](20) NOT NULL,
	[STMTDATE] [datetime] NOT NULL,
	[STARTDATE] [datetime] NOT NULL,
	[ENDDATE] [datetime] NOT NULL,
	[BALBF] [decimal](33, 9) NULL,
	[BALCF] [decimal](33, 9) NULL,
 CONSTRAINT [PK_LEDGERS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MACHINES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MACHINES](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PCName] [varchar](50) NULL,
	[Updated] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Matching]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Matching](
	[DealNo] [varchar](50) NULL,
	[DealType] [varchar](50) NULL,
	[DealDate] [datetime] NULL,
	[Asset] [varchar](50) NULL,
	[Qty] [bigint] NULL,
	[DealValue] [float] NULL,
	[Matched] [bit] NULL,
	[User] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Menus]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Menus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ParentID] [int] NULL,
	[Title] [varchar](50) NULL,
	[Description] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MODULES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MODULES](
	[MID] [int] IDENTITY(1,1) NOT NULL,
	[MODNAME] [varchar](50) NOT NULL,
 CONSTRAINT [PK_MODULES] PRIMARY KEY CLUSTERED 
(
	[MID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[NONTAXACCOUNTS18072014]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NONTAXACCOUNTS18072014](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NOT NULL,
	[TransCode] [varchar](50) NOT NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ORDERS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ORDERS](
	[OrderNo] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[POrderNo] [varchar](50) NULL,
	[OrderDate] [datetime] NOT NULL,
	[DateAdded] [datetime2](7) NOT NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[OrderValue] [decimal](31, 9) NULL,
	[PLimit] [varchar](50) NULL,
	[Limit] [varchar](50) NULL,
	[Reference] [varchar](150) NULL,
	[Instruction] [varchar](50) NULL,
	[QtyOs] [numeric](18, 0) NOT NULL,
	[ScripAt] [varchar](50) NULL,
	[Status] [varchar](50) NOT NULL,
	[Media] [varchar](50) NULL,
	[OrderType] [varchar](20) NOT NULL,
	[DealerID] [varchar](40) NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[ExpiryDate] [datetime2](7) NULL,
	[CancelledID] [varchar](10) NULL,
	[CancelledDate] [datetime2](7) NULL,
	[Login] [varchar](10) NULL,
	[CancelReason] [varchar](150) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ORDERSQUOTE]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ORDERSQUOTE](
	[OrderNo] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[CDate] [datetime] NOT NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Limit] [varchar](50) NULL,
	[Consideration] [decimal](33, 9) NULL,
	[COMMISSION] [decimal](33, 9) NULL,
	[BASICCHARGES] [decimal](33, 9) NULL,
	[CONTRACTSTAMPS] [decimal](33, 9) NULL,
	[TRANSFERFEES] [decimal](33, 9) NULL,
	[WTAX] [decimal](33, 9) NULL,
	[VAT] [decimal](33, 9) NULL,
	[Instruct] [varchar](50) NULL,
	[ScripAt] [varchar](50) NULL,
	[OrderType] [varchar](20) NOT NULL,
	[DealerID] [varchar](40) NOT NULL,
	[AccCode] [int] NOT NULL,
	[ValidUntil] [datetime] NULL,
 CONSTRAINT [PK_ORDERSQUOTE] PRIMARY KEY CLUSTERED 
(
	[OrderNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PASSBAN]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PASSBAN](
	[PASSWORD] [varchar](8) NOT NULL,
 CONSTRAINT [PK_PASSBAN] PRIMARY KEY CLUSTERED 
(
	[PASSWORD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PASSHIST]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PASSHIST](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[USERNAME] [varchar](50) NOT NULL,
	[PASS] [varchar](50) NOT NULL,
	[DT] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PASSPOLICY]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PASSPOLICY](
	[PASSEXPIRY] [int] NOT NULL,
	[LOGATTEMPTS] [int] NOT NULL,
	[PASSHISTORY] [int] NOT NULL,
	[PASSLENGTH] [int] NOT NULL,
	[CHECKSIMILARITY] [bit] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PASSQUESTIONS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PASSQUESTIONS](
	[QUESTION] [varchar](255) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PayClientDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PayClientDeals](
	[DealNo] [varchar](50) NULL,
	[DealType] [varchar](50) NULL,
	[DealDate] [datetime] NULL,
	[Asset] [varchar](50) NULL,
	[Qty] [decimal](18, 0) NULL,
	[DealValue] [decimal](17, 4) NULL,
	[Selected] [bit] NULL,
	[User] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PERMISSIONS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PERMISSIONS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PROFILE] [varchar](50) NOT NULL,
	[SCREEN] [int] NOT NULL,
	[ACCESS] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PORTFOLIOSUMMARY]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PORTFOLIOSUMMARY](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[User] [varchar](50) NOT NULL,
	[ClientNo] [numeric](18, 0) NOT NULL,
	[Asset] [varchar](50) NOT NULL,
	[Shares] [numeric](18, 0) NOT NULL,
	[Cost] [decimal](33, 9) NOT NULL,
	[MktPrice] [decimal](33, 9) NOT NULL,
	[MktValue] [decimal](33, 9) NOT NULL,
	[Profit] [decimal](33, 9) NOT NULL,
 CONSTRAINT [PK_PORTFOLIOSUMMARY] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PRICES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PRICES](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ASSETCODE] [varchar](50) NOT NULL,
	[AssetName] [varchar](50) NULL,
	[PricesDate] [datetime] NOT NULL,
	[Bid] [real] NULL,
	[Offer] [real] NULL,
	[Sales] [real] NULL,
	[Volume] [real] NULL,
	[HISTORY] [decimal](33, 9) NULL,
	[LTP] [decimal](33, 9) NULL,
	[uploaded] [bit] NULL,
 CONSTRAINT [PK_PRICES] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pricestemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pricestemp](
	[AssetID] [numeric](18, 0) NOT NULL,
	[Asset] [varchar](50) NOT NULL,
	[AssetName] [nchar](150) NULL,
	[PricesDate] [datetime] NOT NULL,
	[Bid] [real] NULL,
	[Offer] [real] NULL,
	[Sales] [real] NULL,
	[Volume] [numeric](18, 0) NULL,
	[HISTORY] [real] NULL,
	[LTP] [real] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PROFILES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PROFILES](
	[NAME] [varchar](50) NOT NULL,
	[DESCRIPTION] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Proforma]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Proforma](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](50) NULL,
	[DealDate] [datetime] NULL,
	[ClientNo] [varchar](50) NULL,
	[OrderNo] [varchar](50) NULL,
	[Asset] [varchar](20) NULL,
	[Qty] [decimal](18, 0) NULL,
	[Price] [decimal](19, 4) NULL,
	[Consideration] [decimal](38, 4) NULL,
	[Commission] [decimal](38, 4) NULL,
	[NMIRebate] [decimal](17, 4) NULL,
	[BasicCharges] [decimal](36, 4) NULL,
	[StampDuty] [decimal](19, 4) NULL,
	[CertDueBy] [datetime] NULL,
	[Reference] [varchar](200) NULL,
	[VAT] [decimal](38, 4) NULL,
	[CapitalGains] [decimal](17, 4) NULL,
	[InvestorProtection] [decimal](17, 4) NULL,
	[CommissionerLevy] [decimal](17, 4) NULL,
	[ZSELevy] [decimal](17, 4) NULL,
	[DealValue] [decimal](17, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Rebates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Rebates](
	[ClientNo] [varchar](50) NULL,
	[DealNo] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[Amount] [money] NULL,
	[DealType] [varchar](50) NULL,
	[Asset] [varchar](50) NULL,
	[Qty] [money] NULL,
	[Price] [money] NULL,
	[Consideration] [money] NULL,
	[Commission] [money] NULL,
	[User] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RECONDEALS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RECONDEALS](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DEALTYPE] [varchar](20) NULL,
	[DEALNO] [varchar](40) NULL,
	[DEALDATE] [datetime] NOT NULL,
	[CLIENTNO] [int] NULL,
	[ASSET] [varchar](20) NOT NULL,
	[QTY] [decimal](18, 0) NOT NULL,
	[PRICE] [decimal](33, 9) NOT NULL,
	[CONSIDERATIONTO] [decimal](33, 9) NULL,
	[CONSIDERATIONFROM] [decimal](33, 9) NULL,
	[COMMISSION] [decimal](33, 9) NULL,
	[BASICCHARGES] [decimal](33, 9) NULL,
	[CONTRACTSTAMPS] [decimal](33, 9) NULL,
	[TRANSFERFEES] [decimal](33, 9) NULL,
	[WTAX] [decimal](33, 9) NULL,
	[DEALER] [varchar](30) NULL,
	[SHARESOUTTO] [decimal](18, 0) NULL,
	[SHARESOUTFROM] [decimal](18, 0) NULL,
	[ORIGSHARESOUT] [decimal](18, 0) NULL,
 CONSTRAINT [PK_RECONDEALS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[REQUISITIONS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[REQUISITIONS](
	[ClientNo] [varchar](50) NOT NULL,
	[LETTER] [bit] NULL,
	[Amount] [decimal](31, 9) NULL,
	[TransDate] [datetime] NULL,
	[CHQNO] [decimal](18, 0) NULL,
	[CHQAMT] [decimal](31, 9) NULL,
	[CHQID] [decimal](18, 0) NULL,
	[PAYEE] [varchar](100) NULL,
	[APPROVED] [bit] NULL,
	[COMMENTS] [varchar](255) NULL,
	[TOPRINT] [bit] NULL,
	[PRINTED] [bit] NULL,
	[LOGIN] [varchar](50) NULL,
	[Cancelled] [bit] NOT NULL,
	[TRANSID] [int] NULL,
	[APPROVEDBY] [varchar](50) NULL,
	[CANCELLEDBY] [varchar](50) NULL,
	[ENTEREDBY] [varchar](50) NULL,
	[RQPRINTED] [bit] NULL,
	[CASHBOOK] [varchar](50) NULL,
	[ISRECEIPT] [bit] NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[TRANSCODE] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[ExCurrency] [varchar](50) NULL,
	[ExAmount] [float] NULL,
	[ExRate] [float] NULL,
	[DealNo] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[CashBookID] [int] NULL,
	[Method] [varchar](50) NULL,
	[ReqID] [int] IDENTITY(1,1) NOT NULL,
	[CancelReason] [varchar](150) NULL,
	[CancelDate] [datetime2](7) NULL,
	[CashflowReq] [bit] NOT NULL,
	[AmalgamationID] [bigint] NOT NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RIGHTSOFFERDEALSALLOC]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RIGHTSOFFERDEALSALLOC](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RIGHTSID] [int] NOT NULL,
	[CLIENTNO] [int] NOT NULL,
	[DEALNO] [varchar](20) NULL,
	[DEALQTY] [int] NOT NULL,
	[OFFERQTY] [int] NOT NULL,
	[DEALTYPE] [varchar](20) NOT NULL,
	[DEALDATE] [datetime] NOT NULL,
	[CLIENT] [varchar](255) NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
 CONSTRAINT [PK_RIGHTSOFFERDEALSALLOC] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RIGHTSOFFERS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RIGHTSOFFERS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ASSET] [varchar](50) NOT NULL,
	[PRELIMASSET] [varchar](50) NOT NULL,
	[DT] [datetime] NOT NULL,
	[TRADEDT] [datetime] NOT NULL,
	[FOREACH] [numeric](10, 2) NOT NULL,
	[OFFERQTY] [numeric](10, 2) NOT NULL,
	[OFFERPRICE] [decimal](33, 9) NOT NULL,
	[NOTES] [varchar](255) NULL,
	[ENTRYDATE] [datetime] NOT NULL,
	[PROCESSED] [bit] NOT NULL,
	[PROCESSUSER] [varchar](50) NULL,
	[PROCESSDT] [datetime] NULL,
	[APPROVED] [bit] NOT NULL,
	[APPROVEUSER] [varchar](50) NULL,
	[APPROVEDT] [datetime] NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
 CONSTRAINT [PK_RIGHTSOFFERS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RIGHTSOFFERSCRIPALLOC]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RIGHTSOFFERSCRIPALLOC](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RIGHTSID] [int] NOT NULL,
	[CLIENTNO] [int] NOT NULL,
	[NUMSHARES] [int] NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
 CONSTRAINT [PK_RIGHTSOFFERSCRIPALLOC] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCREENS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCREENS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MOD] [int] NULL,
	[NAME] [varchar](50) NOT NULL,
 CONSTRAINT [PK_SCREENS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPBALTEMP2]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPBALTEMP2](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ASSET] [varchar](20) NOT NULL,
	[CLIENT] [int] NOT NULL,
	[BALANCED] [bit] NOT NULL,
	[DATA] [varchar](2000) NULL,
 CONSTRAINT [PK_SCRIPBALTEMP2] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPCHANGES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPCHANGES](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[LEDGERID] [int] NOT NULL,
	[ORIGOWNER] [int] NOT NULL,
	[NEWOWNER] [int] NOT NULL,
	[DT] [datetime] NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[REF] [varchar](255) NULL,
 CONSTRAINT [PK_SCRIPCHANGES] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPDEALS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPDEALS](
	[REFNO] [varchar](30) NOT NULL,
	[DEALNO] [varchar](40) NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPDEALSCERTS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPDEALSCERTS](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[LEDGERID] [numeric](10, 0) NOT NULL,
	[DEALNO] [varchar](40) NOT NULL,
	[REVERSETEMP] [bit] NOT NULL,
	[DT] [datetime] NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL,
	[QTYUSED] [int] NOT NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPDEALSCONTRA]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPDEALSCONTRA](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[ORIGDEALNO] [varchar](40) NOT NULL,
	[MATCHDEALNO] [varchar](40) NOT NULL,
	[DT] [datetime] NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL,
	[QTYUSED] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPDELIVERIES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPDELIVERIES](
	[DID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DEALNO] [varchar](50) NOT NULL,
	[DVDATE] [datetime] NOT NULL,
	[CALLER] [varchar](50) NOT NULL,
	[CALLEE] [varchar](50) NOT NULL,
	[CALLTIME] [datetime] NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL,
	[CHQREQ] [numeric](18, 0) NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPLEDGER]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPLEDGER](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[REFNO] [varchar](50) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](150) NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](150) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NOT NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NOT NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NOT NULL,
	[INCOMINGID] [bigint] NOT NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[scriprefs]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[scriprefs](
	[refledger] [varchar](30) NULL,
	[reftransfer] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPSAFE]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPSAFE](
	[CLIENTNO] [varchar](50) NOT NULL,
	[LEDGERID] [int] NOT NULL,
	[NOMINEE] [bit] NOT NULL,
	[DATEIN] [datetime] NOT NULL,
	[DATEOUT] [datetime] NULL,
	[CLOSED] [bit] NOT NULL,
	[LOGIN] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPSHAPE]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPSHAPE](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[PDEAL] [varchar](50) NULL,
	[ASSET] [varchar](50) NOT NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](150) NOT NULL,
	[REGADDRESS] [varchar](250) NULL,
	[CD] [bit] NOT NULL,
	[NEWCERTNO] [varchar](50) NULL,
	[TOCLIENT] [varchar](150) NULL,
	[TONAME] [varchar](150) NULL,
	[TOADDRESS] [varchar](255) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[CLOSED] [bit] NOT NULL,
	[LOGIN] [varchar](50) NULL,
	[DEALNO] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCRIPTRANSFER]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCRIPTRANSFER](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[LEDGERID] [numeric](10, 0) NOT NULL,
	[DATESENT] [datetime] NOT NULL,
	[TRANSSEC] [varchar](150) NOT NULL,
	[SOURCEDEAL] [varchar](50) NULL,
	[REFNO] [varchar](50) NOT NULL,
	[SENT] [bit] NOT NULL,
	[CLOSED] [bit] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[cancelreason] [varchar](50) NULL,
	[origrefno] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Sector]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Sector](
	[SID] [int] IDENTITY(1,1) NOT NULL,
	[SNAME] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SHAREJOB]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SHAREJOB](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[ASSET] [varchar](15) NOT NULL,
	[DATE] [datetime] NULL,
	[NETQTY] [numeric](18, 0) NOT NULL,
	[NETCONS] [decimal](33, 9) NOT NULL,
	[MKTPRICE] [decimal](33, 9) NOT NULL,
	[BALBF] [decimal](33, 9) NULL,
	[COST] [decimal](33, 9) NOT NULL,
 CONSTRAINT [PK_SHAREJOB] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SharejobbingSummary]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SharejobbingSummary](
	[dealdate] [datetime] NULL,
	[cons] [money] NULL,
	[username] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sharejobtemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[sharejobtemp](
	[ASSET] [varchar](20) NOT NULL,
	[NETQTY] [decimal](38, 0) NULL,
	[NETCONS] [money] NULL,
	[MKTPRICE] [money] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SJBUY]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SJBUY](
	[DEALDATE] [datetime] NOT NULL,
	[TOTAL] [money] NOT NULL,
 CONSTRAINT [PK_SJBUY] PRIMARY KEY CLUSTERED 
(
	[DEALDATE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SJSELL]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SJSELL](
	[DEALDATE] [datetime] NOT NULL,
	[TOTAL] [money] NOT NULL,
 CONSTRAINT [PK_SJSELL] PRIMARY KEY CLUSTERED 
(
	[DEALDATE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[STATEMENTS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[STATEMENTS](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[STMTDATE] [datetime] NOT NULL,
	[STARTDATE] [datetime] NULL,
	[ENDDATE] [datetime] NULL,
	[BALBF] [decimal](33, 9) NULL,
	[BALCF] [decimal](33, 9) NULL,
	[ARREARS7] [decimal](33, 9) NOT NULL,
	[ARREARS14] [decimal](33, 9) NOT NULL,
	[ARREARS21] [decimal](33, 9) NOT NULL,
	[ARREARS28] [decimal](33, 9) NOT NULL,
	[ARREARSOver] [decimal](33, 9) NOT NULL,
 CONSTRAINT [PK_STATEMENTS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatementsReport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatementsReport](
	[RecID] [bigint] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[DealNo] [varchar](50) NULL,
	[TransID] [bigint] NULL,
	[TransDate] [datetime] NULL,
	[TransCode] [varchar](250) NULL,
	[Amount] [decimal](31, 9) NULL,
	[BalBF] [decimal](32, 4) NULL,
	[BalCF] [decimal](32, 4) NULL,
	[Login] [varchar](50) NULL,
	[MatchID] [int] NULL,
	[Matched] [bit] NULL,
	[qty] [int] NOT NULL,
	[price] [decimal](18, 2) NOT NULL,
	[asset] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatementsReportTemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatementsReportTemp](
	[RecID] [bigint] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[DealNo] [varchar](50) NULL,
	[TransID] [bigint] NULL,
	[TransDate] [datetime2](7) NULL,
	[TransCode] [varchar](250) NULL,
	[Amount] [decimal](32, 4) NULL,
	[BalBF] [decimal](32, 4) NULL,
	[BalCF] [decimal](32, 4) NULL,
	[Login] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SystemParams]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemParams](
	[CertDueBy] [int] NULL,
	[FirstCount] [int] NULL,
	[SecondCount] [int] NULL,
	[ThirdCount] [int] NULL,
	[LockDate] [datetime] NULL,
	[applength] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SystemState]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SystemState](
	[Issue] [varchar](100) NULL,
	[Status] [int] NULL,
	[FirstEmail] [varchar](50) NULL,
	[SecondEmail] [varchar](50) NULL,
	[ThirdEmail] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TBItemised]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TBItemised](
	[RecID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[Description] [varchar](100) NULL,
	[Amount] [decimal](34, 4) NULL,
	[Login] [varchar](50) NULL,
	[BalBF] [decimal](32, 4) NULL,
	[BalCF] [decimal](32, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TBItemisedTemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TBItemisedTemp](
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[Description] [varchar](100) NULL,
	[Amount] [decimal](34, 4) NULL,
	[Login] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblAllScripInCustody]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblAllScripInCustody](
	[asset] [varchar](20) NULL,
	[certno] [varchar](50) NULL,
	[qty] [numeric](18, 0) NOT NULL,
	[regholder] [varchar](150) NOT NULL,
	[idno] [varchar](50) NULL,
	[client] [varchar](150) NULL,
	[COMPANYNAME] [varchar](128) NULL,
	[ASSETNAME] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBalancePositionsSettlements]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBalancePositionsSettlements](
	[dealno] [varchar](10) NULL,
	[balancedealno] [varchar](10) NULL,
	[settlementdate] [datetime] NULL,
	[qtyused] [int] NULL,
	[cancelled] [bit] NULL,
	[canceldt] [datetime] NULL,
	[canceluser] [varchar](20) NULL,
	[cancelreason] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBalances]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBalances](
	[ClientNo] [varchar](50) NULL,
	[balance] [decimal](31, 9) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBalancesTemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBalancesTemp](
	[ClientNo] [varchar](50) NULL,
	[balance] [decimal](34, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBrokerDeliveries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBrokerDeliveries](
	[dealno] [varchar](10) NULL,
	[dt] [datetime] NULL,
	[asset] [varchar](10) NULL,
	[certno] [varchar](30) NULL,
	[qty] [int] NULL,
	[client] [varchar](100) NULL,
	[DealQty] [int] NOT NULL,
	[QtyUsed] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBrokerInDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBrokerInDeals](
	[dealno] [varchar](10) NULL,
	[asset] [varchar](20) NULL,
	[qty] [int] NULL,
	[username] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBrokerNMIUnmatchedTXNs]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBrokerNMIUnmatchedTXNs](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[transdate] [datetime] NULL,
	[dealno] [varchar](10) NULL,
	[asset] [varchar](10) NULL,
	[price] [money] NULL,
	[transcode] [varchar](10) NULL,
	[consfrom] [money] NOT NULL,
	[consto] [money] NOT NULL,
	[sharesfrom] [int] NOT NULL,
	[sharesto] [int] NOT NULL,
	[clientno] [varchar](50) NULL,
	[companyname] [varchar](50) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBrokerToBrokerRecon]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBrokerToBrokerRecon](
	[DealNo] [varchar](20) NULL,
	[Asset] [varchar](10) NULL,
	[DealDate] [datetime] NULL,
	[Qty] [int] NULL,
	[Price] [money] NULL,
	[SharesTo] [int] NULL,
	[SharesFrom] [int] NULL,
	[ConsTo] [money] NULL,
	[ConsFrom] [money] NULL,
	[ClientNo] [varchar](10) NULL,
	[Companyname] [varchar](150) NULL,
	[Balance] [money] NULL,
	[username] [varchar](20) NULL,
	[category] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBuySettlementDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBuySettlementDeals](
	[dealdate] [datetime] NULL,
	[asset] [varchar](10) NULL,
	[dealno] [varchar](10) NULL,
	[qty] [int] NULL,
	[price] [money] NULL,
	[NetConsideration] [money] NULL,
	[regholder] [varchar](100) NULL,
	[SettledConsideration] [money] NULL,
	[username] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblBuySettlementScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblBuySettlementScrip](
	[certno] [varchar](30) NULL,
	[Asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[client] [varchar](100) NULL,
	[regholder] [varchar](50) NULL,
	[clientno] [varchar](50) NULL,
	[username] [varchar](20) NULL,
	[refno] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCapTaxCorrect]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCapTaxCorrect](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCashBookReport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCashBookReport](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TransDate] [datetime] NULL,
	[PostDate] [datetime] NULL,
	[ClientNo] [varchar](500) NULL,
	[transcode] [varchar](50) NULL,
	[description] [varchar](500) NULL,
	[amount] [decimal](30, 12) NULL,
	[StartDate] [datetime] NULL,
	[Enddate] [datetime] NULL,
	[BalBf] [decimal](34, 4) NULL,
	[Balcf] [decimal](34, 4) NULL,
	[CashBookID] [int] NULL,
	[RunBal] [money] NULL,
	[username] [varchar](30) NULL,
	[transid] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCertDup]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCertDup](
	[certno] [varchar](20) NULL,
	[asset] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCertDuplicate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCertDuplicate](
	[certno] [varchar](20) NULL,
	[asset] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCertificate]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCertificate](
	[asset] [varchar](10) NULL,
	[certno] [varchar](20) NULL,
	[qty] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCertificateID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblCertificateID](
	[ID] [bigint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClient](
	[ClientNumber] [int] NOT NULL,
	[ClientName] [nvarchar](300) NULL,
	[Firstname] [nvarchar](100) NULL,
	[IdentityNumber] [varchar](50) NULL,
	[PhysicalAddress1] [varchar](50) NULL,
	[PhysicalAddress2] [varchar](50) NULL,
	[PhysicalAddress3] [varchar](50) NULL,
	[PhysicalAddress4] [varchar](50) NULL,
	[PostalAddress1] [varchar](50) NULL,
	[PostalAddress2] [varchar](50) NULL,
	[PostalAddress3] [varchar](50) NULL,
	[PostalAddress4] [varchar](50) NULL,
	[PhoneNumber] [varchar](50) NULL,
	[FaxNumber] [varchar](50) NULL,
	[EmailAddress] [varchar](50) NULL,
	[ContactPerson] [varchar](50) NULL,
	[ContactPhone] [varchar](50) NULL,
	[DealingContact] [varchar](50) NULL,
	[SettlementContact] [varchar](50) NULL,
	[SettlementPhone] [varchar](50) NULL,
	[BuySettlement] [int] NULL,
	[SellSettlement] [int] NULL,
	[ScripRegistrationName] [varchar](1000) NULL,
	[ScripRegistrationAddress1] [varchar](50) NULL,
	[ScripRegistrationAddress2] [varchar](50) NULL,
	[ScripRegistrationAddress3] [varchar](50) NULL,
	[ScripRegistrationAddress4] [varchar](50) NULL,
	[ScripDeliveryName] [varchar](1000) NULL,
	[ScripDeliveryAddress1] [varchar](50) NULL,
	[ScripDeliveryAddress2] [varchar](50) NULL,
	[ScripDeliveryAddress3] [varchar](50) NULL,
	[ScripDeliveryAddress4] [varchar](50) NULL,
	[BrokersNotesName] [varchar](1000) NULL,
	[BrokersNotesAddress1] [varchar](50) NULL,
	[BrokersNotesAddress2] [varchar](50) NULL,
	[BrokersNotesAddress3] [varchar](50) NULL,
	[BrokersNotesAddress4] [varchar](50) NULL,
	[DebtorsStatementName] [varchar](1000) NULL,
	[DebtorsStatementAddress1] [varchar](50) NULL,
	[DebtorsStatementAddress2] [varchar](50) NULL,
	[DebtorsStatementAddress3] [varchar](50) NULL,
	[DebtorsStatementAddress4] [varchar](50) NULL,
	[GeneralNotes] [varchar](1000) NULL,
	[CategoryID] [int] NULL,
	[Broker] [char](1) NULL,
	[PastelCustID] [varchar](7) NULL,
	[PastelSuppID] [varchar](7) NULL,
	[Reference] [varchar](50) NULL,
	[BankName] [varchar](50) NULL,
	[BankBranch] [varchar](50) NULL,
	[BankAccountNumber] [varchar](50) NULL,
	[AddDate] [datetime] NULL,
	[AddUser] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientBalances]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientBalances](
	[ClientNo] [varchar](50) NULL,
	[client] [varchar](100) NULL,
	[balance] [decimal](31, 9) NULL,
	[bal7] [decimal](31, 9) NULL,
	[bal14] [decimal](31, 9) NULL,
	[bal21] [decimal](31, 9) NULL,
	[bal28] [decimal](31, 9) NULL,
	[balover] [decimal](31, 9) NULL,
	[category] [varchar](100) NULL,
	[ADate] [datetime] NULL,
	[AsAt] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientBuySettlementDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientBuySettlementDeals](
	[dealno] [varchar](10) NULL,
	[dealdate] [datetime] NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NOT NULL,
	[price] [money] NOT NULL,
	[consideration] [money] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientBuySettlementScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientBuySettlementScrip](
	[certno] [varchar](30) NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[Client] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientPortFolio]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientPortFolio](
	[clientno] [varchar](10) NOT NULL,
	[asset] [varchar](10) NULL,
	[bought] [int] NULL,
	[sold] [int] NULL,
	[broughtin] [int] NULL,
	[delivered] [int] NULL,
	[net]  AS ((([bought]+[broughtin])-[sold])-[delivered]),
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientPortfolioCounters]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientPortfolioCounters](
	[asset] [varchar](10) NULL,
	[assetname] [varchar](50) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientScripInOffice]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientScripInOffice](
	[asset] [varchar](20) NULL,
	[certno] [varchar](50) NULL,
	[qty] [numeric](18, 0) NOT NULL,
	[datein] [datetime] NOT NULL,
	[clientno] [varchar](10) NULL,
	[client] [varchar](150) NULL,
	[pool] [varchar](50) NULL,
	[regholder] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblClientTrades]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblClientTrades](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[clientno] [varchar](10) NULL,
	[client] [varchar](100) NULL,
	[dealdate] [datetime] NULL,
	[dealno] [varchar](10) NULL,
	[asset] [varchar](10) NULL,
	[buy] [int] NULL,
	[sell] [int] NULL,
	[qty] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCommissionerLevyLedger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCommissionerLevyLedger](
	[startdate] [datetime] NULL,
	[enddate] [datetime] NULL,
	[TransDt] [datetime] NULL,
	[clientno] [bigint] NULL,
	[dealno] [varchar](10) NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[price] [decimal](34, 4) NULL,
	[amount] [decimal](34, 4) NULL,
	[balbf] [decimal](34, 4) NULL,
	[balcf] [decimal](34, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblConsolidationCustody]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblConsolidationCustody](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[consolid] [bigint] NULL,
	[certno] [varchar](20) NULL,
	[qty] [int] NULL,
	[regholder] [varchar](100) NULL,
	[client] [varchar](100) NULL,
	[cdate] [datetime] NULL,
	[newqty] [int] NULL,
	[Cancelled] [bit] NOT NULL,
	[Canceluser] [varchar](30) NULL,
	[CertID] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblConsolidationTransfers]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblConsolidationTransfers](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[consolid] [bigint] NULL,
	[refno] [varchar](20) NULL,
	[oqty] [int] NULL,
	[nqty] [int] NULL,
	[Cancelled] [bit] NOT NULL,
	[Canceluser] [varchar](30) NULL,
	[transid] [bigint] NULL,
	[shapeid] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblConsolidationUnallocated]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblConsolidationUnallocated](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[consolid] [bigint] NULL,
	[certno] [varchar](20) NULL,
	[qty] [int] NULL,
	[regholder] [varchar](150) NULL,
	[cdate] [datetime] NULL,
	[newqty] [int] NULL,
	[Cancelled] [bit] NOT NULL,
	[Canceluser] [varchar](30) NULL,
	[CertID] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblCSDSettlementDetails]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblCSDSettlementDetails](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[origdealno] [varchar](10) NULL,
	[matchdealno] [varchar](10) NULL,
	[dt] [datetime] NULL,
	[qtyused] [int] NOT NULL,
	[settlementdate] [datetime] NULL,
	[settledby] [varchar](50) NULL,
	[cancelled] [bit] NOT NULL,
	[canceldate] [datetime] NULL,
	[cancelreason] [varchar](50) NULL,
	[canceluser] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDealBalanceCertificates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDealBalanceCertificates](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[dealno] [varchar](50) NULL,
	[balcertqty] [int] NULL,
	[BalcertDate] [datetime] NULL,
	[DateOut] [datetime] NULL,
	[Closed] [bit] NOT NULL,
	[CertNo] [varchar](20) NULL,
	[BalRemaining] [int] NOT NULL,
	[Cancelled] [bit] NOT NULL,
	[Canceldt] [datetime] NULL,
	[Canceluser] [varchar](50) NULL,
	[asset] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDealDifferences]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDealDifferences](
	[dealno] [varchar](10) NULL,
	[dealdate] [datetime] NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[clientno] [varchar](10) NULL,
	[settqty] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDealNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDealNo](
	[dealno] [varchar](40) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDeals](
	[dealno] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDealSaleCorrect]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDealSaleCorrect](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDealsClosedLessScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDealsClosedLessScrip](
	[dealno] [varchar](40) NULL,
	[dealdate] [datetime] NOT NULL,
	[ASSET] [varchar](20) NOT NULL,
	[qty] [decimal](18, 0) NOT NULL,
	[client] [varchar](258) NULL,
	[scripqty] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDealsCons]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDealsCons](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NOT NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL,
	[origdeal] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbldeletedfromscripledgerbkp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbldeletedfromscripledgerbkp](
	[ID] [numeric](10, 0) NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [int] NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDeletedScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDeletedScrip](
	[ID] [numeric](10, 0) NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [int] NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbldeletedscripbkp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbldeletedscripbkp](
	[ID] [numeric](10, 0) NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [int] NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDeletedScripTemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDeletedScripTemp](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[LEDGERID] [numeric](10, 0) NOT NULL,
	[DEALNO] [varchar](40) NOT NULL,
	[REVERSETEMP] [bit] NOT NULL,
	[DT] [datetime] NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDeliveries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDeliveries](
	[asset] [varchar](10) NULL,
	[certno] [varchar](20) NULL,
	[qty] [int] NULL,
	[qtyused] [int] NULL,
	[dealno] [varchar](10) NULL,
	[regholder] [varchar](150) NULL,
	[client] [varchar](200) NULL,
	[dvdate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDeliveryReferenceNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDeliveryReferenceNo](
	[refno] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDetailedPortfolioDeliveries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDetailedPortfolioDeliveries](
	[asset] [varchar](50) NULL,
	[cdate] [datetime] NULL,
	[certno] [varchar](50) NULL,
	[qty] [int] NULL,
	[username] [varchar](50) NULL,
	[incoming] [bit] NOT NULL,
	[deal] [bit] NOT NULL,
	[ref] [varchar](50) NULL,
	[clientno] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDividendScripInOffice]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDividendScripInOffice](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[DIVID] [bigint] NULL,
	[CLIENTNO] [varchar](10) NULL,
	[certno] [varchar](20) NULL,
	[INCOMING] [bit] NULL,
	[DEALNO] [varchar](10) NULL,
	[QTY] [int] NULL,
	[GROSS] [money] NULL,
	[TAX] [money] NULL,
	[NET] [money] NULL,
	[reason] [varchar](50) NULL,
	[DateReceived] [datetime] NULL,
	[Client] [varchar](150) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDueToDueFromPositions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDueToDueFromPositions](
	[dealno] [varchar](10) NULL,
	[dealdate] [datetime] NULL,
	[asset] [varchar](10) NULL,
	[price] [money] NULL,
	[qty] [int] NULL,
	[consideration] [money] NULL,
	[qtyout] [int] NULL,
	[outcons] [money] NULL,
	[client] [varchar](150) NULL,
	[duedate] [datetime] NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblDupCerts]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblDupCerts](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NOT NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NOT NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NOT NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblEmailDealNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblEmailDealNo](
	[dealno] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblFavourPositionSettlements]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblFavourPositionSettlements](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[LEDGERID] [numeric](10, 0) NOT NULL,
	[DEALNO] [varchar](40) NOT NULL,
	[DT] [datetime] NOT NULL,
	[USER] [varchar](50) NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL,
	[QTYUSED] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblFavourRegPositions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblFavourRegPositions](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[FDealno] [varchar](10) NULL,
	[FDealDate] [datetime] NULL,
	[clientno] [varchar](10) NULL,
	[qty] [int] NOT NULL,
	[qtyout] [int] NOT NULL,
	[ledgerid] [bigint] NULL,
	[userid] [varchar](30) NULL,
	[cancelled] [bit] NOT NULL,
	[canceldate] [datetime] NULL,
	[canceluser] [varchar](30) NULL,
	[cancelreason] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblFavourToUnallocated]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblFavourToUnallocated](
	[id] [int] NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[asset] [varchar](20) NOT NULL,
	[newcertno] [varchar](50) NULL,
	[qty] [numeric](18, 0) NOT NULL,
	[clientno] [varchar](50) NULL,
	[client] [varchar](150) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblIncomingRegistrations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblIncomingRegistrations](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[clientno] [int] NULL,
	[dealno] [varchar](10) NULL,
	[refno] [varchar](20) NULL,
	[client] [varchar](100) NULL,
	[certno] [varchar](50) NULL,
	[datereceived] [datetime] NULL,
	[tsec] [varchar](50) NULL,
	[destination] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblLedger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblLedger](
	[RecID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[Description] [varchar](100) NULL,
	[Amount] [decimal](31, 9) NULL,
	[DealValue] [decimal](31, 9) NULL,
	[Login] [varchar](50) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[ReportName] [varchar](300) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[BalBF] [decimal](31, 9) NULL,
	[BalCF] [decimal](31, 9) NULL,
	[ClientName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblLedgerBKP]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblLedgerBKP](
	[RecID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[Description] [varchar](100) NULL,
	[Amount] [decimal](31, 9) NULL,
	[DealValue] [decimal](31, 9) NULL,
	[Login] [varchar](50) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[ReportName] [varchar](300) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[BalBF] [decimal](31, 9) NULL,
	[BalCF] [decimal](31, 9) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblLedgerNames]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblLedgerNames](
	[DealNo] [varchar](50) NULL,
	[ClientName] [varchar](257) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblLedgerTemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblLedgerTemp](
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[Description] [varchar](100) NULL,
	[Amount] [decimal](31, 9) NULL,
	[DealValue] [decimal](31, 9) NULL,
	[Login] [varchar](50) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[ReportName] [varchar](300) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblLikOld]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblLikOld](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[licstring] [varchar](50) NULL,
	[dateentered] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblOldOpenPositions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblOldOpenPositions](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NOT NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblOpenPositionsAging]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblOpenPositionsAging](
	[dealno] [varchar](10) NULL,
	[dealdate] [datetime] NULL,
	[companyname] [varchar](150) NULL,
	[client] [varchar](150) NULL,
	[d7] [int] NULL,
	[d14] [int] NULL,
	[d21] [int] NULL,
	[d28] [int] NULL,
	[overthan] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblOutgoingRegistrations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblOutgoingRegistrations](
	[refno] [varchar](50) NULL,
	[datesent] [datetime] NULL,
	[certno] [varchar](50) NULL,
	[asset] [varchar](50) NULL,
	[qty] [int] NULL,
	[tsec] [varchar](50) NULL,
	[shapeqty] [int] NULL,
	[toclient] [int] NULL,
	[shapecertno] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblOutgoingTransfers]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblOutgoingTransfers](
	[refno] [varchar](10) NULL,
	[datesent] [datetime] NULL,
	[certno] [varchar](30) NULL,
	[qty] [int] NULL,
	[asset] [varchar](10) NULL,
	[regholder] [varchar](150) NULL,
	[startdate] [datetime] NULL,
	[enddate] [datetime] NULL,
	[tsec] [varchar](150) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblOutgoingTransferShapes]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblOutgoingTransferShapes](
	[refno] [varchar](20) NULL,
	[qty] [int] NULL,
	[toclient] [varchar](200) NULL,
	[regholder] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingDelivery1stTempTable]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingDelivery1stTempTable](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[certid] [bigint] NULL,
	[certno] [varchar](20) NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[cdate] [datetime] NULL,
	[transform] [bit] NULL,
	[clientno] [varchar](10) NULL,
	[client] [varchar](100) NULL,
	[regholder] [varchar](100) NULL,
	[userid] [varchar](20) NULL,
	[reference] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingDelivery2ndTempTable]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingDelivery2ndTempTable](
	[asset] [varchar](10) NULL,
	[certno] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingRegistrations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingRegistrations](
	[datesent] [datetime] NULL,
	[refno] [varchar](10) NULL,
	[asset] [varchar](10) NULL,
	[certno] [varchar](20) NULL,
	[certqty] [int] NULL,
	[shapeqty] [int] NULL,
	[dealno] [varchar](10) NULL,
	[newowner] [varchar](150) NULL,
	[regholder] [varchar](150) NULL,
	[clientno] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingRegPool]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingRegPool](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset] [varchar](30) NULL,
	[dealno] [varchar](10) NULL,
	[qty] [int] NULL,
	[assetname] [varchar](50) NULL,
	[client] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingRegSummary]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingRegSummary](
	[counter] [varchar](10) NULL,
	[refno] [varchar](20) NULL,
	[datesent] [datetime] NULL,
	[origqty] [int] NULL,
	[qtyout] [int] NULL,
	[assetname] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingSale]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingSale](
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[datein] [datetime] NULL,
	[dealno] [varchar](50) NULL,
	[client] [varchar](100) NULL,
	[certno] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPendingSaleInto]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPendingSaleInto](
	[dealno] [varchar](50) NULL,
	[datein] [datetime] NULL,
	[certno] [varchar](50) NULL,
	[asset] [varchar](50) NULL,
	[qty] [int] NULL,
	[client] [varchar](100) NULL,
	[dealqty] [int] NOT NULL,
	[qtyused] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPermissions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPermissions](
	[profilename] [varchar](50) NOT NULL,
	[screen] [int] NOT NULL,
	[moduleid] [bigint] NOT NULL,
 CONSTRAINT [PK_tblPermissions] PRIMARY KEY CLUSTERED 
(
	[profilename] ASC,
	[screen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblPrintAllReqs]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblPrintAllReqs](
	[ReqID] [int] NOT NULL,
	[Login] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblProfiles]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblProfiles](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[profilename] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblReceivedRegistration]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblReceivedRegistration](
	[id] [bigint] NULL,
	[refnum] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblRefNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblRefNo](
	[RefNo] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblRegistrationReceipt]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblRegistrationReceipt](
	[newcertno] [varchar](50) NULL,
	[asset] [varchar](20) NOT NULL,
	[qty] [numeric](18, 0) NOT NULL,
	[issuedate] [datetime] NULL,
	[holderno] [varchar](50) NULL,
	[transferno] [varchar](50) NULL,
	[client] [varchar](386) NULL,
	[ClientNo] [bigint] NULL,
	[ScripDate] [datetime] NULL,
	[regholder] [varchar](100) NULL,
	[userid] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblSafeCustodyMovements]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSafeCustodyMovements](
	[asset] [varchar](10) NULL,
	[certno] [varchar](30) NULL,
	[qty] [int] NULL,
	[datein] [datetime] NULL,
	[client] [varchar](150) NULL,
	[RegHolder] [varchar](50) NULL,
	[category] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblSafeCustodyScripID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblSafeCustodyScripID](
	[ID] [bigint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblSafeCustodyToClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSafeCustodyToClient](
	[certno] [varchar](30) NULL,
	[qty] [int] NULL,
	[asset] [varchar](10) NULL,
	[client] [varchar](50) NULL,
	[datesent] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblSafeCustodyToUnallocated]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSafeCustodyToUnallocated](
	[dealno] [varchar](10) NULL,
	[dt] [datetime] NULL,
	[certno] [varchar](30) NULL,
	[qty] [int] NULL,
	[asset] [varchar](10) NULL,
	[client] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScreens]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScreens](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[screennumber] [int] NULL,
	[screenname] [varchar](50) NULL,
	[moduleid] [bigint] NOT NULL,
 CONSTRAINT [PK_tblScreens] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripBalancing]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripBalancing](
	[counter] [varchar](10) NOT NULL,
	[bought] [int] NULL,
	[sold] [int] NULL,
	[dueto] [int] NULL,
	[duefrom] [int] NULL,
	[unallocated] [int] NULL,
	[transfersec] [int] NULL,
	[balancecertificates] [int] NULL,
	[imbalance]  AS (((([duefrom]+[unallocated])+[transfersec])-[balancecertificates])-[dueto]) PERSISTED,
	[username] [varchar](20) NULL,
 CONSTRAINT [PK_tblScripBalancing] PRIMARY KEY CLUSTERED 
(
	[counter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripBalancingReport]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripBalancingReport](
	[counter] [varchar](10) NOT NULL,
	[bought] [int] NOT NULL,
	[sold] [int] NOT NULL,
	[dueto] [int] NOT NULL,
	[duefrom] [int] NOT NULL,
	[unallocated] [int] NOT NULL,
	[transfersec] [int] NOT NULL,
	[balancecertificates] [int] NOT NULL,
	[imbalance] [int] NULL,
	[username] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripBalancingSummary]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripBalancingSummary](
	[Result] [varchar](2000) NULL,
	[DueTo] [int] NULL,
	[DueFrom] [int] NULL,
	[Sold] [int] NULL,
	[Bought] [int] NULL,
	[InOffice] [int] NULL,
	[TransferSec] [int] NULL,
	[ShareJob] [int] NULL,
	[Imbalance] [int] NULL,
	[Asset] [varchar](50) NULL,
	[AsAt] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripDeliveriesInOut]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripDeliveriesInOut](
	[id] [numeric](10, 0) NULL,
	[refno] [varchar](30) NULL,
	[asset] [varchar](20) NULL,
	[certno] [varchar](50) NULL,
	[qty] [numeric](18, 0) NULL,
	[cdate] [datetime] NULL,
	[dealno] [varchar](40) NULL,
	[client] [varchar](257) NULL,
	[userid] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripForregistration]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripForregistration](
	[recid] [bigint] IDENTITY(1,1) NOT NULL,
	[id] [numeric](19, 0) NULL,
	[certno] [varchar](50) NULL,
	[asset] [varchar](20) NULL,
	[qty] [numeric](18, 0) NULL,
	[cdate] [datetime] NULL,
	[transform] [bit] NULL,
	[clientno] [varchar](50) NULL,
	[regholder] [varchar](250) NULL,
	[client] [varchar](258) NULL,
	[userid] [varchar](50) NULL,
	[reference] [varchar](150) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripLedgerBKP]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripLedgerBKP](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [int] NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NOT NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NOT NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripLedgerCopy]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripLedgerCopy](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NOT NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NOT NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NOT NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripledgerID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblScripledgerID](
	[id] [bigint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblScripLegderDuplicates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripLegderDuplicates](
	[ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NOT NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NOT NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NOT NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripPool]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripPool](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset] [varchar](10) NOT NULL,
	[certno] [varchar](20) NOT NULL,
	[qty] [int] NULL,
	[assetname] [varchar](250) NULL,
	[client] [varchar](250) NULL,
	[cdate] [datetime] NULL,
	[regholder] [varchar](250) NULL,
	[userid] [varchar](50) NULL,
	[reference] [varchar](20) NULL,
	[transdate] [datetime] NULL,
	[startdate] [datetime] NULL,
	[enddate] [datetime] NULL,
	[source] [varchar](50) NULL,
	[tsec] [varchar](100) NULL,
	[certid] [bigint] NULL,
	[scrippool] [varchar](50) NULL,
	[username] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripReplica]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripReplica](
	[ID] [numeric](10, 0) NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [int] NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NULL,
	[CANCELREASON] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripReversals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblScripReversals](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[asset] [varchar](10) NULL,
	[certno] [varchar](30) NULL,
	[qty] [int] NULL,
	[price] [money] NULL,
	[canceldt] [datetime] NULL,
	[canceluser] [varchar](30) NULL,
	[cancelreason] [varchar](150) NULL,
	[rptpool] [varchar](20) NULL,
	[username] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblScripShapeID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblScripShapeID](
	[ID] [bigint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblSelectedCategory]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSelectedCategory](
	[category] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblSelectedClient]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSelectedClient](
	[clientno] [varchar](20) NULL,
	[username] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblSelectedCounter]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSelectedCounter](
	[asset] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblShapeDealQty]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblShapeDealQty](
	[dealno] [varchar](10) NULL,
	[qty] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblSystemParams]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblSystemParams](
	[ApproveReceipts] [bit] NOT NULL,
	[PartSettlement] [bit] NOT NULL,
	[RegistrationReceipts] [bit] NOT NULL,
	[VerifyScrip] [bit] NOT NULL,
	[FinancialPeriodOnly] [bit] NOT NULL,
	[SeperateBrokerDeals] [bit] NOT NULL,
	[LockScrip4BDeals] [bit] NOT NULL,
	[PrintSettlementLetter] [bit] NOT NULL,
	[PrintSettlementSafeCustody] [bit] NOT NULL,
	[BalanceCertificates] [bit] NOT NULL,
	[DeliverScripOnBuySettlement] [bit] NULL,
	[PrintBrokerInDelivery] [bit] NULL,
	[PartSettlementBrokerDeals] [bit] NOT NULL,
	[WebSiteURL] [varchar](50) NULL,
	[PartSettleBrokerDeals] [bit] NOT NULL,
	[NomineeName] [varchar](50) NULL,
	[PrintClientScripReceipt] [bit] NOT NULL,
	[PrintTransLetter] [bit] NOT NULL,
	[SafeCustodyOutLetter] [bit] NOT NULL,
	[Applength] [int] NOT NULL,
	[Threshhold] [int] NOT NULL,
	[createbrokerbalanceposition] [bit] NULL,
	[DBBackupPath] [varchar](100) NULL,
	[CashflowRecreq] [bit] NOT NULL,
	[DBBackupPathCopy] [varchar](50) NULL,
	[CRC] [varchar](10) NOT NULL,
	[CaptureCSDNo] [bit] NOT NULL,
	[ControlAccount] [varchar](20) NOT NULL,
	[DBServerIP] [varchar](50) NULL,
	[CDCSettlementAccount] [int] NOT NULL,
	[DBName] [varchar](50) NULL,
	[DBUsername] [varchar](50) NULL,
	[DBPassword] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempBrokerScrip]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempBrokerScrip](
	[CLIENTNO] [varchar](20) NULL,
	[CERTNO] [varchar](30) NULL,
	[ASSET] [varchar](10) NULL,
	[QTY] [int] NULL,
	[REGHOLDER] [varchar](50) NULL,
	[TRANSFORM] [bit] NULL,
	[REASON] [varchar](50) NULL,
	[username] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempDealCloseAdj]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempDealCloseAdj](
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ASSET] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[price] [decimal](31, 9) NULL,
	[SHARESOUT] [numeric](18, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempDeliveryNote]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempDeliveryNote](
	[dealno] [varchar](20) NULL,
	[dealdate] [datetime] NULL,
	[qty] [int] NOT NULL,
	[asset] [varchar](10) NULL,
	[dealvalue] [money] NULL,
	[dvdate] [datetime] NULL,
	[clientno] [varchar](10) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempDulpicates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempDulpicates](
	[dealno] [varchar](10) NULL,
	[transcode] [varchar](15) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempID]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempID](
	[id] [bigint] NULL,
	[assetcode] [varchar](20) NULL,
	[certno] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempRefNo]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempRefNo](
	[RefNo] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempSafe]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempSafe](
	[recid] [bigint] IDENTITY(1,1) NOT NULL,
	[id] [bigint] NULL,
	[certno] [varchar](30) NULL,
	[asset] [varchar](10) NULL,
	[qty] [int] NULL,
	[cdate] [datetime] NULL,
	[transform] [bit] NULL,
	[clientno] [varchar](20) NULL,
	[regholder] [varchar](50) NULL,
	[client] [varchar](50) NULL,
	[userid] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempSafeCustody]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempSafeCustody](
	[id] [numeric](10, 0) NOT NULL,
	[certno] [varchar](50) NOT NULL,
	[asset] [varchar](20) NOT NULL,
	[qty] [numeric](18, 0) NULL,
	[cdate] [datetime] NOT NULL,
	[transform] [bit] NULL,
	[clientno] [varchar](50) NULL,
	[regholder] [varchar](150) NOT NULL,
	[client] [varchar](258) NULL,
	[userid] [varchar](50) NOT NULL,
	[reference] [varchar](30) NULL,
	[username] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTempShape]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTempShape](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Asset] [varchar](10) NULL,
	[Qty] [int] NOT NULL,
	[CD] [bit] NOT NULL,
	[dealno] [varchar](50) NULL,
	[toclient] [varchar](20) NOT NULL,
	[regholder] [varchar](150) NULL,
	[regaddress] [varchar](150) NULL,
	[username] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbltempshapeid]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbltempshapeid](
	[id] [bigint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblTopTrader]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTopTrader](
	[cno] [int] NULL,
	[cons] [decimal](34, 4) NULL,
	[client] [varchar](100) NULL,
	[StartDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[Cnt] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTopTraders]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTopTraders](
	[cno] [bigint] NULL,
	[consideration] [decimal](34, 4) NULL,
	[commission] [decimal](34, 4) NULL,
	[startdt] [datetime] NULL,
	[enddt] [datetime] NULL,
	[clientname] [varchar](100) NULL,
	[Cnt] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTopTradersTemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblTopTradersTemp](
	[cno] [int] NULL,
	[consideration] [decimal](34, 4) NULL,
	[commission] [decimal](34, 4) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblTraceHistory]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTraceHistory](
	[recid] [bigint] IDENTITY(1,1) NOT NULL,
	[tracedate] [datetime] NULL,
	[details] [varchar](500) NULL,
	[username] [varchar](20) NULL,
	[logedinuser] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTransfer]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTransfer](
	[refno] [varchar](20) NULL,
	[datesent] [datetime] NULL,
	[userid] [varchar](20) NULL,
	[asset] [varchar](10) NULL,
	[transsec] [varchar](50) NULL,
	[id] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblTXNStemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblTXNStemp](
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NOT NULL,
	[TransCode] [varchar](50) NOT NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblUnallocated1stTempTable]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblUnallocated1stTempTable](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[certid] [bigint] NULL,
	[certno] [varchar](50) NULL,
	[asset] [varchar](50) NULL,
	[qty] [int] NULL,
	[cdate] [datetime] NULL,
	[transform] [bit] NULL,
	[clientno] [varchar](10) NULL,
	[client] [varchar](250) NULL,
	[regholder] [varchar](250) NULL,
	[userid] [varchar](50) NULL,
	[reference] [varchar](150) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblUnallocated2ndTempTable]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblUnallocated2ndTempTable](
	[asset] [varchar](10) NULL,
	[certno] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblUserLastCounter]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblUserLastCounter](
	[asset] [varchar](10) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tblWareHouseBuyBacks]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tblWareHouseBuyBacks](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NOT NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](31, 9) NULL,
	[INVESTORPROTECTION] [decimal](31, 9) NULL,
	[COMMISSIONERLEVY] [decimal](31, 9) NULL,
	[ZSELEVY] [decimal](31, 9) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](31, 9) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[OrigDealNo] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tempmerged]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tempmerged](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[CNO] [int] NULL,
	[POSTDT] [datetime] NULL,
	[DEALNO] [varchar](40) NULL,
	[TRANSCODE] [varchar](50) NULL,
	[TRANSDT] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AMOUNT] [decimal](33, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](33, 9) NULL,
	[ARREARSCF] [decimal](33, 9) NULL,
	[USER] [varchar](20) NULL,
	[LOGIN] [varchar](10) NULL,
	[SUMAMOUNT] [decimal](33, 9) NOT NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[temppass]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[temppass](
	[pass] [varchar](50) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TopTraders]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TopTraders](
	[RecNo] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[ClientName] [varchar](100) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Value] [decimal](18, 2) NULL,
	[DealType] [varchar](50) NULL,
	[username] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[totals_view1]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[totals_view1](
	[cat] [varchar](50) NULL,
	[total] [numeric](38, 6) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRADINGSUMMARY]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRADINGSUMMARY](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[DEALTYPE] [varchar](20) NULL,
	[DEALNO] [varchar](40) NULL,
	[DEALDATE] [datetime] NOT NULL,
	[CLIENTNO] [varchar](50) NULL,
	[CATEGORY] [varchar](20) NULL,
	[ASSET] [varchar](20) NOT NULL,
	[QTY] [decimal](18, 0) NOT NULL,
	[PRICE] [decimal](33, 9) NOT NULL,
	[CONSIDERATION] [decimal](33, 9) NULL,
	[COMMISSION] [decimal](33, 9) NULL,
	[BASICCHARGES] [decimal](33, 9) NULL,
	[CONTRACTSTAMPS] [decimal](33, 9) NULL,
	[TRANSFERFEES] [decimal](33, 9) NULL,
	[SHARESOUT] [decimal](18, 0) NULL,
	[CHQNO] [decimal](18, 0) NULL,
	[WTAX] [decimal](33, 9) NULL,
	[COMMISSIONERLEVY] [decimal](18, 9) NULL,
	[CAPITALGAINS] [decimal](18, 9) NULL,
	[INVESTORPROTECTION] [decimal](18, 9) NULL,
	[ZSELEVY] [decimal](18, 9) NULL,
	[VAT] [decimal](18, 9) NULL,
	[BroughtIn] [int] NOT NULL,
	[TakenOut] [int] NOT NULL,
	[ClientName] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[UserID] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRANSACTIONS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRANSACTIONS](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL,
 CONSTRAINT [PK_TRANSACTIONS] PRIMARY KEY CLUSTERED 
(
	[TRANSID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[transactions14082015]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[transactions14082015](
	[TRANSID] [int] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRANSACTIONSAGING]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRANSACTIONSAGING](
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NULL,
	[TransDate] [datetime2](3) NULL,
	[Amount] [decimal](31, 9) NULL,
	[transcode] [varchar](50) NULL,
	[MatchID] [int] NULL,
	[DealNo] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransactionsNullified]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransactionsNullified](
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](31, 9) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](31, 9) NULL,
	[Amount] [decimal](31, 9) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[transactionstemp]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[transactionstemp](
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DEALNO] [varchar](40) NULL,
	[TRANSCODE] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](36, 4) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[USER] [varchar](20) NULL,
	[LOGIN] [varchar](10) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NOT NULL,
	[matched] [bit] NOT NULL,
	[Consideration] [decimal](17, 4) NULL,
	[Amount] [decimal](17, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransferSecretaries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransferSecretaries](
	[REFNO] [varchar](50) NULL,
	[QTY] [int] NULL,
	[REGHOLDER] [varchar](250) NULL,
	[ASSET] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRANSJUL]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRANSJUL](
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](36, 4) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](17, 4) NULL,
	[Amount] [decimal](17, 4) NULL,
	[YON] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRANSTYPES]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRANSTYPES](
	[TransType] [varchar](50) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[Auto] [bit] NOT NULL,
	[Credit] [bit] NOT NULL,
	[Login] [varchar](50) NULL,
	[Active] [bit] NULL,
 CONSTRAINT [PK_TransTypes] PRIMARY KEY CLUSTERED 
(
	[TransType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrialBalanceFinal]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrialBalanceFinal](
	[ACCOUNT] [varchar](40) NOT NULL,
	[GROUP] [varchar](40) NULL,
	[DEBITBAL] [decimal](31, 9) NULL,
	[CREDITBAL] [decimal](31, 9) NULL,
	[ClientNo] [varchar](50) NULL,
	[AsAt] [datetime] NULL,
 CONSTRAINT [PK_TrialBalanceFinal] PRIMARY KEY CLUSTERED 
(
	[ACCOUNT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrialBalancePrepare1]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrialBalancePrepare1](
	[ClientNo] [varchar](50) NOT NULL,
	[BAL] [decimal](31, 9) NULL,
 CONSTRAINT [PK_TrialBalancePrepare1] PRIMARY KEY CLUSTERED 
(
	[ClientNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrialBalancePrepare2]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrialBalancePrepare2](
	[CAT] [varchar](40) NOT NULL,
	[DEBTORS] [decimal](31, 9) NULL,
	[CREDITORS] [decimal](31, 9) NULL,
 CONSTRAINT [PK_TrialBalancePrepare2] PRIMARY KEY CLUSTERED 
(
	[CAT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrialBalancePrepare3]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrialBalancePrepare3](
	[ClientNo] [varchar](50) NOT NULL,
	[BAL] [decimal](31, 9) NULL,
	[TransCode] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TurnOver]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TurnOver](
	[ClientNo] [varchar](50) NULL,
	[Asset] [varchar](50) NULL,
	[DealType] [varchar](50) NULL,
	[Qty] [numeric](18, 0) NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[DealDate] [datetime] NULL,
	[Login] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[USERS]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[USERS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[LOGIN] [varchar](50) NOT NULL,
	[PASS] [varchar](50) NOT NULL,
	[QUESTION] [varchar](255) NULL,
	[ANSWER] [varchar](255) NULL,
	[NAME] [varchar](50) NULL,
	[PROFILE] [varchar](50) NOT NULL,
	[SYSTEMAINT] [bit] NOT NULL,
	[EXPDATE] [datetime] NULL,
	[ISLOCKED] [bit] NOT NULL,
	[LOGOUTAT] [datetime] NULL,
	[LOGINAT] [datetime] NULL,
	[LOGGEDIN] [bit] NULL,
	[LASTPING] [datetime] NULL,
	[LASTSCREEN] [varchar](255) NULL,
	[PCNAME] [varchar](50) NULL,
	[PCLICENSE] [varchar](50) NULL,
	[temppass] [bit] NULL,
	[pwd] [varchar](50) NULL,
	[IsDefault] [bit] NULL,
	[lockedat] [datetime] NULL,
	[LoginErrorMessage] [varchar](50) NULL,
	[password1] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserSettings]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserSettings](
	[Login] [varchar](50) NULL,
	[Skin] [varchar](50) NULL,
	[BackImage] [image] NULL,
	[IsDefault] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZCashBookTrans]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZCashBookTrans](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](50) NULL,
	[Description] [varchar](50) NULL,
	[Amount] [decimal](36, 4) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](17, 4) NULL,
	[Cancelled] [bit] NULL,
	[ChqRqID] [bigint] NULL,
	[ExCurrency] [varchar](50) NULL,
	[ExRate] [float] NULL,
	[ExAmount] [float] NULL,
	[MatchID] [bigint] NULL,
	[YON] [bit] NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZCashBookTrans] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZClientCategory]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZClientCategory](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[ClientCategory] [varchar](20) NOT NULL,
	[BasicCharges] [decimal](31, 9) NULL,
	[Commission] [real] NOT NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[VAT] [decimal](19, 4) NOT NULL,
	[CapitalGains] [decimal](17, 4) NULL,
	[InvestorProtection] [decimal](17, 4) NULL,
	[CommissionerLevy] [decimal](17, 4) NULL,
	[ZSELevy] [decimal](17, 4) NULL,
	[NMIRebate] [decimal](17, 4) NULL,
	[Login] [varchar](50) NULL,
	[TxnDate] [datetime2](7) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZClientCategory] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZClients]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZClients](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[CID] [int] NOT NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[SHORTCODE] [varchar](50) NULL,
	[LONGCODE] [varchar](50) NULL,
	[TITLE] [varchar](8) NULL,
	[FIRSTNAME] [varchar](128) NULL,
	[SURNAME] [varchar](128) NULL,
	[COMPANYNAME] [varchar](128) NULL,
	[TYPE] [varchar](20) NOT NULL,
	[CATEGORY] [varchar](20) NOT NULL,
	[STATUS] [varchar](20) NULL,
	[STATUSREASON] [varchar](128) NULL,
	[NOMINEECO] [bit] NOT NULL,
	[IDTYPE] [varchar](20) NULL,
	[IDNO] [varchar](50) NULL,
	[UtilityType] [varchar](20) NULL,
	[UtilityNo] [varchar](50) NULL,
	[PhysicalAddress] [varchar](255) NULL,
	[PostalAddress] [varchar](255) NULL,
	[UsePhysicalAddress] [bit] NOT NULL,
	[CONTACTNO] [varchar](255) NULL,
	[MOBILENOSMS] [varchar](100) NULL,
	[MOBILENO] [varchar](1000) NULL,
	[AltMobile] [varchar](50) NULL,
	[Fax] [varchar](255) NULL,
	[EMAIL] [varchar](2000) NULL,
	[CONTACTVERIFIED] [varchar](20) NULL,
	[DateAdded] [datetime] NOT NULL,
	[BANK] [varchar](50) NULL,
	[BANKBRANCH] [varchar](50) NULL,
	[BankAccountNo] [varchar](50) NULL,
	[BankAccountType] [varchar](50) NULL,
	[BUYSETTLE] [varchar](50) NOT NULL,
	[SELLSETTLE] [varchar](50) NOT NULL,
	[ORDERVALIDITY] [int] NULL,
	[RNAME] [varchar](128) NULL,
	[RADDRESS] [varchar](255) NULL,
	[DELIVERYOPTION] [varchar](50) NOT NULL,
	[DNAME] [varchar](128) NULL,
	[DADDRESS] [varchar](255) NULL,
	[SECTOR] [varchar](50) NULL,
	[SENDPRICES] [varchar](10) NOT NULL,
	[SENDDEALS] [varchar](10) NOT NULL,
	[SENDPRICESON] [varchar](100) NULL,
	[LoginID] [varchar](50) NULL,
	[DIVCLIENTNO] [int] NULL,
	[SENDPRICESINCLUDE] [varchar](100) NULL,
	[OnlineSubscribed] [bit] NOT NULL,
	[Sex] [varchar](10) NULL,
	[Directors] [varchar](100) NULL,
	[ReferredBy] [varchar](50) NULL,
	[Employer] [varchar](100) NULL,
	[JobTitle] [varchar](50) NULL,
	[ContactPerson] [varchar](50) NULL,
	[BusPhone] [varchar](50) NULL,
	[DateEdited] [datetime2](7) NULL,
	[EditedBy] [varchar](50) NULL,
	[StatusDate] [datetime2](7) NULL,
	[NomineeAccount] [bit] NOT NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZClients] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZDealallocations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZDealallocations](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[ID] [numeric](18, 0) NOT NULL,
	[DocketNo] [numeric](19, 0) NULL,
	[DealType] [varchar](20) NULL,
	[DealNo] [varchar](40) NOT NULL,
	[DealDate] [datetime] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[OrderNo] [numeric](18, 0) NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Consideration] [decimal](31, 9) NULL,
	[NetCommission] [decimal](31, 9) NULL,
	[BASICCHARGES] [decimal](31, 9) NULL,
	[StampDuty] [decimal](31, 9) NULL,
	[TRANSFERFEES] [float] NULL,
	[Reference] [varchar](150) NULL,
	[DEALER] [varchar](30) NULL,
	[APPROVED] [bit] NULL,
	[SHARESOUT] [numeric](18, 0) NULL,
	[OutTransSec] [bit] NULL,
	[CERTDUEBY] [datetime] NULL,
	[SCRIPSETTLED] [bit] NULL,
	[CHQNO] [numeric](18, 0) NULL,
	[CHQRQID] [numeric](18, 0) NULL,
	[CHQPRINTED] [bit] NULL,
	[Cancelled] [bit] NULL,
	[MERGED] [bit] NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](30) NULL,
	[PAIDTAX] [bit] NULL,
	[PAIDZSE] [bit] NULL,
	[PAIDREBATE] [bit] NULL,
	[ADJUSTMENT] [bit] NULL,
	[CONSOLIDATED] [bit] NULL,
	[WTAX] [decimal](31, 9) NULL,
	[PAIDWTAX] [bit] NULL,
	[CancelLoginID] [varchar](50) NULL,
	[CancelDate] [datetime] NULL,
	[DateAdded] [datetime] NULL,
	[VAT] [decimal](31, 9) NOT NULL,
	[PAIDVAT] [bit] NULL,
	[CONTRA] [bit] NULL,
	[CAPITALGAINS] [decimal](17, 4) NULL,
	[INVESTORPROTECTION] [decimal](17, 4) NULL,
	[COMMISSIONERLEVY] [decimal](17, 4) NULL,
	[ZSELEVY] [decimal](17, 4) NULL,
	[PAIDCAPITALGAINSTAX] [bit] NULL,
	[PAIDINVESTORPROTECTIONTAX] [bit] NULL,
	[PAIDCOMMLV] [bit] NULL,
	[PAIDZSELV] [bit] NULL,
	[Uploaded] [bit] NULL,
	[DealValue] [decimal](17, 4) NULL,
	[GrossCommission] [float] NULL,
	[NMIRebate] [float] NULL,
	[ApprovedBy] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[AutoMatch] [bit] NULL,
	[Cancelreason] [varchar](150) NULL,
	[YON] [bit] NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZDealallocations] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZDockets]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZDockets](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetCode] [varchar](50) NOT NULL,
	[DocketNo] [numeric](19, 0) NOT NULL,
	[DocketDate] [datetime] NOT NULL,
	[BrokerNo] [varchar](50) NOT NULL,
	[COUNTERPARTY] [varchar](50) NULL,
	[DealType] [varchar](50) NOT NULL,
	[EXTERNALF] [bit] NULL,
	[STATUS] [varchar](50) NOT NULL,
	[Price] [decimal](31, 9) NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[DealValue] [decimal](31, 9) NULL,
	[BALBF] [decimal](31, 9) NULL,
	[ZSEREFNO] [numeric](18, 0) NULL,
	[BALCF] [decimal](31, 9) NULL,
	[USERID] [varchar](50) NULL,
	[COMMENTS] [varchar](50) NULL,
	[LOGIN] [varchar](50) NULL,
	[ADJUSTMENT] [bit] NULL,
	[BnB] [bit] NULL,
	[DateAdded] [datetime2](7) NULL,
	[CancelDate] [datetime2](7) NULL,
	[CancelledBy] [varchar](50) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZDockets] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZOrders]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZOrders](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[OrderNo] [numeric](18, 0) NOT NULL,
	[POrderNo] [varchar](50) NULL,
	[OrderDate] [datetime] NOT NULL,
	[DateAdded] [datetime2](7) NOT NULL,
	[Asset] [varchar](20) NOT NULL,
	[Qty] [numeric](18, 0) NOT NULL,
	[OrderValue] [decimal](31, 9) NULL,
	[PLimit] [varchar](50) NULL,
	[Limit] [varchar](50) NULL,
	[Reference] [varchar](150) NULL,
	[Instruction] [varchar](50) NULL,
	[QtyOs] [numeric](18, 0) NOT NULL,
	[ScripAt] [varchar](50) NULL,
	[Status] [varchar](50) NOT NULL,
	[Media] [varchar](50) NULL,
	[OrderType] [varchar](20) NOT NULL,
	[DealerID] [varchar](40) NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[ExpiryDate] [datetime2](7) NULL,
	[CancelledID] [varchar](10) NULL,
	[CancelledDate] [datetime2](7) NULL,
	[Login] [varchar](10) NULL,
	[CancelReason] [varchar](150) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZOrders] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZRequisitions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZRequisitions](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[LETTER] [bit] NULL,
	[Amount] [decimal](31, 9) NULL,
	[TransDate] [datetime] NULL,
	[CHQNO] [decimal](18, 0) NULL,
	[CHQAMT] [decimal](31, 9) NULL,
	[CHQID] [decimal](18, 0) NULL,
	[PAYEE] [varchar](100) NULL,
	[APPROVED] [bit] NULL,
	[COMMENTS] [varchar](255) NULL,
	[TOPRINT] [bit] NULL,
	[PRINTED] [bit] NULL,
	[LOGIN] [varchar](50) NULL,
	[Cancelled] [bit] NOT NULL,
	[TRANSID] [int] NULL,
	[APPROVEDBY] [varchar](50) NULL,
	[CANCELLEDBY] [varchar](50) NULL,
	[ENTEREDBY] [varchar](50) NULL,
	[RQPRINTED] [bit] NULL,
	[CASHBOOK] [varchar](50) NULL,
	[ISRECEIPT] [bit] NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[TRANSCODE] [varchar](50) NULL,
	[PostDate] [datetime] NULL,
	[ExCurrency] [varchar](50) NULL,
	[ExAmount] [float] NULL,
	[ExRate] [float] NULL,
	[DealNo] [varchar](50) NULL,
	[MatchID] [bigint] NULL,
	[CashBookID] [int] NULL,
	[Method] [varchar](50) NULL,
	[ReqID] [int] NOT NULL,
	[CancelReason] [varchar](150) NULL,
	[CancelDate] [datetime2](7) NULL,
	[CashflowReq] [bit] NOT NULL,
	[AmalgamationID] [bigint] NOT NULL,
	[YON] [bit] NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZRequisitions] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZScripdeliveries]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZScripdeliveries](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[DID] [numeric](18, 0) NOT NULL,
	[DEALNO] [varchar](50) NOT NULL,
	[DVDATE] [datetime] NOT NULL,
	[CALLER] [varchar](50) NOT NULL,
	[CALLEE] [varchar](50) NOT NULL,
	[CALLTIME] [datetime] NOT NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELDT] [datetime] NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELREF] [varchar](50) NULL,
	[CHQREQ] [numeric](18, 0) NULL,
	[CANCELREASON] [varchar](50) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZScripdeliveries] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZScripledger]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZScripledger](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[ID] [numeric](10, 0) NOT NULL,
	[REFNO] [varchar](30) NOT NULL,
	[ITEMNO] [int] NOT NULL,
	[INCOMING] [bit] NOT NULL,
	[CDATE] [datetime] NOT NULL,
	[USERID] [varchar](50) NOT NULL,
	[REASON] [varchar](50) NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[CERTNO] [varchar](50) NULL,
	[ASSET] [varchar](20) NULL,
	[QTY] [numeric](18, 0) NOT NULL,
	[REGHOLDER] [varchar](50) NOT NULL,
	[ADDRESS] [varchar](255) NULL,
	[TRANSFORM] [bit] NOT NULL,
	[DNAME] [varchar](50) NULL,
	[DADDRESS] [varchar](255) NULL,
	[CLOSED] [bit] NOT NULL,
	[COMMENTS] [varchar](100) NULL,
	[LOGIN] [varchar](50) NULL,
	[CANCELLED] [bit] NOT NULL,
	[CANCELUSER] [varchar](50) NULL,
	[CANCELDT] [datetime] NULL,
	[VERIFIED] [int] NOT NULL,
	[VERIFYUSER] [varchar](50) NULL,
	[VERIFYDT] [datetime] NULL,
	[VERIFYREF] [varchar](50) NULL,
	[ISSUEDATE] [datetime] NULL,
	[HOLDERNO] [varchar](50) NULL,
	[TRANSFERNO] [varchar](50) NULL,
	[SHAPEID] [int] NOT NULL,
	[INCOMINGID] [bigint] NOT NULL,
	[CANCELREASON] [varchar](50) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZScripledger] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZScripsafe]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZScripsafe](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[CLIENTNO] [varchar](50) NOT NULL,
	[LEDGERID] [int] NOT NULL,
	[NOMINEE] [bit] NOT NULL,
	[DATEIN] [datetime] NOT NULL,
	[DATEOUT] [datetime] NULL,
	[CLOSED] [bit] NOT NULL,
	[LOGIN] [varchar](50) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZScripsafe] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZtblDealBalanceCertificates]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZtblDealBalanceCertificates](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[dealno] [varchar](50) NULL,
	[balcertqty] [int] NULL,
	[BalcertDate] [datetime] NULL,
	[DateOut] [datetime] NULL,
	[Closed] [bit] NOT NULL,
	[CertNo] [varchar](20) NULL,
	[BalRemaining] [int] NOT NULL,
	[Cancelled] [bit] NOT NULL,
	[Canceldt] [datetime] NULL,
	[Canceluser] [varchar](50) NULL,
	[asset] [varchar](20) NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZtblDealBalanceCertificates] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZTransactions]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZTransactions](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[TRANSID] [int] NOT NULL,
	[ClientNo] [varchar](50) NOT NULL,
	[PostDate] [datetime] NULL,
	[DealNo] [varchar](40) NULL,
	[TransCode] [varchar](50) NULL,
	[TransDate] [datetime] NULL,
	[REFNO] [varchar](10) NULL,
	[DESCRIPTION] [varchar](50) NULL,
	[AmountOldFalcon] [decimal](36, 4) NULL,
	[CASH] [bit] NULL,
	[BANK] [varchar](50) NULL,
	[BANKBR] [varchar](20) NULL,
	[CHQNO] [varchar](20) NULL,
	[DRAWER] [varchar](50) NULL,
	[ARREARSBF] [decimal](34, 6) NULL,
	[ARREARSCF] [decimal](34, 6) NULL,
	[LOGIN] [varchar](50) NULL,
	[SUMAMOUNT] [decimal](34, 6) NULL,
	[CASHBOOKID] [int] NULL,
	[Exported] [bit] NULL,
	[ORIGINALTRANSID] [int] NULL,
	[Uploaded] [bit] NULL,
	[matched] [bit] NULL,
	[Consideration] [decimal](17, 4) NULL,
	[Amount] [decimal](17, 4) NULL,
	[YON] [bit] NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZTransactions] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ZUsers]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ZUsers](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[LOGIN] [varchar](50) NOT NULL,
	[PASS] [varchar](50) NOT NULL,
	[QUESTION] [varchar](255) NULL,
	[ANSWER] [varchar](255) NULL,
	[NAME] [varchar](50) NULL,
	[PROFILE] [varchar](50) NOT NULL,
	[SYSTEMAINT] [bit] NOT NULL,
	[EXPDATE] [datetime] NULL,
	[ISLOCKED] [bit] NOT NULL,
	[LOGOUTAT] [datetime] NULL,
	[LOGINAT] [datetime] NULL,
	[LOGGEDIN] [bit] NULL,
	[LASTPING] [datetime] NULL,
	[LASTSCREEN] [varchar](255) NULL,
	[PCNAME] [varchar](50) NULL,
	[PCLICENSE] [varchar](50) NULL,
	[temppass] [bit] NULL,
	[AuditAction] [char](1) NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[AuditUser] [varchar](50) NOT NULL,
	[AuditApp] [varchar](128) NULL,
 CONSTRAINT [PK_ZUsers] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[cat_view]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[cat_view]
AS 
select	a.assetcode, a.linkto, a.shares,
	'cat' = CASE
			WHEN a.linkto IS NULL THEN a.category
			ELSE (select ast.category from assets ast where ast.assetcode = a.linkto)
		END
from assets a
where a.status in ('ACTIVE','SUSPENDED') and (a.shares > 0)

GO
/****** Object:  View [dbo].[catshares_view]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[catshares_view]
AS 
select cat, sum(shares) as 'allshares' from cat_view group by cat

GO
/****** Object:  View [dbo].[weights_view]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[weights_view]
AS 
select	c.assetcode, c.cat, c.shares,
	'weight' = (c.shares / (select cs.allshares from catshares_view cs where cs.cat = c.cat))*100,
	'price' = (select top 1 history from prices p where (p.assetcode = c.assetcode) and (((p.[date] = '2011/04/13') and (p.[session] <= 'AM')) or (p.[date] < '2011/04/13')) order by p.[date] desc, p.[id] desc)
from cat_view c

GO
/****** Object:  View [dbo].[totals_view]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[totals_view]
AS 
select cat, sum(weight*price*100) as total from weights_view group by cat

GO
/****** Object:  View [dbo].[vwCashFlowIn]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[vwCashFlowIn]
as
select d.asset, d.qty, d.certdueby as 'Due Date', d.id, d.clientno,
d.dealno, d.dealtype, d.dealdate,
d.dealvalue as consideration,
s.dvdate, s.[caller], s.callee, s.calltime, s.cancelled, s.canceldt,
s.canceluser, s.cancelref, s.chqreq, s.did,
'settled' = case d.sharesout when 0 then CONVERT(bit, 1) else CONVERT(bit, 0) end,
r.approved
from
 DEALALLOCATIONS d inner join SCRIPDELIVERIES s on d.DealNo = s.DEALNO
 inner join REQUISITIONS r on d.DealNo = r.DealNo
 where d.DealType = 'SELL'
 and s.DEALNO = d.DealNo
GO
/****** Object:  View [dbo].[vwCashFlowOut]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[vwCashFlowOut]
as

select d.Asset,d.Qty,d.certdueby as 'Due Date', d.[id], d.clientno,
	d.dealno,d.dealtype,d.dealdate,
                d.consideration+d.basiccharges+d.transferfees+d.GrossCommission+d.wtax+d.stampduty+d.vat+d.commissionerlevy+d.capitalgains+d.investorprotection+d.zselevy as consideration,
                s.dvdate, s.caller,s.callee,s.calltime, s.cancelled, s.canceldt,
	s.canceluser,s.cancelref,s.chqreq,s.did,
	'settled' = case d.sharesout when 0 then convert(bit,1) else convert(bit,0) end
	from DealAllocations d, scripdeliveries s
	where (d.dealtype = 'BUY')
		and (s.dealno = d.dealno)


GO
/****** Object:  View [dbo].[vwClientListing]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[vwClientListing]
as
select clientno,
case [type]
	when 'COMPANY' then companyname
	else SURNAME+' '+FIRSTNAME
end as clientname,
[type] as clienttype,
category, [status], physicaladdress, contactno
from clients

GO
/****** Object:  View [dbo].[vwClosedDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[vwClosedDeals]
as
with deals as
(select dealno, asset, dealdate, certdueby, dealtype, clientno, qty, sharesout, price, consideration
from dealallocations where sharesout = 0 and approved = 1 and cancelled = 0 and merged = 0 and CONSOLIDATED = 0
)
select d.dealno, d.asset, d.dealdate, d.certdueby as duedate, d.dealtype, d.clientno, d.qty, d.sharesout, d.price, d.consideration
from deals d inner join clients c on d.clientno = c.clientno where d.SHARESOUT = 0




GO
/****** Object:  View [dbo].[vwDaybookAllocations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE view [dbo].[vwDaybookAllocations]
as
select x.dealno, 
case x.bookover
	when 1 then 'B/OVER'
	else x.dealtype
end as dealtype, x.dealdate, a.zsecode+' - '+a.assetname as asset, x.qty, x.price, 
x.Consideration, x.GrossCommission, x.StampDuty, x.VAT, x.CAPITALGAINS, x.INVESTORPROTECTION, x.CSDLevy, 
x.ZSELEVY, x.COMMISSIONERLEVY, x.csdnumber, a.assetname, x.dealvalue, x.certdueby, x.basiccharges,
case c.[type]
	when 'COMPANY' then c.companyname
	else concat(c.surname,' ',c.firstname)
end as client, c.[type], c.category, c.physicaladdress, c.clientno,
d.commission as comchg, d.stampduty as sdtchg, d.vat as vatchg, d.capitalgains as cgtchg, d.investorprotection as iptchg, d.commissionerlevy as secchg, d.zselevy as zsechg, d.csdlevy as csdchg, a.isino
from dealallocations x inner join assets a on x.asset = a.assetcode
inner join clients c on x.clientno = c.clientno
left join clientcategory d on c.category = d.clientcategory
where x.cancelled = 0
and x.merged = 0












GO
/****** Object:  View [dbo].[vwDealAllocations]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [dbo].[vwDealAllocations]
as
select d.clientno, d.dealtype, d.dealdate, d.dealno, d.asset, d.qty, d.price, d.consideration, d.grosscommission, d.stampduty, D.VAT, d.capitalgains, d.investorprotection, d.zselevy, d.commissionerlevy, d.csdlevy, d.dealvalue, D.CSDNUMBER
, c.category,
case c.[type]
when 'COMPANY' then c.companyname
else surname+' '+firstname
end as client, c.physicaladdress, d.id, a.assetname, d.NetCommission, d.BASICCHARGES, d.certdueby
from dealallocations d inner join clients c on d.clientno = c.clientno
inner join assets a on d.asset = a.assetcode
where d.cancelled = 0
and d.merged = 0







GO
/****** Object:  View [dbo].[vwDups]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwDups]
AS
SELECT     dbo.TRANSACTIONS.CNO, dbo.TRANSACTIONS.DEALNO, dbo.TRANSACTIONS.TRANSCODE, COUNT(dbo.TRANSACTIONS.DEALNO) AS NumDups, 
                      dbo.DEALALLOCATIONS.DEALDATE, MAX(dbo.TRANSACTIONS.TRANSID) AS Transid
FROM         dbo.TRANSACTIONS INNER JOIN
                      dbo.DEALALLOCATIONS ON dbo.TRANSACTIONS.DEALNO = dbo.DEALALLOCATIONS.DEALNO
GROUP BY dbo.TRANSACTIONS.CNO, dbo.TRANSACTIONS.DEALNO, dbo.TRANSACTIONS.TRANSCODE, dbo.DEALALLOCATIONS.DEALDATE
HAVING      (NOT (dbo.TRANSACTIONS.DEALNO IS NULL)) AND (dbo.TRANSACTIONS.CNO >= 0 AND dbo.TRANSACTIONS.CNO <= 29) AND 
                      (dbo.DEALALLOCATIONS.DEALDATE >= CONVERT(DATETIME, '2010-01-11 00:00:00', 102)) AND (COUNT(dbo.TRANSACTIONS.DEALNO) > 1)

GO
/****** Object:  View [dbo].[vwOpenDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[vwOpenDeals]
as
with deals as
(select dealno, asset, dealdate, dealtype, clientno, qty, sharesout, price, consideration, CertDueBy
from dealallocations where sharesout > 0 and approved = 1 and cancelled = 0 and merged = 0
)
select d.dealno, d.asset, d.dealdate, d.dealtype, d.clientno, d.qty, d.sharesout, d.price, d.consideration, d.CertDueBy as duedate
from deals d inner join clients c on d.clientno = c.clientno







GO
/****** Object:  View [dbo].[vwScripInOffice]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [dbo].[vwScripInOffice]
as
with scrip as (select datein, ledgerid, clientno from SCRIPSAFE where CLIENTNO <> '0' and CLOSED = 0 and (dateout is null))
select l.asset, l.certno, l.qty, s.datein, s.clientno, coalesce(c.companyname, c.surname+'  '+c.firstname) as client,
case l.reason
when 'FORSALE' then 'PENDING SALE'
when 'FOR SALE' then 'PENDING SALE'
when 'PENDING SALE' then 'PENDING SALE'
when 'SAFECUSTODY' then 'SAFE CUSTODY'
when 'SAFE CUSTODY' then 'SAFE CUSTODY'
when 'TRANSFERRED' then 'FROM T/SEC'
when 'FAVOUR' then 'FAVOUR REGISTRATION'
end as pool,
l.regholder
from scrip s inner join scripledger l on s.LEDGERID = l.ID
inner join clients c on s.CLIENTNO = c.CLIENTNO
where s.CLIENTNO not in (select CLIENTNO from clients where ((CATEGORY = 'BROKER') or (CATEGORY like 'NMI%')))






GO
/****** Object:  View [dbo].[vwSettlementDeals]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[vwSettlementDeals]
as
select d.dealdate, d.dealno, d.qty, d.asset, d.price, d.consideration, coalesce(c.companyname, c.surname+' '+c.firstname) as client,
(isnull(d.vat,0)+isnull(d.investorprotection,0)+isnull(d.csdlevy,0)) as settleamount
from dealallocations d inner join clients c on d.clientno = c.clientno
and d.approved = 1 and d.cancelled = 0 and d.merged = 0
and d.dealtype = 'SELL'

GO
/****** Object:  View [dbo].[vwUserProfiles]    Script Date: 2020/12/07 11:43:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vwUserProfiles]
AS
SELECT     dbo.PERMISSIONS.PROFILE, dbo.SCREENS.NAME, dbo.MODULES.MODNAME
FROM         dbo.PERMISSIONS INNER JOIN
                      dbo.SCREENS ON dbo.PERMISSIONS.SCREEN = dbo.SCREENS.ID INNER JOIN
                      dbo.MODULES ON dbo.SCREENS.MOD = dbo.MODULES.MID





GO
ALTER TABLE [dbo].[ASSETS] ADD  CONSTRAINT [DF__ASSETS__shares__735BD47E]  DEFAULT ((0)) FOR [shares]
GO
ALTER TABLE [dbo].[BALANCES] ADD  CONSTRAINT [DF_BALANCES_ACC]  DEFAULT (0) FOR [ACC]
GO
ALTER TABLE [dbo].[BANKS] ADD  DEFAULT ((0)) FOR [Audit]
GO
ALTER TABLE [dbo].[BonusIssues] ADD  DEFAULT ((0)) FOR [PROCESSED]
GO
ALTER TABLE [dbo].[BonusIssues] ADD  DEFAULT ((0)) FOR [APPROVED]
GO
ALTER TABLE [dbo].[BonusIssues] ADD  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF__BusinessR__Share__41055EDB]  DEFAULT ((0)) FOR [Sharejobalert]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF__BusinessR__tbale__41F98314]  DEFAULT ((0)) FOR [tbalert]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF_BusinessRules_ExRateAlert]  DEFAULT ((0)) FOR [ExRateAlert]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF_BusinessRules_PassLength]  DEFAULT ((8)) FOR [PassLength]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF_BusinessRules_PassHistory]  DEFAULT ((6)) FOR [PassHistory]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF_BusinessRules_PassSimilarity]  DEFAULT ((1)) FOR [PassSimilarity]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF_BusinessRules_LogAttempts]  DEFAULT ((3)) FOR [LogAttempts]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF_BusinessRules_UseSecretQuestions]  DEFAULT ((0)) FOR [UseSecretQuestions]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  CONSTRAINT [DF__BusinessR__Multi__744FF8B7]  DEFAULT ((1)) FOR [MultipleLogins]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  DEFAULT ((0)) FOR [CSDTxnOnSettlement]
GO
ALTER TABLE [dbo].[BusinessRules] ADD  DEFAULT ((0)) FOR [ApprovePayments]
GO
ALTER TABLE [dbo].[CASHBOOKTRANS] ADD  CONSTRAINT [DF__CASHBOOKTRA__YON__3AE27131]  DEFAULT ((1)) FOR [YON]
GO
ALTER TABLE [dbo].[CLIENTCATEGORY] ADD  DEFAULT ((0)) FOR [CSDLevy]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_TYPE]  DEFAULT ((0)) FOR [TYPE]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_CATEGORY]  DEFAULT ((0)) FOR [CATEGORY]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_NOMINEECO]  DEFAULT ((0)) FOR [NOMINEECO]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_UsePhysicalAddress]  DEFAULT ((1)) FOR [UsePhysicalAddress]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_BUYSETTLE]  DEFAULT ((0)) FOR [BUYSETTLE]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_SELLSETTLE]  DEFAULT ((0)) FOR [SELLSETTLE]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_ORDERVALIDITY]  DEFAULT ((7)) FOR [ORDERVALIDITY]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_DELIVERYOPTION]  DEFAULT ((0)) FOR [DELIVERYOPTION]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_SENDPRICES]  DEFAULT ((0)) FOR [SENDPRICES]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_SENDDEALS]  DEFAULT ((0)) FOR [SENDDEALS]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  CONSTRAINT [DF_CLIENTS_OnlineSubscribed]  DEFAULT ((0)) FOR [OnlineSubscribed]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  DEFAULT ((0)) FOR [NomineeAccount]
GO
ALTER TABLE [dbo].[CLIENTS] ADD  DEFAULT ((1)) FOR [Custodial]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_SMSDeals]  DEFAULT ((0)) FOR [SMSDeals]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_SMSScrip]  DEFAULT ((0)) FOR [SMSScrip]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_SMSCorpAction]  DEFAULT ((0)) FOR [SMSCorpAction]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_SMSPrices]  DEFAULT ((0)) FOR [SMSPrices]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_SMSOther]  DEFAULT ((0)) FOR [SMSOther]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_EmailDeals]  DEFAULT ((0)) FOR [EmailDeals]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_EmailScrip]  DEFAULT ((0)) FOR [EmailScrip]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_EmailCorpAction]  DEFAULT ((0)) FOR [EmailCorpAction]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_EmailPrices]  DEFAULT ((0)) FOR [EmailPrices]
GO
ALTER TABLE [dbo].[ClientsCommunication] ADD  CONSTRAINT [DF_ClientsCommunication_EmailOther]  DEFAULT ((0)) FOR [EmailOther]
GO
ALTER TABLE [dbo].[CONSOLIDATIONDEALS] ADD  CONSTRAINT [DF_CONSOLIDATIONDEALS_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[CONSOLIDATIONS] ADD  CONSTRAINT [DF_CONSOLIDATIONS_PROCESSED]  DEFAULT ((0)) FOR [PROCESSED]
GO
ALTER TABLE [dbo].[CONSOLIDATIONS] ADD  CONSTRAINT [DF_CONSOLIDATIONS_APPROVED]  DEFAULT ((0)) FOR [APPROVED]
GO
ALTER TABLE [dbo].[CONSOLIDATIONS] ADD  CONSTRAINT [DF_CONSOLIDATION_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[dealallocations] ADD  DEFAULT ((0)) FOR [Bookover]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF_DEALALLOCATIONS_CANCELLED]  DEFAULT ((0)) FOR [Cancelled]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF_DEALALLOCATIONS_MERGED]  DEFAULT ((0)) FOR [MERGED]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF_DEALALLOCATIONS_CONSOLIDATED]  DEFAULT ((0)) FOR [CONSOLIDATED]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF__DEALALLOCAT__YON__3CCAB9A3]  DEFAULT ((1)) FOR [YON]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF__DEALALLOC__SMSSe__0BC85AEC]  DEFAULT ((0)) FOR [SMSSent]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF__DEALALLOC__CSDLe__2B410645]  DEFAULT ((0)) FOR [CSDLevy]
GO
ALTER TABLE [dbo].[DEALALLOCATIONS_OG] ADD  CONSTRAINT [DF__DEALALLOC__CSDSe__41304764]  DEFAULT ((0)) FOR [CSDSettled]
GO
ALTER TABLE [dbo].[LedgerAccount] ADD  CONSTRAINT [DF_LedgerAccount_isActive]  DEFAULT ((1)) FOR [isActive]
GO
ALTER TABLE [dbo].[MACHINES] ADD  CONSTRAINT [DF_MACHINES_Updated]  DEFAULT ((0)) FOR [Updated]
GO
ALTER TABLE [dbo].[PRICES] ADD  DEFAULT ((0)) FOR [uploaded]
GO
ALTER TABLE [dbo].[pricestemp] ADD  CONSTRAINT [DF_pricestemp_Bid]  DEFAULT ((0)) FOR [Bid]
GO
ALTER TABLE [dbo].[pricestemp] ADD  CONSTRAINT [DF_pricestemp_Offer]  DEFAULT ((0)) FOR [Offer]
GO
ALTER TABLE [dbo].[pricestemp] ADD  CONSTRAINT [DF_pricestemp_Sales]  DEFAULT ((0)) FOR [Sales]
GO
ALTER TABLE [dbo].[pricestemp] ADD  CONSTRAINT [DF_pricestemp_Volume]  DEFAULT ((0)) FOR [Volume]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF_REQUISITIONS_APPROVED]  DEFAULT ((0)) FOR [APPROVED]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF_REQUISITIONS_CANCELLED]  DEFAULT ((0)) FOR [Cancelled]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF_REQUISITIONS_ISRECEIPT]  DEFAULT ((0)) FOR [ISRECEIPT]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF_REQUISITIONS_TRANSCODE]  DEFAULT ('PAY') FOR [TRANSCODE]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF_REQUISITIONS_CashBookID]  DEFAULT ((2)) FOR [CashBookID]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF__REQUISITI__Cashf__15B0EC82]  DEFAULT ((0)) FOR [CashflowReq]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF__REQUISITI__Amalg__16A510BB]  DEFAULT ((0)) FOR [AmalgamationID]
GO
ALTER TABLE [dbo].[REQUISITIONS] ADD  CONSTRAINT [DF__REQUISITION__YON__3DBEDDDC]  DEFAULT ((1)) FOR [YON]
GO
ALTER TABLE [dbo].[RIGHTSOFFERDEALSALLOC] ADD  CONSTRAINT [DF_RIGHTSOFFERDEALSALLOC_CANCELLED]  DEFAULT (0) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[RIGHTSOFFERS] ADD  CONSTRAINT [DF_RIGHTSOFFERS_PROCESSED]  DEFAULT (0) FOR [PROCESSED]
GO
ALTER TABLE [dbo].[RIGHTSOFFERS] ADD  CONSTRAINT [DF_RIGHTSOFFERS_APPROVED]  DEFAULT (0) FOR [APPROVED]
GO
ALTER TABLE [dbo].[RIGHTSOFFERS] ADD  CONSTRAINT [DF_RIGHTSOFFERS_CANCELLED]  DEFAULT (0) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[RIGHTSOFFERSCRIPALLOC] ADD  CONSTRAINT [DF_RIGHTSOFFERSCRIPALLOC_CANCELLED]  DEFAULT (0) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[SCRIPDEALSCERTS] ADD  CONSTRAINT [DF_SCRIPDEALSCERTS_REVERSETEMP]  DEFAULT ((0)) FOR [REVERSETEMP]
GO
ALTER TABLE [dbo].[SCRIPDEALSCERTS] ADD  CONSTRAINT [DF_SCRIPDEALSCERTS_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[SCRIPDEALSCERTS] ADD  CONSTRAINT [DF_SCRIPDEALSCERTS_QTYUSED]  DEFAULT ((0)) FOR [QTYUSED]
GO
ALTER TABLE [dbo].[SCRIPDEALSCONTRA] ADD  CONSTRAINT [DF_SCRIPDEALSCONTRA_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[SCRIPDEALSCONTRA] ADD  CONSTRAINT [DF_SCRIPDEALSCONTRA_QTYUSED]  DEFAULT ((0)) FOR [QTYUSED]
GO
ALTER TABLE [dbo].[SCRIPLEDGER] ADD  CONSTRAINT [DF_SCRIPLEDGER_CLOSED]  DEFAULT ((0)) FOR [CLOSED]
GO
ALTER TABLE [dbo].[SCRIPLEDGER] ADD  CONSTRAINT [DF_SCRIPLEDGER_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[SCRIPLEDGER] ADD  CONSTRAINT [DF_SCRIPLEDGER_SHAPEID]  DEFAULT ((0)) FOR [SHAPEID]
GO
ALTER TABLE [dbo].[SCRIPLEDGER] ADD  CONSTRAINT [DF_SCRIPLEDGER_INCOMINID]  DEFAULT ((0)) FOR [INCOMINGID]
GO
ALTER TABLE [dbo].[SCRIPSAFE] ADD  CONSTRAINT [DF_SCRIPSAFE_NOMINEE]  DEFAULT ((0)) FOR [NOMINEE]
GO
ALTER TABLE [dbo].[SCRIPSAFE] ADD  CONSTRAINT [DF_SCRIPSAFE_CLOSED]  DEFAULT ((0)) FOR [CLOSED]
GO
ALTER TABLE [dbo].[SCRIPSHAPE] ADD  CONSTRAINT [DF_SCRIPSHAPE_CD]  DEFAULT ((0)) FOR [CD]
GO
ALTER TABLE [dbo].[SCRIPSHAPE] ADD  CONSTRAINT [DF_SCRIPSHAPE_CLOSED]  DEFAULT ((0)) FOR [CLOSED]
GO
ALTER TABLE [dbo].[SCRIPTRANSFER] ADD  CONSTRAINT [DF_SCRIPTRANSFER_SENT]  DEFAULT ((0)) FOR [SENT]
GO
ALTER TABLE [dbo].[SCRIPTRANSFER] ADD  CONSTRAINT [DF_SCRIPTRANSFER_CLOSED]  DEFAULT ((0)) FOR [CLOSED]
GO
ALTER TABLE [dbo].[SCRIPTRANSFER] ADD  CONSTRAINT [DF_SCRIPTRANSFER_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[StatementsReport] ADD  DEFAULT ((0)) FOR [qty]
GO
ALTER TABLE [dbo].[StatementsReport] ADD  DEFAULT ((0)) FOR [price]
GO
ALTER TABLE [dbo].[tblBalancePositionsSettlements] ADD  DEFAULT ((0)) FOR [cancelled]
GO
ALTER TABLE [dbo].[tblBrokerDeliveries] ADD  DEFAULT (0) FOR [DealQty]
GO
ALTER TABLE [dbo].[tblBrokerDeliveries] ADD  DEFAULT (0) FOR [QtyUsed]
GO
ALTER TABLE [dbo].[tblBrokerNMIUnmatchedTXNs] ADD  CONSTRAINT [DF_tblBrokerNMIUnmatchedTXNs_price]  DEFAULT ((0)) FOR [price]
GO
ALTER TABLE [dbo].[tblBrokerNMIUnmatchedTXNs] ADD  CONSTRAINT [DF_tblBrokerNMIUnmatchedTXNs_consfrom]  DEFAULT ((0)) FOR [consfrom]
GO
ALTER TABLE [dbo].[tblBrokerNMIUnmatchedTXNs] ADD  CONSTRAINT [DF_tblBrokerNMIUnmatchedTXNs_consto]  DEFAULT ((0)) FOR [consto]
GO
ALTER TABLE [dbo].[tblBrokerNMIUnmatchedTXNs] ADD  CONSTRAINT [DF_tblBrokerNMIUnmatchedTXNs_sharesfrom]  DEFAULT ((0)) FOR [sharesfrom]
GO
ALTER TABLE [dbo].[tblBrokerNMIUnmatchedTXNs] ADD  CONSTRAINT [DF_tblBrokerNMIUnmatchedTXNs_sharesto]  DEFAULT ((0)) FOR [sharesto]
GO
ALTER TABLE [dbo].[tblBuySettlementDeals] ADD  CONSTRAINT [DF__tblBuySet__NetCo__19D5B7CA]  DEFAULT ((0)) FOR [NetConsideration]
GO
ALTER TABLE [dbo].[tblClientBuySettlementDeals] ADD  CONSTRAINT [DF_tblClientBuySettlementDeals_qty]  DEFAULT (0) FOR [qty]
GO
ALTER TABLE [dbo].[tblClientBuySettlementDeals] ADD  CONSTRAINT [DF_tblClientBuySettlementDeals_price]  DEFAULT (0) FOR [price]
GO
ALTER TABLE [dbo].[tblClientBuySettlementDeals] ADD  CONSTRAINT [DF_tblClientBuySettlementDeals_consideration]  DEFAULT (0) FOR [consideration]
GO
ALTER TABLE [dbo].[tblConsolidationCustody] ADD  CONSTRAINT [DF__tblConsol__Cance__62F0628B]  DEFAULT ((0)) FOR [Cancelled]
GO
ALTER TABLE [dbo].[tblConsolidationTransfers] ADD  DEFAULT ((0)) FOR [Cancelled]
GO
ALTER TABLE [dbo].[tblConsolidationUnallocated] ADD  CONSTRAINT [DF__tblConsol__Cance__64D8AAFD]  DEFAULT ((0)) FOR [Cancelled]
GO
ALTER TABLE [dbo].[tblCSDSettlementDetails] ADD  CONSTRAINT [DF_tblCSDSettlementDetails_qtyused]  DEFAULT ((0)) FOR [qtyused]
GO
ALTER TABLE [dbo].[tblCSDSettlementDetails] ADD  CONSTRAINT [DF_tblCSDSettlementDetails_cancelled]  DEFAULT ((0)) FOR [cancelled]
GO
ALTER TABLE [dbo].[tblDealBalanceCertificates] ADD  CONSTRAINT [DF__tblDealBa__Close__4159993F]  DEFAULT ((0)) FOR [Closed]
GO
ALTER TABLE [dbo].[tblDealBalanceCertificates] ADD  CONSTRAINT [DF__tblDealBa__BalRe__63AEB143]  DEFAULT ((0)) FOR [BalRemaining]
GO
ALTER TABLE [dbo].[tblDealBalanceCertificates] ADD  CONSTRAINT [DF__tblDealBa__Cance__79E8D67C]  DEFAULT ((0)) FOR [Cancelled]
GO
ALTER TABLE [dbo].[tblDetailedPortfolioDeliveries] ADD  CONSTRAINT [DF__tblDetail__incom__452AF57A]  DEFAULT ((0)) FOR [incoming]
GO
ALTER TABLE [dbo].[tblDetailedPortfolioDeliveries] ADD  DEFAULT ((0)) FOR [deal]
GO
ALTER TABLE [dbo].[tblFavourPositionSettlements] ADD  CONSTRAINT [DF_tblFavourPositionSettlements_CANCELLED]  DEFAULT ((0)) FOR [CANCELLED]
GO
ALTER TABLE [dbo].[tblPendingSaleInto] ADD  CONSTRAINT [DF__tblPendin__dealq__6458BCB9]  DEFAULT (0) FOR [dealqty]
GO
ALTER TABLE [dbo].[tblPendingSaleInto] ADD  CONSTRAINT [DF__tblPendin__qtyus__654CE0F2]  DEFAULT (0) FOR [qtyused]
GO
ALTER TABLE [dbo].[tblScreens] ADD  DEFAULT ((0)) FOR [moduleid]
GO
ALTER TABLE [dbo].[tblScripBalancing] ADD  CONSTRAINT [DF_tblScripBalancing_bought]  DEFAULT ((0)) FOR [bought]
GO
ALTER TABLE [dbo].[tblScripBalancing] ADD  CONSTRAINT [DF_tblScripBalancing_sold]  DEFAULT ((0)) FOR [sold]
GO
ALTER TABLE [dbo].[tblScripBalancing] ADD  CONSTRAINT [DF_tblScripBalancing_dueto]  DEFAULT ((0)) FOR [dueto]
GO
ALTER TABLE [dbo].[tblScripBalancing] ADD  CONSTRAINT [DF_tblScripBalancing_unallocated]  DEFAULT ((0)) FOR [unallocated]
GO
ALTER TABLE [dbo].[tblScripBalancing] ADD  CONSTRAINT [DF_tblScripBalancing_transfersec]  DEFAULT ((0)) FOR [transfersec]
GO
ALTER TABLE [dbo].[tblScripBalancing] ADD  CONSTRAINT [DF_tblScripBalancing_balancecertificates]  DEFAULT ((0)) FOR [balancecertificates]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF_tblSystemParams_ApproveReceipts]  DEFAULT ((0)) FOR [ApproveReceipts]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF_tblSystemParams_PartSettlement]  DEFAULT ((0)) FOR [PartSettlement]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF_tblSystemParams_VerifyScrip]  DEFAULT ((0)) FOR [VerifyScrip]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF_tblSystemParams_FinancialPeriodOnly]  DEFAULT ((0)) FOR [FinancialPeriodOnly]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF_tblSystemParams_SeparateBrokerDeals]  DEFAULT ((0)) FOR [SeperateBrokerDeals]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__LockS__69FC8776]  DEFAULT ((0)) FOR [LockScrip4BDeals]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Print__6AF0ABAF]  DEFAULT ((0)) FOR [PrintSettlementLetter]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF_tblSystemParams_PrintSettlementSafeCustody]  DEFAULT ((1)) FOR [PrintSettlementSafeCustody]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Balan__2CA96073]  DEFAULT ((1)) FOR [BalanceCertificates]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Deliv__6D82FF97]  DEFAULT ((0)) FOR [DeliverScripOnBuySettlement]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Print__6E7723D0]  DEFAULT ((1)) FOR [PrintBrokerInDelivery]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__PartS__0FA30D71]  DEFAULT ((0)) FOR [PartSettlementBrokerDeals]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__PartS__1467C28E]  DEFAULT ((0)) FOR [PartSettleBrokerDeals]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Print__788A9DEF]  DEFAULT ((1)) FOR [PrintClientScripReceipt]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Print__797EC228]  DEFAULT ((1)) FOR [PrintTransLetter]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__SafeC__387018DA]  DEFAULT ((0)) FOR [SafeCustodyOutLetter]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Apple__3F1D1669]  DEFAULT ((0)) FOR [Applength]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Thres__40113AA2]  DEFAULT ((0)) FOR [Threshhold]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__creat__71738C0C]  DEFAULT ((1)) FOR [createbrokerbalanceposition]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Cashf__5284F098]  DEFAULT ((0)) FOR [CashflowRecreq]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystemPa__CRC__249408B6]  DEFAULT ((10)) FOR [CRC]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  CONSTRAINT [DF__tblSystem__Captu__55374011]  DEFAULT ((0)) FOR [CaptureCSDNo]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  DEFAULT ('0') FOR [ControlAccount]
GO
ALTER TABLE [dbo].[tblSystemParams] ADD  DEFAULT ((0)) FOR [CDCSettlementAccount]
GO
ALTER TABLE [dbo].[tblTempDeliveryNote] ADD  DEFAULT ((0)) FOR [qty]
GO
ALTER TABLE [dbo].[tblTopTraders] ADD  CONSTRAINT [DF_tblTopTraders_Cnt]  DEFAULT (0) FOR [Cnt]
GO
ALTER TABLE [dbo].[TRADINGSUMMARY] ADD  CONSTRAINT [DF__TRADINGSU__Broug__4337C010]  DEFAULT ((0)) FOR [BroughtIn]
GO
ALTER TABLE [dbo].[TRADINGSUMMARY] ADD  CONSTRAINT [DF__TRADINGSU__Taken__442BE449]  DEFAULT ((0)) FOR [TakenOut]
GO
ALTER TABLE [dbo].[TRANSACTIONS] ADD  CONSTRAINT [DF_TRANSACTIONS_Amount]  DEFAULT ((0)) FOR [Amount]
GO
ALTER TABLE [dbo].[TRANSACTIONS] ADD  CONSTRAINT [DF__TRANSACTION__YON__3BD6956A]  DEFAULT ((1)) FOR [YON]
GO
ALTER TABLE [dbo].[TrialBalanceFinal] ADD  CONSTRAINT [DF_TRIALBALANCEFINAL_DEBITBAL]  DEFAULT (0) FOR [DEBITBAL]
GO
ALTER TABLE [dbo].[TrialBalanceFinal] ADD  CONSTRAINT [DF_TRIALBALANCEFINAL_CREDITBAL]  DEFAULT (0) FOR [CREDITBAL]
GO
ALTER TABLE [dbo].[TrialBalancePrepare1] ADD  CONSTRAINT [DF_TRIALBALANCEPREPARE2_BAL]  DEFAULT ((0)) FOR [BAL]
GO
ALTER TABLE [dbo].[TrialBalancePrepare2] ADD  CONSTRAINT [DF_TRIALBALANCEPREPARE2_DEBITBAL]  DEFAULT ((0)) FOR [DEBTORS]
GO
ALTER TABLE [dbo].[TrialBalancePrepare2] ADD  CONSTRAINT [DF_TRIALBALANCEPREPARE2_CREDITBAL]  DEFAULT ((0)) FOR [CREDITORS]
GO
ALTER TABLE [dbo].[USERS] ADD  CONSTRAINT [DF_USERS_SYSTEMAINT]  DEFAULT ((0)) FOR [SYSTEMAINT]
GO
ALTER TABLE [dbo].[ZCashBookTrans] ADD  CONSTRAINT [DF_ZCashBookTrans_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZCashBookTrans] ADD  CONSTRAINT [DF_ZCashBookTrans_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZCashBookTrans] ADD  CONSTRAINT [DF_ZCashBookTrans_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZClientCategory] ADD  CONSTRAINT [DF_ZClientCategory_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZClientCategory] ADD  CONSTRAINT [DF_ZClientCategory_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZClientCategory] ADD  CONSTRAINT [DF_ZClientCategory_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZClients] ADD  CONSTRAINT [DF_ZClients_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZClients] ADD  CONSTRAINT [DF_ZClients_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZClients] ADD  CONSTRAINT [DF_ZClients_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZDealallocations] ADD  CONSTRAINT [DF_ZDealallocations_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZDealallocations] ADD  CONSTRAINT [DF_ZDealallocations_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZDealallocations] ADD  CONSTRAINT [DF_ZDealallocations_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZDockets] ADD  CONSTRAINT [DF_ZDockets_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZDockets] ADD  CONSTRAINT [DF_ZDockets_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZDockets] ADD  CONSTRAINT [DF_ZDockets_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZOrders] ADD  CONSTRAINT [DF_ZOrders_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZOrders] ADD  CONSTRAINT [DF_ZOrders_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZOrders] ADD  CONSTRAINT [DF_ZOrders_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZRequisitions] ADD  CONSTRAINT [DF_ZRequisitions_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZRequisitions] ADD  CONSTRAINT [DF_ZRequisitions_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZRequisitions] ADD  CONSTRAINT [DF_ZRequisitions_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZScripdeliveries] ADD  CONSTRAINT [DF_ZScripdeliveries_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZScripdeliveries] ADD  CONSTRAINT [DF_ZScripdeliveries_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZScripdeliveries] ADD  CONSTRAINT [DF_ZScripdeliveries_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZScripledger] ADD  CONSTRAINT [DF_ZScripledger_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZScripledger] ADD  CONSTRAINT [DF_ZScripledger_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZScripledger] ADD  CONSTRAINT [DF_ZScripledger_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZScripsafe] ADD  CONSTRAINT [DF_ZScripsafe_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZScripsafe] ADD  CONSTRAINT [DF_ZScripsafe_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZScripsafe] ADD  CONSTRAINT [DF_ZScripsafe_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZtblDealBalanceCertificates] ADD  CONSTRAINT [DF_ZtblDealBalanceCertificates_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZtblDealBalanceCertificates] ADD  CONSTRAINT [DF_ZtblDealBalanceCertificates_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZtblDealBalanceCertificates] ADD  CONSTRAINT [DF_ZtblDealBalanceCertificates_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZTransactions] ADD  CONSTRAINT [DF_ZTransactions_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZTransactions] ADD  CONSTRAINT [DF_ZTransactions_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZTransactions] ADD  CONSTRAINT [DF_ZTransactions_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[ZUsers] ADD  CONSTRAINT [DF_ZUsers_AuditDate]  DEFAULT (getdate()) FOR [AuditDate]
GO
ALTER TABLE [dbo].[ZUsers] ADD  CONSTRAINT [DF_ZUsers_AuditUser]  DEFAULT (suser_sname()) FOR [AuditUser]
GO
ALTER TABLE [dbo].[ZUsers] ADD  CONSTRAINT [DF_ZUsers_AuditApp]  DEFAULT (('App=('+rtrim(isnull(app_name(),'')))+') ') FOR [AuditApp]
GO
ALTER TABLE [dbo].[Menus]  WITH CHECK ADD FOREIGN KEY([ParentID])
REFERENCES [dbo].[Menus] ([ID])
GO
ALTER TABLE [dbo].[SCREENS]  WITH NOCHECK ADD  CONSTRAINT [FK_SCREENS_MODULES] FOREIGN KEY([MOD])
REFERENCES [dbo].[MODULES] ([MID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SCREENS] CHECK CONSTRAINT [FK_SCREENS_MODULES]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PERMISSIONS"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 229
               Right = 190
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SCREENS"
            Begin Extent = 
               Top = 6
               Left = 228
               Bottom = 187
               Right = 380
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "MODULES"
            Begin Extent = 
               Top = 3
               Left = 495
               Bottom = 122
               Right = 647
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 4620
         Width = 3765
         Width = 1500
         Width = 2130
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwUserProfiles'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vwUserProfiles'
GO
