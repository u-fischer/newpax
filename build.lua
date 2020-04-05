-- Build script for newpax
packageversion="0.1"
packagedate="2020-04-05"

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

--specialformats = specialformats or {}
--
--if string.find(status.banner,"2019") then
--  print("TL2019")
--  TL2019bool=true
--else 
--  -- tl2020
--  print("TL2020 or later")
--
--  specialformats["latex"] = specialformats["latex"] or 
--   {
--    luatex     = {binary="luahbtex",format = "lualatex"},
--   }
--  specialformats["latex-dev"] = specialformats["latex-dev"] or 
--   {
--    luatex = {binary="luahbtex",format = "lualatex-dev"}
--   }
--end

checkengines = {"luatex","pdftex","xetex"}
checkconfigs = {"build"}

checkruns = 3
checksuppfiles = {"newpax-input.pdf"}


-- ctan setup
docfiles = {"doc/*tagpdf.tex"}
textfiles= {"doc/CTANREADME.md"}
ctanreadme= "CTANREADME.md"

typesetexe = "lualatex"
packtdszip   = false
installfiles = {
                "newpax.sty",
                "newpax.lua"
               }  
               
sourcefiles  = {
                "newpax.sty",
                "newpax.lua"
               }
                            
typesetfiles = {"doc/newpax.tex"}
typesetdemofiles = {"doc/doc-extract.tex","doc/doc-pax-test.tex","doc/doc-newpax-test.tex"}

typesetruns = 4


