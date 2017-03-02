-- Keyboard for text input
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

local Keyboard = class()

local Colour, Font, Sentence, UTF8 = Colour, Font, Sentence, UTF8
if _M then
    Colour = cimport "Colour"
    UTF8 = cimport "utf8"
    Font,Sentence = unpack(cimport "Font",nil)
    cimport "ColourNames"
    cimport "RoundedRectangle"
end

--[[
These global constants define our lock states:

"None": lower case characters
"Cap": next character is capitalised, afterwards revert to "None"
"Shift": upper case characters
"Num": the numerical value of each key is returned.
--]]

local LOCK_NONE = 1
local LOCK_CAP = 2
local LOCK_SHIFT = 3
local LOCK_NUM = 4

function Keyboard:advanceLock()
    if self.lock == LOCK_CAP then
        if self.locktime and ElapsedTime - self.locktime < 1 then
            self.lock = LOCK_SHIFT
        else
            self.lock = LOCK_NONE
        end
    elseif self.lock == LOCK_NONE then
        self.lock = LOCK_CAP
        self.locktime = ElapsedTime
    else
        self.lock = LOCK_NONE
    end
end

function Keyboard:init(...)

Keyboard.qwerty = {
    {"q","w","e","r","t","y","u","i","o","p"},
    {{nil,nil,nil,nil,.5},"a","s","d","f","g","h","j","k","l"},
    {"","z","x","c","v","b","n","m"}
}

Keyboard.fullqwerty = {
    {"q","w","e","r","t","y","u","i","o","p",
        {Sentence(Font({name = "AppleSDGothicNeo-Bold", size = 2}),UTF8(9003)),BACKSPACE}},
    {{nil,nil,nil,nil,.5},"a","s","d","f","g","h","j","k","l",
        {Sentence(Font({name = "AppleSDGothicNeo-Bold", size = 2}),UTF8(9166)),"\n",nil,nil,1.5}},
    {{Sentence(Font({name = "AppleSDGothicNeo-Bold", size = 2}),UTF8(8679)),Keyboard.advanceLock,Sentence(Font({name = "AppleSDGothicNeo-Bold", size = 2}),UTF8(11014)),Keyboard.advanceLock},
        "z","x","c","v","b","n","m",{",",nil,"!"},{".",nil,"?"}},
    {"","","",{" "," ",nil,nil,6}}
}
    self.init = self.__init
    Keyboard.init = Keyboard.__init
    self:init(...)
end

function Keyboard:__init(t)
    self.fontname = t.name
    self.fonttype = t.fonttype
    self.type = t.type
    self.keys = {}
    local rl = 0
    local nr = 0
    self.deactivated = {}
    self.keys = {}
    local cc
    for i,r in ipairs(Keyboard[self.type]) do
        local rrl = 0
        for j,k in ipairs(r) do
            rrl = rrl + 1
        end
        rl = math.max(rl,rrl)
        nr = nr + 1
        self.deactivated[i] = {}
    end
    self.rowlength = rl
    self.numrows = nr
    self.activekey = {}
    self.active = false
    self.resize = true
    self.colour = Colour.svg.LightGray
    self.pcolour = Colour.svg.DarkGray
    self.dcolour = Colour.svg.DarkSlateGray
    self.kcolour = Colour.svg.Black
    self:initialise(t.width)
end

function Keyboard:initialise(w)
    w = w or WIDTH
    self.iwidth = w
    self.keywidth = math.floor(w/self.rowlength)
    self.width = self.keywidth * self.rowlength
    self.padding = 10
    local rl = self.keywidth - 2*self.padding
    local f
    if self.fonttype == "bitmap" then
    local fs = {64,48,32,24,12}
    for k,v in ipairs(fs) do
        if (v - rl) < 0 then
            self.fontsize = v
            break
        end
    end
    f = Font[self.fontname .. " " .. self.fontsize .. "0"]()
    else
        rl = math.floor(rl)
        self.fontsize = rl
        f = Font({
        name = self.fontname,
        size = rl
        })
    end
    self.font = f
    local row,ccc,CCC,l,sy,key
    for i,r in ipairs(Keyboard[self.type]) do
        self.keys[i] = {}
        for j,k in ipairs(r) do
            if type(k) == "string" then
                if k ~= "" then
                key = UTF8(k)
                ccc = Sentence(f,key)
                ccc:setColour(self.kcolour)
                ccc:prepare()
                key:toupper()
                CCC = Sentence(f,key)
                CCC:setColour(self.kcolour)
                CCC:prepare()
                self.keys[i][j] = {
                    ccc,nil,CCC,nil,1
                }
                else
                    self.keys[i][j] = {
                        nil,nil,nil,nil,1
                    }
                end
            else
                if k[1] then
                    ccc = Sentence(f,k[1],{"size"})
                    ccc:setColour(self.kcolour)
                    ccc:prepare()
                    if k[3] then
                        CCC = Sentence(f,k[3],{"size"})
                    else
                        CCC = Sentence(f,ccc,{"size"})
                        CCC:toupper()
                    end
                    CCC:setColour(self.kcolour)
                    CCC:prepare()
                    l = k[5] or 1
                    sy = k[4] or k[2]
                    self.keys[i][j] = {
                        ccc,k[2],CCC,sy,l
                    }
                else
                    l = k[5] or 1
                    self.keys[i][j] = {
                        nil,nil,nil,nil,l
                    }
                end
            end
        end
    end
    self.lh = f:lineheight()
    self.keyheight = self.lh + 4*self.padding
    local kh = self.keyheight
    --[[
    local kw = self.keywidth

    local kr = self.padding
    local image = image(kw,kh)
    local hw = math.ceil(kw/2)
    local hh = math.ceil(kh/2)
    local a,d
    for i = 1,hw do
        for j = 1,hh do
            if i < kr and j < kr then
                d = math.sqrt((kr - i)^2 + (kr - j)^2)
            elseif i < kr then
                d = kr - i
            elseif j < kr then
                d = kr - j
            else
                d = 0
            end
            if d > kr then
                a = 0
            elseif d > kr - 4 then
                a = 255*.25*(kr - d)
            else
                a = 255
            end
                    image:set(i,j,255,255,255,a)
                    image:set(kw-i,j,255,255,255,a)
                    image:set(i,kh-j,255,255,255,a)
                    image:set(kw-i,kh-j,255,255,255,a)
           
        end
    end
    self.keypad = image
    --]]
    self.exh = self.font:exh()
    --[[
    local xx,yy,xy = 0,0,0
    
    yy = self.numrows * kh
    self.height = yy
    local row
    --]]
    self.height = self.numrows * kh
    self.lock = LOCK_NONE
    self.top = self.height
    if displayMode() == FULLSCREEN then
        self.top = self.top + 50
    end
end

function Keyboard:draw(x,y)
    if not self.active then
        return
    end
    x = x or 0
    if displayMode() == FULLSCREEN then
        y = y or 50
    else
        y = y or 0
    end
    self.x = x
    self.y = y
    pushStyle()
    spriteMode(CORNER)
    local col,kh,kw,xx,yy,ex,kr
    ex = self.exh/2
    kh = self.keyheight
    kw = self.keywidth
    kr = self.padding
    yy = y + self.height
    self.top = yy
    for i,r in ipairs(self.keys) do
        yy = yy - kh
        xx = x
        for j,k in ipairs(r) do
            if k[1] then
            if self.deactivated[i][j] then
                col = self.dcolour
            else
                if i == self.activekey[1]
                    and j == self.activekey[2]
                    then
                        col = self.pcolour
                else
                    col = self.colour
                end
            end
            fill(col)
            RoundedRectangle(xx+kr/8,yy+kr/8,k[5]*kw-kr/4,kh-kr/4,kr)
            tint(Colour.svg.Black)
            if self.lock == LOCK_NONE then
                k[1]:draw(xx+k[5]*kw/2-k[1].width/2,yy+kh/2 - ex)
            else
                k[3]:draw(xx+k[5]*kw/2-k[3].width/2,yy+kh/2 - ex)
            end
            end
            xx = xx + k[5]*kw
        end
    end
    popStyle()
end

function Keyboard:isTouchedBy(touch)
    if not self.active then
        return false
    end
    if touch.x < self.x then
        return false
    end
    if touch.x > self.x + self.width then
        return false
    end
    if touch.y < self.y then
        return false
    end
    if touch.y > self.y + self.height then
        return false
    end
    return true
end

function Keyboard:processTouches(g)
    if g.updated then
        if g.num == 1 then
            local t = g.touchesArr[1]
            local x,y,r,c
            x = t.touch.x - self.x
            y = self.height - t.touch.y + self.y 
            r = math.floor(y/self.keyheight) + 1
            c = x/self.keywidth
            for k,v in ipairs(self.keys[r]) do
                if c < v[5] then
                    c = k
                    break
                else
                    c = c - v[5]
                end
            end
            if not self.deactivated[r][c]
                and self.keys[r]
                and self.keys[r][c]
                and self.keys[r][c][1]
                 then
                self.activekey = {r,c}
            end
        end
        g:noted()
    end
    if g.type.ended then
        if self.activekey[1] then
            local k = self.keys[self.activekey[1]][self.activekey[2]]
            local kk
            if self.lock == LOCK_NONE then
                kk = k[2] or k[1]:getUTF8()
            else
                kk = k[4] or k[3]:getUTF8()
            end
            if type(kk) == "function" then
                kk(self)
            else
                if self.callback and
                    self.callback(kk,self.activekey) then
                        self.active = false
                end
                if self.lock == LOCK_CAP then
                    self.lock = LOCK_NONE
                end
            end
        self.activekey = {}
        end
        g:reset()
    end
end

function Keyboard:activate(f)
    self.active = true
    self.callback = f
    self:reactivateallkeys()
end

function Keyboard:deactivate()
    self.active = false
    self.callback = nil
    self:reactivateallkeys()
end

function Keyboard:fullscreen(od,d)
    if not self.resize then
        return
    end
    if od == d then
        return
    end
    local ow,w
    if d == STANDARD then
        w = 751
    else
        w = 1024
    end
    if od == STANDARD then
        ow = 751
    else
        ow = 1024
    end
    self:initialise(self.iwidth * w/ow)
end

function Keyboard:deactivatekey(k)
    self.deactivated[k[1]][k[2]] = true
end

function Keyboard:reactivatekey(k)
    self.deactivated[k[1]][k[2]] = nil
end

function Keyboard:reactivateallkeys()
    for k,v in ipairs(self.deactivated) do
        self.deactivated[k] = {}
    end
end

if _M then
    return Keyboard
else
    _G["Keyboard"] = Keyboard
end
