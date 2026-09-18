<div align="center">

## flexOS Live ISO Builder

All latest flexOS OS ISOs available from [Releases page](https://github.com/flexOS-linux/live-iso/releases).

</div>

## Get started

1. Clone this project & `cd` into it:

```sh
git clone https://github.com/flexOS-linux/live-iso.git && cd live-iso
```

2. Configure the builder, GRUB and kernel settings in the `configs` directory.

3. Run the build:

> [!WARNING]
> This script must be run with **sudo** (root privileges).

```sh
sudo ./build.sh
```

4. Once completed, the ISO file will be located in the `builds` directory.
