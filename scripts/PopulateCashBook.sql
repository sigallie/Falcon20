alter procedure PopulateCashBook  --execute PopulateCashBook 'STANBIC', '20190401', '20910617'
@cashbook varchar(50),
@start datetime,
@end datetime,
@user varchar(30) = 'bug'
as

declare @id bigint
declare @openingbal money

delete from tblCashBookReport where username = @user

select @id = id from CASHBOOKS
where code = @cashbook

select @openingbal = isnull(sum(amount), 0) from CASHBOOKTRANS
where CASHBOOKID = @id
and transdate < @start
--and 

insert into tblCashBookReport(transdate, [description], RunBal, username, transid)
values(@start, 'Balance brought forward', @openingbal, @user, 0)

insert into tblCashBookReport(transdate, postdate, clientno, [description], amount, balbf, username, transid)
select transdate, postdate, clientno, transcode+' - '+[description], amount, @openingbal, @user, transid
from CASHBOOKTRANS
where CASHBOOKID = @id
and transdate >= @start
and transdate <= @end
order by transdate, transid

execute spComputeRunningBalances @id, @start, @end, @user