USE [Newfalcon20]
GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveBannedPassword]    Script Date: 2020/10/21 7:14:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[spAddRemoveBannedPassword]
@pass varchar(50),
@code int
as

if @code = 1
begin
	if not exists(select pass from BannedPasswords where pass = @pass)
	begin
		insert into BannedPasswords(pass)
		values(@pass)
	end
	else
	begin
		raiserror('The passowrd is already specified!', 11, 1)
	end
end

if @code = 2
begin
	delete from bannedpasswords where pass = @pass
end