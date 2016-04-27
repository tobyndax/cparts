# cparts
Atom plugin for automatically showing counterparts when working with header files in C,C++ and Objective-C

i.e. when you open the file test.cc with the package enabled the file  test.h will be displayed in a split pane to the right.
The same if you open test.h, test.cc will be displayed in the split pane to the right

ctrl-alt-o to toggle on and off.

Which file extensions that trigger the counterpart side pane can be set by regular expressions from the settings pane.

On Linux and Mac the package deals with several files with the same name by selecting
the file closest to the triggering file. This is not implemented on Windows yet.

#License
Cparts is released under the MIT-license, the whole license is provided in LICENSE, if you are unfamiliar with the MIT-license, please read through it before use.
