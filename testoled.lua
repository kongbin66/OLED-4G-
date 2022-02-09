module(..., package.seeall)

require "sys"
require "mono_lcd_spi_ssd1306"
require "utils"
require "common"
require "pm"
require "misc"

function showInit()

end

sys.taskInit(function()
    showInit()
    while true do
        a = 1
        disp.sleep(0)
        while a < 20 do
            disp.clear()
            disp.puttext(common.utf8ToGb2312(a), 18, 18)
            disp.update()
            sys.wait(1000)
            a = a + 1
        end
        disp.sleep(1)
        sys.wait(5000)
    end

end)



