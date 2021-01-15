alter view vwDealAllocations
as
select d.dealdate, d.dealno, d.asset, d.qty, d.price, d.consideration, d.grosscommission, d.stampduty, d.capitalgains, d.investorprotection, d.zselevy, d.commissionerlevy, d.csdlevy, d.dealvalue
, c.category,
case c.[type]
when 'COMPANY' then c.companyname
else surname+' '+firstname
end as client
from dealallocations d inner join clients c on d.clientno = c.clientno
