create function fnGetCashBookID(@cashbook varchar(50))
returns int
as
begin
	declare @cashID int

	select @cashID = id from CASHBOOKS
	where code = @cashbook

	return @cashID
end


