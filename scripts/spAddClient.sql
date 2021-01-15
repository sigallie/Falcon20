USE [newfalcontest]
GO
/****** Object:  StoredProcedure [dbo].[spAddClient]    Script Date: 2019/12/09 10:24:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spAddClient]
@clientno varchar(10),
@companyname varchar(50),
@title varchar(20),
@firstname varchar(30),
@lastname varchar(30),
@address1 varchar(50),
@address2 varchar(50),
@phone varchar(50),
@email varchar(50),
@contact varchar(50),
@type varchar(30),
@bank varchar(30),
@branch varchar(30),
@accountno varchar(30),
@accounttype varchar(30),
@employer varchar(30),
@sector varchar(50),
@jobtitle varchar(30),
@busphone varchar(30),
@category  varchar(20)
as  --select clientno from clients
declare @id bigint

select @id = cast(replace(max(clientno), 'MMC', '') as int) + 1 from clients

if @clientno <> '0'
begin
	update clients set firstname = @firstname, surname = @lastname, companyname = @companyname,
	PhysicalAddress = @address1, [type] = @type, CATEGORY = @category, email = @email, BANK = @bank, BANKBRANCH = @branch,
	BankAccountType = @accounttype, BusPhone = @busphone, JobTitle = @title, SECTOR = @sector
	where clientno = @clientno
end
else
begin
	insert into clients(clientno, shortcode, title, firstname, surname, companyname, [type], category, [status], 
	STATUSREASON, PhysicalAddress, PostalAddress, contactno, dateadded, bank, bankbranch, BankAccountNo, 
	BankAccountType, sector, employer, JobTitle, ContactPerson, BusPhone)
	values(cast(@id as varchar(6)) +'MMC', 'NONE', @title, @firstname, @lastname, @companyname,  @type, @category, 'ACTIVE', 
	'NEW CLIENT', @address1, @address2, @phone, getdate(), @bank, @branch, @accountno, 
	@accountType, @sector,
	@employer, 
	@jobtitle, @contact, @busphone)
end
