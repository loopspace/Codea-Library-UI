-- FontPicker

if _M then
    ListSelector = cimport "ListSelector"
    Font,Sentence = unpack(cimport "Font")
end

local FontPicker = class()

FontPicker.Fonts = {
        {"Academy Engraved", "AcademyEngravedLetPlain"},
        {"American Typewriter","AmericanTypewriter",
            {
            {"Light", "AmericanTypewriter-Light"},
            {"Regular", "AmericanTypewriter"},
            {"Bold", "AmericanTypewriter-Bold"},
            {"Condensed Light", "AmericanTypewriter-CondensedLight"},
            {"Condensed", "AmericanTypewriter-Condensed"},
            {"Condensed Bold", "AmericanTypewriter-CondensedBold"},
            }
        },
        {"Arial","ArialMT",
            {
            {"Regular","ArialMT"},
            {"Italic","Arial-ItalicMT"},
            {"Bold","Arial-BoldMT"},
            {"Bold Italic","Arial-BoldItalicMT"},
            }
        },
        {"Baskerville","Baskerville",
            {
            {"Regular","Baskerville"},
            {"Italic","Baskerville-Italic"},
            {"SemiBold","Baskerville-SemiBold"},
            {"SemiBold Italic","Baskerville-SemiBoldItalic"},
            {"Bold","Baskerville-Bold"},
            {"Bold Italic","Baskerville-BoldItalic"},
            }
        },
        {"Bodoni IT","BodoniSvtyTwoITCTT-Book",
            {
            {"Regular","BodoniSvtyTwoITCTT-Book"},
            {"Italic","BodoniSvtyTwoITCTT-BookIta"},
            {"Bold","BodoniSvtyTwoITCTT-Bold"},
            {"Small Caps","BodoniSvtyTwoSCITCTT-Book"},
            }
        },
        {"Bodoni OSIT","BodoniSvtyTwoOSITCTT-Book",
            {
            {"Regular","BodoniSvtyTwoOSITCTT-Book"},
            {"Italic","BodoniSvtyTwoOSITCTT-BookIta"},
            {"Bold","BodoniSvtyTwoOSITCTT-Bold"},
            }
        },
        --{"Bodoni Ornaments","BodoniOrnamentsITCTT"},
        {"Bradley Hand","BradleyHandITCTT-Bold"},
        {"Chalkboard","ChalkboardSE-Light",
            {
            {"Regular","ChalkboardSE-Regular"},
            {"Bold","ChalkboardSE-Bold"},
            }
        },
        {"Chalkduster","Chalkduster"},
        {"Copperplate","Copperplate",
            {
            {"Light","Copperplate-Light"},
            {"Regular","Copperplate"},
            {"Bold","Copperplate-Bold"},
            }
        },
        {"Courier","Courier",
            {
            {"Regular","Courier"},
            {"Oblique","Courier-Oblique"},
            {"Bold","Courier-Bold"},
            {"Bold Oblique","Courier-BoldOblique"},
            }
        },
        {"Courier New","CourierNewPSMT",
            {
            {"Regular","CourierNewPSMT"},
            {"Bold","CourierNewPS-BoldMT"},
            {"Bold Italic","CourierNewPS-BoldItalicMT"},
            {"Italic","CourierNewPS-ItalicMT"},
            }
        },
        -- {"DBLCDTempBlack","DBLCDTempBlack"},
        {"Didot","Didot",
            {
            {"Regular","Didot"},
            {"Italic","Didot-Italic"},
            {"Bold","Didot-Bold"},
            }
        },
        {"Futura","Futura-Medium",
            {
            {"Medium","Futura-Medium"},
            {"Medium Italic","Futura-MediumItalic"},
            {"Condensed Medium","Futura-CondensedMedium"},
            {"Condensed Extra Bold","Futura-CondensedExtraBold"},
            }
        },
        {"Georgia","Georgia",
            {
            {"Regular","Georgia"},
            {"Italic","Georgia-Italic"},
            {"Bold","Georgia-Bold"},
            {"Bold Italic","Georgia-BoldItalic"},
            }
        },
        {"Gill Sans", "GillSans",
            {
            {"Light","GillSans-Light"},
            {"Light Italic","GillSans-LightItalic"},
            {"Regular","GillSans"},
            {"Italic","GillSans-Italic"},
            {"Bold","GillSans-Bold"},
            {"Bold Italic","GillSans-BoldItalic"},
            }
        },
        {"Helvetica","Helvetica",
            {
            {"Light","Helvetica-Light"},
            {"Light Oblique", "Helvetica-LightOblique"},
            {"Regular","Helvetica"},
            {"Oblique","Helvetica-Oblique"},
            {"Bold","Helvetica-Bold"},
            {"Bold Oblique","Helvetica-BoldOblique"},
            }
        },
        {"Helvetica Neue","HelveticaNeue",
            {
            {"Ultra Light","HelveticaNeue-UltraLight"},
            {"Ultra Light Italic", "HelveticaNeue-UltraLightItalic"},
            {"Light","HelveticaNeue-Light"},
            {"Light Italic","HelveticaNeue-LightItalic"},
            {"Regular","HelveticaNeue"},
            {"Italic","HelveticaNeue-Italic"},
            {"Medium","HelveticaNeue-Medium"},
            {"Bold","HelveticaNeue-Bold"},
            {"Bold Italic","HelveticaNeue-BoldItalic"},
            {"Condensed Bold","HelveticaNeue-CondensedBold"},
            {"Condensed Black","HelveticaNeue-CondensedBlack"},
            }
        },
        {"Hoefler","HoeflerText-Regular",
            {
            {"Regular","HoeflerText-Regular"},
            {"Italic","HoeflerText-Italic"},
            {"Bold","HoeflerText-Black"},
            {"Bold Italic","HoeflerText-BlackItalic"},
            }
        },
        {"Inconsolata","Inconsolata"},
        {"Marion","Marion-Regular",
            {
            {"Regular","Marion-Regular"},
            {"Italic","Marion-Italic"},
            {"Bold","Marion-Bold"},
            }
        },
        {"MarkerFelt","MarkerFelt-Thin",
            {
            {"Thin","MarkerFelt-Thin"},
            {"Wide","MarkerFelt-Wide"},
            }
        },
        {"Noteworthy","Noteworthy-Light",
            {
            {"Light","Noteworthy-Light"},
            {"Bold","Noteworthy-Bold"},
            }
        },
        {"Optima","Optima-Regular",
            {
            {"Italic","Optima-Italic"},
            {"Regular","Optima-Regular"},
            {"Bold","Optima-Bold"},
            {"Bold Italic","Optima-BoldItalic"},
            {"Extra Bold","Optima-ExtraBlack"},
            }
        },
        {"Palatino","Palatino-Roman",
            {
            {"Regular","Palatino-Roman"},
            {"Italic","Palatino-Italic"},
            {"Bold","Palatino-Bold"},
            {"Condensed","Palatino-BoldItalic"},
            }
        },
        {"Papyrus","Papyrus",
            {
            {"Regular","Papyrus"},
            {"Condensed","Papyrus-Condensed"},
            }
        },
        {"PartyLetPlain","PartyLetPlain"},
        {"Snell Roundhand","SnellRoundhand",
            {
            {"Regular","SnellRoundhand"},
            {"Bold","SnellRoundhand-Bold"},
            {"Black","SnellRoundhand-Black"},
            }
        },
        {"Times New Roman","TimesNewRomanPSMT",
            {
            {"Regular","TimesNewRomanPSMT"},
            {"Italic","TimesNewRomanPS-ItalicMT"},
            {"Bold","TimesNewRomanPS-BoldMT"},
            {"Bold Italic","TimesNewRomanPS-BoldItalicMT"},
            }
        },
        {"Trebuchet","TrebuchetMS",
            {
            {"Regular","TrebuchetMS"},
            {"Italic","TrebuchetMS-Italic"},
            {"Bold","TrebuchetMS-Bold"},
            {"Bold Italic","Trebuchet-BoldItalic"},
            }
        },
        {"Verdana","Verdana",
            {
            {"Regular","Verdana"},
            {"Italic","Verdana-Italic"},
            {"Bold","Verdana-Bold"},
            {"Bold Italic","Verdana-BoldItalic"},
            }
        },
     -- "ZapfDingbatsITC", -- Interesting chars not in range 0-255
        --]]
        --{"Zapfino","Zapfino"}
        --]]
    }

function FontPicker:init()
end

function FontPicker:activate(t)
    t = t or {}
    self.args = t
    local l = {}
    local f = t.fonts or self.Fonts
    t.fonts = nil
    self.fonts = f
    for k,v in ipairs(f) do
        table.insert(l,
            Sentence(Font({name = v[2], size = 24}), v[1]))
    end
    t.list = l
    self.action = t.action
    t.action = nil
    self.list = ListSelector(t)
    t.list = nil
    self.active = true
    self.list:activate({
        action = function(n) return self:processFont(n) end
    })
end

function FontPicker:deactivate()
    self.active = false
    self.action = nil
    self.list:deactivate()
    self.list = nil
end

function FontPicker:draw()
    if self.active then
        self.list:draw()
    end
end

function FontPicker:isTouchedBy(touch)
    if self.active and self.list then
        return self.list:isTouchedBy(touch)
    end
    return false
end
    
function FontPicker:processTouches(g)
    return self.list:processTouches(g)
end

function FontPicker:processFont(n)
    if self.fonts[n][3] then
        local t = self.args
        t.fonts = self.fonts[n][3]
        t.action = self.action
        self:activate(t)
    else
        if self.action(self.fonts[n][2]) then
            self:deactivate()
            return true
        end
    end
    return false
end

if _M then
    return FontPicker
else
    _G["FontPicker"] = FontPicker
end
