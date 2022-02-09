--- 模块功能：onenet studio功能测试.
-- @module onenet
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.4.7
module(..., package.seeall)

require "ntp"
require "pm"
require "misc"
require "mqtt"
require "utils"
require "patch"
require "socket"
require "http"
require "common"
require "lbsLoc"

-- 产品ID和产品动态注册秘钥
local ProductId = _G.ProductId
local DeviceName = _G.DeviceName
local token = _G.token
local onenet_mqttClient
local onenet_start_flag = true
local onenet_get_desired_flag = false --获得到渴望值标志
local onenet_start_time = os.time()
local onenet_last_time = os.time()
local connect_fail_count = 0
local publish_success
local last_sleep_time = 0
local last_wake_time = os.time()

local function task_onenet_reconnect()--连接MQTT客户端，成功清计数器退出。连接20次失败，转为飞行模式，清计数器退出
    while (not onenet_mqttClient.connected) and (connect_fail_count < 20) do
        print("****************net.getState():", net.getState())
        print("****************not onenet_mqttClient.connected:", not onenet_mqttClient.connected)
        connect_fail_count = connect_fail_count + 1
        _G.tempfail = connect_fail_count
        sys.wait(2000)
        log.warn("-------连接onenet...---------", connect_fail_count)
        onenet_mqttClient:connect("218.201.45.7", 1883)
    end

    if connect_fail_count >= 15 then--连接超过15次变为飞行模式
        net.switchFly(true)
        sys.wait(1000)
        net.switchFly(true)
        sys.wait(3000)
    end
    --清除计数器
    connect_fail_count = 0
    _G.tempfail = connect_fail_count
end

local function proc(onenet_mqttClient)--接收解析渴望值，while(1)只执行一次，接收和未接收都返回result
    local result, data
    while true do
        result, data = onenet_mqttClient:receive(60000, "APP_SOCKET_SEND_DATA")
        -- 接收到数据
        if result then
            log.warn("----------mqttInMsg.proc", data.topic, data.payload)
            if data.topic == "$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/desired/get/reply" then
                -- body
                onenet_get_desired_flag = true
                local tjsondata, result, errinfo = json.decode(data.payload)
                if result then
                    _G.temp_alarm = tjsondata["data"]["temp_alarm"]["value"]
                    _G.period = tjsondata["data"]["period"]["value"]
                    _G.tempU = tjsondata["data"]["tempU"]["value"]
                    _G.tempL = tjsondata["data"]["tempL"]["value"]
                end
                -- print(result)
                -- print(_G.temp_alarm)
                -- print(_G.period)
                -- print(_G.tempU)
                -- print(_G.tempL)
                log.warn("---------------------- 完成期望值获取获取 ----------------------")
                break
            end
            -- TODO：根据需求自行处理data.payload
        else
            break
        end
    end
    return result or data == "timeout" or data == "APP_SOCKET_SEND_DATA"
end
-- 订阅消息回复
local function onenet_subscribe()--发布"/thing/property/post/reply"成功1失败0
    -- mqtt订阅主题，根据自己需要修改
    local onenet_topic = {
        ["$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/post/reply"] = 0
    }
    if onenet_mqttClient:subscribe(onenet_topic) then
        return true
    else
        return false
    end
end
-- 订阅期望值回复
local function onenet_subscribe_desired_reply()---- 订阅期望值回复，发布期望值订阅主题，成功true，失败false
    -- mqtt订阅主题，根据自己需要修改
    local onenet_topic = {
        ["$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/desired/get/reply"] = 0
    }
    if onenet_mqttClient:subscribe(onenet_topic) then
        return true
    else
        return false
    end
end
-- 发布信息
function onenet_publish()
    -- mqtt发布主题根据自己需要修改
    if onenet_start_flag then--刷新onenet_start_time
        onenet_start_time = os.time()
        onenet_start_flag = false
    end
    onenet_last_time = os.time()
    log.warn(onenet_last_time)
    if _G.temp_alarm then--判断报警条件
        if _G.tempU < _G.temp then
            _G.tempUA = _G.tempUA + 1
        else
            _G.tempUA = 0
        end
        if _G.tempL > _G.temp then
            _G.tempLA = _G.tempLA + 1
        else
            _G.tempLA = 0
        end
        if _G.tempUA > 0 or _G.tempLA > 0 then
            print("发布报警信号")
            sys.publish("ALERT_ON")
        end
    end
    local jsondata2 = string.format(--格式发送JSON信息
        "{\"id\": \"1\",\"params\": {\"temp\": { \"value\": %.2f },\"humi\": { \"value\": %.2f},\"start_time\": { \"value\": %d},\"last_time\": { \"value\": %d},\"tempLA\": { \"value\": %d},\"tempUA\": { \"value\": %d},\"$OneNET_LBS\": {\"value\": [{ \"cid\": %d, \"lac\": %d, \"mcc\": 460, \"mnc\": %d, \"flag\": 10 }]}}}",
        _G.temp, _G.humi, onenet_start_time, onenet_last_time, _G.tempLA, _G.tempUA, tonumber(net.getCi(), 16),
        tonumber(net.getLac(), 16), tonumber(net.getMnc(), 16))
    log.warn(jsondata2)
    publish_success = onenet_mqttClient:publish("$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/post",--整合thing/property/post全部信息
        jsondata2, 0)
    log.warn("?????--------publish_success------", publish_success)
    while not publish_success do--开始发送信息
        onenet_mqttClient:disconnect()
        task_onenet_reconnect()
        log.warn("---------------------- onenet_连接成功 ----------------------")
        publish_success = onenet_mqttClient:publish("$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/post",--publish
            jsondata2, 0)
        sys.wait(500)
        log.warn("?????--------publish_success------", publish_success)
    end
end

-- 发布飞行模式时记录的信息
function onenet_flyrec_publish(temp, humi, time)
    log.warn("=============???", temp, humi, time)
    local jsondata2 = string.format(
        "{\"id\": \"1\",\"params\": {\"temp\": { \"value\": %.2f,\"time\":%d000 },\"humi\": { \"value\": %.2f,\"time\":%d000 }}}",
        temp, time, humi, time)
    log.warn(jsondata2)
    publish_success = onenet_mqttClient:publish("$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/post",
        jsondata2, 0)
    while not publish_success do
        onenet_mqttClient:disconnect()
        task_onenet_reconnect()
        log.warn("---------------------- onenet_连接成功 ----------------------")
        publish_success = onenet_mqttClient:publish("$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/post",
            jsondata2, 0)
        sys.wait(1000)
        log.warn("?????--------publish_success------", publish_success)
    end
end

-- 发布请求期望值信息
function onenet_publish_get_desired()
    local jsondata = "{\"id\":\"1\",\"params\":[\"temp_alarm\",\"tempL\",\"tempU\",\"period\"]} "
    onenet_mqttClient:publish("$sys/" .. ProductId .. "/" .. DeviceName .. "/thing/property/desired/get", jsondata, 0)
end
-- 2. 连接onenet
local function onenet_iot()
    while true do
        log.warn("---------------------- 进入onenet_iot ----------------------")
        if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then--没联网络软件重启，重启后的trace中会打印出此重启原因
            sys.restart("网络初始化失败!")
        end
        local clientid = DeviceName
        local username = ProductId
        local password = token

        -- 创建一个MQTT客户端
        onenet_mqttClient = mqtt.client(clientid, 100, username, password)
        -- 阻塞执行MQTT CONNECT动作，直至成功
        task_onenet_reconnect()
        log.warn("---------------------- onenet_连接成功 ----------------------")



        -------------------------------获取期望值----------------------------
        if onenet_subscribe_desired_reply() then--发布渴望请求信息，接收渴望值
                    log.warn("---------------------- desired_reply订阅成功 ----------------------")
                    -- 循环处理接收和发送的数据
                    while true do
                        onenet_publish_get_desired()
                        log.warn("---------------------- 完成期望值获取发送 ----------------------")
                        if not proc(onenet_mqttClient) then--没收到输出提示
                            log.error("mqttTask.mqttInMsg.proc error")
                            log.warn("---------------------- 收不到回应就报错 ----------------------")
                            break
                        end
                        if onenet_get_desired_flag then--得到了退出循环
                            break
                        end
                        log.warn("onenet_get_desired_flag:", onenet_get_desired_flag)
                    end
                else--没收到提示信息
                    log.warn("mqtt订阅失败")
                end
        
        

        -------------------------------发送数据----------------------------
        -- 订阅主题
        if onenet_subscribe() then--发布上传命令，更新记录状态，唤醒“test”,判断采集周期，按条件恢复飞行模式，采集温度，发布温度信息文件记录。
            log.warn("---------------------- 订阅成功 ----------------------")
            -- 循环处理接收和发送的数据
            while true do--更新记录状态，唤醒“test”,判断采集周期，按条件恢复飞行模式，采集温度，发布温度信息文件系统记录。
                log.warn("-##########- 死循环 --###############--")
                if not _G.REC_STATE then--不记录断开MQTT客户端
                    onenet_mqttClient:disconnect()
                    log.warn("**********打破内部记录循环**********")
                    break
                end
                pm.wake("TEST")
                sys.wait(100)
                last_wake_time = os.time()
                log.warn("last_wake_time", last_wake_time)
                log.warn("last_wake_time - last_sleep_time:", last_wake_time - last_sleep_time)
                
                if last_wake_time - last_sleep_time >= _G.period * 60 -15 then--唤醒时间超过设定周期,重连NQTT客户端，按条件恢复飞行模式，采集温度，发布温度信息，文件系统记录。
                    log.warn("暂时断开连接")
                    onenet_mqttClient:disconnect()
                    ---------------------- 飞行模式恢复网络 ----------------------
                    if not _G.FLY_STATE then--不是设定的飞行模式在这里恢复
                        log.warn("---------------------- 飞行恢复 ----------------------")
                        task_onenet_reconnect()
                        log.warn("onenet_连接成功 -")
                    end
                    task_ds18b20.ds18b20_get_recing()
                    sys.wait(500)
                    if not _G.FLY_STATE then--不是飞行模式：发布信息publish，io文件系统格式，补发漏传，记录到文件系统
                        log.warn("====================== connected ----------------------", onenet_mqttClient.connected)
                        onenet_publish()
                        --------------补传飞行记录----------------------------------------
                        log.warn("---------------------- 补传飞行记录 ----------------------")
                        if io.fileSize("fly_rec.json") > 10 then--文件系统拼装信息格式为sjon，并发布飞行模式产生的信息
                            local fileval = string.sub(io.readFile("fly_rec.json"), 0, -2) .. "}"
                            log.warn("=========获取的飞行内容 ", fileval)
                            local tjsondata, result, errinfo = json.decode(fileval)
                            log.warn("解析结果：", result)
                            if result then--发布飞行模式时记录的信息
                                for key, value in pairs(tjsondata) do--记录到文件系统
                                    onenet_flyrec_publish(value["temp"], value["humi"], value["time"])
                                    sys.wait(1000)
                                end
                            end
                            io.writeFile("fly_rec.json", "{", "w")
                        end
                    else--是飞行模式，格式文件系统格式并后端插入到文件系统
                        _G.flyrec_count = _G.flyrec_count + 1
                        io.writeFile("fly_rec.json", string.format(--格式文件系统格式并后端插入到文件系统
                            "\"rec%d\":{\"temp\":%.2f,\"humi\":%.2f,\"time\":%d},", _G.flyrec_count, _G.temp, _G.humi,
                            os.time()), "a")
                        log.warn("============现在的文件大小: ", io.fileSize("fly_rec.json"))
                    end
                    _G.REC_count = _G.REC_count + 1
                    log.warn("---------------------- 完成温度发送 ----------------------")
                    last_sleep_time = os.time()
                end
                log.warn("我休眠了")
                pm.sleep("TEST")
                log.warn("last_sleep_time", last_sleep_time)
                sys.wait(29000) -- 休眠时间
            end
        else--订阅失败重连MQTT服务器
            log.warn("mqtt订阅失败")
            task_onenet_reconnect()
            log.warn("onenet_连接成功 -")
        end 
        if not _G.REC_STATE then--不是记录状态退出
            log.warn("**********打破外部记录循环**********")
            break
        end
    end
end
-- ntp 自动对时
ntp.timeSync(1, function()
    log.warn("---------------ntp---------------done")
end)
-- 1. 初始化网络
local function iot()
    -- (1). 初始化网络
    if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then
        sys.restart("网络初始化失败!")
    end
    -- 低功耗
    ril.request("AT+CNETLIGHT=0\r\n")
    ril.request("AT+WAKETIM=1\r\n")
    sys.timerStart(function()
        ril.request("AT*RTIME=2\r\n")
    end, 1000)
    -- (2). 等到NTP同步
    while not ntp.isEnd() do
        sys.wait(1000)
    end
    log.warn("---------------------- 网络初始化已成功,进入onenet ----------------------")
    -- (3). 进入onenet连接
    onenet_iot()
end
-- 开始测量时触发
function onenet_get_recing()
    _G.tempUA = 0
    _G.tempLA = 0
    _G.REC_count = 0
    _G.flyrec_count = 0
    onenet_start_flag = true
    sys.taskInit(function()
        io.writeFile("fly_rec.json", "{", "w")
        iot()
    end)
end

sys.subscribe("REC_STATE_ON", onenet_get_recing)

