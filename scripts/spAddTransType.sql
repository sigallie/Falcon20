create procedure spDeactivateTransType
@code varchar(30)
as

if exists(select transtype from transtypes where transtype = @code and active = 1)
begin
	update transtypes set active = 0
	where transtype = @code
end

if exists(select transtype from transtypes where transtype = @code and active = 0)
begin
	update transtypes set active = 1
	where transtype = @code
end