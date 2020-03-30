
local OPEN = pdfe.open
local GETSIZE = pdfe.getsize
local GETINFO = pdfe.getinfo
local GETPAGE = pdfe.getpage
local GETNUMBER = pdfe.getnumber
local GETNAME  = pdfe.getname
local GETINTEGER = pdfe.getinteger
local GETARRAY = pdfe.getarray
local GETDICTIONARY = pdfe.getdictionary
local GETSTRING = pdfe.getstring
local GETFROMDICTIONARY = pdfe.getfromdictionary
local GETFROMARRAY = pdfe.getfromarray
local PAGESTOTABLE = pdfe.pagestotable
local DICTIONARYTOTABLE = pdfe.dictionarytotable

-- get/build data
-- returns table,pagecount where table objref ->page number
local function getpagesdata (pdfedoc)
  local pagecount   = GETINTEGER (pdfedoc.Catalog.Pages,"Count")
  local pagestable  = PAGESTOTABLE (pdfedoc)
  local pagereferences ={}
  for i=1,#pagestable do
   pagereferences[pagestable[i][3]]=i
  end
  return pagereferences, pagecount
end

-- builds a table "destination name -> obj reference (pdfedict) from the Names tree

local function getdestreferences (pdfedoc)
  local desttable= {}
  local catnames = GETDICTIONARY (pdfedoc.Catalog, "Names")
  if catnames then
    local namesarray  = GETARRAY(pdfedoc.Catalog.Names.Dests,"Names")
      for i=0,#namesarray-1 do
        if (i % 2 == 0) then
          key = GETSTRING(namesarray,i)
        else
         value = GETDICTIONARY(namesarray,i)
         desttable[key]=value
        end 
    end
  end  
  return desttable
end

local function getdestdata (name)
   local destdict = destreferencesVAR[name] 
   local type,ref,pagenum,destx,desty = nil, nil, 1,0,0
   if destdict then
     local destarray = GETARRAY(destdict,"D")
     if destarray then
       type, ref, pageref = GETFROMARRAY(destarray,1)
       pagenum = pagereferencesVAR[pageref]
       destx = GETNUMBER(destarray,2)
       desty = GETNUMBER(destarray,3)
     end
  end 
  return pagenum, destx, desty
end

-- output functions 
-- write the info 
local function outputfileinfo (filename,pdfedoc,pages)
  local bytes       = GETSIZE(pdfedoc)
  local date        = GETINFO(pdfedoc).CreationDate
  local a="\\[{file}{(".. filename ..".pdf)}"
  a = a .. "{,\n" 
  a = a .. "  Size={".. bytes .. "},\n"
  a = a .. "  Date={" .. date .. "},"
  a = a .. " \n}\\\\\n" 
  a = a .. "\\[{pagenum}{"..pages.."}\\\\\n"
  return a
end 

local function outputpageinfo (pdfedoc,page) -- page=integer
  local pagebox = GETPAGE(pdfedoc,page).MediaBox
  local a=""
  if pagebox then
    a = "\\[{page}{"..page.."}{"
    a = a .. GETNUMBER(pagebox,0)
    for j = 1, 3 do
     a = a .. " "..GETNUMBER(pagebox,j)
    end
     a= a .. "}{}\\\\\n"   
  end
  return a
end

local function outputannotinfo (pdfedict,page,type)
  local a = "\\[{annot}{"..page.."}{".. GETNAME(pdfedict,"Subtype") .."}{"
  local rectangle =GETARRAY(pdfedict,"Rect")
  a = a .. GETNUMBER(rectangle,0)
  for k = 1, 3 do
    a = a.. " "..GETNUMBER(rectangle,k)
  end
  a = a .. "}{"
  a = a .. type .. "}"  
  return a
end


local function outputcolor (pdfedict)
  local color = GETARRAY(pdfedict,"C")
  local a =""
  if color then
    a = "  C={["
    for i=0,#color-1 do
      a=a.. GETNUMBER(color,i) .. " "
    end
    a = a .."]},\n"
  end 
  return a
end 

local function outputname (pdfedict,key)
  local name = GETNAME(pdfedict,key)
  local a = ""
  if name then
    a = "  "..key.."={/" .. name .."},\n"
  end 
  return a
end 

local function outputborder (pdfedict)
  local border = GETARRAY(pdfedict,"Border")
  local a =""
  if border then 
    a = "  Border={["
    for i=0,2 do
      a = a .. GETNUMBER(border,i) .. " "
    end
  end 
 -- fourth argument later ...
  a = a .."]},\n"
  return a
end 

local function outputBS (pdfedict)
  local bsstyle = GETDICTIONARY(pdfedict,"BS")
  local a =""
  if bsstyle then 
    local bsstyledict = DICTIONARYTOTABLE(bsstyle)
    print("BBBBBBBBB",table.serialize(bsstyledict))
    a = "  BS={<<"
    for k,v in pairs (bsstyledict) do
      a = a .. "/".. k 
      if v[1]== 5 then
       a = a .. "/" .. v[2] 
      else 
       a = a .." " .. v[2]
      end  
    end
  end 
  a = a ..">>},\n"
  return a
end 


local function outputuri (pdfedict)
  local type, value, hex = GETFROMDICTIONARY(pdfedict,"URI")
  local a="  URI={"
  if hex then 
    a = a .. "\\<"..value.."\\>},\n"
  else
    a = a .. "("..value ..")},\n"
  end
  return a
end 

local function outputnamed (pdfedict)
  local name = GETNAME(pdfedict,"N")
  local a="  Name={" .. name .. "},\n"
  return a
end 

local function outputgotor (pdfedict) -- action dictionary
  local type, value, hex = GETFROMDICTIONARY(pdfedict,"F")
  local a = "  File={"
  if hex then
    a = a .. "\\<"..value.."\\>},\n"
  else
    a = a .. "("..value ..")},\n"
  end
  local type, pagenum = GETFROMARRAY(GETARRAY (pdfedict,"D"),1)
  local type, fittype = GETFROMARRAY(GETARRAY (pdfedict,"D"),2)
  a = a .. "  DestPage={" .. pagenum .. "},\n"
  a = a .. "  DestView={/".. fittype .. "},\n"
  return a    
end

local function outputgoto (count)
  local a="  DestLabel={" .. count .. "},\n"
  return a
end 

local function outputdest (destcount,name)
 local pagenum, destx, desty = getdestdata(name)
 local a =""
 local a =  "\\[{dest}{"..pagenum .. "}{" .. destcount .. "}{XYZ}{"
 a = a .. "\n  DestY={" .. desty .. "},"
 a = a .. "\n  DestX={" .. destx .. "},"
 a = a .. "\n}\\\\\n"
 return a
end


local function WRITE(content)
  writeVAR:write(content)
end



-- the main function

local function __writepax (ext,file)
  local fileVAR = kpse.find_file(file ..".pdf")
  -- getting the data for the concrete document:
  writeVAR = io.open (file .."."..ext,"w") -- do we need to strip path parts??
  docVAR   = OPEN (fileVAR)
  pagereferencesVAR, pagecountVAR = getpagesdata (docVAR)
  destcountVAR   = 0 
  -- build from names table:
  destreferencesVAR = getdestreferences (docVAR)
  -- output ...
  WRITE("\\[{pax}{0.1l}\\\\", "\n")
  WRITE(outputfileinfo (file,docVAR,pagecountVAR))
  for i=1, pagecountVAR do
    WRITE(outputpageinfo(docVAR,i))
    local annots=GETPAGE(docVAR,i).Annots
    if annots then
      for j = 0,#annots-1 do
       local annot = GETDICTIONARY (annots,j)
       local annotaction = GETDICTIONARY(annot,"A")
       local annotactiontype = GETNAME(annotaction,"S")
       WRITE(outputannotinfo(annot,i,annotactiontype)) 
       WRITE("{\n") -- begin data 
         WRITE ( outputcolor(annot) )
         WRITE ( outputname(annot,"H") )
         WRITE ( outputborder (annot) )
         WRITE ( outputBS (annot) )
       if annotactiontype =="URI" then 
         WRITE ( outputuri(annotaction) )
         WRITE("}\\\\\n") -- end annot data   
       elseif annotactiontype =="GoTo" then
         destcountVAR=destcountVAR + 1
         local annotactiongoto = GETSTRING(annotaction,"D")
         WRITE ( outputgoto (destcountVAR) )
         WRITE("}\\\\\n") -- end annot data   
         WRITE ( outputdest(destcountVAR,annotactiongoto) )
       elseif annotactiontype=="GoToR" then
         WRITE ( outputgotor(annotaction) )
         WRITE("}\\\\\n") -- end annot data  
       elseif annotactiontype=="Named" then
         WRITE ( outputnamed (annotaction) )
         WRITE("}\\\\\n") -- end annot data        
       end
      end
    end  
  end 
  io.close(writeVAR)
end

local function writepax (file)
 __writepax ("pax",file)
end

local function writenewpax (file)
 __writepax ("newpax",file)
end
 
newpax = {} 
newpax.writepax    = writepax
newpax.writenewpax = writenewpax
 
return newpax

-- writenewpax ("pax-input")
