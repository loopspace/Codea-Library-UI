-- List Selector

if _M then
    Colour = cimport "Colour"
    Font,Sentence = unpack(cimport "Font")
    UTF8 = cimport "utf8"
    cimport "ColourNames"
    cimport "Coordinates"
--cimport "Utilities"
end

local ListSelector = class()

function ListSelector:init(t)
    if t then self:setList(t) end
end

function ListSelector:setList(t)
    t = t or {}
    local ilist = t.list or {}
    local mf = t.minimumSize or 10
    local ft = t.font or Font({name = "Courier", size = 16})
    self.minsize = mf
    self.choice = 1
    local w = 0
    local nf = 0
    local h = 0
    local list = {}
    for k,s in ipairs(ilist) do
        if type(s) == "string" then
            s = Sentence(ft,s)
        elseif type(s) == "table" and s.is_a and s:is_a(UTF8) then
            s = Sentence(ft,s)
        end
        s:prepare()
        w = math.max(w,s.width)
        nf = nf + 1
        h = math.max(h, s.font:lineheight())
        table.insert(list,s)
    end
    w = w + 10
    self.totalwidth = w + 2
    self.nitems = nf
    if nf > mf then
        mf = nf
        self.restrict = self.restrictMod
    end
    self.mitems = mf
    self.pos = t.pos or function() return RectAnchorOf(Screen,"centre") end
    self.ipos = self.pos
    self.width = w
    local hw = w/2
    self.m = mesh()
    self.overlay = mesh()
    local ver = {}
    local col = {}
    for k,v in ipairs({
        {0,0},
        {0,1},
        {1,1},
        {0,0},
        {1,0},
        {1,1},
        {0,0},
        {0,-1},
        {1,-1},
        {0,0},
        {1,0},
        {1,-1}
    }) do
        table.insert(ver,vec2(v[1],v[2]))
        table.insert(col,
                Colour.opacity(Colour.svg.Black,100*math.abs(v[2])))
    end
    self.overlay.vertices = ver
    self.overlay.colors = col
    local img = image(2*w,h*math.ceil(mf/2))
    local x,y = 5,h*math.ceil(mf/2)
    pushMatrix()
    resetMatrix()
    pushStyle()
    resetStyle()
    fill(Colour.svg.White)
    noSmooth()
    setContext(img)
    rect(0,0,2*w,math.ceil(mf/2)*h)
    for i=1,nf do
        y = y + list[i].font.descent - h
        list[i]:draw(x,y)
        y = y - list[i].font.descent
        if i == math.ceil(mf/2) then
            x,y = w+5,h*math.ceil(mf/2)
        end
    end
    setContext()
    self.m.texture = img
    self.img = img
    local nv = 2*mf
    local st = 2*math.pi/nv
    ver = {}
    local texc = {}
    local a,b,c,d,tx,ty
    local r = mf*h/(2*math.pi)
    self.radius = r
    a = 0
    b = -r
    tx,ty = 0,0
    for i = 1,nv do
        c = -r*math.sin(i*st)
        d = -r*math.cos(i*st)

        for k,v in ipairs({
            {-hw,a,b,0,2*(i-1)/nv},
            {hw,a,b,.5,2*(i-1)/nv},
            {hw,c,d,.5,2*i/nv},
            {-hw,a,b,0,2*(i-1)/nv},
            {-hw,c,d,0,2*i/nv},
            {hw,c,d,.5,2*i/nv}
        }) do
            table.insert(ver,vec3(v[1],v[2],v[3]))
            table.insert(texc,vec2(tx+v[4],v[5]-ty))
        end
        if i == mf then
            tx,ty = .5,2*(i-1)/nv
        end
        a,b = c,d
    end

    self.m.vertices = ver
    self.m.texCoords = texc
    self.m:setColors(Colour.svg.White)
    self.velocity = 0
    -- debug:log({name = "List: ", message = function() return self.choice end})
end

function ListSelector:draw()
    if self.active then
        local ang
        local w = self.totalwidth
        local r = self.radius
        local x,y = self.pos()
        pushStyle()
        pushMatrix()
        resetMatrix()
        resetStyle()
        ortho(0,WIDTH,0,HEIGHT,2*r,-2*r)
        translate(x,y,0)
        
        camera(0,0,2*r,0,0,0,0,1,0)

        local v = self.choice
            ang = (v -.5)*360/self.mitems
        pushMatrix()
        rotate(ang,-1,0,0)
        self.m:draw()
        popMatrix()
        if not self.intouch then
            self.choice,self.velocity = self:restrict(v,self.velocity)
        end
        resetMatrix()
        stroke(Colour.svg.SlateBlue)
        strokeWidth(6)
        noFill()
        noSmooth()
        rectMode(CORNERS)
        pushMatrix()
        translate(x-self.totalwidth/2-5,y)
        scale(self.totalwidth +10,r+2)
        self.overlay:draw()
        popMatrix()
        rect(x-self.totalwidth/2-5,
            y-r-5,
            x + self.totalwidth/2+5,
            y+r+5)
        popMatrix()
        popStyle()
        
    end
end

function ListSelector:activate(t)
    t = t or {}
    self.pos = t.pos or self.pos
    self.choice = t.value or 1
    self.active = true
    self.action = t.action or function() return true end
end

function ListSelector:deactivate()
    self.pos = self.ipos
    self.active = false
    self.action = function() return true end
    self.subfp = nil
end

function ListSelector:getValue()
    local v = math.floor(self.choice+.5)
    v = (v-1)%self.nitems + 1
    return v
end
    
function ListSelector:restrict(v,s)
    if s == 0 then
        if v ~= math.floor(v) then
            local tgt = math.max(1,
                math.min(self.nitems,math.floor(v + .5)))
            if math.abs(v - tgt) < .01 then
                v = tgt
            else
                v = v + DeltaTime*(tgt- v)
            end
        else
            v = (v-1)%self.nitems + 1
        end
    else
        if v < -2 then
            s = math.abs(s)/2
        end
        if v > self.nitems + 2 then
            s = - math.abs(s)/2
        end
        v = v + DeltaTime*s
        s = s * .99
        if math.abs(s) < .1 then
            s = 0
        end
    end
    return v,s
end

function ListSelector:restrictMod(v,s)
    if s == 0 then
        if v ~= math.floor(v) then
            local tgt = math.floor(v + .5)
            if math.abs(v - tgt) < .01 then
                v = tgt
            else
                v = v + DeltaTime*(tgt- v)
            end
        else
            v = (v-1)%self.nitems + 1
        end
    else
        v = v + DeltaTime*s
        s = s * .99
        if math.abs(s) < .1 then
            s = 0
        end
    end
    return v,s
end

function ListSelector:isTouchedBy(touch)
    if not self.active then
        return false
    end
    local x,y = self.pos()
    if touch.x < x - self.totalwidth/2 then
        return false
    end
    if touch.x > x + self.totalwidth/2 then
        return false
    end
    if touch.y < y - self.radius then
        return false
    end
    if touch.y > y + self.radius then
        return false
    end
    self.intouch = true
    return true
end

function ListSelector:processTouches(g)
    if g.type.ended and g.type.tap and g.num == 2 then
        local value = self:getValue()
        if self.action and self.action(value) then
            self:deactivate()
        end
        g:reset()
        return
    end
    local x,y = self.pos()
    local t = g.touchesArr[1]
    if t.touch.state ~= BEGAN then
            if t.updated then
                self.choice = (self.choice - 1 +
                    t.touch.deltaY/HEIGHT
                    *self.radius/self.mitems)%self.mitems
                    + 1
            end

    end
    if t.touch.state == ENDED then
        if t.short and t.moved then
            self.velocity = 2*t:velocity().y/HEIGHT
                    *self.radius/self.mitems
        else
            self.velocity = 0
        end
    end
    g:noted()
    if (not g.type.tap and g.type.ended) or g.type.finished then
        self.intouch = false
        g:reset()
    end
end

ListSelector.help = "Drag the wheels up and down to change the digits.  Drag the outermost wheels to add or remove digits."

if _M then
    return ListSelector
else
    _G["ListSelector"] = ListSelector
end

