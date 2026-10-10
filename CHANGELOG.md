# Changelog

## [1.5.0](https://github.com/JakobMelchard/.github/compare/v1.4.0...v1.5.0) (2026-10-10)


### Features

* **ai-review:** add reusable PR-Agent review with a fallback model and a failing check ([#114](https://github.com/JakobMelchard/.github/issues/114)) ([15d66f6](https://github.com/JakobMelchard/.github/commit/15d66f61ce372d87ea4610cc488f2e2208feb8a2))

## [1.4.0](https://github.com/JakobMelchard/.github/compare/v1.3.0...v1.4.0) (2026-10-09)


### Features

* bot-threads gate fails while a bot review thread is unresolved ([#97](https://github.com/JakobMelchard/.github/issues/97)) ([e928afe](https://github.com/JakobMelchard/.github/commit/e928afe9859291830c8751de9d2c21d562038cdb))
* **infra:** adopt tu, drop deleted repos, manage homepages ([#100](https://github.com/JakobMelchard/.github/issues/100)) ([0a0c690](https://github.com/JakobMelchard/.github/commit/0a0c6905dd390d72d5d45151c0f517c9bf559efd))
* **infra:** declare the ai-review label ([#96](https://github.com/JakobMelchard/.github/issues/96)) ([04d5b56](https://github.com/JakobMelchard/.github/commit/04d5b56b43fdf67bc6154f590a284cc8325e8a9c))
* **infra:** manage lilfeelz/fz ([#101](https://github.com/JakobMelchard/.github/issues/101)) ([119acb4](https://github.com/JakobMelchard/.github/commit/119acb4b9b0c5addba9af6a95ffc6cbf7be38d27))
* **infra:** thread-resolution ruleset for private personal repos ([#103](https://github.com/JakobMelchard/.github/issues/103)) ([1c430a9](https://github.com/JakobMelchard/.github/commit/1c430a967651d0d019d9b9254fb2e8922046a822))
* **renovate:** automerge devDependencies and Actions minors, add release age ([#92](https://github.com/JakobMelchard/.github/issues/92)) ([df992a8](https://github.com/JakobMelchard/.github/commit/df992a886b29337a09252fcd3674dded77033913))
* **shell:** runs-on input picks the runner for every job ([#93](https://github.com/JakobMelchard/.github/issues/93)) ([52b4ca4](https://github.com/JakobMelchard/.github/commit/52b4ca48121805fe15a0a7fccc604fb2c6797a5f))


### Bug Fixes

* **hooks:** prettier and eslint skip with a notice when the repo has no ([d719f4a](https://github.com/JakobMelchard/.github/commit/d719f4a1773498b9e015b4bc5017baee043d5316))
* **infra:** protect dev from deletion in workspaces and .config ([#104](https://github.com/JakobMelchard/.github/issues/104)) ([be874d2](https://github.com/JakobMelchard/.github/commit/be874d2d33bd4f7f8921855b5541487b1e6a72c8))
* **infra:** turn on vulnerability alerts before dependabot security updates ([#102](https://github.com/JakobMelchard/.github/issues/102)) ([3f5c6de](https://github.com/JakobMelchard/.github/commit/3f5c6de7e17cfa5107a7f004189b99540b99c2aa))
* **routines:** run repository checks without GH_TOKEN ([#109](https://github.com/JakobMelchard/.github/issues/109)) ([fb10e85](https://github.com/JakobMelchard/.github/commit/fb10e85bafde86b4c524303e0454753c2bdb1578))

## [1.3.0](https://github.com/JakobMelchard/.github/compare/v1.2.0...v1.3.0) (2026-10-04)


### ⚠ BREAKING CHANGES

* drop actions/hooks, run this repo's hooks through prek ([#26](https://github.com/JakobMelchard/.github/issues/26))

### Features

* **actions:** code-changed, whether a change is more than Markdown ([#77](https://github.com/JakobMelchard/.github/issues/77)) ([26b6918](https://github.com/JakobMelchard/.github/commit/26b69187175306ec36a8a82cfdd9e93c27d79946))
* **ci:** reusable xcode workflow for iOS apps ([#19](https://github.com/JakobMelchard/.github/issues/19)) ([af66e47](https://github.com/JakobMelchard/.github/commit/af66e47915d145dbb03b1f43144b0a736239a072))
* docs action, markdown to pages in the docs.melchard.org shell ([#64](https://github.com/JakobMelchard/.github/issues/64)) ([bd0525d](https://github.com/JakobMelchard/.github/commit/bd0525d5c16bbaec80811d2fc3603f3ecd7b8420))
* dormant opencode fallback for the nightly routines ([#71](https://github.com/JakobMelchard/.github/issues/71)) ([203daa8](https://github.com/JakobMelchard/.github/commit/203daa87a026c9f9dea09f2eceb5687aabae2c65))
* feedback triage workflow and composite action ([#63](https://github.com/JakobMelchard/.github/issues/63)) ([b9f9382](https://github.com/JakobMelchard/.github/commit/b9f9382a08ff6002a6253b806aeedc1903f6c9df))
* **infra:** actions_can_approve_prs for personal repos ([#44](https://github.com/JakobMelchard/.github/issues/44)) ([1074207](https://github.com/JakobMelchard/.github/commit/10742079a24a656f69098a25c2ab2158ff390a0f))
* **infra:** keep Linux jobs on hosted runners, macOS on mimi ([#35](https://github.com/JakobMelchard/.github/issues/35)) ([994f2b1](https://github.com/JakobMelchard/.github/commit/994f2b15aacd7e8e0ce24c356f9d3e504aa72cd9))
* **infra:** manage lilfeelz repos and required-check rulesets ([#41](https://github.com/JakobMelchard/.github/issues/41)) ([9d1818b](https://github.com/JakobMelchard/.github/commit/9d1818b9965cbe72bc70f49793ad9cb5f61de5c7))
* **infra:** manage lilfeelz/chrome-extensions ([#75](https://github.com/JakobMelchard/.github/issues/75)) ([977412d](https://github.com/JakobMelchard/.github/commit/977412d7cdf3d36bf4320439599a21b94c903200))
* **infra:** rulesets on public repos, plan/apply CI, encrypted state ([#42](https://github.com/JakobMelchard/.github/issues/42)) ([268e9e3](https://github.com/JakobMelchard/.github/commit/268e9e374887569a049f8c5fe25cc35fe9327245))
* **infra:** sentry label for issues opened from Sentry alerts ([#74](https://github.com/JakobMelchard/.github/issues/74)) ([baef10e](https://github.com/JakobMelchard/.github/commit/baef10e5ae52ef930c1cb941be13d9ce260b5ced))
* nightly cloud routines and the agent:cloud label ([#69](https://github.com/JakobMelchard/.github/issues/69)) ([26e64c4](https://github.com/JakobMelchard/.github/commit/26e64c4e5fb0d3b6b2ddd4710a13faebe4b7d922))
* permanent interaction limits, feedback triage only for collaborators ([#67](https://github.com/JakobMelchard/.github/issues/67)) ([2145c1a](https://github.com/JakobMelchard/.github/commit/2145c1a50897e40cc07d19becc9bc590894cb14b))
* reusable android workflow and starter ([#28](https://github.com/JakobMelchard/.github/issues/28)) ([c2ac19b](https://github.com/JakobMelchard/.github/commit/c2ac19b848cb2a2464c2c4e8f886f72172e4e066))
* reusable prek workflow, Renovate pre-commit manager, public .githooks ([#23](https://github.com/JakobMelchard/.github/issues/23)) ([d201055](https://github.com/JakobMelchard/.github/commit/d201055eab036576c5cda6009b551f433a77cb7e))
* **routines-fallback:** read check runs and workflow runs ([#72](https://github.com/JakobMelchard/.github/issues/72)) ([2a4b0fb](https://github.com/JakobMelchard/.github/commit/2a4b0fbd307d70413d5b2224b9a4bd2f35e6cbf3))
* weekly grouped Renovate updates ([#68](https://github.com/JakobMelchard/.github/issues/68)) ([51d5edd](https://github.com/JakobMelchard/.github/commit/51d5edd4b90abe6d73b49d977855a32502e4f01c))
* **xcode:** clone public sibling repos; swiftkit becomes public ([#27](https://github.com/JakobMelchard/.github/issues/27)) ([9f07fa0](https://github.com/JakobMelchard/.github/commit/9f07fa0f3a6e80fc1fba30e50cdcbaa5bb49dd69))


### Bug Fixes

* **ci:** route drill, agenx, content and android jobs to Blacksmith ([#86](https://github.com/JakobMelchard/.github/issues/86)) ([4e68f98](https://github.com/JakobMelchard/.github/commit/4e68f98b2ec564f25d63d050e7e7a12d513ea56f))
* **infra:** keep cf's dev branch when the promotion PR merges ([#85](https://github.com/JakobMelchard/.github/issues/85)) ([27afef4](https://github.com/JakobMelchard/.github/commit/27afef417d644e8a6e28ce8b55140cb0765c8238))
* **infra:** keyboard required checks that actually report ([#65](https://github.com/JakobMelchard/.github/issues/65)) ([1f1af34](https://github.com/JakobMelchard/.github/commit/1f1af347ec099af70b6682a30e886b4f5b833fc7))
* **infra:** make tofu plan succeed: skip archived repos, sync settings with GitHub ([#24](https://github.com/JakobMelchard/.github/issues/24)) ([17045ea](https://github.com/JakobMelchard/.github/commit/17045eaa101fc8f5b0947e205c6033e682f3db82))
* **infra:** request auto-merge only on public repos ([#25](https://github.com/JakobMelchard/.github/issues/25)) ([03a702a](https://github.com/JakobMelchard/.github/commit/03a702af55aa3472064aca04185f4b629b9719a0))
* **shell:** syntax-check zsh scripts whose shebang has arguments ([#45](https://github.com/JakobMelchard/.github/issues/45)) ([a03b66e](https://github.com/JakobMelchard/.github/commit/a03b66e890218db9ccd44e6cb2e2747941eadfdb))
* **xcode:** create the destination simulator when the runner has none ([#30](https://github.com/JakobMelchard/.github/issues/30)) ([238de31](https://github.com/JakobMelchard/.github/commit/238de31d86432ae352279a264db3facd334deb78))


### Miscellaneous Chores

* drop actions/hooks, run this repo's hooks through prek ([#26](https://github.com/JakobMelchard/.github/issues/26)) ([56a4c9d](https://github.com/JakobMelchard/.github/commit/56a4c9d4225a0c55868b7ede529d42b55534fa9f))
* release 1.3.0 ([25a169b](https://github.com/JakobMelchard/.github/commit/25a169b26d71fb7c1774eea1b0362a23abdfc68b))

## [1.2.0](https://github.com/JakobMelchard/.github/compare/v1.1.0...v1.2.0) (2026-09-27)


### Features

* **release:** release PRs authored by the org app so CI runs on them ([fd5158e](https://github.com/JakobMelchard/.github/commit/fd5158ef11bbccc1114cd2b9a0d94f1dc0ed93b7))

## [1.1.0](https://github.com/JakobMelchard/.github/compare/v1.0.0...v1.1.0) (2026-09-27)


### Features

* **ci:** conventional PR titles and workflow provenance in every reusable workflow ([7688236](https://github.com/JakobMelchard/.github/commit/7688236eae4e2a6b615b672ddbabcb1c7298f8f5))
* org community files, declared labels, public Renovate preset ([49ab337](https://github.com/JakobMelchard/.github/commit/49ab33701c00019cbc3c28e577582ba8cdfb080d))
* self release with immutable tags, weekly fleet-sync, auto starter workflow ([7603faa](https://github.com/JakobMelchard/.github/commit/7603faa86acc6a7b89c9144642e90719e388e108))
