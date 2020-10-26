function init()
    m.top.functionName = "onStreamerChange"
end function

function onStreamerChange()

    stream_link = getStreamLink()

    m.top.streamUrl = stream_link

end function

function saveLogin(access_token, refresh_token) as Void
    sec = createObject("roRegistrySection", "LoggedInUserData")
    sec.Write("UserToken", access_token)
    sec.Write("RefreshToken", refresh_token)
    sec.Flush()
end function

function getStreamLink() as Object
    access_token_url = "https://twoku-web.herokuapp.com/code"

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()

    url.SetUrl(access_token_url)
    response_string = url.GetToString()
    ? "getAuth response: "; response_string
    
    tcpListen = CreateObject("roStreamSocket")
        
    addr = CreateObject("roSocketAddress")
    addr.SetAddress("192.168.0.16:1337")
    
    tcpListen.SetSendToAddress(addr)
    tcpListen.notifyReadable(true)
    tcpListen.Connect()
    tcpListen.SendStr(response_string + Chr(13) + Chr(10))

    ? "isConnected() "; tcpListen.isConnected()

    code = ""
    while true
        if tcpListen.GetCountRcvBuf() > 0
            code = tcpListen.ReceiveStr(512)
            print code
            exit while
        end if
    end while

    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.SetUrl("https://id.twitch.tv/oauth2/token?client_id=w9msa6phhl3u8s2jyjcmshrfjczj2y&client_secret=k38wg2xhm8oh26ghvl60narz4te9on&code=" + code + "&grant_type=authorization_code&redirect_uri=http://localhost:3000/auth")
    port = CreateObject("roMessagePort")
    url.SetMessagePort(port)

    print url.AsyncPostFromString("")
    msg = wait(0, port)
    print msg.GetString()

    oauth_token = ParseJson(msg.GetString())

    ? "oauth_token.access_token: "; oauth_token.access_token
    saveLogin(oauth_token.access_token, oauth_token.refresh_token)

    return ""
end function