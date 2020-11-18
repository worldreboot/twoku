function createUrl()
    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.AddHeader("Client-ID", "w9msa6phhl3u8s2jyjcmshrfjczj2y")
    while m.global.appBearerToken = invalid
    end while
    userToken = m.global.userToken
    '? "(userToken) " userToken
    if userToken <> invalid and userToken <> ""
        '? "we usin " userToken
        url.AddHeader("Authorization", "Bearer " + m.global.userToken)
    else
        url.AddHeader("Authorization", m.global.appBearerToken)
    end if
    return url
end function

function refreshToken()
    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.SetUrl("https://twoku-web.herokuapp.com/refresh")
    port = CreateObject("roMessagePort")
    url.SetMessagePort(port)
    url.AsyncPostFromString("code=" + getRefreshToken())
    msg = port.WaitMessage(0)
    oauth_token = ParseJson(msg.GetString())

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.SetUrl("https://id.twitch.tv/oauth2/validate")
    url.AddHeader("Authorization", "Bearer " + oauth_token.access_token)
    response = ParseJson(url.GetToString())

    saveLogin(oauth_token.access_token, oauth_token.refresh_token, response.login)
end function

function getRefreshToken()
    sec = createObject("roRegistrySection", "LoggedInUserData")
    if sec.Exists("RefreshToken")
        return sec.Read("RefreshToken")
    end if
    return ""
end function

function saveLogin(access_token, refresh_token, login) as Void
    sec = createObject("roRegistrySection", "LoggedInUserData")
    sec.Write("UserToken", access_token)
    sec.Write("RefreshToken", refresh_token)
    sec.Write("LoggedInUser", login)
    m.global.setField("userToken", access_token)
    sec.Flush()
end function