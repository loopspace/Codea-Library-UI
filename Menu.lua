-- Menu class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Menu" class defines a generic menu object.  This contains a list
and items on this list can be selected whereupon some appropriate
function is called.  Items can also be displayed as highlighted
according to the return value of some other function.
--]]

local Menu = class()
local Font, Sentence, Colour = Font, Sentence, Colour
if _M then
    Font, Sentence = unpack(cimport "Font",nil)
    Colour = cimport "Colour"
    cimport "ColourNames"
    cimport "Coordinates"
    cimport "RoundedRectangle"
end
--[[
Our initial data is our position and optional title.
--]]

function Menu:init(t)
    t = t or {}
    self.opos = t.pos or function() return 0,0 end
    self.anchor = t.anchor or "north west"
    self:orientationChanged()
    self.dir = t.direction or "y"
    self.font = t.font or Font({name = "Courier", size = 16})
    if t.floating then
        self.onactive = t.onActivation or function(s,x,y) s.x = x or s.x s.y = y or s.y end
    else
        self.onactive = t.onActivation or function() end
    end
    self.ondeactive = t.onDeactivation or function() end
    local title = t.title or ""
    if title == "" then
        self.hasTitle = false
    else
        self.hasTitle = true
    end
    self.title = Sentence(self.font,title)
    self.sep = 10
    self.colour = t.colour or Colour.svg.Bisque
    self.textColour = t.textColour or Colour.svg.DarkSlateBlue
    self.title:setColour(self.textColour)
    self.items = {}
    self.nextitem = 1
    self.nitems = 0
    self.width = 0
    self.height = 0
    self.highlight = -1
    self.itemHeight = self.font:lineheight() + self.sep
    self.children = {}
    if t.autoactive == nil then
        self.autoactive = true
    else
        self.autoactive = t.autoactive
    end
end

function Menu:orientationChanged()
    local x,y = self.opos()
    self.x = x
    self.y = y
end

--[[
The "draw" function calls another draw option depending on whether the
menu goes across or down.
--]]

function Menu:draw()
    if self.nitems == 0 then
        return
    end
    if self.dir == "x" then
        self:drawAcross()
    else
        self:drawDown()
    end
end

--[[
This is for vertical lists.  We have to work out our width first, and
the title is not set to the full width to allow for a "tab like"
effect.

An item may be "highlighted", if it has a suitable function defined
and if the return value of this is true.  An item may also be
"selected" (more accurately, "potentially selected") if the current
touch is hovering over it.
--]]

function Menu:drawDown()
    pushStyle()
    fill(self.colour)
    spriteMode(CORNER)
    self.title:prepare()
    local sep = self.sep
    local lh = self.itemHeight
    local x = self.x
    local y = self.y
    local w = 0
    local h = 0
    local c = 0
    local iw,ih
    if self.hasTitle then
        w = self.title.width
        h = lh + sep
    end
    if self.active then
        
        for k,v in ipairs(self.items) do
            v.title:prepare()
            if v.title.width > w then
                w = v.title.width
            end
            h = h + lh
        end
    end
    w = w + 2*sep
    h = h + sep
    self.width = w
    self.height = h
    x,y = RectAnchorAt(x,y,w,h,self.anchor)
    local th = 0
    local tw = 0
    if self.hasTitle then
        tw = self.title.width + 2*sep
        th = lh + sep
        if self.active then
            c = 9
        else
            c = 0
        end
        local ty = y + h - th
        RoundedRectangle(
            x,
            ty,
            tw,
            th,
            sep,
            c)
        self.title:draw(x+sep,ty+sep)
    end
    h = h - th
    if self.active then
        if self.hasTitle then
            if self.width == tw then
                c = 6
            else
                c = 2
            end
        else
            c = 0
        end
        RoundedRectangle(
            x,
            y,
            w,
            h,
            sep,
            c
        )
        
        x = x + sep
        w = w - sep
        y = y + h
        for k,v in ipairs(self.items) do
            y = y - lh
            if k == self.highlight and v.action then
                fill(Colour.shade(self.colour,50))
                RoundedRectangle(
                    x - sep/2,
                    y - sep/2,
                    w,
                    lh,
                    sep/2)
            elseif v.highlight() then
                fill(Colour.tint(self.colour,50))
                RoundedRectangle(
                x - sep/2,
                y - sep/2,
                w,
                lh,
                sep/2)
            end
            if v.icon then
                if v.disable() then
                    tint(Colour.tone(self.textColour,50))
                else
                    tint(self.textColour)
                end
                iw,ih = spriteSize(v.icon)
                sprite(v.icon,x,y,(lh-sep)*iw/ih,lh-sep)
            else
                local tc
                if v.disable() then
                    tc = Colour.blend(self.textColour,25,self.colour)
                else
                    tc = self.textColour
                end
                v.title:draw(x,y,tc)
            end
        end
    end
    popStyle()
end

--[[
This is for horizontal lists.
--]]

function Menu:drawAcross()
    pushStyle()
    noSmooth()
    spriteMode(CORNER)
    fill(self.colour)
    self.title:prepare()
    local sep = self.sep
    local lh = self.itemHeight
    local w = 0
    local h = lh + sep
    local iw,ih
    if self.hasTitle then
        w = self.title.width + 2*sep
    end
    if self.active then
        for k,v in ipairs(self.items) do
            if v.icon then
                iw,ih = spriteSize(v.icon)
                w = w + iw*(lh-sep)/ih + sep
            else
                v.title:prepare()
                w = w + v.title.width + sep
            end
        end
        w = w + sep
    end
    local x,y = RectAnchorAt(
        self.x,
        self.y,
        w,
        h,
        self.anchor)
    if self.active or self.hasTitle then
        RoundedRectangle(
            x,
            y,
            w,
            h,
            sep
        )
    end
    self.width = w
    self.height = h
    x = x + sep
    y = y + sep
    if self.active then
        for k,v in ipairs(self.items) do
            if v.icon then
                iw,ih = spriteSize(v.icon)
                w = iw*(lh-sep)/ih + sep
            else
                w = v.title.width + sep
            end
            if k == self.highlight and v.action then
                fill(Colour.shade(self.colour,50))
                RoundedRectangle(
                    x - sep/2,
                    y - sep/2,
                    w,
                    lh,
                    sep/2)
            elseif v.highlight() then
                fill(Colour.tint(self.colour,50))
                RoundedRectangle(
                x - sep/2,
                y - sep/2,
                w,
                lh,
                sep/2)
            end
            if v.icon then
                if v.disable() then
                    tint(Colour.tone(self.textColour,50))
                else
                    tint(self.textColour)
                end
                iw,ih = spriteSize(v.icon)
                sprite(v.icon,x,y,(lh-sep)*iw/ih,lh-sep)
            else
                local tc
                if v.disable() then
                    tc = Colour.tone(self.textColour,50)
                else
                    tc = self.textColour
                end
                v.title:draw(x,y,tc)
            end
            x = x + w
        end
    end
    popStyle()
end

--[[
If we are active then we claim all touches in our bounding box.  If we
are not active then we still claim touches on our title.
--]]

function Menu:isTouchedBy(touch)
    if self.nitems == 0 then
        return false
    end
    if not self.active and not self.hasTitle then
        return false
    end
    local x,y = RectAnchorAt(
        self.x,
        self.y,
        self.width,
        self.height,
        self.anchor)
    if touch.x < x then
        return false
    end
    if touch.x > x + self.width then
        return false
    end
    if touch.y < y then
        return false
    end
    if touch.y > y + self.height then
        return false
    end
    
    return true
end

--[[
For the touch processing, we need to know which element in the list is
currently under the touch.  While the touch is in progress then this
element is highlighted.  When the touch ends, the call-back function
for this element is called.  The arguments to this call-back are an
appropriate xy coordinate for the element in the list (which can be
used to make something appear alongside or just below the element).
--]]

function Menu:processTouches(g)
    if g.updated then
        if not self.active then
            if g.type.ended then
                self:activate(self.x,self.y) 
                g:reset()
            end
        else
        local t
        t = g.touchesArr
        for k,v in ipairs(t) do
            if v.touch.state == ENDED then
                local n,x,y = self.highlight,self.itemx,self.itemy
		          if self.items[n] 
                        and self.items[n].action 
                        and not self.items[n].disable() then
                    self:deactivateChildrenExcept(n)
                    local r = self.items[n].action(x,y)
                    if r then
                        self:deactivateUp()
                    end
                end
                v:destroy()
                self.highlight = -1
            else
                local n,x,y,w,sep
                x,y = RectAnchorAt(
                    self.x,
                    self.y,
                    self.width,
                    self.height,
                    self.anchor)
                sep = self.sep
                if self.dir == "y" then
                    n = math.floor((y + self.height - sep/2 - v.touch.y)
                            /self.itemHeight)
                    if not self.hasTitle then
                        n = n + 1
                        y = y + self.itemHeight
                    end
                    y = y + self.height - n * self.itemHeight - self.sep/2
                    x = x + self.width + 1
                else
                    n = 0
                    --y = y - self.itemHeight - sep
                    y = y - 1
                    if self.hasTitle then
                        if x + self.title.width + sep < v.touch.x then
                            x = x + self.title.width + sep
                        end
                    end
                    if x < v.touch.x then
                        n = n + 1
                        local iw,ih
                        local lh = self.itemHeight
                        for l,u in ipairs(self.items) do
                            if u.icon then
                                iw,ih = spriteSize(u.icon)
                                if x + iw*(lh-sep)/ih + sep > v.touch.x then
                                    break
                                end
                                x = x + iw*(lh-sep)/ih + sep
                            else
                                if x + u.title.width + sep > v.touch.x then
                                    break
                                end
                                x = x + u.title.width + sep
                            end
                            n = n + 1
                        end
                    end
                end
                    if self.items[n].disable() then
                        self.highlight = -1
                    else
                        self.highlight = n
                    end
                self.itemx = x
                self.itemy = y
            end
        end
        end
    end
    g:noted()
end

function Menu:invoke(n,x,y)
    local m,r
    for _,v in ipairs(self.items) do
        m = v.title:getString()
        if m == n then
            r = v.action(x,y)
            break
        end
    end
    return r
end

--[[
This adds an item to the menu.  The arguments are the text, the
call-back function, the highlighter function, and whether to
increment the "next item" counter (for backwards compatibility, the
argument is whether to not increment).
--]]

function Menu:addItem(t)
    t = t or {}
    local m = {}
    m.title = Sentence(self.font,t.title)
    m.title:setColour(self.textColour)
    m.action = t.action
    m.deselect = t.deselect or function() end
    m.highlight = t.highlight or function() return false end
    m.disable = t.disable or function() return false end
    m.icon = t.icon
    table.insert(self.items,self.nextitem,m)
    if not t.atEnd then
        self.nextitem = self.nextitem + 1
    end
    self.nitems = self.nitems + 1
    return m
end

function Menu:addSubMenu(t,m,b)
    self:addItem({
        title = t,
        action = function(x,y)
            m:toggle(x,y)
        end,
        highlight = function()
            return m.active
        end,
        deselect = function()
            m.active = false
        end
    })
    if b ~= false then
        m:isChildOf(self)
    end
end

--[[
Try to remove an item corresponding to the given title.
--]]

function Menu:removeItem(t)
    for k,v in ipairs(self.items) do
        if v.title:getString() == t then
            table.remove(self.items,k)
            return v
        end
    end
end

function Menu:deactivate()
    if self.autoactive and self.active then
        self.active = false
	     self:ondeactive()
        self:deactivateChildren()
        self:deactivateParent()
    end
end

function Menu:deactivateDown()
    if self.autoactive and self.active then
        self.active = false
	     self:ondeactive()
        self:deactivateChildren()
    end
end

function Menu:deactivateUp()
    if self.autoactive and self.active then
        self.active = false
	   self:ondeactive()
        self:deactivateParent()
    end
end

function Menu:deactivateChildrenExcept(n)
    for k,v in ipairs(self.items) do
        if k ~= n then
            if v.highlight() then
                v.deselect()
            end
        end
    end
end

function Menu:deactivateChildren()
    for k,v in ipairs(self.items) do
        if v.highlight() then
            v.deselect()
        end
    end
end

function Menu:deactivateParent()
    if self.parent then
        self.parent:deactivate()
    end
end
            
function Menu:activate(x,y)
    self.active = true
    self:onactive(x,y)
    self:activateParent()
end

function Menu:toggle(x,y)
    if self.active then
        self:deactivate()
    else
        self:activate(x,y)
    end
end

function Menu:activateParent()
    if self.parent then
        self.parent:activate()
    end
end

function Menu:isChildOf(m)
    self.parent = m
    m:addChild(self)
end

function Menu:addChild(m)
    table.insert(self.children,m)
end

if _M then
    return Menu
else
    _G["Menu"] = Menu
end

