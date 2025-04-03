script_name('Autoupdate script') -- íàçâàíèå ñêðèïòà
script_author('FORMYS') -- àâòîð ñêðèïòà
script_description('Autoupdate') -- îïèñàíèå ñêðèïòà

require "lib.moonloader" -- ïîäêëþ÷åíèå áèáëèîòåêè
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local keys = require "vkeys"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

update_state = false

local script_vers = 15
local script_vers_text = "5.05"

local update_url = "https://raw.githubusercontent.com/Chebasikas/scrit/refs/heads/main/update.ini" -- òóò òîæå ñâîþ ññûëêó
local update_path = getWorkingDirectory() .. "/update.ini" -- è òóò ñâîþ ññûëêó

local script_url = "https://github.com/Chebasikas/scrit/raw/refs/heads/main/aaaa.lua" -- òóò ñâîþ ññûëêó
local script_path = thisScript().path

local sampev = require 'lib.samp.events'
local marker, case_nickname = -1, ''
local showObjects = false
local spawnedObjects = {}
local modelll = 18728

local allowedPlayers = {"Cheba_Godles"} -- íèêè èãðîêîâ, êîòîðûì ìîæíî áóäåò çàéòè

function isPlayerAllowed(playerName)
    for _, allowedName in ipairs(allowedPlayers) do
        if playerName == allowedName then
            return true
        end
    end
    return false
end



function sampev.onServerMessage(color, text)
    if text:find('.+ ïîäîáðàë') then
        case_nickname = text:match('(.+) ïîäîáðàë')
    elseif text:find('.+ óðîíèë') or text:find('.+ äîñòàâèë') then
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
        changeBlipColour(marker, 0xFF0000FF) -- ‘èíèé ìàðêåð
    end
end
-- €âòîìàòè÷åñêîå âîññòàíîâëåíèå ìàðêåðà ñ çàäåðæêîé ïîñëå ñòðèìèíãà
function sampev.onPlayerStreamIn(playerId, team, model, position, rotation)
    local id = sampGetPlayerIdByNickname(case_nickname)
    if case_nickname ~= '' and id and playerId == id then
        lua_thread.create(function()
            wait(500) -- „àåì âðåìß èãðå ñîçäàòü ped
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
    sampAddChatMessage('[Script] Ïðèâåò, Âëàäûêà ' .. nick, -1)

    
    sampAddChatMessage("{FF0000}ÏÎÈÑÊ ÊÅÉÑÎÂ {00FF00}Ãîòîâ {FF0000}ê èñïîëüçîâàíèÿ", -1)
    sampRegisterChatCommand("cases", function()
        showObjects = not showObjects
        sampAddChatMessage("ÊÅÉÑÛ " .. (showObjects and "{00FF00}Àêòèâèðîâàí" or "{FF0000}Äåàêòèâèðîâàí") , 230*65536+0*256+255)
    end)





    sampRegisterChatCommand("update", cmd_update)

	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)

    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("Åñòü îáíîâëåíèå! Âåðñèÿ: " .. updateIni.info.vers_text, -1)
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
                    sampAddChatMessage("Ñêðèïò óñïåøíî îáíîâëåí!", -1)
                    thisScript():reload()
                end
            end)
            break
        end


        if wasKeyPressed(0x7B) then 

            showObjects = not showObjects
         sampAddChatMessage("ÊÅÉÑÛ " .. (showObjects and "{00FF00}Àêòèâèðîâàí" or "{FF0000}Äåàêòèâèðîâàí") , 230*65536+0*256+255)ects = not showObjects
            
        end
        if showObjects then
            local foundObjects = {}
            for _, v in pairs(getAllObjects()) do
                local models = getObjectModel(v)
                if models == 1210 then
                    local _, x, y, z = getObjectCoordinates(v)
                    local x1, y1 = convert3DCoordsToScreen(x, y, z)
                    if x1 and y1 then -- Ïðîâåðêà, ÷òî êîîðäèíàòû íà ýêðàíå
                        -- Ñîçäàåì íîâûé îáúåêò, åñëè åãî åùå íåò
                        if not spawnedObjects[v] then
                            spawnedObjects[v] = createObject(modelll, x, y, z -1)  -- z -1 ñïàíèò íàæå ïî z íà åäèíèöó ,àíàëîãè÷íî â îáíîâëåíèè êîîðäèíàò ñóùåñòâóþùåãî îáúåêòà,ïî æåëàíèþ ìåíÿåøü êàê òåáå íàäî
                        else
                            -- Îáíîâëÿåì êîîðäèíàòû ñóùåñòâóþùåãî îáúåêòà
                            setObjectCoordinates(spawnedObjects[v], x, y, z -1)
                        end
                        foundObjects[v] = true
                    end
                end
            end
            -- Óäàëÿåì îáúåêòû, åñëè îíè áîëüøå íå âèäíû
            for obj, _ in pairs(spawnedObjects) do
                if not foundObjects[obj] then
                    deleteObject(spawnedObjects[obj])
                    spawnedObjects[obj] = nil
                end
            end
        else
            -- Óäàëÿåì âñå îáúåêòû, åñëè showObjects âûêëþ÷åí
            deleteAllSpawnedObjects()
        end



	end

    else
    sampAddChatMessage('[Script]×¸? ' .. nick .. ' íå èìååò äîñòóï ê ýòîìó ñêðèïòó.', -1)
    thisScript():unload()
    
end
end

function cmd_update(arg)
    sampShowDialog(1000, "Àâòîîáíîâëåíèå v3.0", "{FFFFFF}Ýòî óðîê ïî îáíîâëåíèþ\n{FFF000}Íîâàÿ âåðñèÿ", "Çàêðûòü", "", 0)
end

function deleteAllSpawnedObjects()
    for obj, spawnedObj in pairs(spawnedObjects) do
        deleteObject(spawnedObj)
        spawnedObjects[obj] = nil
    end
end
