# archive-rsync

## ABOUT

This Bash script uses my
[get-mnt.sh](https://github.com/brianchase/get-mnt) to back up local
files to a mounted device with [rsync](https://rsync.samba.org/).

## HOW IT WORKS

You can run the script without options to use its default settings or
run it with options to override them. The options are as follows:

```
$ archive-rsync.sh [-r] [-s PATH] [-d PATH]
```

By default, the script syncs files from `$HOME/Archive` to a mounted
device, such as a USB thumb drive. To get the path of that
destination, the script uses
[get-mnt.sh](https://github.com/brianchase/get-mnt), which allows you
to select a mounted device for the backup or to mount one and then
select it. For more information on how this aspect of the script
works, please see the documentation for
[get-mnt.sh](https://github.com/brianchase/get-mnt) and its associated
script – the crucial piece, really –
[mnt-dev.sh](https://github.com/brianchase/mnt-dev).

To use a different default source directory in `$HOME` than `Archive`,
change the value of the variable `DIR` on line four of the script:

```
DIR="Archive"
```

Alternatively, specify a different source directory with `-s PATH`:

```
$ archive-rsync.sh -s /new/source/path
```

You may specify a different destination directory with `-d PATH`:

```
$ archive-rsync.sh -d /new/destination/path
```

You may also change both at once:

```
$ archive-rsync.sh -s /new/source/path -d /new/destination/path
```

Since you can change source and destination directories, you can use
the script without using
[get-mnt.sh](https://github.com/brianchase/get-mnt). But on some
conditions, the script checks whether
[get-mnt.sh](https://github.com/brianchase/get-mnt) is in your path
and executable and, if so, asks whether to mount a connected device –
for example, if the script can't find the source directory. In that
case, if you follow the prompts to mount a device, and the source is
still missing, the script exits with an error.

The conditions surrounding the destination directory are more
complicated. Since [rsync](https://rsync.samba.org/) can create the
directory at the end of the destination path, it's not necessarily a
problem if the full path doesn't exist. If it does, it must be
writable, else the script exits with an error. If it doesn't, its
parent must exist and be writable, else the script exits with an
error. Here, too, the script may check whether
[get-mnt.sh](https://github.com/brianchase/get-mnt) is in your path
and executable and ask whether to mount a connected device.

In short, for both the source and destination, you may specify
directories on connected devices and mount them before running
[rsync](https://rsync.samba.org/).

You may, in effect, reverse the default source and destination with
`-r`:

```
$ archive-rsync.sh -r
```

This syncs from `Archive` on a mounted device to `$HOME`.

Among other precautions, the script exits with an error if the
destination has insufficient space for the source. Regardless, beware
that the script can't save you from every foolish mistake. Please
inspect and test it before using it. You could lose data otherwise!

If all goes well, the script runs [rsync](https://rsync.samba.org/)
with options `-amu --delete --progress`. Last, if the script used
[get-mnt.sh](https://github.com/brianchase/get-mnt) to mount a device,
the script asks to unmount it.

## PORTABILITY

Since the script uses arrays, it's not strictly
[POSIX](https://en.wikipedia.org/wiki/POSIX)-compliant. As a result,
it isn't compatible with
[Dash](http://gondor.apana.org.au/~herbert/dash/) and probably a good
number of other shells.

## LICENSE

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## REQUIREMENTS

* [rsync](https://rsync.samba.org/)
* [get-mnt](https://github.com/brianchase/get-mnt) (for default settings)

