@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "Collection=%~dp0..\BatchCollection.bat"
set "BatchTest=%~dp0..\..\BatchTest\BatchTest.bat"

call "!BatchTest!" begin suite "BatchCollection 1.0 deterministic self-test"

call "!Collection!" :Initialize
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Initialize BatchCollection"
if defined BT.Abort goto :Summary

call "!Collection!" :GetStat CollectionCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Collection count starts at zero"
call "!Collection!" :GetStat EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Entry count starts at zero"
call "!Collection!" :GetStat SlotCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Slot count starts at zero"

call "!Collection!" :Create Ordered Ordered
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Create an ordered collection"

call "!Collection!" :Create ordered DuplicateName
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a case-insensitive duplicate collection name"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals CollectionNameAlreadyExists because "Report the duplicate collection name"

call "!Collection!" :ReadCollection "!Ordered!" EntryKind Actual
call "!BatchTest!" expect value "!Actual!" to equal Any because "Collections accept any entry kind by default"
call "!Collection!" :ReadCollection "!Ordered!" Duplicates Actual
call "!BatchTest!" expect value "!Actual!" to equal Allow because "Collections allow duplicates by default"
call "!Collection!" :ReadCollection "!Ordered!" MergePolicy Actual
call "!BatchTest!" expect value "!Actual!" to equal Never because "Collections do not merge by default"

call "!Collection!" :Add "!Ordered!" Value Alpha Record.Alpha 2 3 AlphaEntry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 0 because "Add a quantified measured entry"
call "!Collection!" :Add "!Ordered!" Object Object_1 Record.Object 1 4 ObjectEntry
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Add an object-handle entry"
call "!Collection!" :Insert "!Ordered!" 2 Value Middle "" 1 0 MiddleEntry
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Insert an entry at a specific position"

call "!Collection!" :GetAt "!Ordered!" 1 Actual
call "!BatchTest!" expect value "!Actual!" to equal "!AlphaEntry!" because "The first entry retains its order"
call "!Collection!" :GetAt "!Ordered!" 2 Actual
call "!BatchTest!" expect value "!Actual!" to equal "!MiddleEntry!" because "Insertion occupies the requested position"
call "!Collection!" :GetAt "!Ordered!" 3 Actual
call "!BatchTest!" expect value "!Actual!" to equal "!ObjectEntry!" because "Insertion shifts following entries"

call "!Collection!" :ReadCollection "!Ordered!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Entry count tracks ordered records"
call "!Collection!" :ReadCollection "!Ordered!" TotalQuantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 4 because "Total quantity aggregates entries"
call "!Collection!" :ReadCollection "!Ordered!" TotalMeasure Actual
call "!BatchTest!" expect value "!Actual!" to equal 10 because "Total measure aggregates quantity times measure"

call "!Collection!" :Move "!Ordered!" 3 1
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Move an entry within the collection"
call "!Collection!" :GetAt "!Ordered!" 1 Actual
call "!BatchTest!" expect value "!Actual!" to equal "!ObjectEntry!" because "Move updates collection order"
call "!Collection!" :ReadEntry "!AlphaEntry!" Position Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Move updates stable entry positions"

call "!Collection!" :SetQuantity "!Ordered!" "!AlphaEntry!" 3
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Increase an entry quantity"
call "!Collection!" :ReadCollection "!Ordered!" TotalQuantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 5 because "Quantity changes update aggregate quantity"
call "!Collection!" :ReadCollection "!Ordered!" TotalMeasure Actual
call "!BatchTest!" expect value "!Actual!" to equal 13 because "Quantity changes update aggregate measure"

call "!Collection!" :RemoveQuantity "!Ordered!" "!AlphaEntry!" 1
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Remove part of an entry quantity"
call "!Collection!" :ReadEntry "!AlphaEntry!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Partial removal preserves the entry"

call "!Collection!" :Split "!Ordered!" "!AlphaEntry!" 1 SplitEntry
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Split an entry quantity"
call "!Collection!" :ReadCollection "!Ordered!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 4 because "Split creates another ordered entry"
call "!Collection!" :ReadEntry "!SplitEntry!" Position Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Split inserts immediately after the source"

call "!Collection!" :Merge "!Ordered!" "!SplitEntry!" "!AlphaEntry!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Merge compatible entries"
call "!Collection!" :ReadEntry "!AlphaEntry!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Merge combines quantities"
call "!Collection!" :ReadCollection "!Ordered!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 3 because "Merge removes the source entry"

call "!Collection!" :DefineSlot "!Ordered!" Primary Value 2
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Define a typed named slot"
call "!Collection!" :AssignSlot "!Ordered!" Primary "!AlphaEntry!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Assign an entry to a slot"
call "!Collection!" :GetSlot "!Ordered!" Primary Actual
call "!BatchTest!" expect value "!Actual!" to equal "!AlphaEntry!" because "Read a slot assignment"

call "!Collection!" :SetQuantity "!Ordered!" "!AlphaEntry!" 3
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a quantity above an assigned slot maximum"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals SlotQuantityRejected because "Report the slot quantity constraint"
call "!Collection!" :ReadEntry "!AlphaEntry!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "A rejected slot update leaves quantity unchanged"

call "!Collection!" :UnassignSlot "!Ordered!" Primary
call "!Collection!" :SetQuantity "!Ordered!" "!AlphaEntry!" 3
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Quantity can increase after slot removal"

call "!Collection!" :SetPolicy "!Ordered!" CountLimit 3
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Set a count limit at current usage"
call "!Collection!" :Add "!Ordered!" Value Extra "" 1 0 RejectedEntry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject an entry above the count limit"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals CountCapacityExceeded because "Report count capacity failure"

call "!Collection!" :SetPolicy "!Ordered!" CountLimit 0
call "!Collection!" :SetPolicy "!Ordered!" MeasureLimit 13
call "!Collection!" :Add "!Ordered!" Value Heavy "" 1 1 RejectedEntry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject an entry above the measure limit"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals MeasureCapacityExceeded because "Report measure capacity failure"
call "!Collection!" :SetPolicy "!Ordered!" MeasureLimit 0

call "!Collection!" :Create Unique Unique
call "!Collection!" :SetPolicy "!Unique!" EntryKind Value
call "!Collection!" :SetPolicy "!Unique!" Duplicates Reject
call "!Collection!" :SetPolicy "!Unique!" Comparison CaseInsensitive
call "!Collection!" :Add "!Unique!" Value Token "" 1 0 UniqueEntry
call "!Collection!" :Add "!Unique!" Value token "" 1 0 RejectedEntry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject case-insensitive duplicate values"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals DuplicateEntry because "Report duplicate-entry failure"

call "!Collection!" :Create Stack Stack
call "!Collection!" :SetPolicy "!Stack!" EntryKind Value
call "!Collection!" :SetPolicy "!Stack!" MergePolicy SameDefinition
call "!Collection!" :Add "!Stack!" Value Batch_A Product.Shared 2 5 StackEntry
call "!Collection!" :Add "!Stack!" Value Batch_B Product.Shared 3 5 MergedEntry
call "!BatchTest!" expect value "!MergedEntry!" to equal "!StackEntry!" because "Same-definition additions reuse the target entry"
call "!Collection!" :ReadEntry "!StackEntry!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 5 because "Same-definition merge combines quantities"
call "!Collection!" :ReadCollection "!Stack!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Merge policy avoids duplicate entry records"
call "!Collection!" :ReadCollection "!Stack!" TotalMeasure Actual
call "!BatchTest!" expect value "!Actual!" to equal 25 because "Merged quantities preserve aggregate measure"

call "!Collection!" :Split "!Stack!" "!StackEntry!" 1 RejectedEntry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject split while automatic merging is enabled"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals SplitRejected because "Report split-policy failure"

call "!Collection!" :Create Source Source
call "!Collection!" :Create Target Target
call "!Collection!" :SetPolicy "!Target!" MergePolicy SameValue
call "!Collection!" :Add "!Source!" Value Bolt Part.Bolt 5 2 SourceBolt
call "!Collection!" :Add "!Target!" Value Bolt Part.Bolt 2 2 TargetBolt

call "!Collection!" :TransferQuantity "!Source!" "!SourceBolt!" 3 "!Target!" TransferResult
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Transfer a partial quantity atomically"
call "!BatchTest!" expect value "!TransferResult!" to equal "!TargetBolt!" because "Partial transfer merges into a compatible target"
call "!Collection!" :ReadEntry "!SourceBolt!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 2 because "Partial transfer decreases the source quantity"
call "!Collection!" :ReadEntry "!TargetBolt!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 5 because "Partial transfer increases the target quantity"

call "!Collection!" :TransferEntry "!Source!" "!SourceBolt!" "!Target!" TransferResult
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Transfer a whole entry atomically"
call "!BatchTest!" expect value "!TransferResult!" to equal "!TargetBolt!" because "Whole transfer merges into the target"
call "!Collection!" :ReadCollection "!Source!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Merged whole transfer removes the source entry"
call "!Collection!" :ReadEntry "!TargetBolt!" Quantity Actual
call "!BatchTest!" expect value "!Actual!" to equal 7 because "Whole transfer preserves all quantity"

call "!Collection!" :Create Limited Limited
call "!Collection!" :SetPolicy "!Limited!" CountLimit 1
call "!Collection!" :Add "!Limited!" Value Existing "" 1 0 ExistingEntry
call "!Collection!" :Create OverflowSource OverflowSource
call "!Collection!" :Add "!OverflowSource!" Value Candidate "" 1 0 CandidateEntry
call "!Collection!" :TransferEntry "!OverflowSource!" "!CandidateEntry!" "!Limited!" TransferResult
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject a transfer that exceeds target capacity"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals CountCapacityExceeded because "Report transfer capacity failure"
call "!Collection!" :ReadCollection "!OverflowSource!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Failed transfer leaves the source unchanged"
call "!Collection!" :ReadCollection "!Limited!" EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Failed transfer leaves the target unchanged"

call "!Collection!" :Create AssignedSource AssignedSource
call "!Collection!" :Create AssignedTarget AssignedTarget
call "!Collection!" :Add "!AssignedSource!" Value Assigned "" 1 0 AssignedEntry
call "!Collection!" :DefineSlot "!AssignedSource!" Active Value 1
call "!Collection!" :AssignSlot "!AssignedSource!" Active "!AssignedEntry!"
call "!Collection!" :TransferEntry "!AssignedSource!" "!AssignedEntry!" "!AssignedTarget!" TransferResult
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Transfer an assigned entry"
call "!Collection!" :GetSlot "!AssignedSource!" Active Actual
call "!BatchTest!" expect value "!Actual!" to equal "" because "Whole transfer clears source slot assignments"
call "!Collection!" :ReadEntry "!AssignedEntry!" AssignedSlots Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Transferred entries report no stale assignments"

call "!Collection!" :Create Parent Parent
call "!Collection!" :Create Child Child
call "!Collection!" :Create Grandchild Grandchild
call "!Collection!" :Add "!Parent!" Collection "!Child!" "" 1 0 ChildReference
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Add a nested collection reference"
call "!Collection!" :ReadCollection "!Child!" ReferenceCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 1 because "Nested collections track inbound references"

call "!Collection!" :Release "!Child!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject release of a referenced collection"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals CollectionReferenced because "Report the collection reference constraint"

call "!Collection!" :Add "!Child!" Collection "!Grandchild!" "" 1 0 GrandchildReference
call "!Collection!" :Add "!Grandchild!" Collection "!Parent!" "" 1 0 RejectedEntry
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Reject an indirect nested collection cycle"
call "!Collection!" :ReadLastError Kind Actual
call "!BatchTest!" expect error Kind value "!Actual!" equals CollectionCycle because "Report nested cycle detection"

call "!Collection!" :RemoveEntry "!Parent!" "!ChildReference!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Remove a nested collection reference"
call "!Collection!" :ReadCollection "!Child!" ReferenceCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "Removing a nested entry decrements references"

call "!Collection!" create collection Readable into ReadableCollection
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Create a collection through readable syntax"
call "!Collection!" add value Sample to collection "!ReadableCollection!" into ReadableEntry
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Add a value through readable syntax"
call "!Collection!" read entry "!ReadableEntry!" field Value into Actual
call "!BatchTest!" expect value "!Actual!" to equal Sample because "Read an entry through readable syntax"
call "!Collection!" show entries in collection "!ReadableCollection!" >nul
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "List entries through readable syntax"

call "!Collection!" :Release "!ReadableCollection!"
call "!Collection!" :Release "!Grandchild!"
set "ActualExit=!errorlevel!"
call "!BatchTest!" expect exit "!ActualExit!" to equal 30 because "Grandchild remains referenced until Child is released"
call "!Collection!" :Release "!Child!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release a formerly referenced collection"
call "!Collection!" :Release "!Grandchild!"
call "!BatchTest!" expect exit "!errorlevel!" to equal 0 because "Release a child after its parent reference is removed"
call "!Collection!" :Release "!Parent!"
call "!Collection!" :Release "!AssignedTarget!"
call "!Collection!" :Release "!AssignedSource!"
call "!Collection!" :Release "!OverflowSource!"
call "!Collection!" :Release "!Limited!"
call "!Collection!" :Release "!Target!"
call "!Collection!" :Release "!Source!"
call "!Collection!" :Release "!Stack!"
call "!Collection!" :Release "!Unique!"
call "!Collection!" :Release "!Ordered!"

call "!Collection!" :GetStat CollectionCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "All collections are released"
call "!Collection!" :GetStat EntryCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "All entry records are released"
call "!Collection!" :GetStat SlotCount Actual
call "!BatchTest!" expect value "!Actual!" to equal 0 because "All slots are released"

:Summary
call "!BatchTest!" finish suite
set "TestExit=!errorlevel!"
call "!Collection!" :Shutdown >nul 2>nul
exit /b !TestExit!
