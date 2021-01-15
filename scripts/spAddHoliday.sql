create procedure spAddHoliday
@date datetime,
@description varchar(50)
as

if exists(select holidaydate from Holidays where holidaydate = @date)
begin
	raiserror('The specified date already exists!', 11, 1)
	return
end

insert into Holidays(holidaydate, holiday)
values(@date, @description)