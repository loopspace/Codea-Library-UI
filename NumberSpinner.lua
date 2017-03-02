--NumberSpinner

local NumberSpinner = class()

if _M then
    Font = unpack(cimport "Font",nil)
    Colour = cimport "Colour"
    cimport "Coordinates"
    cimport "Rectangle"
    cimport "ColourNames"
end

function NumberSpinner:init(t)
    t = t or {}
    self.numbers = {0}
    self.numdigits = 1
    self.decimals = {}
    self.numdecs = 0
    self.maxdecs = 5
    self.maxdigits = 5
    self.allowneg = true
    local fnt = t.font or Font({name = "Inconsolata", size = 60})
    self.pos = t.pos or function() return RectAnchorOf(Screen,"centre") end
    self.ipos = self.pos
    local h = fnt:lineheight()
    local ds = fnt.descent
    local w = fnt:charWidth("0")
    fnt:setColour(Colour.svg.Black)
    self.width = w
    local hw = w/2
    self.m = mesh()
    self.pm = mesh()
    self.dpt = mesh()
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
    
    local img = image(w,10*h)
    pushMatrix()
    resetMatrix()
    pushStyle()
    resetStyle()
    fill(Colour.svg.White)
    noSmooth()
    setContext(img)
    rect(0,0,w,10*h)
    for i=0,9 do
        fnt:write(i,0,i*h+ds)
    end
    setContext()
    self.m.texture = img
    img = image(w,10*h)
    setContext(img)
    rect(0,0,w,10*h)
    fnt:write("-",0,4.5*h+ds)
    setContext()
    self.pm.texture = img
    img = image(w,10*h)
    setContext(img)
    rect(0,0,w,10*h)
    fnt:write(".",0,4.75*h+ds)
    setContext()
    popStyle()
    popMatrix()
    self.dpt.texture = img
    local nv = 40
    local st = 2*math.pi/nv
    ver = {}
    local texc = {}
    local a,b,c,d
    local r = 5*h/math.pi
    self.radius = r
    a = 0
    b = -r
    for i = 1,nv do
        c = -r*math.sin(i*st)
        d = -r*math.cos(i*st)
        for k,v in ipairs({
            {-hw,a,b,0,(i-1)/nv},
            {hw,a,b,1,(i-1)/nv},
            {hw,c,d,1,i/nv},
            {-hw,a,b,0,(i-1)/nv},
            {-hw,c,d,0,i/nv},
            {hw,c,d,1,i/nv}
        }) do
            table.insert(ver,vec3(v[1],v[2],v[3]))
            table.insert(texc,vec2(v[4],v[5]))
        end
        a,b = c,d
    end

    self.m.vertices = ver
    self.m.texCoords = texc
    self.m:setColors(Colour.svg.White)
    self.pm.vertices = ver
    self.pm.texCoords = texc
    self.pm:setColors(Colour.svg.White)
    self.dpt.vertices = ver
    self.dpt.texCoords = texc
    self.dpt:setColors(Colour.svg.White)
end

function NumberSpinner:draw()
    if self.active then
        local ang,tgt
        local w = self.width +2
        local r = self.radius
        local tw = 0
        local x,y = self.pos()
        pushStyle()
        pushMatrix()
        resetMatrix()
        resetStyle()
        ortho(0,WIDTH,0,HEIGHT,2*r,-2*r)
        translate(x+w/2,y,0)
        
        camera(0,0,2*r,0,0,0,0,1,0)
        for k,v in ipairs(self.numbers) do
            ang = v*36 - 162
            tw = tw + w
            translate(-w,0,0)
            pushMatrix()
            rotate(ang,1,0,0)
            self.m:draw()
            popMatrix()
            if not self.intouch and v ~= math.floor(v) then
                tgt = math.floor(v + .5)
                if math.abs(v - tgt) < .01 then
                    self.numbers[k] = tgt
                else
                    self.numbers[k] = v + DeltaTime*(tgt- v)*10
                end
            end
        end
        self.numwidth = tw
        
        if self.isneg then
            translate(-w,0,0)
            self.pm:draw()
            tw = tw + w
        end
        self.totallwidth = tw
        self.totalwidth = tw
        self.decwidth = 0
        if self.numdecs > 0 then
            translate(tw,0)
            self.dpt:draw()
            tw = w
            for k,v in ipairs(self.decimals) do
            ang = v*36 - 162
            tw = tw + w
            translate(w,0,0)
            pushMatrix()
            rotate(ang,1,0,0)
            self.m:draw()
            popMatrix()
            if not self.intouch and v ~= math.floor(v) then
                tgt = math.floor(v + .5)
                if math.abs(v - tgt) < .01 then
                    self.decimals[k] = tgt
                else
                    self.decimals[k] = v + DeltaTime*(tgt- v)*10
                end
            end
            end
            self.decwidth = tw
            self.totalwidth = self.totalwidth + tw
        end
        --ortho()
        resetMatrix()
        stroke(Colour.svg.SlateBlue)
        strokeWidth(6)
        noFill()
        noSmooth()
        rectMode(CORNERS)
        pushMatrix()
        translate(x-self.totallwidth-5,y)
        scale(self.totallwidth + self.decwidth+10,r)
        self.overlay:draw()
        popMatrix()
        rect(x-self.totallwidth-5,
            y-r-5,
            x+self.decwidth+5,
            y+r+5)
        popMatrix()
        popStyle()
        
    end
end

function NumberSpinner:activate(t)
    t = t or {}
    self.pos = t.pos or self.pos
    self.maxdigits = t.maxdigits or self.maxdigits
    self.maxdecs = t.maxdecs or self.maxdecs
    if t.allowSignChange ~= nil then
        self.allowsign = t.allowSignChange
    else
        self.allowsign = true
    end
    local value = t.value or 0
    if value < 0 then
        self.isneg = true
        value = - value
    end
    local decs = value - math.floor(value)
    value = math.floor(value)
        
    local n = {}
    local nn = 1
    n[1] = math.floor(value%10)
    value = math.floor(value/10)
    while value > 0 do
        table.insert(n,math.floor(value%10))
        value = math.floor(value/10)
        nn = nn + 1
    end
    self.numbers = n
    self.numdigits = nn
    self.maxdigits = math.max(self.maxdigits,nn)
    n = {}
    nn = 0
    while decs > 0 and nn <= self.maxdecs do
        decs = decs*10
        table.insert(n,math.floor(decs))
        decs = decs - math.floor(decs)
        nn = nn + 1
    end
    self.decimals = n
    self.numdecs = nn
    --self.maxdecs = math.max(nn,self.maxdecs)
    self.active = true
    self.action = t.action or function() return true end
end

function NumberSpinner:deactivate()
    self.numbers = {0}
    self.numdigits = 1
    self.decimals = {}
    self.numdecs = 0
    self.maxdecs = 5
    self.maxdigits = 5
    self.isneg = false
    self.allowsign = true
    self.pos = self.ipos
    self.active = false
    self.action = function() return true end
end

function NumberSpinner:getValue()
    local value = 0
    local ten = 1
    for k,v in ipairs(self.numbers) do
        value = value + (math.floor(v+.5)%10)*ten
        ten = ten * 10
    end
    local ten = .1
    for k,v in ipairs(self.decimals) do
        value = value + (math.floor(v+.5)%10)*ten
        ten = ten * .1
    end
    if self.isneg then
        value = - value
    end
    return value
end
    

function NumberSpinner:isTouchedBy(touch)
    if not self.active then
        return false
    end
    local x,y = self.pos()
    if touch.x < x - self.totalwidth then
        self:deactivate()
        return true
    end
    if touch.x > x + self.decwidth then
        self:deactivate()
        return true
    end
    if touch.y < y - self.radius then
        self:deactivate()
        return true
    end
    if touch.y > y + self.radius then
        self:deactivate()
        return true
    end
    self.intouch = true
    return true
end

function NumberSpinner:processTouches(g)
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
    if t.touch.state == BEGAN then
        local n = math.floor((x - t.touch.x)/self.width + 1)
        self.moving = n
    else
        if self.moving then
            if self.moving > 0 then
            if t.updated and self.numbers[self.moving] then
                self.numbers[self.moving] = (self.numbers[self.moving] - t.touch.deltaY/HEIGHT*self.radius/10)%10
                
            end
            
            if not self.isneg
                and self.moving == self.numdigits
                and self.allowsign
                and g.type.tap 
                and g.type.finished
                then
                    self.isneg = true
            end
            if self.numdigits < self.maxdigits
                and t.updated 
                and t.touch.x < x - self.numwidth - self.width then
                    table.insert(self.numbers,0)
                    self.numdigits = self.numdigits + 1
            end
            
            if t.updated
                and self.moving == self.numdigits
                and t.touch.x > x - self.numwidth + 2*self.width then
                    if self.numdigits > 1 then
                        table.remove(self.numbers)
                        self.numdigits = self.numdigits - 1
                    else
                        self.numbers[1] = 0
                    end
                    
               
            end
            
            if self.moving == 1 and self.numdecs == 0 and self.maxdecs > 0 then
                if t.updated
                    and t.touch.x > x + self.width then
                    table.insert(self.decimals,0)
                    self.numdecs = 1
                end
            end
            if self.isneg 
                and self.moving > #self.numbers
                and self.allowsign
                and g.type.tap
                and g.type.finished then
                self.isneg = false
            end
            
        else
                
            if t.updated and self.decimals[-self.moving] then
                self.decimals[-self.moving] = (self.decimals[-self.moving] - t.touch.deltaY/HEIGHT*self.radius/10)%10
            end
                
            if self.numdecs < self.maxdecs 
                and t.touch.x > x + self.decwidth + 2*self.width then
                table.insert(self.decimals,0)
                self.numdecs = self.numdecs + 1
            end
            if t.updated
                and self.moving == -self.numdecs
                and t.touch.x < x + self.decwidth - 2*self.width then
                    
                table.remove(self.decimals)
                self.numdecs = self.numdecs - 1
                    
            end
           
           end
        end
        g:noted()
    end
    
    if (not g.type.tap and g.type.ended) or g.type.finished then
        self.intouch = false
        self.moving = nil
        g:reset()
    end
end

NumberSpinner.help = "Drag the wheels up and down to change the digits.  Drag the outermost wheels to add or remove digits."

if _M then
    return NumberSpinner
else
    _G["NumberSpinner"] = NumberSpinner
end
