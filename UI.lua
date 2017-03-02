-- User interface class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
This is a "User Interface" class.  It is a container class that controls
the various pieces of the user interface: deciding whether they are drawn
and ensuring that they are registered with the "Touch Handler".

It is configured to use the "Touch Handler" class for touches, though
the interaction with that class is light so it could easily be
reconfigured to use some other system.  It uses the "Font" class to
define a "System Font", though again this is more to ensure that the
elements in the user interface that need a font have one.

By default, the class initialises a keypad, a numeric pad, a "main
menu", two text areas (a small one for "System Messages" and a larger
one for "Information"), a colour picker, and a slider.  Initially,
only the menu and the smaller text area are active (ie drawn): others
are activated on need.

The "User Interface" class provides some functions that are basically
wrappers around its elements.  For example, there is a "getText(f)"
method which activates the keypad and allows the user to specify some
text string.  The argument passed to this is a function which is
called when the user has finished specifying the string (such a
function is sometimes known as a "call-back").  This gets round the
problem that the program has to keep working while waiting for the
user to input the text.

Ideally, the "User Interface" is drawn last and is given first chance
at claiming a touch.  This requires the user not to override these.
Also, temporary elements (such as the keypad) should be drawn on top
of the more permanent ones (such as the main menu) and the temporary
elements should be given priority for claiming touches.  The class is
set up so that elements are drawn in the order in which they are
specified and touches are claimed in the reverse order.
--]]

local Font,Textarea,Colour = Font,Textarea,Colour
if _M then
    Font,_,Textarea = unpack(cimport "Font",nil)
    cimport "Coordinates"
    Colour = cimport "Colour"
end

local Menu,Keypad,ColourPicker,ColourWheel,Cubic,Keyboard,
        Slider,NumberSpinner,PictureBrowser,
        FontPicker,PalmRest,ListSelector,Button
= Menu,Keypad,ColourPicker,ColourWheel,Cubic,Keyboard,
        Slider,NumberSpinner,PictureBrowser,
        FontPicker,PalmRest,ListSelector,Button

local UI = class()

--[[
This is the initialiser function.  The sole argument is a "Touch
Handler" (though it would make sense to allow varying the font and the
initial family of elements).  We declare ourselves "active" (meaning
that the user interface elements are drawn) and initialise a few
standard elements: keypad, numeric pad, menu, message area,
information area, colour picker, and slider (not all are initially
active.
--]]
 
function UI:init(t,opts)
    opts = opts or {}
    self.touchHandler = t
    self.nelts = 0
    self.elements = {}
    self.elementHandlers = t:unshiftHandlers()
    self.systemfont = Font({name = "Courier", size = 16})
    self.largefont = Font({name = "Courier", size = 32})
    self.hugefont = Font({name = "Courier", size = 64})
    self.keyboards = {}
    self.timers = {}
    self.active = true
    self.screen = Screen
    self.orientation = CurrentOrientation
    self:supportedOrientations(ANY)
    local mopts

    if _M then
        if cmodule.loaded "Button" then
            Button = cimport "Button"
        end
        if cmodule.loaded "Menu" then
            Menu = cimport "Menu"
        end
        if cmodule.loaded "Keypad" then
            Keypad = cimport "Keypad"
        end
        if cmodule.loaded "ColourPicker" then
            ColourPicker = cimport "ColourPicker"
        end
        if cmodule.loaded "ColourWheel" then
            ColourWheel = cimport "ColourWheel"
        end
        if cmodule.loaded "Cubic" then
            Cubic = cimport "Cubic"
        end
        if cmodule.loaded "Keyboard" then
            Keyboard = cimport "Keyboard"
        end
        if cmodule.loaded "Slider" then
            Slider = cimport "Slider"
        end
        if cmodule.loaded "NumberSpinner" then
            NumberSpinner = cimport "NumberSpinner"
        end
        if cmodule.loaded "PictureBrowser" then
            PictureBrowser = cimport "PictureBrowser"
        end
        if cmodule.loaded "FontPicker" then
            FontPicker = cimport "FontPicker"
        end
        if cmodule.loaded "PalmRest" then
            PalmRest = cimport "PalmRest"
        end
        if cmodule.loaded "ListSelector" then
            ListSelector = cimport "ListSelector"
        end
    end
    
    if Menu then
        local xshift
        if displayMode() ~= FULLSCREEN_NO_BUTTONS then
            xshift = 50
        else
            xshift = 10
        end
        mopts = {
        pos = function()
                local x,y = RectAnchorOf(self.screen,"north west")
                x = x + xshift
                y = y - 10
                return x,y
            end,
        anchor = "north west",
        font = self.systemfont
        }
        if opts.mainMenu then
            for k,v in pairs(opts.mainMenu) do
                mopts[k] = v
            end
        end
    self.mainMenu = Menu(mopts)
    self.mainMenu.dir = "x"
    self.mainMenu.active = true
    self.mainMenu.autoactive = false
    -- cancel stuff might not be needed any longer
    self.cancel = Menu({
        pos = function()
                local x,y = RectAnchorOf(self.screen,"north east")
                x = x - 10
                y = y - 10
                return x,y
            end,
        anchor = "north east",
        font = self.largefont
    })
    self.cancel.active = false
    self.cancel:addItem({
        title = "Cancel",
        action = function()
                    self:cancelActivity()
                end
    })
    self.tocancel = {}
    self:addElement(
        self.mainMenu,
        self.cancel
        )
    end
    if Keypad then
        mopts = {
        pos = function()
                local x,y = RectAnchorOf(self.screen,"west")
                x = x + 50
                return x,y
            end,
        anchor = "west",
        width = 75,
        height = 50,
        colour = Colour.svg.Magenta
        }
        if opts.keypad then
            for k,v in pairs(opts.keypad) do
                mopts[k] = v
            end
        end
    self.keypad = Keypad(mopts)
    mopts = {
        pos = function()
                local x,y = RectAnchorOf(self.screen,"west")
                x = x + 50
                return x,y
            end,
        anchor = "west",
        width = 75,
        height = 50,
        colour = Colour.svg.DeepPink,
        numeric = true
        }
        if opts.numpad then
            for k,v in pairs(opts.numpad) do
                mopts[k] = v
            end
        end
    self.numpad = Keypad(mopts)
    self:addElement(
        self.keypad,
        self.numpad
        )
        self:addHelp({
            title = "Key and numeric pads",
            text = Keypad.help
        })
    end
    if ColourPicker then
    self.colourPicker = ColourPicker()
    self:addElement(
        self.colourPicker
        )
        self:addHelp({
            title = "Colour Picker",
            text = ColourPicker.help
        })
    end
    if ColourWheel then
    self.colourWheel = ColourWheel()
    self:addElement(
        self.colourWheel
        )
        self:addHelp({
            title = "Colour Wheel",
            text = ColourWheel.help
        })
        self.useWheel = true
    end
    if Cubic then
        self.cubic = Cubic(vec4(0,1,0,0))
        self:addElement(self.cubic)
        self:addHelp({
            title = "Cubic Curve",
            text = Cubic.help
        })
    end
    if Slider then
        Slider = cimport "Slider"
        mopts = {
            a = function()
                    local x,y = RectAnchorOf(self.screen,"west")
                    x = x + 50
                    y = y + 
                    math.min(200,2*RectAnchorOf(self.screen,"height")/3)
                    return x,y
                end,
            b = function()
                    local x,y = RectAnchorOf(self.screen,"west")
                    x = x + 50
                    y = y - 
                    math.min(200,2*RectAnchorOf(self.screen,"height")/3)
                    return x,y
                end,
            colour = Colour.svg.Coral
        }
        if opts.slider then
            for k,v in pairs(opts.slider) do
                mopts[k] = v
            end
        end
        self.slider = Slider(mopts)
        self:addElement(
            self.slider
        )
        self:addHelp({
            title = "Slider",
            text = Slider.help
        })
    end

    if NumberSpinner then
        mopts = {
            -- font = self.hugefont
            pos = function() return RectAnchorOf(self.screen,"centre") end
        }
        if opts.numberSpinner then
            for k,v in pairs(opts.numberSpinner) do
                mopts[k] = v
            end
        end
        self.numberspinner = NumberSpinner(mopts)
        self:addElement(
            self.numberspinner
        )
        self:addHelp({
            title = "Number Spinner",
            text = NumberSpinner.help
        })
        self.useSpinner = true
    end
    if PictureBrowser then
        self.picturebrowser = PictureBrowser()
        self:addElement(self.picturebrowser)
    end
    if FontPicker then
        self.fontpicker = FontPicker()
        self:addElement(self.fontpicker)
    end
    if Textarea then
        mopts = {
        font = self.systemfont,
        pos = function()
                    return 10,10
                end,
        width = "20em",
        height = "4lh",
        title = "System Messages"
        }
        if opts.messages then
            for k,v in pairs(opts.messages) do
                mopts[k] = v
            end
        end
    self.messages = Textarea(mopts)
    -- self.messages.active = true
    mopts = {
        font = self.systemfont,
        pos = function()
                    return RectAnchorOf(self.screen,"centre")
                end,
        width = "math.min(80em,WIDTH)",
        height = "15lh",
        anchor = "centre",
        title = "Information",
        vfill = true
        }
        if opts.information then
            for k,v in pairs(opts.information) do
                mopts[k] = v
            end
        end
    self.information = Textarea(mopts)
    mopts = {
        font = self.largefont,
        pos = function()
                    local x,y = RectAnchorOf(self.screen,"centre")
                    return x,y
                end,
        width = "math.min(80em,WIDTH)",
        height = "10lh",
        anchor = "centre",
        fit = true,
        fadeTime = 2
        }
        if opts.notices then
            for k,v in pairs(opts.notices) do
                mopts[k] = v
            end
        end
    self.notices = Textarea(mopts)
    mopts = {
        font = self.systemfont,
        pos = function()
                    local x,y = RectAnchorOf(self.screen,"north east")
                    y = y - 50
                    return x,y
                end,
        width = "math.min(80em,WIDTH)",
        height = "30lh",
        anchor = "north east",
        fit = true
        }
        if opts.helptext then
            for k,v in pairs(opts.helptext) do
                mopts[k] = v
            end
        end
    self.helptxt = Textarea(mopts)
    self:addElement(
        self.notices,
        self.helptxt,
        self.information,
        self.messages
    )
    self:addHelp({
        title = "Text boxes",
        text = Textarea.help
    })
    end
    if PalmRest then
       self.palmrest = PalmRest({
                                })
       self:addElement(self.palmrest)
    self:addHelp({
        title = "Palm rest",
        text = PalmRest.help
    })
    end
    if ListSelector then
        self.listselector = ListSelector()
        self:addElement(self.listselector)
        self:addHelp({
            title = "List Selector",
            text = ListSelector.help
        })
    end
end

--[[
This is the draw function.  If we're active then we draw all our
elements (not all will actually draw: we just call their "draw"
method).  We also ensure that if we're active then the main menu is
active (this is a sanity check as menus are sometimes deactivated by
their children).  We ensure that the matrix and style are saved and
reset.
--]]

function UI:draw()
    self:checkTimers()
    if not self.active then
        return false
    end
    pushMatrix()
    pushStyle()
    resetMatrix()
    viewMatrix(matrix())
    ortho()
    TransformOrientation(self.orientation)
    for k=self.nelts,1,-1 do
        self.elements[k]:draw()
    end
    popMatrix()
    popStyle()
end

--[[
This adds a new element, or new elements, to the user interface; for
example, a new menu.  The arguments are a list of objects of
appropriate classes.
--]]

function UI:addElement(...)
    for k,v in ipairs({...}) do
        table.insert(self.elements,v)
        table.insert(self.elementHandlers, 
            self.touchHandler:registerHandler(v))
        self.nelts = self.nelts + 1
        self:modifyTouchedBy(v)
        self:modifyprocessTouches(v)
    end
end

function UI:modifyTouchedBy(v)
    local f = v.isTouchedBy
    v.isTouchedBy = function(s,t)
        t = TransformTouch(self.orientation,t)
        return f(s,t)
        end
end

function UI:modifyprocessTouches(v)
    local f = v.processTouches
    v.processTouches = function(s,g)
        g:transformTouches(self.orientation)
        return f(s,g)
        end
end

function UI:activateElement(e)
    local i,h
    for k=self.nelts,1,-1 do
        if self.elements[k] == e then
            h = self.elementHandlers[k]
            i = true
        else
            if i then
                self.elements[k+1] = self.elements[k]
                self.elementHandlers[k+1] = self.elementHandlers[k]
            end
        end
    end
    if i then
        self.elements[1] = e
        self.elementHandlers[1] = h
    end
end
        

--[[
This adds a submenu to the main menu.  The argument is the title
(which appears in the main menu).  It returns the newly created menu
which can then have elements added to it (see the "Menu" class for
more on this).
--]]

function UI:addMenu(t)
    t = t or {}
    local x = t.x or 0
    local y = t.y or 0
    local pos = function() return x,y end
    local ae = t.atEnd or false
    local m
    local mopts = {font = self.systemfont, pos = pos, floating = true}
    if not t.attach then
        mopts.title = t.title
    end
    local tmopts = t.menuOpts or {}
    for k,v in pairs(tmopts) do
        mopts[k] = v
    end
    
    m = Menu(mopts)
    if t.attach then
    self.mainMenu:addItem({
        title = t.title,
        action = function(x,y)
            if m.active then
                m:deactivateDown()
            else
                m:activate(x,y)
            end
        end,
        deselect = function()
            m:deactivateDown()
        end,
        highlight = function()
            return m.active
        end,
        atEnd = ae
    })
    end
    self:addElement(m)
    return m
end

--[[
Adds a button to the UI
--]]

function UI:addButton(t)
    local b = Button(t)
    self:addElement(b)
    return b
end

--[[
The following all initiate some activity.  We need a cancellation method.
--]]

function UI:cancelActivity()
    for k,v in ipairs(self.tocancel) do
        v:deactivate()
    end
    self.tocancel = {}
    self.cancel:deactivate()
end

--[[
This is a wrapper around the keypad activation method.  The argument
is a "call back" function that will be called when the keypad has
finished and the text entered by the user is available to the program
for use.
--]]

function UI:getText(f)
    self:activateElement(self.keypad)
    self.keypad:activate(f)
end

--[[
This is similar to the "getText" function except that it uses the
numeric keypad instead of the normal keypad.
--]]

function UI:getNumberPad(f)
    self:activateElement(self.numpad)
    self.numpad:activate(f)
end

--[[
This gets a number using a number spinner.
--]]

function UI:getNumberSpinner(...)
    self:activateElement(self.numberspinner)
    self.numberspinner:activate(...)
end

--[[
This gets a number using the preferred method.
--]]

function UI:getNumber(f)
    if self.useSpinner then
        self:getNumberSpinner({action = f})
    else
        self:getNumberPad(f)
    end
end

--[[
This activates the colour picker.  The two arguments are the list of
colours to use and the call-back function.  See the "ColourPicker"
class for details of what these arguments should be like.
--]]



function UI:getColourPicker(t,f)
    self:activateElement(self.colourPicker)
    self.colourPicker:setList(t)
    self.colourPicker:activate(f)
end

--[[
This activates the colour wheel.  The argument is the call-back
function and initial/current colour.
--]]

function UI:getColourWheel(c,f)
    self:activateElement(self.colourWheel)
    self.colourWheel:activate(c,f)
end

--[[
This gets a colour using the preferred method.
--]]

function UI:getColour(t,f)
    if type(t) == "string" then
        self:getColourPicker(t,f)
        return
    end
    if type(t) == "function" then
        t,f = f,t
    end
    if self.useWheel then
        if not t then
            t = Colour.svg.Black
        end
        self:getColourWheel(t,f)
    else
        if type(t) ~= "string" then
            t = ""
        end
        self:getColourPicker(t,f)
    end
end

--[[
Gets a font name.
--]]

function UI:getFont(f)
    self:activateElement(self.fontpicker)
    self.fontpicker:activate({action = f})
end

--[[
Gets a picture as an image.
--]]

function UI:setPictureList(t)
    self.picturebrowser:setList(t)
end

function UI:getPicture(f)
    self:activateElement(self.picturebrowser)
    self.picturebrowser:activate(f)
end

--[[
This is a wrapper for the cubic curve object.
--]]

function UI:getCurve(...)
    self:activateElement(self.cubic)
    self.cubic:activate(...)
end

--[[
This is a wrapper for the "slider" object, which allows the user to
specify a parameter by sliding a "slider".  See the "Slider" class for
the allowed arguments to this function.
--]]

function UI:getParameter(...)
    self:activateElement(self.slider)
    self.slider:activate(...)
end

--[[
This gets an item from a list.
--]]

function UI:getItem(t)
    self:activateElement(self.listselector)
    self.listselector:setList({
        list = t.list,
        font = t.font or self.systemfont
    })
    self.listselector:activate({
        pos = t.pos,
        value = t.value,
        action = t.action
        })
end

--[[
This adds a message to the "System Messages" text area, also ensuring
that this is active.  See the "Textarea" class for the parameters to
pass to this.
--]]

function UI:addMessage(...)
    if not self.messages then
        return false
    end
    self.messages:addLine(...)
    self.messages:activate()
end

--[[
This is the same as "addMessage" except that it adds the message to
the "Information" text area.
--]]

function UI:addInformation(...)
    if not self.information then
        return false
    end
    self.information:addLine(...)
    self.information:activate()
end

--[[
This is the same as "addMessage" except that it adds the message to
the "Notices" text area and sets a timer.
--]]

function UI:addNotice(t)
    if not self.notices then
        return false
    end
    local time = t.time or 7
    if type(t.text) == "table" then
        self.notices:setLines(unpack(t.text))
    else
        self.notices:setLines(t.text)
    end
    if t.pos then
        self.notices.opos = t.pos
    else
        self.notices.opos = function()
                    return RectAnchorOf(self.screen,"centre")
                end
    end
    self.notices:resetAnchor()
    self.notices.fade = t.fadeTime or 2
    self.notices:activate()
    self:setTimer(time,function() self.notices:deactivate() return true end)
end

function UI:setTimer(t,dt,f)
    if type(dt) == "function" then
        dt,f = 0,dt
    end
    table.insert(self.timers,{t + ElapsedTime,dt,f})
end

function UI:checkTimers()
    local rm,n = {},0
    local ret
    for k,v in ipairs(self.timers) do
        if ElapsedTime > v[1] then
            ret = v[3]()
            if ret == true then
                table.insert(rm,k)
                n = n + 1
            elseif type(ret) == "number" then
                v[1] = ElapsedTime + ret
            else
                v[1] = ElapsedTime + v[2]
            end
        end
    end
    if n > 0 then
        for k = n,1,-1 do
            table.remove(self.timers,rm[k])
        end
    end
end

function UI:reset()
    for k,v in ipairs(self.elements) do
        if v.reset and type(v.reset) == "function" then
            v:reset()
        end
    end
end

function UI:pause(p)
    for k,v in ipairs(self.elements) do
        if v.pause and type(v.pause) == "function" then
            v:pause(p)
        end
    end
end

function UI:orientationChanged(o)
    if not self.allowedOrientations[o] then
        return
    end
    self.orientation = o
    self.screen = Screen
    for k,v in ipairs(self.elements) do
        if v.orientationChanged and type(v.orientationChanged) == "function" then
            v:orientationChanged(o)
        end
    end
end

function UI:setOrientation(o,t)
    if t then
        self.allowedOrientations = t
    end
    o = ResolveOrientation(o,CurrentOrientation)
    self.orientation = o
    if o == PORTRAIT or o == PORTRAIT_UPSIDE_DOWN then
        self.screen = Portrait
    else
        self.screen = Landscape
    end
    for k,v in ipairs(self.elements) do
        if v.orientationChanged and type(v.orientationChanged) == "function" then
            v:orientationChanged(o)
        end
    end
end

function UI:supportedOrientations(...)
    self.allowedOrientations = {}
    for _,v in ipairs({...}) do
        if v < 4 then
            self.allowedOrientations[v] = true
        elseif v == 4 then
            self.allowedOrientations[0] = true
            self.allowedOrientations[1] = true
        elseif v == 5 then
            self.allowedOrientations[2] = true
            self.allowedOrientations[3] = true
        elseif v == 6 then
            self.allowedOrientations[0] = true
            self.allowedOrientations[1] = true
            self.allowedOrientations[2] = true
            self.allowedOrientations[3] = true
        end
    end
end

function UI:declareKeyboard(...)
     local kbd = Keyboard(...)
     ui:addElement(kbd)
     self.keyboards[kbd.type] = kbd
     return kbd
 end
 
 function UI:useKeyboard(t,f)
     if self.keyboards[t] then
        self:activateElement(self.keyboards[t])
         self.keyboards[t]:activate(f)
        self.activekbd = self.keyboards[t]
     end
 end

function UI:unuseKeyboard(t)
    if t then
        if self.keyboards[t] then
             self.keyboards[t]:deactivate()
            if self.activekbd == self.keyboards[t] then
                self.activekbd = nil
            end
        end
    else
        if self.activekbd then
            self.activekbd:deactivate()
            self.activekbd = nil
        end
    end
end

function UI:keyboardtop()
    if self.activekbd then
        return self.activekbd.top
    else
        return 0
    end
end

function UI:systemmenu()
    local m = self:addMenu({title = "Main", attach = true})
    if fullscreen then
    m:addItem({
        title = "Fullscreen",
        action = function()
            fullscreen()
            return true
        end,
        highlight = function()
            return displayMode() ~= STANDARD
        end
    })
    end
    if pause then
    m:addItem({
        title = "Pause",
        action = function()
            pause()
            return true
        end,
        highlight = function()
            return _G["paused"]
        end
    })
    end
    if reset then
    m:addItem({
        title = "Reset",
        action = function()
            reset()
            return true
        end
    })
    end
    m:addItem({
        title = "Start Recording",
        action = function() DoAtEndDraw(function()
                if not isRecording() then
                    startRecording()
                end
                    return true
                end)
            return true
        end
    })
    m:addItem({
        title = "Stop Recording",
        action = function() DoAtEndDraw(function()
                if isRecording() then
                    stopRecording()
                end
                    return true
                end)
            return true
        end
    })
    if hide then
    m:addItem({
        title = "Hide",
        action = function()
            hide()
            return true
        end
    })
    end
    m:addItem({
        title = "Reset touches",
        action = function()
            self.touchHandler:reset()
            return true 
        end})
    m:addItem({
        title = "Exit",
        action = function()
            close() 
            return true 
        end})
    paused = false
    return m
end

function UI:helpmenu()
    local m = self:addMenu({title = "Help", attach = true, atEnd = true})
    self.helpm = m
    if self.helps then
        for k,v in ipairs(self.helps) do
            m:addItem({
        title = v[1],
        action = function()
            if self.helptxt.active then
                self.helptxt:deactivate()
            else
                self.helptxt:activate()
                self.helptxt:setLines(unpack(v[2]))
            end
            return true
        end
            })
        end
    end
    return m
end

function UI:addHelp(t)
    t = t or {}
    local text = t.text
    if type(text) ~= "table" then
        text = {text}
    end
    table.insert(text,"(Double-tap this box to hide it.)")
    if self.helpm then
    self.helpm:addItem({
        title = t.title,
        action = function()
            if self.helptxt.active then
                self.helptxt:deactivate()
            else
                self.helptxt:activate()
                self.helptxt:setLines(unpack(text))
            end
            return true
        end
    })
    else
        self.helps = self.helps or {}
        table.insert(self.helps,{t.title,text})
    end
end

function UI:removeHelp(t)
    if self.helpm then
        return self.helpm:removeItem(t)
    elseif self.helps then
        for k,v in ipairs(self.helps) do
            if v.title == t then
                table.remove(self.helps,k)
                return v
            end
        end
    end
end

function UI:hide(t)
    t = t or 5
    self:addNotice({text = "The hidden things will return after " .. t .. " seconds"})
    self:setTimer(7,function() self.active = false return true end)
    self:setTimer(t+7,function() unhide() return true end)
end

function UI:unhide()
    self.active = true
end

--[[
Helper functions to delay stuff to the end of the current draw function.  To
make use of these, you must call AtEndOfDraw() in the draw function (at the
end, obviously).
--]]

function AtEndOfDraw()
    local t = atenddraw or {}
    local s = {}
    for k,v in ipairs(t) do
        if not v() then
            table.insert(s,v)
        end
    end
    atenddraw = s
end

function DoAtEndDraw(f)
    atenddraw = atenddraw or {}
    table.insert(atenddraw,f)
end

if _M then
    cmodule.gexport {
    AtEndOfDraw = AtEndOfDraw,
    DoAtEndDraw = DoAtEndDraw
    }
    
    return UI
else
    _G["AtEndOfDraw"] = AtEndOfDraw
    _G["DoAtEndDraw"] = DoAtEndDraw
    _G["UI"] = UI
end

