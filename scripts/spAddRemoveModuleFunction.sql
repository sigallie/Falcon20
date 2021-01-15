alter procedure spAddRemoveModuleFunction
@module varchar(50),
@function varchar(50),
@code int
as

declare @mid int

select @mid = mid from modules
where modname = @module

if exists(select id from tblScreens where moduleid = @mid and screenname = @function)
begin
	raiserror('The specified function already exists in the selected module', 11, 1)
	return
end

insert into tblScreens(screenname, moduleid)
values(@function, @mid)