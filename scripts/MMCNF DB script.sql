USE [master]
GO
/****** Object:  Database [MMCNF]    Script Date: 2019-04-11 04:33:10 PM ******/
CREATE DATABASE [MMCNF]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Falcon_dat', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\MMCNF.mdf' , SIZE = 997888KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 LOG ON 
( NAME = N'Falcon_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\MMCNF.ldf' , SIZE = 175744KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
GO
ALTER DATABASE [MMCNF] SET COMPATIBILITY_LEVEL = 90
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MMCNF].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [MMCNF] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MMCNF] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MMCNF] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MMCNF] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MMCNF] SET ARITHABORT OFF 
GO
ALTER DATABASE [MMCNF] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [MMCNF] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [MMCNF] SET AUTO_SHRINK ON 
GO
ALTER DATABASE [MMCNF] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MMCNF] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [MMCNF] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MMCNF] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MMCNF] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MMCNF] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MMCNF] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MMCNF] SET  DISABLE_BROKER 
GO
ALTER DATABASE [MMCNF] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [MMCNF] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MMCNF] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MMCNF] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MMCNF] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MMCNF] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MMCNF] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MMCNF] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [MMCNF] SET  MULTI_USER 
GO
ALTER DATABASE [MMCNF] SET PAGE_VERIFY TORN_PAGE_DETECTION  
GO
ALTER DATABASE [MMCNF] SET DB_CHAINING OFF 
GO
ALTER DATABASE [MMCNF] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [MMCNF] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'MMCNF', N'ON'
GO
USE [MMCNF]
GO
/****** Object:  User [FalconUser]    Script Date: 2019-04-11 04:33:11 PM ******/
CREATE USER [FalconUser] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[FalconUser]
GO
/****** Object:  User [FalconClient]    Script Date: 2019-04-11 04:33:11 PM ******/
CREATE USER [FalconClient] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[FalconClient]
GO
ALTER ROLE [db_datareader] ADD MEMBER [FalconUser]
GO
ALTER ROLE [db_owner] ADD MEMBER [FalconClient]
GO
/****** Object:  Schema [FalconClient]    Script Date: 2019-04-11 04:33:11 PM ******/
CREATE SCHEMA [FalconClient]
GO
/****** Object:  Schema [FalconUser]    Script Date: 2019-04-11 04:33:11 PM ******/
CREATE SCHEMA [FalconUser]
GO
/****** Object:  StoredProcedure [dbo].[AccountLedgerAdd]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AccountLedgersFinish]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AccountLedgersPrepare]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalance]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalanceDaily]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalancePeriod]    Script Date: 2019-04-11 04:33:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE               PROCEDURE [dbo].[AccountsTrialBalancePeriod]
 ( 
	@EndDate	datetime )--  [AccountsTrialBalancePeriod] '20101207'
AS
declare @bal decimal(31,9),  @tempbal decimal(31,9),@cr decimal(31,9), @dr decimal(31,9), @drclient decimal(31,9), @crclient decimal(31,9), @crbroker decimal(31,9), @drbroker decimal(31,9),@txnbal decimal(31,9),@NMIRebate decimal(31,9)
--declare @OldCommLvAcc int, @zseclientno int, @taxclientno int,@EndDate1 
declare  @StartYear datetime

delete from TrialBalancePrepare1
delete from TrialBalancePrepare2
delete from TrialBalancePrepare3

delete from TrialBalanceFinal
--select @EndDate1=DATEADD(d,1,@EndDate)
select @StartYear= cast(DATEPART(YY,@EndDate) as varchar(50))+'0101'

--select @OldCommLvAcc = commissioneraccount, @zseclientno = zseclientno, @taxclientno = taxclientno from systemparams

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
--insert into TrialBalanceFinal (clientno,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '190',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'br%'
insert into TrialBalanceFinal (ClientNo,account,debitbal,creditbal,[group]) select '191',cat, debtors, creditors, 'TRADE DEBTORS & CREDITORS' from TrialBalancePrepare2 where cat like 'cl%'

--update transactions set consideration = 199.39 where transid = 215058
-- bank balance
select @cr = 0
select @dr = 0
select @bal = sum(-amount) from CASHBOOKTRANS where yon=1 and (transdate <= @EndDate) and (transcode  like 'PAY%' or (transcode like 'REC%') ) -- (+ve means debit balance)
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
	
	--select @dr = @dr + 3274.5
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

-- CSD LEVY ADDED 18 JULY 2014
select @cr = 0
select @dr = 0
select @bal = sum(amount) from transactions where (transdate <= @EndDate) and ((transcode like 'CSDLV') or (transcode like 'CSDLVCNL') or (transcode like 'CSDLVD%')) and YON=1 --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
if @bal is null
	select @bal = 0
select @tempbal = sum(amount) from CASHBOOKTRANS where  (transdate <= @EndDate) and (transcode like 'CSDLVD%') --and transdate >= '2009-05-13' --and clientno <> @OldCommLvAcc
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
	--if @enddate < '20181212'
		--select @dr = @dr - 3274.55

		--if @enddate >= '20181212'
		--select @dr = @dr + 549.06
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

	if @enddate >= '20181212'
		select @cr = @cr - 150.2
insert into TrialBalanceFinal (ClientNo,ACCOUNT,debitbal,creditbal,[group]) values ('200','RTGS PAYMENT FEES', @dr, @cr, 'NON-TRADING ACTIVITIES')

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
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalancePeriodDP]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AccountsTrialBalancePeriodNEW1]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ActiveAccountsClients]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ActiveClients]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ActiveClientsOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AdjustCashBal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[Age_AmountsClient]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[Age_AmountsClientOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AgingClients]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AgingClientsPD]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AllClients]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AllNMIRebates]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AllocatedDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ApprovePayments]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ApproveReceipts]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ArchiveAudit]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AssetPrices]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AutoMatchPayments]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[AutoMatchReceipts]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[BackDatedEntries]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[BalancesOnly]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[BalancesOnlyOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[BalancesOnlyPD]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CancelBrokerDeal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CancelJournal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CancelRebate]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ChangeZSEOrderNo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CheckAccess]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CheckShareJobbing]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ClientPortfolio]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ClientsBasicInfo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ConfirmBrokerDeal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CreditorsAging]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CreditorsAgingOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[CreditorsAgingPD]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealCharges]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealChargesTransact]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealsDue]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealsReconciliation]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealsReconciliationEx]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealsReconciliationExScripBal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DealTransact]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DebtorsAging]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DebtorsAgingOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[DebtorsAgingPD]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[FixArrearsMulti]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[FixArrearsSingle]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[FixCashBal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[FixCashBalSingle]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GenerateAudittrail]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetAssetDetails]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetBrokerDetails]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetCashBal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientDeliveryInfo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientName]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientNo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientOrders]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientRates]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientRegInfo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientTransactions]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientUnPaidDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetClientUnreceiptedDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetCorpActionDetails]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetDealNo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetNextLedgerRef]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetNextTransferRef]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetNomineeCo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetOrderDetails]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetServerInfo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetTransferSec]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetTSecDetails]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[GetUpdate]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc1]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc2]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc3]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc4]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc5]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc6]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc7]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[IndexProc8]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ListMultiDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ListShareJobbing]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ListShareJobbingEx]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[Login]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[LoginOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[Logout]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[Match]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[MergeDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ModifyPrice]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ModifyPriceInternal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[NewClient]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PayRec]    Script Date: 2019-04-11 04:33:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE           PROCEDURE [dbo].[PayRec]	(
	@User			varchar(20)=NULL,
	@ClientNo		varchar(50),
	@DealNo			varchar(40),
	@TransCode		varchar(50)=NULL,
	@TransDate		datetime2(7),
	@Description	varchar(50) = NULL,
	@Amount			decimal(31, 9)=0,
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
    @MatchID		bigint=0
    
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
	if(@IsCredit<>1)
		select @origtransid=transid from CASHBOOKTRANS where ChqRqID=@ChqRqID
	insert into CASHBOOKTRANS
	([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],[TransDate],[REFNO],[DESCRIPTION],[AMOUNT],[CASH],BANK,BANKBR,CHQNO,DRAWER,ARREARSBF,ARREARSCF,CASHBOOKID,Cancelled, ChqRqID,ExCurrency,ExRate,ExAmount,MatchID,ORIGINALTRANSID)
	values
	(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@NewTransDate,@RefNo,@Description,@Amount1,@Cash,@Bank,@BankBranch,@ChequeNo,@Drawer,@BF,@CF,@CashBookID,0,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID,@origtransid)

	update requisitions set approved=1 where reqid=@ChqRqID
	--new matching for aging
	select top 1 @Mid=Transid, @CID=chqrqid from CASHBOOKTRANS where [login]=@User order by TRANSID desc
	update CASHBOOKTRANS set MID=@MID where TRANSID=@MID
	update DEALALLOCATIONS set MID=@MID where CHQRQID=@CID
	
	exec TrackClientStatus @ClientNo
commit
GO
/****** Object:  StoredProcedure [dbo].[Ping]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateJournals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateLedger]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateLedgerOLD]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateRebates]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReport]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReportMulti]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReportOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateStatementsReportPD]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PopulateTBItemised]    Script Date: 2019-04-11 04:33:11 PM ******/
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
	
	--select @CB = @CB+sum(amount) from CASHBOOKTRANS
	--where TransDate < @StartDate and TransDate<@EndDate
	
    insert into TBItemised select *,@OB,@CB from TBItemisedTemp where clientno=@clientno order by TransDate
END

GO
/****** Object:  StoredProcedure [dbo].[PostPay]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PostPayOld]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PostRec]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PrepareTurnOver]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PrintAllReceipts]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PrintAllRequisitions]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ReadAudit]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ReadIndices]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[RequisitionPayRec]    Script Date: 2019-04-11 04:33:11 PM ******/
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
    --@Transid		int = 0,
    @ExCurrency		varchar(50)=NULL,
    @ExRate			float=0,
    @ExAmount		float=0,
    @MatchID		bigint=0
    
				) 
AS


declare @BF decimal(38,4), @CF decimal(38,4), @NewTransDate datetime2(7)
declare @IsCredit bit
declare @Amount1 decimal(38,4)
declare @Amount2 decimal(38,4)
declare @Factor numeric

select @Amount1 = @Amount

select @BF = 0, @CF = 0


select @IsCredit = Credit from TRANSTYPES where TRANSTYPE = @TransCode
if @@ERROR <> 0 return -1
if @IsCredit = 1
	select @Amount1 = -@Amount1
select @CF = @BF + @Amount1
if @TransDate is NULL
	select @TransDate = GetDate()


insert into Requisitions
([LOGIN],[ClientNo],PostDate,[DEALNO],[TRANSCODE],Method,[TransDate],[DESCRIPTION],[AMOUNT],CASHBOOKID,Cancelled, ExCurrency,ExRate,ExAmount,Approved)
values
(@User,@ClientNo,GetDate(),@DealNo,@TransCode,@Method,@TransDate,@Description,@Amount1,@CashBookID,0,@ExCurrency,@ExRate,@ExAmount,0)


GO
/****** Object:  StoredProcedure [dbo].[ReverseJournals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ReviewJournals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ReviewPayments]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ReviewReceipts]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ScripBalancingSummary]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[ScripBalancingSummaryScripBal]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAccummulateCapitalGains]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAccummulateCommissionerLevy]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAccummulateInvestorProtection]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAccummulateStampDuty]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAccummulateVAT]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAddSecuritySettings]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAppendToFile]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spApproveBonusIssueDeals]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spApproveConsolidationSplit]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spApproveDividend]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spApproveIPO]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spApproveTransaction]    Script Date: 2019-04-11 04:33:11 PM ******/
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

CREATE procedure [dbo].[spApproveTransaction]
	@user varchar(30),
	@reqid bigint
as
declare @transcode varchar(10)

select @transcode = transcode from requisitions where ReqID = @reqid

if @transcode = 'PAY' or @transcode = 'REC'
begin
	insert into cashbooktrans(clientno, postdate, dealno, transcode, transdate, [description], amount, cash, [LOGIN], cashbookid, chqrqid)
	select clientno, postdate, dealno, transcode, transdate, [description], amount, 1, @user, cashbookid, @reqid
	from Requisitions 
	where ReqID = @reqid

	update requisitions set approved = 1 where reqid = @reqid
end

--select top 10 * from cashbooktrans order by transid desc
GO
/****** Object:  StoredProcedure [dbo].[spAssignPermmission]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spBackupFalconDB]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spBrokerToBrokerRecon]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCancelCashFlowDelivery]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCancelCompletedTransfer]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCancelConsolidation]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCancelTransfer]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCapitalGainsTax]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCheckAccess]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCheckBrokerNo]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCheckChargeAccount]    Script Date: 2019-04-11 04:33:11 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spCheckClientBuyScrip]    Script Date: 2019-04-11 04:33:11 PM ******/
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
