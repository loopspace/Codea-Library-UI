-- Slider class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Slider" class draws a slider on the screen for the user to be
able to modify a parameter.  When the slider is finished, a call-back
function is used to pass the new parameter value to the rest of the
program.
--]]


local Slider = class()

--[[
Our initial information consists of our end points (as vec2 objects)
and a colour.
--]]

function Slider:init(t)
    t = t or {}
    self.oa = t.a
    self.ob = t.b
    self:orientationChanged()
    local d = self.b - self.a
    d = vec2(-d.y,d.x)
    self.d = d/d:len()
    self.t = 0
    self.fg = t.colour
    self.bg = color(0,0,0,255)
    if t.autoactive == nil then
        self.autoactive = true
    else
        self.autoactive = t.autoactive
    end
end

function Slider:orientationChanged()
    local x,y = self.oa()
    self.a = vec2(x,y)
    x,y = self.ob()
    self.b = vec2(x,y)
end

--[[
This draws the slider and the bar at the current parameter value.
--]]

function Slider:draw()
    if self.active then
        local a = self.a
        local b = self.b
        local t = self.t
        pushStyle()
        strokeWidth(10)
        stroke(self.bg)
        line(a.x,a.y,b.x,b.y)
        strokeWidth(6)
        stroke(self.fg)
        line(a.x,a.y,b.x,b.y)
        local c = t*a + (1 - t)*b
        local d = 20 * self.d
        a = c - d
        b = c + d
        strokeWidth(10)
        stroke(self.bg)
        line(a.x,a.y,b.x,b.y)
        strokeWidth(6)
        stroke(self.fg)
        line(a.x,a.y,b.x,b.y)
    end
end

--[[
This is our activation function.  Our arguments are: the current value
of the parameter, its minimum and maximum values, and two call-back
functions.  The first is called when the slider is moved, the second
when it has finished moving.  This means that the program can adjust
to changes in the value as they occur.
--]]

function Slider:activate(t,min,max,f,ff)
    if type(t) == "table" then
        min = t.min
        max = t.max
        f = t.action
        ff = t.finalAction
        t = t.value
    end
    self.active = true
    t = (t - min)/(max - min)
    self.t = math.min(math.max(0,t),1)
    self.min = min
    self.max = max
    self.action = f
    self.finalAction = ff
end

function Slider:deactivate()
    if self.autoactive then
        self.active = false
        self.action = nil
        self.finalAction = nil
    end
end

--[[
If we are active, we try to claim all touches.
--]]

function Slider:isTouchedBy(touch)
    if not self.active then
        return false
    end
    local a = self.a
    local b = self.b
    local c = (a - b):normalize()
    local d = vec2(touch.x,touch.y)
    d = d - b
    local ts = c:dot(d)
    if ts < -20 or ts > (a-b):len() + 20 then
        return false
    else
        local e = d - ts * c
        if e:len() > 40 then
            return false
        end
    end
    return true
end

--[[
We project the touch value onto the line and set the parameter value
accordingly, then call the appropriate call-back function.
We have to begin the touch near the slider, and there should be a way to cancel a slide ...
--]]

function Slider:processTouches(g)
    if g.updated then
        local t = g.touchesArr[1]
            
        local a = self.a
        local b = self.b
        local c = a - b
        local d = vec2(t.touch.x,t.touch.y)
        d = d - b
        local st = c:dot(d)
        st = math.min(math.max(0,st/c:lenSqr()),1)
        self.t = st
        st = st*self.max + (1 - st)*self.min
        if self.action then
            self.action(st)
        end
        if g.type.ended then
            if self.finalAction then
                self.finalAction(st)
            end
            self:deactivate()
        end
        g:noted()
    end 
end
        
Slider.help = "The slider is used to change a continuous parameter between two given values.  To change the parameter, drag the slider bar.  To select a value, release the bar.  Depending on how it was set up, you may see things change as you slide it, though it may be that not everything changes until the bar is released.  You can cancel the slider  at the start by touching some part of the screen well away from the slider."

if _M then
    return Slider
else
    _G["Slider"] = Slider
end

