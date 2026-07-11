script_name("{e6953e}AutoSawnoff {ffffff}by yargoff")
script_version("1.5.5")
script_author('yargoff')

local ev = require('samp.events')
local imgui = require 'mimgui'
local ffi = require('ffi')
local encoding = require('encoding')
local faicons = require('fAwesome6')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local colortag = '{e69f35}'
local tag = colortag .. '[AutoSawnoff]{ffffff}'
local smile = ':gun:'
local base_color = 0xFFe69f35

function json(filePath)
    local configDir = getWorkingDirectory() .. '\\config'

    filePath = configDir .. '\\' .. (filePath:match('%.json$') and filePath or filePath .. '.json')

    local class = {}

    if not doesDirectoryExist(configDir) then
        createDirectory(configDir)
    end

    function class:Save(tbl)
        tbl = tbl or {}
        local file = io.open(filePath, 'w')
        if not file then
            return false, 'Не удалось открыть файл для записи'
        end
        local encoded = encodeJson(tbl)
        if not encoded then
            file:close()
            return false, 'Ошибка кодирования JSON'
        end
        file:write(encoded)
        file:close()

        return true, 'ok'
    end

    function class:Load(defaultTable)
        defaultTable = defaultTable or {}
        if not doesFileExist(filePath) then
            self:Save(defaultTable)
            return defaultTable
        end
        local file = io.open(filePath, 'r')
        if not file then
            return defaultTable
        end
        local content = file:read('*a')
        file:close()
        local data = {}
        if content and content ~= '' then
            local ok, result = pcall(decodeJson, content)

            if ok and type(result) == 'table' then
                data = result
            else
                print('[JSON] Ошибка чтения файла: ' .. tostring(filePath))
                print('[JSON] Файл будет восстановлен.')

                data = defaultTable
                self:Save(data)
            end
        else
            data = defaultTable
            self:Save(data)
        end
        for k, v in pairs(defaultTable) do
            if data[k] == nil then
                data[k] = v
            end
        end

        return data
    end

    return class
end
local name_file = 'AutoSawnoff.json'
local settings = json(name_file):Load({
    autoUse = false,
    autoUseJoinGame = false,
    SpecificAccessory = false,      -- Конкретный аксессуар
    JSmetod = false,
    checkobres = false,
    STRUTDTA = false,               -- Установка рандом времени использования при корректировке
    IDobres = 5822,
    IDsecondacs = 0,
    minTime = 0,
    maxTime = 0,
    minSeconds = 0,
    maxSeconds = 0,
    talitts = 0,                    -- Время после захода на сервер
    slotObrez = -1,
    slotZamena = -1,
    typeInv = -1,
    reloadBug = 0,
    hidemessage = false,
    debugmessage = false,
    seekinv = false,
    invset = 1, useset = 1,
    date = '', goodsbor = 0, failsbor = 0
})
local function save_settings()
    json(name_file):Save(settings)
end
local function message(text, color)
    if settings.hidemessage then return end

    if not text or text == ' ' then return end
    if not color or color == ' ' then color = base_color end

    if smile then
        sampAddChatMessage(smile .. ' ' .. tag .. ' ' .. text, color)
    else
        sampAddChatMessage(tag .. ' ' .. text, color)
    end
end
local function test_message(text, color)
    if not settings.debugmessage then return end

    if not text or text == '' then
        return
    end

    if not color or color == '' then
        base_color = base_color
    else
        base_color = color
    end

    if smile then
        sampAddChatMessage(smile .. ' {ff0000}[DEBUG MESSAGE] ' .. tag .. ' ' .. text, base_color)
    else
        sampAddChatMessage('{ff0000}[DEBUG MESSAGE] ' .. tag .. ' ' .. text, base_color)
    end
end

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(u8(text)).x/2)
    imgui.Text(u8(text))
end
function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4
    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end
    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end
    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end

local autoUse = imgui.new.bool(settings.autoUse)
local AUJoinGame = imgui.new.bool(settings.autoUseJoinGame)
local checkobres = imgui.new.bool(settings.checkobres)
local STRUTDTA = imgui.new.bool(settings.STRUTDTA)
local SpecificAccessory = imgui.new.bool(settings.SpecificAccessory)
local JSmetod = imgui.new.bool(settings.JSmetod)
local hidemessage = imgui.new.bool(settings.hidemessage)
local debugmessage = imgui.new.bool(settings.debugmessage)
local seekinv = imgui.new.bool(settings.seekinv)
local useset = imgui.new.int(settings.useset)
local minTime = imgui.new.int(settings.minTime)
local maxTime = imgui.new.int(settings.maxTime)
local minSeconds = imgui.new.int(settings.minSeconds)
local maxSeconds = imgui.new.int(settings.maxSeconds)
local talitts = imgui.new.int(settings.talitts)
local idobrez = imgui.new.char[256](settings.IDobres)
local idacs = imgui.new.char[256]()

local inventoryRequested = false

local STATE_IDLE = 0
local STATE_OPENING = 1
local STATE_EQUIPPING = 2
local STATE_CLOSING = 3
local currentState = STATE_IDLE
local busy = false

local actionActive = false
local actionId = 0
local sawnoff = false
local nextExecutionTime = 0     -- Время следующего выполнения
local waitUntilTime = 0         -- Время, до которого нужно ждать из-за КД
local NextUseTime = nil

local renderWindow = imgui.new.bool(false)

local legacs = {
    ['Обрез'] = 5822,
    ['Бехелит Черного мечника'] = 9214,
    ['Наплечник Друида'] = 9235,
    ['Сердце Лича'] = 9420,
    ['Ожерелье ведьмы'] = 9483,
    ['Ожерелье медведя'] = 9581,
    ['Ожерелье Фрирен'] = 9605,
    ['Полицейский пояс из боеприпас'] = 9824
}

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    theme()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
end)

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 315, 375
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        if imgui.Begin(faicons('gun') .. ' Auto Sawnoff ' .. faicons('gun'), renderWindow, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then

            if imgui.BeginTabBar('Tabs') then -- задаём начало вкладок
                if imgui.BeginTabItem(u8'Меню') then -- первая вкладка
                    if imgui.BeginChild('Name', imgui.ImVec2(315, 66), true) then
                        if NextUseTime and NextUseTime > os.time() then
                            imgui.CenterText(('Таймер до следующего сбора'))
                            imgui.CenterText(('Следующий автосбор: ' .. os.date('%H:%M:%S', NextUseTime)))
                            imgui.CenterText(('Осталось: ' .. formatTime(NextUseTime - os.time())))
                        else
                            imgui.CenterText(('Таймер до следующего сбора'))
                            imgui.CenterText(('А/С ещё не использовался'))
                        end
                        imgui.EndChild() -- обязательно следите за тем, чтобы каждый чайлд был закрыт
                    end
                    if imgui.Checkbox(faicons('hand') .. u8(' Автосбор обрезов'), autoUse) then
                        settings.autoUse = autoUse[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Автоматический сбор обрезов после окончания КД на использование')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(faicons('timer') .. u8(' Корректировка времени'), AUJoinGame) then
                        settings.autoUseJoinGame = AUJoinGame[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Скрипт будет при каждом заходе на сервер использовать а/с "Обрез"')
                        imgui.Text(u8'Это нужно, чтобы корректировать время следующего\nиспользования а/с без необходимости проводить старт-проверку')
                        imgui.EndTooltip()
                    end
                    if imgui.Button(faicons('circle_play') .. u8' Старт-проверка') then
                        autoSawnoff()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Нажмите на эту кнопку после включения "Автосбор обрезов"')
                        imgui.Text(u8'или просто используйте а/с в инвентаре')
                        imgui.EndTooltip()
                    end
                    imgui.EndTabItem() -- конец вкладки
                end
                if imgui.BeginTabItem(u8'Методы работы') then -- первая вкладка
                    if imgui.Checkbox(faicons('newspaper') .. u8(' Автосбор обрезов через JS'), JSmetod) then
                        settings.JSmetod = JSmetod[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Скрипт будет использовать а/с "Обрез" через JavaScript-метод, а не Lua-метод')
                        imgui.Text(u8'Но учтите, что это дольше чем Lua и работает не через отправку пакетов')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(faicons('pen_circle') .. u8' Вписать ID а/с "Обрез" самостоятельно', checkobres) then
                        settings.checkobres = checkobres[0]
                        save_settings()
                    end
                    if settings.IDobres and settings.IDobres ~= '' then
                        imgui.Text(faicons('cash_register') .. u8(' ID а/с "Обрез" - ' .. settings.IDobres))
                    else
                        imgui.Text(faicons('cash_register') .. u8(' ID а/с "Обрез" - отсутствует'))
                    end
                    if settings.checkobres then
                        imgui.PushItemWidth(150)
                        if imgui.InputText(u8"##ID а/с обреза", idobrez, 256) then
                            local obres = u8:decode(ffi.string(idobrez))
                            if not obres or obres == '' then
                                settings.IDobres = 5822
                                save_settings()
                            else
                                settings.IDobres = tonumber(obres)
                                save_settings()
                            end
                        end
                        imgui.PushItemWidth(0)
                    else
                        if imgui.CollapsingHeader(u8('Аксессуары из разных сетов')) then

                            for i, v in pairs(legacs) do

                                if imgui.Button(u8(i)) then
                                    settings.IDobres = v
                                    save_settings()
                                end

                            end
                        end
                    end
                    imgui.Separator()
                    if imgui.Checkbox(faicons('bolt') .. u8(' Замена а/с "Обрез" на иной конкретный а/с'), SpecificAccessory) then
                        settings.SpecificAccessory = SpecificAccessory[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'После использования обреза в 4 слот будет возвращен а/с ID которого Вы впишете')
                        imgui.EndTooltip()
                    end
                    if settings.SpecificAccessory then
                        if settings.IDsecondacs and settings.IDsecondacs ~= '' then
                            imgui.Text(faicons('cash_register') .. u8(' ID внесенного вами а/с - ' .. settings.IDsecondacs))
                        else
                            imgui.Text(faicons('cash_register') .. u8(' ID внесенного вами а/с - отсутствует'))
                        end
                        imgui.PushItemWidth(150)
                        if imgui.InputText(u8"##ID постоянного а/с на 4 слоте", idacs, 256) then
                            local arg = u8:decode(ffi.string(idacs))
                            settings.IDsecondacs = tonumber(arg)
                            save_settings()
                        end
                        imgui.PushItemWidth(0)
                    end
                    imgui.EndTabItem() -- конец вкладки
                end
                if imgui.BeginTabItem(u8'Статус') then -- первая вкладка
                    imgui.Text(faicons('users') .. u8(' Корректных автосборов - ' .. settings.goodsbor .. ' | Не удалось собрать - ' .. settings.failsbor))
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Данная статистика за текущие сутки')
                        imgui.EndTooltip()
                    end

                    local invset = tonumber(settings.invset)
                    local useset = tonumber(settings.useset)
                    if invset ~= useset then
                        imgui.Text((faicons('ban') .. u8' Не смог определить каким сетом из 3-ёх вы пользуетесь\n(Наведитесь на сообщение для большей информации)'))
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.Text(u8'Как исправить данную ошибку?')
                            imgui.Text(u8'1. Обновите информацию какой сет выбран сейчас у вас в инвентаре')
                            imgui.Text(u8'2. Укажите в настройках скрипта каким сетом из 3-ёх вы пользуетесь')
                            imgui.Text(u8'3. Проверьте, чтобы данные совпадали!')
                            imgui.Text(u8('Сейчас в инвентаре выбран сет - №' .. settings.invset.. ' | Сет в настройках - №' .. settings.useset))
                            imgui.Text(u8'Если все будет верно, то будет написано, каким сетом вы пользуетесь сейчас')
                            imgui.EndTooltip()
                        end
                    else
                        imgui.Text(faicons('traffic_light_stop') .. u8' Вы пользуетесь сетом №' .. invset)
                    end

                    if settings.typeInv == 1 then
                        local t = tostring(settings.slotObrez)
                        imgui.Text(faicons('sitemap') .. u8' Ваш аксессуар находится в инвентаре, слот - '..(t))
                    elseif settings.typeInv == 2 then
                        imgui.Text(faicons('sitemap') .. u8' Ваш аксессуар надет на вас!')
                    else
                        imgui.Text(faicons('ban') .. u8' Аксессуар не найден...')
                    end

                    imgui.EndTabItem() -- конец вкладки
                end
                if imgui.BeginTabItem(u8'Настройки') then -- вторая вкладка
                    if imgui.Checkbox(u8('Тихий режим'), hidemessage) then
                        settings.hidemessage = hidemessage[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Убирает ВСЕ сообщения от скрипта для "тихого" сбора.')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8('Скрывать инвентарь при использовании'), seekinv) then
                        settings.seekinv = seekinv[0]
                        save_settings()
                    end
                    if imgui.Checkbox(u8('DEBUG сообщения'), debugmessage) then
                        settings.debugmessage = debugmessage[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Выводит СИСТЕМНЫЕ сообщения СКРИПТА в чат!')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8('Рандом время при корректировке использования'), STRUTDTA) then
                        settings.STRUTDTA = STRUTDTA[0]
                        save_settings()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Устанавливает рандом время использования а/с "Обрез", если включен пункт "Корректировка времени"')
                        imgui.EndTooltip()
                    end
                    imgui.Separator()
                    imgui.Text(u8'Корректировка времени сработает через ' .. settings.talitts ..u8 ' сек.\nпосле захода на сервер')
                    imgui.PushItemWidth(180)
                    if imgui.SliderInt(u8'##1', talitts, 1, 30, '') then
                        settings.talitts = talitts[0]
                        save_settings()
                    end
                    imgui.Separator()
                    if imgui.SliderInt(u8'Номер используемого сета', useset, 1, 3) then
                        settings.useset = useset[0]
                        save_settings()
                    end
                    imgui.Separator()
                    imgui.Text(faicons('timer') .. u8(' Настройки рандомизации времени'))
                    if imgui.SliderInt(u8'Мин. минут', minTime, 0, 15) then
                        settings.minTime = minTime[0]
                        save_settings()
                    end
                    if imgui.SliderInt(u8'Макс. минут', maxTime, 0, 30) then
                        settings.maxTime = maxTime[0]
                        save_settings()
                    end
                    if imgui.SliderInt(u8'Мин. секунд', minSeconds, 0, 59) then
                        settings.minSeconds = minSeconds[0]
                        save_settings()
                    end
                    if imgui.SliderInt(u8'Макс. секунд', maxSeconds, 0, 59) then
                        settings.maxSeconds = maxSeconds[0]
                        save_settings()
                    end
                    imgui.PopItemWidth()
                    imgui.Separator()
                    if imgui.Button(faicons('arrow_rotate_right') .. u8' Перезагрузить скрипт') then
                        settings.reloadBug = 1
                        save_settings()
                        thisScript():reload()
                    end
                    imgui.EndTabItem() -- конец вкладки
                end
                imgui.EndTabBar() -- конец всех вкладок
            end
        imgui.End()
    end
end)

local function setState(state)
    currentState = state

    test_message(
        'STATE -> ' .. tostring(state),
        0x00ff00
    )
end
local function resetActionState()
    busy = false
    sawnoff = false
    inventoryRequested = false
    actionActive = false

    setState(STATE_IDLE)
end

local function validateAction(id)
    return id == actionId
        and currentState ~= STATE_IDLE
end

local function findItemById(str, searchItemId)
    local typeInv = tonumber(str:match('"type":(%d+)'))
    if not typeInv then
        return nil
    end

    for obj in str:gmatch("{[^{}]+}") do
        local slot = tonumber(obj:match('"slot":(%d+)'))
        local item = tonumber(obj:match('"item":(%d+)'))

        if item == searchItemId then
            return typeInv, slot
        end
    end

    return nil
end

function formatTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60

    return string.format('%02d:%02d:%02d', h, m, s)
end

function getRandomValue(min, max)
    min = tonumber(min) or 0
    max = tonumber(max) or 0

    if min > max then
        min, max = max, min
    end

    return math.random(min, max)
end
function getRandomMinutes(min, max)
    return getRandomValue(min, max)
end
function getRandomSeconds(min, max)
    return getRandomValue(min, max)
end

function evalanon(code)
    evalcef(("(() => {%s})()"):format(code))
end

function evalcef(code, encoded)
    encoded = encoded or 0
    local bs = raknetNewBitStream()

    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #code)
    raknetBitStreamWriteInt8(bs, encoded)
    raknetBitStreamWriteString(bs, code)

    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

function main()
    while not isSampAvailable() do wait(100) end

    message('Скрипт загружен!')

    sampRegisterChatCommand('asawnoff', function()
        renderWindow[0] = not renderWindow[0]
    end)

    sampRegisterChatCommand('usesawnoff', autoSawnoff)

    sampRegisterChatCommand('rsawnoff', function ()
        settings.reloadBug = 1
        save_settings()
        thisScript():reload()
    end)

    if settings.reloadBug == 1 then
        sampSendChat('/invent')
        sendCEF('inventoryClose')

        settings.reloadBug = 0
        save_settings()
    end

    math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1,6)))
    while true do
        wait(200)

        if not sampIsLocalPlayerSpawned() then
            if sawnoff then
                message('Выключаю запущенный процесс автосбора обрезов, т.к. персонаж не подключен к серверу')
                resetActionState()
            end
        end

        if settings.autoUse then
            if sampIsLocalPlayerSpawned() then
                local currentTime = os.time()
                if waitUntilTime > 0 then

                    local remain = waitUntilTime - currentTime
                    if remain <= 0 then
                        waitUntilTime = 0
                        message('Ожидание завершено, собираю...')
                        autoSawnoff()
                    end
                end

                if nextExecutionTime > 0 then
                    local remain = nextExecutionTime - currentTime

                    if remain <= 0 then
                        nextExecutionTime = 0
                        autoSawnoff()
                        message('Автозапуск выполнен после завершения КД!')
                    end
                end

            else
                sawnoff = false
                inventoryRequested = false
            end
        end

        local date = os.date('%d.%m.%Y')
        if settings.date ~= date then
            settings.date = date
            settings.goodsbor = 0
            settings.failsbor = 0
            save_settings()
        end
    end
end

function ev.onServerMessage(color, text)

    if text:match('%[Информация%] {ffffff}Вы использовали запас обрезов.') then

        if settings.autoUse then
            message('Обнаружено использование запаса обрезов. Устанавливаю КД...')

            local currentTime = os.time()

            local randomDelayMinutes = getRandomMinutes(settings.minTime, settings.maxTime)
            local randomDelaySeconds = getRandomSeconds(settings.minSeconds or 0, settings.maxSeconds or 0)

            local totalDelay = 3600 + (randomDelayMinutes * 60) + randomDelaySeconds
            nextExecutionTime = currentTime + totalDelay

             -- Сохраняем timestamp
            NextUseTime = nextExecutionTime

            -- Время следующего использования
            local nextUseStr = os.date('%H:%M:%S', nextExecutionTime)

            message(
                string.format(
                    'КД установлен: +%d мин. +%d сек. | Осталось: %s | Следующее использование: %s',
                    randomDelayMinutes,
                    randomDelaySeconds,
                    formatTime(totalDelay),
                    nextUseStr
                ), base_color)
        end

        settings.goodsbor = settings.goodsbor + 1
        save_settings()
    end

    local lasttimeStr = text:match('%[Ошибка%] {ffffff}Для использования этого аксессуара должно пройти ещё (%d+) минут!')
    if lasttimeStr then
        if settings.autoUse and settings.STRUTDTA then
            local lasttime = tonumber(lasttimeStr)
            if lasttime then

                local currentTime = os.time()

                local randomMinutes = getRandomMinutes(settings.minTime, settings.maxTime)
                local randomSeconds = getRandomSeconds(settings.minSeconds or 0, settings.maxSeconds or 0)

                local totalSeconds = (lasttime * 60) + (randomMinutes * 60) + randomSeconds

                waitUntilTime = currentTime + totalSeconds
                NextUseTime = waitUntilTime

                -- Время следующего использования
                local nextUseStr = os.date('%H:%M:%S', waitUntilTime)

                message(string.format(
                    'Нужно подождать: %s | +%d мин +%d сек | Следующее использование: %s',
                    formatTime(totalSeconds),
                    randomMinutes,
                    randomSeconds,
                    nextUseStr
                ), 0xFFe69f35)

                -- Сбрасываем обычный автозапуск
                nextExecutionTime = 0
            end
        elseif settings.autoUse then
            local lasttime = tonumber(lasttimeStr)
            if lasttime then
                local currentTime = os.time()

                waitUntilTime = currentTime + (lasttime * 60)
                NextUseTime = waitUntilTime

                -- Время следующего использования
                local nextUseStr = os.date('%H:%M:%S', waitUntilTime)

                message((
                    'Нужно подождать: ' ..
                    formatTime(lasttime * 60) ..
                    ' | Следующее использование: ' ..
                    nextUseStr
                ), 0xFFe69f35)

                nextExecutionTime = 0
            end
        end
    end

    if text:match('{DFCFCF}%[Подсказка%] {DC4747}На сервере есть инвентарь, используйте клавишу Y для работы с ним.') then
        if settings.autoUse and settings.autoUseJoinGame then
            lua_thread.create(function ()
                wait(settings.talitts * 1000)
                autoSawnoff()
            end)
        end
    end

    if text:find("bits %(%d+%) doesn%'t include button_type %(%d+%)") then
        if sawnoff then
            message('Упс... Слот не смог определиться.')
            settings.failsbor = settings.failsbor + 1
            save_settings()

            resetActionState()
            return
        end
    end

    if text:match('%[Ошибка%] {ffffff}Запрещено использовать аксессуары в зоне проведения мероприятия "Зловещая экспедиция".') then
        resetActionState()
        return
    end
end

function autoSawnoff()
    if settings.invset ~= settings.useset then
        message('У вас не совпадает тип действующего инвентаря с типом указанным в настройках')
        return
    end

    if settings.JSmetod then
        if not settings.IDobres or settings.IDobres == '' or settings.IDobres == ' ' then
            message('Не вписан ID а/с "Обрез" (или лег. акса с его переносом). Отменяю запуск...')
            return
        end
        if not settings.SpecificAccessory then
            message('Чтобы использовать этот способ включите замену а/с "Обрез" (или лег. акса с его переносом) на конкретный а/с. Отменяю запуск...')
            return
        end
        if not settings.IDsecondacs or settings.IDsecondacs == '' or settings.IDsecondacs == ' ' then
            message('Не вписан ID постоянного а/с, отменяю запуск...')
            return
        end
        lua_thread.create(function ()
            emul_num({220, 0, 27, 64})
            evalanon([[ 
                (function() {

                    const id = 'force_hide_inv';

                    if (!document.getElementById(id)) {

                        const style = document.createElement('style');
                        style.id = id;

                        style.innerHTML = `
                            .inventory,
                            .inventory.b,
                            [class*="inventory"] {
                                opacity: 0 !important;
                                visibility: hidden !important;
                            }
                        `;

                        document.head.appendChild(style);
                    }

                })();
            ]])
            wait(100)
            sampSendChat('/invent')
            wait(1200)

            -- используем обрез ID 5822
            local OBREZ = settings.IDobres
            local ACC = settings.IDsecondacs

            evalanon(string.format([[
                (async function() {

                    const OBREZ = %d;
                    const ACC = %d;


                    function findItem(itemId) {
                        return document.querySelector(`img[alt="ID:${itemId}"]`);
                    }

                    async function clickItem(itemId, buttonText) {

                        const img = findItem(itemId);
                        if (!img) return false;

                        const item = img.closest('.inventory-item');
                        if (!item) return false;

                        item.dispatchEvent(new MouseEvent("contextmenu", {
                            bubbles: true,
                            button: 2
                        }));

                        return await new Promise(res => {

                            let i = 0;

                            const t = setInterval(() => {

                                const btn = Array.from(
                                    document.querySelectorAll('.inventory-button__text')
                                ).find(b => b.textContent.includes(buttonText));

                                if (btn) {
                                    btn.click();
                                    clearInterval(t);
                                    setTimeout(() => res(true), 700);
                                }

                                if (++i > 25) {
                                    clearInterval(t);
                                    res(false);
                                }

                            }, 100);

                        });
                    }

                    try {

                        // =====================
                        // АКС снять
                        // =====================

                        const accImg = findItem(ACC);
                        if (accImg) {
                            await clickItem(ACC, "Снять");
                            await new Promise(r => setTimeout(r, 800));
                        }

                        // =====================
                        // ОБРЕЗ цикл
                        // =====================

                        await clickItem(OBREZ, "Надеть");
                        await new Promise(r => setTimeout(r, 1200));

                        await clickItem(OBREZ, "Использовать");
                        await new Promise(r => setTimeout(r, 1500));

                        await clickItem(OBREZ, "Снять");
                        await new Promise(r => setTimeout(r, 1200));

                        // =====================
                        // АКС вернуть
                        // =====================

                        const accAgain = findItem(ACC);
                        if (accAgain) {
                            await clickItem(ACC, "Надеть");
                        }

                        // =====================
                        // Закрыть инвент
                        // =====================

                        try {
                            if (typeof inventoryClose === 'function') inventoryClose();
                        } catch (e) {}

                        const closeBtn = document.querySelector('.ui-close');
                        if (closeBtn) closeBtn.click();

                        document.dispatchEvent(new KeyboardEvent('keydown', {
                            key: 'Escape',
                            code: 'Escape',
                            keyCode: 27,
                            which: 27,
                            bubbles: true
                        }));

                    }

                })();
                ]], OBREZ, ACC))
            wait(12000)
            evalanon([[
                (function() {

                    const style = document.getElementById('force_hide_inv');

                    if (style) {
                        style.remove();
                    }

                })();
            ]])
        end)
    else
        sawnoff = true
        emul_num({220, 0, 27, 64})
        sampSendChat('/invent')
    end
end

addEventHandler('onReceivePacket', function (id, bs)
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)

            local inv = str:match('event.inventory.playerInventory')
            if inv then
                local page = str:match('accsPages":{"total":3,"page":(%d+)')
                if page then
                    local tpage = tonumber(page)
                    settings.invset = tpage
                    save_settings()
                end
            end

            local type, slot = findItemById(str, settings.IDobres)
            if type and slot then
                settings.typeInv = type
                settings.slotObrez = slot

                test_message(('A/C обрез найден | type: %d | slot: %d'):format(type, slot), 0xff0000)
                save_settings()
            end

            if sawnoff then
                if settings.SpecificAccessory then
                    local type, slotik = findItemById(str, settings.IDsecondacs)
                    if slotik then
                        test_message('Тип сбора обреза с исп-ем конкретного ID а/с')
                        test_message('Слот замены найден - ' .. tostring(slotik), 0x4366e6)
                        test_message('ID а/с: ' .. settings.IDsecondacs .. ' | Слот: ' .. slotik, 0xff0000)
                        settings.slotZamena = slotik
                        save_settings()
                    end
                else
                    local slot = str:match('"slot":(%d+)')
                    if slot then
                        test_message('Тип сбора обреза без конкретного ID а/с')
                        test_message('ID а/с который был на 4 слоте: ' .. settings.IDsecondacs .. ' | Слот в который попал: ' .. slot, 0xff0000)
                        settings.slotZamena = tonumber(slot)
                        save_settings()
                    end
                end
            end

            if str:find('event.setActiveView') and str:find('Inventory') then
                if sawnoff then
                    if actionActive then return end
                    if busy then return end

                    busy = true
                    actionActive = true

                    actionId = actionId + 1

                    local currentAction = actionId
                    setState(STATE_OPENING)
                    if inventoryRequested then resetActionState() return false end
                    if isCharInAnyCar(PLAYER_PED) then sendCEF('requestShowingInventory|27') inventoryRequested = true end

                    lua_thread.create(function ()
                        wait(300)

                        if not validateAction(currentAction) then resetActionState() return end
                        setState(STATE_EQUIPPING)

                        if settings.typeInv == 2 then
                            sendCEF('clickOnButton|{"type":2,"slot":' .. settings.slotObrez .. ',"action":1}')
                        else
                            local slots = {
                                    [1] = 3,
                                    [2] = 9,
                                    [3] = 15
                                }

                            local invset = tonumber(settings.invset)
                            local useset = tonumber(settings.useset)

                            if invset ~= useset then
                                message('У вас не соответствуют данные между используемыми сетами. В инвентаре сет №' ..
                                tostring(invset) .. ', а в настройках скрипта №' .. tostring(useset))
                                resetActionState()
                                return
                            end

                            local targetSlot = slots[invset]

                            if not targetSlot then
                                message('Неизвестный номер сета: ' .. tostring(invset))
                                resetActionState()
                                return
                            end

                            sendCEF(('inventory.moveItem|{"from":{"slot":%d,"type":%d,"amount":1},"to":{"slot":%d,"type":%d}}'):format(settings.slotObrez, 1, targetSlot, 2))
                            wait(250)
                            if not validateAction(currentAction) then resetActionState() return end

                            sendCEF('clickOnButton|{"type":2,"slot":' .. settings.slotObrez .. ',"action":1}')

                            wait(1200)
                            test_message(("Возврат: from slot=%d type=2 -> slot=%d type=1"):format(settings.slotObrez, settings.slotZamena))
                            if settings.slotZamena and settings.slotZamena ~= -1 then
                                sendCEF(('inventory.moveItem|{"from":{"slot":%d,"type":%d,"amount":1},"to":{"slot":%d,"type":%d}}'):format(settings.slotObrez, 2, settings.slotZamena, 1))
                            end
                        end

                        wait(200)
                        if not validateAction(currentAction) then resetActionState() return end

                        setState(STATE_CLOSING)
                        sendCEF('inventoryClose')
                        resetActionState()
                    end)

                    if settings.seekinv then
                        return false
                    end
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