# In progress
- Improve user logs scroll view
- Display results by option value, not index
- Use 12-word mnemonics for identity backups
- Compress public keys when creating new identity
- Use EnvelopePackage when packaging vote
- Fetch and store ProcessData
- Adapt app to use ProcessData flags when applicable
- Add ProcessDetails, ProcessStatus
- Hash addresses when generating EthereumWallet
- Change processMetadata filename (don't try to load legacy processes)
- Enable different ENS & Process domains
- Enable MultipleChoice voting widget
- Implement pin authentication & authentication versioning
- Implement onboarding flow
- Add common-client-lib submodule, implement backup link generation

# 0.8.16
- Fix green border for some android versions
- Display html entity descriptions
- Enable link input without camera permission for qr scan
- Enable ipfs image urls
- Implement app telemetry
- Fix bootnode url changing

# 0.8.15
- Fix poll option padding
- Periodically update process dates + info
- Display spinner when refreshing dates
- Cache BlockStatus for date estimations
- Fix hidden process bug

# 0.8.14
- Fix network initialization erro
- Fix notification linking
- Enable in-app notifications

# 0.8.13

- Fix wrong-language feedback message when selecting new language
- Implement rich text process + question descriptions
- Fix single-user census
- Tweak tab bar UI
- Implement non-blocking startup
- Add registration with manual link input
- Add account selection when following deeplinks
- Add settings view
- Add bootnode URL configuration from app
- Enable account removal

# 0.8.12

- Fix single-voter census proof ability

# 0.8.11

- Fix user ability to vote, refresh results after voting
  
# 0.8.10

- Bump ios development target
- Fix voting issue

# 0.8.9

- Importing an updated version of dvote, ensuring that JSON messages are sent exactly as they are signed

# 0.8.8

- Temporary backoff from using native crypto methods (iOS)

# 0.8.7

- Using Flutter 1.22
- Upgraded dependencies

# 0.8.6

- Adding push notification support
- Allowing to choose the UI language
- Allow to persist UI settings

# 0.8.5

- Using native symmetric encryption
- Using HTTP gateway connections instead of Web Sockets
- Improving the refresh of UI data
