-- In order to drop objects belonging to SAPSR3 you can this script as a reference.
-- In order to execute this sql file on the SAP ASE database host follow these steps:
-- 
-- Log into the OS as user syb<SAPSID>
-- Copy this file cleanSAPSR3Schema.sql to a temporary location, for example /tmp or in case of operating system Windows to C:\temp
-- Execute the command
--    isql -USAPSR3 -S<SAPSID> -X -P<password> -i<path to file cleanSAPSR3Schema.sql> 
-- An example would look like:
--    Unix/Linux: isql -USAPSR3 -STST -X -PXYZ1234 -i/tmp/cleanSAPSR3Schema.sql
--    Windows:    isql -USAPSR3 -STST -X -PXYZ1234 -ic:\temp\cleanSAPSR3Schema.sql
-- Afterwards log into the database as user SAPSR3 with command isql -USAPSR3 -S<SAPSID> -X -P<password> and double check whether the schema is empty. 
-- This can be done with commands
--   select name, type from sysobjects  where uid = user_id('SAPSR3') AND type <> 'F' 
--   go
-- If there are still objects remaining, start to delete objects with type U first, by issuing the command drop table <name> for each object individually.
-- Afterwards check again if the schema is empty as stated above.

SET NOCOUNT ON
use @@servername 
go 
if (exists( select * from sysobjects where name = 'upg_dropcmds' and id = object_id(user_name() + '.' + name ) )) 
    drop table [upg_dropcmds] 
create table upg_dropcmds (otype char(2) not null primary key, ocmd  varchar(100)) 
if (exists( select * from sysobjects where name = 'upg_dbss' and id = object_id(user_name() + '.' + name) )) 
    drop table [upg_dbss] 

create table upg_dbss (dname sysname) 

insert upg_dropcmds values ('U', 'drop table ') 
insert upg_dropcmds values ('V', 'drop view ') 
insert upg_dropcmds values ('P', 'drop procedure ') 
insert upg_dropcmds values ('IF', 'drop function ') 
insert upg_dropcmds values ('TF', 'drop function ') 
insert upg_dropcmds values ('FN', 'drop function ') 
insert upg_dropcmds values ('SF', 'drop function ') 
go 

declare udbs cursor for 
    select name from master..sysdatabases 
    where name = @@servername  
go 

declare @cmd varchar(250) 
declare @dbname sysname 
open udbs 
fetch next from udbs into @dbname 
while @@fetch_status = 0 
begin 
    select @cmd =  'if (exists(select name from ['+@dbname+']..sysusers where name = ''SAPSR3''))
            insert upg_dbss values('''+@dbname+''')'
    exec (@cmd) 
    fetch next from udbs into @dbname 
end 
close udbs 
deallocate udbs 
go 
 
 
declare objnames cursor for 
select name, type from sysobjects 
where id = object_id('SAPSR3' + '.' + name) 
and type in ('U', 'V', 'P', 'IF', 'TF', 'FN', 'SF') and name <> 'upg_dropcmds' and name <> 'upg_dbss' 
order by type desc 
go 
 
 
declare @cmd varchar(250) 
declare @objname sysname 
declare @objtype char(2) 
if (exists(select name from master..syslogins where name = 'SAPSR3')) 
begin 
    open objnames 
    fetch next from objnames into @objname, @objtype 
    while @@fetch_status = 0 begin 
        select @cmd = '' 
        select @cmd = ocmd from upg_dropcmds where otype = @objtype 
        if (len(@cmd) > 0) begin 
            select @cmd = @cmd || '[SAPSR3].[' || @objname || ']' 
            print 'executing %1!' , @cmd 
            exec (@cmd) 
        end 
        else print 'Unable to drop objects of type %1!' , @objtype 
        fetch next from objnames 
        into @objname, @objtype 
    end 
    close objnames 
    deallocate objnames 
end 
else begin 
    print 'Login ''SAPSR3'' not found' 
end 
go 
 
drop table [upg_dropcmds] 
drop table [upg_dbss] 
go 
if ((select COUNT(name) from sysobjects where uid = user_id('SAPSR3') AND type <> 'F') > 0) 
 BEGIN 
    select name, type from sysobjects  where uid = user_id('SAPSR3') AND type <> 'F' 
    print 'Please drop those objects manually. First, drop objects of type U with command "drop table <name>". Afterwards run "select name, type from sysobjects  where uid = user_id(''SAPSR3'') AND type <> ''F''" to check for remaining objects.' 
	print 'Completed with errors.' 
 END 
 ELSE
	print 'Completed successfully.' 
go 
