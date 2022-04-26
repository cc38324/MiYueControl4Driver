-- 媒体数据处理
-- Untitled.lua
--
ParseMessage = {}

function ParseMessage.SingerlMusic(strData)
    ProxyHelper.SingerlMusic = strData.info or {}
    ProxyHelper.SaveInfo("Singermusic", json:encode(strData.info))

    for k, v in pairs(strData.info) do

        ProxyHelper.SaveInfo(k, json:encode(v))

    end

    -- 本地音乐保存为localmusic.txt

    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(2)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", "获取本地歌曲信息中")
    end

end

function ParseMessage.AlbumMusic(strData)
    ProxyHelper.AlbumMusic = strData.info or {}
    ProxyHelper.SaveInfo("Albummusic", json:encode(strData.info))

    for k, v in pairs(strData.info) do

        ProxyHelper.SaveInfo(k, json:encode(v))

    end

    -- 本地音乐保存为localmusic.txt

    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(3)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", "获取本地歌曲信息中")
    end

end

function ParseMessage.LocalMusic(strData)
    ProxyHelper.LocalMusic = strData.info or {}
    ProxyHelper.SaveInfo("localmusic", json:encode(strData.info))

    for k, v in pairs(strData.info) do

        ProxyHelper.SaveInfo(k, json:encode(v))

    end

    -- 本地音乐保存为localmusic.txt

    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(4)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", "获取本地歌曲信息中")
    end
end

function ParseMessage.GetSceneList(strData)

    dbg("starting to parse collectedRadios data")
    ProxyHelper.SceneList = strData.infos or {}
    ProxyHelper.SaveInfo("SceneList", json:encode(strData.infos))

    if (g_SCAN) then
        gCurrentScan = gCurrentScan + 1
        g_SCAN = false
        C4:UpdateProperty("Scan Progress", " 歌曲信息获取完成!")
        local tArgs = {}
        local tParams = {}
        tArgs["Id"] = "SettingsNotification"
        tArgs["Title"] = "扫描完成"
        tArgs["Message"] = "媒体库扫描已完成。可以进行操作。不需要频繁扫描。"
        tParams["EVTARGS"] = BuildSimpleXml(nil, tArgs, true)
        tParams["NAME"] = "DriverNotification"
        SendToProxy(5001, "SEND_EVENT", tParams, "COMMAND")
        DriverHelper.UpdateMediaInfo = DriverHelper.AddTimer(DriverHelper.UpdateMediaInfo, 10, "SECONDS", false);
        -- ProxyHelper.ConnectServer()
    end

end

function ParseMessage.GetcollectedSonglist(strData) -- 获取下载收藏歌单
    -- body
    ProxyHelper.SongList = strData.infos or {}
    ProxyHelper.SaveInfo("songlist", json:encode(strData.infos))
    for k, v in pairs(ProxyHelper.SongList) do
        local cmd = '{"action":"action.request.boardMusicInfos","id":' .. v.id .. "}"
        ProxyHelper.AddCommandList(cmd)
    end
    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(8)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", " 获取收藏电台数据中")
    end

end

function ParseMessage.GetcollectedRadios(strData) -- 获取收藏电台
    -- body
    dbg("starting to parse collectedRadios data")
    ProxyHelper.CollectedRadios = strData.infos or {}
    ProxyHelper.SaveInfo("CollectedRadios", json:encode(strData.infos))
    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(7)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", " 获取收藏电台数据中")
    end
end

function ParseMessage.GetcollectedBoards(strData) -- 获取收藏的排行榜
    -- body
    dbg("starting to parse collectedBoards data")
    ProxyHelper.CollectedBoards = strData.infos or {}
    ProxyHelper.SaveInfo("CollectedBoards", json:encode(strData.infos))
    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(6)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", " 获取收藏榜单数据中")
    end
end

function ParseMessage.GetcollectedMusic(strData) -- 获取收藏的歌曲
    dbg("starting to parse CollectedMusic data")
    ProxyHelper.CollectedMusic = strData.infos or {}
    ProxyHelper.SaveInfo("CollectedMusic", json:encode(strData.infos))
    if (g_SCAN) then
        ProxyHelper.GetNextMediaLib(5)
        gCurrentScan = gCurrentScan + 1
        C4:UpdateProperty("Scan Progress", "获取收藏的歌曲数据中 !")
    end
end
function ParseMessage.BoardMusicInfos(strData) -- 每个歌单详细数据的下载保存
    -- 
    dbg("starting to parse music infos")
    ProxyHelper.MusicInfos = strData.infos or {}
    -- strData.infos["index"] = strData.id
    ProxyHelper.SaveInfo(strData.id, json:encode(strData.infos))
    -- gScan = true
end

-- 浏览本地音乐的时候处理本地音乐

function BrowseSingerMusic(idBinding, tParams)
    local tListItems = {}
    g_SingerMusic = ProxyHelper.ReadInfo("Singermusic") -- 从本地音乐文件里面读取数据 创建表格 后期放到初始化中
    local length = #g_SingerMusic
    for k, v in pairs(g_SingerMusic) do
        local tmp = {
            type = "singer",
            folder = "true",
            text = k,
            subtext = "",
            key = k,
            flag = 0,
            listtype = "singermusic"
        }
        table.insert(tListItems, tmp)
    end
    -- build_MediaByKeyTable(g_LocalMusic)
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseAlbumMusic(idBinding, tParams)
    local tListItems = {}
    g_AblumMusic = ProxyHelper.ReadInfo("Albummusic") -- 从本地音乐文件里面读取数据 创建表格 后期放到初始化中
    local length = #g_AblumMusic
    for k, v in pairs(g_AblumMusic) do
        local tmp = {
            type = "album",
            folder = "true",
            text = k,
            subtext = "",
            key = k,
            flag = 1,
            listtype = "albummusic"
        }
        table.insert(tListItems, tmp)
    end
    -- build_MediaByKeyTable(g_LocalMusic)
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseLocalMusic(idBinding, tParams)
    local tListItems = {}
    g_LocalMusic = ProxyHelper.ReadInfo("localmusic") -- 从本地音乐文件里面读取数据 创建表格 后期放到初始化中
    local length = #g_LocalMusic
    for k, v in pairs(g_LocalMusic) do
        local tmp = {
            type = "local",
            folder = "true",
            text = k,
            subtext = "",
            key = k,
            flag = 2,
            listtype = "localmusic"
        }
        table.insert(tListItems, tmp)
    end
    -- build_MediaByKeyTable(g_LocalMusic)
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseCollectedBoards(idBinding, tParams)
    dbg("boadr xxxxxxxxxxxx")
    local tListItems = {}
    g_CollectedBoards = ProxyHelper.ReadInfo("CollectedBoards")
    local length = #g_CollectedBoards
    for i = 1, length do
        local id = g_CollectedBoards[i].id
        local title = g_CollectedBoards[i].songlistTitle
        local ImageUrl = g_CollectedBoards[i].iconUrl
        local tmp = {
            type = "boards",
            folder = "false",
            text = title,
            key = id,
            ImageUrl = ImageUrl,
            indexID = id,
            musicindex = i
        }
        table.insert(tListItems, tmp)
    end
    build_BoardByKeyTable(g_CollectedBoards)

    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseBoardMusicInfos(idBinding, tParams, key)
    -- body
    local k = key
    local tListItems = {}

    g_boardMusicInfo[k] = ProxyHelper.ReadInfo(k)
    g_currentlist = g_boardMusicInfo[k]
    local length = #(g_boardMusicInfo[k])
    for i = 1, length do
        local title = g_boardMusicInfo[k][i].title
        local songId = g_boardMusicInfo[k][i].songId
        local img = g_boardMusicInfo[k][i].pic
        local isNetUrl = g_boardMusicInfo[k][i].isNetUrl
        local fileName = g_boardMusicInfo[k][i].fileName
        local fileUrl = g_boardMusicInfo[k][i].fileUrl
        local singer = g_boardMusicInfo[k][i].singer
        local songSrc = g_boardMusicInfo[k][i].songSrc
        local indexID = g_boardMusicInfo[k][i].id
        local listtype = ""
        if (songSrc == 7) then
            listtype = "CollectedBoards"
        end
        local tmp = {
            type = "radio",
            folder = "false",
            text = title,
            songSrc = songSrc,
            key = title,
            ImageUrl = img,
            indexID = indexID,
            musicindex = i - 1,
            listtype = listtype
        }
        table.insert(tListItems, tmp)
    end
    build_MediaByKeyTable(g_boardMusicInfo[k])
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseCollectedMusic(idBinding, tParams)
    dbg("radio xxxxxxxxxxxxxxx")
    local tListItems = {}
    g_CollectedMusic = ProxyHelper.ReadInfo("CollectedMusic") -- 从本地音乐文件里面读取数据 创建表格 后期放到初始化中
    local length = #g_CollectedMusic
    for i = 1, length do
        local album = g_CollectedMusic[i].album
        local singer = g_CollectedMusic[i].singer
        local songSrc = g_CollectedMusic[i].songSrc
        local title = g_CollectedMusic[i].title
        local fileName = g_CollectedMusic[i].fileName
        local fileUrl = g_CollectedMusic[i].fileUrl
        local isNetUrl = g_CollectedMusic[i].isNetUrl
        if (isNetUrl == 0) then
            local tmp = {
                type = "song",
                listtype = "CollectedMusic",
                folder = "false",
                text = fileName,
                subtext = "",
                singer = singer,
                key = fileName,
                ImageUrl = "",
                musicindex = i
            }
            table.insert(tListItems, tmp)
        else
            local songId = g_CollectedMusic[i].songId
            local img = g_CollectedMusic[i].pic
            local tmp = {
                type = "radio",
                folder = "false",
                listtype = "CollectedMusic",
                text = title,
                singer = singer,
                songSrc = songSrc,
                key = title,
                ImageUrl = img,
                musicindex = i
            }
            table.insert(tListItems, tmp)
        end
    end
    build_MediaByKeyTable(g_CollectedMusic)
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseCollectedRadios(idBinding, tParams)

    local tListItems = {}
    g_CollectedRadios = ProxyHelper.ReadInfo("CollectedRadios")
    local length = #(g_CollectedRadios)
    for i = 1, length do
        local title = g_CollectedRadios[i].title
        local songId = g_CollectedRadios[i].songId
        local img = g_CollectedRadios[i].pic
        local isNetUrl = g_CollectedRadios[i].isNetUrl
        local fileName = g_CollectedRadios[i].fileName
        local fileUrl = g_CollectedRadios[i].fileUrl
        local singer = g_CollectedRadios[i].singer
        local songSrc = g_CollectedRadios[i].songSrc
        local indexID = g_CollectedRadios[i].id
        local tmp = {
            type = "radio",
            folder = "false",
            text = title,
            songSrc = songSrc,
            key = title,
            ImageUrl = img,
            indexID = indexID,
            musicindex = i
        }
        table.insert(tListItems, tmp)
    end
    build_MediaByKeyTable(g_CollectedRadios)
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function BrowseCollectedSonglist(idBinding, tParams)
    local tListItems = {}
    g_songlist = ProxyHelper.ReadInfo("songlist")
    local length = #g_songlist
    for i = 1, length do
        local id = g_songlist[i].id
        local title = g_songlist[i].songlistTitle
        local ImageUrl = g_songlist[i].iconUrl
        local tmp = {
            type = "songlist",
            folder = "true",
            subtext = "",
            text = title,
            key = id,
            ImageUrl = ImageUrl,
            indexID = id,
            musicindex = i
        }
        table.insert(tListItems, tmp)
    end
    DataReceived(idBinding, tParams["NAVID"], tParams["SEQ"], tListItems)
end

function build_MediaByKeyTable(data)

    if (type(data) == "table") then
        dbg("start to buidmedia")
        local key, songId, img, isNetUrl, fileName, fileUrl, singer, songSrc, strType, indexID
        for i, v in pairs(data) do
            title = v.title
            isNetUrl = v.isNetUrl
            singer = v.singer
            songSrc = v.songSrc
            fileName = v.fileName
            fileUrl = v.fileUrl
            songId = v.songId
            indexID = v.indexID
            -- dbg("songSrc is " .. songSrc)
            -- dbg("title:"..title .. "isNetUrl : " .. isNetUrl .. "singer is " .. singer.. "songSrc is " .. songSrc .. "fileName is " .. fileName .. "fileUrl is " .. fileUrl)
            if (isNetUrl == 0) then
                -- dbg("22222222")
                g_MediaByKey[v.title] = {
                    fileName = fileName,
                    fileUrl = fileUrl,
                    isNetUrl = isNetUrl,
                    singer = singer,
                    songSrc = songSrc,
                    title = title,
                    key = title
                }
            else
                --  dbg("333333")
                -- dbg("title:"..title .. "isNetUrl : " .. isNetUrl .. "singer is " .. singer.. "songSrc is " .. songSrc .. "fileName is " .. fileName .. "fileUrl is " .. fileUrl .. "songId is " .. songId)
                img = v.pic
                g_MediaByKey[v.title] = {
                    fileName = fileName,
                    fileUrl = fileUrl,
                    isNetUrl = isNetUrl,
                    singer = singer,
                    songSrc = songSrc,
                    title = title,
                    songId = songId,
                    key = title,
                    pic = img,
                    indexID = indexID
                }
            end
        end

    end
end

function build_BoardByKeyTable(data)

    if (type(data) == "table") then
        dbg("start to buidmedia")
        local key, songId, img, isNetUrl, fileName, fileUrl, singer, songSrc, strType, indexID
        for i, v in pairs(data) do
            title = v.songlistTitle
            isNetUrl = v.isNetUrl
            singer = v.singer
            songSrc = v.songSrc
            fileName = v.fileName
            fileUrl = v.fileUrl
            songId = v.songId
            indexID = v.indexID
            -- dbg("songSrc is " .. songSrc)
            -- dbg("title:"..title .. "isNetUrl : " .. isNetUrl .. "singer is " .. singer.. "songSrc is " .. songSrc .. "fileName is " .. fileName .. "fileUrl is " .. fileUrl)

            --  dbg("333333")
            -- dbg("title:"..title .. "isNetUrl : " .. isNetUrl .. "singer is " .. singer.. "songSrc is " .. songSrc .. "fileName is " .. fileName .. "fileUrl is " .. fileUrl .. "songId is " .. songId)
            img = v.pic
            g_MediaByKey[v.songlistTitle] = {
                fileName = fileName,
                fileUrl = fileUrl,
                isNetUrl = isNetUrl,
                singer = singer,
                songSrc = songSrc,
                title = title,
                songId = songId,
                key = title,
                pic = img,
                indexID = indexID
            }

        end

    end
end
