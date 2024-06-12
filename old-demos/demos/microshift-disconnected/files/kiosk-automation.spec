# Define metadata for the package
Name: kiosk-automation
Version: 1.0
Release: 1
Summary: Adds scripts to make the kiosk-based automation work
BuildArch: x86_64
License: GPL

# Define dependencies (if any)
Requires: systemd

%description
Adds scripts to make the kiosk-based automation work

%prep
# No preparation needed

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/share/containers/systemd/
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/bin/
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system/multi-user.target.wants/

cp -p /root/kiosk-config/rhde_encrypted.tar $RPM_BUILD_ROOT/%{_prefix}/share/
cp -p /root/kiosk-config/kiosk-token.service $RPM_BUILD_ROOT/etc/systemd/system/kiosk-token.service
cp -p /root/kiosk-config/deactivation_kiosk.sh $RPM_BUILD_ROOT/%{_prefix}/bin/deactivation_kiosk.sh
cp -p /root/kiosk-config/deactivation-kiosk.service $RPM_BUILD_ROOT/etc/systemd/system/deactivation-kiosk.service
cp -p /root/kiosk-config/token-web.sh $RPM_BUILD_ROOT/%{_prefix}/bin/token-web.sh

chmod +x $RPM_BUILD_ROOT/%{_prefix}/bin/*
# Set SELinux context for the files
restorecon -R $RPM_BUILD_ROOT/etc/systemd/system $RPM_BUILD_ROOT/%{_prefix}/bin/  $RPM_BUILD_ROOT/%{_prefix}/share/

# Reload systemd daemon
systemctl daemon-reload


%post
chmod +x $RPM_BUILD_ROOT/%{_prefix}/bin/*
# Set SELinux context for the files
restorecon -R $RPM_BUILD_ROOT/etc/systemd/system $RPM_BUILD_ROOT/%{_prefix}/bin/  $RPM_BUILD_ROOT/%{_prefix}/share/

systemctl enable deactivation-kiosk.service || :
systemctl start deactivation-kiosk.service || :

systemctl enable kiosk-token.service || :
systemctl start kiosk-token.service || :

systemctl daemon-reload || :


# Define files to be included in the package
%files
/%{_prefix}/share/rhde_encrypted.tar
/etc/systemd/system/kiosk-token.service
/%{_prefix}/bin/deactivation_kiosk.sh
/etc/systemd/system/deactivation-kiosk.service
/%{_prefix}/bin/token-web.sh

%changelog