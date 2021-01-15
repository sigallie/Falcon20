create procedure spAdUserPermission
@profile varchar(50),
@module varchar(50),
@function varchar(50)
as

declare @screenid bigint
declare @moduleid bigint

select @screenid = id from tblScreens where screenname = @function
select @moduleid = mid from modules where modname = @module

if not exists(select * from tblPermissions where profilename = @profile and screen = @screenid and moduleid = @moduleid)
begin
	insert into tblPermissions(profilename, screen, moduleid)
	values(@profile, @screenid, @moduleid)
end
else
begin
	raiserror('The specified permission already exists for the user group!', 11, 1)
end