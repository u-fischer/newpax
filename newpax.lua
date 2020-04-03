
local OPEN = pdfe.open
local GETSIZE = pdfe.getsize
local GETINFO = pdfe.getinfo
local GETPAGE = pdfe.getpage
local GETNAME  = pdfe.getname
local GETARRAY = pdfe.getarray
local GETDICTIONARY = pdfe.getdictionary
local GETFROMDICTIONARY = pdfe.getfromdictionary
local GETFROMARRAY = pdfe.getfromarray
local PAGESTOTABLE = pdfe.pagestotable
local DICTIONARYTOTABLE = pdfe.dictionarytotable
local ARRAYTOTABLE = pdfe.arraytotable
local FILENAMEONLY=file.nameonly

strENTRY_BEG = "\\["
strENTRY_END = "\\\\\n"
strCMD_BEG = "{"
strCMD_END = "}"
strARG_BEG = "{"
strARG_END = "}"
strKVS_BEG = "{"
strKVS_END = "\n}"
strKVS_EMPTY = "{}"
strKV_BEG  = "\n  "
strKV_END  = ","
strKEY_BEG = ""
strKEY_END = ""
strVALUE_BEG = "={"
strVALUE_END = "}"
strHEX_STR_BEG = "\\<"
strHEX_STR_END = "\\>"



-- get/build data
-- returns table,pagecount where table objref ->page number
local function getpagesdata (pdfedoc)
  local type,pagecount,detail   = GETFROMDICTIONARY (pdfedoc.Catalog.Pages,"Count")
  local pagestable  = PAGESTOTABLE (pdfedoc)
  local pagereferences ={}
  for i=1,#pagestable do
   pagereferences[pagestable[i][3]]=i
  end
  return pagereferences, pagecount
end

-- builds a table "destination name -> obj reference (pdfedict) from the Names tree

local function processnamesarray (pdfearray,targettable)
  for i=1,#pdfearray do
    type,value,detail= GETFROMARRAY(pdfearray,i)
    if (i % 2 == 1) then
     tkey = value
    else
      tvalue = value
      targettable[tkey]=tvalue
     -- print("ZZZZ",table.serialize(targettable))
    end 
  end
end

local function findallnamesarrays (pdfedict,table)
  local namesarray  = GETARRAY(pdfedict,"Names")
  if namesarray then
     processnamesarray (namesarray,table)
  else
     local kidsarray = GETARRAY(pdfedict,"Kids")
     if kidsarray then
       for i=1,#kidsarray do
         findallnamesarrays (kidsarray[i],table)
       end
     end
  end  
end

local function getdestreferences (pdfedoc)
  local deststable= {}
  local catnames  = GETDICTIONARY (pdfedoc.Catalog, "Names")
  if catnames then 
    local destsdict = GETDICTIONARY (catnames, "Dests")
    if destsdict then 
      findallnamesarrays (destsdict,deststable)   
    end
  end  
  return deststable
end

local function getdestdata (name)
   local destdict = destreferencesVAR[name] 
   local type,ref,pagenum,destx,desty = nil, nil, 1,0,0
   local data = {0, "XYZ"}
   if destdict then
     local destarray = GETARRAY(destdict,"D")
     if destarray then
       data = ARRAYTOTABLE(destarray)
       type, ref, pageref = GETFROMARRAY(destarray,1)
       pagenum = pagereferencesVAR[pageref]
     end
  end 
  return pagenum, data
end

-- output functions 
-- write the info 
local function outputfileinfo (filename,pdfedoc,pages)
  local bytes       = GETSIZE(pdfedoc)
  local date        = GETINFO(pdfedoc).CreationDate
  local a= strENTRY_BEG .. strCMD_BEG .. "file" .. strCMD_END 
  a = a .. strARG_BEG .. "(" .. filename .. ".pdf)" ..  strARG_END
  a = a .. "{,\n" 
  a = a .. "  Size={".. bytes .. "},\n"
  a = a .. "  Date={" .. date .. "},"
  a = a .. " \n}" .. strENTRY_END 
  a = a .. strENTRY_BEG .."{pagenum}{"..pages.."}" .. strENTRY_END
  return a
end 

local function outputpageinfo (pdfedoc,page) -- page=integer
  -- trimbox, bleedbox, cropbox,artbox,rotate etc could be put in 
  -- the second argument as keyval:
  -- TrimBox={0 0 300 350},
  -- but pax skips the argument anyway, so not really useful 
  local mediabox = pdfe.getbox(GETPAGE(pdfedoc,page),"MediaBox")
  local a=""
  if mediabox then
    a = strENTRY_BEG .. "{page}{"..page.."}{"
    a = a .. mediabox[1]
    for j = 2, 4 do
     a = a .. " "..mediabox[j]
    end
     a= a .. "}{}" .. strENTRY_END   
  end
  return a
end

local function outputannotinfo (pdfedict,page,type)
  local a = strENTRY_BEG .. "{annot}{"..page.."}{".. GETNAME(pdfedict,"Subtype") .."}{"
  local rectangle = ARRAYTOTABLE(GETARRAY(pdfedict,"Rect"))
  a = a .. rectangle[1][2]
  for k = 1, 3 do
    a = a.. " "..rectangle[k][2]
  end
  a = a .. "}{"
  a = a .. type .. "}"  
  return a
end


local function outputcolor (pdfedict)
  local color = GETARRAY(pdfedict,"C")
  local a =""
  if color then
    local colortable = ARRAYTOTABLE(color)
    a = "  C={["
    for i=1,#colortable do
      a=a.. colortable[i][2] .. " "
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
    local bordertable = ARRAYTOTABLE(border)
    -- print("CCC",table.serialize(bordertable))
    a = "  Border={["
    for i=1,3 do
      a = a .. bordertable[i][2] .. " "
    end
  end 
 -- fourth argument later, it is an array (type 7)
  a = a .."]},\n"
  print("BBBBBB",a)
  return a
end 

local function outputBS (pdfedict)
  local bsstyle = GETDICTIONARY(pdfedict,"BS")
  local a =""
  if bsstyle then 
    local bsstyledict = DICTIONARYTOTABLE(bsstyle)
    a = "  BS={<<"
    for k,v in pairs (bsstyledict) do
      a = a .. "/".. k 
      if v[1]== 5 then
       a = a .. "/" .. v[2] 
      else 
       a = a .." " .. v[2]
      end  
    end
    a = a ..">>},\n" 
  end 
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
 local pagenum, data = getdestdata(name)
 local a =""
 a =  strENTRY_BEG .. "{dest}{"..pagenum .. "}{" .. destcount .. "}"
 -- name
 a = a .. "{".. data[2][2] .."}{"
 if data[2][2] == "XYZ" then   
   if data[3][2] then 
    a = a .. "\n  DestX={" .. data[3][2] .. "},"
   end
   if data[4][2] then 
    a = a .. "\n  DestY={" .. data[4][2] .. "},"
   end
   if data[5][2] then 
    a = a .. "\n  DestZoom={" .. data[5][2] .. "},"
   end 
 elseif data[2][2] == "Fit"  then -- nothing to do
 elseif data[2][2] == "FitB" then -- nothing to do
 elseif data[2][2] == "FitH" then
   if data[3][2] then 
    a = a .. "\n  DestY={" .. data[3][2] .. "},"
   end
 elseif data[2][2] == "FitBH" then
   if data[3][2] then 
    a = a .. "\n  DestY={" .. data[3][2] .. "},"
   end   
 elseif data[2][2] == "FitV" then
   if data[3][2] then 
    a = a .. "\n  DestX={" .. data[3][2] .. "},"
   end
 elseif data[2][2] == "FitBV" then
   if data[3][2] then 
    a = a .. "\n  DestX={" .. data[3][2] .. "},"
   end   
 elseif data[2][2] == "FitR" and data[6] then   
   a = a .. "\n  Rect={" 
   a = a .. data[3][2] .. " "
   a = a .. data[4][2] .. " " 
   a = a .. data[5][2] .. " " 
   a = a .. data[6][2] .. "},"
 end
 a = a .. "\n}" .. strENTRY_END   
 return a
end


local function WRITE(content)
  writeVAR:write(content)
end



-- the main function

local function __writepax (ext,file)
  local fileVAR = assert(kpse.find_file(file ..".pdf"),"file not found")  
  local fileBASE = FILENAMEONLY(fileVAR)
  print(fileBASE)
  -- getting the data for the concrete document:
  writeVAR = io.open (fileBASE .."."..ext,"w") -- always in current directory
  docVAR   = OPEN (fileVAR)
  pagereferencesVAR, pagecountVAR = getpagesdata (docVAR)
  destcountVAR   = 0 
  -- build from names table:
  destreferencesVAR = getdestreferences (docVAR)
  -- output ...
  WRITE(strENTRY_BEG .. "{pax}{0.1l}" .. strENTRY_END)
  WRITE(outputfileinfo (file,docVAR,pagecountVAR))
  for i=1, pagecountVAR do
    WRITE(outputpageinfo(docVAR,i))
    local annots=GETPAGE(docVAR,i).Annots
    if annots then
      for j = 0,#annots-1 do
        local annot = GETDICTIONARY (annots,j)
        local annotaction = GETDICTIONARY(annot,"A")
        local annotactiontype =""
        if annotaction then
          annotactiontype = GETNAME(annotaction,"S")
          if annotactiontype then
            WRITE(outputannotinfo(annot,i,annotactiontype)) 
          end  
          WRITE("{\n") -- begin data 
          WRITE ( outputcolor(annot) )
          WRITE ( outputname(annot,"H") )
          WRITE ( outputborder (annot) )
          WRITE ( outputBS (annot) )
          if annotactiontype =="URI" then 
            WRITE ( outputuri(annotaction) )
            WRITE("}" .. strENTRY_END) -- end annot data   
          elseif annotactiontype =="GoTo" then
            destcountVAR=destcountVAR + 1
            local type,annotactiongoto,hex = GETFROMDICTIONARY(annotaction,"D")
            -- print (annotactiongoto, type,annotactiongoto,hex)
            WRITE ( outputgoto (destcountVAR) )
            WRITE("}" .. strENTRY_END) -- end annot data   
            WRITE (outputdest(destcountVAR,annotactiongoto) )
          elseif annotactiontype=="GoToR" then
            WRITE ( outputgotor(annotaction) )
            WRITE("}" .. strENTRY_END) -- end annot data  
          elseif annotactiontype=="Named" then
            WRITE ( outputnamed (annotaction) )
            WRITE("}" .. strENTRY_END) -- end annot data        
          end
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
