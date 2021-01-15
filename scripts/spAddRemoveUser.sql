alter procedure spAddRemoveUser
@username varchar(50)
,@first varchar(50)
,@last varchar(50)
,@group varchar(50)
,@pass varchar(50)
,@code int
as
--select * from users
if @code = 1
begin
	if not exists(select [login] from users where [login] = @username)
	begin
		insert into users([login], pass, name, [profile], islocked, temppass)
		values(@username, @pass, @first +' '+@last, @group, 0, 1)
	end
	else
	begin
		raiserror('Username already exists!', 11, 1)
		return
	end

end