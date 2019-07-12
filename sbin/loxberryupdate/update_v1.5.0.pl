#!/usr/bin/perl

# Input parameters from loxberryupdate.pl:
# 	release: the final version update is going to (not the version of the script)
#   logfilename: The filename of LoxBerry::Log where the script can append
#   updatedir: The directory where the update resides
#   cron: If 1, the update was triggered automatically by cron

use LoxBerry::Update;

init();


LOGINF "Installing new network templates for IPv6...";
unlink "$lbhomedir/system/network/interfaces.eth_dhcp";
unlink "$lbhomedir/system/network/interfaces.eth_static";
unlink "$lbhomedir/system/network/interfaces.wlan_dhcp";
unlink "$lbhomedir/system/network/interfaces.wlan_static";
copy_to_loxberry("/system/network/interfaces.loopback");
copy_to_loxberry("/system/network/interfaces.ipv4");
copy_to_loxberry("/system/network/interfaces.ipv6");

LOGINF "Installing additional Perl modules...";
apt_update("update");
apt_install("libdata-validate-ip-perl");

# Upgrade Raspbian on next reboot
LOGINF "Upgrading system to latest Raspbian release ON NEXT REBOOT.";
my $logfilename_wo_ext = $logfilename;
$logfilename_wo_ext =~ s{\.[^.]+$}{};
open(F,">$lbhomedir/system/daemons/system/99-updaterebootv150");
print F <<EOF;
#!/bin/bash
perl $lbhomedir/sbin/loxberryupdate/updatereboot_v1.5.0.pl logfilename=$logfilename_wo_ext-reboot 2>&1
EOF
close (F);
qx { chmod +x $lbhomedir/system/daemons/system/99-updaterebootv150 };

## If this script needs a reboot, a reboot.required file will be created or appended
LOGWARN "Update file $0 requests a reboot of LoxBerry. Please reboot your LoxBerry after the installation has finished.";
reboot_required("LoxBerry Update requests a reboot.");

apt_update("clean");

LOGOK "Update script $0 finished." if ($errors == 0);
LOGERR "Update script $0 finished with errors." if ($errors != 0);

# End of script
exit($errors);

