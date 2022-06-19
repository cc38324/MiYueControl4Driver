-- 播放器反馈数据处理
-- Untitled.lua
--
gCurrentVolume = 0
tmpQueue = ""

playType = {
    ListRepeatOn = 0,
    SingleRepeatOn = 1,
    RepeatOn = 3,
    ShuffleOn = 2
}
function ParseFeedback(strData)
    -- body

    dbg("Begin to Parse DATA" .. strData)

    local response = json:decode(strData)
    ProxyHelper.TCPReceiveBuf = ""

    if (response.result == 400) then
        return
    end
    if (response.result == 200) then
        local msg_id = {
            ["action.request.collectedMusic"] = "GetcollectedMusic",
            ["action.request.collectedBoards"] = "GetcollectedBoards",
            ["action.request.collectedRadios"] = "GetcollectedRadios",
            ["action.request.collectedSonglist"] = "GetcollectedSonglist",
            ["action.request.boardMusicInfos"] = "BoardMusicInfos",
            ["action.response.sensorlist"] = "GetSceneList"
        }

        if (response.action == "action.get.classifiedLocalmusic") then
            if (response.flag == 0) then
                ParseMessage.SingerlMusic(response)

            elseif (response.flag == 1) then
                ParseMessage.AlbumMusic(response)

            elseif (response.flag == 2) then
                ParseMessage.LocalMusic(response)
            end
        end

        if (type(ParseMessage[msg_id[response.action]]) == "function") then

            ParseMessage[msg_id[response.action]](response)

        end

        if (response.action == "action.response.localMusicChanged") then

            for i = 1, 3 do
                C4:SetTimer(2000, function(oTimer)
                    ProxyHelper.GetNextMediaLib(i)
                end, false)

            end
            -- g_SCAN = true
        end

        if (response.action == "action.response.netMusicUpdateComplete") then
            ProxyHelper.Scan()
        end

        if (response.action == "action.response.currentMusicList") then

        end

        if (response.action == "action.response.sensorlist") then
            -- ProxyHelper.GetNextMediaLib(8)
        end

        if (response.action == "action.response.playerposition") then

            local volume = math.floor(tonumber(response.volumeValue))
            if (gCurrentVolume ~= volume) then
                -- UpdateVolume(gCurrentVolume)
                gCurrentVolume = volume
                UpdateVolume(gCurrentVolume)
            end

            if (response.isPlaying) then
                for k, v in pairs(playType) do
                    if v == response.playType then
                        gPlaytype = k
                    end
                end

                DashboardChanged("PLAY")

                if (gQueues["STATE"] ~= "PLAY") then
                    gQueues["STATE"] = "PLAY"
                end

            else
                DashboardChanged("PAUSE")
                gQueues["STATE"] = "PAUSE"
                -- gCurrentSongTitle = ""
            end

            local SongTitle = response.info.title
            if (gCurrentSongTitle == SongTitle) then
                return
            else
                gCurrentSongTitle = SongTitle
            end

            -- for k, v in pairs(gNowPlaying) do
            --     if (gCurrentSongTitle == v.Title) then
            --         gCurrentSongIndex = k
            --     end
            -- end

            local img = response.info.pic
            local title = response.info.title
            local singer = response.info.singer
            UpdateMediaInfo(5001, title, singer, "", "", img, g_RoomID, "secondary", "True")

            if (tonumber(response.musicIndex) < 0) then
                -- local queue = response.info
                -- 

                -- for k, v in pairs() do
                --     gNowPlaying[k] = {
                --         Title = v.title,
                --         fileName = v.fileName,
                --         songSrc = v.songSrc,
                --         singer = v.singer,
                --         ImageUrl = v.pic,
                --         songId = v.songId,
                --         fileUrl = v.fileUrl,
                --         Id = k - 1
                --     }
                -- end
                local queue = {}

                table.insert(queue, 1, {
                    title = response.info.title,
                    pic = response.info.pic
                })

                local List = BuildListXml(queue, true)

                C4:SetTimer(2000, function(oTimer)
                    QueueChanged(5001, nil, g_RoomID, List)

                end, false)

            end

        elseif (response.action == "action.request.musiclist") then

            -- local Nowplaylist = {}
            -- if (gNowPlaying[1] ~= nil) then
            gNowPlaying = {}
            -- gCurrentSongIndex = 1	
            -- end

            for k, v in pairs(response.infos) do
                gNowPlaying[k] = {
                    title = v.title,
                    fileName = v.fileName,
                    songSrc = v.songSrc,
                    singer = v.singer,
                    pic = v.pic,
                    songId = v.songId,
                    fileUrl = v.fileUrl,
                    Id = k - 1,
                    isNetUrl = v.isNetUrl
                }

                if (gCurrentSongTitle == v.title) then
                    gCurrentSongIndex = k
                end
            end

            -- UpdateMediaInfo(5001, gNowPlaying[gCurrentSongIndex].Title, gNowPlaying[gCurrentSongIndex].singer, "", "",
            --     gNowPlaying[gCurrentSongIndex].ImageUrl, g_RoomID, "secondary", "True")
            C4:SetTimer(2000, function(oTimer)
                local data = CacheNowPlaying()
                QueueChanged(5001, nil, g_RoomID, data)

            end, false)

        elseif (response.action == "action.collect.musics") then

            ProxyHelper.GetNextMediaLib(4)

        elseif (response.action == "action.response.collectDataChanged") then
            local flag = tonumber(response.flag)
            if (flag == -1) then
                ProxyHelper.GetNextMediaLib(4)
            elseif (flag == -2) then
                ProxyHelper.GetNextMediaLib(6)
            elseif (flag == -3) then
                ProxyHelper.GetNextMediaLib(5)
            elseif (flag == -4) then
                g_GetColl = false
                ProxyHelper.GetNextMediaLib(7)
            elseif (flag > 0) then
                local cmd = '{"action":"action.request.boardMusicInfos","id":' .. flag .. "}"
                ProxyHelper.AddCommandList(cmd)

            end

        elseif (response.action == "action.request.getVolume") then
            gCurrentVolume = math.floor(tonumber(response.volumeValue))
            UpdateVolume(gCurrentVolume)
        elseif (response.action == "action.request.changeVolume") then
            -- GetCurrentVolume()
            gCurrentVolume = math.floor(tonumber(response.volumeValue))
            UpdateVolume(gCurrentVolume)

        end

    end
end

function CacheNowPlaying()
    local queue = {}

    queue = gNowPlaying
    -- print("gNOWPLAYING IS :" .. #gNowPlaying)
    -- if (#gNowPlaying < 6) then

    --     for i = 1, #gNowPlaying do
    --         -- gNowPlaying[gCurrentSongIndex + i -1].ImageUrl = nil
    --         queue[i] = gNowPlaying[gCurrentSongIndex + i - 1]
    --     end
    -- else
    --     for i = 1, 5 do
    --         -- gNowPlaying[gCurrentSongIndex + i -1].ImageUrl = nil
    --         queue[i] = gNowPlaying[gCurrentSongIndex + i + 1]
    --     end
    -- end

    -- print("queue leng is " ..#queue
    -- PrintTable(queue)

    -- if (#queue > 1) then

    --     -- table.insert(queue, 1, {
    --     --     Title = '当前播放歌曲',
    --     --     isHeader = "true"
    --     -- })
    --     table.insert(queue, 3, {
    --         Title = '下一首歌曲',
    --         isHeader = "true"
    --     })
    -- else
    --     table.insert(queue, 1, {
    --         Title = '当前播放歌曲',
    --         isHeader = "true"
    --     })
    -- end

    local List = BuildListXml(queue, true)
    local NowPlayingIndex = BuildSimpleXml(nil, {
        ["NowPlayingIndex"] = gCurrentSongIndex - 1
    })
    local data = NowPlayingIndex .. List
    tmpQueue = data

    return tmpQueue
end
