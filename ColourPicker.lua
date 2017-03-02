-- ColourPicker
--[[
The "ColourPicker" class is a module for the "User Interface" class
(though it can be used independently).  It defines a grid of colours
(drawn from a list) which the user can select from.  When the user
selects a colour then a "call-back" function is called with the given
colour as its argument.
--]]

if _M then
    Colour = cimport "Colour"
    cimport "RoundedRectangle"
end

local ColourPicker = class()

--[[
There is nothing to do on initialisation.
--]]

function ColourPicker:init()
end

--[[
This is the real initialisation code, but it can be called at any
time.  It sets up the list from which the colours will be displayed
for the user to select from.  At the moment, it can deal with the
"x11" and "svg" lists, though allowing more is simple enough: the main
issue is deciding how many rows and columns to use to display the grid
of colours.
--]]

function ColourPicker:setList(t)
    local c,m,n
    if t == "x11" then
        -- 317 colours
        c = Colour.x11
        n = 20
        m = 16
    else
        -- 151 colours
        c = Colour.svg
        n = 14
        m = 11
    end
    local l = {}
    for k,v in pairs(c) do
        table.insert(l,v)
    end
    table.sort(l,ColourSort)
    self.m = m
    self.n = n
    self.colours = l
end

--[[
This is a crude sort routine for the colours.  It is not a good one.
--]]

function ColourSort(a,b)
    local c,d
    c = 2 * a.r + 4 * a.g + a.b
    d = 2 * b.r + 4 * b.g + b.b
    return c < d
end

--[[
This draws a grid of rounded rectangles (see the "Font" class) of each
colour.
--]]

function ColourPicker:draw()
    if self.active then
    pushStyle()
    strokeWidth(-1)
    local w = WIDTH/self.n
    local h = HEIGHT/self.m
    local s = math.min(w/4,h/4,10)
    local c = self.colours
    w = w - s
    h = h - s
    local i = 0
    local j = 1
    for k,v in ipairs(c) do
        fill(v)
        RoundedRectangle(s/2 + i*(w+s),HEIGHT + s/2 - j*(h+s),w,h,s)
        i = i + 1
        if i == self.n then
            i = 0
            j = j + 1
        end
    end
    popStyle()
    end
end

--[[
If we are active, we claim all touches.
--]]

function ColourPicker:isTouchedBy(touch)
    if self.active then
        return true
    end
end

--[[
The touch information is used to select a colour.  We wait until the
gesture has ended and then look at the xy coordinates of the first
touch.  This tells us which colour was selected and this is passed to
the call-back function which is stored as the "action" attribute.

The action attribute should be an anonymous function which takes one
argument, which will be a "color" object.
--]]

function ColourPicker:processTouches(g)
    if g.updated then
        if g.type.ended then
            local t = g.touchesArr[1]
            local w = WIDTH/self.n
            local h = HEIGHT/self.m
            local i = math.floor(t.touch.x/w) + 1
            local j = math.floor((HEIGHT - t.touch.y)/h)
            local n = i + j*self.n
            if self.colours[n] then
                if self.action then
                    local a = self.action(self.colours[n])
                    if a then
                        self:deactivate()
                    end
                end
            else
                self:deactivate()
            end
            g:reset()
        else
            g:noted()
        end
    end
end

--[[
This activates the colour picker, making it active and setting the
call-back function to whatever was passed to the activation function.
--]]

function ColourPicker:activate(f)
    self.active = true
    self.action = f
end

function ColourPicker:deactivate()
    self.active = false
    self.action = nil
end

ColourPicker.help = "The colour picker is used to choose a colour from a given range.  To choose a colour, touch one of the coloured rectangles.  You can cancel the colour picker by touching some part of the screen where there isn't a coloured rectangle (but where there would be one if there were more colours)."

if _M then
    return ColourPicker
else
    _G["ColourPicker"] = ColourPicker
end