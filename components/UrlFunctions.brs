function createUrl()
    url = CreateObject("roUrlTransfer")
    url.EnableEncodings(true)
    url.RetainBodyOnError(true)
    url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    url.InitClientCertificates()
    url.AddHeader("Client-ID", "w9msa6phhl3u8s2jyjcmshrfjczj2y")
    while m.global.appBearerToken = invalid
    end while
    url.AddHeader("Authorization", m.global.appBearerToken)'"Bearer kp3nfb1pwuo6imnfbf20x3gqtbxu2e")
    return url
end function