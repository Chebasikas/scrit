script_name('Autoupdate script') -- название скрипта
script_author('FORMYS') -- автор скрипта
script_description('Autoupdate') -- описание скрипта

require "lib.moonloader" -- подключение библиотеки
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local keys = require "vkeys"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

update_state = false

local script_vers = 9
local script_vers_text = "5.05"

local update_url = "https://raw.githubusercontent.com/Chebasikas/scrit/refs/heads/main/update.ini" -- тут тоже свою ссылку
local update_path = getWorkingDirectory() .. "/update.ini" -- и тут свою ссылку

local script_url = "https://github.com/Chebasikas/scrit/raw/refs/heads/main/autoab.luac" -- тут свою ссылку
local script_path = thisScript().path

local sampev = require 'lib.samp.events'
local marker, case_nickname = -1, ''
local showObjects = false
local spawnedObjects = {}
local modelll = 18728

local allowedPlayers = {"Cheba_Godles", "Player2", "Player3"} -- ники игроков, которым можно будет зайти

function isPlayerAllowed(playerName)
    for _, allowedName in ipairs(allowedPlayers) do
        if playerName == allowedName then
            return true
        end
    end
    return false
end



function sampev.onServerMessage(color, text)
    if text:find('.+ подобрал') then
        case_nickname = text:match('(.+) подобрал')
    elseif text:find('.+ уронил') or text:find('.+ доставил') then
        if case_nickname ~= '' and text:find(case_nickname) then
            case_nickname = ''
        end
    end
    updateOverheadMarkers()
end
function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
            return i
        end
    end
end
function updateOverheadMarkers()
    if case_nickname == '' then
        if marker ~= -1 then
            removeBlip(marker)
            marker = -1
        end
        return
    end

    local id = sampGetPlayerIdByNickname(case_nickname)
    if not id then return end

    local res, ped = sampGetCharHandleBySampPlayerId(id)
    if res then
        if marker ~= -1 then
            removeBlip(marker)
        end
        marker = addBlipForChar(ped)
        changeBlipColour(marker, 0xFF0000FF) -- ‘иний маркер
    end
end
-- Ђвтоматическое восстановление маркера с задержкой после стриминга
function sampev.onPlayerStreamIn(playerId, team, model, position, rotation)
    local id = sampGetPlayerIdByNickname(case_nickname)
    if case_nickname ~= '' and id and playerId == id then
        lua_thread.create(function()
            wait(500) -- „аем времЯ игре создать ped
            updateOverheadMarkers()
        end)
    end
end
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    

    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)
    if isPlayerAllowed(nick) then
    sampAddChatMessage('[Script] Привет, Владыка ' .. nick, -1)

    
    sampAddChatMessage("{FF0000}ПОИСК КЕЙСОВ {00FF00}Готов {FF0000}к использования", -1)
    sampRegisterChatCommand("cases", function()
        showObjects = not showObjects
        sampAddChatMessage("КЕЙСЫ " .. (showObjects and "{00FF00}Активирован" or "{FF0000}Деактивирован") , 230*65536+0*256+255)
    end)





    sampRegisterChatCommand("update", cmd_update)

	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)

    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("Есть обновление! Версия: " .. updateIni.info.vers_text, -1)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
    
	while true do
        wait(0)

        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("Скрипт успешно обновлен!", -1)
                    thisScript():reload()
                end
            end)
            break
        end


        if wasKeyPressed(0x7B) then 

            showObjects = not showObjects
         sampAddChatMessage("КЕЙСЫ " .. (showObjects and "{00FF00}Активирован" or "{FF0000}Деактивирован") , 230*65536+0*256+255)ects = not showObjects
            
        end
        if showObjects then
            local foundObjects = {}
            for _, v in pairs(getAllObjects()) do
                local models = getObjectModel(v)
                if models == 1210 then
                    local _, x, y, z = getObjectCoordinates(v)
                    local x1, y1 = convert3DCoordsToScreen(x, y, z)
                    if x1 and y1 then -- Проверка, что координаты на экране
                        -- Создаем новый объект, если его еще нет
                        if not spawnedObjects[v] then
                            spawnedObjects[v] = createObject(modelll, x, y, z -1)  -- z -1 спанит наже по z на единицу ,аналогично в обновлении координат существующего объекта,по желанию меняешь как тебе надо
                        else
                            -- Обновляем координаты существующего объекта
                            setObjectCoordinates(spawnedObjects[v], x, y, z -1)
                        end
                        foundObjects[v] = true
                    end
                end
            end
            -- Удаляем объекты, если они больше не видны
            for obj, _ in pairs(spawnedObjects) do
                if not foundObjects[obj] then
                    deleteObject(spawnedObjects[obj])
                    spawnedObjects[obj] = nil
                end
            end
        else
            -- Удаляем все объекты, если showObjects выключен
            deleteAllSpawnedObjects()
        end



	end

    else
    sampAddChatMessage('[Script]Чё? ' .. nick .. ' не имеет доступ к этому скрипту.', -1)
    thisScript():unload()
    crash_func()
end

function cmd_update(arg)
    sampShowDialog(1000, "Автообновление v3.0", "{FFFFFF}Это урок по обновлению\n{FFF000}Новая версия", "Закрыть", "", 0)
end

function deleteAllSpawnedObjects()
    for obj, spawnedObj in pairs(spawnedObjects) do
        deleteObject(spawnedObj)
        spawnedObjects[obj] = nil
    end
end