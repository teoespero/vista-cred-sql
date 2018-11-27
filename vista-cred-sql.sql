-- where are we
select 
	upper(@@SERVERNAME) as DBServer,
	DB_NAME() as DBName,
	DistrictID,
	DistrictAbbrev,
	DistrictTitle
from tblDistrict


-- set useCustomCredentialData to 'Global' (0)
update tblDistrict
	set useCustomCredentialData = 0

-- begin from scratch
truncate table tblCredentialDetail
truncate table convCredential

-- on pasting we get an error saying
-- the column was not big enough

alter table convCredential alter column crednum varchar(50)
alter table convCredential alter column renew1 varchar(50)
alter table convCredential alter column subjectCred varchar(50)


-- get the employee id
update convCredential 
	set
		EmployeeID = te.EmployeeID
from convCredential cv
inner join
	tblEmployee te
	on cv.SSN = te.SocSecNo

-- check for stragglers
select distinct
	Fullname
from convCredential
where
	EmployeeID is null
-- none, good


-- get CredTerm ID
update convCredential
	set
		renew2 = ct.CredentialTermID
from convCredential cv
inner join
	DS_Global..tblCredentialTerm ct
	on ct.CredentialTermCode = cv.renew1

-- check for credterm stragglers
select *
from convCredential
where
	renew2 is null
	-- none, good

-- get credCode ID
update convCredential
	set
		renew4 = gcc.CredentialSubjectID
from convCredential cv
left join
	DS_Global..tblCredentialSubject gcc
	on gcc.CredentialCode = cv.renew3
	and cv.Subject1 = gcc.CredentialSubject

select * from DS_Global..tblCredentialSubject gcc
where
	gcc.CredentialCode = 'SC8'

-- check for stragglers, renew4 (CredentialSubjectID)
select distinct
	Subject1,
	renew3
from convCredential
where
	renew4 is null
	and Subject1 is not null

-- insert them

-- get our columns + ','
select COLUMN_NAME + ','
from DS_Global.INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = N'tblCredentialSubject'

insert into DS_Global..tblCredentialSubject (
	DistrictId,
	CredentialSubject,
	CredentialCode,
	isSupplimental,
	State
)
select distinct
	-1,
	Subject1,
	renew3,
	0,
	'CA'
from convCredential
where
	renew4 is null
	and Subject1 is not null

select *
from DS_Global..tblCredentialCode


-- get credID
update convCredential
	set
		CredentialID = gcc.CredentialID
from convCredential cv
inner join
	DS_Global..tblCredential gcc
	on gcc.Credential = cv.Credential
	and gcc.CredentialCode = cv.renew3




-- check for stragglers credentialid
select 
	distinct
	Credential,
	renew3
from convCredential
where
	CredentialID is null

insert into DS_Global..tblCredential (
	DistrictId,
	Credential,
	CredentialCode,
	State
)
select 
	distinct
	-1,
	Credential,
	renew3,
	'CA'
from convCredential
where
	CredentialID is null

	select *
	from DS_Global..tblCredential 
	where
		Credential like 'Designated Subjects Adult Education Teaching Credential: %'



-- insert our employees

-- get our columns + ','
select COLUMN_NAME + ','
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = N'tblCredentialDetail'

truncate table tblCredentialDetail


insert into tblCredentialDetail(
	EmployeeID,
	CredentialTermID,
	IssueDate,
	ExpireDate,
	CredentialNo,
	CredentialID,
	Assignment,
	Notes,
	Dcreated,
	DistrictID
)
select
	distinct
	EmployeeID,
	renew2,
	IssueDate,
	ExpireDate,
	CredNum,
	CredentialID,
	Assignment,
	renew4,
	'11/27/18',
	(select DistrictID from tblDistrict)
from convCredential


-- back populate credential id
-- for our subjects
update convCredential
	set
		CredentialDetailID = cd.CredentialDetailID
from convCredential cv
inner join
	tblCredentialDetail cd
	on cd.EmployeeID = cv.EmployeeID
	and cd.CredentialNo = cv.CredNum
	and cd.Assignment = cv.Assignment
	and cd.Notes = cv.renew4

update convCredential
set
	CredentialDetailID = null



-- insert our subject details
truncate table tblCredentialSubjectDetail
insert into tblCredentialSubjectDetail (
	CredentialDetailID,
	CredentialSubjectID,
	Dcreated,
	DistrictId,
	IssueDate,
	MajorMinor
)
select 
	distinct
	CredentialDetailID,
	renew4,
	'11/27/18',
	(select DistrictID from tblDistrict),
	IssueDate,
	Assignment
from convCredential cv
where
	renew4 is not null
	

-- populate the subject string on tblCredentialDetail
select 
	cd.CredentialDetailID,
		cd.CredentialNo,
		cr.Credential,
		cd.IssueDate,
		cd.ExpireDate,
		ct.CredentialTerm,
		csd.CredentialSubjectID,
		csj.CredentialSubject,
		cst.CredentialSubjectType,
		cd.CredentialID,
		cr.CredentialCode,
		isnull(cst.CredentialSubjectType,'') + ':' + csj.CredentialSubject + ':' + cr.CredentialCode
from tblCredentialDetail cd
inner join
	DS_Global..tblCredential cr
	on cd.CredentialID = cr.CredentialID
inner join
	DS_Global..tblCredentialTerm ct
	on cd.CredentialTermID = ct.CredentialTermID
inner join
	tblCredentialSubjectDetail csd
	on csd.CredentialDetailID = cd.CredentialDetailID
inner join
	DS_Global..tblCredentialSubject csj
	on csd.CredentialSubjectID = csj.CredentialSubjectID
left join
	DS_Global..tblCredentialSubjectType cst
	on cst.CredentialSubjectTypeID = csd.CredentialSubjectTypeID

-- update subject string
-- populate the subject string on tblCredentialDetail
update tblCredentialDetail
	set
		SubjectString = isnull(cst.CredentialSubjectType,'') + ':' + isnull(csj.CredentialSubject,'') + ':' + isnull(cr.CredentialCode,'')
from tblCredentialDetail cd
inner join
	DS_Global..tblCredential cr
	on cd.CredentialID = cr.CredentialID
inner join
	DS_Global..tblCredentialTerm ct
	on cd.CredentialTermID = ct.CredentialTermID
inner join
	tblCredentialSubjectDetail csd
	on csd.CredentialDetailID = cd.CredentialDetailID
inner join
	DS_Global..tblCredentialSubject csj
	on csd.CredentialSubjectID = csj.CredentialSubjectID
left join
	DS_Global..tblCredentialSubjectType cst
	on cst.CredentialSubjectTypeID = csd.CredentialSubjectTypeID



