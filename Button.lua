-- Button class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

local Button = class()

function Button:init(t)
    t = t or {}
    self.size = t.size or 50
    self.fontsize = t.fontsize or 100
    self.osize = t.fullsize or self.size
    self.ofsize = t.fullfontsize or self.fontsize
    self.x = t.x or self.size
    self.y = t.y or self.size
    self.orient = t.orient or false
    self.active = t.active
    self.tactive = t.active
    if t.contents then
        if type(t.contents) == "string" then
            self.contents = function()
                text(t.contents)
            end
        else
            self.contents = t.contents
        end
    else
        self.contents = function() end
    end
    self.action = t.action or function() end
    self.finalAction = t.finalAction or function() end
end

function Button:draw()
    if not self.active then
        return
    end
    pushStyle()
    fontSize(self.fontsize)
    ellipseMode(RADIUS)
    fill(40,40,50,127)
    local x,y,mw,a = self.x,self.y,self.size,0
    if self.orient then
        if math.abs(Gravity.x) < math.abs(Gravity.y) then
            if Gravity.y < 0 then
                x,y = WIDTH-x,HEIGHT-y
            else
                a=180
            end
        else
            if Gravity.x < 0 then
                x = WIDTH-x
                a=-90
            else
                y = HEIGHT-y
                a=90
            end
        end
    end
    self.pos = vec2(x,y)
    self.angle = -math.rad(a)
    pushMatrix()
    translate(x,y)
    rotate(a)
    noStroke()
    ellipse(0,0,mw)
    fill(255, 255, 255, 255)
    self.contents()
    popMatrix()
    popStyle()
end

function Button:isTouchedBy(t)
    if not self.tactive then
        return false
    end
    local tpos = vec2(t.x,t.y)
    if self.pos:dist(tpos) < self.size then
        return true
    end
    return false
end

function Button:processTouches(g)
    if g.updated and g.type.ended then
        local t = g.touchesArr[1].touch
        local vt = (vec2(t.x,t.y) - self.pos):rotate(self.angle)
        if self:isTouchedBy(t) then
            self.action(vt)
        end
    end
    if g.type.finished then
        local t = g.touchesArr[1].touch
        local vt = (vec2(t.x,t.y) - self.pos):rotate(self.angle)
        if self:isTouchedBy(t) then
            self.finalAction(vt)
        end
    end
    g:noted()
end

function Button:activate()
    if self.active then
        return
    end
    self.active = true
    self.tactive = true
    if self.twid then
        tween.stop(self.twid)
    end
    self.twid = tween(2,self,{size = self.osize, fontsize = self.ofsize},tween.easing.backOut)
end

function Button:deactivate()
    if not self.active then
        return
    end
    self.tactive = false
    if self.twid then
        tween.stop(self.twid)
    end
    self.twid = tween(2,self,{size = 0, fontsize = 0},tween.easing.backIn,function() self.active = false end)
end

if _M then
    return Button
else
    _G["Button"] = Button
end