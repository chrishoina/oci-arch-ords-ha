# 1. ORDS in an OCI compute instance using available RPMs

## 2. Some questions

- What happens when you install ORDS in a compute instance, in OCI, with the `sudo dnf install ords -y` command?
- What does the configuration folder structure look like?
- What does the bin look like?
- What are the users that install and invoke the `ords serve` command?
- Detail the steps for installing sqlcl, and java.
- Do you need to explicitly set the `PATH`s for the ORDS `/bin` and SQLcl `/bin`? Or is that already done with the `sudo dnf install [product]` command?

## 3. Technical details

What am I supposed to call this? I am doing some testing, and here are the "variables" in my experimentation:

| Name | Characteristics | Notes/Details |
| ---- | --------------- | ------------- |
|testinstance01 | IPv4, no Boot volume | In ords-vcn, public subnet-ords-vcn |
| Linux OS | 9 | Image build: 2025.02.28-0|
|Shape | AMD VM.Standard.E4.Flex | 1 OCPU, 16GB memory, 1 Gbps bandwidth |

Saved the private key file in the .ssh folder.
Public IP address: `132.226.202.219`

> **:memo: NOTE:** When you view the compute instance details in the OCI dashnboard, the OS shows what looks to be a "fully-qualified" version. When you create the compute instance, you'll see soemthing like `Linux 9`.  
>
>But when you view the details (after the instance has provisioned) it will show something like this: `Oracle-Linux-9.5-2025.02.28-0`. 
>
> I believe, for Terraform files you need to use `9.5` as the OS. Just noting for future steps.

To access the compute instance, we follow the steps outlined [here](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/connect-to-linux-instance.htm).

### 3.1 Accessing the Compute Instance

1. I'll `cd` to my .ssh directory to make those steps a little easier.
2. Issue the `chmod 400 [your private key file]` command.[^3.1]
3. Use `ssh -i [your private key file] opc@[your compute's public IP address`. Accept the "Are you sure you want to continue connecting (yes/no/[fingerprint])?" question (i.e. "yes").
4. You'll be logged in as the `opc` user.

<!-- Question for me, do we need to do this chmod command when we are doing this with Terraform? -->

Here is where things are unclear. Should we switch users now, to the `oracle` user? Or should we issue the `sudo ords install`, `sudo sqlcl install`, and `sudo graalvm install` commands as `opc`?

The *absolute* top level directory consists of the following (basically "`cd`ing" until you can't anymore):

```sh
.  ..  afs  bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  .swapfile  sys  tmp  usr  var
```

It looks like when you first sign-in, you are immediately placed in the `/home/opc` directory. I assume all installs are to be done at this location. In other words, when following along with documentation, the product assumes you are here. I do not know if this matters though. It may be that the underlying scripts just "know" where you put stuff.

I'll install my "dependecies" next: ORDS, SQLcl, GraalVM.

[^3.1]: About the [chmod](https://ss64.com/bash/chmod.html) commmand.

### 3.2 Installing dependencies

#### 3.2.1 ORDS

`sudo dnf install ords -y`

I do not know if you need the `-y` flag. It works just fine with it. I assume if you don't include the `-y` that means you'll have to take the additional step to accept some condition. Adding the `-y` seems to work better with scripting (as an "automation insurance policy").

Why `dnf` and not `yum`?[^3.2.1]

[3.2.1]: In short, `dnf` is better. For...reasons. I'm not an expert, I just read up, and the do what I'm told. But [here is some background](https://docs.oracle.com/en/operating-systems/oracle-linux/8/relnotes8.0/ol8-NewFeaturesandChanges.html#ol8-features-yum) on the support for *Dandified yum* or `dnf`. Who comes up with these names?

There are some helpful notes after the ORDS has been installed:

```sh
WARN: ORDS requires Java 17.
        You can install Oracle Java at https://www.oracle.com/java/technologies/downloads/#java17.
INFO: Before starting ORDS service, run the below command as user oracle:
        ords --config /etc/ords/config install
INFO: To enable the ORDS service during startup, run the below command:
        sudo  systemctl enable ords
```

> **:memo: NOTE:** This isn't the same as installing ORDS to "talk" to your database. All this does is install the ORDS product folder. You'll still have to configure it.

If you issue a `cd ..` command, you'll move up a folder. You should now see the following:

```sh
.  ..  opc  oracle
```

Whereas, before the ORDS install, you would have seen only:

```sh
.  ..  opc
```

It looks like whatever you did, it just created this `oracle` directory. You can't naviate (`cd oracle`) to this folder, you'll recieve an `-bash: cd: oracle: Permission denied` error. This is probably the `oracle` user, that I've seen referenced *everywhere*.

> **:memo: FYI:** The `sudo cd oracle` command doesn't do anything either.

Moving on the SQLcl and then GraalVM.

#### 3.2.2 SQLcl

`sudo dnf install sqlcl -y`

Same experience here. No issues with the install. I presume this sets your `$PATH` for you? Something seems to be working in some capactity. Because if you issue the `sql -version` command you recieve this error:

```sh
Error: SQLcl requires Java 11 and above to run.
    Found Java version no_java.
    Please set JAVA_HOME to appropriate version.
```

It looks like Java isn't installed or configured. Is that correct? Issuing the `which java` command and you'll get:

```sh
/usr/bin/which: no java in (/home/opc/.local/bin:/home/opc/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin)
```

  > :memo: **NOTE:** At this point, if I issue the `env` command (`ENV` doesn't work for some reason), I'll see the following:
  >
  > ```sh
> SHELL=/bin/bash
> HISTCONTROL=ignoredups
> HISTSIZE=1000
> HOSTNAME=testinstance01
> PWD=/home
> LOGNAME=opc
> XDG_SESSION_TYPE=tty
> MODULESHOME=/usr/share/Modules
> MANPATH=/usr/share/man:
> MOTD_SHOWN=pam
> __MODULES_SHARE_MANPATH=:1
> HOME=/home/opc
> LANG=en_US.UTF-8
> LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.m4a=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.oga=01;36:*.opus=01;36:*.spx=01;36:*.xspf=01;36:
> SSH_CONNECTION=136.56.69.68 49876 10.0.0.153 22
> XDG_SESSION_CLASS=user
> SELINUX_ROLE_REQUESTED=
> TERM=xterm-256color
> LESSOPEN=||/usr/bin/lesspipe.sh %s
> USER=opc
> MODULES_RUN_QUARANTINE=LD_LIBRARY_PATH LD_PRELOAD
> LOADEDMODULES=
> SELINUX_USE_CURRENT_RANGE=
> SHLVL=1
> XDG_SESSION_ID=6
> XDG_RUNTIME_DIR=/run/user/1000
> SSH_CLIENT=136.56.69.68 49876 22
> __MODULES_LMINIT=module use --append /usr/share/Modules/modulefiles:module use --append /etc/modulefiles:module use --append /usr/share/modulefiles
> which_declare=declare -f
> PATH=/home/opc/.local/bin:/home/opc/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
> SELINUX_LEVEL_REQUESTED=
> MODULEPATH=/etc/scl/modulefiles:/usr/share/Modules/modulefiles:/etc/modulefiles:/usr/share/modulefiles
> DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
> MAIL=/var/spool/mail/opc
> SSH_TTY=/dev/pts/0
> MODULES_CMD=/usr/share/Modules/libexec/modulecmd.tcl
> BASH_FUNC_ml%%=() {  module ml "$@"
> }
> BASH_FUNC_which%%=() {  ( alias;
>  eval ${which_declare} ) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot $@
> }
> BASH_FUNC_module%%=() {  local _mlredir=1;
>  if [ -n "${MODULES_REDIRECT_OUTPUT+x}" ]; then
>  if [ "$MODULES_REDIRECT_OUTPUT" = '0' ]; then
>  _mlredir=0;
>  else
>  if [ "$MODULES_REDIRECT_OUTPUT" = '1' ]; then
>  _mlredir=1;
>  fi;
>  fi;
>  fi;
>  case " $@ " in 
>  *' --no-redirect '*)
>  _mlredir=0
>  ;;
>  *' --redirect '*)
>  _mlredir=1
>  ;;
>  esac;
>  if [ $_mlredir -eq 0 ]; then
>  _module_raw "$@";
>  else
>  _module_raw "$@" 2>&1;
>  fi
> }
> BASH_FUNC_scl%%=() {  if [ "$1" = "load" -o "$1" = "unload" ]; then
>  eval "module $@";
>  else
>  /usr/bin/scl "$@";
>  fi
> }
> BASH_FUNC__module_raw%%=() {  eval "$(/usr/bin/tclsh '/usr/share/Modules/libexec/modulecmd.tcl' bash "$@")";
>  _mlstatus=$?;
>  return $_mlstatus
> }
> _=/usr/bin/env
> OLDPWD=/home/opc
> ```

   Actually, it looks like you don't even need to set the `$PATH` for the SQLcl `/bin` directory. It [seems like](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/24.4/sqcug/working-sqlcl.html) the only dependency is Java. Onto Java, or GraalVM in this case.

#### 3.2.3 GraalVM 21 Enterprise Edition (based on Java 17 JDK)[^3.2.3]

Instructions on graalvm install in linux https://docs.oracle.com/en/learn/get-started-with-graalvm-on-oracle-linux/#task-2-install-graalvm-enterprise-oracle-linux
There are two commands that I issued. One for GraalVM, the other for the JavaScript component:

`sudo dnf install graalvm21-ee-17 -y`

`sudo dnf install graalvm21-ee-17-javascript`

Afterwhich, you need to set the `JAVA_HOME` environment variable, followed by setting it in the `PATH` environment variable.

The commands I issued, in order:

1. `sudo echo -e "export JAVA_HOME=/usr/lib64/graalvm/graalvm21-ee-17" >> ~/.bashrc`

2. `sudo echo -e 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc`

3. `source ~/.bashrc`

    > :memo: **NOTE:** The command line didn't like when I issued the `sudo source ~/.bashcr` command.

About source: https://ss64.com/bash/source.html

*Now* if I issue the `java -version` command I will see:

```sh
java version "17.0.14" 2025-01-21 LTS
Java(TM) SE Runtime Environment GraalVM EE 21.3.13 (build 17.0.14+8-LTS-jvmci-21.3-b98)
Java HotSpot(TM) 64-Bit Server VM GraalVM EE 21.3.13 (build 17.0.14+8-LTS-jvmci-21.3-b98, mixed mode, sharing)
```

[3.2.3]: Why GraalVM 21 Enterprise Edition (based on Java 17 JDK). Its a pretty stable release. At some point between GraalVM 21 and 23 (not to be confused with the Enterprise Edition which has its own versioning) deprecated the `gu` installer. So, trying to get the JavaScript component to work with later versions of GraalVM is a huge pain in the ass. I've wasted a couple weeks' worth of my time trying to figure it out. Until that user experience is improved, I'm staying with the Java 17 JDK-based GraalVM version. Java `7 JDK works just fine for both SQLcl and ORDS. I'd also like to set ORDS up to use some of the MLE/Js and GraphQL functionality. And GraalVM is required for both.

## 3.2.4 What do we know?

Here are some observations at this point (in no particular order): 

1. In the `/opt/oracle` directory, there are two sub-directories: `/ords` and `/sqlcl`.  

    The `opt/oracle/ords` directory consists of the following directories and files:  

    ```sh
    .  ..  bin  docs  examples  icons  lib  LICENSE.txt  linux-support  NOTICE.txt  ords.war  scripts  THIRD-PARTY-LICENSES.txt
    ```

    While the `opt/oracle/sqlcl` directory consists of:

    ```sh
    .  ..  bin  lib  LICENSE.txt  NOTICES.txt  THIRD-PARTY-LICENSES.txt
    ```

2. However, the `/etc` directory *also* has an `ords` directory *and* an `ords.conf` file. This `ords` directory contains a `config` subfolder. You cannot `cd` into it, even with the `sudo` prefix. You cannot `cd` or `cat` the `ords.conf` "thing" either.

    These are both located at: `/etc/ords` and `/etc/ords.conf`.

3. What happens when I switch to the `oracle` user, with the `sudo su - oracle` command? And *then* try to peek into these?  

    The `/opt/oracle/ords` is the same:

    ```sh
    .  ..  bin  docs  examples  icons  lib  LICENSE.txt  linux-support  NOTICE.txt  ords.war  scripts  THIRD-PARTY-LICENSES.txt
    ```

## 2.3.5 To-do

- [ ] Move through the *actual* ORDS installation. But test using the slient version of the `ords install adb`. It looks like there are [minimal requirements](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/24.4/ordig/installing-and-configuring-customer-managed-ords-autonomous-database.html#ORDIG-GUID-5EC91403-2176-4C62-8793-E32BBF3FE0D0).
- [ ] Review the how the ords folders have changed after each step
- [ ] Solving the `ords/bin` mystery; should you just go ahead and point to it as an environment variable (I think yes, and it probably couldnt hurt).
- [ ] Should you just go ahead and specify the configuration folder as well? Or should you just keep it as this:
`ords --config /etc/ords/config install adb`?
- [ ] Should we `mv` the database wallet.zip file, so it is *always* accessible, each time?
- [ ] How to automate the ords start-up/shut-down?

## 4. Performing the ORDS install

### 4.1 Setup

What you need for an ORDS ADB install: [Slient Install in ADB](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/24.4/ordig/installing-and-configuring-customer-managed-ords-autonomous-database.html#ORDIG-GUID-5EC91403-2176-4C62-8793-E32BBF3FE0D0):

- Database Pool: If this option is omitted, then the default database pool is used.
- Wallet Path: This is required if this option does not exist in the ORDS configuration database pool.
- Wallet Service Name: The TNS alias name from tnsnames.ora file contained in the wallet zip file. If this option is omitted, and the setting db.wallet.zip.service does not exist in the ORDS configuration database pool, then the wallet service name defaults to `[Your database "short name"]_LOW`.
- Administrator username and password (Required)
- Runtime database username and password (Required)
- PL/SQL gateway username and password (Required)
- Additional Database Features (What does this mean??)

#### 4.1.1 Install steps

1. Securely copy your database wallet from OCI, into your compute instance. You can do this with the following command:

```sh
scp -i [Your compute instance's private key] /the/locally/saved/path/to/your/wallet/Wallet_[your ADB "short name"].zip opc@[your compute instance's IP address]:/home/opc
```

About the Cloud Wallet, what is in it? https://docs.oracle.com/en-us/iaas/autonomous-database/doc/download-client-credentials.html

Switch to the `oracle` user. With the `sudo su - oracle` command.

tempadb
see gitignore*
TNS names are one of:

- `tempadb_high`
- `tempadb_low`
- `tempadb_medium`

For simplicity, the database admin and wallet passwords are the same.
Just need to move this from your downloads to your compute instance

Terraform has [a resource](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_autonomous_database_wallet) for doing this "locally". It looks like you the contents are derived from the var.tf file. That "stuff" all comes from the schema.yaml file.

> :exclamation: **NOTE:** Something to figure out when doing with terraform.

```sh
.  ..  .bash_history  .bash_logout  .bash_profile  .bashrc  .ssh  Wallet_tempadb.zip
```

In directory: `/home/opc/Wallet_tempadb.zip`

[Something to remember](https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/get-started.html#GUID-15CB716C-74A5-42E5-9BCA-7EC9C9FFA712). Does the `oracle:oinstall` command need to be used? I think I'm going to do this, since for the install the `Oracle` user is the one completing the ORDS install.

- Database Pool: If this option is omitted, then the default database pool is used.
- Wallet Path: This is required if this option does not exist in the ORDS configuration database pool.
- Wallet Service Name: The TNS alias name from tnsnames.ora file contained in the wallet zip file. If this option is omitted, and the setting db.wallet.zip.service does not exist in the ORDS configuration database pool, then the wallet service name defaults to <DB>_LOW.
- Administrator username and password (Required)
- Runtime database username and password (Required)
- PL/SQL gateway username and password (Required)
- Additional Database Features (What does this mean??)

At this point, or even sooner, we'd probably need to open up the ports for the compute instance, since ORDS will be running on either port 8080 (HTTP) or 8443 (HTTPS).

sudo firewall-cmd --permanent  --add-port=8080/tcp
sudo firewall-cmd --permanent  --add-port=443/tcp
sudo firewall-cmd --permanent  --add-port=80/tcp
sudo firewall-cmd --reload

https://firewalld.org/documentation/man-pages/firewall-cmd.html

Issuing the `sudo firewall-cmd --list-all-zones`, and you'll see the following:

```sh
block
  target: %%REJECT%%
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: 
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

dmz
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

drop
  target: DROP
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: 
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

external
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: yes
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

home
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client mdns samba-client ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

internal
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client mdns samba-client ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

nm-shared
  target: ACCEPT
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: dhcp dns ssh
  ports: 
  protocols: icmp ipv6-icmp
  forward: no
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
	rule priority="32767" reject

public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens3
  sources: 
  services: dhcpv6-client ssh
  ports: 8080/tcp 443/tcp 80/tcp
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

trusted
  target: ACCEPT
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: 
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

work
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

It looks like everything I just did "took":

```sh
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens3
  sources: 
  services: dhcpv6-client ssh
  ports: 8080/tcp 443/tcp 80/tcp
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

Ports 8080, 443, and 80 are available. I'm not sure if all or some are needed. Or if this is even correct.

chown -R 

Move the file from `/home/opc/Wallet_tempadb.zip` to `/home/oracle/Wallet_tempadb.zip`. And then change the ownership, like in [this example](https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/get-started.html#GUID-15CB716C-74A5-42E5-9BCA-7EC9C9FFA712).


sudo mv /home/opc/Wallet_tempadb.zip /home/oracle/Wallet_tempadb.zip

Issuing the `ls -a` you'll see the following: 

```sh
.  ..  .bash_history  .bash_logout  .bash_profile  .bashrc  .ssh
```

About the ls command: https://www.gnu.org/software/coreutils/manual/html_node/ls-invocation.html#ls_003a-List-directory-contents

The Wallet.zip file is gone.

Switch to the Oracle user with `sudo su - oracle`, then issue the `ls -l` command, to view file ownership properties. You'll see this:

```sh
total 24
-rw-r--r--. 1 opc opc 21975 Mar 17 20:55 Wallet_tempadb.zip
```

Great resource for what r, rw, r, etc means: https://www.redhat.com/en/blog/linux-file-permissions-explained

You'll see how the owner and owner group are still `opc`, you'll need to change the owner and group to oracle:oinstall (similar to the `passwords.txt` file like you'll see shortly). As the `opc` user, issue the following command: https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/get-started.html#GUID-15CB716C-74A5-42E5-9BCA-7EC9C9FFA712
about user/groups in linux: https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/identifying-an-oracle-software-owner-user-account.html

`sudo chown oracle:oinstall /home/oracle/Wallet_tempadb.zip`

Then switch back to the `oracle` user to view the changes to the file permissions. As the `oracle` user issue the `ls -l` command again, and you'll see: 

```sh
total 28
-rw-r--r--. 1 oracle oinstall    45 Mar 18 13:24 passwords.txt
-rw-r--r--. 1 oracle oinstall 21975 Mar 17 20:55 Wallet_tempadb.zip
```

This is good, you know have most of what you need to complete the ORDS *slient* ADB installation.

For silent installation, you'll need:

| Configuration option | Required | Command Option | Notes |
| -------------------- | :--------: | -------------- |  ----- |
|Database Pool         |        | | You can omit this, ORDS will default to the `/default` database pool. THIS IS OKAY!   |
|Wallet Path | :white_check_mark: | `--wallet /home/oracle/Wallet_tempadb.zip` | Either needs to exist in the same folder as the database pool's config directory, or you need to explicitly name it. Since the idea is to automate this stuff "on the fly," no configuration folders would exist. Its possible to recreate these folders and have them ready to go, but that is a more advanced set-up. |
|Wallet Service Name | | | If we don't include this, then it will simply default to the `Wallet_[the database_"short name"_low` service level. This is okay, that is what is in the default ADB ORDS anyways.|
|Admin username |:white_check_mark: | --admin-user ADMIN | This is the "Admin" unique to ADB. This doesn't exist for a non-ADB installation. You'd use something like PDB_DBA or PDBDBA for this.|
|Admin Password |:white_check_mark: |`--password-stdin < passwords.txt`| For simplicity, the passwords will all be identical. Maybe not the most ideal approach, but for automating, it will make things much smoother. |
|Runtime Username | :white_check_mark: | `--db-user ORDS_PUBLIC_USER_02` | You already have an `ORDS_PUBLIC_USER` in ADB. That is the "OG" ORDS runtime user. Each time you spin up a new compute instance, it's runtime user would be need to be something like: `ORDS_PUBLIC_USER_COMPUTE_XX` (where "XX" is a variable), or something similar. It just needs to be easily identifiable, easily tracked. |
|Runtime Password | :white_check_mark: | `--password-stdin < passwords.txt` option| Same notes as above. |
|PL/SQL Gateway Username | :white_check_mark: | `--gateway-user ORDS_PLSQL_GATEWAY_01` | An `ORDS_PLSQL_GATEWAY` user already exists. So you can name the subsequent users similar to how you've chosen for the `ORDS_PUBLIC_USER`. Something like: `ORDS_PLSQL_GATEWAY_COMPUTE_XX`|
|PL/SQL Gateway Password | :white_check_mark: | `--password-stdin < passwords.txt` | Same notes as above. |

touch passwords.txt
vi passwords.txt
press `i` key to insert text
Add the three passwords, one on each line for:

- `admin-user`
- `db-user`
- `gateway-user`
Press `esc` key, followed by `qw!` to save and exit
If you've forgotten the directory, issue the `pwd` command, and add your Wallet.zip file to the end of that path. This will be the value for your `--wallet` command option (see the table above).

At this point you should have everything you need to complete the install. You can issue the `ls -a` command to verify this: 

```sh
[oracle@testinstance01 ~]$ ls -a
.  ..  .bash_history  .bash_logout  .bash_profile  .bashrc  passwords.txt  .viminfo  Wallet_tempadb.zip
```

Installation Checklist
|Stuff| Ready/Complete | Notes |
| --- | :--------------:| --- |
| Correct Java set | <input type="checkbox"/> | GraalVM 17 or above if you want to take advantage of the `MLE/JS` and `GraphQL` features. |
| the ords/config/ folder path | | Remember way back when? You still have to include this too: `--config /etc/ords/config` |
| `passwords.txt` file + file path complete/ready | <input type="checkbox"/> | |
| `port 8080 open`| <input type="checkbox"/> |ORDS needs this for when it starts up, unless you are using HTTPS, then you'll need port 8443. |
| `port 80 open`| <input type="checkbox"/> | Why this? I believe the Network Health Checker uses port 80 for its health checking/reporting. |
| Wallet file ownership changed to `oracle:oinstall` | <input type="checkbox"/> | |
| ORDS CLI command options ready| <input type="checkbox"/> | see Configuration Settings table above | |

```sh
ords --config /etc/ords/config install adb --admin-user ADMIN --db-user ORDS_PUBLIC_USER_COMPUTE_01 --gateway-user ORDS_PLSQL_GATEWAY_COMPUTE_01 --wallet /home/oracle/Wallet_tempadb.zip --password-stdin < passwords.txt
```

Question about the `--config folder location`. We are told to include the folder path in the above command, as: `/etc/ords/config`. BUT, this entire time, we've been in the `/home/oracle` directory. Should we stay in this directory? Will the ORDS know how to "get to" the `/etc/ords/config` folder, even though you are in another directory? The `etc` folder is located a `/`, when you `cd` to it, you are located at `/etc`, cd further, till you are in the `config` folder, and you'll be at `/etc/ords/config`. I guess that makes sense, since `/` is the top. Same as if you were at `/home/oracle`. That initial `/` denotes the top-most level of your directories. So, it probably works. 

> :memo: **NOTE:** If you ever get lost as the `oracle` user. Meaning, if you've been navigating around the directories, and you just want to get back to "home base", I just `exit` as the `oracle` user, and then as the `opc` user I issue the `sudo su - oracle` again, that takes you back to the `/home/oracle` location. 

Running the `ords install...` command:

```sh
[oracle@testinstance01 ~]$ ords --config /etc/ords/config install adb --admin-user ADMIN --db-user ORDS_PUBLIC_USER_COMPUTE_01 --gateway-user ORDS_PLSQL_GATEWAY_COMPUTE_01 --wallet /home/oracle/Wallet_tempadb.zip --password-stdin < passwords.txt
```

And the output you'll see (unless of course you are automating, then you won't see any of this):

```sh
ORDS: Release 24.4 Production on Tue Mar 18 14:12:21 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

Oracle REST Data Services - Non-Interactive Customer Managed ORDS for Autonomous Database
Connecting to Autonomous database user: ADMIN TNS Service: TEMPADB_LOW
Retrieving information
The setting named: db.wallet.zip.path was set to: /home/oracle/Wallet_tempadb.zip in configuration: default
The setting named: db.wallet.zip.service was set to: TEMPADB_LOW in configuration: default
The setting named: db.username was set to: ORDS_PUBLIC_USER_COMPUTE_01 in configuration: default
The setting named: db.password was set to: ****** in configuration: default
The setting named: plsql.gateway.mode was set to: proxied in configuration: default
The setting named: security.requestValidationFunction was set to: ords_util.authorize_plsql_gateway in configuration: default
2025-03-18T14:12:24.073Z INFO        Created folder /home/oracle/logs
2025-03-18T14:12:24.074Z INFO        The log file is defaulted to the current working directory located at /home/oracle/logs
2025-03-18T14:12:24.325Z INFO        Connecting to Autonomous database user: ADMIN TNS Service: TEMPADB_LOW
2025-03-18T14:12:26.972Z INFO        ... Verifying Autonomous Database runtime user
2025-03-18T14:12:27.881Z INFO        ... Verifying Autonomous Database gateway user
2025-03-18T14:12:27.882Z INFO        Completed configuring for Customer Managed Oracle REST Data Services version 24.4.0.r3451601. Elapsed time: 00:00:03.553 

2025-03-18T14:12:27.885Z INFO        Log file written to /home/oracle/logs/ords_adb_2025-03-18_141224_07526.log
2025-03-18T14:12:27.890Z INFO        To run in standalone mode, use the ords serve command:
2025-03-18T14:12:27.891Z INFO        ords --config /etc/ords/config serve
2025-03-18T14:12:27.891Z INFO        Visit the ORDS Documentation to access tutorials, developer guides and more to help you get started with the new ORDS Command Line Interface (http://oracle.com/rest).
[oracle@testinstance01 ~]$ 
```

Review results and artifacts 

```sh
2025-03-18T14:12:27.885Z INFO        Log file written to /home/oracle/logs/ords_adb_2025-03-18_141224_07526.log
2025-03-18T14:12:27.890Z INFO        To run in standalone mode, use the ords serve command:
2025-03-18T14:12:27.891Z INFO        ords --config /etc/ords/config serve
```

You can see the new user schemas in your database, from the SQL Worksheet Navigator. 

we can now peek at the configuration folder, to see what has changed. 

You can `cd` straight to the `/etc/ords/config` with the `cd /etc/ords/config` command. And if you issue the `ls -a` command, you'll see two new folders: `databases` and `global`.

```sh
[oracle@testinstance01 config]$ ls -a
.  ..  databases  global
```

cd databases

```sh
[oracle@testinstance01 databases]$ ls -a
.  ..  default
```

```sh
[oracle@testinstance01 databases]$ cd default
[oracle@testinstance01 default]$ ls -a
.  ..  pool.xml  wallet
```

```sh
[oracle@testinstance01 default]$ cat pool.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on Tue Mar 18 14:12:24 UTC 2025</comment>
<entry key="db.username">ORDS_PUBLIC_USER_COMPUTE_01</entry>
<entry key="db.wallet.zip.path">/home/oracle/Wallet_tempadb.zip</entry>
<entry key="db.wallet.zip.service">TEMPADB_LOW</entry>
<entry key="plsql.gateway.mode">proxied</entry>
<entry key="security.requestValidationFunction">ords_util.authorize_plsql_gateway</entry>
</properties>
```

Either `cd ..` and `cd ..` again or simply `cd /etc/ords/config` so you are at the level where both `databases` and `global` folders are visisble:

```sh
[oracle@testinstance01 config]$ ls -a
.  ..  databases  global
```

```sh
[oracle@testinstance01 config]$ cd global
[oracle@testinstance01 global]$ ls -a
.  ..  settings.xml
```

```sh
[oracle@testinstance01 global]$ cat settings.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on Tue Mar 18 14:12:23 UTC 2025</comment>
</properties>
```

Review the ORDS install logs:

```sh
[oracle@testinstance01 ~]$ cd logs
[oracle@testinstance01 logs]$ ls -a
.  ..  ords_adb_2025-03-18_141224_07526.log
```

Then `cat ords_adb_2025-03-18_141224_07526.log`, you'll see the following:

```sh
[oracle@testinstance01 logs]$ cat ords_adb_2025-03-18_141224_07526.log
------------------------------------------------------------
Date       : 18 Mar 2025 14:12:24
Release    : Oracle REST Data Services 24.4.0.r3451601

Database   : Oracle Database 23ai Enterprise Edition  
DB Version : 23.7.0.25.03
------------------------------------------------------------
Container Name: BQJ5JPF7PVXPPQ5_TEMPADB
------------------------------------------------------------

[*** script: ords_runtime_user.sql] 

PL/SQL procedure successfully completed.

[*** script: ords_gateway_user.sql] 

PL/SQL procedure successfully completed.

[*** Info: Completed configuring for Customer Managed Oracle REST Data Services version 24.4.0.r3451601. Elapsed time: 00:00:03.553]
```

Just to be safe, and so we are all on the same page, navigate back to the `/home/oracle` directory. Issue the `pwd` command to view your current directory. Then issue the `ls -a` command to review the files in this directory (nothing will have changed, ths)

```sh
[oracle@testinstance01 ~]$ pwd 
/home/oracle
[oracle@testinstance01 ~]$ ls -a
.  ..  .bash_history  .bash_logout  .bash_profile  .bashrc  logs  passwords.txt  .viminfo  Wallet_tempadb.zip
[oracle@testinstance01 ~]$ 
```

[oracle@testinstance01 bin]$ pwd
/opt/oracle/ords/bin


`echo -e 'export PATH="$PATH:/opt/oracle/ords/bin"' >> ~/.bash_profile`
`source ~/.bash_profile`
`ords --config /etc/ords/config serve`


We used `./bashrc` when setting Java. But we use `./bash_profile` when setting the ORDS `/bin`, so what is it? What is preferred or more correct; `./bashrc` or `./bash_profile`? Details https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/24.4/ordig/installing-and-configuring-oracle-rest-data-services.html#GUID-D86804FC-4365-4499-B170-2F901C971D30

```sh
[opc@testinstance01 ~]$ echo -e 'export PATH="$PATH:/opt/oracle/ords/bin"' >> ~/.bash_profile
[opc@testinstance01 ~]$ source ~/.bash_profile
[opc@testinstance01 ~]$ env
SHELL=/bin/bash
HISTCONTROL=ignoredups
HISTSIZE=1000
HOSTNAME=testinstance01
JAVA_HOME=/usr/lib64/graalvm/graalvm21-ee-17
PWD=/home/opc
LOGNAME=opc
XDG_SESSION_TYPE=tty
MODULESHOME=/usr/share/Modules
MANPATH=/usr/share/man:
MOTD_SHOWN=pam
__MODULES_SHARE_MANPATH=:1
HOME=/home/opc
LANG=en_US.UTF-8
LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.m4a=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.oga=01;36:*.opus=01;36:*.spx=01;36:*.xspf=01;36:
SSH_CONNECTION=136.56.69.68 52993 10.0.0.153 22
SSH_CONNECTION=136.56.69.68 52993 10.0.0.153 22
XDG_SESSION_CLASS=user
SELINUX_ROLE_REQUESTED=
TERM=xterm-256color
LESSOPEN=||/usr/bin/lesspipe.sh %s
USER=opc
MODULES_RUN_QUARANTINE=LD_LIBRARY_PATH LD_PRELOAD
LOADEDMODULES=
SELINUX_USE_CURRENT_RANGE=
SHLVL=1
XDG_SESSION_ID=889
XDG_RUNTIME_DIR=/run/user/1000
SSH_CLIENT=136.56.69.68 52993 22
__MODULES_LMINIT=module use --append /usr/share/Modules/modulefiles:module use --append /etc/modulefiles:module use --append /usr/share/modulefiles
which_declare=declare -f
PATH=/usr/lib64/graalvm/graalvm21-ee-17/bin:/usr/lib64/graalvm/graalvm21-ee-17/bin:/home/opc/.local/bin:/home/opc/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/opt/oracle/ords/bin
SELINUX_LEVEL_REQUESTED=
MODULEPATH=/etc/scl/modulefiles:/usr/share/Modules/modulefiles:/etc/modulefiles:/usr/share/modulefiles
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
MAIL=/var/spool/mail/opc
SSH_TTY=/dev/pts/0
MODULES_CMD=/usr/share/Modules/libexec/modulecmd.tcl
BASH_FUNC_ml%%=() {  module ml "$@"
}
BASH_FUNC_which%%=() {  ( alias;
 eval ${which_declare} ) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot $@
}
BASH_FUNC_module%%=() {  local _mlredir=1;
 if [ -n "${MODULES_REDIRECT_OUTPUT+x}" ]; then
 if [ "$MODULES_REDIRECT_OUTPUT" = '0' ]; then
 _mlredir=0;
 else
 if [ "$MODULES_REDIRECT_OUTPUT" = '1' ]; then
 _mlredir=1;
 fi;
 fi;
 fi;
 case " $@ " in 
 *' --no-redirect '*)
 _mlredir=0
 ;;
 *' --redirect '*)
 _mlredir=1
 ;;
 esac;
 if [ $_mlredir -eq 0 ]; then
 _module_raw "$@";
 else
 _module_raw "$@" 2>&1;
 fi
}
BASH_FUNC_scl%%=() {  if [ "$1" = "load" -o "$1" = "unload" ]; then
 eval "module $@";
 else
 /usr/bin/scl "$@";
 fi
}
BASH_FUNC__module_raw%%=() {  eval "$(/usr/bin/tclsh '/usr/share/Modules/libexec/modulecmd.tcl' bash "$@")";
 _mlstatus=$?;
 return $_mlstatus
}
```

```sh
[opc@testinstance01 ~]$ sudo su - oracle
Last login: Tue Mar 18 14:55:24 GMT 2025 on pts/0
[oracle@testinstance01 ~]$ env
SHELL=/bin/bash
HISTCONTROL=ignoredups
HISTSIZE=1000
HOSTNAME=testinstance01
PWD=/home/oracle
LOGNAME=oracle
MODULESHOME=/usr/share/Modules
MANPATH=/usr/share/man:
__MODULES_SHARE_MANPATH=:1
HOME=/home/oracle
LANG=en_US.UTF-8
LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.m4a=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.oga=01;36:*.opus=01;36:*.spx=01;36:*.xspf=01;36:
TERM=xterm-256color
LESSOPEN=||/usr/bin/lesspipe.sh %s
USER=oracle
MODULES_RUN_QUARANTINE=LD_LIBRARY_PATH LD_PRELOAD
LOADEDMODULES=
SHLVL=1
__MODULES_LMINIT=module use --append /usr/share/Modules/modulefiles:module use --append /etc/modulefiles:module use --append /usr/share/modulefiles
which_declare=declare -f
PATH=/home/oracle/.local/bin:/home/oracle/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
MODULEPATH=/etc/scl/modulefiles:/usr/share/Modules/modulefiles:/etc/modulefiles:/usr/share/modulefiles
MAIL=/var/spool/mail/oracle
MODULES_CMD=/usr/share/Modules/libexec/modulecmd.tcl
BASH_FUNC_ml%%=() {  module ml "$@"
}
BASH_FUNC_which%%=() {  ( alias;
 eval ${which_declare} ) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot $@
}
BASH_FUNC_module%%=() {  local _mlredir=1;
 if [ -n "${MODULES_REDIRECT_OUTPUT+x}" ]; then
 if [ "$MODULES_REDIRECT_OUTPUT" = '0' ]; then
 _mlredir=0;
 else
 if [ "$MODULES_REDIRECT_OUTPUT" = '1' ]; then
 _mlredir=1;
 fi;
 fi;
 fi;
 case " $@ " in 
 *' --no-redirect '*)
 _mlredir=0
 ;;
 *' --redirect '*)
 _mlredir=1
 ;;
 esac;
 if [ $_mlredir -eq 0 ]; then
 _module_raw "$@";
 else
 _module_raw "$@" 2>&1;
 fi
}
BASH_FUNC_scl%%=() {  if [ "$1" = "load" -o "$1" = "unload" ]; then
 eval "module $@";
 else
 /usr/bin/scl "$@";
 fi
}
BASH_FUNC__module_raw%%=() {  eval "$(/usr/bin/tclsh '/usr/share/Modules/libexec/modulecmd.tcl' bash "$@")";
 _mlstatus=$?;
 return $_mlstatus
}
_=/usr/bin/env
```

Should you as oracle or opc? 

Even though you set the ords/bin path as the opc user, everything still seems to work even if you issue the `ords --config /etc/ords/config serve` as the oracle user.

```sh
[oracle@testinstance01 ~]$ ords --config /etc/ords/config serve
```

And output you'll see:

```sh
ORDS: Release 24.4 Production on Tue Mar 18 14:59:48 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

2025-03-18T14:59:48.756Z INFO        HTTP and HTTP/2 cleartext listening on host: 0.0.0.0 port: 8080
2025-03-18T14:59:48.786Z INFO        Disabling document root because the specified folder does not exist: /etc/ords/config/global/doc_root
2025-03-18T14:59:48.787Z INFO        Default forwarding from / to contextRoot configured.
2025-03-18T14:59:52.723Z INFO        Configuration properties for: |default|lo|
java.specification.version=17
conf.use.wallet=true
sun.jnu.encoding=UTF-8
user.region=US
java.class.path=/opt/oracle/ords/ords.war
java.vm.vendor=Oracle Corporation
sun.arch.data.model=64
nashorn.args=--no-deprecation-warning
java.vendor.url=https://java.oracle.com/
resource.templates.enabled=false
user.timezone=UTC
java.vm.specification.version=17
os.name=Linux
sun.java.launcher=SUN_STANDARD
user.country=US
sun.boot.library.path=/usr/lib64/graalvm/graalvm21-ee-java17/lib
sun.java.command=/opt/oracle/ords/ords.war --config /etc/ords/config serve
jdk.debug=release
sun.cpu.endian=little
user.home=/home/oracle
oracle.dbtools.launcher.executable.jar.path=/opt/oracle/ords/ords.war
user.language=en
sun.stderr.encoding=UTF-8
java.specification.vendor=Oracle Corporation
java.version.date=2025-01-21
java.home=/usr/lib64/graalvm/graalvm21-ee-java17
db.username=ORDS_PUBLIC_USER_COMPUTE_01
file.separator=/
java.vm.compressedOopsMode=Zero based
jdk.internal.vm.ci.enabled=true
line.separator=

sun.stdout.encoding=UTF-8
java.specification.name=Java Platform API Specification
java.vm.specification.vendor=Oracle Corporation
java.awt.headless=true
db.password=******
sun.management.compiler=HotSpot 64-Bit Tiered Compilers
security.requestValidationFunction=ords_util.authorize_plsql_gateway
db.wallet.zip.service=TEMPADB_LOW
java.runtime.version=17.0.14+8-LTS-jvmci-21.3-b98
user.name=oracle
path.separator=:
os.version=5.15.0-305.176.4.el9uek.x86_64
java.runtime.name=Java(TM) SE Runtime Environment
file.encoding=UTF-8
plsql.gateway.mode=proxied
db.wallet.zip.path=/home/oracle/Wallet_tempadb.zip
java.vm.name=Java HotSpot(TM) 64-Bit Server VM
java.vendor.version=GraalVM EE 21.3.13
java.vendor.url.bug=https://bugreport.java.com/bugreport/
java.io.tmpdir=/tmp
oracle.dbtools.cmdline.ShellCommand=ords
java.version=17.0.14
user.dir=/home/oracle
os.arch=amd64
java.vm.specification.name=Java Virtual Machine Specification
oracle.dbtools.cmdline.home=/opt/oracle/ords
native.encoding=UTF-8
java.library.path=/usr/java/packages/lib:/usr/lib64:/lib64:/lib:/usr/lib
java.vendor=Oracle Corporation
java.vm.info=mixed mode, sharing
java.vm.version=17.0.14+8-LTS-jvmci-21.3-b98
java.specification.maintenance.version=1
sun.io.unicode.encoding=UnicodeLittle
java.class.version=61.0

2025-03-18T14:59:52.806Z WARNING     *** jdbc.MaxLimit in configuration |default|lo| is using a value of 10, this setting may not be sized adequately for a production environment ***
2025-03-18T14:59:53.294Z INFO        

Mapped local pools from /etc/ords/config/databases:
  /ords/                              => default                        => VALID     


2025-03-18T14:59:53.380Z INFO        Oracle REST Data Services initialized
Oracle REST Data Services version : 24.4.0.r3451601
Oracle REST Data Services server info: jetty/12.0.13
Oracle REST Data Services java info: Java HotSpot(TM) 64-Bit Server VM GraalVM EE 21.3.13 (build: 17.0.14+8-LTS-jvmci-21.3-b98 mixed mode, sharing)
```

Kill the process and review logs 
How do I navigate to the landing page for this compute instance? 

[oracle@testinstance01 /]$ cd etc/ords/config
[oracle@testinstance01 config]$ ls -a
.  ..  databases  global
[oracle@testinstance01 config]$ 

```sh
[oracle@testinstance01 config]$ ords config --help
2025-03-18T15:29:57Z INFO   ORDS has not detected the option '--config' and this will be set up to the default directory.

ORDS: Release 24.4 Production on Tue Mar 18 15:29:59 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config


Usage:
  ords config [OPTIONS] [COMMAND]

Configure application and database connection pool settings

Options:
        --db-pool <string>       The name of the database connection pool to
                                 configure

    -h, --help                   Show usage information for the command

        --quiet                  Hides the banner, copyright and configuration
                                 location information.

Commands:
        delete                   Remove the specified configuration setting

        get                      Show the value of the specified configuration
                                 setting. Sensitive values will be replaced
                                 with: ******

        info                     Describe the specified configuration setting

        list                     List all explicitly configured pool and global
                                 settings

        secret                   Securely store a sensitive configuration
                                 setting such as: db.password

        set                      Set the configuration setting to the specified
                                 value. Sensitive values cannot be set using
                                 this method, use the secret command instead

        user                     Create or update a user and its password and
                                 roles. Display the user information.
```

```sh
[oracle@testinstance01 config]$ ords config list --include-defaults
```

```sh
2025-03-18T15:35:18Z INFO   ORDS has not detected the option '--config' and this will be set up to the default directory.

ORDS: Release 24.4 Production on Tue Mar 18 15:35:20 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

Database pool: default
INFO: The configuration does not have any global settings specified.

Setting                                     Value                                   Source     
-----------------------------------------   -------------------------------------   -----------
apex.security.administrator.roles           SQL Developer, OAuth Client Developer   Default    
apex.security.developer.roles               SQL Developer, OAuth Client Developer   Default    
apex.security.user.roles                                                            Default    
cache.metadata.enabled                      true                                    Default    
cache.metadata.graphql.expireAfterAccess    1m                                      Default    
cache.metadata.graphql.expireAfterWrite     2m                                      Default    
cache.metadata.timeout                      5s                                      Default    
database.api.enabled                        false                                   Default    
database.api.management.services.disabled   false                                   Default    
db.adminUser                                                                        Default    
db.adminUser.password                                                               Default    
db.cdb.adminUser                                                                    Default    
db.cdb.adminUser.password                                                           Default    
db.connectionType                                                                   Default    
db.credentialsSource                        POOL                                    Default    
db.customURL                                                                        Default    
db.hostname                                                                         Default    
db.idlePoolTimeout                                                                  Default    
db.invalidPoolTimeout                       15m                                     Default    
db.password                                 ******                                  Pool Wallet
db.poolDestroyTimeout                       5m                                      Default    
db.port                                     1521                                    Default    
db.serviceNameSuffix                                                                Default    
db.servicename                                                                      Default    
db.sid                                                                              Default    
db.tnsAliasName                                                                     Default    
db.tnsDirectory                                                                     Default    
db.username                                 ORDS_PUBLIC_USER_COMPUTE_01             Pool       
db.wallet.cache                             /tmp/ords-wallet-cache                  Default    
db.wallet.zip                                                                       Default    
db.wallet.zip.path                          /home/oracle/Wallet_tempadb.zip         Pool       
db.wallet.zip.service                       TEMPADB_LOW                             Pool       
debug.printDebugToScreen                    false                                   Default    
debug.trackResources                        false                                   Default    
error.externalPath                                                                  Default    
error.responseFormat                        AUTO                                    Default    
feature.grahpql.max.nesting.depth           5                                       Default    
feature.graphql                             ENABLED                                 Default    
feature.openservicebroker.exclude           false                                   Default    
feature.predispatchTasks                    false                                   Default    
feature.sdw                                 false                                   Default    
feature.sdw.selfServiceSchema               false                                   Default    
feature.serviceconsole                      false                                   Default    
http.cookie.filter                                                                  Default    
http.cookie.filter.byValue                                                          Default    
icap.port                                                                           Default    
icap.secure.port                                                                    Default    
icap.server                                                                         Default    
instance.api.enabled                        false                                   Default    
jdbc.ConnectionWaitTimeout                  3                                       Default    
jdbc.DriverType                             thin                                    Default    
jdbc.InactivityTimeout                      1800                                    Default    
jdbc.InitialLimit                           0                                       Default    
jdbc.MaxConnectionReuseCount                1000                                    Default    
jdbc.MaxLimit                               10                                      Default    
jdbc.MaxStatementsLimit                     10                                      Default    
jdbc.MinLimit                               2                                       Default    
jdbc.auth.admin.role                                                                Default    
jdbc.auth.enabled                           false                                   Default    
jdbc.cleanup.mode                           RECYCLE                                 Default    
jdbc.driverName                                                                     Default    
jdbc.statementTimeout                       900s                                    Default    
jdbc.ucp.enableJMX                          true                                    Default    
json.sdo.geometry.output.geojson            false                                   Default    
misc.defaultPage                            apex                                    Default    
misc.pagination.maxRows                     10000                                   Default    
mongo.access.log                                                                    Default    
mongo.enabled                               false                                   Default    
mongo.host                                  0.0.0.0                                 Default    
mongo.idle.timeout                          30m                                     Default    
mongo.op.timeout                            10m                                     Default    
mongo.port                                  27017                                   Default    
mongo.tls                                   true                                    Default    
ocid.dbtools.connection                                                             Default    
oracle.jdbc.vectorDefaultGetObjectType      String                                  Default    
owa.docTable                                                                        Default    
owa.trace.sql                               false                                   Default    
plsql.gateway.mode                          proxied                                 Pool       
procedure.postProcess                                                               Default    
procedure.preProcess                                                                Default    
procedure.rest.preHook                                                              Default    
public.properties.url                                                               Default    
request.traceHeaderName                     Request-Id                              Default    
resource.templates.enabled                  false                                   Default    
restEnabledSql.active                       false                                   Default    
restXMLModules.active                       true                                    Default    
security.credentials.attempts               -1                                      Default    
security.credentials.file                                                           Default    
security.credentials.lock.time              10m                                     Default    
security.disableDefaultExclusionList        false                                   Default    
security.exclusionList                                                              Default    
security.externalSessionTrustedOrigins                                              Default    
security.httpsHeaderCheck                                                           Default    
security.inclusionList                                                              Default    
security.jwks.connection.timeout            5s                                      Default    
security.jwks.read.timeout                  5s                                      Default    
security.jwks.refresh.interval              10s                                     Default    
security.jwks.size                          100000                                  Default    
security.jwt.allowed.age                    -1s                                     Default    
security.jwt.allowed.skew                   0s                                      Default    
security.jwt.authenticators                 DATABASE                                Default    
security.jwt.profile.enabled                true                                    Default    
security.maxEntries                         2000                                    Default    
security.par.enabled                        true                                    Default    
security.requestAuthenticationFunction                                              Default    
security.requestValidationFunction          ords_util.authorize_plsql_gateway       Pool       
security.validationFunctionType             plsql                                   Default    
security.verifySSL                          true                                    Default    
standalone.access.log                                                               Default    
standalone.access.log.retainDays            90                                      Default    
standalone.binds                            0.0.0.0                                 Default    
standalone.context.path                     /ords                                   Default    
standalone.doc.root                         ${config.url}/global/doc_root           Default    
standalone.http.port                        8080                                    Default    
standalone.https.cert                                                               Default    
standalone.https.cert.key                                                           Default    
standalone.https.host                                                               Default    
standalone.https.port                       8443                                    Default    
standalone.static.context.path              /i                                      Default    
standalone.static.path                                                              Default    
standalone.stop.timeout                     10s                                     Default    
```

```sh
[oracle@testinstance01 config]$ ords --config /etc/ords/config config set feature.sdw true

ORDS: Release 24.4 Production on Tue Mar 18 15:37:51 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

The setting named: feature.sdw was set to: true in configuration: default
```

```sh
[oracle@testinstance01 config]$ ords --config /etc/ords/config config list --include-defaults

ORDS: Release 24.4 Production on Tue Mar 18 15:38:23 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

Database pool: default
INFO: The configuration does not have any global settings specified.

Setting                                     Value                                   Source     
-----------------------------------------   -------------------------------------   -----------
apex.security.administrator.roles           SQL Developer, OAuth Client Developer   Default    
apex.security.developer.roles               SQL Developer, OAuth Client Developer   Default    
apex.security.user.roles                                                            Default    
cache.metadata.enabled                      true                                    Default    
cache.metadata.graphql.expireAfterAccess    1m                                      Default    
cache.metadata.graphql.expireAfterWrite     2m                                      Default    
cache.metadata.timeout                      5s                                      Default    
database.api.enabled                        false                                   Default    
database.api.management.services.disabled   false                                   Default    
db.adminUser                                                                        Default    
db.adminUser.password                                                               Default    
db.cdb.adminUser                                                                    Default    
db.cdb.adminUser.password                                                           Default    
db.connectionType                                                                   Default    
db.credentialsSource                        POOL                                    Default    
db.customURL                                                                        Default    
db.hostname                                                                         Default    
db.idlePoolTimeout                                                                  Default    
db.invalidPoolTimeout                       15m                                     Default    
db.password                                 ******                                  Pool Wallet
db.poolDestroyTimeout                       5m                                      Default    
db.port                                     1521                                    Default    
db.serviceNameSuffix                                                                Default    
db.servicename                                                                      Default    
db.sid                                                                              Default    
db.tnsAliasName                                                                     Default    
db.tnsDirectory                                                                     Default    
db.username                                 ORDS_PUBLIC_USER_COMPUTE_01             Pool       
db.wallet.cache                             /tmp/ords-wallet-cache                  Default    
db.wallet.zip                                                                       Default    
db.wallet.zip.path                          /home/oracle/Wallet_tempadb.zip         Pool       
db.wallet.zip.service                       TEMPADB_LOW                             Pool       
debug.printDebugToScreen                    false                                   Default    
debug.trackResources                        false                                   Default    
error.externalPath                                                                  Default    
error.responseFormat                        AUTO                                    Default    
feature.grahpql.max.nesting.depth           5                                       Default    
feature.graphql                             ENABLED                                 Default    
feature.openservicebroker.exclude           false                                   Default    
feature.predispatchTasks                    false                                   Default    
feature.sdw                                 true                                    Pool       
feature.sdw.selfServiceSchema               false                                   Default    
feature.serviceconsole                      false                                   Default    
http.cookie.filter                                                                  Default    
http.cookie.filter.byValue                                                          Default    
icap.port                                                                           Default    
icap.secure.port                                                                    Default    
icap.server                                                                         Default    
instance.api.enabled                        false                                   Default    
jdbc.ConnectionWaitTimeout                  3                                       Default    
jdbc.DriverType                             thin                                    Default    
jdbc.InactivityTimeout                      1800                                    Default    
jdbc.InitialLimit                           0                                       Default    
jdbc.MaxConnectionReuseCount                1000                                    Default    
jdbc.MaxLimit                               10                                      Default    
jdbc.MaxStatementsLimit                     10                                      Default    
jdbc.MinLimit                               2                                       Default    
jdbc.auth.admin.role                                                                Default    
jdbc.auth.enabled                           false                                   Default    
jdbc.cleanup.mode                           RECYCLE                                 Default    
jdbc.driverName                                                                     Default    
jdbc.statementTimeout                       900s                                    Default    
jdbc.ucp.enableJMX                          true                                    Default    
json.sdo.geometry.output.geojson            false                                   Default    
misc.defaultPage                            apex                                    Default    
misc.pagination.maxRows                     10000                                   Default    
mongo.access.log                                                                    Default    
mongo.enabled                               false                                   Default    
mongo.host                                  0.0.0.0                                 Default    
mongo.idle.timeout                          30m                                     Default    
mongo.op.timeout                            10m                                     Default    
mongo.port                                  27017                                   Default    
mongo.tls                                   true                                    Default    
ocid.dbtools.connection                                                             Default    
oracle.jdbc.vectorDefaultGetObjectType      String                                  Default    
owa.docTable                                                                        Default    
owa.trace.sql                               false                                   Default    
plsql.gateway.mode                          proxied                                 Pool       
procedure.postProcess                                                               Default    
procedure.preProcess                                                                Default    
procedure.rest.preHook                                                              Default    
public.properties.url                                                               Default    
request.traceHeaderName                     Request-Id                              Default    
resource.templates.enabled                  false                                   Default    
restEnabledSql.active                       false                                   Default    
restXMLModules.active                       true                                    Default    
security.credentials.attempts               -1                                      Default    
security.credentials.file                                                           Default    
security.credentials.lock.time              10m                                     Default    
security.disableDefaultExclusionList        false                                   Default    
security.exclusionList                                                              Default    
security.externalSessionTrustedOrigins                                              Default    
security.httpsHeaderCheck                                                           Default    
security.inclusionList                                                              Default    
security.jwks.connection.timeout            5s                                      Default    
security.jwks.read.timeout                  5s                                      Default    
security.jwks.refresh.interval              10s                                     Default    
security.jwks.size                          100000                                  Default    
security.jwt.allowed.age                    -1s                                     Default    
security.jwt.allowed.skew                   0s                                      Default    
security.jwt.authenticators                 DATABASE                                Default    
security.jwt.profile.enabled                true                                    Default    
security.maxEntries                         2000                                    Default    
security.par.enabled                        true                                    Default    
security.requestAuthenticationFunction                                              Default    
security.requestValidationFunction          ords_util.authorize_plsql_gateway       Pool       
security.validationFunctionType             plsql                                   Default    
security.verifySSL                          true                                    Default    
standalone.access.log                                                               Default    
standalone.access.log.retainDays            90                                      Default    
standalone.binds                            0.0.0.0                                 Default    
standalone.context.path                     /ords                                   Default    
standalone.doc.root                         ${config.url}/global/doc_root           Default    
standalone.http.port                        8080                                    Default    
standalone.https.cert                                                               Default    
standalone.https.cert.key                                                           Default    
standalone.https.host                                                               Default    
standalone.https.port                       8443                                    Default    
standalone.static.context.path              /i                                      Default    
standalone.static.path                                                              Default    
standalone.stop.timeout                     10s                                     Default
```

```sh
[oracle@testinstance01 databases]$ cd default
[oracle@testinstance01 default]$ ls -a
.  ..  pool.xml  wallet
[oracle@testinstance01 default]$ cat pool.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on Tue Mar 18 15:37:52 UTC 2025</comment>
<entry key="db.username">ORDS_PUBLIC_USER_COMPUTE_01</entry>
<entry key="db.wallet.zip.path">/home/oracle/Wallet_tempadb.zip</entry>
<entry key="db.wallet.zip.service">TEMPADB_LOW</entry>
<entry key="feature.sdw">true</entry>
<entry key="plsql.gateway.mode">proxied</entry>
<entry key="security.requestValidationFunction">ords_util.authorize_plsql_gateway</entry>
</properties>
```

```sh
[oracle@testinstance01 global]$ ords --config /etc/ords/config config set database.api.enabled true

ORDS: Release 24.4 Production on Tue Mar 18 15:53:04 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

The global setting named: database.api.enabled was set to: true
[oracle@testinstance01 global]$ ords --config /etc/ords/config config set restEnabledSql.active true

ORDS: Release 24.4 Production on Tue Mar 18 15:53:13 2025

Copyright (c) 2010, 2025, Oracle.

Configuration:
  /etc/ords/config

The setting named: restEnabledSql.active was set to: true in configuration: default
```

```sh
[oracle@testinstance01 global]$ cat settings.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on Tue Mar 18 15:53:04 UTC 2025</comment>
<entry key="database.api.enabled">true</entry>
</properties>
```

```sh
[oracle@testinstance01 default]$ cat pool.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on Tue Mar 18 15:53:13 UTC 2025</comment>
<entry key="db.username">ORDS_PUBLIC_USER_COMPUTE_01</entry>
<entry key="db.wallet.zip.path">/home/oracle/Wallet_tempadb.zip</entry>
<entry key="db.wallet.zip.service">TEMPADB_LOW</entry>
<entry key="feature.sdw">true</entry>
<entry key="plsql.gateway.mode">proxied</entry>
<entry key="restEnabledSql.active">true</entry>
<entry key="security.requestValidationFunction">ords_util.authorize_plsql_gateway</entry>
</properties>
```

*If you do not include the `--feature-sdw <BOOLEAN>` and then you change your mind later. It isn't enough to just issue the `ords config set feature.sdw true` command. Because, your `database.api.enabled` and `restEnabledSql.active` are not set at this time, so you still have to configure them manually. 

I believe for a High-availability set-up, you don't need access to Database Actions. Since this set up is probably more geared toward/for REST APIs only. 

