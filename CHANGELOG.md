# Changelog

## [2.2.0](https://github.com/JakobMelchard/.github/compare/v2.1.0...v2.2.0) (2026-10-14)


### Features

* **ai-review:** accept the model key as an optional secret ([#205](https://github.com/JakobMelchard/.github/issues/205)) ([d69182e](https://github.com/JakobMelchard/.github/commit/d69182ee878519a9aad85c28d5dddf5734370fdb))


### Bug Fixes

* **ci:** keep private-deps git credentials in the job env ([#190](https://github.com/JakobMelchard/.github/issues/190)) ([0e037dd](https://github.com/JakobMelchard/.github/commit/0e037ddd4189a26d155ffc1dad29e27191b2b2b2))
* **release:** load only the app secrets from Infisical ([#191](https://github.com/JakobMelchard/.github/issues/191)) ([ce72cb4](https://github.com/JakobMelchard/.github/commit/ce72cb4a8b9aa9f0f38b734b3aea6a51ecbfcf7d))
* **routines:** run only when ROUTINES is on, dispatch included ([#188](https://github.com/JakobMelchard/.github/issues/188)) ([d789117](https://github.com/JakobMelchard/.github/commit/d789117b4adbc7bda69df30d63acc574e17c9c96))
* **tofu:** keep plans out of the apply concurrency group ([#189](https://github.com/JakobMelchard/.github/issues/189)) ([8153c69](https://github.com/JakobMelchard/.github/commit/8153c6903e9947b761ebbc0c6eb20aefaf075c06))
* **tofu:** plan on any change when working-directory is the repo root ([#204](https://github.com/JakobMelchard/.github/issues/204)) ([47770bd](https://github.com/JakobMelchard/.github/commit/47770bd41d62bde013c60555f083832aa495bb16))

## [2.1.0](https://github.com/JakobMelchard/.github/compare/v2.0.1...v2.1.0) (2026-10-13)


### Features

* **automerge:** squash-merge labelled PRs once checks pass ([#153](https://github.com/JakobMelchard/.github/issues/153)) ([b50d893](https://github.com/JakobMelchard/.github/commit/b50d8938f139db43b34103f8dfa0c3cd03cc93fe))


### Bug Fixes

* **actions:** keep tokens-check as a no-op for pinned callers ([#149](https://github.com/JakobMelchard/.github/issues/149)) ([83a8ba3](https://github.com/JakobMelchard/.github/commit/83a8ba3ef6322e188b4a8b50a7a31f6a8f1a2df7))
* **automerge:** merge only after two polls see the same checks ([#176](https://github.com/JakobMelchard/.github/issues/176)) ([51d6380](https://github.com/JakobMelchard/.github/commit/51d6380d9bdc79ca6f8a8160222bcaf9bbb11099))
* **automerge:** skip its own check by name; the caller grants no actions read ([#154](https://github.com/JakobMelchard/.github/issues/154)) ([3136823](https://github.com/JakobMelchard/.github/commit/3136823a60259dfcfa34f4b81623472810a67d2b))
* keep listing repos when gh fails for one ([#173](https://github.com/JakobMelchard/.github/issues/173)) ([b80becf](https://github.com/JakobMelchard/.github/commit/b80becf940098c25e99998a0e6b6b608ab9a063e))
* keep the app key and the token out of the routine agent's reach ([#169](https://github.com/JakobMelchard/.github/issues/169)) ([143fac6](https://github.com/JakobMelchard/.github/commit/143fac64b021fb2fa77d6038d31e77f91514eeea))
* no next link on unlisted docs pages, per-run temp file in shell.yml ([#175](https://github.com/JakobMelchard/.github/issues/175)) ([42259da](https://github.com/JakobMelchard/.github/commit/42259da7da1c806799b7688630974bbc4ea0eb42))
* pin code-changed in the reusable workflows to a release and test its logic ([#172](https://github.com/JakobMelchard/.github/issues/172)) ([b443d73](https://github.com/JakobMelchard/.github/commit/b443d73f06d402bbe036449d29b95ae0dec9251f))
* **tofu:** load only the secrets a PR plan needs and blank the app key before it runs ([#170](https://github.com/JakobMelchard/.github/issues/170)) ([c150dd1](https://github.com/JakobMelchard/.github/commit/c150dd1390fdf2f27a3b7f29447bc888438574e8))
* verify the gitleaks download and pin the actionlint install ([#174](https://github.com/JakobMelchard/.github/issues/174)) ([2d0256d](https://github.com/JakobMelchard/.github/commit/2d0256dd515b05888ae829eee4bfa3b1e6b562e2))

## [2.0.1](https://github.com/JakobMelchard/.github/compare/v2.0.0...v2.0.1) (2026-10-11)


### Bug Fixes

* **tofu:** retry the state push so parallel roots do not lose state ([#143](https://github.com/JakobMelchard/.github/issues/143)) ([ee42cf3](https://github.com/JakobMelchard/.github/commit/ee42cf3be7ed0f801907f86989f19280e5f2ad1a))

## [2.0.0](https://github.com/JakobMelchard/.github/compare/v1.6.0...v2.0.0) (2026-10-11)


### ⚠ BREAKING CHANGES

* drop the token secret from go, python and node ([#142](https://github.com/JakobMelchard/.github/issues/142))

### Features

* **cf:** reusable wrangler deploy for Workers with a Durable Object ([#134](https://github.com/JakobMelchard/.github/issues/134)) ([e65ef67](https://github.com/JakobMelchard/.github/commit/e65ef67c793877b9a6512de6eb5be2078f3cbe8d))
* drop the token secret from go, python and node ([#142](https://github.com/JakobMelchard/.github/issues/142)) ([df5f3ee](https://github.com/JakobMelchard/.github/commit/df5f3eeb693e350ab4b8c524c1283a4aaca13264))
* **tofu:** read a second Infisical project and map env names ([#137](https://github.com/JakobMelchard/.github/issues/137)) ([b7007fa](https://github.com/JakobMelchard/.github/commit/b7007fa8d7b234f1a5255ca50483d29b590c91d2))
* **tofu:** reusable plan, apply and encrypted state commit ([#124](https://github.com/JakobMelchard/.github/issues/124)) ([a1cd195](https://github.com/JakobMelchard/.github/commit/a1cd195ad9ac123e86b5e1954eaa701736091edc))
* workflow-templates as one-line callers ([#135](https://github.com/JakobMelchard/.github/issues/135)) ([507a794](https://github.com/JakobMelchard/.github/commit/507a794bade56a5b06a02e024f4b1d8c64b2de99))


### Bug Fixes

* simulator step and tofu token conditions ([#141](https://github.com/JakobMelchard/.github/issues/141)) ([806e63a](https://github.com/JakobMelchard/.github/commit/806e63a7d87a49bef9c12091e882754f69daed1b))

## [1.6.0](https://github.com/JakobMelchard/.github/compare/v1.5.0...v1.6.0) (2026-10-11)


### Features

* **review-label:** ai:* review labels and label-triggered cubic review ([#121](https://github.com/JakobMelchard/.github/issues/121)) ([3df05b5](https://github.com/JakobMelchard/.github/commit/3df05b5988afb7e6cf186702438e3f79e9dab893))

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
