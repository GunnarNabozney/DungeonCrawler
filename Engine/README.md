# Reusable Batch Engine

This folder contains project-agnostic infrastructure for building structured applications with Windows batch files.

The engine replaces functionality commonly implemented in PowerShell or conventional programming languages with reusable, human-readable `.bat` components.

## Direction

The architectural target is a pure Windows batch engine.

New reusable engine functionality must be implemented in `.bat`. Existing non-batch files may remain temporarily as migration inputs until their responsibilities are replaced.

Components must model general concepts such as objects, tables, collections, validation, transactions, events, serialization, text, and terminal interaction. They must not depend on the concepts, data, or rules of any one application.

## Command language

Public engine commands should read like instructions:

```bat
call "!Runtime!" run Math Add into Result with Left 17 and Right 25
call "!Table!" read field Balance from record "!Account!" into Balance
call "!Collection!" transfer entry "!Item!" from collection "!Source!" to collection "!Target!"
```

Each component should provide two surfaces:

1. A readable command language for application code.
2. A compact colon-prefixed ABI for engine integration and stable protocol use.

Readable commands must route into the compact ABI rather than creating a second implementation path.

## Reuse before duplication

Engine components should reuse established seams wherever practical:

- **BatchValidate** for validation and normalization.
- **BatchMath** for checked arithmetic.
- **BatchText** for arbitrary or expansion-sensitive text.
- **BatchCollection** for ordered membership, quantities, slots, and generic ownership relationships.
- **BatchTable** for schema-controlled records, stable IDs, references, and indexes.
- **BatchRuntime** for modules, functions, typed objects, invocation frames, and readable command design.
- **BatchTest** for deterministic component tests and standard summaries.

New components should extend or compose these systems instead of recreating their responsibilities.

## Component contract

Reusable engine components should provide:

- Deterministic initialization and shutdown.
- Explicit ownership and cleanup rules.
- Monotonic stable handles where handles are required.
- Structured errors with consistent exit-code families.
- Read, check, show, list, and statistic commands where useful.
- A documented compact ABI.
- A readable public command language.
- Project-agnostic names and behavior.
- Deterministic targeted tests.
- No hidden PowerShell implementation.

Arbitrary payload text must not be placed directly into expansion-sensitive CMD variables. Store it through the engine's safe-text boundary and pass handles instead.

## Development workflow

Use the smallest complete change:

```text
Inspect -> Change -> Targeted validation -> Commit -> Push
```

Run the affected component's deterministic suite after implementation changes. Commit and push immediately after targeted validation succeeds so the remote main branch remains the shared source of truth.

Reserve full application validation for changes that affect application integration or shared application boundaries.

## Future consistency pass

After the batch engine is complete, perform a full engine review to align every component with the final conventions for:

- Readable command grammar
- Compact ABIs
- Protocol manifests
- Dependency declarations
- Structured errors
- Ownership
- Introspection
- Documentation
- Test layout
- Pure `.bat` implementation

The goal is not merely to make batch files work. The goal is to make them compose like a small, readable programming environment.

Very unreasonable. Very reusable. Very fun.
