# rankmirrors-arm
rankmirrors-arm sorts your Pacman mirrorlist using the rankmirrors utility on archlinuxarm systems.

*Note*: You need pacman-contrib package (https://archlinuxarm.org/packages/armv7h/pacman-contrib) installed to get the rankmirrors utility.

## Usage:
```
rankmirrors-arm.sh [-p | -g | -f MIRRORLIST] [-n | -m] [-o]
```
### General Options:
- `-o/--output`       do not overwrite pacman mirrorlist, only show generated mirrorlist

### Source Options:   select one (default: --pacman)
- `-p/--pacman`       use the current pacman mirrorlist
- `-g/--get`          get the current mirrorlist from archlinuxarm's pacman-mirrorlist sources
- `-f/--file`         use the specified MIRRORFILE

### Rankmirrors Options:  passed on to rankmirrors tool
- `-n NUM`            number of servers to output, 0 for all
- `-m/--max-time NUM` specify a ranking operation timeout, can be decimal number

### Environment Variables:
- `PACMIRRORLIST`     override pacman mirrorlist path (default: /etc/pacman.d/mirrorlist)

#### Examples:
- `PACMIRRORLIST="/etc/pacman.d/local_mirrorlist" rankmirrors.sh`
- `rankmirrors.sh --pacman -n 6 --output
