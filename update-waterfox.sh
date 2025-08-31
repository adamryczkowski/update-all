#!/bin/bash
repo_path=/media/adam-minipc/other/debs

if command -v waterfox >/dev/null; then
	waterfox=$(command -v waterfox)
elif [ -f /opt/waterfox/waterfox ]; then
	waterfox=/opt/waterfox/waterfox
else
	exit 0 #no waterfox
fi

local_version=$(${waterfox} --version)
pattern='^Mozilla Waterfox ([0-9.]+)$'

if [[ "$local_version" =~ $pattern ]]; then
	local_version=${BASH_REMATCH[1]}
else
	printf '%s\n' "Something wrong with the waterfox. ${waterfox} --version returned" "$local_version"
	exit 1
fi

function get_latest_github_release_name { #source: https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
	curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
		grep '"tag_name":' |                                            # Get tag line
		sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

remote_version=$(get_latest_github_release_name MrAlex94/Waterfox)
pattern='^([0-9\.]+)\-.*$'
if [[ "${remote_version}" =~ $pattern ]]; then
   ver_str="${BASH_REMATCH[1]}"
   clas_str="${BASH_REMATCH[2]}"; : "${clas_str}"
else
	echo "Something wrong with the remote version of waterfox: ${remote_version}"
	exit 1
fi

function get_cached_file {
	local filename="$1"
	local download_link="$2"
	local _repo_path="$repo_path"
	if [ ! -d "${_repo_path}" ]; then
		mkdir -p /tmp/repo_path
		_repo_path="/tmp/repo_path"
	fi
	if [ ! -f "${_repo_path}/${filename}" ]; then
		if [ -z "$download_link" ]; then
			echo "File is missing from cache"
			return 1
		fi
		if [ ! -w "${_repo_path}" ]; then
			echo "Cannot write to the repo ${_repo_path}" >/dev/stderr
			_repo_path="/tmp/repo_path"
			mkdir -p /tmp/repo_path
		fi
		wget -c "${download_link}" -O "${_repo_path}/${filename}"
	fi
	if [ ! -f "${_repo_path}/${filename}" ]; then
		echo "Cannot download the file"
		return 1
	fi
	echo "${_repo_path}/${filename}"
}

function is_folder_writable {
	local folder="$1"
	local user="$2"
	
	#source: https://stackoverflow.com/questions/14103806/bash-test-if-a-directory-is-writable-by-a-given-uid
	read -r -a INFO < <(stat -L -c "0%a %G %U" "$folder")
	PERM=${INFO[0]}
	GROUP=${INFO[1]}
	OWNER=${INFO[2]}

	ACCESS=no
	if ((( PERM & 0002 ) != 0 )); then
		ACCESS=yes
	elif ((( PERM & 0020 ) != 0 )); then
		readarray -t gs < <(groups "$user")
		for g in "${gs[@]}"; do
			if [[ $GROUP == "$g" ]]; then
				ACCESS=yes
				break
			fi
		done
	elif ((( PERM & 0200 ) != 0 )); then
		[[ $user == "$OWNER" ]] && ACCESS=yes
	fi
	if [ "$ACCESS" = 'yes' ]; then
		return 0
	else
		return 1
	fi
}


function uncompress_cached_file {
set -x
	local filename="$1"
	local destination="$2"
	local usergr="$3"
	local user
	local timestamp_path; timestamp_path="$(dirname "${destination}")/$(basename "${filename}").timestamp"
	if [ -z "$usergr" ]; then
		user=$USER
		usergr=$user
		group=""; : "${group}"
	else
		local pattern='^([^:]+):([^:]+)$'
		if [[ "$usergr" =~ $pattern ]]; then
			group=${BASH_REMATCH[2]}; : "${group}"
			user=${BASH_REMATCH[1]}
		else
			group=""; : "${group}"
			user=$usergr
		fi
	fi
	
	local path_filename
	if [ ! -f "$filename" ]; then
		path_filename=$(get_cached_file "$filename")
	else
		path_filename="$filename"
	fi
	if [ -z "$path_filename" ]; then
		echo "no input file $path_filename"
		return 1
	fi
	if [ -z "$destination" ]; then
		echo "no destination $destination"
		return 2
	fi
	if [ -d "$destination" ]; then
		moddate_remote=$(stat -c %y "$destination")
		if [ -f "$timestamp_path" ]; then
			moddate_hdd=$(cat "$timestamp_path")
			if [ "$moddate_hdd" = "$moddate_remote" ]; then
				return 0
			fi
		fi
	fi
	local destdir; destdir=$(dirname "$destination")
	pushd "$destdir" >/dev/null || return 0
	if is_folder_writable "$destdir" "$user"; then
		if [ "$user" = "$USER" ]; then
			dtrx --one rename "$path_filename"
			filename_no_ext="${path_filename%.*}"
			if [ ! -d "$filename_no_ext" ]; then
				filename_no_ext="${filename_no_ext%.*}"
			fi
			if [ -d "$(basename "$destination")" ]; then
				sudo rm -rf "$(basename "$destination")"
			fi
			sudo mv "$(basename "$filename_no_ext")" "$(basename "$destination")"
			echo "$moddate_remote" | tee "$timestamp_path" >/dev/null
		else
			sudo -u "$user" dtrx --one rename "$path_filename"
			if [ -d "$(basename "$destination")" ]; then
				sudo rm -rf "$(basename "$destination")"
			fi
			sudo mv "$(basename "$filename_no_ext")" "$(basename "$destination")"
			echo "$moddate_remote" | sudo -u "$user" -- tee "$timestamp_path" >/dev/null
		fi
	else
		sudo dtrx --one rename "$path_filename"
		if [ -d "$(basename "$destination")" ]; then
			rm -rf "$(basename "$destination")"
		fi
		sudo mv "$(basename "$filename_no_ext")" "$(basename "$destination")"
		sudo chown -R "$usergr" "$destination"
		echo "$moddate_remote" | sudo -u "$user" -- tee "$timestamp_path" >/dev/null
	fi
	popd >/dev/null || true
set +x
}

if [ ! -f /usr/share/applications/waterfox.desktop ]; then
	localexec="$waterfox"
	sudo tee -a /usr/share/applications/waterfox.desktop  <<EOF
[Desktop Entry]
Version=1.0
Name=Waterfox Web Browser
Name[ar]=متصفح الويب فَيَرفُكْس
Name[ast]=Restolador web Waterfox
Name[bn]=ফায়ারফক্স ওয়েব ব্রাউজার
Name[ca]=Navegador web Waterfox
Name[cs]=Waterfox Webový prohlížeč
Name[da]=Waterfox - internetbrowser
Name[el]=Περιηγητής Waterfox
Name[es]=Navegador web Waterfox
Name[et]=Waterfoxi veebibrauser
Name[fa]=مرورگر اینترنتی Waterfox
Name[fi]=Waterfox-selain
Name[fr]=Navigateur Web Waterfox
Name[gl]=Navegador web Waterfox
Name[he]=דפדפן האינטרנט Waterfox
Name[hr]=Waterfox web preglednik
Name[hu]=Waterfox webböngésző
Name[it]=Waterfox Browser Web
Name[ja]=Waterfox ウェブ・ブラウザ
Name[ko]=Waterfox 웹 브라우저
Name[ku]=Geroka torê Waterfox
Name[lt]=Waterfox interneto naršyklė
Name[nb]=Waterfox Nettleser
Name[nl]=Waterfox webbrowser
Name[nn]=Waterfox Nettlesar
Name[no]=Waterfox Nettleser
Name[pl]=Przeglądarka WWW Waterfox
Name[pt]=Waterfox Navegador Web
Name[pt_BR]=Navegador Web Waterfox
Name[ro]=Waterfox – Navigator Internet
Name[ru]=Веб-браузер Waterfox
Name[sk]=Waterfox - internetový prehliadač
Name[sl]=Waterfox spletni brskalnik
Name[sv]=Waterfox webbläsare
Name[tr]=Waterfox Web Tarayıcısı
Name[ug]=Waterfox توركۆرگۈ
Name[uk]=Веб-браузер Waterfox
Name[vi]=Trình duyệt web Waterfox
Name[zh_CN]=Waterfox 网络浏览器
Name[zh_TW]=Waterfox 網路瀏覽器
Comment=Browse the World Wide Web
Comment[ar]=تصفح الشبكة العنكبوتية العالمية
Comment[ast]=Restola pela Rede
Comment[bn]=ইন্টারনেট ব্রাউজ করুন
Comment[ca]=Navegueu per la web
Comment[cs]=Prohlížení stránek World Wide Webu
Comment[da]=Surf på internettet
Comment[de]=Im Internet surfen
Comment[es]=Navegue por la web
Comment[et]=Lehitse veebi
Comment[fa]=صفحات شبکه جهانی اینترنت را مرور نمایید
Comment[fi]=Selaa Internetin WWW-sivuja
Comment[fr]=Naviguer sur le Web
Comment[gl]=Navegar pola rede
Comment[he]=גלישה ברחבי האינטרנט
Comment[hr]=Pretražite web
Comment[hu]=A világháló böngészése
Comment[it]=Esplora il web
Comment[ja]=ウェブを閲覧します
Comment[ko]=웹을 돌아 다닙니다
Comment[ku]=Li torê bigere
Comment[lt]=Naršykite internete
Comment[nb]=Surf på nettet
Comment[nl]=Verken het internet
Comment[nn]=Surf på nettet
Comment[no]=Surf på nettet
Comment[pl]=Przeglądanie stron WWW 
Comment[pt]=Navegue na Internet
Comment[pt_BR]=Navegue na Internet
Comment[ro]=Navigați pe Internet
Comment[ru]=Доступ в Интернет
Comment[sk]=Prehliadanie internetu
Comment[sl]=Brskajte po spletu
Comment[sv]=Surfa på webben
Comment[ug]=دۇنيادىكى توربەتلەرنى كۆرگىلى بولىدۇ
Comment[uk]=Перегляд сторінок Інтернету
Comment[vi]=Để duyệt các trang web
Comment[zh_CN]=浏览互联网
Comment[zh_TW]=瀏覽網際網路
GenericName=Web Browser
GenericName[ar]=متصفح ويب
GenericName[ast]=Restolador Web
GenericName[bn]=ওয়েব ব্রাউজার
GenericName[ca]=Navegador web
GenericName[cs]=Webový prohlížeč
GenericName[da]=Webbrowser
GenericName[el]=Περιηγητής διαδικτύου
GenericName[es]=Navegador web
GenericName[et]=Veebibrauser
GenericName[fa]=مرورگر اینترنتی
GenericName[fi]=WWW-selain
GenericName[fr]=Navigateur Web
GenericName[gl]=Navegador Web
GenericName[he]=דפדפן אינטרנט
GenericName[hr]=Web preglednik
GenericName[hu]=Webböngésző
GenericName[it]=Browser web
GenericName[ja]=ウェブ・ブラウザ
GenericName[ko]=웹 브라우저
GenericName[ku]=Geroka torê
GenericName[lt]=Interneto naršyklė
GenericName[nb]=Nettleser
GenericName[nl]=Webbrowser
GenericName[nn]=Nettlesar
GenericName[no]=Nettleser
GenericName[pl]=Przeglądarka WWW
GenericName[pt]=Navegador Web
GenericName[pt_BR]=Navegador Web
GenericName[ro]=Navigator Internet
GenericName[ru]=Веб-браузер
GenericName[sk]=Internetový prehliadač
GenericName[sl]=Spletni brskalnik
GenericName[sv]=Webbläsare
GenericName[tr]=Web Tarayıcı
GenericName[ug]=توركۆرگۈ
GenericName[uk]=Веб-браузер
GenericName[vi]=Trình duyệt Web
GenericName[zh_CN]=网络浏览器
GenericName[zh_TW]=網路瀏覽器
Keywords=Internet;WWW;Browser;Web;Explorer
Keywords[ar]=انترنت;إنترنت;متصفح;ويب;وب
Keywords[ast]=Internet;WWW;Restolador;Web;Esplorador
Keywords[ca]=Internet;WWW;Navegador;Web;Explorador;Explorer
Keywords[cs]=Internet;WWW;Prohlížeč;Web;Explorer
Keywords[da]=Internet;Internettet;WWW;Browser;Browse;Web;Surf;Nettet
Keywords[de]=Internet;WWW;Browser;Web;Explorer;Webseite;Site;surfen;online;browsen
Keywords[el]=Internet;WWW;Browser;Web;Explorer;Διαδίκτυο;Περιηγητής;Waterfox;Φιρεφοχ;Ιντερνετ
Keywords[es]=Explorador;Internet;WWW
Keywords[fi]=Internet;WWW;Browser;Web;Explorer;selain;Internet-selain;internetselain;verkkoselain;netti;surffaa
Keywords[fr]=Internet;WWW;Browser;Web;Explorer;Fureteur;Surfer;Navigateur
Keywords[he]=דפדפן;אינטרנט;רשת;אתרים;אתר;פיירפוקס;מוזילה;
Keywords[hr]=Internet;WWW;preglednik;Web
Keywords[hu]=Internet;WWW;Böngésző;Web;Háló;Net;Explorer
Keywords[it]=Internet;WWW;Browser;Web;Navigatore
Keywords[is]=Internet;WWW;Vafri;Vefur;Netvafri;Flakk
Keywords[ja]=Internet;WWW;Web;インターネット;ブラウザ;ウェブ;エクスプローラ
Keywords[nb]=Internett;WWW;Nettleser;Explorer;Web;Browser;Nettside
Keywords[nl]=Internet;WWW;Browser;Web;Explorer;Verkenner;Website;Surfen;Online 
Keywords[pt]=Internet;WWW;Browser;Web;Explorador;Navegador
Keywords[pt_BR]=Internet;WWW;Browser;Web;Explorador;Navegador
Keywords[ru]=Internet;WWW;Browser;Web;Explorer;интернет;браузер;веб;файрфокс;огнелис
Keywords[sk]=Internet;WWW;Prehliadač;Web;Explorer
Keywords[sl]=Internet;WWW;Browser;Web;Explorer;Brskalnik;Splet
Keywords[tr]=İnternet;WWW;Tarayıcı;Web;Gezgin;Web sitesi;Site;sörf;çevrimiçi;tara
Keywords[uk]=Internet;WWW;Browser;Web;Explorer;Інтернет;мережа;переглядач;оглядач;браузер;веб;файрфокс;вогнелис;перегляд
Keywords[vi]=Internet;WWW;Browser;Web;Explorer;Trình duyệt;Trang web
Keywords[zh_CN]=Internet;WWW;Browser;Web;Explorer;网页;浏览;上网;火狐;Waterfox;ff;互联网;网站;
Keywords[zh_TW]=Internet;WWW;Browser;Web;Explorer;網際網路;網路;瀏覽器;上網;網頁;火狐
Exec=${localexec} %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/usr/local/lib/waterfox/browser/icons/mozicon128.png
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=${localexec} -new-window

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=${localexec} -private-window
EOF
fi

if [[ "$remote_version" != "$local_version" ]]; then
	link="https://storage-waterfox.netdna-ssl.com/releases/linux64/installer/waterfox-classic-${ver_str}.en-US.linux-x86_64.tar.bz2"
	filename="waterfox-${ver_str}.en-US.linux-x86_64.tar.bz2"
	get_cached_file "$filename" "$link"
	uncompress_cached_file "$filename" "/opt/waterfox"
	sudo chown root -R "/opt/waterfox"
fi
