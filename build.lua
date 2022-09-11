-- Build script for newpax
packageversion="0.52"
packagedate="2022-09-11"

module   = "newpax"
ctanpkg  = "newpax"
tdsroot = "lualatex"
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
  ctanPath = "/macros/latex/contrib/newpax",
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
stdengine = "luatex"
checkconfigs = {"build"}

checkruns = 3
checksuppfiles = {"newpax-input.pdf"}

docfiledir = "./doc"

-- ctan setup
docfiles =  {"*.tex"}
textfiles=  {"doc/CTANREADME.md"}
ctanreadme= "CTANREADME.md"

typesetexe = "lualatex-dev"
packtdszip   = false
installfiles = { "*.sty", "*.lua" }  
               
sourcefiles  = {"*.dtx","*.ins","*.sty"}

                            
typesetfiles     = {"newpax.tex","doc-use-newpax.tex","doc-use-pax.tex"}
typesetdemofiles = {"doc-input1.tex","doc-input2.tex"}

typesetruns = 4


tagfiles = {"Readme.md",
            "newpax.dtx",
            "newpax.ins",
            "doc/newpax.tex",
            "doc/CTANREADME.md"
            }



function update_tag (file,content,tagname,tagdate)
 tagdate = packagedate
 if string.match (file, "%.dtx$" ) then
  content = string.gsub (content,
                         "%d%d%d%d%-%d%d%-%d%d v%d%.%d ",
                         packagedate.. " v"..packageversion .. " ")
  content = string.gsub (content,
                         '(version%s*=%s*")%d%.%d+(",%s*--TAGVERSION)',
                         "%1"..packageversion.."%2")
  content = string.gsub (content,
                         '(date%s*=%s*")%d%d%d%d%-%d%d%-%d%d(",%s*--TAGDATE)',
                         "%1"..packagedate.."%2")                         
  return content
 elseif string.match (file, "^Readme.md$") then
   content = string.gsub (content,
                         "Version: %d%.%d+",
                         "Version: " .. packageversion )
   content = string.gsub (content,
                         "version%-%d%.%d+",
                         "version-" .. packageversion )
   content = string.gsub (content,
                         "for %d%.%d+",
                         "for " .. packageversion )
   content = string.gsub (content,
                         "%d%d%d%d%-%d%d%-%d%d",
                         packagedate )
   local imgpackagedate = string.gsub (packagedate,"%-","--")
   content = string.gsub (content,
                         "%d%d%d%d%-%-%d%d%-%-%d%d",
                         imgpackagedate)
   return content
  elseif string.match (file, "%.md$") then
   content = string.gsub (content,
                         "Packageversion: %d%.%d+",
                         "Packageversion: " .. packageversion )
   content = string.gsub (content,
                         "Packagedate: %d%d%d%d/%d%d/%d%d",
                         "Packagedate: " .. tagdate )
   return content  
 elseif string.match (file, "%.tex$" ) then
   content = string.gsub (content,
                         "package@version{%d%.%d+}",
                         "package@version{" .. packageversion .."}" )
   content = string.gsub (content,
                         "package@date{%d%d%d%d%-%d%d%-%d%d}",
                         "package@date{" .. packagedate .."}" )
   return content  
 end
 return content
 end
