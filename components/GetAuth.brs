function init()
    m.top.functionName = "onStreamerChange"
end function

function onStreamerChange()

    stream_link = getStreamLink()

    m.top.finished = true

end function

function saveLogin(access_token, refresh_token, login) as Void
    sec = createObject("roRegistrySection", "LoggedInUserData")
    sec.Write("UserToken", access_token)
    sec.Write("RefreshToken", refresh_token)
    sec.Write("LoggedInUser", login)
    m.global.setField("userToken", access_token)
    sec.Flush()
end function

function logUser()
    access_token_url = "http://72.136.77.60:3000/"

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()

    url.SetUrl(access_token_url)
    response_string = url.GetToString()

    return ""
end function

function getStreamLink() as Object
    m.top.finished = false

    enter_code_url = "https://twoku-web.herokuapp.com/register"

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.SetUrl(enter_code_url)
    response_string = url.GetToString()
    ? "getAuth enter code: "; response_string
    m.top.code = response_string

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.SetUrl("https://twoku-web.herokuapp.com/unregister")
    port = CreateObject("roMessagePort")
    url.SetMessagePort(port)
    
    while true
        print url.AsyncPostFromString("code=" + response_string)
        msg = port.WaitMessage(0)
        if msg.GetResponseCode() = 200
            exit while
        end if
        sleep(5000)
    end while

    print msg.GetString()

    oauth_token = ParseJson(msg.GetString())

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.SetUrl("https://id.twitch.tv/oauth2/validate")
    url.AddHeader("Authorization", "Bearer " + oauth_token.access_token)
    response_string = ParseJson(url.GetToString())

    ? "oauth_token.refresh_token "; oauth_token.refresh_token
    saveLogin(oauth_token.access_token, oauth_token.refresh_token, response_string.login)

    return ""
end function