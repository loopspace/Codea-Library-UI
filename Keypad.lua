-- Keypad class for text input
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Keypad" class defines an object that behaves a little like the
input on a mobile phone.  Via a call-back function, it can be used to
get a text string from the user for use in a program.

There are two types of Keypad: the phone type and a numeric type based
on the numeric pad on a keyboard.
--]]

local Keypad = class()
local Font, Sentence, UTF8, Colour = Font, Sentence, UTF8, Colour
if _M then
    Font, Sentence = unpack(cimport "Font",nil)
    UTF8 = cimport "utf8"
    Colour = cimport "Colour"
    cimport "ColourNames"
    cimport "Coordinates"
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
local lock_sym = {}

--[[
The locks are indicated on the display by certain strings which need
to be initialised.  This needs the "Font" class to be loaded already
so we define a function to do the initialisation.
--]]

local function kp_set_locks(f,c)
    lock_sym = {
     Sentence(f,"abc"),
     Sentence(f,"Abc"),
     Sentence(f,"ABC"),
     Sentence(f,"123")
    }
    for k,v in pairs(lock_sym) do
        v:setColour(c)
    end
end

--[[
The standard keypad has certain features that need to be initialised.
These include:

The characters on the "control" keys.
The characters shown on the keys, both in normal or numeric mode.

The key lists which determine which characters are returned by each
key, both in normal or numeric mode.
--]]

local kp_left
local kp_ret
local kp_right
local kp_del
local kp_keystr
local kp_keylists
local kp_np_keystr
local kp_np_keylists
local kp_initialised

local function kp_initialise()
    if kp_initialised then
        return true
    end

kp_left = UTF8(5589) --utf8hex("ab")
kp_ret = UTF8("Enter")
kp_right = UTF8(5586)
kp_del = UTF8("Del")

kp_keystr = {
        {kp_left},
        {kp_ret},
        {kp_right},
        {"1"},
        {"2","ABC"},
        {"3","DEF"},
        {"4","GHI"},
        {"5","JKL"},
        {"6","MNO"},
        {"7","PQRS"},
        {"8","TUV"},
        {"9","WXYZ"},
        {kp_del},
        {"0"},
        {"^"}
    }
kp_keylists = {
        {14,{".",",","'","?","!","\"","1","-","(",")","@","/",":","_"},"1"},
        {12,{"a","b","c","2","ä","æ","å","à","á","â","ã","ç"},"2"},
        {8,{"d","e","f","3","è","é","ê","ë"},"3"},
        {8,{"g","h","i","4","ì","í","î","ï"},"4"},
        {5,{"j","k","l","5","£"},"5"},
        {11,{"m","n","o","6","ö","ø","ò","ó","ô","õ","ñ"},"6"},
        {7,{"p","q","r","s","7","ß","$"},"7"},
        {8,{"t","u","v","8","ù","ú","û","ü"},"8"},
        {5,{"w","x","y","z","9"},"9"},
        {1,{""},""},
        {2,{" ","0"},"0"}
    }

kp_np_keystr = {
        {kp_left},
        {kp_ret},
        {kp_right},
        {"7"},
        {"8"},
        {"9"},
        {"4"},
        {"5"},
        {"6"},
        {"1"},
        {"2"},
        {"3"},
        {kp_del},
        {"0"},
        {"."}
    }
kp_np_keylists = {
        {1,{},"7"},
        {1,{},"8"},
        {1,{},"9"},
        {1,{},"4"},
        {1,{},"5"},
        {1,{},"6"},
        {1,{},"1"},
        {1,{},"2"},
        {1,{},"3"},
        {1,{},""},
        {1,{},"0"},
        {1,{},"."}
    }
    
            kp_initialised = true
            
end

--[[
This is our initialisation function which defines the coordinates of
the top left corner, the dimensions of a single "key pad", our colour,
and whether we are numeric or text.
--]]

function Keypad:init(t)
    -- you can accept and set parameters here
    t = t or {}
    kp_initialise()
    if t.active ~= nil then
        self.active = t.active
    else
        self.active = false
    end
    if t.autoactive ~= nil then
        self.autoactive = t.autoactive
    else
        self.autoactive = true
    end
    self.opos = t.pos or function() return 0,0 end
    self.anchor = t.anchor or "north west"
    self.width = t.width
    self.height = t.height
    self.colour = t.colour
    self.sep = 10
    self:orientationChanged()
    self.font = t.font or Font({name = "Courier", size = 16})
    self.preStr = Sentence(self.font,"")
    self.preStr:setColour(Colour.svg.Black)
    self.postStr = Sentence(self.font,"")
    self.postStr:setColour(Colour.svg.Black)
    self.chr = Sentence(self.font,"")
    self.chr:setColour(Colour.svg.Black)
    self.cursor = Sentence(self.font,UTF8(124))
    self.cursor:setColour(Colour.svg.Black)
    self.currchr = {}
    
    if t.numeric then
        self.keystr = kp_np_keystr
        self.keylists = kp_np_keylists
        self.keylists[10] = function() self:deleteChar() end
        self.lock = LOCK_NUM
    else
        self.keystr = kp_keystr
        self.keylists = kp_keylists
        self.lock = LOCK_NONE
        self.keylists[10] = function() self:deleteChar() end
        self.keylists[12] = function() self:advanceLock() end
        kp_set_locks(self.font,Colour.shade(self.colour,50))
    end
    self.keys = {}
    for k,v in ipairs(self.keystr) do
        table.insert(self.keys,{})
        for l,u in ipairs(v) do
            local s = Sentence(self.font,u)
            s:setColour(Colour.svg.Black)
            table.insert(self.keys[k],s)
        end
    end
end

function Keypad:orientationChanged()
    local x,y = self.opos()
    x,y = RectAnchorAt(
        x,
        y,
        3 * (self.width + self.sep),
        6 * (self.height + self.sep),
        self.anchor)
    y = y + 6 * (self.height + self.sep)
    self.x = x
    self.y = y
end

--[[
This is our draw function which renders the keypad and its constituent
parts to the screen, assuming that we are active.
--]]

function Keypad:draw()
    if self.active then
    local k,x,y
    
    pushStyle()
    smooth()
    noStroke()
    ellipseMode(RADIUS)
    fill(self.colour)
    k = 0
    for j = 2,6 do
        for i = 0,2 do
            k = k + 1
            x = self.x + i * (self.width + self.sep) + self.sep/2
            y = self.y - j * (self.height + self.sep) + self.sep/2
            RoundedRectangle(
                x,
                y,
                self.width,
                self.height,
                self.sep)
            if self.keys[k] then
                for l,u in ipairs(self.keys[k]) do
                    u:prepare()
                    u:draw(
                        x + self.width/2 - u.width/2,
                        y + self.height/2 - self.font:lineheight() * (l - 1)
                        )
                end
            end
        end
    end
    x = self.x + self.sep/2
    y = self.y - self.sep/2 - self.height
    RoundedRectangle(
                     x, 
                     y,
                     3*self.width + 2*self.sep,
                     self.height,
                     self.sep)
    self.preStr:prepare()
    self.postStr:prepare()
    self.chr:prepare()
    x = x + self.sep
    y = y + (self.height - self.font:lineheight())/2
    x,y = self.preStr:draw(x,y)
    x,y = self.chr:draw(x,y)
    if math.floor(2*ElapsedTime)%2 == 0 then
        self.cursor:draw(x,y)
    end
    x = x + self.font:charWidth()
    x,y = self.postStr:draw(x,y)
    x = self.x + self.sep
    y = self.y - self.sep/2 - self.font:lineheight()
    lock_sym[self.lock]:draw(x,y)
    popStyle()
    end
end

--[[
If we are active then we claim any touch that falls within our natural
"bounding box".  If we're in "autoactive" mode then a touch outside our bounding box turns us off.
--]]

function Keypad:isTouchedBy(touch)
    if self.active then
    if touch.x < self.x 
    or touch.x > self.x + 3 * (self.width + self.sep)
    or touch.y > self.y
    or touch.y < self.y - 6 * (self.height + self.sep) then
        if self.autoactive then
            self:deactivate()
            return true
        else
            return false
        end
    end
    return true
    end
end

--[[
This routine process the touches.  We process touches one by one as
they end.  In normal mode, we have to keep track of the key that was
last pressed since if the same key is pressed within half a second
then we replace the previous character by the next on the list for
that key.

As we can move forwards and backwards in the string, we actually
maintain three Sentence objects: before the cursor, the current
character, and after the cursor.  Moving the cursor shifts characters
back and forth between these three.

We also have to keep track of the current lock.
--]]

function Keypad:processTouches(g)
    if self.active then
    if g.updated then
        local t,n,i,j
        t = g.touchesArr
        table.sort(t,sortByCreated)
        for k,v in ipairs(t) do
            if v.touch.state == ENDED then
                
                j = math.floor((self.y - v.touch.y)/(self.height + self.sep)) + 1
                if j > 1 and j < 7 then
                    i = math.floor((v.touch.x - self.x)/(self.width + self.sep)) + 1
                    if j == 2 then
                        self.preStr:append(self.chr)
                        self.chr:clear()
                        self.currchr = {}
                        if i == 2 then
                            self.preStr:append(self.postStr)
                            self.postStr:clear()
                            if self.returnFn then
                                local r
                                r = self.returnFn(self.preStr:getString())
                                if r then
                                    self:deactivate()
                                end
                            end
                        elseif i == 1 then
                            self.postStr:unshift(self.preStr:pop())
                        elseif i == 3 then
                            self.preStr:push(self.postStr:shift())
                        end
                    else
                    n = i + 3*(j - 3)

                    if n == self.currchr[1] 
                        and v.createdat - self.currchr[4] < .5 then
                            self.currchr[2] = self.currchr[2] + 1
                            self.currchr[4] = v.createdat
                    elseif type(self.keylists[n]) == "function" then
                        self.keylists[n]()
                    else
                        if self.lock == LOCK_CAP
                            and self.currchr[1] then
                                self.lock = LOCK_NONE
                        end
                        self.preStr:append(self.chr)
                        self.chr:clear()
                        self.currchr = {n,1,self.lock,v.updatedat}
                    end
                    end
                    v:destroy()
                    if self.currchr[1] then
                        local c
                        local a = self.keylists[self.currchr[1]]
                        if self.currchr[3] == LOCK_NUM then
                            c = UTF8(a[3])
                        else
                            local d = (self.currchr[2] - 1) % a[1] +1
                            c = UTF8(a[2][d])
                        end
                        if self.currchr[3] == LOCK_CAP or
                            self.currchr[3] == LOCK_SHIFT then
                                c:toupper()
                        end
                        self.chr:setString(c)
                    end
                end
            end
        end
    end
    g:noted()
    else
        g:reset()
    end
end

--[[
This functions shifts the lock to the next state, saving the current
character into the before-cursor string.
--]]

function Keypad:advanceLock()
    self.preStr:append(self.chr)
    self.chr:clear()
    self.currchr = {}
    self.lock = (self.lock) % 4 + 1
end

--[[
This deletes the current character (which may be the last one on the
before-cursor string).
--]]

function Keypad:deleteChar()
    if self.currchr[1] then
        self.chr:clear()
        self.currchr = {}
    else
        self.preStr:pop()
    end
end

--[[
This activates the keypad, and sets the call-back function for when
the text input is finalised.
--]]

function Keypad:activate(f,x,y)
    self:clear()
    if x then
        self.x = x
    end
    if y then
        self.y = y
    end
    if f then
        self.returnFn = f
    end
    self.active = true
end

function Keypad:deactivate()
    self:clear()
    if self.autoactive then
        self.active = false
    end
end

--[[
This clears all the strings.
--]]

function Keypad:clearString()
    self.preStr:setString("")
    self.postStr:setString("")
    self.chr:setString("")
    self.currchr = {}
end

--[[
This clears all the settings.
--]]

function Keypad:clear()
    self.preStr:setString("")
    self.postStr:setString("")
    self.chr:setString("")
    self.currchr = {}
    self.returnFn = nil
end

--[[
This is for sorting touches by their start time.
--]]

local function sortByCreated(a,b)
    return a.createdat < b.createdat
end

Keypad.help = "The keypad and numeric pad are used to get (short) input from the user.  The keypad acts like the input on a phone: multiple taps on the same key on quick succession cycle through the letters, and the case-key acts as on a phone.  The numeric pad is similar to the numeric pad on a computer.  For both, the upper keys are for left-right navigation through the input and to accept the input.  The pad can be cancelled by touching some part of the screen away from it."

if _M then
    return Keypad
else
    _G["Keypad"] = Keypad
end

