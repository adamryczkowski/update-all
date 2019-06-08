#!/bin/bash

function get_latest_github_release_name { #source: https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
	local skip_v=$2
	ans=$(curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
		grep '"tag_name":' |                                            # Get tag line
		sed -E 's/.*"([^"]+)".*/\1/') # Pluck JSON value
	                                    
	if [ -n "$skip_v" ]; then
		pattern='v(.*)$'
		if [[ ! "$ans" =~ $pattern ]]; then
			echo "Cannot strip \"v\" prefix from  $version"
			return -1 
		else
			ans=${BASH_REMATCH[1]}
		fi
	fi
	echo "$ans"
}

function get_cached_file {
	local filename="$1"
	local download_link="$2"
	if [ ! -d "${repo_path}" ]; then
		mkdir -p /tmp/repo_path
		local repo_path="/tmp/repo_path"
	fi
	if [ ! -f "${repo_path}/${filename}" ]; then
		if [ -z "$download_link" ]; then
			echo "File is missing from cache"
			return 1
		fi
		if [ ! -w "${repo_path}" ]; then
			if ! sudo chown ${USER} "${repo_path}"; then
				echo "Cannot write to the repo ${repo_path}" >/dev/stderr
				return 1
			fi
			local repo_path="/tmp/repo_path"
			mkdir -p /tmp/repo_path
		fi
		wget -c "${download_link}" -O "${repo_path}/${filename}"
	fi
	if [ ! -f "${repo_path}/${filename}" ]; then
		echo "Cannot download the file"
		return 1
	fi
	echo "${repo_path}/${filename}"
}

function uncompress_cached_file {
	local path_filename="$1"
	local destination="$2"
	local usergr=root
	local user=root
	
	if [ -z "$destination" ]; then
		echo "no destination $destination"
		return 2
	fi
	pushd $(dirname $destination)
	extension="${path_filename##*.}"
	filename_no_ext="${path_filename%.*}"
	if [ ! -d "$filename_no_ext" ]; then
		filename_no_ext="${filename_no_ext%.*}"
	fi
	sudo dtrx --one rename "$path_filename"
	sudo mv $(basename $filename_no_ext) $(basename $destination) 
	popd
set +x
}

if which julia >/dev/null; then
	julia_bin=$(readlink $(which julia))
	if [[ "$julia_bin" != "/opt/julia/bin/julia" ]]; then
		echo "Cannot update julia, because it is in non-standard place"
		exit 0
	fi
else
	if [ ! -f "/opt/julia/bin/julia" ]; then
		echo "julia not found"
		exit 0
	else
		julia_bin=/opt/julia/bin/julia
	fi
fi

julia_verstr=$($julia_bin --version)
pattern='^julia version (.*)$'
if [[ ! $julia_verstr =~ $pattern ]]; then
	echo "Cannot read julia version from string $julia_verstr"
	exit 0
fi
loc_julia_ver=${BASH_REMATCH[1]}
remote_julia_ver=$(get_latest_github_release_name JuliaLang/julia skip_v)
pattern='^([0-9]+\.[0-9])\..*'
if [[ $remote_julia_ver =~ $pattern ]]; then
	remote_julia_shortver=${BASH_REMATCH[1]}
else
	echo "Wrong format of version: ${remote_julia_ver}"
	return 1
fi

if [ "$loc_julia_ver" != "$remote_julia_ver" ]; then

	julia_file="julia-${remote_julia_ver}-linux-x86_64.tar.gz"
	julia_link="https://julialang-s3.julialang.org/bin/linux/x64/${remote_julia_shortver}/${julia_file}"
	julia_path=$(get_cached_file "${julia_file}" "${julia_link}")
	sudo rm -rf /opt/julia
	uncompress_cached_file "${julia_path}" /opt/julia
	$julia_bin -e 'using Pkg;Pkg.add(["Revise", "IJulia", "Rebugger", "RCall", "Knet", "Plots", "StatsPlots" , "DataFrames", "JLD", "Flux", "TensorFlow", "Debugger", "Weave", "ScikitLearn"]);ENV["PYTHON"]=""; Pkg.update(); Pkg.build(); using Revise; using IJulia; using Rebugger; using RCall; using Knet; using Plots; using StatsPlots; using DataFrames; using JLD; using Flux; using TensorFlow; using Debugger'
else
	$julia_bin -e 'using Pkg;Pkg.update()'
fi


