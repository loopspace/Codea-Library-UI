-- Cubic

local Cubic = class()

local cubicShader

function Cubic:init(...)
    self.scale = 200
    self.x = WIDTH/2
    self.y = HEIGHT/2
    self.colour = color(161, 140, 24, 255)
    self.bgcolour = color(61, 29, 29, 255)
    self.guidecolour = color(28, 101, 139, 129)
    local m = mesh()
    local nsteps = 200
    local w = 5
    local h = 1
    for n=1,nsteps do
        m:addRect(0,(n-.5)*h,w,h)
    end
    local s = shader()
    s.vertexProgram,s.fragmentProgram = cubicShader()
    m.shader = s
    m.shader.len = nsteps
    self.mesh = m
    self:setCoefficients(...)
end

function Cubic:setCoefficients(...)
    local arg = {...}
    if arg[4] then
        self.coefficients = vec4(arg[1],arg[2],arg[3],arg[4])
    elseif arg[1] then
        if type(arg[1]) == "table" then
            self.coefficients = arg[1].coefficients
        else
            self.coefficients = arg[1]
        end
    end
    self.coefficients = self.coefficients or vec4(0,1,0,0)
    self:toBezier()
    self:update()
end

function Cubic:update()
    self.mesh.shader.pts_1 = self.coefficients.x
    self.mesh.shader.pts_2 = self.coefficients.y
    self.mesh.shader.pts_3 = self.coefficients.z
    self.mesh.shader.pts_4 = self.coefficients.w
end

function Cubic:toBezier()
    self.bezier = vec4(
        self.coefficients.x,
        self.coefficients.y/3,
        self.coefficients.x + 2*self.coefficients.y/3
        + self.coefficients.z/3,
        self.coefficients.x + self.coefficients.y
        + self.coefficients.z + self.coefficients.w
    )
end

function Cubic:fromBezier()
    self.coefficients = vec4(
        self.bezier.x,
        3*(self.bezier.y - self.bezier.x),
        3*(self.bezier.x - 2*self.bezier.y + self.bezier.z),
        -self.bezier.x + 3*self.bezier.y - 3*self.bezier.z + self.bezier.w
    )
    self:update()
end

function Cubic:draw()
    if not self.active then
        return
    end
    pushMatrix()
    resetMatrix()
    pushStyle()
    resetStyle()
    translate(self.x - self.scale/2,self.y - self.scale/2)
    scale(self.scale)
    fill(self.bgcolour)
    RoundedRectangle(-.2,-.2,1.4,1.4,.2)
    strokeWidth(5/self.scale)
    lineCapMode(SQUARE)
    stroke(0, 0, 0, 255)
    line(0,0,0,1)
    line(0,1,1,1)
    line(1,1,1,0)
    line(1,0,0,0)
    self.mesh:setColors(self.colour)
    self.mesh:draw()
    stroke(self.guidecolour)
    line(0,self.bezier.x,1/3,self.bezier.y)
    line(1/3,self.bezier.y,2/3,self.bezier.z)
    line(2/3,self.bezier.z,1,self.bezier.w)
    popStyle()
    popMatrix()
end

function Cubic:isTouchedBy(touch)
    return self.active
end

function Cubic:processTouches(g)
    if g.updated then
        if g.num == 1 then
            local t = g.touchesArr[1]
            local v = vec2(t.touch.x,t.touch.y)
            v = v - vec2(self.x - self.scale/2,self.y - self.scale/2)
            v = v / self.scale
            if t.touch.state == BEGAN then
                if v.x < 1/6 then
                    self.moving = "x"
                elseif v.x < 1/2 then
                    self.moving = "y"
                elseif v.x < 5/6 then
                    self.moving = "z"
                else
                    self.moving = "w"
                end
            elseif g.type.moved then
                self.bezier[self.moving] = v.y
                self:fromBezier()
                if self.ctscallback then
                    self.ctscallback(self.coefficients)
                end
            end
        elseif g.type.tap and g.type.ended then
            if self.callback then
                if self.callback(self.coefficients) then
                    self:deactivate()
                end
            end
        elseif g.type.moved then
            local v,n = vec2(0,0),0
            for _,t in ipairs(g.touchesArr) do
                if t.updated then
                    v = v + vec2(t.touch.deltaX,t.touch.deltaY)
                    n = n + 1
                end
            end
            if n > 0 then
                v = v / n
                self.x = self.x + v.x
                self.y = self.y + v.y
            end
        end
        g:noted()
    end
    if g.type.ended and not g.type.tap then
        g:reset()
    end
end

function Cubic:activate(v,f,ff,b)
    self.active = true
    self.callback = f
    self.ctscallback = ff
    if v then
        if b then
            self.bezier = v
            self:fromBezier()
        else
            self.coefficients = v
            self:toBezier()
            self:update()
        end
    end
end

function Cubic:deactivate()
    self.active = false
    self.callback = nil
    self.ctscallback = nil
end

if testsuite then
    
    
    testsuite.addTest({
        name = "Cubic",
        setup = function()
            local w = Cubic(1,2,3,4)
            print(w.coefficients)
            local z = Cubic(vec4(2,3,4,5))
            print(z.coefficients)
        end,
        draw = function()
        end
    })
end

cubicShader = function()
    return [[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;

//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

//This is an output variable that will be passed to the fragment shader
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

uniform float pts_1;
uniform float pts_2;
uniform float pts_3;
uniform float pts_4;
uniform float len;

void main()
{
    highp float t = position.y/len;
    highp float y = pts_1 + t*pts_2 + t*t*pts_3 + t*t*t*pts_4;
    highp float dy = pts_2 + 2.0*t*pts_3 + 3.*t*t*pts_4;
    highp vec2 bdir = vec2(dy,-1.);
    bdir = position.x*normalize(bdir)/len;
    highp vec2 bpos = vec2(t,y) + bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0,1);
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = texCoord;
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * bzpos;
}
]],[[
//
// A basic fragment shader
//

//This represents the current texture on the mesh
uniform lowp sampler2D texture;

//The interpolated vertex color for this fragment
varying lowp vec4 vColor;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = vColor;
    if (vTexCoord.x < .2)
        col.a = col.a*vTexCoord.x/.2;
    if (vTexCoord.x > .8)
        col.a = col.a*(1.-vTexCoord.x)/.2;
    //Set the output color to the texture color
    gl_FragColor = col;
}
]]
end

if _M then
    return Cubic
else
    _G["Cubic"] = Cubic
end

