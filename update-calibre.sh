#!/bin/bash
if which calibre; then
	wersjalocal=$(calibre --version | perl -pe 's{.*([0-9]+\.[0-9]+).*}{$1}g')

	url="http://calibre-ebook.com/download_linux"
	wersjanet=$(curl -L $url | grep 'The latest release of calibre is' | perl -pe 's{.*The latest release of calibre is ([0-9]+\.[0-9]+).*}{$1}g' )
	#echo "Remote version: $wersjanet"
	#echo "Local version: $wersjalocal"

	if [ "$wersjanet" != "$wersjalocal" ]; then
		echo "Found new wersion $wersjanet on the web. (our version: $wersjalocal)"
		wget -nv -O- https://download.calibre-ebook.com/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"
	fi
fi

