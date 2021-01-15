alter procedure spConsolidatedCharges --exec spConsolidatedCharges '2020/01/01', '2020/09/17', 'adept'
@start datetime,
@end datetime,
@user varchar(30)
as
delete from ConsolidatedCharges where username = @user

insert into ConsolidatedCharges
select distinct x.transdate,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'COMMS') as comm,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'SDUTY') as sduty,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'CAPTAX') as cgt,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'ZSELV') as zse,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'CSDLV') as csd,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'INVPROT') as ipl,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'VATCOMM') as vat,
	(select isnull(sum(t.amount),0) from transactions t where t.transdate = x.transdate and t.transcode = 'COMMLV') as seclv
	, @user
from transactions x
where x.transdate >= @start
and x.transdate <= @end
