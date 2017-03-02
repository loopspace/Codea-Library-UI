--Project: Library UI
--Version: 2.3
--Dependencies:
--Comments:
--Options: NoConnect

cmodule "Library UI"
cmodule.path("Library Base", "Library Utilities")
Font,Sentence,Textarea = unpack(cimport "Font")
UTF8 = cimport "utf8"
Colour = cimport "Colour"
cimport "ColourNames"
-- kp_left = UTF8(5589)--utf8hex("ab")
VERSION = 2.3
clearProjectData()
-- DEBUG = true
-- Use this function to perform your initial setup
function setup()
    if AutoGist then
        autogist = AutoGist("Library UI","A library of classes and functions for user interface.",VERSION)
        autogist:backup(true)
    end
    --displayMode(FULLSCREEN_NO_BUTTONS)
    --[[
    if not cmodule then
        openURL("http://loopspace.mathforge.org/discussion/36/my-codea-libraries")
        print("You need to enable the module loading mechanism.")
        print("See http://loopspace.mathforge.org/discussion/36/my-codea-libraries")
        print("Touch the screen to exit the program.")
        draw = function()
        end
        touched = function()
            close()
        end
        return
    end
    --]]

    local Touches = cimport "Touch"
    
    -- local UI = cimport "UI"
    Debug = cimport "Debug"
    Colour = cimport "Colour"
    cimport "ColourNames"
    cimport "RoundedRectangle"
    --[[
    cimport "PictureBrowser"
    cimport "Menu"
    cimport "Keypad"
    cimport "Keyboard"
    cimport "NumberSpinner"
    cimport "FontPicker"
    cimport "CubicSelector"
    --]]
    touches = Touches()
    ui = UI(touches)

    debug = Debug({ui = ui})

    ui:systemmenu()
    ui:helpmenu()
    ui:addMessage("This is a system message, hello everyone.")

    debug:log({
        name = "Screen north west",
        message = function() local x,y = RectAnchorOf(Screen,"north west") return x .. ", " .. y end
    })
    --debug:activate()
    local m = ui:addMenu({title = "UI Examples", attach = true})
    m:addItem({
        title = "Select Picture",
        action = function()
            ui:getPicture(function(i) img = i return true end)
                return true
                end
    })
    ui:setPictureList({directory = "Documents", camera = true, filter = function(n,w,h) return math.min(w,h) > 500 end})
    tarea = Textarea({
        font = Font({name = "AmericanTypewriter", size = 20}),
        pos = function()
                    return WIDTH/2,3*HEIGHT/4
                end,
        anchor = "centre",
        width = "20em",
        height = "4lh",
        })
    tarea:activate()
    m:addItem({
        title = "Get String",
        action = function()
            local str = ""
            ui:useKeyboard("fullqwerty",
                function(k) 
                    if k == RETURN then
                        ui:addMessage("You typed: " .. str)
                        return true 
                    elseif k == BACKSPACE then
                        str = string.sub(str,1,-2)
                    else
                        str = str .. k
                    end
                    tarea:setLines(str)
                end)
            return true
            end
    })
    ui:declareKeyboard({name = "ArialMT", type = "fullqwerty"})
    m:addItem({
        title = "Get Number",
        action = function()
            ui:getNumberSpinner({
                action = function(n)
                    ui:addMessage(n)
                    return true
                    end
            })
            return true
            end
    })
    col = color(255, 255, 255, 255)
    m:addItem({
        title = "Choose Colour",
        action = function()
            ui:getColourWheel(col,function(c) col = c return true end)
                return true
                end
    })

    m:addItem({
        title = "Choose Font",
        action = function()
            ui:getFont(function(f) 
                tarea.font = Font({name = f,size = 20})
                return true end)
                return true
                end
    })
    m:addItem({
        title = "Get a Cubic",
        action = function()
            ui:getCurve(cubic,function(c) 
                cubic = c
                print(c)
                return true end)
                return true
                end
    })
end

-- This function gets called once every frame
function draw()
    -- process touches and taps
    touches:draw()
    background(34, 47, 53, 255)
    if img then
        local w,h = img.width,img.height
        local asp = math.min(WIDTH/w,HEIGHT/h,1)
        fill(col)
        rectMode(CENTER)
        rect(WIDTH/2,HEIGHT/2,w*asp,h*asp)
        asp = .9*asp
        sprite(img,WIDTH/2,HEIGHT/2,w*asp,h*asp)
    end
    tarea:draw()
    ui:draw()
    debug:draw()
    touches:show()
end

function touched(touch)
    touches:addTouch(touch)
end

function orientationChanged(o)
    if ui then
         ui:orientationChanged(o)
    end
end

function fullscreen()
end

function reset()
end
