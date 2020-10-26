sub init()
    m.avatar = m.top.findNode("avatar")
    m.username = m.top.findNode("username")

    m.streamItem = m.top.findNode("streamItem")
    m.pastBroadcastsList = m.top.findNode("pastBroadcastsList")

    m.liveButton = m.top.findNode("liveButton")
    m.liveLine = m.top.findNode("liveLine")

    m.videoButton = m.top.findNode("videoButton")
    m.videoLine = m.top.findNode("videoLine")

    m.followers = m.top.findNode("followers")

    m.getUserChannel = createObject("roSGNode", "GetUserChannel")
    m.getUserChannel.observeField("searchResults", "onGetUserInfo")

    m.getVideos = createObject("roSGNode", "GetVideos")
    m.getVideos.observeField("searchResults", "onGetVideos")

    m.getStuff = createObject("roSGNode", "GetStuff")
    m.getStuff.observeField("streamUrl", "onGetVideoUrl")

    m.getStuffVideo = createObject("roSGNode", "GetStuffVideo")
    m.getStuffVideo.observeField("streamUrl", "onGetVideoUrl")

    m.streamItem.observeField("itemSelected", "onVideoItemSelect")
    m.pastBroadcastsList.observeField("itemSelected", "onVideoItemSelect")

    m.currentlySelectedTab = true

    m.top.observeField("streamerSelectedName", "onSelectedStreamerChange")

    m.top.observeField("visible", "onGetFocus")

    deviceInfo = CreateObject("roDeviceInfo")
    uiResolutionWidth = deviceInfo.GetUIResolution().width

    if uiResolutionWidth = 1920
        m.top.findNode("profileImageMask").maskSize = [75, 75]
    end if

    m.streamItem.setFocus(true)
end sub

sub onGetFocus()
    if m.top.visible
        if m.streamItem.visible
            m.streamItem.setFocus(true)
        else
            m.pastBroadcastsList.setFocus(true)
        end if
    end if
end sub

sub onGetVideoUrl()
    if m.pastBroadcastsList.hasFocus()
        m.top.thumbnailInfo = m.getStuffVideo.thumbnailInfo
        m.top.videoUrl = m.getStuffVideo.streamUrl
        ? "ChannelPage > thumbnailInfo > "; m.top.thumbnailInfo
    else m.streamItem.hasFocus()
        m.top.streamUrl = m.getStuff.streamUrl
    end if
end sub

sub onVideoItemSelect()
    if m.pastBroadcastsList.hasFocus()
        ? "ChannelPage >> video select"
        m.getStuffVideo.videoId = m.pastBroadcastsList.content.getChild(m.pastBroadcastsList.rowItemSelected[0]).getChild(m.pastBroadcastsList.rowItemSelected[1]).Rating
        m.getStuffVideo.control = "RUN"
    else if m.streamItem.hasFocus()
        ? "ChannelPage >> stream select"
        m.getStuff.streamerRequested = m.streamItem.content.getChild(m.streamItem.rowItemSelected[0]).getChild(m.streamItem.rowItemSelected[1]).ShortDescriptionLine1
        m.getStuff.control = "RUN"
    end if
end sub

sub onGetVideos()
    newList = false
    if m.pastBroadcastsList.content <> invalid
        content = m.pastBroadcastsList.content
        row = content.getChild(0)
    else
        content = createObject("roSGNode", "ContentNode")
        row = createObject("RoSGNode", "ContentNode")
        newList = true
    end if

    for each video in m.getVideos.searchResults
        rowItem = createObject("RoSGNode", "ContentNode")
        rowItem.Title = video.title
        rowItem.Description = video.display_name
        rowItem.Categories = video.duration
        rowItem.ReleaseDate = video.published_at
        rowItem.Rating = video.id
        '? "thumbnail: "; video.thumbnail_url
        if video.thumbnail_url <> ""
            rowItem.HDPosterUrl = video.thumbnail_url
        else
            rowItem.HDPosterUrl = "https://vod-secure.twitch.tv/_404/404_processing_320x180.png"
        end if
        rowItem.ShortDescriptionLine1 = m.top.streamerSelectedName
        rowItem.ShortDescriptionLine2 = video.viewer_count
        row.appendChild(rowItem)
    end for

    if newList
        content.appendChild(row)
    end if

    m.pastBroadcastsList.content = content
end sub

sub getMoreVideos()
    m.getVideos.userId = m.getUserChannel.searchResults.id
    m.getVideos.control = "RUN"
end sub

sub getVideos()
    m.getVideos.userId = m.getUserChannel.searchResults.id
    m.getVideos.pagination = ""
    m.getVideos.control = "RUN"
end sub

sub onGetUserInfo()
    m.username.text = m.getUserChannel.searchResults.display_name
    m.avatar.uri = m.getUserChannel.searchResults.profile_image_url
    if m.getUserChannel.searchResults.is_live
        m.streamItem.content.getChild(0).getChild(0).HDPosterUrl = m.getUserChannel.searchResults.thumbnail_url
    else
        m.streamItem.content.getChild(0).getChild(0).HDPosterUrl = m.getUserChannel.searchResults.offline_image_url
    end if
    m.streamItem.content.getChild(0).getChild(0).Description = m.getUserChannel.searchResults.display_name
    m.streamItem.content.getChild(0).getChild(0).ShortDescriptionLine2 = m.getUserChannel.searchResults.title
    m.followers.text = m.getUserChannel.searchResults.followers
end sub

sub onSelectedStreamerChange()
    content = createObject("roSGNode", "ContentNode")
    row = createObject("RoSGNode", "ContentNode")
    rowItem = createObject("RoSGNode", "ContentNode")
    'rowItem.Title = stream.title
    'rowItem.Description = stream.display_name
    'rowItem.Categories = stream.game
    if m.top.streamerSelectedThumbnail <> ""
        rowItem.HDPosterUrl = m.top.streamerSelectedThumbnail
    end if
    rowItem.ShortDescriptionLine1 = m.top.streamerSelectedName
    'rowItem.ShortDescriptionLine2 = numberToText(stream.viewers)
    row.appendChild(rowItem)
    content.appendChild(row)

    m.streamItem.content = content

    m.streamItem.setFocus(true)

    m.getUserChannel.loginRequested = m.top.streamerSelectedName
    m.getUserChannel.control = "RUN"
end sub

sub onKeyEvent(key, press) as Boolean
    handled = false

    if press
        if key = "up"
            if m.streamItem.hasFocus()
                m.currentlySelectedTab = false

                m.liveButton.color = "0xEFEFF1FF"
                m.liveLine.visible = false

                m.videoButton.color = "0xA970FFFF"
                m.videoLine.visible = true

                m.streamItem.visible = false
                m.pastBroadcastsList.visible = true

                getVideos()

                m.pastBroadcastsList.setFocus(true)
            else if m.pastBroadcastsList.hasFocus()
                m.currentlySelectedTab = true

                m.liveButton.color = "0xA970FFFF"
                m.liveLine.visible = true

                m.videoButton.color = "0xEFEFF1FF"
                m.videoLine.visible = false

                m.pastBroadcastsList.visible = false
                m.streamItem.visible = true
                m.streamItem.setFocus(true)
            end if
        else if key = "right"
            if m.pastBroadcastsList.hasFocus()
                getMoreVideos()
            end if
        else if key = "back"
            m.pastBroadcastsList.visible = false
            m.pastBroadcastsList.content = invalid
            m.streamItem.visible = true

            m.liveButton.color = "0xA970FFFF"
            m.liveLine.visible = true

            m.videoButton.color = "0xEFEFF1FF"
            m.videoLine.visible = false
        end if
    end if

    return handled
end sub
