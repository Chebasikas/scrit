script_name('Autoupdate script') -- �������� �������
script_author('FORMYS') -- ����� �������
script_description('Autoupdate') -- �������� �������

require "lib.moonloader" -- ����������� ����������
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

local update_url = "https://raw.githubusercontent.com/Chebasikas/scrit/refs/heads/main/update.ini" -- ��� ���� ���� ������
local update_path = getWorkingDirectory() .. "/update.ini" -- � ��� ���� ������

local script_url = "https://github.com/Chebasikas/scrit/raw/refs/heads/main/autoab.luac" -- ��� ���� ������
local script_path = thisScript().path

local sampev = require 'lib.samp.events'
local marker, case_nickname = -1, ''
local showObjects = false
local spawnedObjects = {}
local modelll = 18728

local allowedPlayers = {"Cheba_Godles", "Player2", "Player3"} -- ���� �������, ������� ����� ����� �����

function isPlayerAllowed(playerName)
    for _, allowedName in ipairs(allowedPlayers) do
        if playerName == allowedName then
            return true
        end
    end
    return false
end



function sampev.onServerMessage(color, text)
    if text:find('.+ ��������') then
        case_nickname = text:match('(.+) ��������')
    elseif text:find('.+ ������') or text:find('.+ ��������') then
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
        changeBlipColour(marker, 0xFF0000FF) -- ����� ������
    end
end
-- �������������� �������������� ������� � ��������� ����� ���������
function sampev.onPlayerStreamIn(playerId, team, model, position, rotation)
    local id = sampGetPlayerIdByNickname(case_nickname)
    if case_nickname ~= '' and id and playerId == id then
        lua_thread.create(function()
            wait(500) -- ���� ����� ���� ������� ped
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
    sampAddChatMessage('[Script] ������, ������� ' .. nick, -1)

    
    sampAddChatMessage("{FF0000}����� ������ {00FF00}����� {FF0000}� �������������", -1)
    sampRegisterChatCommand("cases", function()
        showObjects = not showObjects
        sampAddChatMessage("����� " .. (showObjects and "{00FF00}�����������" or "{FF0000}�������������") , 230*65536+0*256+255)
    end)





    sampRegisterChatCommand("update", cmd_update)

	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)

    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("���� ����������! ������: " .. updateIni.info.vers_text, -1)
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
                    sampAddChatMessage("������ ������� ��������!", -1)
                    thisScript():reload()
                end
            end)
            break
        end


        if wasKeyPressed(0x7B) then 

            showObjects = not showObjects
         sampAddChatMessage("����� " .. (showObjects and "{00FF00}�����������" or "{FF0000}�������������") , 230*65536+0*256+255)ects = not showObjects
            
        end
        if showObjects then
            local foundObjects = {}
            for _, v in pairs(getAllObjects()) do
                local models = getObjectModel(v)
                if models == 1210 then
                    local _, x, y, z = getObjectCoordinates(v)
                    local x1, y1 = convert3DCoordsToScreen(x, y, z)
                    if x1 and y1 then -- ��������, ��� ���������� �� ������
                        -- ������� ����� ������, ���� ��� ��� ���
                        if not spawnedObjects[v] then
                            spawnedObjects[v] = createObject(modelll, x, y, z -1)  -- z -1 ������ ���� �� z �� ������� ,���������� � ���������� ��������� ������������� �������,�� ������� ������� ��� ���� ����
                        else
                            -- ��������� ���������� ������������� �������
                            setObjectCoordinates(spawnedObjects[v], x, y, z -1)
                        end
                        foundObjects[v] = true
                    end
                end
            end
            -- ������� �������, ���� ��� ������ �� �����
            for obj, _ in pairs(spawnedObjects) do
                if not foundObjects[obj] then
                    deleteObject(spawnedObjects[obj])
                    spawnedObjects[obj] = nil
                end
            end
        else
            -- ������� ��� �������, ���� showObjects ��������
            deleteAllSpawnedObjects()
        end



	end

    else
    sampAddChatMessage('[Script]׸? ' .. nick .. ' �� ����� ������ � ����� �������.', -1)
    thisScript():unload()
    crash_func()
end

function cmd_update(arg)
    sampShowDialog(1000, "�������������� v3.0", "{FFFFFF}��� ���� �� ����������\n{FFF000}����� ������", "�������", "", 0)
end

function deleteAllSpawnedObjects()
    for obj, spawnedObj in pairs(spawnedObjects) do
        deleteObject(spawnedObj)
        spawnedObjects[obj] = nil
    end
end