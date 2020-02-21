# Generate Fake Data! By Chris King
#
# This generates fake credit card data (not validated), names, emails, phone numbers
#
# Generate-Data-Entries
# Get-Data-Entry
# Generate-CC
# Generate-Name
# Generate-Email
# Generate-PhoneNum


function Generate-CC() {
	$set = "0123456789".ToCharArray()
	$cc_num = ""
	for ($i = 0; $i -lt 16; ++$i) {
		$cc_num += $set | Get-Random
	}
	return $cc_num
}

function Generate-SSN() {
	$set = "0123456789".ToCharArray()
	$ssn = ""
	for ($i = 0; $i -lt 9; ++$i) {
		if ($i -eq 3 -or $i -eq 5) {
			$ssn += "-"
		}
		$ssn += $set | Get-Random
	}
	return $ssn
}

function Generate-Name() {
	$set = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
	$fname_size = Get-Random -Minimum 5 -Maximum 10
	$lname_size = Get-Random -Minimum 5 -Maximum 10
	$firstname = ""
	$lastname = ""
	for ($i = 0; $i -lt $fname_size; ++$i) {
		$firstname += $set | Get-Random
	}
	for ($i = 0; $i -lt $lname_size; ++$i) {
		$lastname += $set | Get-Random
	}
	return $firstname+" "+$lastname
}

function Generate-Email() {
	$set = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
	$endings = "gmail.com", "hotmail.com", "yahoo.com", "mail.com", "msn.com", "att.net"
	$name_size = Get-Random -Minimum 4 -Maximum 10
	$email = ""
	for ($i = 0; $i -lt $name_size; ++$i) {
		$email += $set | Get-Random
	}
	$ending = $endings| Get-Random
	return $email+"@"+$ending
}

function Generate-PhoneNum() {
	$set = "0123456789".ToCharArray()
	$area = ""
	$first = ""
	$second = ""
	for ($i = 0; $i -lt 3; ++$i) {
		$area += $set | Get-Random
		$first += $set | Get-Random
		$second += $set | Get-Random
	}
	$second += $set | Get-Random
	return "($area)$first-$second"
}

function Get-Data-Entry() {
	$name = Generate-Name
	$email = Generate-Email
	$cc = Generate-CC
	$ssn = Generate-SSN
	$phone = Generate-PhoneNum
	$obj = New-Object PSObject
	$obj | Add-Member NoteProperty "Name" $name
	$obj | Add-Member NoteProperty "Email" $email
	$obj | Add-Member NoteProperty "Credit Card" $cc
	$obj | Add-Member NoteProperty "SSN" $ssn
	$obj | Add-Member NoteProperty "Phone #" $phone
	Write-Output $obj
}

function Generate-Data-Entries($numRecords) {
	for ($i = 0; $i -lt $numRecords; ++$i) {
		Get-Data-Entry
	}
}