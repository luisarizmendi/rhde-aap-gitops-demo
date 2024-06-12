Name:       kiosk-config
Version:    0.0.1
Release:    rh1
Summary:    Custom config to run a RHEL workstation as kiosk
License:    BSD
Source0:    user-template
Source1:    kiosk-environment
Source2:    com.redhat.Kiosk.SampleApp.desktop
Source3:    redhat-kiosk-sampleapp.session
Source4:    redhat-kiosk-sampleapp.desktop
Source5:    com.redhat.Kiosk.SampleApp.service
Source6:    session.conf
Source7:    kiosk-app
Requires(pre): shadow-utils
Requires: gnome-kiosk
Requires: gnome-kiosk-script-session
Requires: gdm
Requires: firefox
Requires: accountsservice
BuildRequires: systemd-rpm-macros
ExclusiveArch: x86_64

%description
Custom config to run a RHEL workstation as kiosk

# Since we don't recompile from source, disable the build_id checking
%global _missing_build_ids_terminate_build 0
%global _build_id_links none
%global debug_package %{nil}

# We are evil, we have no changelog !
%global source_date_epoch_from_changelog 0

%prep
cp %{S:0} user-template
cp %{S:1} kiosk-environment
cp %{S:2} com.redhat.Kiosk.SampleApp.desktop
cp %{S:3} redhat-kiosk-sampleapp.session
cp %{S:4} redhat-kiosk-sampleapp.desktop
cp %{S:5} com.redhat.Kiosk.SampleApp.service
cp %{S:6} session.conf
cp %{S:7} kiosk-app

%build

%install
install -m 0644 -D kiosk-environment %{buildroot}/etc/profile.d/kiosk.sh
install -m 0644 -D com.redhat.Kiosk.SampleApp.desktop %{buildroot}/usr/share/applications/com.redhat.Kiosk.SampleApp.desktop
install -m 0644 -D redhat-kiosk-sampleapp.session %{buildroot}/usr/share/gnome-session/sessions/redhat-kiosk-sampleapp.session
install -m 0644 -D redhat-kiosk-sampleapp.desktop %{buildroot}/usr/share/wayland-sessions/redhat-kiosk-sampleapp.desktop
install -m 0644 -D redhat-kiosk-sampleapp.desktop %{buildroot}/usr/share/xsessions/redhat-kiosk-sampleapp.desktop
install -m 0644 -D com.redhat.Kiosk.SampleApp.service %{buildroot}%{_userunitdir}/com.redhat.Kiosk.SampleApp.service
install -m 0755 -d %{buildroot}%{_userunitdir}/gnome-session@redhat-kiosk-sampleapp.target.d
install -m 0644 -D session.conf %{buildroot}%{_userunitdir}/gnome-session@redhat-kiosk-sampleapp.target.d/session.conf
install -m 0755 -d %{buildroot}/etc/accountsservice/user-templates/
install -m 0644 -D user-template %{buildroot}/etc/accountsservice/user-templates/standard
install -m 0644 -D user-template %{buildroot}/etc/accountsservice/user-templates/administrator
install -m 0755 -D kiosk-app %{buildroot}/usr/bin/kiosk-app

%files
%config(noreplace) %attr(0644, root, root) /etc/profile.d/kiosk.sh
%attr(0644, root, root) /usr/share/applications/com.redhat.Kiosk.SampleApp.desktop
%attr(0644, root, root) /usr/share/gnome-session/sessions/redhat-kiosk-sampleapp.session
%attr(0644, root, root) /usr/share/wayland-sessions/redhat-kiosk-sampleapp.desktop
%attr(0644, root, root) /usr/share/xsessions/redhat-kiosk-sampleapp.desktop
%attr(0644, root, root) %{_userunitdir}/com.redhat.Kiosk.SampleApp.service
%attr(0644, root, root) %{_userunitdir}/gnome-session@redhat-kiosk-sampleapp.target.d/session.conf
%config(noreplace) %attr(0644, root, root) /etc/accountsservice/user-templates/standard
%config(noreplace) %attr(0644, root, root) /etc/accountsservice/user-templates/administrator
%attr(0755, root, root) /usr/bin/kiosk-app

%pre
getent group kiosk >/dev/null 2>&1 || groupadd kiosk
getent passwd kiosk >/dev/null 2>&1 || useradd -r -N -g kiosk -d /home/kiosk -m kiosk

%post
%systemd_user_post com.redhat.Kiosk.SampleApp.service
sed -i '/AutomaticLoginEnable/d' /etc/gdm/custom.conf
sed -i '/nAutomaticLogin/d' /etc/gdm/custom.conf
sed -i '/\[daemon\]/a AutomaticLoginEnable=True\nAutomaticLogin=kiosk' /etc/gdm/custom.conf
systemctl set-default graphical.target

%preun
%systemd_user_preun com.redhat.Kiosk.SampleApp.service
if [ "$1" == "0" ]; then # Uninstall
  sed -i '/AutomaticLoginEnable/d' /etc/gdm/custom.conf
  sed -i '/\[daemon\]/a AutomaticLoginEnable=False' /etc/gdm/custom.conf
fi

%postun
%systemd_user_postun com.redhat.Kiosk.SampleApp.service

%changelog













