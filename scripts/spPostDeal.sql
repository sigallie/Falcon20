USE [NewfalconTest]
GO
/****** Object:  StoredProcedure [dbo].[spPostDeal]    Script Date: 2020/09/17 5:55:13 AM ******/
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

ALTER procedure [dbo].[spPostDeal] -- exec spPostDeal '20190220', '4498MMC', 'SELL', 2581, 96, 'CAIRN-L', '121554', 'bug'
	@dealdate datetime, @clientno varchar(10), @dealtype varchar(10),
	@qty int, @price float, @asset varchar(10), @CSDNumber varchar(10)
	,@user varchar(30), @noncustodial bit
as
declare @dealno varchar(10), @consideration money, @dealvalue money
declare @category varchar(30), @CDC varchar(10), @charges float, @brokerdealtype varchar(10);
declare @cgt money = 0, @sduty money = 0, @defaultcashbook int


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
	approvedby, grosscommission, yon, csdlevy, csdnumber)
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
	,@CSDNumber
	--select * from dealallocations
	--post the corresponding broker deal to ATS Trades account
	insert into dealallocations (docketno,dealtype,dealno,dealdate,clientno,asset,qty,price,consideration,grosscommission,basiccharges,stampduty,login,approved,sharesout,certdueby,cancelled, vat,capitalgains,investorprotection,commissionerlevy,zselevy,dealvalue,yon, DateAdded) 
	values(0, @brokerdealtype, left(@brokerdealtype, 1) +'/'+dbo.fnGetDealNo(), @dealdate, 0, @asset, @qty, @price, @consideration, 0, 0, 0, @user, 1, 0, dbo.fnGetSettlementDate(@dealdate), 0, 0, 0, 0, 0, 0, @consideration, 1, getdate())

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