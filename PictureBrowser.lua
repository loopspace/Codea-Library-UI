-- PictureBrowser

local PictureBrowser = class()
if _M then
    cimport "RoundedRectangle"
    cimport "Coordinates"
    Colour = cimport "Colour"
    cimport "ColourNames"
end

function PictureBrowser:init()
end

function PictureBrowser:setList(t)
    t = t or {}
    self.width = t.width or 100
    self.height = t.height or 100
    self.anchor = t.anchor or "centre"
    self.camera = t.camera
    local d = t.directory or "Documents"
    local f = t.filter or function(n,w,h) return true end
    local l = assetList(d,SPRITES)
    local ims = {}
    local img,w
    local c = 0
    for k,v in ipairs(l) do
        img = readImage(d .. ":" .. v)
        if f(v,img.width,img.height) then
            w = 100*math.min(1,img.width/img.height)
            table.insert(ims,{img,w})
            c = c + 1
        end
    end
    if self.camera then
        img = image(self.width,self.height)
        setContext(img)
        pushStyle()
        pushMatrix()
        resetStyle()
        resetMatrix()
        font("ArialRoundedMTBold")
        fontSize(self.width/5)
        fill(Colour.svg.LightGoldenrod)
        RoundedRectangle(0,0,self.width,self.height,10)
        fill(Colour.svg.Black)
        text("Take",self.width/2,self.height/2 + self.width/10)
        text("Photo",self.width/2,self.height/2 - self.width/10)
        popStyle()
        popMatrix()
        setContext()
        table.insert(ims,{img,100})
        c = c + 1
    end
    self.images = ims
    self.nimages = c
    self.size = math.ceil(math.sqrt(c))
    self.active = t.active or false
    self.sep = t.sep or 10
    self.fwidth = self.size*(self.width + self.sep) + self.sep
    local n = math.ceil(self.nimages/self.size)
    self.fheight = n*(self.width + self.sep) + self.sep
    local pos = t.pos or function()
        return RectAnchorOf(Screen,"centre")
    end
    self.x = 0
    self.y = 0
    self.pos = function()
        local x,y = pos()
        return x + self.x,y + self.y
    end
end

function PictureBrowser:draw()
    if not self.active then
        return
    end
    pushMatrix()
    resetMatrix()
    pushStyle()
    resetStyle()
    
    if self.usecamera then
        spriteMode(CENTER)
        local x,y = RectAnchorOf(Screen,"centre")
        local w,h = spriteSize(CAMERA)
        local ws = RectAnchorOf(Screen,"width") -10
        local hs = RectAnchorOf(Screen,"height") -10
        local asp = math.min(ws/w,hs/h,1)
        sprite(CAMERA,x,y,w*asp,h*asp)
        font("ArialRoundedMTBold")
        fontSize(30)
        fill(Colour.svg.LightGoldenrod)
        ws = ws + 10
        RoundedRectangle(0,0,ws,70,10)
        fill(Colour.svg.Black)
        
        text("Tap to take picture",ws/2,50)
        text("Swipe to change camera",ws/2,20)
    else
        spriteMode(CORNER)
        local x,y = self.pos()
        x,y = RectAnchorAt(x,y,self.fwidth,self.fheight,self.anchor)
        local w = self.width + self.sep
        RoundedRectangle(x,y,self.fwidth,self.fheight,self.sep)
        y = y + self.fheight - w
        x = x + self.sep
        local xx = x
        for i=1,self.nimages do
            sprite(self.images[i][1],x,y,self.images[i][2])
            x = x + w
            if x > xx + self.fwidth - w then
                x = xx
                y = y - w
            end
        end
    end
    popStyle()
    popMatrix()
end

function PictureBrowser:isTouchedBy(touch)
    if not self.active then
        return false
    end
    if self.usecamera then
        return true
    end
    local x,y = self.pos()
    x,y = RectAnchorAt(x,y,self.fwidth,self.fheight,self.anchor)
    if touch.x < x then
        return false
    end
    if touch.y < y then
        return false
    end
    if touch.x > x + self.fwidth then
        return false
    end
    if touch.y > y + self.fheight then
        return false
    end
    self.tpoint = vec2(touch.x,touch.y) - vec2(self.x,self.y)
    return true
end

function PictureBrowser:processTouches(g)
    if g.type.moved and not g.type.long and not self.usecamera then
        self.x = g.touchesArr[1].touch.x - self.tpoint.x
        self.y = g.touchesArr[1].touch.y - self.tpoint.y
    end
    if g.type.ended then
        if self.usecamera then
            if g.type.moved then
                if cameraSource() == CAMERA_FRONT then
                    cameraSource(CAMERA_BACK)
                else
                    cameraSource(CAMERA_FRONT)
                end
            else
                local img = image(CAMERA)
                if self.callback(img) then
                    self:deactivate()
                else
                    self.usecamera = false
                end
            end
        elseif not g.type.moved then
            local t = g.touchesArr[1]
            local w = self.width + self.sep
            local x,y = self.pos()
            x,y = RectAnchorAt(x,y,self.fwidth,self.fheight,self.anchor)
            y = y + self.fheight
            x = math.ceil((t.touch.x - x)/w)
            y = math.floor((y - t.touch.y)/w)
            local n = self.size*y + x
            if n > 0 and n <= self.nimages then
                if self.camera and n == self.nimages then
                    self.usecamera = true
                elseif self.callback(self.images[n][1]) then
                    self:deactivate()
                end
            end
        end
        g:reset()
    else
        g:noted()
    end
end

function PictureBrowser:activate(f)
    self.active = true
    self.callback = f
    self.usecamera = false
end

function PictureBrowser:deactivate()
    self.active = false
    self.callback = nil
    self.usecamera = false
end

if _M then
    return PictureBrowser
else
    _G["PictureBrowser"] = PictureBrowser
end

