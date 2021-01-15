create procedure spAddRemoveBank
@bank varchar(50),
@code int
as

if @code = 1
begin
	if not exists(select * from banks where name = @bank)
	begin
		insert into banks(code)
		values(@bank)
	end
	else
	begin
		raiserror('The specified bank already exists!', 11, 1)
	end
end
else
begin
	delete from banks where name = @bank
end

