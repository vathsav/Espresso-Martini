# CHANGELOG
All notable changes to this project will be documented in this file. To know better on how to write and maintain a changelog, refer to [this link](https://keepachangelog.com/en/1.0.0/).
Releases will be named after famous illusionists.

## [1.2.0] - Harry Houdini

### Added
- Support for `retries` and `polling` by associating an array of answers to the single request. [#13](https://github.com/TheInkedEngineer/Espresso-Martini/pull/13)
- A new printing layout for CLI's `endpoints` command.[#14](https://github.com/TheInkedEngineer/Espresso-Martini/pull/14)

### Deprecated
- `delay` under `MockServer.NetworkExchange` has been moved under `MockServer.Response` to allow each response to decide how long it should take before it's returned.

### Removed
- `--verbose` flag as it was redundant with the new printing layout.[#14](https://github.com/TheInkedEngineer/Espresso-Martini/pull/14)

## [1.1.0] - Harry Houdini

### Added
- Possibility to add a global delay to all requests [#3](https://github.com/TheInkedEngineer/Espresso-Martini/pull/3)
- Possibility to add a delay on a per-networkExchange basis (will override global delay) [#5](https://github.com/TheInkedEngineer/Espresso-Martini/pull/5)
- `MockServer.Configuration` -- a concrete implementation of `ServerConfigurationProvider`.[#7](https://github.com/TheInkedEngineer/Espresso-Martini/pull/7)
- Support to run the server from the command line using `espressomartini run`[#7](https://github.com/TheInkedEngineer/Espresso-Martini/pull/7)
- Support to configure the server parameters from the CLI using `--configuration` argument[#7](https://github.com/TheInkedEngineer/Espresso-Martini/pull/7)
- Support for installing CLI via [Make](https://www.gnu.org/software/make/)[#7](https://github.com/TheInkedEngineer/Espresso-Martini/pull/7)
- Support to list all valid endpoints from the command line using `espressomartini endpoints`[#8](https://github.com/TheInkedEngineer/Espresso-Martini/pull/8)
- Support to get detailed information of the endpoints using the `--verbose` flag.[#8](https://github.com/TheInkedEngineer/Espresso-Martini/pull/8)
- Possibility to choose the level of information to print in the console. [#11](https://github.com/TheInkedEngineer/Espresso-Martini/pull/11)

### Deprecated
- `SimpleConfigurationProvider` has been renamed `MockServer.SimpleConfiguration`

## [1.0.0] - David Copperfield

### Added
- Match requests based on method + path components
- Possibility to run a mock server for the following response types:
  - empty
  - string
  - data
  - json
  - fileContent
- Support for iOS 13+
- Support for macOS 12+
