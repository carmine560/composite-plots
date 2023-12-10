# composite-plots #

<!-- Bash script that composites scanned scatter plots using Hugin and
ImageMagick 6 -->

The `composite-plots.sh` Bash script composites scanned scatter plots using
[Hugin](https://hugin.sourceforge.io/) and [ImageMagick
6](https://legacy.imagemagick.org/).

## Prerequisites ##

`composite-plots.sh` has been tested on Debian on WSL and uses the following
command and package:

  * [`align_image_stack`](https://wiki.panotools.org/Align_image_stack) from
    Hugin to align scanned scatter plots
  * ImageMagick 6 to convert and composite aligned scatter plots

Install each package as needed.  For example:

``` shell
sudo apt install hugin-tools
sudo apt install imagemagick-6.q16
```

## Usage ##

`composite-plots.sh` will create a `~/.config/$USER/composite-plots.cfg`
configuration file if it does not exist.  Replace the default values in it with
yours.  Then:

``` shell
composite-plots.sh input_1 input_2 [... input_4]
```

## License ##

[MIT](LICENSE.md)

## Link ##

  * [*Bash Scripting to Composite Scanned Plots Using Hugin and
    ImageMagick*](https://carmine560.blogspot.com/2018/07/automatically-composite-scanned-scatter.html):
    a blog post for more details
