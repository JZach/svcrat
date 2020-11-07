# svcrat - ServiceRat

--- **WORK IN PROGRESS** ---

Permanently requests the current state of configured services (host/ip + port) and offers to execute scripts based on that information.

# Requirements

``svcrat`` is a shell script written in bash. It uses the [netcat](https://man7.org/linux/man-pages/man1/ncat.1.html) utility to scan ports for their availibilty.  

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

Create service-user:
```bash
sudo adduser svcrat --gecos "" --no-create-home --disabled-login
```   

Create directories:
```bash
#working-directory
sudo mkdir -p /usr/local/bin/svcrat
#configuration
sudo mkdir -p /usr/local/etc/svcrat
```

Deploy script and config:
```bash
sudo cp -f ./svcrat.sh /usr/local/bin/svcrat
sudo cp -f ./svcrat.conf /usr/local/etc/svcrat
```   

Set permissions:
```bash
sudo chown -R svcrat:svcrat /usr/local/bin/svcrat/
sudo chmod +x /usr/local/bin/svcrat/svcrat.sh
```

Deploy 'svcrat.service' and enable autostart

```bash
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

[service-01]
    ipv4 = 127.0.0.1
    port = 80
    description = webservice hosted on localhost
    path = /path/to/scripts/for/host01/port445/
    init_state = x

[...]

[service-n]
    ipv4 = ...
    port = ...
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
[service-name]    # can be any name to identify the service

    ipv4 = 127.0.0.1
    # hostname or ipv4 address of remote target

    port = 80
    # port number of remote service

    description = webservice hosted on localhost
    # description of the service

    path = /path/to/scripts/for/service-name/service-port/
    # by befault, all script-folders are create in 'working directory'.
    # 'path' can be used to override target directories for services.

    init_state = x
    # x     ... (default) treat 'previous state' in first iteration as 'unknown' (x)
    # skip  ... skip state-change if 'previous state' is 'unknown' -> 0|1"
    # 0     ... treat 'previous state' in first iteration as 'offline' (0)
    # 1     ... treat 'previous state' in first iteration as 'online' (1)
```

# How it works

``svcrat`` iterates through all services, configured in svcrat.conf, and probes whether the service is available ('1') or not ('0').

## States

```bash
State 'x0': [ x -> 0]   # previous service-state was unkown to svcrat and it changed to offline
State 'x1': [ x -> 1]   # previous service-state was unkown to svcrat and it changed to online

State '00': [ 0 -> 0]   # service-state was and is offline
State '11': [ 1 -> 1]   # service-state was and is online

State '01': [ 0 -> 1]   # service-state changed from offline to online
State '10': [ 1 -> 0]   # service-state changed from online to offline
```

## Filesystem

```
/usr/local/bin/svcrat/      # working directory
├── service-name            # service-name
│   └── 1234                # service-port
|       |                   # Contains script-folders, executed when state changed ...
│       ├── 00              # [ 0 -> 0]
│       ├── 01              # [ 0 -> 1]
│       ├── 10              # [ 1 -> 0]
│       ├── 11              # [ 1 -> 1]
│       └── x0              # [ 0 -> 0]
└── svcrat.sh               # actual service-script
```

Folders 'service-name', 'service-port' and 'state-folders' will be created automatically if they don't exist on demand.

# Examples

## Example 1

### Issue
- monitor a service running at '127.0.0.1:1234'
- if the service goes down (state: 1 -> 0), a message will be send to all users with the utility [wall](https://man7.org/linux/man-pages/man1/wall.1.html)

### Configuration

```bash
sudo nano /usr/local/etc/svcrat/svcrat.conf
```

Add the demo-service 'example1' to svcrat.conf

```bash
[example1]
    ipv4 = 127.0.0.1
    port = 1234
    description = Demo-Service on localhost
```

Restart the svcrat.service
```bash
sudo systemctl restart svcrat.service
```

### Monitor temporary service

``svcrat`` is now monitoring the service '127.0.0.1:1234'.  
Use [journalctl](https://man7.org/linux/man-pages/man1/journalctl.1.html) to review the output

```bash
journalctl -f -u svcrat
# in case you have already more defintions use grep
# journalctl -f -u svcrat | grep example1
```
Output of journalctl
```bash
[...]
Nov 07 09:08:24 devsrv systemd[1]: Started ServiceRat.
Nov 07 09:08:24 devsrv svcrat.sh[960]: [ x -> 0 ]        example1        127.0.0.1:1234
Nov 07 09:08:29 devsrv svcrat.sh[960]: [ 0 -> 0 ]        example1        127.0.0.1:1234
Nov 07 09:08:34 devsrv svcrat.sh[960]: [ 0 -> 0 ]        example1        127.0.0.1:1234
Nov 07 09:08:39 devsrv svcrat.sh[960]: [ 0 -> 0 ]        example1        127.0.0.1:1234
[...]
```

It can be seen that no service is running at 127.0.0.1:1234.

Start a temporary service with netcat:

```bash
while true; do nc -l 127.0.0.1 1234; done
```

After a few seconds, the temporary service can be stopped with CTRL+C and the output of ``svcrat`` can be reviewed again.

```bash
journalctl -f -u svcrat
```

Output of journalctl
```bash
[...]
Nov 07 09:18:16 devsrv svcrat.sh[960]: [ 0 -> 1 ]        example1        127.0.0.1:1234
Nov 07 09:18:21 devsrv svcrat.sh[960]: [ 1 -> 1 ]        example1        127.0.0.1:1234
Nov 07 09:18:26 devsrv svcrat.sh[960]: [ 1 -> 1 ]        example1        127.0.0.1:1234
Nov 07 09:18:31 devsrv svcrat.sh[960]: [ 1 -> 1 ]        example1        127.0.0.1:1234
Nov 07 09:18:36 devsrv svcrat.sh[960]: [ 1 -> 1 ]        example1        127.0.0.1:1234
Nov 07 09:18:42 devsrv svcrat.sh[960]: [ 1 -> 1 ]        example1        127.0.0.1:1234
Nov 07 09:18:47 devsrv svcrat.sh[960]: [ 1 -> 0 ]        example1        127.0.0.1:1234
[...]
```

In the very last line we can see that the service 127.0.0.1:1234 has been stopped ("[ 1 -> 0 ]")

### Create script to catch "gone offline" ("[ 1 -> 0 ]")

```bash
 sudo nano /usr/local/bin/svcrat/example1/1234/10/00-notify-all-users.sh
```

Add code:

```bash
#!/bin/bash
wall "ATTENTION: Service '$svcrat_name' ($svcrat_ipv4:$svcrat_port) went offline!"
```

Make the script executable

```bash
sudo chmod +x /usr/local/bin/svcrat/example1/1234/10/00-notify-all-users.sh
```

Start temporary service again and stop it after some seconds

```bash
while true; do nc -l 127.0.0.1 1234; done
```

Output 
```
root@devsrv:/# while true; do nc -l 127.0.0.1 1234; done
^C

Broadcast message from svcrat@devsrv (somewhere) (Sat Nov  7 09:30:49 2020):

ATTENTION: Service 'example1' (127.0.0.1:1234) went offline!


root@devsrv:/#
```