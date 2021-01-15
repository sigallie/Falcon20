alter procedure spLockUnlockUser
@user varchar(50)
as

if exists(select [login] from users where [login] = @user and islocked = 1)
begin
	update users set islocked = 0 where [login] = @user
end
else
begin
	update users set islocked = 1 where [login] = @user
end