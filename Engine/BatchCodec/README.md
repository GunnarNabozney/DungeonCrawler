# BatchCodec 1.0

BatchCodec provides deterministic, versioned serialization for the batch engine. It stores arbitrary value bytes through BatchText handles and never places payload content in a CMD variable or command line.

## Format version 1

A package is canonical 7-bit ASCII with CRLF line endings:

```text
BATCHCODEC|1|<Kind>
<canonical records>
END|<RecordCount>|<SHA256>
```

Supported document kinds:

- `SaveData`: registry values, objects, object fields, and text records.
- `Registry`: registry-value records only.
- `Object`: object declarations and object-field records only.
- `TextBundle`: text records only.

Metadata is encoded from UTF-8 bytes. ASCII letters, digits, `-`, `.`, `_`, and `~` remain literal; every other byte becomes uppercase `%HH`. Payloads use canonical Base64 and carry an explicit decoded byte length. Records are sorted by category and logical key before encoding. Duplicate keys are case-insensitive.

The final SHA-256 value covers the exact canonical header and record body, including CRLF. Decode rejects malformed syntax, invalid escaping, invalid Base64, length mismatches, duplicate records, non-canonical ordering, incompatible record categories, integrity failures, and unsupported versions.

## Record forms

```text
R|Registry|Dotted.Key|Type|ByteLength|Base64
O|ObjectName|Dotted.TypeId
F|ObjectName|FieldName|Type|ByteLength|Base64
T|Dotted.TextName|ByteLength|Base64
```

## Compact API

```text
:Initialize
:Shutdown
:CreateDocument Kind OutputVariable
:AddRegistryValue Document Registry Key Type TextHandle
:AddObject Document ObjectName TypeId
:AddObjectField Document ObjectName FieldName Type TextHandle
:AddText Document Name TextHandle
:Encode Document TargetPath
:Decode SourcePath OutputVariable
:GetRegistryValue Document Registry Key TypeOutput TextOutput
:GetObjectType Document ObjectName TypeOutput
:GetObjectField Document ObjectName FieldName TypeOutput TextOutput
:GetText Document Name TextOutput
:Escape TextHandle TextOutput
:Unescape TextHandle TextOutput
:GetDocumentInfo Document Field OutputVariable
:GetStat DocumentCount OutputVariable
:Release Document
:ReadLastError Field OutputVariable
:PrintLastError
:ClearLastError
```

Payloads are copied when added, so a document does not depend on the lifetime of the source BatchText handle. Get operations materialize new BatchText handles owned by the caller.

## Escaping

`:Escape` and `:Unescape` operate on BatchText handles. They preserve every byte, including `%`, `!`, shell metacharacters, NUL, high bytes, and mixed newlines. Unescape accepts only literal unreserved ASCII and canonical uppercase `%HH` groups. Over-escaped unreserved bytes are rejected.

## Limits

- Format version: `1`
- Maximum package: 64 MiB
- Maximum payload: 16 MiB
- Maximum records: 10,000
- Handle space: 999,999 active allocations per process lifetime
