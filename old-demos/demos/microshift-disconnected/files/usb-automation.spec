# Define metadata for the package
Name: usb-automation
Version: 1.0
Release: 1
Summary: Adds scripts to make the usb-based automation work
BuildArch: x86_64
License: GPL

# Define dependencies (if any)
Requires: systemd

%description
Adds scripts to make the usb-based automation work

%prep
# No preparation needed

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/udev/rules.d/
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/share/
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/bin/
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system
cp -p /root/usb-automation/99-usb-autoconfig.rules $RPM_BUILD_ROOT/etc/udev/rules.d/
cp -p /root/usb-automation/rhde_automation_encryption_key $RPM_BUILD_ROOT/%{_prefix}/share/
cp -p /root/usb-automation/rhde-automation-pub.pem $RPM_BUILD_ROOT/%{_prefix}/share/
cp -p /root/usb-automation/usb-autoconfig.service $RPM_BUILD_ROOT/etc/systemd/system/
cp -p /root/usb-automation/signature_verification_script.sh $RPM_BUILD_ROOT/%{_prefix}/bin/
cp -p /root/usb-automation/usb_autoconfig.sh $RPM_BUILD_ROOT/%{_prefix}/bin/
cp -p /root/usb-automation/rhde_automation_run.sh $RPM_BUILD_ROOT/%{_prefix}/bin/
cp -p /root/usb-automation/usb_check.sh $RPM_BUILD_ROOT/%{_prefix}/bin/
chmod +x $RPM_BUILD_ROOT/%{_prefix}/bin/*
# Set SELinux context for the files
restorecon -R $RPM_BUILD_ROOT/etc/systemd/system $RPM_BUILD_ROOT/%{_prefix}/bin/  $RPM_BUILD_ROOT/etc/udev/rules.d/ $RPM_BUILD_ROOT/%{_prefix}/share/
# Reload systemd daemon
systemctl daemon-reload
# Restart systemd-udevd service
systemctl restart systemd-udevd.service

# Define files to be included in the package
%files
/etc/udev/rules.d/99-usb-autoconfig.rules
/%{_prefix}/bin/signature_verification_script.sh
/%{_prefix}/bin/usb_autoconfig.sh
/%{_prefix}/bin/rhde_automation_run.sh
/etc/systemd/system/usb-autoconfig.service
/%{_prefix}/bin/usb_check.sh
/%{_prefix}/share/rhde_automation_encryption_key
/%{_prefix}/share/rhde-automation-pub.pem

%changelog
