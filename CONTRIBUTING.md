# Contributing

Thanks for helping keep this architecture context accurate and useful. This repository contains periodically generated architecture data, the pipeline that produces it, and small human-authored corrections for changes between generation runs.

## Do not edit `architecture/`

Everything under [`architecture/`](architecture/) is generated output, not hand-crafted documentation. Do not change, add, move, or delete files there. Pull requests that modify that directory are rejected by CI.

Generation is run periodically and manually by [jtanner](https://github.com/jctanner). It is deliberately not on an automated schedule because full generation has material repository-cloning and model-execution costs.

If the generated output is incorrect or behind the current state:
* contribute an overlay (preferred)
* add addtional repos for inclusion in platforms.yaml
* improve the arch-analyzer
* improve the repo-to-architecture-summary skill

## Overlays

Overlays are human-written, targeted corrections between generation runs. They are read by downstream consumers in addition to the generated architecture data, and an active overlay takes precedence when it conflicts with generated content. Use one when generated output is missing or incorrect, or when a version, maturity level, dependency, or platform fact has changed since the last generation.

Follow the format and lifecycle in [`overlays/README.md`](overlays/README.md):

- Name files `NNNN-short-kebab-description.md` and include the required YAML front matter.
- State one concrete, source-backed fact. Include relevant component and release scopes, plus links in `provenance`.
- Keep the fact, impact, and context concise. **All overlays are fed to consumers**, so a long or numerous set of overlays can consume their context window and reduce the usefulness of the architecture data.
- Avoid duplicating facts already present in generated documents or splitting one correction into several overlays without a clear need.
- Once a generation contains the correction, mark the overlay `superseded` and set `superseded_by`; retain the file as its audit trail.

An overlay is deliberately temporary. Capture the lasting rationale and decision in the [architecture decision records repository](https://github.com/opendatahub-io/architecture-decision-records), then link that ADR from the overlay when appropriate. An overlay correcting generated content also records a gap for a later generation run to absorb.

Validate overlay changes with:

```bash
make lint-overlays
```

## Platform definitions

[`platforms.yaml`](platforms.yaml) is the declarative source of truth for each platform run. The configured `orgs` determine the primary repositories: `opendatahub-io` for ODH and `red-hat-data-services` for RHOAI where their platform definitions specify those organizations. `extra_orgs` and `extra_repos` add repositories outside that primary discovery set.

Use `include_components` to explicitly add a repository to the component map when normal discovery does not identify it. Use `exclude_repos` or `exclude_components` only when the repository/component should not participate in that platform's analysis. Preserve YAML anchors and shared configuration where they accurately express common platform behavior.

### Sensitive checkout content

`platforms.yaml` also controls post-checkout removal of sensitive or unnecessary source content before architecture analysis:

- Set `exclude_files` on an `extra_repos` entry for exclusions specific to that repository.
- Use a `post_checkout` rule with `repo` and `exclude_files` for a platform-wide matching repository rule.
- Patterns are relative globs. Absolute paths and paths containing `..` are invalid, and the pipeline will not remove content outside a repository checkout.

Keep exclusions as narrow as possible and explain their purpose in the pull request. They affect what the generator can inspect, so an overly broad rule can make future architecture output incomplete.

Validate configuration changes with:

```bash
make lint-platforms
```

## Pipeline and pull requests

For Python pipeline changes, use Python 3.13+ and `uv`; for Go tooling, follow the module-specific checks. Run the checks relevant to your change before opening a pull request:

```bash
make lint
make test
uv run pytest
```

Keep pull requests focused, describe the architecture fact or behavior being changed, and include links to the source, issue, or ADR that supports it. For pipeline changes, include relevant tests. Never include credentials, tokens, or sensitive source material in a contribution.
