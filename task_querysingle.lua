--周期获取信号质量
module(..., package.seeall)
require "utils"
require "pm"

sys.taskInit(function()--周期获取信号质量
    while true do
        pm.wake("QUERY_SINGLE")
        if not _G.FLY_STATE then--不在飞行模式下
            net.csqQueryPoll()
            net.cengQueryPoll()
            sys.wait(2000)
            while _G.SINGLE_QUERY ==0  and _G.LCD_STATE do
                _G.SINGLE_QUERY = net.getRssi()
                log.info("getting获取信号强度",_G.SINGLE_QUERY)
                sys.wait(2000)
            end
            _G.SINGLE_QUERY = net.getRssi()
            log.info("final获取信号强度",_G.SINGLE_QUERY)
            net.stopQueryAll()
        end
        pm.sleep("QUERY_SINGLE")
        sys.wait(600000)
    end
end)
