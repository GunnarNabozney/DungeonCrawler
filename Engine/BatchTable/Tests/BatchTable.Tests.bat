@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Table=%~dp0..\BatchTable.bat"
set "Collection=%~dp0..\..\BatchCollection\BatchCollection.bat"
set "BatchTest=%~dp0..\..\BatchTest\BatchTest.bat"

call "!BatchTest!" begin suite "BatchTable 1.0 deterministic self-test"

call "!Table!" :Initialize
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchTable"

call "!Table!" :GetStat TableCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Table count starts at zero"
call "!Table!" :GetStat RecordCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Record count starts at zero"
call "!Table!" :GetStat IndexCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Index count starts at zero"

call "!Table!" :CreateTable People PeopleTable
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create a schema-controlled table"

call "!Table!" :CreateTable people DuplicateTable
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a case-insensitive duplicate table name"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals TableNameAlreadyExists because "Report duplicate table names"

call "!Table!" :DefineField "!PeopleTable!" Name Id true false "" "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a required identifier field"
call "!Table!" :DefineField "!PeopleTable!" Age UInt false true 0 "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define an unsigned field with a default"
call "!Table!" :DefineField "!PeopleTable!" Active Bool false true true "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a Boolean field with a default"
call "!Table!" :DefineField "!PeopleTable!" Role Enum true false "" "Admin,User,Guest" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a required enum field"
call "!Table!" :DefineField "!PeopleTable!" Manager Reference false false "" "" "!PeopleTable!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a table-scoped reference field"
call "!Table!" :DefineField "!PeopleTable!" Code Id false false "" "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define an optional indexed identifier candidate"
call "!Table!" :DefineField "!PeopleTable!" Bio Text false false "" "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a BatchText handle field"
call "!Table!" :DefineField "!PeopleTable!" Group Collection false false "" "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a BatchCollection handle field"
call "!Table!" :DefineField "!PeopleTable!" Path DottedId false false "" "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a dotted identifier field"
call "!Table!" :DefineField "!PeopleTable!" Score Int false true -1 "" ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a signed field with a default"

call "!Table!" :DefineField "!PeopleTable!" Name Id false false "" "" ""
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a duplicate field"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals FieldAlreadyExists because "Report duplicate fields"

call "!Table!" :DefineField "!PeopleTable!" BadEnum Enum false false "" "" ""
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an enum field without choices"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals EnumChoicesRequired because "Report missing enum choices"

call "!Table!" :DefineIndex "!PeopleTable!" ByName Name true CaseInsensitive
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a unique case-insensitive equality index"
call "!Table!" :DefineIndex "!PeopleTable!" ByRole Role false CaseSensitive
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a non-unique case-sensitive equality index"
call "!Table!" :DefineIndex "!PeopleTable!" ByAge Age false CaseSensitive
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a numeric equality index"

call "!Table!" :DefineIndex "!PeopleTable!" ByBio Bio false CaseSensitive
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an index over an opaque text handle"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals FieldTypeNotIndexable because "Report non-indexable field types"

call "!Table!" :CreateRecord "!PeopleTable!" Alice ""
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Allocate the first stable record ID"
call "!BatchTest!" expect value "!Alice!" to equal People_000001 because "Automatic IDs use the table namespace and monotonic sequence"

call "!Table!" :ReadField "!Alice!" Age Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Record creation applies unsigned defaults"
call "!Table!" :ReadField "!Alice!" Active Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Record creation normalizes Boolean defaults"
call "!Table!" :ReadField "!Alice!" Score Actual
call "!BatchTest!" expect value "!Actual!" to equal -1 because "Record creation applies signed defaults"

call "!Table!" :ValidateRecord "!Alice!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a record missing required fields"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals RequiredFieldMissing because "Report missing required fields"

call "!Table!" :SetField "!Alice!" Name Alice
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Set an indexed identifier field"
call "!Table!" :SetField "!Alice!" Role Admin
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Set an indexed enum field"
call "!Table!" :SetField "!Alice!" Path Region.North
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Set a dotted identifier field"
call "!Table!" :ValidateRecord "!Alice!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Validate a complete record"
call "!Table!" :ReadRecord "!Alice!" Valid Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Validated records retain validity state"

call "!Table!" :CreateRecord "!PeopleTable!" Bob ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Allocate the second stable record ID"
call "!BatchTest!" expect value "!Bob!" to equal People_000002 because "Stable IDs advance monotonically"
call "!Table!" :SetField "!Bob!" Name Bob
call "!Table!" :SetField "!Bob!" Role User
call "!Table!" :SetField "!Bob!" Code Shared
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Populate the second record"

call "!Table!" :CreateRecord "!PeopleTable!" Carol ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Allocate the third stable record ID"
call "!BatchTest!" expect value "!Carol!" to equal People_000003 because "The third ID remains stable"
call "!Table!" :SetField "!Carol!" Name Carol
call "!Table!" :SetField "!Carol!" Role User
call "!Table!" :SetField "!Carol!" Code shared
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Populate the third record"

call "!Table!" :SetField "!Carol!" Name ALICE
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a duplicate value in a case-insensitive unique index"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals UniqueIndexViolation because "Report unique index violations"
call "!Table!" :ReadField "!Carol!" Name Actual
call "!BatchTest!" expect value "!Actual!" to equal Carol because "Rejected indexed updates leave record data unchanged"

call "!Table!" :FindUnique "!PeopleTable!" ByName alice Actual
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Find a record through a unique index"
call "!BatchTest!" expect value "!Actual!" to equal "!Alice!" because "Unique lookup honors case-insensitive comparison"

call "!Table!" :FindEqual "!PeopleTable!" ByRole User RoleQuery
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Materialize a non-unique query result"
call "!Collection!" :ReadCollection "!RoleQuery!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Non-unique indexes return every matching record"
call "!Collection!" :GetAt "!RoleQuery!" 1 QueryEntry
call "!Collection!" :ReadEntry "!QueryEntry!" Value Actual
call "!BatchTest!" expect value "!Actual!" to equal "!Bob!" because "Query results preserve deterministic membership order"
call "!Collection!" :GetAt "!RoleQuery!" 2 QueryEntry
call "!Collection!" :ReadEntry "!QueryEntry!" Value Actual
call "!BatchTest!" expect value "!Actual!" to equal "!Carol!" because "Query results preserve later index members"
call "!Collection!" :Release "!RoleQuery!"

call "!Table!" :SetField "!Carol!" Role Guest
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Update an indexed field"
call "!Table!" :FindEqual "!PeopleTable!" ByRole User RoleQuery
call "!Collection!" :ReadCollection "!RoleQuery!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Indexed updates remove old bucket membership"
call "!Collection!" :Release "!RoleQuery!"
call "!Table!" :FindEqual "!PeopleTable!" ByRole Guest RoleQuery
call "!Collection!" :ReadCollection "!RoleQuery!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Indexed updates add new bucket membership"
call "!Collection!" :Release "!RoleQuery!"

call "!Table!" :SetField "!Bob!" Role Guest
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Move the final value out of an index bucket"
call "!Table!" :ReadIndex "!PeopleTable!" ByRole BucketCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Empty index buckets are released deterministically"

call "!Table!" :DefineIndex "!PeopleTable!" ByActive Active false CaseSensitive
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Build an index over existing records"
call "!Table!" :FindEqual "!PeopleTable!" ByActive true ActiveQuery
call "!Collection!" :ReadCollection "!ActiveQuery!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "A new index includes existing defaulted values"

call "!Table!" :SetField "!Bob!" Group "!ActiveQuery!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Store a BatchCollection handle in a record"
call "!Table!" :SetField "!Bob!" Bio TX000001
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Store a syntactically valid BatchText handle"
call "!Table!" :HasField "!Bob!" Bio Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Check whether an optional field is set"
call "!Table!" :ClearField "!Bob!" Bio
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Clear an optional field"
call "!Table!" :HasField "!Bob!" Bio Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Cleared fields report unset"
call "!Collection!" :Release "!ActiveQuery!"

call "!Table!" :SetField "!Bob!" Age -1
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject a negative unsigned field value"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals InvalidUnsignedInteger because "Report unsigned field validation"
call "!Table!" :SetField "!Bob!" Active maybe
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 20 because "Reject an invalid Boolean field value"
call "!Table!" :ReadField "!Bob!" Active Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Rejected field updates preserve the old value"

call "!Table!" :DefineField "!PeopleTable!" Late Id false false "" "" ""
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Lock field schemas after record creation"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals SchemaLocked because "Report locked table schemas"

call "!Table!" :DefineIndex "!PeopleTable!" UniqueCode Code true CaseInsensitive
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a unique index whose existing data conflicts"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals UniqueIndexViolation because "Report uniqueness failure during index construction"
call "!Table!" :ReadIndex "!PeopleTable!" UniqueCode Field Actual
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Rollback a failed index definition completely"
call "!Table!" :GetStat IndexCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 4 because "Failed index creation does not change index statistics"

call "!Table!" :SetField "!Carol!" Manager "!Alice!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Set a validated record reference"
call "!Table!" :ReadRecord "!Alice!" ReferenceCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Reference fields track inbound references"

call "!Table!" :DeleteRecord "!Alice!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject deletion of a referenced record"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals RecordReferenced because "Report referential integrity constraints"

call "!Table!" :ClearField "!Carol!" Manager
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Clear a record reference"
call "!Table!" :ReadRecord "!Alice!" ReferenceCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Clearing a reference updates inbound counts"
call "!Table!" :DeleteRecord "!Alice!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Delete a record after references are removed"

call "!Table!" :CreateRecord "!PeopleTable!" Dave ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Create a record after deleting an earlier row"
call "!BatchTest!" expect value "!Dave!" to equal People_000004 because "Deleted stable IDs are never reused"
call "!Table!" :SetField "!Dave!" Name Dave
call "!Table!" :SetField "!Dave!" Role Admin

call "!Table!" :CreateRecord "!PeopleTable!" External External_Record
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Create a record with an explicit stable ID"
call "!BatchTest!" expect value "!External!" to equal External_Record because "Explicit stable IDs are preserved"
call "!Table!" :CreateRecord "!PeopleTable!" DuplicateExternal External_Record
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a duplicate explicit record ID"

call "!Table!" :CreateRecord "!PeopleTable!" Echo ""
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Continue automatic allocation after an explicit ID"
call "!BatchTest!" expect value "!Echo!" to equal People_000006 because "Explicit IDs consume sequence positions without reuse"
call "!Table!" :SetField "!Echo!" Name Echo
call "!Table!" :SetField "!Echo!" Role Guest

call "!Table!" :GetRecordAt "!PeopleTable!" 1 Actual
call "!BatchTest!" expect value "!Actual!" to equal "!Bob!" because "Record order compacts independently of stable IDs"
call "!Table!" :GetRecordAt "!PeopleTable!" 3 Actual
call "!BatchTest!" expect value "!Actual!" to equal "!Dave!" because "Stable IDs do not depend on current position"

call "!Table!" :ClearField "!Bob!" Role
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Allow a required field to become temporarily unset"
call "!Table!" :ValidateRecord "!Bob!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Validation detects a cleared required field"
call "!Table!" :SetField "!Bob!" Role Guest
call "!Table!" :ValidateRecord "!Bob!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Restoring a required field restores record validity"

call "!Table!" :ReleaseTable "!PeopleTable!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject release of a non-empty table"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals TableNotEmpty because "Report non-empty table release"

for %%R in ("!Bob!" "!Carol!" "!Dave!" "!External!" "!Echo!") do (
    call "!Table!" :DeleteRecord "%%~R"
    set "ActualExit=!errorlevel!"
    call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Delete record %%~R during deterministic cleanup"
)

call "!Table!" :ReleaseTable "!PeopleTable!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release an empty table and all internal indexes"

call "!Table!" create table Readable into ReadableTable
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Create a table through readable syntax"
call "!Table!" define field Label in table "!ReadableTable!" as Id
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a field through readable syntax"
call "!Table!" create record in table "!ReadableTable!" into ReadableRecord
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Create a record through readable syntax"
call "!Table!" set field Label in record "!ReadableRecord!" to Sample
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Set a field through readable syntax"
call "!Table!" read field Label from record "!ReadableRecord!" into Actual
call "!BatchTest!" expect value "!Actual!" to equal Sample because "Read a field through readable syntax"
call "!Table!" show records in table "!ReadableTable!" >nul
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "List records through readable syntax"
call "!Table!" delete record "!ReadableRecord!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Delete a record through readable syntax"
call "!Table!" release table "!ReadableTable!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release a table through readable syntax"

call "!Table!" :CreateTable Parent ParentTable
call "!Table!" :CreateTable Child ChildTable
call "!Table!" :DefineField "!ChildTable!" Parent Reference false false "" "" "!ParentTable!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Create tables with a schema-level reference"
call "!Table!" :ReleaseTable "!ParentTable!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject release of a table referenced by another schema"
call "!Table!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals TableSchemaReferenced because "Report schema-level table references"
call "!Table!" :ReleaseTable "!ChildTable!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release the dependent schema first"
call "!Table!" :ReleaseTable "!ParentTable!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release the target after schema references are removed"

call "!Table!" :GetStat TableCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "All tables are released"
call "!Table!" :GetStat RecordCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "All records are released"
call "!Table!" :GetStat IndexCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "All indexes are released"
call "!Collection!" :GetStat CollectionCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "BatchTable releases every internal collection"

call "!Table!" :Shutdown
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Shutdown BatchTable after cleanup"

:Summary
call "!BatchTest!" finish suite
set "TestExit=!errorlevel!"
call "!Table!" :Shutdown >nul 2>nul
exit /b !TestExit!
