-- Palm Rest

local PalmRest = class()
if _M then
    cimport "RoundedRectangle"
    cimport "Coordinates"
end

function PalmRest:init(t)
      t = t or {}
      self.orientation = t.orientation
      self.height = t.height or 0
    self.opacity = t.opacity or 127
      self.mesh = mesh()
      local w = math.max(WIDTH,HEIGHT)
      self.width = w
      self.mesh:addRect(w/2,-w/2-5,w+10,w+10)
      self.mesh:setRectColor(1,0,0,0,self.opacity)
    --[[
      RoundedRectangle({
                            mesh = self.mesh,
                            x = w/2,
                            y = 0,
                            width = 200,
                            height = 50,
                            corners = 9,
                            anchor = "south",
                            colour = color(0,0,0,o)
                     })
      RoundedRectangle({
                        mesh = self.mesh,
                        x = w/2,
                        y = 25,
                        width = 160,
                        height = 10,
                        radius = 3,
                        corners = 0,
                        anchor = "centre",
                        colour = color(127,127,127,o)
                     })
    --]]
      self.active = t.active or true
   end

   function PalmRest:draw()
      if not self.active then
         return
      end
      local o,w = self.opacity,self.width
      pushMatrix()
      resetMatrix()
    pushStyle()
      if self.orientation then
         TransformOrientation(self.orientation)
      end
      translate((WIDTH - self.width)/2,self.height)
      self.mesh:draw()
    fill(color(0,0,0,o))
      RoundedRectangle(
                        w/2-100,
                        0,
                        200,
                        50,
                        5,
                        9,
                        0
                    )
    fill (color(127,127,127,o))
      RoundedRectangle(
                        w/2-80,
                        25,
                        160,
                        10,
                        3,
                        0,
                        0
                    )
    popStyle()
      popMatrix()
   end

   function PalmRest:isTouchedBy(touch)
      if not self.active then
         return false
      end
      local v
      if self.orientation then
         v = OrientationInverse(self.orientation,vec2(touch.x,touch.y))
      else
         v = vec2(touch.x,touch.y)
      end
      if v.y < self.height then
         return true
      end
      if v.y < self.height + 50 and math.abs(v.x - WIDTH/2) < 100 then
         return true
      end
      return false
   end

   function PalmRest:processTouches(g)
      for k,v in ipairs(g.touchesArr) do
         if v.updated then
            local x
            if self.orientation then
                  x = OrientationInverse(
                    self.orientation,
                    vec2(v.touch.x,v.touch.y))
            else
                  x = vec2(v.touch.x,v.touch.y)
            end
            if v.touch.state == BEGAN then 
                if x.y < self.height then
                    v:destroy()
                end
            else
                 local y
                 if self.orientation then
                  y = OrientationInverse(
                    self.orientation,
                    vec2(v.touch.prevX,v.touch.prevY))
               else
                  y = vec2(v.touch.prevX,v.touch.prevY)
               end
               self.height = math.max(0,self.height + x.y - y.y)
            end
         end
      end
      if g.type.ended then
         g:reset()
      else
         g:noted()
      end
   end

PalmRest.help = "The palm rest defines an area of the screen where touches are ignored.  Drag the tab to set the height."

if _M then
    return PalmRest
else
    _G["PalmRest"] = PalmRest
end

