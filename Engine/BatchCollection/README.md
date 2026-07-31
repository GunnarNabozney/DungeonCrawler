# BatchCollection 1.0

BatchCollection is the project-agnostic ordered collection layer for the reusable batch engine.

It provides stable collection and entry handles, ordered membership, quantities, generic measures, count and measure limits, duplicate and merge policies, atomic transfers, named slots, nested collection references, and cycle detection.

The component is intentionally neutral. The same operations can represent inventories, carts, queues, assignments, resource pools, document sections, playlists, dependency groups, or any other ordered set of managed entries.

## Reused engine seams

BatchCollection does not duplicate infrastructure already provided elsewhere:

- **BatchValidate** validates and normalizes identifiers, dotted identifiers, unsigned integers, enum values, and output names.
- **BatchMath** performs checked signed 32-bit addition, subtraction, and multiplication for quantities and aggregate measures.
- **BatchTest** provides the deterministic component suite and standardized summary.
- **BatchText** remains the boundary for arbitrary text. Collection values and definitions are restricted metadata tokens; opaque text should be stored in BatchText handles.
- **BatchRuntime** payload handles can be stored as `Object` entries, but their lifetime remains owned by the caller. BatchCollection owns its entry records, not external runtime objects.

This keeps collection mechanics reusable without creating a second validator, arithmetic layer, text store, object runtime, or test framework.

## Requirements

Callers enable command extensions and delayed expansion:

```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
```

BatchValidate and BatchMath must be present in their standard engine locations.

## Data model

A collection has:

- A unique identifier-safe name
- A stable handle such as `BC1`
- Ordered entries
- Entry-kind policy: `Any`, `Value`, `Object`, or `Collection`
- Duplicate policy: `Allow` or `Reject`
- Comparison policy: `CaseSensitive` or `CaseInsensitive`
- Merge policy: `Never`, `SameValue`, or `SameDefinition`
- Optional count limit
- Optional aggregate-measure limit
- Named slots

An entry has:

- A stable handle such as `BCE1`
- Owning collection
- One-based position
- Kind: `Value`, `Object`, or `Collection`
- Dotted-identifier-safe value
- Optional dotted definition identifier
- Positive quantity
- Non-negative per-unit measure
- Assigned-slot count

A zero capacity limit means unlimited.

## Readable API

```bat
call "%Collection%" initialize collections
call "%Collection%" create collection WorkQueue into Queue
call "%Collection%" set collection "%Queue%" policy EntryKind to Object
call "%Collection%" add value Task_1 to collection "%Queue%" into Entry
call "%Collection%" get entry at 1 from collection "%Queue%" into First
call "%Collection%" read entry "%First%" field Quantity into Quantity
call "%Collection%" show entries in collection "%Queue%"
call "%Collection%" remove entry "%First%" from collection "%Queue%"
call "%Collection%" release collection "%Queue%"
call "%Collection%" shutdown collections
```

The readable `add value` command creates a `Value` entry with quantity one, measure zero, and no definition. Advanced operations use the compact API.

## Compact API

```text
:Initialize
:Shutdown
:Create Name OutputVariable
:SetPolicy Collection Policy Value

:Add Collection Kind Value Definition Quantity Measure OutputEntry
:Insert Collection Index Kind Value Definition Quantity Measure OutputEntry
:GetAt Collection Index OutputEntry
:Find Collection Kind Value OutputEntry OutputIndex
:Contains Collection Kind Value OutputBoolean
:Move Collection FromIndex ToIndex

:ReadEntry Entry Field OutputVariable
:ReadCollection Collection Field OutputVariable
:SetQuantity Collection Entry Quantity
:RemoveQuantity Collection Entry Quantity
:RemoveEntry Collection Entry
:Split Collection Entry Quantity OutputEntry
:Merge Collection SourceEntry TargetEntry

:TransferEntry SourceCollection Entry TargetCollection OutputEntry
:TransferQuantity SourceCollection Entry Quantity TargetCollection OutputEntry

:DefineSlot Collection Slot AllowedKind MaximumQuantity
:AssignSlot Collection Slot Entry
:UnassignSlot Collection Slot
:GetSlot Collection Slot OutputEntry

:ListEntries Collection
:ListSlots Collection
:ClearCollection Collection
:Release Collection

:GetStat Statistic OutputVariable
:ReadLastError Field OutputVariable
:PrintLastError
:ClearLastError
```

## Policies

Policies are set with `:SetPolicy`.

| Policy | Values | Default |
|---|---|---|
| `EntryKind` | `Any`, `Value`, `Object`, `Collection` | `Any` |
| `Duplicates` | `Allow`, `Reject` | `Allow` |
| `Comparison` | `CaseSensitive`, `CaseInsensitive` | `CaseSensitive` |
| `MergePolicy` | `Never`, `SameValue`, `SameDefinition` | `Never` |
| `CountLimit` | `0` through `2147483647` | `0` |
| `MeasureLimit` | `0` through `2147483647` | `0` |

Entry-kind, duplicate, comparison, and merge policies can change only while the collection is empty. Capacity limits may change later, but cannot be reduced below current usage.

`SameValue` merges entries only when kind, value, definition, and per-unit measure are compatible. `SameDefinition` requires a non-empty matching definition, matching kind, and matching measure. Nested collection entries never merge.

## Quantities and measures

Quantities are positive signed-32-bit-compatible integers. Measures are non-negative per-unit values.

BatchCollection tracks:

```text
EntryCount
TotalQuantity
TotalMeasure
```

`TotalMeasure` is the checked sum of `Quantity * Measure`. Arithmetic overflow is a structured error rather than silent wraparound.

`Split` creates a second entry immediately after the source. It requires duplicate policy `Allow` and merge policy `Never`.

`Merge` combines compatible entries in one collection. Nested collection entries cannot be split or merged and always have quantity one.

## Atomic transfers

A transfer validates the complete target operation before mutating either collection:

- Target entry-kind policy
- Duplicate or merge behavior
- Count capacity
- Measure capacity
- Nested-cycle safety
- Slot quantity constraints on a merge target

A whole-entry transfer preserves the entry handle when it is not merged. A partial transfer creates or merges a target entry and decreases the source quantity.

Assignments in source slots are cleared when a whole entry leaves its collection.

## Named slots

Slots provide generic assignment semantics:

```bat
call "%Collection%" :DefineSlot "%Queue%" Active Object 1
call "%Collection%" :AssignSlot "%Queue%" Active "%Entry%"
call "%Collection%" :GetSlot "%Queue%" Active Assigned
call "%Collection%" :UnassignSlot "%Queue%" Active
```

A slot accepts one entry, may restrict its kind, and may impose a maximum quantity. An entry can be assigned to more than one slot.

Slots do not duplicate or move entries. They reference entries already in the same collection.

## Nested collections

A `Collection` entry stores another live collection handle. BatchCollection:

- Requires quantity one
- Tracks inbound reference counts
- Rejects direct and indirect cycles
- Prevents release while another collection references the collection
- Decrements references when entries are removed, transferred, cleared, or released

Nested entries are references. Releasing a parent does not automatically release referenced children.

## Ownership boundary

BatchCollection owns collection and entry records. It does not automatically release external values or object handles. This is deliberate: a stored value might be shared, managed by BatchRuntime, or owned by another subsystem.

Callers should release external payloads according to the subsystem that created them.

## Structured errors

Errors expose:

```text
Code
Kind
Message
Operation
Collection
Entry
Constraint
Expected
Actual
```

Exit-code families:

- `0`: success
- `10`: command syntax
- `20`: validation or policy mismatch
- `30`: collection state, capacity, quantity, slot, transfer, or cycle failure
- `50`: component or dependency failure
- `61`: delayed expansion is not enabled

## Serialization boundary

BatchCodec 1.0 is not changed by this component. Collection serialization should be added only after the in-memory contract has been exercised by real consumers. A future codec version can then preserve order, quantities, slots, constraints, and nested references without encoding a premature schema.
