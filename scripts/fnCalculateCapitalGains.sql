alter function fnCalculateCapitalGains(
@consideration money
,@client varchar(10))
returns money
as
begin
	declare @rate float;

	select @rate = isnull(x.CapitalGains, 1) from clientcategory x inner join clients y on x.clientcategory  = y.category
	where y.clientno = @client

	return @consideration * @rate/100
end
