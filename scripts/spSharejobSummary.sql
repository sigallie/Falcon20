alter procedure spSharejobbingSummary
@start datetime,
@end datetime,
@user varchar(50)
as

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
