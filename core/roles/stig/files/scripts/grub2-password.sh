#!/usr/bin/expect
set grub_pwd [lindex $argv 0]
spawn grub2-setpassword $grub_pwd
expect -exact "Enter password: "
send -- "$grub_pwd \r"
expect -exact "Confirm password: "
send -- "$grub_pwd \r"
expect eof
