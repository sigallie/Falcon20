alter procedure spAddRemoveQuestion
@question varchar(50)
,@code int
as

if @code = 1
begin
	if exists(select question from passquestions where question = @question)
	begin
		raiserror('Question already exists!', 11, 1)
		return
	end

	insert into passquestions(question)
	values(@question)
end
else
begin
	delete from passquestions where question = @question
end