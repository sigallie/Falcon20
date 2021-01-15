alter procedure spSaveSettlement
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
