
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

local strENTRY_BEG = "\\["
local strENTRY_END = "\\\\\n"
local strCMD_BEG = "{"
local strCMD_END = "}"
local strARG_BEG = "{"
local strARG_END = "}"
local strKVS_BEG = "{"
local strKVS_END = "\n}"
local strKVS_EMPTY = "{}"
local strKV_BEG  = "\n  "
local strKV_END  = ","
local strKEY_BEG = ""
local strKEY_END = ""
local strVALUE_BEG = "={"
local strVALUE_END = "}"
local strHEX_STR_BEG = "\\<"
local strHEX_STR_END = "\\>"


local strLIT_STR_BEG = "("
local strLIT_STR_END = ")"
local strDICT_BEG= "<<"
local strDICT_END= ">>"
local strNAME= "/"
local strARRAY_BEG= "["
local strARRAY_END= "]"

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
-- XXXXXX encode/escape the file name?
local function outputENTRY_file (file, pdfedoc)
  local bytes       = GETSIZE(pdfedoc)
  local date        = GETINFO(pdfedoc).CreationDate
  -- file
  local a = strENTRY_BEG
  a = a .. strCMD_BEG .. "file" .. strCMD_END 
  a = a .. strARG_BEG .. strLIT_STR_BEG .. file .. strLIT_STR_END ..  strARG_END
  a = a .. strKVS_BEG 
   a = a .. strKV_BEG .. "Size" .. strVALUE_BEG .. bytes .. strVALUE_END .. strKV_END
   a = a .. strKV_BEG .. "Date" .. strVALUE_BEG .. date .. strVALUE_END.. strKV_END
  a = a .. strKVS_END 
  a = a .. strENTRY_END 
  return a
end 

local function outputENTRY_pagenum (pages)
  local a = strENTRY_BEG 
  a = a .. strCMD_BEG .. "pagenum" .. strCMD_END 
  a = a .. strARG_BEG .. pages .. strARG_END 
  a = a .. strENTRY_END
  return a
end 

local function outputENTRY_page (pdfedoc,page) -- page=integer
  -- trimbox, bleedbox, cropbox,artbox,rotate etc could be put in 
  -- the second argument as keyval:
  -- TrimBox={0 0 300 350},
  -- but pax skips the argument anyway, so not really useful 
  local mediabox = pdfe.getbox(GETPAGE(pdfedoc,page),"MediaBox")
  local a=""
  if mediabox then
    a = strENTRY_BEG 
    a = a .. strCMD_BEG .. "page" .. strCMD_END 
    a = a .. strARG_BEG .. page .. strARG_END 
    a = a .. strARG_BEG
      a = a .. mediabox[1]
      for j = 2, 4 do
       a = a .. " ".. mediabox[j]
      end
    a = a .. strARG_END 
    a = a .. strKVS_EMPTY
    a = a .. strENTRY_END   
  end
  return a
end

-- XXXXX: move entry_beg 
local function outputCMD_annot (pdfedict,page,type)
  local rectangle = ARRAYTOTABLE(GETARRAY(pdfedict,"Rect"))
  local a = strCMD_BEG .. "annot" .. strCMD_END 
      a = a .. strARG_BEG .. page .. strARG_END 
      a = a .. strARG_BEG .. GETNAME(pdfedict,"Subtype") .. strARG_END
      a = a .. strARG_BEG
       a = a .. rectangle[1][2]
        for k = 1, 3 do
         a = a.. " "..rectangle[k][2]
        end
      a = a .. strARG_END 
      a = a .. strARG_BEG .. type .. strARG_END  
  return a
end


local function outputKV_color (pdfedict)
  local color = GETARRAY(pdfedict,"C")
  local a =""
  if color then
    local colortable = ARRAYTOTABLE(color)
    a = strKV_BEG .. "C" .. strVALUE_BEG .. strARRAY_BEG
      for i=1,#colortable do
        a = a.. colortable[i][2] .. " "
      end
    a = a .. strARRAY_END .. strVALUE_END .. strKV_END
  end 
  return a
end 

local function outputKV_key (pdfedict,key)
  local name = GETNAME(pdfedict,key)
  local a = ""
  if name then
    a = strKV_BEG .. key .. strVALUE_BEG .. strNAME .. name .. strVALUE_END .. strKV_END
  end 
  return a
end 

-- XXX handle fourth argument
local function outputKV_Border (pdfedict)
  local border = GETARRAY(pdfedict,"Border")
  local a =""
  if border then 
    local bordertable = ARRAYTOTABLE(border)
    a = strKV_BEG .. "Border" .. strVALUE_BEG .. strARRAY_BEG
    for i=1,3 do
      a = a .. bordertable[i][2] .. " "
    end
  end 
 -- fourth argument later, it is an array (type 7)
  a = a ..strARRAY_END .. strVALUE_END .. strKV_END
  return a
end 

local function outputKV_BS (pdfedict)
  local bsstyle = GETDICTIONARY(pdfedict,"BS")
  local a =""
  if bsstyle then 
    local bsstyledict = DICTIONARYTOTABLE(bsstyle)
    a = strKV_BEG .. "BS" .. strVALUE_BEG ..strDICT_BEG
    for k,v in pairs (bsstyledict) do
      a = a .. strNAME.. k 
      if v[1]== 5 then
       a = a .. strNAME .. v[2] 
      else 
       a = a .." " .. v[2]
      end  
    end
    a = a .. strDICT_END .. strVALUE_END .. strKV_END 
  end 
  return a
end 


local function outputKV_uri (pdfedict)
  local type, value, hex = GETFROMDICTIONARY(pdfedict,"URI")
  local a= strKV_BEG .. "URI" .. strVALUE_BEG 
  if hex then 
    a = a .. strHEX_STR_BEG .. value .. strHEX_STR_END 
  else
    a = a .. strLIT_STR_BEG ..value .. strLIT_STR_END 
  end
    a = a .. strVALUE_END .. strKV_END
  return a
end 

local function outputKV_N (pdfedict)
  local name = GETNAME(pdfedict,"N")
  local a= strKV_BEG .. "Name" .. strVALUE_BEG .. name .. strVALUE_END .. strKV_END
  return a
end 

local function outputKV_gotor (pdfedict) -- action dictionary
  local type, value, hex = GETFROMDICTIONARY(pdfedict,"F")
  local type, pagenum    = GETFROMARRAY(GETARRAY (pdfedict,"D"),1)
  local type, fittype    = GETFROMARRAY(GETARRAY (pdfedict,"D"),2)  
  local a =  strKV_BEG .."File" .. strVALUE_BEG
  if hex then
    a = a .. strHEX_STR_BEG .. value .. strHEX_STR_end
  else
    a = a .. strLIT_STR_BEG .. value .. strLIT_STR_END
  end
  a = a .. strVALUE_END .. strKV_END 
  a = a .. strKV_BEG .. "DestPage" .. strVALUE_BEG .. pagenum .. strVALUE_END .. strKV_END
  a = a .. strKV_BEG .. "DestView" .. strVALUE_BEG .. strNAME .. fittype .. strVALUE_END .. strKV_END
  return a    
end


local function outputKV_goto (count)
  local a = strKV_BEG .. "DestLabel" .. strVALUE_BEG .. count .. strVALUE_END .. strKV_END
  return a
end 

local function outputENTRY_dest (destcount,name)
 local pagenum, data = getdestdata(name)
 local a = strENTRY_BEG
 a = a .. strCMD_BEG .. "dest" .. strCMD_END
 a = a .. strARG_BEG .. pagenum .. strARG_END 
 a = a .. strARG_BEG .. destcount .. strARG_END
 -- name
 a = a .. strARG_BEG .. data[2][2] .. strARG_END 
 a = a .. strKVS_BEG
 if data[2][2] == "XYZ" then   
   if data[3][2] then 
    a = a .. strKV_BEG .. "DestX" .. strVALUE_BEG .. data[3][2] .. strVALUE_END .. strKV_END
   end
   if data[4][2] then 
    a = a .. strKV_BEG .. "DestY" .. strVALUE_BEG .. data[4][2] .. strVALUE_END .. strKV_END
   end
   if data[5][2] then 
    a = a .. strKV_BEG .. "DestZoom" .. strVALUE_BEG .. data[5][2] .. strVALUE_END .. strKV_END
   end 
 elseif data[2][2] == "Fit"  then -- nothing to do
 elseif data[2][2] == "FitB" then -- nothing to do
 elseif data[2][2] == "FitH" then
   if data[3][2] then 
    a = a .. strKV_BEG .. "DestY" .. strVALUE_BEG .. data[3][2] .. strVALUE_END .. strKV_END
   end
 elseif data[2][2] == "FitBH" then
   if data[3][2] then 
    a = a .. strKV_BEG .. "DestY" .. strVALUE_BEG  .. data[3][2] .. strVALUE_END .. strKV_END
   end   
 elseif data[2][2] == "FitV" then
   if data[3][2] then 
    a = a .. strKV_BEG .. "DestX" .. strVALUE_BEG .. data[3][2] .. strVALUE_END .. strKV_END
   end
 elseif data[2][2] == "FitBV" then
   if data[3][2] then 
    a = a .. strKV_BEG .. "DestX" .. strVALUE_BEG .. data[3][2] .. strVALUE_END .. strKV_END
   end   
 elseif data[2][2] == "FitR" and data[6] then   
   a = a ..  strKV_BEG .. "DestRect" .. strVALUE_BEG  
   a = a .. data[3][2] .. " "
   a = a .. data[4][2] .. " " 
   a = a .. data[5][2] .. " " 
   a = a .. data[6][2] .. strVALUE_END .. strKV_END
 end
 a = a .. strKVS_END .. strENTRY_END   
 return a
end


local function WRITE(content)
  writeVAR:write(content)
end



-- the main function

local function __writepax (ext,file)
  local fileVAR = assert(kpse.find_file(file ..".pdf"),"file not found")  
  local fileBASE = FILENAMEONLY(fileVAR)
  -- getting the data for the concrete document:
  writeVAR = io.open (fileBASE .."."..ext,"w") -- always in current directory
  docVAR   = OPEN (fileVAR)
  pagereferencesVAR, pagecountVAR = getpagesdata (docVAR)
  destcountVAR   = 0 
  -- build from names table:
  destreferencesVAR = getdestreferences (docVAR)
  -- output ...
  WRITE(strENTRY_BEG .. "{pax}{0.1l}" .. strENTRY_END)
  WRITE(outputENTRY_file(fileVAR,docVAR))
  WRITE(outputENTRY_pagenum(pagecountVAR))
  for i=1, pagecountVAR do
    WRITE(outputENTRY_page(docVAR,i))
    local annots=GETPAGE(docVAR,i).Annots
    if annots then
      for j = 0,#annots-1 do
        local annot = GETDICTIONARY (annots,j)
        local annotaction = GETDICTIONARY(annot,"A")
        local annotactiontype =""
        if annotaction then
          annotactiontype = GETNAME(annotaction,"S")
          WRITE (strENTRY_BEG)
          WRITE (outputCMD_annot(annot,i,annotactiontype)) 
          WRITE (strKVS_BEG) -- begin KVS data 
          WRITE ( outputKV_color(annot) )
          WRITE ( outputKV_key(annot,"H") )
          WRITE ( outputKV_Border (annot) )
          WRITE ( outputKV_BS (annot) )
          if annotactiontype =="URI" then 
            WRITE ( outputKV_uri(annotaction) )
          elseif annotactiontype =="GoTo" then
            destcountVAR=destcountVAR + 1
            WRITE ( outputKV_goto (destcountVAR) )
          elseif annotactiontype=="GoToR" then
            WRITE ( outputKV_gotor(annotaction) )
          elseif annotactiontype=="Named" then
            WRITE ( outputKV_N (annotaction) )
          end
          WRITE(strKVS_END)   -- end KVS
          WRITE(strENTRY_END) -- end annot data     
          if annotactiontype =="GoTo" then
            local type,annotactiongoto,hex = GETFROMDICTIONARY(annotaction,"D")
            WRITE ( outputENTRY_dest(destcountVAR,annotactiongoto) )
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
