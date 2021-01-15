create procedure spRemovePermission
@profile varchar(50),
@module varchar(50),
@function varchar(50)
as

declare @modid int, @functionid int

select @modid = mid from modules where modname = @module

select @functionid = id from tblscreens where screenname = @function

delete from tblPermissions
where profilename = @profile
and screen = @functionid 
and moduleid = @modid