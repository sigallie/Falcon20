alter table tblsystemparams add CDCSettlementAccount int not null default(0)

procedure spSaveSettlement

update tblSystemParams set cdcsettlementaccount = 17