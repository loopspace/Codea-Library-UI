-- ColourWheel

if _M then
    Colour = cimport "Colour"
    cimport "RoundedRectangle"
end

local ColourWheel = class()

function ColourWheel:init()
    self.meshsqr = mesh()
    self.meshhex = mesh()
    self.colour = color(255, 0, 0, 255)
    self.rimcolour = color(255, 0, 0, 255)
    local l = .9
    self.meshsqr.vertices = {
        l*vec2(1,1),
        l*vec2(-1,1),
        l*vec2(-1,-1),
        l*vec2(1,1),
        l*vec2(1,-1),
        l*vec2(-1,-1),
    }
    self.meshsqr.colors = {
        color(255, 255, 255, 255),
        self.rimcolour,
        color(0, 0, 0, 255),
        color(255, 255, 255, 255),
        Colour.complement(self.rimcolour,false),
        color(0, 0, 0, 255),
    }
    local t = {}
    local c = {}
    local cc = {
        color(255, 0, 0, 255),
        color(255, 255, 0, 255),
        color(0, 255, 0, 255),
        color(0, 255, 255, 255),
        color(0, 0, 255, 255),
        color(255, 0, 255, 255),
    }
    self.rimcolours = cc
    for i = 1,6 do
        table.insert(t,
            2*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            1.5*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            2*vec2(
                math.cos((i+1)*math.pi/3),
                math.sin((i+1)*math.pi/3)
                )
            )
        table.insert(t,
            2*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            1.5*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            1.5*vec2(
                math.cos((i-1)*math.pi/3),
                math.sin((i-1)*math.pi/3)
                )
            )
        table.insert(c,cc[i])
        table.insert(c,cc[i])
        table.insert(c,cc[i%6+1])
        table.insert(c,cc[i])
        table.insert(c,cc[i])
        table.insert(c,cc[(i-2)%6+1])
    end
    self.meshhex.vertices = t
    self.meshhex.colors = c
    self.ratio = vec2(0,1)
    self.alpha = 255
    self:setRimColour(1,0)
end

function ColourWheel:setRimColour(x,y)
    self.angle = math.atan2(y,x)
    local a = 3*self.angle/math.pi
    local i = math.floor(a)+1
    a = 100*(i - a)
    i = (i-2)%6 + 1
    local j = i%6 + 1
    self.rimcolour = Colour.blend(
        self.rimcolours[i],a,self.rimcolours[j])
    self.meshsqr:color(2,self.rimcolour)
    self.meshsqr:color(5,Colour.complement(self.rimcolour,false))
    self:setColour()
end

function ColourWheel:setFromColour(rc)
   local c = color(rc.r,rc.g,rc.b,rc.a)
    self.alpha = c.a
    local x,y = math.min(c.r,c.g,c.b)/255,math.max(c.r,c.g,c.b)/255
    self.ratio = vec2(x,y)
    local i,j,ar
    if x == y then
        self.rimcolour = Colour.svg.Red
        self.angle = math.pi/3
    else
        c.r = (c.r - x*255)/(y - x)
        c.g = (c.g - x*255)/(y - x)
        c.b = (c.b - x*255)/(y - x)
        c.a = 255
        self.rimcolour = c
        ar = (c.r + c.g + c.b)/255 - 1
        if c.r >= c.g and c.r >= c.b then
            i = 1
            if c.g >= c.b then
                j = 2
            else
                j = 6
            end
        elseif c.g >= c.b then
            i = 3
            if c.b >= c.r then
                j = 4
            else
                j = 2
            end
        else
            i = 5
            if c.r >= c.g then
                j = 6
            else
                j = 4
            end
        end
        self.angle = (i*(1-ar) + ar*j)*math.pi/3
    end
    self.meshsqr:color(2,self.rimcolour)
    self.meshsqr:color(5,Colour.complement(self.rimcolour,false))
    self:setColour()
end

function ColourWheel:setColour()
    local x,y = self.ratio.x,self.ratio.y
    if y > x then
        self.colour = 
            Colour.shade(
                Colour.tint(
                    self.rimcolour,100*(1-x/y),false),100*y,false)
    elseif x > y then
        self.colour = 
            Colour.shade(
                Colour.tint(
                    Colour.complement(self.rimcolour,false)
                        ,100*(1-y/x),false),100*x,false)
    else
        self.colour = color(255*x,255*x,255*x,255)
    end
    self.colour.a = self.alpha
end

function ColourWheel:draw()
    if not self.active then
        return false
    end
    pushStyle()
    pushMatrix()
    resetMatrix()
    resetStyle()
    translate(WIDTH/2,HEIGHT/2)
    pushMatrix()

    scale(100)
    fill(71, 71, 71, 255)
    RoundedRectangle(-2.1,-3.1,4.6,5.2,.1)
    fill(Colour.opaque(self.colour))
    RoundedRectangle(-1.1,-2.9,2.2,.8,.1)
    self.meshsqr:draw()
    self.meshhex:draw()

    lineCapMode(SQUARE)
    strokeWidth(.05)
    --noSmooth()
    stroke(255, 255, 255, 255)
    line(2.05,self.alpha*3/255-1.5,2.35,self.alpha*3/255-1.5)
    stroke(127, 127, 127, 255)
    line(2.2,-1.55,2.2,1.55)
    stroke(Colour.complement(self.rimcolour,false))
    local a = self.angle - (math.floor(
            3*self.angle/math.pi) + .5)*math.pi/3
    local r = math.cos(math.pi/6)/math.cos(a)
    
    line(1.53*r*math.cos(self.angle),1.53*r*math.sin(self.angle),
        1.97*r*math.cos(self.angle),1.97*r*math.sin(self.angle))
    stroke(255, 255, 255, 255)
    noFill()
    noSmooth()
    popMatrix()
    strokeWidth(5)
    ellipseMode(RADIUS)
    ellipse(self.ratio.x*180-90,self.ratio.y*180-90,20)
    ellipse(220,self.alpha*300/255-150,20)
    fill(Colour.opaque(
            Colour.complement(
                Colour.posterise(self.colour,127,false),false
                )
            )
        )
    font("Courier-Bold")
    textMode(CENTER)
    fontSize(48)
    text("Select",0,-250)
    popMatrix()
    popStyle()
end

--[[
If we are active, we claim all touches.
--]]

function ColourWheel:isTouchedBy(touch)
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

function ColourWheel:processTouches(g)
    if g.updated then
        local t = g.touchesArr[1]
        local x = (t.touch.x - WIDTH/2)/100
        local y = (t.touch.y - HEIGHT/2)/100
        if t.touch.state == BEGAN then
            if math.abs(x) < .9 and math.abs(y) < .9 then
                self.touchedon = 0
            elseif vec2(x,y):lenSqr() > 1 and vec2(x,y):lenSqr() < 4 then
                self.touchedon = 1
            elseif math.abs(x) < 1.1 and math.abs(y+2.5) < .4 then
                self.touchedon = 2
            elseif math.abs(x-2.2) < .1 and math.abs(y) < 1.6 then
                self.touchedon = 3
            elseif math.abs(x-.2) < 2.3 and math.abs(y+.5) < 2.6 then
                self.touchedon = 4
            else
                self.touchedon = 5
            end
        end
        if self.touchedon == 0 then
            x = math.min(math.max((x+.9)/1.8,0),1)
            y = math.min(math.max((y+.9)/1.8,0),1)
            self.ratio = vec2(x,y)
            self:setColour()
        end
        if self.touchedon == 1 then
            self:setRimColour(x,y)
        end
        if self.touchedon == 3 then
            self.alpha = math.min(math.max((y+1.5)*255/3,0),255)
            self:setColour()
        end
        if t.touch.state == ENDED then
            if self.touchedon == 5 then
                if math.abs(x) > 2.1 or math.abs(y+.5) > 2.6 then
                    self:deactivate()
                end
            elseif self.touchedon == 2 then
                if math.abs(x) < 1.1 and math.abs(y+2.5) < .4 then
                    local a = self.action(self.colour)
                    if a then
                        self:deactivate()
                    end
                end
            end
        end
        g:noted()
    end
    if g.type.ended then
        g:reset()
    end
end

--[[
This activates the colour wheel, making it active and setting the
call-back function to whatever was passed to the activation function.
--]]

function ColourWheel:activate(c,f)
    self.active = true
    if c then
        self:setFromColour(c)
    end
    self.action = f
end

function ColourWheel:deactivate()
    self.active = false
    self.action = nil
end

ColourWheel.help = "The colour wheel is used to choose a colour.  The outer wheel selects the dominant colour then the inner square allows you to blend it or its complement with white and black.  Click on the Select button to choose the colour or outside the wheel region to cancel the colour change."

if _M then
    return ColourWheel
else
    _G["ColourWheel"] = ColourWheel
end