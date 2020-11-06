# svcrat - ServiceRat

--- **WORK IN PROGRESS** ---

# Description
Permanently requests the current state of specified services (host/ip + port) and gives the opportunity to execute scripts based on that information.

# Requirements

``svcrat`` is a shell script written in bash. It uses the netcat utility to scan ports for their availibilty.  
Successfully tested on:

- Ubuntu Server 20.04:
  - netcat-openbsd / 1.206-1ubuntu1 / amd64
  - bash 5.0.17(1)-release

# Installation

```bash
cd ~
git clone https://github.com/JZach/svcrat.git
cd svcrat
```

Create necessary directories:

```bash
#working-directory
sudo mkdir -p /usr/local/bin/svcrat
#configuration
sudo mkdir -p /usr/local/etc/svcrat
```
Copy script and config:

```bash
sudo cp -f ./svcrat.sh /usr/local/bin/svcrat
(?? PERMISSIONS ??)
sudo cp -f ./svcrat.conf /usr/local/etc/svcrat
```   

COPY-UNIT-SERICE

```bash
sudo adduser svcrat --gecos "" --no-create-home --disabled-login
sudo cp -f ./svcrat.service /etc/systemd/system/svcrat.service
sudo systemctl enable svcrat.service
sudo systemctl start svcrat.service
```

# Configuration

The configuration file is located at ``/usr/local/etc/svcrat/svcrat.conf`` by default.

```bash
#======================= Global Definitions =======================

[global]
    delay = 5
    verbosity-level = 1
    working-directory = /usr/local/bin/svcrat/

#======================= Service Definitions =======================

[host-01]
    ipv4 = 127.0.0.1
    port = 80
    description = webservice hosted on localhost
    path = /path/to/scripts/for/host01/port445/
    init_state = x

...

[host-n]

```

Currently, these options are available:

```bash
[global]

    delay = 5
    # svcrat runs infinitely. 'delay' specifies the amount of seconds to wait
    # for the next cycle.

    verbosity-level = 1
    # 0 ... no output / quiet
    # 1 ... print states of services
    # 2 ... verbose output

    working-directory = /usr/local/bin/svcrat/
    # ...
```

```bash
[host-title]    # can be any title to identify the host

    ipv4 = 127.0.0.1
    # hostname or ipv4 address of remote target

    port = 80
    # port number of remote service

    description = webservice hosted on localhost
    # description of the service

    path = /path/to/scripts/for/host01/port445/
    # ...
```