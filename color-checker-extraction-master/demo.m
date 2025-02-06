%% demo1
% Drag a rectangle in the image to exactly cover 4 corner markers in the
% DSG ColorChecker. If the ROI for some patches are not locating at the
% patch centers, you can manually adjust them and click 'Continue' to
% finish.
clear all; close all; clc;
cc_img = imread('dsg.png');
colors = checker2colors(cc_img, [10, 14], 'allowadjust', true, 'roisize', 50);
checker = colors2checker(colors, 'layout', [10, 14]);


%% demo 2
% Click 4 corners in the Passport ColorChecker successively to draw a
% quadrangle exactly convering the color checker. Note that the first point
% you click will be treated as the upper-left vertex, so in order to
% retrieve colors in the correct sequence, you should click the
% bottom-right marker first (the marker next to the dark skin patch).
clear all; close all; clc;
cc_img = imread('passport.jpg');
% coord can be used for another extraction, without need to draw a
% quadrangle again
[~, coord] = checker2colors(cc_img, [4, 6], 'mode', 'click', 'show', false);
clearvars -except coord
cc_img = imread('passport.jpg');
colors = checker2colors(cc_img, [4, 6], 'roi', coord);
checker = colors2checker(colors); % not parsing 'layout' parameter works well too
