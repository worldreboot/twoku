function init()
    m.progressBar = m.top.findNode("progressBar")
    m.progressBar.visible = false
    m.progressBarBase = m.top.findNode("progressBarBase")
    m.progressBarProgress = m.top.findNode("progressBarProgress")
    m.timeProgress = m.top.findNode("timeProgress")
    m.controlSelectRect = m.top.findNode("controlSelectRect")
    m.controlButton = m.top.findNode("controlButton")
    m.top.observeField("position", "onVideoPositionChange")
    m.currentProgressBarState = 0
    m.currentPositionSeconds = 0
    m.currentPositionUpdated = false
    m.thumbnails = m.top.findNode("thumbnails")
    m.thumbnailImage = m.top.findNode("thumbnailImage")

    m.loadingIndicator = m.top.findNode("loadingIndicator")
    m.top.observeField("state", "onvideoStateChange")

    m.uiResolutionWidth = createObject("roDeviceInfo").GetUIResolution().width
    if m.uiResolutionWidth = 1920
        m.thumbnails.clippingRect = [0, 0, 146.66, 82.66]
    end if

    m.sec = createObject("roRegistrySection", "VideoSettings")

    m.buttonHoldTimer = createObject("roSGNode", "Timer")
    m.buttonHoldTimer.observeField("fire", "onButtonHold")
    m.buttonHoldTimer.repeat = true
    m.buttonHoldTimer.duration = "0.070"
    m.buttonHoldTimer.control = "stop"

    m.buttonHeld = invalid
    m.scrollInterval = 10
end function

sub onVideoStateChange()
    if m.top.state = "buffering"
        m.loadingIndicator.control = "start"
    else
        m.loadingIndicator.control = "stop"
    end if
end sub

sub onButtonHold()
    if m.buttonHeld <> invalid and m.top.thumbnailInfo <> invalid
        if m.buttonHeld = "right"
            m.currentPositionSeconds += m.scrollInterval
            m.progressBarProgress.width = 1280 * (m.currentPositionSeconds / m.top.duration)
            if m.currentPositionSeconds > m.top.duration
                m.currentPositionSeconds = m.top.duration
            end if
            if m.top.thumbnailInfo.width <> invalid
                if m.progressBarProgress.width + m.top.thumbnailInfo.width / 2 <= m.progressBarBase.width
                    if m.progressBarProgress.width - m.top.thumbnailInfo.width / 2 >= 0
                        m.thumbnails.translation = [m.progressBarProgress.width - m.top.thumbnailInfo.width / 2, -150]
                    else
                        m.thumbnails.translation = [0, -150]
                    end if
                else
                    m.thumbnails.translation = [m.progressBarBase.width - m.top.thumbnailInfo.width, -150]
                end if
            end if
        else if m.buttonHeld = "left"
            m.currentPositionSeconds -= m.scrollInterval
            m.progressBarProgress.width = 1280 * (m.currentPositionSeconds / m.top.duration)
            if m.currentPositionSeconds < 0
                m.currentPositionSeconds = 0
            end if
            if m.top.thumbnailInfo.width <> invalid
                if m.progressBarProgress.width - m.top.thumbnailInfo.width / 2 >= 0
                    if m.progressBarProgress.width + m.top.thumbnailInfo.width / 2 <= m.progressBarBase.width
                        m.thumbnails.translation = [m.progressBarProgress.width - m.top.thumbnailInfo.width / 2, -150]
                    else
                        m.thumbnails.translation = [m.progressBarBase.width - m.top.thumbnailInfo.width, -150]
                    end if
                else
                    m.thumbnails.translation = [0, -150]
                end if
            end if
        end if

        m.timeProgress.text = convertToReadableTimeFormat(m.currentPositionSeconds) + " / " + convertToReadableTimeFormat(m.top.duration)
        if m.top.thumbnailInfo.width <> invalid
            showThumbnail()
        end if         
        m.scrollInterval += 10
    end if
end sub

function convertToReadableTimeFormat(time) as String
    time = Int(time)
    if time < 3600
        seconds = Int((time MOD 60))
        if seconds < 10
            seconds = "0" + Int((time MOD 60)).ToStr()
        else
            seconds = seconds.ToStr() 
        end if
        return Int((time / 60)).ToStr() + ":" + seconds
    else
        hours = Int(time / 3600)
        minutes = Int((time MOD 3600) / 60)
        seconds = Int((time MOD 3600) MOD 60)
        if seconds < 10
            seconds = "0" + seconds.ToStr()
        else
            seconds = seconds.ToStr()
        end if
        if minutes < 10
            minutes = "0" + minutes.ToStr()
        else
            minutes = minutes.ToStr()
        end if
        return hours.ToStr() + ":" + minutes + ":" + seconds
    end if
end function

sub onVideoPositionChange()
    if m.top.duration > 0
        m.progressBarProgress.width = 1280 * (m.top.position / m.top.duration)
        m.timeProgress.text = convertToReadableTimeFormat(m.top.position) + " / " + convertToReadableTimeFormat(m.top.duration)
    end if
end sub

sub showThumbnail()
    if m.top.thumbnailInfo <> invalid and m.top.thumbnailInfo.width <> invalid
        thumbnailsPerPart = Int(m.top.thumbnailInfo.count / m.top.thumbnailInfo.thumbnail_parts.Count())
        thumbnailPosOverall = Int(m.currentPositionSeconds / m.top.thumbnailInfo.interval)
        thumbnailPosCurrent = thumbnailPosOverall MOD thumbnailsPerPart
        thumbnailRow = Int(thumbnailPosCurrent / m.top.thumbnailInfo.cols)
        thumbnailCol = Int(thumbnailPosCurrent MOD m.top.thumbnailInfo.cols)
        if m.uiResolutionWidth = 1280
            m.thumbnailImage.translation = [-thumbnailCol * m.top.thumbnailInfo.width, -thumbnailRow * m.top.thumbnailInfo.height]
        else
            m.thumbnailImage.translation = [(-thumbnailCol * m.top.thumbnailInfo.width) * 0.66, (-thumbnailRow * m.top.thumbnailInfo.height) * 0.66]
        end if
        '? thumbnailPosOverall " " thumbnailPosCurrent
        '? m.currentPositionSeconds " " m.top.thumbnailInfo.interval " " m.top.thumbnailInfo.cols " " m.top.thumbnailInfo.width " " m.top.thumbnailInfo.height
        if m.top.thumbnailInfo.info_url <> invalid and m.top.thumbnailInfo.thumbnail_parts[Int(thumbnailPosOverall / thumbnailsPerPart)] <> invalid 
            m.thumbnailImage.uri = m.top.thumbnailInfo.info_url + m.top.thumbnailInfo.thumbnail_parts[Int(thumbnailPosOverall / thumbnailsPerPart)]
        end if
    end if
end sub

function saveVideoBookmark() as Void
    if m.top.duration >= 900
        videoBookmarks = "{"
        
        tempBookmarks = m.top.videoBookmarks
        if m.top.thumbnailInfo <> invalid and m.top.thumbnailInfo.video_id <> invalid
            bookmarkAlreadyExists = tempBookmarks.DoesExist(m.top.thumbnailInfo.video_id)
            tempBookmarks[m.top.thumbnailInfo.video_id] = Int(m.top.position).ToStr()
        else
            bookmarkAlreadyExists = false
        end if

        if tempBookmarks.Count() < 100
            first = true
            for each item in tempBookmarks.Items()
                if not first
                    videoBookmarks += ","
                end if
                videoBookmarks += chr(34) + item.key + chr(34) + " : " + chr(34) + item.value + chr(34)
                first = false
            end for
        else
            skip = true
            first = true
            for each item in tempBookmarks.Items()
                if not skip
                    if not first
                        videoBookmarks += ","
                    end if
                    videoBookmarks += chr(34) + item.key + chr(34) + " : " + chr(34) + item.value + chr(34)
                    first = false
                end if
                skip = false
            end for
        end if
        
        if m.top.thumbnailInfo <> invalid and bookmarkAlreadyExists = false
            videoBookmarks += "," + chr(34) + m.top.thumbnailInfo.video_id.ToStr() + chr(34) + " : " + chr(34) + Int(m.top.position).ToStr() + chr(34) + "}"
        else
            videoBookmarks += "}"
        end if

        m.top.videoBookmarks = tempBookmarks

        ? "CustomVideo >> videoBookmarks > " videoBookmarks

        'sec = createObject("roRegistrySection", "VideoSettings")
        m.sec.Write("VideoBookmarks", videoBookmarks)
        m.sec.Flush()
    end if
end function

function onKeyEvent(key, press) as Boolean
    if press
        if key = "up"
            if m.currentProgressBarState = 0
                m.currentProgressBarState = 1
                m.progressBar.visible = true
                m.controlSelectRect.visible = true
            else if m.currentProgressBarState = 1
                m.currentProgressBarState = 2
                m.progressBarBase.height = 10
                m.progressBarProgress.height = 10
                m.controlSelectRect.visible = false
                m.thumbnailImage.visible = true
            else if m.currentProgressBarState = 2
                m.currentProgressBarState = 0
                m.progressBarBase.height = 5
                m.progressBarProgress.height = 5
                m.progressBar.visible = false
                m.thumbnailImage.visible = false
            end if
            return true
        else if key = "right"
            if m.currentProgressBarState = 2
                if m.currentPositionUpdated = false
                    m.currentPositionSeconds = m.top.position
                    m.currentPositionUpdated = true
                    m.top.control = "pause"
                    m.controlButton.uri = "pkg:/images/play.png"
                end if
                m.currentPositionSeconds += 10
                if m.currentPositionSeconds > m.top.duration
                    m.currentPositionSeconds = m.top.duration
                end if
                m.progressBarProgress.width = 1280 * (m.currentPositionSeconds / m.top.duration)
                if m.top.thumbnailInfo <> invalid and m.top.thumbnailInfo.width <> invalid
                    if m.progressBarProgress.width + m.top.thumbnailInfo.width / 2 <= m.progressBarBase.width
                        if m.progressBarProgress.width - m.top.thumbnailInfo.width / 2 >= 0
                            m.thumbnails.translation = [m.progressBarProgress.width - m.top.thumbnailInfo.width / 2, -150]
                        else
                            m.thumbnails.translation = [0, -150]
                        end if
                    else
                        m.thumbnails.translation = [m.progressBarBase.width - m.top.thumbnailInfo.width, -150]
                    end if

                    m.timeProgress.text = convertToReadableTimeFormat(m.currentPositionSeconds) + " / " + convertToReadableTimeFormat(m.top.duration)
                    if m.top.thumbnailInfo.width <> invalid
                        showThumbnail()
                    end if
                end if
                m.buttonHeld = "right"
                m.buttonHoldTimer.control = "start"
            end if
            return true
        else if key = "left"
            if m.currentProgressBarState = 2
                if m.currentPositionUpdated = false
                    m.currentPositionSeconds = m.top.position
                    m.currentPositionUpdated = true
                    m.top.control = "pause"
                    m.controlButton.uri = "pkg:/images/play.png"
                end if
                m.currentPositionSeconds -= 10
                if m.currentPositionSeconds < 0
                    m.currentPositionSeconds = 0
                end if
                if m.top.thumbnailInfo <> invalid and m.top.thumbnailInfo.width <> invalid
                    if m.progressBarProgress.width - m.top.thumbnailInfo.width / 2 >= 0
                        if m.progressBarProgress.width + m.top.thumbnailInfo.width / 2 <= m.progressBarBase.width
                            m.thumbnails.translation = [m.progressBarProgress.width - m.top.thumbnailInfo.width / 2, -150]
                        else
                            m.thumbnails.translation = [m.progressBarBase.width - m.top.thumbnailInfo.width, -150]
                        end if
                    else
                        m.thumbnails.translation = [0, -150]
                    end if

                    m.progressBarProgress.width = 1280 * (m.currentPositionSeconds / m.top.duration)
                    'm.thumbnails.translation = [m.progressBarProgress.width - m.top.thumbnailInfo.width / 2, -150]
                    m.timeProgress.text = convertToReadableTimeFormat(m.currentPositionSeconds) + " / " + convertToReadableTimeFormat(m.top.duration)
                    if m.top.thumbnailInfo.width <> invalid
                        showThumbnail()
                    end if
                end if
                m.buttonHeld = "left"
                m.buttonHoldTimer.control = "start"
            end if
            return true
        else if key = "down"
            m.progressBar.visible = false
            return true
        else if key = "back"
            m.currentPositionSeconds = 0
            m.currentProgressBarState = 0
            m.progressBar.visible = false
            m.controlSelectRect.visible = false
            m.currentPositionUpdated = false
            m.thumbnailImage.uri = ""
            saveVideoBookmark()
            m.top.thumbnailInfo = invalid
        else if key = "OK"
            if m.currentProgressBarState = 1
                if m.top.state = "paused"
                    m.top.control = "resume"
                    m.controlButton.uri = "pkg:/images/pause.png"
                    m.currentPositionUpdated = false
                else
                    m.top.control = "pause"
                    m.controlButton.uri = "pkg:/images/play.png"
                end if
            else if m.currentProgressBarState = 2
                m.top.seek = m.currentPositionSeconds
                m.controlButton.uri = "pkg:/images/pause.png"
                m.currentPositionUpdated = false
            end if
            return true
        end if
    else if not press
        if key = "left" or key = "right"
            m.scrollInterval = 10
            m.buttonHeld = invalid
            m.buttonHoldTimer.control = "stop"
        end if
    end if
end function