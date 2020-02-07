steamcmd +login anonymous +force_install_dir /opt/games/dontstarve  +app_update 343050 validate +quit


4 x 1

if which steam; then
	sudo apt-get install debconf-utils
	echo "steam steam/question select I AGREE" | sudo /usr/bin/debconf-set-selections
	sudo apt install --yes steamcmd
fi
