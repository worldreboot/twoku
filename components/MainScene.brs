'api.twitch.tv/api/channels/${user}/access_token?client_id=jzkbprff40iqj646a697cyrvl0zt2m6
'usher.ttvnw.net/api/channel/hls/${user}.m3u8?allow_source=true&allow_spectre=true&type=any&token=${token}&sig=${sig}

function init()
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.keyboardGroup = m.top.findNode("keyboardGroup")
    m.homeScene = m.top.findNode("homeScene")
    m.categoryScene = m.top.findNode("categoryScene")
    m.channelPage = m.top.findNode("channelPage")

    m.keyboardGroup.observeField("streamUrl", "onStreamChange")
    m.keyboardGroup.observeField("streamerSelectedName", "onStreamerSelected")

    m.homeScene.observeField("streamUrl", "onStreamChange")
    m.homeScene.observeField("streamerSelectedName", "onStreamerSelected")
    m.homeScene.observeField("categorySelected", "onCategoryItemSelect")
    m.homeScene.observeField("buttonPressed", "onHeaderButtonPress")

    m.keyboardGroup.observeField("categorySelected", "onCategoryItemSelectFromSearch")

    m.categoryScene.observeField("streamUrl", "onStreamChange")
    m.categoryScene.observeField("streamerSelectedThumbnail", "onStreamerSelected")
    m.categoryScene.observeField("clipUrl", "onClipChange")

    m.channelPage.observeField("videoUrl", "onStreamChangeFromChannelPage")
    m.channelPage.observeField("streamUrl", "onStreamChange")

    m.top.backgroundColor = "0x18181BFF"
    m.top.backgroundUri = ""

    m.currentScene = "home"
    m.lastScene = ""
    m.lastLastScene = ""

    m.stream = createObject("RoSGNode", "ContentNode")
    m.stream["streamFormat"] = "hls"

    m.getToken = createObject("roSGNode", "GetToken")
    m.getToken.observeField("appBearerToken", "onBearerTokenReceived")
    m.getToken.control = "RUN"

    m.login = ""
    m.getUser = createObject("roSGNode", "GetUser")
    m.getUser.observeField("searchResults", "onUserLogin")

    m.testtimer = m.top.findNode("testTimer")
    m.testtimer.control = "start"
    m.testtimer.ObserveField("fire", "refreshFollows")

    getAuth = createObject("RoSGNode", "GetAuth")
    getAuth.control = "RUN"

    loggedInUser = checkIfLoggedIn()
    if loggedInUser <> invalid
        m.getUser.loginRequested = loggedInUser
        m.getUser.control = "RUN"
        m.login = loggedInUser
    end if

    videoQuality = checkSavedVideoQuality()
    if videoQuality <> invalid
        m.global.addFields({videoQuality: Int(Val(videoQuality))})
    else
        m.global.addFields({videoQuality: 2})
    end if

    videoFramerate = checkSavedVideoFramerate()
    if videoQuality <> invalid
        m.global.addFields({videoFramerate: Int(Val(videoFramerate))})
    else
        m.global.addFields({videoFramerate: 60})
    end if

    chatOption = checkSavedChatOption()
    if chatOption <> invalid and chatOption = "true"
        m.global.addFields({chatOption: true})
    else
        m.global.addFields({chatOption: false})
    end if

    videoBookmarks = checkVideoBookmarks()
    ? "MainScene >> videoBookmarks > " videoBookmarks
    if videoBookmarks <> ""
        'm.videoPlayer.videoBookmarks = {}
        m.videoPlayer.videoBookmarks = ParseJSON(videoBookmarks)
        ? "MainScene >> ParseJSON > " m.videoPlayer.videoBookmarks
    else
        m.videoPlayer.videoBookmarks = {}
    end if

    ? "MainScene >> registry space > " createObject("roRegistry").GetSpaceAvailable()

    m.chat = m.top.findNode("chat")

    m.options = createObject("roSGNode", "Options")
    m.options.visible = false

    m.top.appendChild(m.options)

    m.homeScene.setFocus(true)
end function

sub onBearerTokenReceived()
    m.global.addFields({appBearerToken: m.getToken.appBearerToken})
end sub

sub onStreamChangeFromChannelPage()
    m.stream["streamFormat"] = "hls"
    m.stream["url"] = m.channelPage.videoUrl
    m.chat.visible = false

    m.videoPlayer.width = 0
    m.videoPlayer.height = 0
    m.videoPlayer.setFocus(true)
    
    m.keyboardGroup.visible = false
    m.channelPage.visible = false
    
    m.videoPlayer.visible = true
    m.videoPlayer.content = m.stream
    m.videoPlayer.thumbnailInfo = m.channelPage.thumbnailInfo
    m.channelPage.thumbnailInfo = invalid
    m.videoPlayer.control = "play"
    if m.videoPlayer.thumbnailInfo <> invalid
        if m.videoPlayer.videoBookmarks.DoesExist(m.videoPlayer.thumbnailInfo.video_id.ToStr())
            ? "MainScene >> position > " m.videoPlayer.videoBookmarks[m.videoPlayer.thumbnailInfo.video_id.ToStr()]
            m.videoPlayer.seek = Val(m.videoPlayer.videoBookmarks[m.videoPlayer.thumbnailInfo.video_id.ToStr()])
        end if
    end if
end sub

sub onStreamerSelected()
    if m.homeScene.visible
        m.channelPage.streamerSelectedName = m.homeScene.streamerSelectedName
        m.channelPage.streamerSelectedThumbnail = m.homeScene.streamerSelectedThumbnail
        m.lastScene = "home"
    else if m.categoryScene.visible
        m.channelPage.streamerSelectedName = m.categoryScene.streamerSelectedName
        m.channelPage.streamerSelectedThumbnail = m.categoryScene.streamerSelectedThumbnail
        m.lastLastScene = m.lastScene
        m.lastScene = "category"
    else if m.keyboardGroup.visible
        m.channelPage.streamerSelectedName = m.keyboardGroup.streamerSelectedName
        m.channelPage.streamerSelectedThumbnail = ""
        m.lastLastScene = "home"
        m.lastScene = "search"
    end if
    m.homeScene.visible = false
    m.keyboardGroup.visible = false
    m.categoryScene.visible = false

    m.channelPage.visible = true

    m.currentScene = "channel"
end sub

function checkVideoBookmarks()
    sec = createObject("roRegistrySection", "VideoSettings")
    if sec.Exists("VideoBookmarks")
        return sec.Read("VideoBookmarks")
    end if
    return ""
end function

function checkSavedChatOption()
    sec = createObject("roRegistrySection", "VideoSettings")
    if sec.Exists("ChatOption")
        return sec.Read("ChatOption")
    end if
    return invalid
end function

function checkSavedVideoFramerate()
    sec = createObject("roRegistrySection", "VideoSettings")
    if sec.Exists("VideoFramerate")
        return sec.Read("VideoFramerate")
    end if
    return invalid
end function

function checkSavedVideoQuality()
    sec = createObject("roRegistrySection", "VideoSettings")
    if sec.Exists("VideoQuality")
        return sec.Read("VideoQuality")
    end if
    return invalid
end function

function checkIfLoggedIn() as Dynamic
    sec = createObject("roRegistrySection", "LoggedInUserData")
    if sec.Exists("LoggedInUser")
        return sec.Read("LoggedInUser")
    end if
    return invalid
end function

function saveLogin() as Void
    sec = createObject("roRegistrySection", "LoggedInUserData")
    sec.Write("LoggedInUser", m.homeScene.loggedInUserName)
    sec.Flush()
end function

function onHeaderButtonPress()
    if m.homeScene.buttonPressed = "search"
        m.homeScene.visible = false
        m.keyboardGroup.visible = true
        m.keyboardGroup.setFocus(true)
    else if m.homeScene.buttonPressed = "login"
        m.top.dialog = createObject("RoSGNode", "LoginPrompt")
        m.top.dialog.observeField("buttonSelected", "onLogin")
    else if m.homeScene.buttonPressed = "options"
        m.homeScene.visible = false
        m.options.visible = true
        m.options.setFocus(true)
    end if
end function

function onUserLogin()
    m.homeScene.loggedInUserName = m.getUser.searchResults.display_name
    m.homeScene.loggedInUserProfileImage = m.getUser.searchResults.profile_image_url
    m.homeScene.followedStreams = m.getUser.searchResults.followed_users
    saveLogin()
end function

function onCategoryItemSelectFromSearch()
    m.categoryScene.currentCategory = m.keyboardGroup.categorySelected
    m.homeScene.visible = false
    m.keyboardGroup.visible = false
    m.categoryScene.visible = true
    m.lastLastScene = "home"
    m.lastScene = "search"
end function

function onCategoryItemSelect()
    m.categoryScene.currentCategory = m.homeScene.categorySelected
    m.homeScene.visible = false
    m.keyboardGroup.visible = false
    m.categoryScene.visible = true
    m.lastScene = "home"
end function

function onClipChange()
    m.categoryScene.fromClip = true
    m.stream["streamFormat"] = "mp4"
    if m.categoryScene.visible = true
        m.currentScene = "category"
        m.stream["url"] = m.categoryScene.clipUrl
    end if
    m.videoPlayer.setFocus(true)
    m.categoryScene.visible = false
    m.keyboardGroup.visible = false
    m.videoPlayer.width = 0
    m.videoPlayer.height = 0
    m.videoPlayer.visible = true
    m.videoPlayer.content = m.stream
    m.videoPlayer.control = "play"

end function

function onStreamChange()
    m.stream["streamFormat"] = "hls"
    if m.keyboardGroup.visible
        m.currentScene = "search"
        m.chat.channel = m.keyboardGroup.streamerRequested
        m.stream["url"] = m.keyboardGroup.streamUrl
    else if m.homeScene.visible
        m.currentScene = "home"
        m.chat.channel = m.homeScene.streamerRequested
        m.stream["url"] = m.homeScene.streamUrl
    else if m.categoryScene.visible
        m.currentScene = "category"
        m.chat.channel = m.categoryScene.streamerRequested
        m.stream["url"] = m.categoryScene.streamUrl
    else if m.channelPage.visible
        m.currentScene = "channel"
        m.channelPage.visible = false
        m.chat.channel = m.channelPage.streamerSelectedName
        m.stream["url"] = m.channelPage.streamUrl
    end if
    m.chat.visible = m.global.chatOption
    if not m.global.chatOption
        m.videoPlayer.width = 0
        m.videoPlayer.height = 0
    else
        m.videoPlayer.width = 896
        m.videoPlayer.height = 504
    end if
    m.videoPlayer.width = 0
    m.videoPlayer.height = 0
    m.videoPlayer.setFocus(true)
    m.keyboardGroup.visible = false
    m.videoPlayer.visible = true
    m.videoPlayer.content = m.stream
    m.videoPlayer.control = "play"
end function

function refreshFollows()
    if m.login <> ""
        m.getUser.loginRequested = m.login
        m.getUser.control = "RUN"
    end if
end function

function onLogin()
    m.login = m.top.dialog.text
    '? "login > "; m.login
    m.top.dialog.close = true
    m.getUser.loginRequested = m.login
    m.getUser.control = "RUN"
end function

function onKeyEvent(key, press) as Boolean
    handled = false
    if press
        if m.videoPlayer.visible = true and key = "back"
            m.videoPlayer.control = "stop"
            m.videoPlayer.visible = false
            m.keyboardGroup.visible = false
            if m.currentScene = "home"
                m.homeScene.visible = false
                m.homeScene.visible = true
                m.homeScene.setFocus(true)
            else if m.currentScene = "category"
                m.categoryScene.visible = true
                'm.categoryScene.fromClip = false
                m.categoryScene.setFocus(true)
            else if m.currentScene = "search"
                m.keyboardGroup.visible = true
            else if m.currentScene = "channel"
                m.channelPage.visible = true
                m.channelPage.setFocus(true)
            end if
            m.chat.visible = false
            handled = true
        else if m.videoPlayer.visible = true and key = "up"
            
        else if m.homeScene.visible = true and key = "options"
            m.homeScene.visible = false
            m.keyboardGroup.visible = true
            m.keyboardGroup.setFocus(true)
            handled = true
        else if m.options.visible and key = "back"
            m.options.visible = false
            m.homeScene.visible = false
            m.homeScene.visible = true
            m.homeScene.setFocus(true)
            handled = true
        else if (m.keyboardGroup.visible or m.categoryScene.visible or m.channelPage.visible) and key = "back"
            m.categoryScene.visible = false
            m.keyboardGroup.visible = false
            m.options.visible = false
            m.channelPage.visible = false
            m.homeScene.visible = false
            if m.lastScene = "home"
                ? "here?"
                m.homeScene.visible = false
                m.homeScene.visible = true
                m.homeScene.setFocus(true)
            else if m.lastScene = "category"
                m.lastScene = m.lastLastScene
                m.lastLastScene = "home"
                m.categoryScene.visible = true
                'm.categoryScene.fromClip = false
                m.categoryScene.setFocus(true)
            else if m.lastScene = "search"
                m.lastScene = m.lastLastScene
                m.lastLastScene = "home"
                m.keyboardGroup.visible = true
            else
                m.homeScene.visible = false
                m.homeScene.visible = true
                m.homeScene.setFocus(true)
            end if
            handled = true
        end if
    end if

    return handled
end function