# platform components

The public platform repo owns reusable CI, development defaults and portable hook
implementations. It does not own host assignments, repository provisioning or app
runtime requirements. Private `infra` and `template`, personal machine `.config`
and personal/work `.agents` remain separate.

## preserved interfaces

`config/` publishes `@jakobmelchard/config` with the existing eslint, prettier and
tsconfig exports and peer dependencies. This move changes source location only.
`hooks/*.sh` retains every original CLI entry path. The root
`.pre-commit-hooks.yaml` retains all nine hook IDs, stages and language settings.
Existing consumers keep their original repository pins until a separately tested
migration. No original repository or tag is removed, rewritten or redirected.

## source history

The import commits include these original heads as second merge parents:

| source | imported head | destination |
| --- | --- | --- |
| `JakobMelchard/.config` | `11027f65fff42c81c4499d4da607807e734c483e` | `config/` |
| `JakobMelchard/.githooks` | `343af5978502475b523e89a594eb5e86c974eb66` | `hooks/`, root hook manifest |

Source implementations, fixtures, changelogs and licenses were copied; redundant
nested CI, release manifests, hook configuration and ignore files were omitted.
Hook test paths and source-location documentation were adapted. The package's
repository metadata points to `config/` in this repository. The import preserves
original histories and commit identities, rather than rewriting paths.

Merge the migration PR with a merge commit. Squash or rebase would discard import
parents. Merge commits are enabled in this repository; no settings change is
needed. The source tags remain in the source repositories and are not pushed here.

## independent release streams

| path | current version | future tags | artifact |
| --- | --- | --- | --- |
| `.` | 2.5.0 | `vX.Y.Z`, existing major-tag automation | reusable platform |
| `config` | 3.0.0 | `config-vX.Y.Z` | existing npm package |
| `hooks` | 2.0.1 | `hooks-vX.Y.Z` | root pre-commit manifest and scripts |

The manifest seeds existing component versions. It does not republish those
versions. Root release-please excludes `config` and `hooks` paths and retains its
original unprefixed tags. Component releases do not move platform major tags.
The root hook manifest is also a platform file; review its compatibility together
with the hooks release whenever changing hook IDs or stages.

The output helper is fetched at an immutable commit that already contains it.
It does not depend on an old release containing new code or on the caller checking
out this repo. The pin is regression-tested with `git cat-file`.

## publication and migration gates

No package, release or tag is published by this migration task. Before the first
component release, inspect the release PR for correct versions and changelogs;
imported source histories predate the existing platform 2.5.0 release.

`config-publish.yml` is manual and defaults to no staging. Enable it only after
changing the npm trusted publisher from `.config`/`publish.yml` to
`.github`/`config-publish.yml`. Dispatch on a published `config-vX.Y.Z` tag with
`stage: true`; the script rejects platform/hooks tags and version mismatches.
It stages the unchanged package identity with provenance; owner approval and 2FA
remain required before going live. Disable the source publish path at cutover so
only one repository publishes the package. Do not attempt to stage version 3.0.0
again. No npm settings are changed here.

Consumer migration comes after reviewed component releases: use npm semver for
the config package, and published `hooks-vX.Y.Z` tags from `.github` for hooks.
Do not migrate all consumer pins as part of this import. Keep originals until
consumer tests and compatibility checks have completed.

Verification: `config/scripts/consumer-test.sh`, `hooks/test/run`,
`hooks/test/portable`, `prek validate-manifest .pre-commit-hooks.yaml`, and
`bats scripts/test`. The consumer Bats test fetches the manifest from a local Git
revision through prek and checks valid and invalid shell input.
