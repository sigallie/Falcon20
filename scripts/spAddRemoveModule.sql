USE [Newfalcon20]
GO
/****** Object:  StoredProcedure [dbo].[spAddRemoveCashBook]    Script Date: 2020/11/09 4:18:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[spAddRemoveModule]
@module varchar(50),
@code int
as
declare @modid int
if @code = 1
begin
	if not exists(select * from modules where modname = @module)
	begin
		insert into modules(modname)
		values(@module)
	end
	else
	begin
		raiserror('The specified module already exists!', 11, 1)
	end
end
else
begin
	select @modid = mid from modules
	where modname = @module

	if exists(select moduleid from tblPermissions where moduleid = @modid)
	begin
		raiserror('Module cannot be deleted as there are permissions assigned under it', 11, 1)
		return
	end
	
	delete from modules where modname = @module
end
