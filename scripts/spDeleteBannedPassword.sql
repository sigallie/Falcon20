alter procedure spDeleteBannedPassword
@pass varchar(50)
as

delete from BannedPasswords where pass = @pass