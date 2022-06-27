# newpax

![Version: 0.52](https://img.shields.io/badge/current_version-0.52-blue.svg?style=flat-square)
![Date: 2022-06-27](https://img.shields.io/badge/date-2022-06-27-blue.svg?style=flat-square)
[![License: LPPL1.3c ](https://img.shields.io/badge/license-LPPL1.3c-blue.svg?style=flat-square)](https://ctan.org/license/lppl1.3c)

The package is based on the [pax package](https://ctan.org/pkg/pax) by Heiko Oberdiek. 
If offers a lua-based alternative to the java based `pax.jar` to extract the annotations from a PDF. The resulting file
 can then be used together with `pax.sty`. It also offers an extended style which works with all three major engines.
 
## Requirements 

The style requires the new LaTeX PDF management code from the pdfmanagement-testphase package and so also
a current LaTeX and a current L3 layer.

##  Structure

- `newpax.lua` and `newpax.sty` are located in the main folder.
- The doc folder contains the documentation.
- `testfiles` contains tests for the l3build system. 
      
## Rules for contributions

Comments, feedback, examples are welcome. 

Use the [issue tracker](https://github.com/u-fischer/newpax/issues), send me a mail, or make a pull request.

## Licence

The newpax package may be modified and distributed under the terms and conditions of the 
[LaTeX Project Public License](https://www.latex-project.org/lppl/), version 1.3c or greater.
