Name:       {{ gitea_user_name }}{{ user_number }}-onboarding-kiosk
Version:    0.0.1
Release:    rh1
Summary:    Adds scripts to make the kiosk-based automation work
License:    BSD
Source0:    {{ gitea_user_name }}{{ user_number }}/rhde_encrypted.tar
Source1:    {{ gitea_user_name }}{{ user_number }}/kiosk-token.service
Source2:    {{ gitea_user_name }}{{ user_number }}/token-web.sh
Source3:    {{ gitea_user_name }}{{ user_number }}/deactivation-kiosk.service
Source4:    {{ gitea_user_name }}{{ user_number }}/deactivation_kiosk.sh
Requires(pre): shadow-utils
Requires: kiosk-mode
BuildRequires: systemd-rpm-macros
ExclusiveArch: {{ system_arch | default('x86_64') }}

%description
Adds scripts to make the kiosk-based automation work

# Since we don't recompile from source, disable the build_id checking
%global _missing_build_ids_terminate_build 0
%global _build_id_links none
%global debug_package %{nil}

# We are evil, we have no changelog !
%global source_date_epoch_from_changelog 0

%prep
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/rhde_encrypted.tar rhde_encrypted.tar
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/kiosk-token.service kiosk-token.service
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/token-web.sh token-web.sh
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/deactivation-kiosk.service deactivation-kiosk.service
cp %{_sourcedir}/{{ gitea_user_name }}{{ user_number }}/deactivation_kiosk.sh deactivation_kiosk.sh


%build

%install
mkdir -p %{buildroot}/usr/share
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/usr/bin
install -m 0644 -D rhde_encrypted.tar  %{buildroot}/usr/share/rhde_encrypted.tar
install -m 0644 -D kiosk-token.service %{buildroot}/etc/systemd/system/kiosk-token.service
install -m 0755 -D token-web.sh %{buildroot}/usr/bin/token-web.sh
install -m 0644 -D deactivation-kiosk.service %{buildroot}/etc/systemd/system/deactivation-kiosk.service
install -m 0755 -D deactivation_kiosk.sh %{buildroot}/usr/bin/deactivation_kiosk.sh


%files
%attr(0644, root, root) /usr/share/rhde_encrypted.tar
%attr(0644, root, root) /etc/systemd/system/kiosk-token.service
%attr(0755, root, root) /usr/bin/token-web.sh
%attr(0644, root, root) /etc/systemd/system/deactivation-kiosk.service
%attr(0755, root, root) /usr/bin/deactivation_kiosk.sh


%pre

%post
# Set SELinux context for the files
restorecon -R %{buildroot}/etc/systemd/system/kiosk-token.service %{buildroot}/etc/systemd/system/deactivation-kiosk.service %{buildroot}/usr/bin/token-web.sh  %{buildroot}/usr/bin/deactivation_kiosk.sh  %{buildroot}/usr/share/rhde_encrypted.tar

systemctl daemon-reload || :

systemctl enable deactivation-kiosk.service || :
systemctl start deactivation-kiosk.service || :

systemctl enable kiosk-token.service || :
systemctl start kiosk-token.service || :



%preun

%postun

%changelog


