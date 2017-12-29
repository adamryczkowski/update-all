#!/bin/bash
if which R; then
	sudo -H Rscript -e 'update.packages(ask = FALSE, repos="http://cran.us.r-project.org")'
	sudo -H Rscript -e 'if(!require("devtools")) install.packages("devtools", ask=FALSE)'
	sudo -H Rscript -e 'if(!require("dtupdate")) devtools::install_github("hrbrmstr/dtupdate"); dtupdate::github_update()'
	Rscript -e 'update.packages(ask = FALSE, repos="http://cran.us.r-project.org")'
	
#	Rscript -e 'pkgs = loadedNamespaces();desc <- lapply(pkgs, packageDescription, lib.loc = NULL); for (d in desc) {if (!is.null(d$GithubSHA1)) {install_github(repo = d$GithubRepo, username = d$GithubUsername)}}'
fi

if dpkg -s rstudio >/dev/null 2>/dev/null; then
	ver=$(apt show rstudio | grep Version)
	pattern='^Version: ([0-9.]+)\s*$'
	if [[ $ver =~ $pattern ]]; then
		ourversion=${BASH_REMATCH[1]}
		netversion=$(Rscript -e 'cat(stringr::str_match(scan("https://www.rstudio.org/links/check_for_update?version=1.0.0", what = character(0), quiet=TRUE), "^[^=]+=([^\\&]+)\\&.*")[[2]])')
		if [ "$ourversion" != "$netversion" ]; then
			RSTUDIO_URI=$(Rscript /tmp/get_rstudio_uri.R)
			tee /tmp/get_rstudio_uri.R <<EOF
if(!require('rvest')) install.packages('rvest', Ncpus=8, repos='http://cran.us.r-project.org')
xpath='.downloads:nth-child(2) tr:nth-child(5) a'
url = "https://www.rstudio.com/products/rstudio/download/"
thepage<-xml2::read_html(url)
cat(html_node(thepage, xpath) %>% html_attr("href"))
EOF
			RSTUDIO_URI=$(Rscript /tmp/get_rstudio_uri.R)
			
			wget -c --output-document /tmp/rstudio.deb $RSTUDIO_URI 
			sudo dpkg -i /tmp/rstudio.deb
			rm /tmp/rstudio.deb
			rm /tmp/get_rstudio_uri.R
	
			if fc-list |grep -q FiraCode; then
				if !grep -q "text-rendering:" /usr/lib/rstudio/www/index.htm; then
					sudo sed -i '/<head>/a<style>*{text-rendering: optimizeLegibility;}<\/style>' /usr/lib/rstudio/www/index.htm
				fi
			fi
		fi
	fi
fi

