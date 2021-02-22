function Timestamp-Healthcheck
{
    Param
    (
         [Parameter(Mandatory=$false, Position=0, ParameterSetName='URL')]
         [string] $url
    )

    $pwd = "$env:USERPROFILE\OneDrive\Apps\PsCert"
    $bin = "$pwd\bin"
    $modules = "$pwd\modules"
    $temp = "$pwd\temp"
    $openssl = "$bin\openssl\openssl.exe"
    $opensslConf = "$bin\openssl\openssl.cnf"

    switch($PsCmdlet.ParameterSetName){
    "url" { Check-Timestamp-Server }
    }
}

function Check-Timestamp-Server
{
    if(!(test-path -Path $temp))
    {
         mkdir $temp | Out-Null
         if(!(test-path -Path "$temp\ts_test_msg.txt"))
         {
            New-Item "$temp\ts_test_msg.txt" -ItemType file | Out-Null
            Set-Content "$temp\ts_test_msg.txt" "Timestamp test message"  
         } 
    }
    echo "Creating timestamp request..."
    Start-Process $openssl -NoNewWindow -ArgumentList "ts","-query","-data","$temp\ts_test_msg.txt","-cert","-sha256","-no_nonce","-out","$temp\ts_test_msg_sha256.tsq", "-config","$opensslConf" | Out-Null
    echo "Submitting timestamp request to $url..."
    Invoke-WebRequest -uri "http://$url" -Headers @{'Host' = "$url"} -ContentType 'application/timestamp-query' -InFile "$temp\ts_test_msg_sha256.tsq" -OutFile "$temp\ts_test_msg_sha256.tsr" -Method Post | Out-Null
    echo "Timestamp request completed successfully: `r`n"
    Start-Process $openssl -NoNewWindow -ArgumentList "ts","-reply","-in","$temp\ts_test_msg_sha256.tsr","-text","-config","$opensslConf" | Out-Null
    echo "Verifying timestamp signature..."
    Start-Process $openssl -NoNewWindow -ArgumentList "ts","-verify","-data","$temp\ts_test_msg.txt","-in","$temp\ts_test_msg_sha256.tsr","-CAfile","$bin/openssl/DigiCertSHA2AssuredIDTimestampingCA.cer","-untrusted","$bin/openssl/DigiCertAssuredIDRootCA.cer","$opensslConf" | Out-Null
}