# Changelog

## 1.2.25 (2021-07-13)

- Upd: Test-DCShare - added message tag DCTarget to allow message level modifiers to raise per-server processing messages.
- Upd: Test-DCAccessRule - added message tag DCTarget to allow message level modifiers to raise per-server processing messages.
- Upd: Test-DCAccessRule - added equivalent access detection. Will no longer report about inequal access rules, so long as they result in the same effective permissions.
- Fix: Test-DCAccessRule - prompts for confirm on ToString when running in high confirm preference

## 1.2.21 (2021-04-23)

- Upd: Shares - Added capability to specify which server to process through `-TargetServer` parameter.
- Upd: AccessRules - Added capability to specify which server to process through `-TargetServer` parameter.
- Fix: Test-DCAccessRule - errors when path not found: Cannot bind null to InputObject

## 1.2.18 (2020-10-11)

- Upd: Removed most dependencies due to bug in PS5.1. Dependencies in ADMF itself are now expected to provide the necessary tools / modules.
- Upd: Incremented PSFramework minimum version.

## 1.2.17 (2020-09-11)

- Upd: Internal name resoloution update & dependency update

## 1.2.16 (2020-07-31)

- New: Component - File System Access Rules
- Upd: Install-DCChildDomain - shows context prompt when no configuration loaded yet
- Upd: Install-DCDomainController - shows context prompt when no configuration loaded yet
- Upd: Install-DCRootDomain - shows context prompt when no configuration loaded yet
- Fix: Install-DCChildDomain - does not respect Sysvol configuration / parameter
- Fix: Install-DCDomainController - does not respect Sysvol configuration / parameter
- Fix: Install-DCRootDomain - does not respect Sysvol configuration / parameter
- Fix: Install-DCDomainController - stops failing to install at all

## 1.1.8 (2020-07-03)

- Fix: Install-DCDomainController will now install the DC role correctly before trying to join itself to a domain as DC

## 1.1.7 (2020-06-21)

- New Component: Shares
- New Command: Clear-DCConfiguration

## 1.0.5 (2020-01-27)

- Metadata Update, no functional changes

## 1.0.4 (2019-12-21)

- Initial Release
