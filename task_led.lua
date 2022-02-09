--¶©ÔÄALERT_ON,Âú×ãÊ±Éù¹â±¨¾¯ 
module(..., package.seeall)
require "utils"
require "pm"
require "pins"

local alert_led = pins.setup(11, 0)--LED
local alert_beep = pins.setup(9, 0)--beep

function red_led_while_alert_on()
    sys.taskInit(function()
        print("_G.period * 60 / 2 -2", _G.period * 60 / 2 - 2)
        for i = 1, _G.period * 60 / 2 - 2 do
            print("=========================:", i)
            alert_led(1)
            -- alert_beep(1)
            sys.wait(500)
            alert_led(0)
            -- alert_beep(0)
            sys.wait(1500)
        end
    end)
end


sys.subscribe("ALERT_ON", red_led_while_alert_on)

