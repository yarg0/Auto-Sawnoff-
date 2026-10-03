script_name("{e6953e}AutoSawnoff")
script_version("1.6.3")
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

    if not doesDirectoryExist(configDir) then createDirectory(configDir) end
    function class:Save(tbl)
        tbl = tbl or {}

        local file = io.open(filePath, 'w')
        if not file then return false, 'Не удалось открыть файл для записи' end

        local encoded = encodeJson(tbl)
        if not encoded then file:close() return false, 'Ошибка кодирования JSON' end

        file:write(encoded)
        file:close()

        return true, 'ok'
    end

    function class:Load(defaultTable)
        defaultTable = defaultTable or {}

        -- Файла нет — создаём новый
        if not doesFileExist(filePath) then self:Save(defaultTable) return defaultTable end

        local file = io.open(filePath, 'r')

        if not file then  return defaultTable end

        local content = file:read('*a')
        file:close()

        local data = {}

        -- Пустой файл
        if not content or content == '' then
            data = defaultTable
            self:Save(data)
            return data
        end

        -- Читаем JSON
        local ok, result = pcall(decodeJson, content)

        if ok and type(result) == 'table' then
            data = result
        else
            print('[JSON] Ошибка чтения файла: ' .. tostring(filePath))
            print('[JSON] Файл будет восстановлен.')

            data = defaultTable
            self:Save(data)

            return data
        end

        -- Рекурсивное объединение настроек
        local function copyTable(tbl)
            local result = {}

            for k, v in pairs(tbl) do
                if type(v) == 'table' then
                    result[k] = copyTable(v)
                else
                    result[k] = v
                end
            end

            return result
        end

        local function merge(dataTbl, defaultTbl)

            for k, defaultValue in pairs(defaultTbl) do

                -- Поля вообще нет
                if dataTbl[k] == nil then

                    if type(defaultValue) == 'table' then
                        dataTbl[k] = copyTable(defaultValue)
                    else
                        dataTbl[k] = defaultValue
                    end

                -- Оба значения таблицы
                elseif type(dataTbl[k]) == 'table'
                    and type(defaultValue) == 'table' then

                    -- Рекурсивно добавляем только отсутствующие поля
                    merge(dataTbl[k], defaultValue)

                end
            end
        end

        merge(data, defaultTable)

        -- Сохраняем обновлённую структуру
        self:Save(data)

        return data
    end

    return class
end
local name_file = 'AutoSawnoff.json'
local settings = json(name_file):Load({
    autoUse = false,
    autoUseJoinGame = false,
    SpecificAccessory = false,          -- Конкретный аксессуар
    JSmetod = false,
    STRUTDTA = false,                   -- Установка рандом времени использования при корректировке
    Obres = {
        id = 5822,
        slot = nil,
        type = nil,
        AddManually = false
    },
    BaseAcs = {
        id = -1,
        ForciblyReturn = false,
        slot = nil,
        type = nil,
        QuickZamena = nil,
        AddManually = false
    },
    minTime = 0,
    maxTime = 0,
    minSeconds = 0,
    maxSeconds = 0,
    talitts = 0,                        -- Время после захода на сервер
    reloadBug = 0,
    hidemode = {
        hide_message_script = false,    -- Убирает скриптовые сообщения
        hide_server_message = false,    -- Убирает сообщения сбора обреза из чата
        off_anim = false                -- Скрывает анимацию сбора
    },
    debugmessage = false,
    seekinv = false,
    interior = {
        int_use = false,
        int_list_onlyhere = {},
        int_list_exception = {},
    },
    invset = 1,
    date = '', goodsbor = 0, failsbor = 0
})
local function save_settings()
    json(name_file):Save(settings)
end
local function message(text, color)
    if settings.hidemode.hide_message_script then return end

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
    local size = imgui.CalcTextSize(text)
    imgui.SetCursorPosX((imgui.GetWindowWidth() - size.x) / 2)
    imgui.Text(text)
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
function imgui.CenterTextColored(color, text)
    local windowWidth = imgui.GetWindowWidth()
    local textWidth = imgui.CalcTextSize(text).x
    imgui.SetCursorPosX((windowWidth - textWidth) * 0.5)
    imgui.TextColored(color, text)
end

local autoUse = imgui.new.bool(settings.autoUse or false)
local AUJoinGame = imgui.new.bool(settings.autoUseJoinGame or false)
local Obres_AddManually = imgui.new.bool(settings.Obres.AddManually or false)
local BaseAcs_AddManually = imgui.new.bool(settings.BaseAcs.AddManually or false)
local STRUTDTA = imgui.new.bool(settings.STRUTDTA or false)
local SpecificAccessory = imgui.new.bool(settings.SpecificAccessory or false)
local JSmetod = imgui.new.bool(settings.JSmetod or false)
local hide_message_script = imgui.new.bool(settings.hidemode.hide_message_script or false)
local hide_server_message = imgui.new.bool(settings.hidemode.hide_server_message or false)
local off_anim = imgui.new.bool(settings.hidemode.off_anim or false)
local debugmessage = imgui.new.bool(settings.debugmessage or false)
local seekinv = imgui.new.bool(settings.seekinv or false)
local minTime = imgui.new.int(settings.minTime or 0)
local maxTime = imgui.new.int(settings.maxTime or 0)
local minSeconds = imgui.new.int(settings.minSeconds or 0)
local maxSeconds = imgui.new.int(settings.maxSeconds or 0)
local talitts = imgui.new.int(settings.talitts or 0)
local int_use = imgui.new.bool(settings.interior.int_use or false)
local idobrez = imgui.new.char[256](settings.Obres.id)
local ForciblyReturn = imgui.new.bool(settings.BaseAcs.ForciblyReturn or false)
local idacs = imgui.new.char[256](settings.BaseAcs.id)
local interior = imgui.new.char[256]()

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
    ['Полицейский пояс из боеприпас'] = 9824,
    ['Медаль Devil Company'] = 10147,
    ['Масонский правый наплечник'] = 10384
}

local BaseAcs = {
    ['Бехелит Черного мечника'] = 9214,
    ['Наплечник Друида'] = 9235,
    ['Сердце Лича'] = 9420,
    ['Ожерелье ведьмы'] = 9483,
    ['Ожерелье медведя'] = 9581,
    ['Ожерелье Фрирен'] = 9605,
    ['Полицейский пояс из боеприпас'] = 9824,
    ['Энергетический махинатор'] = 7852,
    ['Цепь Махинатор'] = 6313,
    ['Цепь Иллюмината'] = 8555,
    ['Золотая гангстерская цепь'] = 8727,
    ['Медаль Devil Company'] = 10147,
    ['Масонский правый наплечник'] = 10384
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
                    MenuScript()
                    imgui.EndTabItem() -- конец вкладки
                end
                if imgui.BeginTabItem(u8'Методы работы') then -- первая вкладка
                    VariantWork()
                    imgui.EndTabItem() -- конец вкладки
                end
                if imgui.BeginTabItem(u8'Статус') then -- первая вкладка
                    Status()
                    imgui.EndTabItem() -- конец вкладки
                end
                if imgui.BeginTabItem(u8'Настройки') then -- вторая вкладка
                    SettingsMenu()
                    imgui.EndTabItem() -- конец вкладки
                end
                imgui.EndTabBar() -- конец всех вкладок
            end
        imgui.End()
    end
end)

function MenuScript()
    imgui.BeginChild("SawnoffTimer", imgui.ImVec2(0, 70), true)
    imgui.CenterTextColored(imgui.ImVec4(0.35, 0.85, 1.0, 1.0), faicons('stopwatch') .. u8' Автосбор обрезов')
    imgui.Spacing()
    if NextUseTime and NextUseTime > os.time() then
        local nextText = faicons('clock') .. u8' Следующий сбор: ' .. os.date("%H:%M:%S", NextUseTime)
        imgui.CenterTextColored(imgui.ImVec4(0.40, 1.00, 0.45, 1.0), nextText)
        local remainText = faicons('HOURGLASS_CLOCK') .. u8' Осталось: ' .. formatTime(NextUseTime - os.time())
        imgui.CenterTextColored(imgui.ImVec4(1.0, 0.85, 0.35, 1.0), remainText)
    else
        imgui.CenterTextColored(imgui.ImVec4(1.0, 0.55, 0.35, 1.0), faicons('triangle_exclamation') ..u8' Таймер ещё не синхронизирован')
        imgui.CenterTextColored(imgui.ImVec4(0.70, 0.70, 0.70, 1.0), faicons('circle_info') .. u8' Используйте "Старт-проверку"')
    end
    imgui.EndChild()
    imgui.Separator()
    if imgui.Checkbox(faicons('hand') .. u8' Автосбор обрезов', autoUse) then
        settings.autoUse = autoUse[0]
        save_settings()
    end
    if imgui.Checkbox(faicons('clock_rotate_left') .. u8' Корректировка времени', AUJoinGame) then
        settings.autoUseJoinGame = AUJoinGame[0]
        save_settings()
    end
    imgui.Spacing()
    if imgui.Button(faicons('play') .. u8' Запустить старт-проверку', imgui.ImVec2(300, 30)) then
        lua_thread.create(autoSawnoff)
    end
end

function VariantWork()
    imgui.SetWindowFontScale(1.15)
    imgui.TextColored(imgui.ImVec4(0.35, 0.85, 1.0, 1.0), faicons('wand_magic_sparkles') .. u8' Использование аксессуара')
    imgui.SetWindowFontScale(1.0)
    imgui.Separator()
    if imgui.Checkbox(faicons('newspaper') .. u8' JavaScript метод', JSmetod) then
        settings.JSmetod = JSmetod[0]
        save_settings()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Использует JavaScript вместо Lua.')
        imgui.Text(u8'Работает немного медленнее, но стабильнее.')
        imgui.EndTooltip()
    end
    imgui.Spacing()

    imgui.SetWindowFontScale(1.15)
    imgui.TextColored(imgui.ImVec4(1.00, 0.75, 0.35, 1.0), faicons('gun') .. u8' Аксессуар "Обрез"')
    imgui.SetWindowFontScale(1.0)
    imgui.Separator()

    if imgui.Checkbox(faicons('pen') .. u8' Указать ID вручную', Obres_AddManually) then
        settings.Obres.AddManually = Obres_AddManually[0]
        save_settings()
    end
    imgui.TextColored(settings.Obres.id ~= -1 and imgui.ImVec4(0.4,1,0.4,1) or imgui.ImVec4(1,0.45,0.45,1), 
        faicons('fingerprint') .. u8(' ID: ' .. tostring(settings.Obres.id ~= -1 and settings.Obres.id or "не задан")))
    if settings.Obres.AddManually then
        imgui.PushItemWidth(170)
        if imgui.InputText(u8"##IDObrez", idobrez, 256) then
            local ID_Sawnoff = tonumber(u8:decode(ffi.string(idobrez)))
            settings.Obres.id = ID_Sawnoff or 5822
            save_settings()
        end
        imgui.PopItemWidth()
    else
        if imgui.CollapsingHeader(faicons('boxes_stacked') .. u8' Выбрать из набора') then
            for name,id in pairs(legacs) do
                if imgui.Button(u8(name)) then
                    settings.Obres.id = id
                    save_settings()
                end
            end
        end
    end
    imgui.Spacing()

    imgui.SetWindowFontScale(1.15)
    imgui.TextColored(imgui.ImVec4(0.45,1,0.6,1), faicons('shuffle') .. u8' Замена аксессуара')
    imgui.SetWindowFontScale(1.0)
    imgui.Separator()

    if imgui.Checkbox(faicons('repeat') .. u8' Использовать другой аксессуар', SpecificAccessory) then
        settings.SpecificAccessory = SpecificAccessory[0]
        save_settings()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'После использованием "Обреза"')
        imgui.Text(u8'будет возвращен аксессуар с указанным ID.')
        imgui.EndTooltip()
    end
    if settings.SpecificAccessory then
        if imgui.Checkbox(faicons('rotate_left') .. u8' Возвращать основной аксессуар', ForciblyReturn) then
            settings.BaseAcs.ForciblyReturn = ForciblyReturn[0]
            save_settings()
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Перед использованием "Обреза" аксессуар с указанным ID будет')
            imgui.Text(u8'возвращен в слот сета, если вдруг собьется порядок.')
            imgui.EndTooltip()
        end
        imgui.TextColored(settings.BaseAcs.id and imgui.ImVec4(0.45,1,0.45,1) or imgui.ImVec4(1,0.45,0.45,1), 
            faicons('fingerprint') .. u8(' ID: ' .. tostring(settings.BaseAcs.id or "не задан")))
        if imgui.Checkbox(faicons('pen') .. u8' Ввести ID вручную', BaseAcs_AddManually) then
            settings.BaseAcs.AddManually = BaseAcs_AddManually[0]
            save_settings()
        end
        if settings.BaseAcs.AddManually then
            imgui.PushItemWidth(170)
            if imgui.InputText(u8"##BaseAccessoryID", idacs, 256) then
                local ID_Acs = tonumber(u8:decode(ffi.string(idacs)))
                settings.BaseAcs.id = ID_Acs
                save_settings()
            end
            imgui.PopItemWidth()
        else
            if imgui.CollapsingHeader(faicons('boxes_stacked') .. u8' Выбрать аксессуар') then
                for name,id in pairs(BaseAcs) do
                    if imgui.Button(u8(name)) then
                        settings.BaseAcs.id = id
                        save_settings()
                    end
                end
            end
        end
    else
        if settings.BaseAcs.ForciblyReturn then
            ForciblyReturn[0] = false
            settings.BaseAcs.ForciblyReturn = false
            save_settings()
        end
    end
end

function Status()
    imgui.SetWindowFontScale(1.12)
    imgui.TextColored(imgui.ImVec4(0.4, 0.85, 1.0, 1.0), faicons('chart_simple') .. u8' Автосбор')
    imgui.SetWindowFontScale(1.0)
    imgui.Separator()

    local success = settings.goodsbor or 0
    local failed = settings.failsbor or 0
    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.4, 1.0), faicons('circle_check') .. u8' Успешные сборы: ')
    imgui.SameLine()
    imgui.Text(tostring(success))
    imgui.SameLine(200)
    imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), faicons('circle_xmark') .. u8' Ошибки: ')
    imgui.SameLine()
    imgui.Text(tostring(failed))
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Статистика за текущие сутки')
        imgui.EndTooltip()
    end

    imgui.Spacing()

    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.3, 1.0),faicons('shirt') .. u8' Текущий сет: ')
    imgui.SameLine()
    imgui.Text(u8'№' .. tostring(settings.invset))
    imgui.Separator()

    imgui.TextColored(imgui.ImVec4(1.0, 0.65, 0.3, 1.0),faicons('gun') .. u8' Обрез')
    imgui.SameLine(180)
    if settings.Obres.type == 1 then
        imgui.TextColored(imgui.ImVec4(0.3,1,0.4,1), faicons('box') .. u8' Инвентарь [' .. settings.Obres.slot .. ']')
    elseif settings.Obres.type == 2 then
        imgui.TextColored(imgui.ImVec4(0.3,0.8,1,1), faicons('user') .. u8' Надет')
    else
        imgui.TextColored(imgui.ImVec4(1,0.3,0.3,1), faicons('ban') .. u8' Нет')
    end

    imgui.Spacing()

    imgui.TextColored(imgui.ImVec4(0.6,0.8,1,1), faicons('gem') .. u8' Основной аксессуар')
    imgui.SameLine(180)
    if settings.BaseAcs.type == 1 then
        imgui.TextColored(imgui.ImVec4(0.3,1,0.4,1), faicons('box') .. u8' Инвентарь [' .. settings.BaseAcs.slot .. ']')
    elseif settings.BaseAcs.type == 2 then
        imgui.TextColored(imgui.ImVec4(0.3,0.8,1,1),faicons('user') .. u8' Надет')
    else
        imgui.TextColored(imgui.ImVec4(1,0.3,0.3,1),faicons('ban') .. u8' Нет')
    end
end

function SettingsMenu()
    imgui.SetWindowFontScale(1.15)
    imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1.0, 1), faicons('gear') .. u8' Основные настройки')
    imgui.SetWindowFontScale(1.0)

    imgui.Separator()
    if imgui.Checkbox(faicons('volume_xmark') .. u8' Тихий режим', hide_message_script) then
        settings.hidemode.hide_message_script = hide_message_script[0]
        save_settings()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Отключает сообщения скрипта во время работы')
        imgui.EndTooltip()
    end
    imgui.SameLine()
    if imgui.Checkbox(u8'Скрывать серверные сообщения', hide_server_message) then
        settings.hidemode.hide_server_message = hide_server_message[0]
        save_settings()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Убирает все серверные сообщения связанные со сбором обреза')
        imgui.EndTooltip()
    end

    if imgui.Checkbox(u8'Убирать анимацию сбора', off_anim) then
        settings.hidemode.off_anim = off_anim[0]
        save_settings()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Убирает все анимации связанные со сбором')
        imgui.EndTooltip()
    end

    if imgui.Checkbox(faicons('eye_slash') .. u8' Скрывать инвентарь при использовании', seekinv) then
        settings.seekinv = seekinv[0]
        save_settings()
    end

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.3, 1), faicons('building') .. u8' Ограничение по интерьерам')

    if imgui.Checkbox(faicons('door_open') .. u8' Использовать проверку интерьеров', int_use) then
        settings.interior.int_use = int_use[0]
        save_settings()
    end
    if settings.interior.int_use then
        if imgui.BeginChild("InteriorSettings", imgui.ImVec2(0, 200), true) then
            local currentInt = getCharActiveInterior(PLAYER_PED)
            imgui.CenterText(faicons('location_dot') .. u8' Текущий интерьер: ' .. tostring(currentInt))
            imgui.Spacing()

            if imgui.Button(faicons('circle_check') .. u8' Разрешить текущий', imgui.ImVec2(160,25)) then
                addInteriorList(currentInt, "only")
            end

            imgui.SameLine()

            if imgui.Button(faicons('ban') .. u8' Запретить текущий', imgui.ImVec2(160,25)) then
                addInteriorList(currentInt, "exception")
            end

            imgui.Spacing()

            imgui.CenterText(faicons('keyboard') .. u8' Ввести ID интерьера вручную')
            imgui.PushItemWidth(120)
            imgui.InputText(u8"##interioraddhands", interior, 256)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(faicons('circle_check') .. u8' Разрешить', imgui.ImVec2(97,25)) then
                local ID = u8:decode(ffi.string(interior))
                addInteriorList(ID, "only")
            end
            imgui.SameLine()
            if imgui.Button(faicons('ban') .. u8' Исключить', imgui.ImVec2(97,25)) then
                local ID = u8:decode(ffi.string(interior))
                addInteriorList(ID, "exception")
            end

            imgui.Separator()

            imgui.TextColored(imgui.ImVec4(0.4,1.0,0.4,1), faicons('circle_check') .. u8' Разрешённые интерьеры')

            if #settings.interior.int_list_onlyhere == 0 then
                imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1), u8'Список пуст')
            else
                for i,id in ipairs(settings.interior.int_list_onlyhere) do
                    imgui.Text(faicons('cube') .. u8' Интерьер №' .. tostring(id))
                    imgui.SameLine()
                    if imgui.Button( faicons('trash') .. '##only' .. i) then
                        removeInteriorList(id,"only")
                    end
                end
            end

            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(1.0,0.4,0.4,1), faicons('circle_xmark') .. u8' Запрещённые интерьеры')

            if #settings.interior.int_list_exception == 0 then
                imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1), u8'Список пуст')
            else
                for i, id in ipairs(settings.interior.int_list_exception) do
                    imgui.Text(faicons('triangle_exclamation') .. u8' Интерьер №' .. tostring(id))
                    imgui.SameLine()
                    if imgui.Button(faicons('trash') .. '##exception' .. i) then
                        removeInteriorList(id,"exception")
                    end
                end
            end
            imgui.EndChild()

        end
    end

    imgui.Spacing()
    imgui.Separator()
    imgui.TextColored(imgui.ImVec4(1,0.5,0.3,1), faicons('bug') .. u8' Отладка')

    if imgui.Checkbox(faicons('terminal') .. u8' DEBUG сообщения', debugmessage) then
        settings.debugmessage = debugmessage[0]
        save_settings()
    end
    if imgui.Checkbox(faicons('shuffle') .. u8' Рандомизация времени', STRUTDTA) then
        settings.STRUTDTA = STRUTDTA[0]
        save_settings()
    end

    imgui.Spacing()
    imgui.Separator()

    imgui.TextColored(imgui.ImVec4(0.5,0.8,1,1),faicons('clock') .. u8' Настройки времени')
    imgui.Text(u8'Корректировка через ' .. settings.talitts .. u8' секунд')
    imgui.PushItemWidth(200)
    if imgui.SliderInt(u8'##delay', talitts, 1, 30) then
        settings.talitts = talitts[0]
        save_settings()
    end
    imgui.Text(faicons('hourglass_start') .. u8' Рандомизация использования')
    if imgui.SliderInt(u8'Минимальная минута', minTime, 0, 15) then
        settings.minTime = minTime[0]
        save_settings()
    end
    if imgui.SliderInt(u8'Максимальная минута', maxTime, 0, 30) then
        settings.maxTime = maxTime[0]
        save_settings()
    end
    if imgui.SliderInt(u8'Минимальная секунда', minSeconds, 0, 59) then
        settings.minSeconds = minSeconds[0]
        save_settings()
    end
    if imgui.SliderInt(u8'Максимальная секунда', maxSeconds, 0, 59) then
        settings.maxSeconds = maxSeconds[0]
        save_settings()
    end
    imgui.PopItemWidth()
    imgui.Spacing()
    imgui.Separator()
    imgui.SetCursorPosX((imgui.GetWindowWidth()-220)/2)
    if imgui.Button(faicons('rotate') .. u8' Перезагрузить скрипт', imgui.ImVec2(220,30)) then
        settings.reloadBug = 1
        save_settings()
        thisScript():reload()
    end
end

local function setState(state)
    currentState = state
    test_message('STATE -> ' .. tostring(state), 0x00ff00)
end

local function resetActionState()
    busy = false
    sawnoff = false
    inventoryRequested = false
    actionActive = false

    setState(STATE_IDLE)
end

local function validateAction(id)
    return id == actionId and currentState ~= STATE_IDLE
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
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format('%02d:%02d:%02d', hours, minutes, secs)
end

function getRandomValue(min, max)
    min = math.floor(tonumber(min) or 0)
    max = math.floor(tonumber(max) or 0)
    if min > max then min, max = max, min end
    return math.random(min, max)
end

local function getRandomDelay()
    local minutes = getRandomValue(settings.minTime or 0, settings.maxTime or 0)
    local seconds = getRandomValue(settings.minSeconds or 0, settings.maxSeconds or 0)
    return minutes, seconds
end

local function setNextUse(delaySeconds, mode, messageText, messageColor)
    delaySeconds = math.max(0, math.floor(tonumber(delaySeconds) or 0))
    local executeTime = os.time() + delaySeconds

    if mode == 'server' then
        waitUntilTime = executeTime
        nextExecutionTime = 0
    else
        nextExecutionTime = executeTime
        waitUntilTime = 0
    end

    NextUseTime = executeTime

    if messageText then
        local text = string.format('%s | Следующее использование: %s', messageText, os.date('%H:%M:%S', executeTime))
        message(text, messageColor)
    end

    return executeTime
end

local function setCooldown()
    local minutes, seconds = getRandomDelay()
    local totalDelay = 3600 + minutes * 60 + seconds
    local nextTime = os.time() + totalDelay

    nextExecutionTime = nextTime
    waitUntilTime = 0
    NextUseTime = nextTime

    message(string.format(
            'КД установлен: +%d мин. +%d сек. | Осталось: %s | Следующее использование: %s',
            minutes, seconds,
            formatTime(totalDelay),
            os.date('%H:%M:%S', nextTime)), base_color)

    print(string.format(
            'КД установлен: +%d мин. +%d сек. | Осталось: %s | Следующее использование: %s',
            minutes, seconds,
            formatTime(totalDelay),
            os.date('%H:%M:%S', nextTime)))
end

local function setServerCooldown(lastTime)
    lastTime = tonumber(lastTime)
    if not lastTime then return end

    local minutes = 0
    local seconds = 0

    if settings.STRUTDTA then minutes, seconds = getRandomDelay() end
    local totalSeconds = lastTime * 60 + minutes * 60 + seconds
    local nextTime = setNextUse(totalSeconds, 'server')

    if settings.STRUTDTA then
        message(string.format(
                'Нужно подождать: %s | +%d мин +%d сек | Следующее использование: %s',
                formatTime(totalSeconds),
                minutes, seconds,
                os.date('%H:%M:%S', nextTime)), 0xFFe69f35)

        print(string.format(
                'Нужно подождать: %s | +%d мин +%d сек | Следующее использование: %s',
                formatTime(totalSeconds),
                minutes, seconds,
                os.date('%H:%M:%S', nextTime)))
    else
        message(string.format(
                'Нужно подождать: %s | Следующее использование: %s',
                formatTime(totalSeconds),
                os.date('%H:%M:%S', nextTime)), 0xFFe69f35)

        print(string.format(
                'Нужно подождать: %s | Следующее использование: %s',
                formatTime(totalSeconds),
                os.date('%H:%M:%S', nextTime)))
    end
end

local function checkNewDay()
    local date = os.date('%d.%m.%Y')
    if settings.date == date then return end

    settings.date = date
    settings.goodsbor = 0
    settings.failsbor = 0

    save_settings()
    print('Новые сутки. Статистика сброшена.')
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

    math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1, 6)))
    math.random()
    math.random()
    math.random()

    message('Скрипт загружен!')

    sampRegisterChatCommand('asawnoff', function()
        renderWindow[0] = not renderWindow[0]
    end)

    sampRegisterChatCommand('usesawnoff', function()
        if sawnoff then message('Автосбор уже выполняется.') return end
        lua_thread.create(function() autoSawnoff() end)
    end)

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

    local nextDateCheck = 0
    while true do
        wait(200)

        if not sampIsLocalPlayerSpawned() then
            if sawnoff then
                message('Выключаю запущенный процесс автосбора обрезов, т.к. персонаж не подключен к серверу')
                resetActionState()
            end

            goto continue
        end

        if settings.autoUse then
            local currentTime = os.time()

            if waitUntilTime > 0 then
                if currentTime >= waitUntilTime then
                    waitUntilTime = 0
                    NextUseTime = 0

                    message('Ожидание завершено, собираю...')
                    if not sawnoff then autoSawnoff() end
                end
            end

            if nextExecutionTime > 0 then
                if currentTime >= nextExecutionTime then
                    nextExecutionTime = 0
                    NextUseTime = 0

                    message('Автозапуск выполнен после завершения КД!')
                    if not sawnoff then autoSawnoff() end
                end
            end
        end

        local now = os.clock()
        if now >= nextDateCheck then
            nextDateCheck = now + 5
            checkNewDay()
        end

        ::continue::
    end
end

function ev.onServerMessage(color, text)

    if text:match('%[Информация%] {ffffff}Вы использовали запас обрезов%.') then
        if settings.autoUse then
            message('Обнаружено использование запаса обрезов. Устанавливаю КД...')
            print('Обнаружено использование запаса обрезов. Устанавливаю КД...')
            setCooldown()
        end

        settings.goodsbor = (tonumber(settings.goodsbor) or 0) + 1
        save_settings()

        if settings.hidemode.hide_server_message then return false end

        return
    end

    local lasttimeStr = text:match('%[Ошибка%] {ffffff}Для использования этого аксессуара должно пройти ещё (%d+) минут!')
    if lasttimeStr and settings.autoUse then setServerCooldown(lasttimeStr) return end

    if text:match('{DFCFCF}%[Подсказка%] {DC4747}На сервере есть инвентарь, используйте клавишу Y для работы с ним%.') then
        if settings.autoUse and settings.autoUseJoinGame and sampIsLocalPlayerSpawned() then
            lua_thread.create(function()
                local delay = tonumber(settings.talitts) or 0
                wait(delay * 1000)
                if sampIsLocalPlayerSpawned() and settings.autoUse and not sawnoff then autoSawnoff() end
            end)
        end

        return
    end

    if text:find("bits %(%d+%) doesn't include button_type %(%d+%)") then
        if sawnoff then
            message('Упс... Слот не смог определиться.')
            settings.failsbor = (tonumber(settings.failsbor) or 0) + 1
            save_settings()
            resetActionState()
        end

        return
    end

    if text:match('%[Ошибка%] {ffffff}Запрещено использовать аксессуары в зоне проведения мероприятия "Зловещая экспедиция"%.' ) then resetActionState() return end

    if color == -10270721 and text:find('Нельзя так быстро открывать инвентарь, подождите еще 1 сек%.') then
        if sawnoff then
            lua_thread.create(function()
                resetActionState()
                local delay = math.random(5000, 10000)
                message(string.format('Сработала защита от быстрого открытия инвентаря! Следующая попытка будет через %.1f сек.', delay / 1000))
                wait(delay)
                if sampIsLocalPlayerSpawned() and settings.autoUse and not sawnoff then autoSawnoff() end
            end)
        end

        return
    end

    if text:match(':u1f7e8: В инвентарь добавлен предмет: :item5829:%.') then
        if settings.hidemode.hide_server_message then return false end
    end

end

function autoSawnoff()

    if not settings.Obres.slot or not settings.Obres.type then
        message('Обрез не найден, сбор отменен')
        resetActionState()
        return
    end

    if not sampIsLocalPlayerSpawned() then
        message('Персонаж не подключен к серверу. Сбор отменяется...')
        resetActionState()
        return
    end

    -- Проверка интерьеров
    if settings.interior.int_use then
        local currentInterior = getCharActiveInterior(PLAYER_PED)
        local onlyList = settings.interior.int_list_onlyhere or {}
        local exceptionList = settings.interior.int_list_exception or {}

        for _, int in ipairs(exceptionList) do
            if tonumber(int) == currentInterior then
                message('Сбор не сработал! Текущий интерьер находится в списке исключений.')
                resetActionState()
                return
            end
        end

        if #onlyList > 0 then
            local allowed = false
            for _, int in ipairs(onlyList) do
                if tonumber(int) == currentInterior then
                    allowed = true
                    break
                end
            end

            if not allowed then
                message('Сбор не сработал! У вас включено использование а/с только в {cc8941}разрешённых{ffffff} интерьерах.')
                message(('Разрешённые интерьеры: %s | Текущий: %d'):format(table.concat(onlyList, ", "), currentInterior))
                resetActionState()
                return
            end
        end
    end

    if settings.JSmetod then
        if not settings.Obres.id or settings.Obres.id == '' or settings.Obres.id == ' ' then
            message('Не вписан ID а/с "Обрез" (или лег. акса с его переносом). Отменяю запуск...')
            return
        end
        if not settings.SpecificAccessory then
            message('Чтобы использовать этот способ включите замену а/с "Обрез" (или лег. акса с его переносом) на конкретный а/с. Отменяю запуск...')
            return
        end
        if not settings.BaseAcs.id or settings.BaseAcs.id == '' or settings.BaseAcs.id == ' ' then
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
            local OBREZ = settings.Obres.id
            local ACC = settings.BaseAcs.id

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

function onWindowMessage(msg, wparam, lparam)

    if not sawnoff then return end

    if msg == 0x100 or msg == 0x101 or
       msg == 0x102 or msg == 0x104 or msg == 0x105 then

        if wparam == 0x1B or wparam == 0x59 then
            consumeWindowMessage(true)
            return
        end
    end
end

function ev.onApplyPlayerAnimation(playerId, animLib, animName)
    if settings.hidemode.off_anim and animLib == 'BOMBER' and animName == 'BOM_Plant_Loop' then return false end
end

addEventHandler('onReceivePacket', function (id, bs)
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)

            if str:match('event.inventory.playerInventory') then
                local page = str:match('accsPages":{"total":3,"page":(%d+)')
                if page and settings.invset ~= tonumber(page) then
                    settings.invset = tonumber(page)
                    save_settings()
                end
            end

            local type, slot = findItemById(str, settings.Obres.id)
            if type and slot then
                settings.Obres.type = type
                settings.Obres.slot = slot

                test_message(('A/C обрез найден | type: %d | slot: %d'):format(type, slot), 0xff0000)
                save_settings()
            end

            if settings.hidemode.hide_server_message then
                if str:match('event.damageInformer.initializeDamageInfo') and str:match('Обрез') then
                    return false
                end

                if str:match('event.notify.initialize') and str:match('Вы использовали запас обрезов.') then
                    return false
                end
            end

            if settings.BaseAcs.id and settings.BaseAcs.id ~= -1 then
                local typeSacs, slotSacs = findItemById(str, settings.BaseAcs.id)
                if typeSacs and slotSacs then
                    settings.BaseAcs.type = typeSacs
                    settings.BaseAcs.slot = slotSacs

                    test_message(('Основной A/C найден | type: %d | slot: %d'):format(typeSacs, slotSacs), 0xff0000)
                    save_settings()
                end
            end

            if sawnoff then
                if settings.SpecificAccessory then
                    local type, slotik = findItemById(str, settings.BaseAcs.id)
                    if slotik then
                        test_message('Тип сбора обреза с исп-ем конкретного ID а/с')
                        test_message('Слот замены найден - ' .. tostring(slotik), 0x4366e6)
                        test_message('ID а/с: ' .. settings.BaseAcs.id .. ' | Слот: ' .. slotik, 0xff0000)
                        settings.BaseAcs.QuickZamena = slotik
                        save_settings()
                    end
                else
                    local slot = str:match('"slot":(%d+)')
                    if slot then
                        test_message('Тип сбора обреза без конкретного ID а/с')
                        test_message('ID а/с который был на 4 слоте: ' .. settings.BaseAcs.id .. ' | Слот в который попал: ' .. slot, 0xff0000)
                        settings.BaseAcs.QuickZamena = tonumber(slot)
                        save_settings()
                    end
                end
            end

            if str:find('event.setActiveView') and str:find('Inventory') then
                if sawnoff then

                    local slots = {
                            [1] = 3,
                            [2] = 12,
                            [3] = 18
                        }

                    local invset = tonumber(settings.invset)
                    local targetSlot = slots[invset]

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
                        wait(550)
                        if settings.BaseAcs.ForciblyReturn then
                            if settings.BaseAcs.type ~= 2 and settings.BaseAcs.slot and settings.BaseAcs.type then
                                sendCEF(('inventory.moveItemForce|{"slot": %d, "type": 2, "amount": 1}'):format(targetSlot))
                                wait(750)
                                sendCEF(('inventory.moveItem|{"from":{"slot":%d,"type":%d,"amount":1},"to":{"slot":%d,"type":%d}}'):format(settings.BaseAcs.slot, 1, targetSlot, 2))
                            end
                        end

                        if not validateAction(currentAction) then resetActionState() return end
                        setState(STATE_EQUIPPING)

                        if settings.Obres.type == 2 then
                            sendCEF('clickOnButton|{"type":2,"slot":' .. settings.Obres.slot .. ',"action":1}')
                        else
                            if not targetSlot then
                                message('Неизвестный номер сета: ' .. tostring(invset))
                                resetActionState()
                                return
                            end

                            sendCEF(('inventory.moveItem|{"from":{"slot":%d,"type":%d,"amount":1},"to":{"slot":%d,"type":%d}}'):format(settings.Obres.slot, 1, targetSlot, 2))
                            wait(750)
                            if not validateAction(currentAction) then resetActionState() return end

                            sendCEF('clickOnButton|{"type":2,"slot":' .. settings.Obres.slot .. ',"action":1}')

                            wait(1450)
                            if settings.BaseAcs.QuickZamena and settings.BaseAcs.QuickZamena ~= -1 then
                                test_message(("Возврат: from slot=%d type=2 -> slot=%d type=1"):format(settings.Obres.slot, settings.BaseAcs.QuickZamena))
                                sendCEF(('inventory.moveItem|{"from":{"slot":%d,"type":%d,"amount":1},"to":{"slot":%d,"type":%d}}'):format(settings.Obres.slot, 2, settings.BaseAcs.QuickZamena, 1))
                            end
                        end

                        wait(500)
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

function addInteriorList(args, mode)
    if not args or args == '' then return end
    local targetId = tonumber(args)
    if not targetId then message('Ошибка: укажите корректный ID интерьера (число)') return end

    local addList
    local checkList
    local listName
    local otherName

    if mode == "only" then
        addList = settings.interior.int_list_onlyhere
        checkList = settings.interior.int_list_exception
        listName = "разрешённых"
        otherName = "исключений"
    elseif mode == "exception" then
        addList = settings.interior.int_list_exception
        checkList = settings.interior.int_list_onlyhere
        listName = "исключений"
        otherName = "разрешённых"
    else
        return
    end

    settings.interior.int_list_onlyhere =  settings.interior.int_list_onlyhere or {}
    settings.interior.int_list_exception = settings.interior.int_list_exception or {}

    for _, id in ipairs(addList) do
        if tonumber(id) == targetId then
            message(string.format('Интерьер с ID {cc8941}%d{ffffff} уже находится в списке %s', targetId, listName))
            return
        end
    end

    for _, id in ipairs(checkList) do
        if tonumber(id) == targetId then
            message(string.format('Интерьер с ID {cc8941}%d{ffffff} уже находится в списке %s. Добавление отменено.', targetId, otherName))
            return
        end
    end

    table.insert(addList, targetId)
    save_settings()
    message(string.format('Интерьер с ID {cc8941}%d{ffffff} успешно добавлен в список %s', targetId, listName))
end

function removeInteriorList(args, mode)
    local list
    if mode == "only" then
        list = settings.interior.int_list_onlyhere
    elseif mode == "exception" then
        list = settings.interior.int_list_exception
    else
        return
    end

    if not args or args == '' then
        list = {}
        if mode == "only" then
            settings.interior.int_list_onlyhere = {}
        else
            settings.interior.int_list_exception = {}
        end

        save_settings()
        message('Список интерьеров очищен')
        return
    end

    local targetId = tonumber(args)
    if not targetId then message('Ошибка: укажите корректный ID интерьера') return end

    for i, id in ipairs(list) do
        if tonumber(id) == targetId then
            table.remove(list, i)
            save_settings()
            message(string.format('Интерьер с ID {cc8941}%d{ffffff} удалён из списка', targetId))
            return
        end
    end
    message(string.format('Интерьер с ID {cc8941}%d{ffffff} не найден', targetId))
end

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

function HideLootSawnoff()
    local json = '[ null ]'
    local code = "window.executeEvent('event.damageInformer.initializeDamageInfo', `" .. json .. "`);"
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #code)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteString(bs, code)
    raknetEmulPacketReceiveBitStream(220, bs)
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