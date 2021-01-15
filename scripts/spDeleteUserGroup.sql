alter procedure spDeleteUserGroup
@groupname varchar(50)
as

if exists(select profilename from tblPermissions where profilename = @groupname)
begin
	raiserror('Group cannot be deleted as there are users assigned to it!', 11, 1)
	return
end

delete from tblProfiles where profilename = @groupname