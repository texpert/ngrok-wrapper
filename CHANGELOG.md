# Changelog

## [v0.3.1](https://github.com/texpert/ngrok-wrapper/tree/v0.3.1) (2024-08-25)

[Full Changelog](https://github.com/texpert/ngrok-wrapper/compare/v0.3.0...v0.3.1)

### Maintenance release

Ruby, Rubocop, and CI upgrades

**Closed issues:**

- Config error with Ngrok v3.3.3 [\#31](https://github.com/texpert/ngrok-wrapper/issues/31)
- The ngrok agent \(v3\) only accepts long name flags prefixed with -- and will error if a single hyphen is used [\#20](https://github.com/texpert/ngrok-wrapper/issues/20)

**Merged pull requests:**

- Upgrade paambaati/codeclimate-action to version 9 [\#34](https://github.com/texpert/ngrok-wrapper/pull/34) ([texpert](https://github.com/texpert))
- Upgrade actions/checkout to version 4 [\#33](https://github.com/texpert/ngrok-wrapper/pull/33) ([texpert](https://github.com/texpert))
- Restrict Ruby minimal version to 3.1 [\#32](https://github.com/texpert/ngrok-wrapper/pull/32) ([texpert](https://github.com/texpert))
- Bump actions/checkout to 3.5.0 [\#30](https://github.com/texpert/ngrok-wrapper/pull/30) ([texpert](https://github.com/texpert))
- Bump actions/checkout to 3.3.0 [\#29](https://github.com/texpert/ngrok-wrapper/pull/29) ([texpert](https://github.com/texpert))
- Bump main Ruby version to 2.7.7 [\#28](https://github.com/texpert/ngrok-wrapper/pull/28) ([texpert](https://github.com/texpert))
- Fix Code Climate issues [\#27](https://github.com/texpert/ngrok-wrapper/pull/27) ([texpert](https://github.com/texpert))

## [v0.3.0](https://github.com/texpert/ngrok-wrapper/tree/v0.3.0) (2022-11-19)

[Full Changelog](https://github.com/texpert/ngrok-wrapper/compare/v0.2.0...v0.3.0)

### Both Ngrok v2, and v3 are now supported.

Tested and working on Ubuntu Linux and macOS.

**Merged pull requests:**

- Added compatibility with Ngrok v3.x \(specs also enhanced to test both 2 and 3 versions\) [\#24](https://github.com/texpert/ngrok-wrapper/pull/24) ([texpert](https://github.com/texpert))
- Prepare for different ngrok versions params, still for version 2 [\#23](https://github.com/texpert/ngrok-wrapper/pull/23) ([texpert](https://github.com/texpert))
- Allow region subdomains - modify Rails config.hosts example to parse the host from NGROK\_URL [\#22](https://github.com/texpert/ngrok-wrapper/pull/22) ([texpert](https://github.com/texpert))
- Set main Ruby version to 2.7.6 [\#21](https://github.com/texpert/ngrok-wrapper/pull/21) ([texpert](https://github.com/texpert))
- Bump actions/checkout from 2 to 3 [\#19](https://github.com/texpert/ngrok-wrapper/pull/19) ([texpert](https://github.com/texpert))

## [v0.2.0](https://github.com/texpert/ngrok-wrapper/tree/v0.2.0) (2022-02-19)

[Full Changelog](https://github.com/texpert/ngrok-wrapper/compare/v0.1.0...v0.2.0)

### Making Ngrok process survive server stop on Linux

It was working OK on Mac OS on the 0.1.0 release, but not on Linux.

It came out that `Process.setsid` should be applied to the spawned process to establish this process as a new session 
and process group leader. This is completely detaching it from the parent process, so it won't be killed when the 
parent will go down.


**Merged pull requests:**

- Add config.hosts example for Rails \>= 6.0.0 [\#18](https://github.com/texpert/ngrok-wrapper/pull/18) ([texpert](https://github.com/texpert))
- Ngrok.start should try to return first @ngrok\_url\_https or then @ngrok\_url [\#17](https://github.com/texpert/ngrok-wrapper/pull/17) ([texpert](https://github.com/texpert))
- Use fork, Process.setsid and spawn instead of just spawn, to change the owner of ngrok process [\#16](https://github.com/texpert/ngrok-wrapper/pull/16) ([texpert](https://github.com/texpert))

## [v0.1.0](https://github.com/texpert/ngrok-wrapper/tree/v0.1.0) (2022-01-09)

[Full Changelog](https://github.com/texpert/ngrok-wrapper/compare/3e032fa019c91ee7338a7ad3a3335e6c5597b394...v0.1.0)

**Merged pull requests:**

- Added `github_changelog_generator` to the gemspec [\#14](https://github.com/texpert/ngrok-wrapper/pull/14) ([texpert](https://github.com/texpert))
- Described gem's usage in Rails, move the description from `examples` folder into README.md [\#13](https://github.com/texpert/ngrok-wrapper/pull/13) ([texpert](https://github.com/texpert))
- Fix Codeclimate rubocop channel to beta to enable latest 1-24-1 [\#11](https://github.com/texpert/ngrok-wrapper/pull/11) ([texpert](https://github.com/texpert))
- Add codeclimate fixme and rubocop plugins [\#10](https://github.com/texpert/ngrok-wrapper/pull/10) ([texpert](https://github.com/texpert))
- Decompose `fetch_urls` for maintainability [\#9](https://github.com/texpert/ngrok-wrapper/pull/9) ([texpert](https://github.com/texpert))
- Refactor `ngrok_running?` to re-use `ngrok_process_status_lines` instead of a shell process [\#8](https://github.com/texpert/ngrok-wrapper/pull/8) ([texpert](https://github.com/texpert))
- Raise if Ngrok with the pid from persistence file is running on other port [\#7](https://github.com/texpert/ngrok-wrapper/pull/7) ([texpert](https://github.com/texpert))
- Refactor DRYing `ngrok_exec_params` method [\#6](https://github.com/texpert/ngrok-wrapper/pull/6) ([texpert](https://github.com/texpert))
- Remove redundant methods and introduce `:params` read accessor [\#5](https://github.com/texpert/ngrok-wrapper/pull/5) ([texpert](https://github.com/texpert))
- Don't forget to close the log file and don't use returns in a block [\#4](https://github.com/texpert/ngrok-wrapper/pull/4) ([texpert](https://github.com/texpert))
- Fix CI setup-ruby action to use Ruby version from strategy matrix [\#3](https://github.com/texpert/ngrok-wrapper/pull/3) ([texpert](https://github.com/texpert))
- Fix CodeClimate issue Class Wrapper has 22 methods \(exceeds 20 allowed\) [\#2](https://github.com/texpert/ngrok-wrapper/pull/2) ([texpert](https://github.com/texpert))
- Fix the specs to avoid trying to run real Ngrok when testing using fixture log files [\#1](https://github.com/texpert/ngrok-wrapper/pull/1) ([texpert](https://github.com/texpert))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
