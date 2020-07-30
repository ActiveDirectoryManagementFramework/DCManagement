# Changelog

## ???

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
