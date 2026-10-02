# Changelog

## [2.0.0](https://github.com/JakobMelchard/.github/compare/v1.2.0...v2.0.0) (2026-10-02)


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

* **infra:** keyboard required checks that actually report ([#65](https://github.com/JakobMelchard/.github/issues/65)) ([1f1af34](https://github.com/JakobMelchard/.github/commit/1f1af347ec099af70b6682a30e886b4f5b833fc7))
* **infra:** make tofu plan succeed: skip archived repos, sync settings with GitHub ([#24](https://github.com/JakobMelchard/.github/issues/24)) ([17045ea](https://github.com/JakobMelchard/.github/commit/17045eaa101fc8f5b0947e205c6033e682f3db82))
* **infra:** request auto-merge only on public repos ([#25](https://github.com/JakobMelchard/.github/issues/25)) ([03a702a](https://github.com/JakobMelchard/.github/commit/03a702af55aa3472064aca04185f4b629b9719a0))
* **shell:** syntax-check zsh scripts whose shebang has arguments ([#45](https://github.com/JakobMelchard/.github/issues/45)) ([a03b66e](https://github.com/JakobMelchard/.github/commit/a03b66e890218db9ccd44e6cb2e2747941eadfdb))
* **xcode:** create the destination simulator when the runner has none ([#30](https://github.com/JakobMelchard/.github/issues/30)) ([238de31](https://github.com/JakobMelchard/.github/commit/238de31d86432ae352279a264db3facd334deb78))


### Miscellaneous Chores

* drop actions/hooks, run this repo's hooks through prek ([#26](https://github.com/JakobMelchard/.github/issues/26)) ([56a4c9d](https://github.com/JakobMelchard/.github/commit/56a4c9d4225a0c55868b7ede529d42b55534fa9f))

## [1.2.0](https://github.com/JakobMelchard/.github/compare/v1.1.0...v1.2.0) (2026-09-27)


### Features

* **release:** release PRs authored by the org app so CI runs on them ([fd5158e](https://github.com/JakobMelchard/.github/commit/fd5158ef11bbccc1114cd2b9a0d94f1dc0ed93b7))

## [1.1.0](https://github.com/JakobMelchard/.github/compare/v1.0.0...v1.1.0) (2026-09-27)


### Features

* **ci:** conventional PR titles and workflow provenance in every reusable workflow ([7688236](https://github.com/JakobMelchard/.github/commit/7688236eae4e2a6b615b672ddbabcb1c7298f8f5))
* org community files, declared labels, public Renovate preset ([49ab337](https://github.com/JakobMelchard/.github/commit/49ab33701c00019cbc3c28e577582ba8cdfb080d))
* self release with immutable tags, weekly fleet-sync, auto starter workflow ([7603faa](https://github.com/JakobMelchard/.github/commit/7603faa86acc6a7b89c9144642e90719e388e108))
