Name:       {{ gitea_user_name }}{{ user_number }}-usb-automation
Version:    0.0.1
Release:    rh1
Summary:    Adds scripts to make the usb-based automation work
License:    BSD
Source0:    {{ gitea_user_name }}{{ user_number }}/rhde_automation_encryption_key
Source1:    {{ gitea_user_name }}{{ user_number }}/rhde-automation-pub.pem
Source2:    {{ gitea_user_name }}{{ user_number }}/99-usb-autoconfig.rules
Source3:    {{ gitea_user_name }}{{ user_number }}/usb-autoconfig.service
Source4:    {{ gitea_user_name }}{{ user_number }}/signature_verification_script.sh
Source5:    {{ gitea_user_name }}{{ user_number }}/usb_autoconfig.sh
Source6:    {{ gitea_user_name }}{{ user_number }}/rhde_automation_run.sh
Source7:    {{ gitea_user_name }}{{ user_number }}/usb_check.sh
Requires(pre): shadow-utils
Requires: kiosk-mode
BuildRequires: systemd-rpm-macros
ExclusiveArch: {{ system_arch | default('x86_64') }}


%description
Adds scripts to make the usb-based automation work


# Since we don't recompile from source, disable the build_id checking
%global _missing_build_ids_terminate_build 0
%global _build_id_links none
%global debug_package %{nil}

# We are evil, we have no changelog !
%global source_date_epoch_from_changelog 0

%prep
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/rhde_automation_encryption_key rhde_automation_encryption_key
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/rhde-automation-pub.pem rhde-automation-pub.pem
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/99-usb-autoconfig.rules 99-usb-autoconfig.rules
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/usb-autoconfig.service usb-autoconfig.service
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/signature_verification_script.sh signature_verification_script.sh
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/usb_autoconfig.sh usb_autoconfig.sh
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/rhde_automation_run.sh rhde_automation_run.sh
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/usb_check.sh usb_check.sh


%build

%install
mkdir -p %{buildroot}/usr/share
mkdir -p %{buildroot}/etc/udev/rules.d
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/usr/bin
install -m 0600 -D rhde_automation_encryption_key  %{buildroot}/usr/share/
install -m 0644 -D rhde-automation-pub.pem  %{buildroot}/usr/share/
install -m 0644 -D 99-usb-autoconfig.rules  %{buildroot}/etc/udev/rules.d/
install -m 0644 -D usb-autoconfig.service  %{buildroot}/etc/systemd/system/
install -m 0755 -D signature_verification_script.sh  %{buildroot}/usr/bin
install -m 0755 -D usb_autoconfig.sh  %{buildroot}/usr/bin
install -m 0755 -D  rhde_automation_run.sh  %{buildroot}/usr/bin
install -m 0755 -D usb_check.sh  %{buildroot}/usr/bin


%files
%attr(0600, root, root) /usr/share/rhde_automation_encryption_key
%attr(0644, root, root) /usr/share/rhde-automation-pub.pem
%attr(0644, root, root) /etc/udev/rules.d/99-usb-autoconfig.rules
%attr(0644, root, root) /etc/systemd/system/usb-autoconfig.service
%attr(0755, root, root) /usr/bin/signature_verification_script.sh
%attr(0755, root, root) /usr/bin/usb_autoconfig.sh
%attr(0755, root, root) /usr/bin/rhde_automation_run.sh
%attr(0755, root, root) /usr/bin/usb_check.sh


%pre

%post
# Set SELinux context for the files
restorecon -R %{buildroot}/etc/systemd/system %{buildroot}/usr/bin  %{buildroot}/etc/udev/rules.d

systemctl daemon-reload || :

systemctl enable usb-autoconfig.service || :
systemctl start usb-autoconfig.service || :


%preun

%postun

%changelog












