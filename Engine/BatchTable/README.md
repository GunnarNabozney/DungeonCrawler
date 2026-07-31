# BatchTable 1.0

BatchTable is the project-agnostic schema-controlled record layer for the reusable batch engine.

It provides stable record IDs, typed fields, required-field validation, table-scoped references, deterministic record order, equality indexes, unique constraints, and query results backed by BatchCollection.

## Reused engine seams

BatchTable deliberately reuses established components instead of creating parallel frameworks:

- **BatchValidate** normalizes identifiers, dotted identifiers, signed and unsigned integers, Booleans, enum choices, enum values, and engine handle shapes.
- **BatchMath** performs checked counter arithmetic.
- **BatchCollection** owns ordered table membership, index-bucket membership, and caller-owned query-result collections.
- **BatchTest** provides the deterministic suite, assertions, and standard summary.
- **BatchText** remains the arbitrary-text boundary. `Text` fields store BatchText handles, never payload bytes in CMD variables.
- **BatchRuntime** object handles may be stored in `Object` fields, but object lifetime remains owned by BatchRuntime.

BatchTable does not shut down or clear its dependencies. It releases only collections that it created.

## Data model

A table has:

- A stable table handle such as `BTB1`
- A case-insensitive unique name
- A field schema
- A monotonically increasing record sequence
- An ordered collection of stable record IDs
- Zero or more equality indexes

A record ID is independent of the record's current position. Automatic IDs use:

```text
<TableName>_<six-digit sequence>
```

Examples:

```text
People_000001
People_000002
People_000003
```

Deleted IDs are never reused. Record IDs are globally unique across live tables. An explicit identifier may be supplied when importing or restoring known IDs. Explicit IDs consume a sequence position so the automatic allocator remains monotonic.

Protocol 1 supports 999,999 automatic IDs per table. Table names are limited to 55 characters so generated IDs remain valid identifiers.

## Field types

- `Int`: normalized signed 32-bit integer
- `UInt`: normalized unsigned 32-bit integer
- `Bool`: normalized to `0` or `1`
- `Id`: identifier
- `DottedId`: identifier or dotted identifier
- `Enum`: one value from a validated choice list
- `Reference`: stable record ID from one declared target table
- `Text`: syntactically valid BatchText handle
- `Object`: syntactically valid BatchRuntime object handle
- `Collection`: syntactically valid BatchCollection handle

Handle fields validate handle shape, not external liveness. The component that owns the handle remains responsible for lifetime.

Unset fields are distinct from empty values. Protocol 1 does not add a general null value.

## Schema rules

Fields must be defined before the first record is created. Creating the first record locks the field schema.

A field declares:

```text
Name
Type
Required
HasDefault
Default
Choices
ReferenceTable
```

- `Choices` is valid only for `Enum`.
- `ReferenceTable` is required only for `Reference`.
- Reference defaults are intentionally unsupported in protocol 1.
- Defaults are normalized through the field validator before the field is committed.
- Record creation applies every default.
- `ValidateRecord` checks required fields and reference liveness.

## Stable references

`Reference` fields enforce the declared target table and maintain inbound reference counts.

A referenced record cannot be deleted:

```text
RecordReferenced
```

Clearing or changing the reference decrements the old target before the new relationship is committed.

Field schemas also retain their target tables. A target table cannot be released while another live table schema references it. Self-referencing schemas are released with their own table.

Tables must be empty before release.

## Equality indexes

Protocol 1 indexes support:

- `Int`
- `UInt`
- `Bool`
- `Id`
- `DottedId`
- `Enum`
- `Reference`

Each index declares:

```text
Field
Unique
Comparison
```

Comparison is either:

```text
CaseSensitive
CaseInsensitive
```

Indexes may be defined before or after records exist. When an index is added to an existing table, BatchTable builds it from current records and rolls the definition back if a uniqueness conflict is found.

Index updates occur whenever an indexed field is set, changed, cleared, or its record is deleted. Empty buckets are released immediately.

Implementation note: index buckets avoid rescanning every record for equality lookups. Bucket-key comparison remains deterministic and may scan the distinct bucket keys because CMD environment-variable names cannot safely represent all case-sensitive logical keys.

## Query results

`FindEqual` returns a caller-owned BatchCollection containing matching record IDs in deterministic index-membership order.

The caller releases the result:

```bat
call "%Table%" :FindEqual "%People%" ByRole User Results
call "%Collection%" :ReadCollection "%Results%" EntryCount Count
call "%Collection%" :Release "%Results%"
```

`FindUnique` returns one record ID or an empty value and requires a unique index.

## Compact API

```text
:Initialize
:Shutdown

:CreateTable Name OutputVariable
:DefineField Table Field Type Required HasDefault Default Choices ReferenceTable
:ReadFieldSchema Table Field Property OutputVariable

:DefineIndex Table Index Field Unique Comparison
:ReadIndex Table Index Property OutputVariable

:CreateRecord Table OutputVariable RequestedId
:SetField Record Field Value
:ClearField Record Field
:ReadField Record Field OutputVariable
:HasField Record Field OutputVariable
:ValidateRecord Record
:ReadRecord Record Property OutputVariable
:GetRecordAt Table Position OutputVariable

:FindEqual Table Index Value OutputCollection
:FindUnique Table Index Value OutputRecord

:ListRecords Table
:ListIndexes Table
:DeleteRecord Record
:ReleaseTable Table

:GetStat Statistic OutputVariable
:ReadLastError Field OutputVariable
:PrintLastError
:ClearLastError
```

Use an empty `RequestedId` for automatic allocation.

## Readable API

```bat
call "%Table%" initialize tables
call "%Table%" create table People into PeopleTable
call "%Table%" define field Name in table "%PeopleTable%" as Id
call "%Table%" create record in table "%PeopleTable%" into Person
call "%Table%" set field Name in record "%Person%" to Alice
call "%Table%" read field Name from record "%Person%" into Actual
call "%Table%" check field Name in record "%Person%" into HasName
call "%Table%" validate record "%Person%"
call "%Table%" find value Alice in "%PeopleTable%" by ByName into Results
call "%Table%" show records in table "%PeopleTable%"
call "%Table%" show indexes in table "%PeopleTable%"
call "%Table%" delete record "%Person%"
call "%Table%" release table "%PeopleTable%"
call "%Table%" shutdown tables
```

The compact API exposes the complete schema and index configuration surface. The readable API intentionally covers the common path.

## Structured errors

Error state uses:

```text
Code
Kind
Message
Operation
Table
Record
Constraint
Expected
Actual
```

Exit-code families follow the engine convention:

- `0`: success
- `10`: readable command syntax
- `20`: value, schema, or type validation
- `30`: table, record, field, index, uniqueness, reference, or arithmetic constraint
- `50`: dependency or internal collection failure
- `61`: delayed expansion is not enabled

## Ownership and cleanup

BatchTable owns:

- Internal ordered record collections
- Internal index-bucket collections
- Table, field, record, and index metadata

Callers own:

- Query-result collections
- BatchText handles stored in `Text`
- BatchRuntime object handles stored in `Object`
- BatchCollection handles stored in `Collection`

Deleting a record does not release externally owned handles stored in its fields.

## Serialization boundary

BatchCodec 1.0 is unchanged. Table serialization should be added after the in-memory schema and index contract has been exercised by real consumers.

A future codec version can preserve:

- Table names and field schemas
- Stable record IDs and sequence positions
- Set and unset fields
- Reference relationships
- Index definitions

Index buckets should be rebuilt after decode rather than serialized as redundant state.
