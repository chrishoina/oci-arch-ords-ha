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

There are two commands that I issued. One for GraalVM, the other for the JavaScript component:

`sudo dnf install graalvm21-ee-17 -y`

`sudo dnf install graalvm21-ee-17-javascript`

Afterwhich, you need to set the `JAVA_HOME` environment variable, followed by setting it in the `PATH` environment variable.

The commands I issued, in order:

1. `sudo echo -e "export JAVA_HOME=/usr/lib64/graalvm/graalvm21-ee-17" >> ~/.bashrc`

2. `sudo echo -e 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc`

3. `source ~/.bashrc`

    > :memo: **NOTE:** The command line didn't like when I issued the `sudo source ~/.bashcr` command.

*Now* if I issue the `java -version` command I will see:

```sh
java version "17.0.14" 2025-01-21 LTS
Java(TM) SE Runtime Environment GraalVM EE 21.3.13 (build 17.0.14+8-LTS-jvmci-21.3-b98)
Java HotSpot(TM) 64-Bit Server VM GraalVM EE 21.3.13 (build 17.0.14+8-LTS-jvmci-21.3-b98, mixed mode, sharing)
```

[3.2.3]: Why GraalVM 21 Enterprise Edition (based on Java 17 JDK). Its a pretty stable release. At some point between GraalVM 21 and 23 (not to be confused with the Enterprise Edition which has its own versioning) deprecated the `gu` installer. So, trying to get the JavaScript component to work with later versions of GraalVM is a huge pain in the ass. I've wasted a couple weeks' worth of my time trying to figure it out. Until that user experience is improved, I'm staying with the Java 17 JDK-based GraalVM version. Java `7 JDK works just fine for both SQLcl and ORDS. I'd also like to set ORDS up to use some of the MLE/Js and GraphQL functionality. And GraalVM is required for both.