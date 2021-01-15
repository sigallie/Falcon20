alter function fnCalculateCommission(
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