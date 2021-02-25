-- Build script for newpax
packageversion="0.2"
packagedate="2021-02-25"

module   = "newpax"
ctanpkg  = "newpax"

local ok, mydata = pcall(require, "ulrikefischerdata.lua")
if not ok then
  mydata= {email="XXX",github="XXX",name="XXX"}
end

uploadconfig = {
  pkg     = ctanpkg,
  version = "v"..packageversion.." "..packagedate,
  author  = mydata.name,
  license = "lppl1.3c",
  summary = "Experimental package to extract and reinsert PDF annotations",
  -- ctanPath = "????????",
  repository = mydata.github .. "newpax",
  bugtracker = mydata.github .. "newpax/issues",
  support    = mydata.github .. "newpax/issues",
  uploader = mydata.name,
  email    = mydata.email,
  update   = true ,
  topic=    "pdf-feat",
  note     = [[ Uploaded automatically by l3build...]],
  description=[[The package is based on the pax package from Heiko Oberdiek. 
  If offers a lua-based alternative to the java based pax.jar to extract the annotations from a PDF. The resulting file
  can then be used together with pax.sty. It also offers an extended style which works with all three major engines.]],
  announcement_file="ctan.ann"              
}


checkengines = {"luatex","pdftex","xetex"}
checkconfigs = {"build"}

checkruns = 3
checksuppfiles = {"newpax-input.pdf"}

docfiledir = "./doc"

-- ctan setup
docfiles =  {"*.tex"}
textfiles=  {"CTANREADME.md"}
ctanreadme= "CTANREADME.md"

typesetexe = "lualatex-dev"
packtdszip   = false
installfiles = {
                "newpax.sty",
                "newpax.lua"
               }  
               
sourcefiles  = {
                "newpax.sty",
                "newpax.lua"
               }
                            
typesetfiles     = {"newpax.tex","doc-use-newpax.tex","doc-use-pax.tex"}
typesetdemofiles = {"doc-input1.tex","doc-input2.tex"}

typesetruns = 4


