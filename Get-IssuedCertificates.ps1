<# Get-IssuedCertificates v0.1 SystemInsecure
--== April 27, 2023 ==--

MUST run interactively on a Microsoft CA server.

This script gets a list of all certificate templates in the domain, you choose one (or multiple),
and it will list out certificates that have been issued by the CA you are running the script on.

See Errata section at bottom for prerequisites, restrictions and the changelog.

#>

$templateDump = certutil.exe -v -template

$templates = @(ForEach($line in $templateDump){
	If($line -like "*Template=*"){
        $vName=(Get-TextWithin $line -StartChar "=" -EndChar "(")
        $vOID=(Get-TextWithin $line -StartChar "(" -EndChar ")")

        if ($vOID.GetType().BaseType.ToString() -eq "System.Array"){
            $vName=$vName+"("+$vOID[0]+")"
            $vOID=$vOID[-1]
        }

		$vasdf = New-Object -TypeName psobject
        $vasdf | Add-Member -membertype noteproperty -name 'Name' -value $vName
        $vasdf | Add-Member -membertype noteproperty -name 'OID' -value $vOID
        $vasdf
    }
})

$templates = $templates | Out-GridView -OutputMode Multiple

$certs = $null
ForEach($template in $templates.OID){
$certs += certutil -view -restrict "certificate template=$template,Disposition=20" -out "CommonName,NotBefore,NotAfter,CertificateTemplate"
}

$i=0
$output = @(
    ForEach($line in $certs){
        If($line -like "*Issued Common Name: *"){
            $asdf = New-Object -TypeName psobject
            $asdf | Add-Member -membertype noteproperty -name 'Common Name' -value (($certs[$i] -replace "Issued Common Name: ","") -replace '"','').trim()
            $asdf | Add-Member -membertype NoteProperty -name 'Effective Date' -value (($certs[$i+1] -replace "Certificate Effective Date: ","") -replace '\d+\:\d+\s+\w+','').trim()
            $asdf | Add-Member -membertype NoteProperty -name 'Expiration Date' -value (($certs[$i+2] -replace "Certificate Expiration Date: ","") -replace '\d+\:\d+\s+\w+','').trim()
            $asdf | Add-Member -membertype NoteProperty -name 'Template' -value (($certs[$i+3] -replace "Certificate Template: ","") -replace '"','').trim()
            $asdf
        }
        $i++
    }
)

$output # | Export-Csv -path "C:\Users\$($env:USERNAME)\Documents\IssuedCerts_$(hostname)_$($(get-date -format 'yyyyMMdd').ToString()).csv" -NoTypeInformation 

<# --== Errata ==--

Prerequisites needed before launching:
- Powershell 5.1 or better
- Run interactively on the Certificate Authority

Restrictions
- None

To do in later versions:
- Nothing planned

Changelog:
- 0.1 Initial version. April 27, 2023.
#>
