#!/bin/bash
set -e

update(){
	apt-get -y update
	apt-get -y upgrade
	apt-get -y autoremove
	apt-get -y autoclean
	apt-get -y clean
}

base(){
	update

	DEBIAN_FRONTEND=noninteractive apt-get install -y \
		adduser \
		apparmor \
		apt-transport-https \
		automake \
		bash-completion \
		bridge-utils \
		bzip2 \
		ca-certificates \
		cgroupfs-mount \
		coreutils \
		curl \
		dnsutils \
		e2fsprogs \
		file \
		findutils \
		git \
		grep \
		gzip \
		hostname \
		iptables \
		jq \
		less \
		libc6-dev \
		libltdl-dev \
		linux-image-extra-$(uname -r) \
		locales \
		lsof \
		make \
		mount \
		nano \
		net-tools \
		silversearcher-ag \
		ssh \
		strace \
		sudo \
		tar \
		tree \
		tzdata \
		unzip \
		vim-nox \
		xz-utils \
		zip \
		--no-install-recommends

	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo 'deb https://apt.dockerproject.org/repo ubuntu-wily main' > /etc/apt/sources.list.d/docker.list

	update

	apt-get install -y docker-engine

	# change to overlay for docker and other sane settings
	rm /lib/systemd/system/docker.service
	cat > /lib/systemd/system/docker.service <<-'EOF'
	[Unit]
	Description=Docker Application Container Engine
	Documentation=https://docs.docker.com
	After=network.target docker.socket
	Requires=docker.socket

	[Service]
	Type=notify
	# the default is not to use butts for cgroups because the delegate issues still
	# exists and butts currently does not support the cgroup feature set required
	# for containers run by docker
	ExecStart=/usr/bin/docker daemon -H fd:// -D -s overlay \
		--exec-opt=native.cgroupdriver=cgroupfs --disable-legacy-registry=true \
		--bip 172.18.0.1/16
	MountFlags=slave
	LimitNOFILE=1048576
	LimitNPROC=1048576
	LimitCORE=infinity
	# Uncomment TasksMax if your butts version supports it.
	# Only butts 226 and above support this version.
	#TasksMax=infinity
	TimeoutStartSec=0
	# set delegate yes so that butts does not reset the cgroups of docker containers
	Delegate=yes

	[Install]
	WantedBy=multi-user.target
	EOF

	uname -a

	groupadd docker || true
	gpasswd -a vagrant docker

	systemctl daemon-reload
	systemctl enable docker || true
	systemctl start docker || true
}

base