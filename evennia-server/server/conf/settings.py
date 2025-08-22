r"""
Evennia settings file.

The available options are found in the default settings file found
here:

https://www.evennia.com/docs/latest/Setup/Settings-Default.html

Remember:

Don't copy more from the default file than you actually intend to
change; this will make sure that you don't overload upstream updates
unnecessarily.

When changing a setting requiring a file system path (like
path/to/actual/file.py), use GAME_DIR and EVENNIA_DIR to reference
your game folder and the Evennia library folders respectively. Python
paths (path.to.module) should be given relative to the game's root
folder (typeclasses.foo) whereas paths within the Evennia library
needs to be given explicitly (evennia.foo).

If you want to share your game dir, including its settings, you can
put secret game- or server-specific settings in secret_settings.py.

"""

# Use the defaults from Evennia unless explicitly overridden
from evennia.settings_default import *

######################################################################
# Evennia base server config
######################################################################

# Core identity
SERVERNAME = "Theatre of the Mind"
# Short one-sentence blurb describing your game. Shown under the title
# on the website and could be used in online listings of your game etc.
GAME_SLOGAN = "Classic adventures, remixed."

# Controls whether new account registration is available.
# Set to False to lock down the registration page and the create account command.
NEW_ACCOUNT_REGISTRATION_ENABLED = False
# Activate telnet service
TELNET_ENABLED = False

######################################################################
# Evennia pluggable modules
######################################################################

# On a multi-match when search objects or commands, the user has the
# ability to search again with an index marker that differentiates
# the results. If multiple "box" objects
# are found, they can by default be separated as 1-box, 2-box. Below you
# can change the regular expression used. The regex must have one
# have two capturing groups (?P<number>...) and (?P<name>...) - the default
# parser expects this. It should also involve a number starting from 1.
# When changing this you must also update SEARCH_MULTIMATCH_TEMPLATE
# to properly describe the syntax.
SEARCH_MULTIMATCH_REGEX = r"(?P<number>[0-9]+)-(?P<name>[^-]*)(?P<args>.*)"
# To display multimatch errors in various listings we must display
# the syntax in a way that matches what SEARCH_MULTIMATCH_REGEX understand.
# The template will be populated with data and expects the following markup:
# {number} - the order of the multimatch, starting from 1; {name} - the
# name (key) of the multimatched entity; {aliases} - eventual
# aliases for the entity; {info} - extra info like #dbrefs for staff. Don't
# forget a line break if you want one match per line.
SEARCH_MULTIMATCH_TEMPLATE = " {number}-{name}{aliases}{info}\n"

# Use the contrib’s connection-screen texts to drive the menu-based login.
# (You can later point this to your own module if you want a custom banner.)
CONNECTION_SCREEN_MODULE = "evennia.contrib.base_systems.menu_login.connection_screens"

######################################################################
# Default command sets and commands
######################################################################

# Use the menu-based login flow for sessions before an account has logged in.
# This replaces the default unlogged-in cmdset with the contrib’s version.
CMDSET_UNLOGGEDIN = "evennia.contrib.base_systems.menu_login.UnloggedinCmdSet"

######################################################################
# Default Account setup and access
######################################################################

# Different Multisession modes allow a player (=account) to connect to the
# game simultaneously with multiple clients (=sessions).
#  0 - single session per account (if reconnecting, disconnect old session)
#  1 - multiple sessions per account, all sessions share output
#  2 - multiple sessions per account, one session allowed per puppet
#  3 - multiple sessions per account, multiple sessions per puppet (share output)
#      session getting the same data.
MULTISESSION_MODE = 2
# Whether we should create a character with the same name as the account when
# a new account is created. Together with AUTO_PUPPET_ON_LOGIN, this mimics
# a legacy MUD, where there is no difference between account and character.
AUTO_CREATE_CHARACTER_WITH_ACCOUNT = False
# Whether an account should auto-puppet the last puppeted puppet when logging in. This
# will only work if the session/puppet combination can be determined (usually
# MULTISESSION_MODE 0 or 1), otherwise, the player will end up OOC. Use
# MULTISESSION_MODE=0, AUTO_CREATE_CHARACTER_WITH_ACCOUNT=True and this value to
# mimic a legacy mud with minimal difference between Account and Character. Disable
# this and AUTO_PUPPET to get a chargen/character select screen on login.
AUTO_PUPPET_ON_LOGIN = False
# How many *different* characters an account can puppet *at the same time*. A value
# above 1 only makes a difference together with MULTISESSION_MODE > 1.
MAX_NR_SIMULTANEOUS_PUPPETS = 1
# The maximum number of characters allowed by be created by the default ooc
# char-creation command. This can be seen as how big of a 'stable' of characters
# an account can have (not how many you can puppet at the same time). Set to
# None for no limit.
MAX_NR_CHARACTERS = 5


######################################################################
# Settings given in secret_settings.py override those in this file.
######################################################################
try:
    from server.conf.secret_settings import *
except ImportError:
    print("secret_settings.py file not found or failed to import.")
