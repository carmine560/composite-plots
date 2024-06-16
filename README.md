# composite-plots #

<!-- Bash script that composites scanned scatter plots using Hugin and
ImageMagick 6 -->

The `composite_plots.sh` Bash script composites scanned scatter plots to
compare the distributions using [Hugin](https://hugin.sourceforge.io/) and
[ImageMagick 6](https://legacy.imagemagick.org/).

## Prerequisites ##

`composite_plots.sh` has been tested on Debian Testing on WSL 2 and uses the
following command and package:

  * [`align_image_stack`](https://wiki.panotools.org/Align_image_stack) from
    Hugin to align scanned scatter plots
  * ImageMagick 6 to convert and composite aligned scatter plots

Install each package as needed. For example:

``` shell
sudo apt install hugin-tools
sudo apt install imagemagick-6.q16
```

## Usage ##

`composite_plots.sh` will create a
`~/.config/composite-plots/composite_plots.cfg` configuration file if it does
not exist. Replace the default values in it with yours. Then:

``` shell
composite_plots.sh input_1 input_2 [... input_4]
```

## License ##

[MIT](LICENSE.md)

## Link ##

  * [*Bash Scripting to Composite Scanned Plots Using Hugin and
    ImageMagick*](https://carmine560.blogspot.com/2018/07/automatically-composite-scanned-scatter.html):
    a blog post for more details
