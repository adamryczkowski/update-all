#!/bin/bash

localrmirror="/media/adam-minipc/other"
remotemirror="http://cran.us.r-project.org"
minipc=192.168.10.2

mount_smb_share "$localrmirror"

function get_home_dir {
	echo $( getent passwd "$USER" | cut -d: -f6 )
}

function get_other_folder {
	folder="$1"
	if [ -n "${folder}" ]; then
		folder="/${folder}"
	fi
	mountpoint="/media/adam-minipc/other"
	if [ -d "${mountpoint}" ]; then
		if [ ! -d "${mountpoint}${folder}" ]; then
			if ping -c 1 -w 1 ${minipc}>/dev/null; then
				mount ${mountpoint}
			fi 
		fi
		if [ -d "${mountpoint}${folder}" ]; then
			echo ${mountpoint}${folder}
		fi
	fi
	echo ""
}

function get_deb_folder {
	deb_folder=$(get_home_dir)/tmp/debs
	other_folder=$(get_other_folder debs)
	if [ -n "${other_folder}" ]; then
		echo ${other_folder}
	else
		if [ ! -d ${deb_folder} ]; then
			mkdir -p ${deb_folder}
		fi
		echo ${deb_folder}
	fi
}

function update_r {
	cran_folder=$(get_other_folder r-mirror)
	if [ -n "${cran_folder}" ]; then
		remotemirror="file:///${cran_folder}"
	else
		remotemirror="http://cran.us.r-project.org"
	fi
	sudo chown -R ${USER} $(get_home_dir)/R
	sudo Rscript -e "update.packages(ask = FALSE, repos=\"${remotemirror}\")"
	Rscript -e "update.packages(ask = FALSE, repos=\"${remotemirror}\")"
	Rscript -e "if(!require(\"devtools\")) {install.packages(\"devtools\", ask=FALSE, repos=\"${remotemirror}\");devtools::install_github(\"hadley/devtools\")}"
	Rscript -e 'if(!require("dtupdate")) devtools::install_github("hrbrmstr/dtupdate"); dtupdate::github_update()'
	Rscript -e 'dtupdate::github_update(auto.install = TRUE, ask = FALSE)'
#	Rscript -e "update.packages(ask = FALSE, repos=\"${remotemirror}\")"
}

function update_rstudio {
	ver=$(apt show rstudio | grep Version)
	pattern='^Version: ([0-9.]+)\s*$'
	if [[ $ver =~ $pattern ]]; then
		ourversion=${BASH_REMATCH[1]}
#		netversion=$(Rscript -e 'cat(stringr::str_match(scan("https://www.rstudio.org/links/check_for_update?version=1.0.0", what = character(0), quiet=TRUE), "^[^=]+=([^\\&]+)\\&.*")[[2]])')
		netversion=$(curl -s http://download1.rstudio.org/current.ver)
		if [ "$ourversion" != "$netversion" ]; then
			deb_folder=$(get_deb_folder)
			tee /tmp/get_rstudio_uri.R <<EOF
if(!require('rvest')) install.packages('rvest', Ncpus=8, repos='${remotemirror}')
xpath='.downloads:nth-child(2) tr:nth-child(5) a'
url = "https://www.rstudio.com/products/rstudio/download/"
thepage<-xml2::read_html(url)
cat(html_node(thepage, xpath) %>% html_attr("href"))
EOF
			RSTUDIO_URI=$(Rscript /tmp/get_rstudio_uri.R)
			
			wget -c --output-document /tmp/rstudio.deb $RSTUDIO_URI -O ${deb_folder}/rstudio_${netvesion}_amd64.deb
			if ! sudo dpkg -i ${deb_folder}/rstudio_${netvesion}_amd64.deb; then
				sudo apt install -f --yes
			fi
			rm /tmp/get_rstudio_uri.R
	
			if fc-list |grep -q FiraCode; then
				if ! grep -q "text-rendering:" /usr/lib/rstudio/www/index.htm; then
					sudo sed -i '/<head>/a<style>*{text-rendering: optimizeLegibility;}<\/style>' /usr/lib/rstudio/www/index.htm
				fi
			fi
		fi
	fi
}

function update_rstudio_server {
	ver=$(apt show rstudio-server | grep Version)
	pattern='^Version: ([0-9.]+)\s*$'
	if [[ $ver =~ $pattern ]]; then
		ourversion=${BASH_REMATCH[1]}
		do_check=1
	fi
	netversion=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver)
	if [ "$ourversion" != "$netversion" ]; then
		deb_folder=$(get_deb_folder)
		tee /tmp/get_rstudio_uri.R <<'EOT'
if(!require('rvest')) install.packages('rvest', Ncpus=8, repos='http://cran.us.r-project.org')
if(!require('stringr')) install.packages('stringr', Ncpus=8, repos='http://cran.us.r-project.org')
xpath='code:nth-child(3)'
url = "https://www.rstudio.com/products/rstudio/download-server/"
thepage<-xml2::read_html(url)
link<-html_node(thepage, xpath) %>% html_text()
cat(stringr::str_match(link, '^\\$( wget)? (.*)$')[[3]])
EOT
		RSTUDIO_URI=$(sudo Rscript /tmp/get_rstudio_uri.R)
		RSTUDIO_URI=$(sudo Rscript /tmp/get_rstudio_uri.R)
		
		wget -c $RSTUDIO_URI --output-document ${deb_folder}/rstudio-server_${netversion}_amd64.deb
		if ! sudo dpkg -i ${deb_folder}/rstudio-server_${netversion}_amd64.deb; then
			sudo apt install -f --yes
		fi
		rm /tmp/get_rstudio_uri.R
	fi
}

if dpkg -s r-base-core >/dev/null 2>/dev/null; then
	update_r
fi

if dpkg -s rstudio >/dev/null 2>/dev/null; then
	update_rstudio
fi

if dpkg -s rstudio-server >/dev/null 2>/dev/null; then
	update_rstudio_server
fi

