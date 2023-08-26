# If steam is not present - exit

if ! which steam; then
  echo "Steam is not installed. Please install it first."
  exit 1
fi

# If steamcmd is not present - install it

if ! which steamcmd; then
  echo "SteamCMD is not installed. Installing..."
  sudo apt-get install debconf-utils
  echo "steam steam/question select I AGREE" | sudo /usr/bin/debconf-set-selections
  sudo apt install --yes steamcmd
fi

# If steam is not logged in - exit

if ! steamcmd +login anonymous +quit; then
  echo "Steam is not logged in. Please log in first."
  exit 1
fi

# Check if the steam_login.txt exists, and if it does read its contents into the "mylogin" variable

if [ -f steam_login.txt ]; then
  mylogin=$(cat steam_login.txt)
else
  echo "steam_login.txt not found. Please create it and put your Steam login name there as a single line."
  exit 1
fi

Found the following games:
LD_PRELOAD="" steamcmd +login $mylogin +apps_installed +quit   |grep -Po '^AppID [0-9]+(?= : ).*' | sort -V

LD_PRELOAD="" steamcmd +login $mylogin $(
  steamcmd +login $mylogin +apps_installed +quit \
  |grep -Po '(?<=^AppID )[0-9]+(?= : )' \
  |sort -V \
  |while read appid; do \
    echo +app_update "$appid"; done \
) +quit
