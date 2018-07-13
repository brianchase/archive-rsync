# archive-rsync

## ABOUT

This Bash script uses [get-mnt](https://github.com/brianchase/get-mnt)
for backing up files with [rsync](https://rsync.samba.org/).

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
* [get-mnt](https://github.com/brianchase/get-mnt)

