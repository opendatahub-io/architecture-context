# Context Index and Version Diff

`arch-query index` is an opt-in generator for a single architecture version.
Its versioned JSON output includes component names, source artifact paths,
available section counts, explicit common-question-to-section mappings, and
existing commit/analyzer metadata. It does not infer aliases or populate
missing facts.

The index format is currently version 2. The `purpose` question category maps
to the component `purpose` field rather than a section, so its section list is
empty. Other mappings are stable and sorted for deterministic output.

`arch-query diff --output json` provides version 1 machine-readable comparison
results. It reports added/removed/changed component facts and explicit status
values for successful comparisons, unknown components, missing extraction
data, and incompatible missing inputs. Existing text diff output is preserved.
