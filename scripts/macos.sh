#!/usr/bin/env bash
###############################################################################
# macOS System Preferences
###############################################################################
# Sets macOS defaults and preferences
# Based on: https://github.com/mathiasbynens/dotfiles
#
# IMPORTANT: Some changes require logout/restart to take effect
#
# Validated for: macOS 26.1 (Tahoe)
# Previous validation: macOS 15.7 (Sequoia)
#
# Last synced with system: 2025-11-26
# All preference values in this script match the current system configuration.
#
# Note: Safari and Mail are containerized apps in modern macOS.
#       Their preferences may require the apps to be closed first,
#       or may need to be set through the apps' UI instead.
###############################################################################

set -e

optional_failures=()
run_optional() {
  local command_output
  if command_output=$("$@" 2>&1); then
    return 0
  else
    optional_failures+=("$*")
    printf '  ⚠️  Could not apply: %s\n' "$*" >&2
    if [[ -n "$command_output" ]]; then
      printf '      %s\n' "$command_output" >&2
    fi
  fi
}

# Save preference snapshots before making any changes. These are reference
# snapshots, not an automatic rollback of every setting in this script.
now=$(date -u "+%Y-%m-%d-%H%M%S")
backup_file=$(mktemp "$HOME/Desktop/macos-defaults-$now.XXXXXX") || {
  printf '❌ Could not create a defaults snapshot on the Desktop. No preferences changed.\n' >&2
  exit 1
}
power_backup_file=$(mktemp "$HOME/Desktop/macos-power-$now.XXXXXX") || {
  rm -f "$backup_file"
  printf '❌ Could not create a power settings snapshot on the Desktop. No preferences changed.\n' >&2
  exit 1
}
if ! defaults read >"$backup_file" || ! pmset -g custom >"$power_backup_file"; then
  rm -f "$backup_file" "$power_backup_file"
  printf '❌ Could not save defaults or power settings. No preferences changed.\n' >&2
  exit 1
fi
printf '📦 Saved preference snapshots:\n   %s\n   %s\n\n' "$backup_file" "$power_backup_file"

# Close apps after the snapshots succeed.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || \
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
killall Safari 2>/dev/null || true
killall Mail 2>/dev/null || true

printf "⚙️  Applying macOS preferences...\n\n"

###############################################################################
# General UI/UX                                                               #
###############################################################################

printf "  → General UI/UX settings\n"

# Enable dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Set accent color to Blue (4 = Blue, default macOS)
defaults write NSGlobalDomain AppleAccentColor -int 4

# Set highlight color to Blue
defaults write NSGlobalDomain AppleHighlightColor -string \
  "0.698039 0.843137 1.000000 Blue"

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk by default, instead of iCloud (commented out - keeping system default)
# defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Display ASCII control characters using caret notation
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
run_optional sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

###############################################################################
# Menu Bar Items                                                              #
###############################################################################

printf "  → Menu bar settings\n"

# Show Wi-Fi in menu bar (macOS 11+)
defaults write com.apple.controlcenter "NSStatusItem Visible WiFi" -bool true

# Always show Wi-Fi in menu bar (18=always show, 17=when active, 16=don't show)
defaults write com.apple.controlcenter WiFi -int 18

# Show Bluetooth in menu bar (macOS 11+)
# defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
# defaults write com.apple.controlcenter Bluetooth -int 17

# Show Battery in menu bar (macOS 11+)
defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true

# Show Sound in menu bar (macOS 11+)
# defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true

# Show Focus/Do Not Disturb in menu bar (macOS 11+)
# defaults write com.apple.controlcenter "NSStatusItem Visible DoNotDisturb" -bool true

# Show Display brightness in menu bar (macOS 11+)
# defaults write com.apple.controlcenter "NSStatusItem Visible Display" -bool true

# Time Machine - Show in menu bar
# defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.TimeMachine" -bool true

# AirDrop
# defaults write com.apple.controlcenter "NSStatusItem Visible AirDrop" -bool true
# defaults write com.apple.controlcenter AirDrop -int 18

# Screen Mirroring
# defaults write com.apple.controlcenter "NSStatusItem Visible ScreenMirroring" -bool true

# Now Playing (Music controls)
# defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying" -bool true

# Accessibility Shortcuts
# defaults write com.apple.controlcenter "NSStatusItem Visible AccessibilityShortcuts" -bool true

# Keyboard Brightness
# defaults write com.apple.controlcenter "NSStatusItem Visible KeyboardBrightness" -bool true

# User Switcher (Fast User Switching)
# defaults write com.apple.controlcenter "NSStatusItem Visible UserSwitcher" -bool true

###############################################################################
# Localization & Formats                                                      #
###############################################################################

printf "  → Localization settings\n"

# Use metric units (commented out - already using system defaults)
# defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
# defaults write NSGlobalDomain AppleMetricUnits -bool true
# defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"

# Set menu bar clock to digital (not analog)
defaults write com.apple.menuextra.clock IsAnalog -bool false

# Set menu bar clock format to show weekday, date, and time
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d h:mm a"

# Set the timezone (see `sudo systemsetup -listtimezones` for other values)
# sudo systemsetup -settimezone "America/New_York" >/dev/null

###############################################################################
# Keyboard, Mouse, & Trackpad                                                 #
###############################################################################

printf "  → Keyboard, mouse, and trackpad settings\n"

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable period substitution (double-space to period)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable automatic spelling correction
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set keyboard repeat rate to fastest (2)
defaults write NSGlobalDomain KeyRepeat -int 2

# Set delay until key repeat to shortest (15)
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable "natural" scrolling (commented out - keeping system default)
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Enable full keyboard access for all controls (enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Enable tap to click on trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Enable tap to click for this user
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable tap to click on login screen
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

###############################################################################
# Screen & Energy Saving                                                      #
###############################################################################

printf "  → Screen and energy settings\n"

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1

# Set password prompt delay to zero seconds
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# Energy saving settings
# Enable lid wake on all power sources
run_optional sudo pmset -a lidwake 1

# Restart automatically on power loss
run_optional sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
run_optional sudo systemsetup -setrestartfreeze on

# Set display sleep to 15 minutes on all power sources
run_optional sudo pmset -a displaysleep 15

# Never sleep when connected to power adapter
run_optional sudo pmset -c sleep 0

# Sleep after 5 minutes on battery power
run_optional sudo pmset -b sleep 5

# Set standby delay to 24 hours (86400 seconds)
run_optional sudo pmset -a standbydelay 86400

# Disable hibernation (speeds up sleep)
run_optional sudo pmset -a hibernatemode 0

###############################################################################
# Finder                                                                      #
###############################################################################

printf "  → Finder settings\n"

# Set home directory as default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# Set home directory path for new Finder windows
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Show external hard drives on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# Show internal hard drives on desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

# Show mounted servers on desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

# Show removable media on desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Show hidden files by default (commented out - keeping system default: false)
# defaults write com.apple.finder AppleShowAllFiles -bool true

# Prefer Finder tabs when opening documents
defaults write NSGlobalDomain AppleWindowTabbingMode -string "always"

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use column view in all Finder windows by default (matching current system)
# Four-letter codes: `icnv` (icon), `clmv` (column), `glyv` (gallery), `Nlsv` (list)
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Avoid creating .DS_Store files on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Enable AirDrop over Ethernet and on unsupported Macs
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# Enable snap-to-grid for desktop icons
run_optional /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Enable Desktop Stacks grouped by Kind
defaults write com.apple.finder DesktopViewSettings -dict GroupBy Kind

# Enable snap-to-grid for standard icon views
run_optional /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Enable snap-to-grid for all icon views
run_optional /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Set icon grid spacing to 100 for desktop
run_optional /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Set icon grid spacing to 100 for standard views
run_optional /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Set icon grid spacing to 100 for all icon views
run_optional /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Expand File Info panes: "General", "Open with", and "Sharing & Permissions"
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true

###############################################################################
# Window Management                                                           #
###############################################################################

printf "  → Window management settings\n"

# Disable "click wallpaper to show desktop" (macOS Sonoma 14.0+)
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# Enable window tiling (macOS Sequoia 15.0+)
# This controls both menu bar (fill screen) and edge (tile left/right) behaviors
# Note: Separate controls for menu bar vs edges are not publicly documented
defaults write com.apple.WindowManager GloballyEnabled -bool false

# Enable tiled window margins (spacing between tiled windows, macOS Sequoia 15.0+)
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool true

# Set application window grouping behavior (macOS Sonoma 14.0+)
# 0 = Group by application, 1 = Group by most recently used
defaults write com.apple.WindowManager AppWindowGroupingBehavior -int 0

###############################################################################
# Dock, Dashboard, & Mission Control                                          #
###############################################################################

printf "  → Dock, Dashboard, and Mission Control settings\n"

# Auto-hide menu bar (commented out - keeping system default: false)
# defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Change minimize/maximize window effect (matching current system: scale)
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Enable highlight hover effect for grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Wipe default macOS app icons from the Dock (commented out - keeping current Dock apps)
# Useful for setting up new Macs
# defaults write com.apple.dock persistent-apps -array

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Group windows by application in Mission Control
defaults write com.apple.dock expose-group-by-app -bool true

# Dashboard preferences removed (deprecated since macOS Catalina 10.15)
# Dashboard no longer exists in modern macOS

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Remove the animation when hiding/showing the Dock
# defaults write com.apple.dock autohide-time-modifier -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock screen

# Set top right screen corner to show Desktop
defaults write com.apple.dock wvous-tr-corner -int 4

# Set top right screen corner modifier to none
defaults write com.apple.dock wvous-tr-modifier -int 0

# Set bottom right screen corner to Mission Control
defaults write com.apple.dock wvous-br-corner -int 2

# Set bottom right screen corner modifier to none
defaults write com.apple.dock wvous-br-modifier -int 0

# Set bottom left screen corner to no action
defaults write com.apple.dock wvous-bl-corner -int 0

# Set bottom left screen corner modifier to none
defaults write com.apple.dock wvous-bl-modifier -int 0

# Reset Launchpad (commented out - can cause unexpected layout changes)
# find "${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete 2>/dev/null || true

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

printf "  → Safari settings\n"

# Note: Safari is a containerized app. These preferences may require Safari
# to be closed first, or may need to be set through Safari's preferences UI.
# The commands will attempt to set preferences but may show warnings.

# Disable universal search (don't send search queries to Apple)
run_optional defaults write com.apple.Safari UniversalSearchEnabled -bool false

# Suppress Safari search suggestions
run_optional defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Show the full URL in the address bar
run_optional defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Prevent Safari from opening 'safe' files automatically after downloading
run_optional defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Enable the Develop menu and the Web Inspector
run_optional defaults write com.apple.Safari IncludeDevelopMenu -bool true
run_optional defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
run_optional defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Warn about fraudulent websites
run_optional defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Update extensions automatically
run_optional defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Mail                                                                        #
###############################################################################

printf "  → Mail settings\n"

# Note: Mail is a containerized app. These preferences may require Mail
# to be closed first, or may need to be set through Mail's preferences UI.
# The commands will attempt to set preferences but may show warnings.

# Copy addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>`
run_optional defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Disable send and reply animations
run_optional defaults write com.apple.mail DisableReplyAnimations -bool true
run_optional defaults write com.apple.mail DisableSendAnimations -bool true

# Most recent first in conversations
run_optional defaults write com.apple.mail ConversationViewSortDescending -bool true

# Disable inline attachments (show icons only)
run_optional defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# Compose mail in plain-text
run_optional defaults write com.apple.mail SendFormat Plain

# Disable remote content
run_optional defaults write com.apple.mail DisableURLLoading -bool true

###############################################################################
# Spotlight                                                                   #
###############################################################################

printf "  → Spotlight settings\n"

# Set spotlight indexing order and disable some categories
defaults write com.apple.spotlight orderedItems -array \
  '{"enabled" = 1;"name" = "APPLICATIONS";}' \
  '{"enabled" = 1;"name" = "MENU_CONVERSION";}' \
  '{"enabled" = 1;"name" = "MENU_DEFINITION";}' \
  '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
  '{"enabled" = 1;"name" = "DIRECTORIES";}' \
  '{"enabled" = 1;"name" = "DOCUMENTS";}' \
  '{"enabled" = 1;"name" = "PDF";}' \
  '{"enabled" = 0;"name" = "FONTS";}' \
  '{"enabled" = 0;"name" = "MESSAGES";}' \
  '{"enabled" = 0;"name" = "CONTACT";}' \
  '{"enabled" = 0;"name" = "EVENT_TODO";}' \
  '{"enabled" = 0;"name" = "IMAGES";}' \
  '{"enabled" = 0;"name" = "BOOKMARKS";}' \
  '{"enabled" = 0;"name" = "MUSIC";}' \
  '{"enabled" = 0;"name" = "MOVIES";}' \
  '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
  '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
  '{"enabled" = 0;"name" = "SOURCE";}' \
  '{"enabled" = 0;"name" = "MENU_OTHER";}' \
  '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
  '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
  '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

###############################################################################
# Terminal & iTerm2                                                           #
###############################################################################

printf "  → Terminal and iTerm2 settings\n"

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Don't display the annoying prompt when quitting iTerm
# Note: iTerm2 preference will be set if the app is installed.
# If not installed, this command will succeed but have no effect until the app is installed.
run_optional defaults write com.googlecode.iterm2 PromptOnQuit -bool false

###############################################################################
# Time Machine                                                                #
###############################################################################

printf "  → Time Machine settings\n"

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

printf "  → Activity Monitor settings\n"

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# TextEdit                                                                    #
###############################################################################

printf "  → TextEdit settings\n"

# Use plain text mode for new documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

###############################################################################
# Photos                                                                      #
###############################################################################

printf "  → Photos settings\n"

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Mac App Store                                                               #
###############################################################################

printf "  → Mac App Store settings\n"

# Enable WebKit Developer Tools
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Enable automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install system data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

###############################################################################
# Google Chrome                                                               #
###############################################################################

printf "  → Google Chrome settings\n"

# Expand print dialog by default
# Note: Chrome preferences will be set if the app is installed.
# If not installed, these commands will succeed but have no effect until the app is installed.
run_optional defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
run_optional defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Transmission                                                                #
###############################################################################

printf "  → Transmission settings\n"

# Note: Transmission preferences will be set if the app is installed.
# If not installed, these commands will succeed but have no effect until the app is installed.

# General settings
run_optional defaults write org.m0k.transmission AutoSize -bool false
run_optional defaults write org.m0k.transmission AutoStartDownload -bool true
run_optional defaults write org.m0k.transmission CheckDownload -bool false
run_optional defaults write org.m0k.transmission CheckQuit -bool false
run_optional defaults write org.m0k.transmission CheckRemove -bool true
run_optional defaults write org.m0k.transmission CheckRemoveDownloading -bool true
run_optional defaults write org.m0k.transmission CheckUpload -bool false
run_optional defaults write org.m0k.transmission DeleteOriginalTorrent -bool false
run_optional defaults write org.m0k.transmission DownloadAsk -bool true
run_optional defaults write org.m0k.transmission DownloadAskManual -bool false
run_optional defaults write org.m0k.transmission DownloadAskMulti -bool false
run_optional defaults write org.m0k.transmission DownloadLocationConstant -bool false
run_optional defaults write org.m0k.transmission MagnetOpenAsk -bool false
run_optional defaults write org.m0k.transmission PlayDownloadSound -bool false
run_optional defaults write org.m0k.transmission RandomPort -bool false
run_optional defaults write org.m0k.transmission SleepPrevent -bool true
run_optional defaults write org.m0k.transmission SmallView -bool true
run_optional defaults write org.m0k.transmission SUEnableAutomaticChecks -bool false
run_optional defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool false
run_optional defaults write org.m0k.transmission WarningDonate -bool false
run_optional defaults write org.m0k.transmission WarningLegal -bool false

# Display settings
run_optional defaults write org.m0k.transmission DisplayProgressBarAvailable -bool true

# Security settings
run_optional defaults write org.m0k.transmission EncryptionRequire -bool true

# Blocklist settings
run_optional defaults write org.m0k.transmission BlocklistAutoUpdate -bool true
run_optional defaults write org.m0k.transmission BlocklistURL -string \
  "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz"

# Connection limits
run_optional defaults write org.m0k.transmission PeersTorrent -int 10
run_optional defaults write org.m0k.transmission PeersTotal -int 200

# Speed limits
run_optional defaults write org.m0k.transmission SpeedLimitDownloadLimit -int 2000
run_optional defaults write org.m0k.transmission SpeedLimitUploadLimit -int 1000

###############################################################################
# Networking                                                                  #
###############################################################################

printf "  → Networking settings\n"

# Configure Proton VPN
# Note: Proton VPN preferences will be set if the app is installed.
# If not installed, these commands will succeed but have no effect until the app is installed.
run_optional defaults write ch.protonvpn.mac AutoConnect -bool true
run_optional defaults write ch.protonvpn.mac StartMinimized -bool true
run_optional defaults write ch.protonvpn.mac StartOnBoot -bool true
run_optional defaults write ch.protonvpn.mac VpnAcceleratorEnabled -bool true

###############################################################################
# Kill/Restart affected applications                                          #
###############################################################################

if ((${#optional_failures[@]})); then
  printf '\n⚠️  %s optional settings could not be applied; see warnings above.\n\n' "${#optional_failures[@]}" >&2
else
  printf '\n✓ macOS preferences applied successfully!\n\n'
fi
printf "⚠️  Restarting affected applications...\n"

for app in "Activity Monitor" \
  "Address Book" \
  "Calendar" \
  "cfprefsd" \
  "Contacts" \
  "Dock" \
  "Finder" \
  "Google Chrome" \
  "Mail" \
  "Messages" \
  "Photos" \
  "Safari" \
  "SystemUIServer" \
  "Terminal" \
  "Transmission" \
  "iCal"; do
  killall "${app}" &>/dev/null || true
done

printf "\n✓ Done!\n\n"
printf "📝 Notes:\n"
printf "   • Some changes require logout/restart to take effect\n"
printf '   • Defaults snapshot: %s\n' "$backup_file"
printf '   • Power settings snapshot: %s\n' "$power_backup_file"
printf "   • Run 'task mac:restart:all' to restart Dock, Finder, and SystemUIServer\n\n"
