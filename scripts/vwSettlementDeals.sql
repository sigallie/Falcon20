alter view vwSettlementDeals
as
select d.dealdate, d.dealno, d.qty, d.asset, d.price, d.consideration, coalesce(c.companyname, c.surname+' '+c.firstname) as client,
(d.vat+d.investorprotection+d.csdlevy) as settleamount
from dealallocations d inner join clients c on d.clientno = c.clientno
and d.approved = 1 and d.cancelled = 0 and d.merged = 0
and d.dealtype = 'SELL'