# Color Checker Extraction Toolbox

Color Checker Extraction Toolbox allows you to pick up color responses from images containing various types of color checkers, which is useful for camera color correction or other camera calibration applications. Currently only manual mode is supported. The auto mode will be included in the future using [Object Detection Framework](https://github.com/pedrodiamel/colorchecker-detection).

MATLAB version R2018b or higher with Image Processing Toolbox is **recommended** in order to implement [images.roi](https://www.mathworks.com/help/images/roi-based-processing.html) object. But for other versions the normal [rectangle](https://www.mathworks.com/help/matlab/ref/rectangle.html) function works well too.

Following screen records will give you a brief impression about how it works.

# Demo

* Interactively select color checker region in the image:

<img src="screenshots/demo1.gif" width="1024">

<br>

* Programmatically specify Regions-of-Interest for color patches without need to manually select checkers again and again:

<img src="screenshots/demo2.gif" width="1024">

# License

Copyright 2019 Qiu Jueqin

Licensed under [MIT](http://opensource.org/licenses/MIT).