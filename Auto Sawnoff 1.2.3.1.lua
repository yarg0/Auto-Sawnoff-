script_name("{e6953e}AutoSawnoff {ffffff}by yargoff")
script_author('yargoff')

local ev = require('lib.samp.events')
local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local tag = '{c99732}[AutoSawnoff]{ffffff}'
local base_color = 0xFFe69f35

function json(filePath)
    local filePath = getWorkingDirectory()..'\\config\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
    local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\config') then
        createDirectory(getWorkingDirectory()..'\\config')
    end
    
    function class:Save(tbl)
        if tbl then
            local F = io.open(filePath, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end

    function class:Load(defaultTable)
        if not doesFileExist(filePath) then
            class:Save(defaultTable or {})
        end
        local F = io.open(filePath, 'r+')
        local TABLE = decodeJson(F:read() or {})
        F:close()
        for def_k, def_v in next, defaultTable do
            if TABLE[def_k] == nil then
                TABLE[def_k] = def_v
            end
        end
        return TABLE
    end

    return class
end

local settings = json('autoSawnoff.json'):Load({
    autoUse = false,
    autoUseJoinGame = false,
    minTime = 0,
    maxTime = 0,
    talitts = 0, -- время после захода на сервер (time after logging in to the server)
    slotObrez = '0',
    slotZamena = '0',
    typeInv = '0',
    reloadBug = 0,
})

local autoUse = imgui.new.bool(settings.autoUse)
local AUJoinGame = imgui.new.bool(settings.autoUseJoinGame)
local minTime = imgui.new.int(settings.minTime)
local maxTime = imgui.new.int(settings.maxTime)
local talitts = imgui.new.int(settings.talitts)

local sawnoff = false
local checkZamena = false
local nextExecutionTime = 0  -- Время следующего выполнения
local waitUntilTime = 0      -- Время, до которого нужно ждать из-за КД
local dontback = false

local renderWindow = imgui.new.bool(false)

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    theme()
end)

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 310, 260
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        if imgui.Begin('Auto Sawnoff [by yargoff]', renderWindow, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
            if settings.typeInv == '1' then
                imgui.Text(u8'Ваш аксессуар находится в инвентаре, слот - '..(settings.slotObrez))
            elseif settings.typeInv == '2' then
                imgui.Text(u8'Ваш аксессуар надет на вас!')
            else
                imgui.Text(u8'Аксессуар не найден...')
            end
            if imgui.Checkbox(u8('Автоиспользование'), autoUse) then
                settings.autoUse = autoUse[0]
                json('autoSawnoff.json'):Save(settings)
            end
            if imgui.Button(u8'Старт-проверка') then
                autoSawnoff()
            end
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Эта кнопка нужна если вы включили автоиспользование после захода в игру\nА до этого момента оно было выключено')
                imgui.EndTooltip()
            end
            imgui.Separator()
            if imgui.Checkbox(u8('Автоиспользование а/с при КАЖДОМ\nперезаходе на сервер'), AUJoinGame) then
                settings.autoUseJoinGame = AUJoinGame[0]
                json('autoSawnoff.json'):Save(settings)
            end
            imgui.Text(u8'Сработает через ' .. settings.talitts ..u8 ' сек. после захода на сервер')
            imgui.PushItemWidth(180)
            if imgui.SliderInt(u8'##1', talitts, 0, 15, '') then
                settings.talitts = talitts[0]
                json('autoSawnoff.json'):Save(settings)
            end
            imgui.Separator()
            if imgui.SliderInt(u8'Мин. время', minTime, 0, 10) then
                settings.minTime = minTime[0]
                json('autoSawnoff.json'):Save(settings)
            end
            if imgui.SliderInt(u8'Макс. время', maxTime, 0, 20) then
                settings.maxTime = maxTime[0]
                json('autoSawnoff.json'):Save(settings)
            end
            imgui.PopItemWidth()
            if imgui.Button(u8'Reload скрипт') then
                settings.reloadBug = 1
                json('autoSawnoff.json'):Save(settings)
                thisScript():reload()
            end
        imgui.End()
    end
end)

local inventoryRequested = false
function getRandomMinutes(min, max)
    min = tonumber(min) or 0
    max = tonumber(max) or 0

    if min > max then
        min, max = max, min
    end

    return math.random(min, max)
end
function main()
    while not isSampAvailable() do wait(0) end
    sampAddChatMessage(tag..' Скрипт загружен! Автор: {7ce653}yargoff', base_color)

    sampRegisterChatCommand('asawnoff', function()
        renderWindow[0] = not renderWindow[0]
    end)

    sampRegisterChatCommand('usesawnoff', autoSawnoff)

    sampRegisterChatCommand('rsawnoff', function ()
        settings.reloadBug = 1
        json('autoSawnoff.json'):Save(settings)
        thisScript():reload()
    end)

    if settings.reloadBug == 1 then
        sampSendChat('/invent')
        sendCEF('inventoryClose')
        settings.reloadBug = 0
        json('autoSawnoff.json'):Save(settings)
    end
    
    math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1,6)))
    while true do
        wait(0)

        -- Проверка и выполнение периодического запуска, если включено
        if settings.autoUse then
            if sampIsLocalPlayerSpawned() then
                local currentTime = os.time()

                -- Если есть ожидание из-за КД, проверяем, прошло ли оно
                if waitUntilTime > 0 and currentTime >= waitUntilTime then
                    waitUntilTime = 0
                    sampAddChatMessage(tag..' Ожидание завершено, собираю...', base_color)
                    autoSawnoff()
                end

                -- Проверка: если время пришло (после КД), выполняем задачу
                if nextExecutionTime > 0 and currentTime >= nextExecutionTime then
                    nextExecutionTime = 0
                    autoSawnoff()
                    sampAddChatMessage(tag..' Автозапуск выполнен после завершения КД!', base_color)
                end
            else
                sawnoff = false
                inventoryRequested = false
            end
        end

    end
end

function ev.onServerMessage(color, text)
    -- Детект использования запаса обрезов — начинаем отсчёт КД
    if text:match('%[Информация%] %{ffffff%}Вы использовали запас обрезов.') then
        if settings.autoUse then
            sampAddChatMessage(tag..' Обнаружено использование запаса обрезов. Устанавливаю КД...', base_color)

            -- Генерируем случайную задержку (в минутах) на основе настроек
            local randomDelayMinutes = getRandomMinutes(settings.minTime, settings.maxTime)
            local currentTime = os.time()
            -- КД = 1 час + случайное время (в минутах)
            nextExecutionTime = currentTime + (3600 + randomDelayMinutes * 60)

            sampAddChatMessage(tag..' КД установлен: 1 час + ' .. randomDelayMinutes .. ' минут. Следующий запуск через '
                .. math.floor((nextExecutionTime - currentTime) / 60) .. ' минут', base_color)
        end
    end

    -- Обработка КД с временем ожидания
    local lasttimeStr = text:match('%[Ошибка%] %{ffffff%}Для использования этого аксессуара должно пройти ещё (%d+) минут!')
    if lasttimeStr then
        if settings.autoUse then
            local lasttime = tonumber(lasttimeStr)  -- преобразуем строку в число
            if lasttime then
                local currentTime = os.time()
                waitUntilTime = currentTime + (lasttime * 60)  -- устанавливаем время, до которого ждём
                sampAddChatMessage(tag..' Нужно подождать ' .. lasttime .. ' минут. Откладываю выполнение.', base_color)
                -- Сбрасываем запланированное выполнение, чтобы не конфликтовало
                nextExecutionTime = 0
            end
        end
    end

    if text:match('{DFCFCF}%[Подсказка%] {DC4747}На сервере есть инвентарь, используйте клавишу Y для работы с ним.') then
        if settings.autoUse and settings.autoUseJoinGame then
            lua_thread.create(function ()
                wait((settings.talitts * 1000))
                autoSawnoff()
            end)
        end
    end
end

function autoSawnoff()
    sawnoff = true
    emul_num({220, 0, 27, 64})
    sampSendChat('/invent')
end

addEventHandler('onReceivePacket', function (id, bs)
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)

            local typeInv, slot = str:match('type":(%d+),"items":%[{"slot":(%d+),"available":1,"blackout":0,"item":5822')
            if typeInv and slot then
                settings.typeInv = typeInv
                settings.slotObrez = slot
                local status, code = json('autoSawnoff.json'):Save(settings)
            end

            if sawnoff then
                local isCorrectEvent = str:find('event%.inventory%.playerInventory')
                local hasDontbackPattern = str:find('"type":1,"items":%[{"slot":%d+,"available":1,"blackout":0}')

                if isCorrectEvent and hasDontbackPattern then
                    dontback = true
                    checkZamena = false
                    sawnoff = false
                    return false
                else
                    dontback = false

                    local hasSlot3Pattern = str:find('"type":2,"items":%[{"slot":3,"available":1,"blackout":0,"item":5822')
                    local hasSlot9Pattern = str:find('"type":2,"items":%[{"slot":9,"available":1,"blackout":0,"item":5822')

                    if isCorrectEvent and (hasSlot3Pattern or hasSlot9Pattern) then
                        checkZamena = true
                    end

                    if checkZamena then
                        local zamena, id = str:match('"type":1,"items":%[{"slot":(%d+),"available":1,"blackout":0,"item":(%d*)')
                        if zamena and id then
                            checkZamena = false
                            settings.slotZamena = zamena
                            local status, code = json('autoSawnoff.json'):Save(settings)
                        end
                    end
                end
            end

            if dontback then
                return false
            end

            if str:find('event.setActiveView') and str:find('Inventory') then
                if sawnoff then
                    if inventoryRequested then return false end

                    if isCharInAnyCar(PLAYER_PED) then
                        sendCEF('requestShowingInventory|27')
                        inventoryRequested = true
                    end

                    lua_thread.create(function ()
                        wait(300)
                        if settings.typeInv == '2' and (settings.slotObrez == '3' or settings.slotObrez == '9') then
                            sendCEF('clickOnButton|{"type": 2,"slot": ' .. settings.slotObrez .. ', "action": 1}')
                        else
                            sendCEF('inventory.moveItemForce|{"slot": ' .. settings.slotObrez .. ', "type": 1, "amount": 1}')
                            wait(300)
                            sendCEF('clickOnButton|{"type": 2,"slot": ' .. settings.slotObrez .. ', "action": 1}')

                            if not dontback then
                                sendCEF('inventory.moveItem|{"from":{"slot":' .. settings.slotObrez .. ',"type":2,"amount":1},"to":{"slot":' .. settings.slotZamena .. ',"type":1}}')
                            end
                        end

                        sendCEF('inventoryClose')
                        sawnoff = false
                        inventoryRequested = false
                    end)
                    return false
                end
            end
        end
    end
end)

sendCEF = function(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function emul_num(array)
    local bs = raknetNewBitStream()
    for i, byte in ipairs(array) do
        raknetBitStreamWriteInt8(bs, byte)
    end
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function theme() -- Стиль mimgui
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.ChildBg]                = ImVec4(0.12, 0.12, 0.12, 1.00);
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
    colors[clr.Border]                 = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
    colors[clr.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
    colors[clr.TitleBg]                = ImVec4(0.14, 0.14, 0.14, 0.81);
    colors[clr.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[clr.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
    colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.Button]                 = ImVec4(0.76, 0.16, 0.16, 1.00);
    colors[clr.ButtonHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
    colors[clr.Tab]                    = ImVec4(0.09, 0.09, 0.09, 1.00);
    colors[clr.TabHovered]             = ImVec4(0.58, 0.23, 0.23, 1.00);
    colors[clr.TabActive]              = ImVec4(0.76, 0.16, 0.16, 1.00);
    colors[clr.Button]                 = ImVec4(0.40, 0.39, 0.38, 0.16);
    colors[clr.ButtonHovered]          = ImVec4(0.40, 0.39, 0.38, 0.39);
    colors[clr.ButtonActive]           = ImVec4(0.40, 0.39, 0.38, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
    colors[clr.ModalWindowDimBg]   = ImVec4(0.26, 0.26, 0.26, 0.60);
end