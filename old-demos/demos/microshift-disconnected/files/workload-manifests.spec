Name:           workload-manifests
Version:        0.0.1
Release:        1%{?dist}
Summary:        Adds workload manifests to microshift
BuildArch:      noarch
License:        GPL
# No Source0 directive needed if directly using local files

%description
Adds workload manifests to microshift

%prep
# No preparation needed

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/lib/microshift/manifests
# Copy manifest files from /root/manifests
cp -pr /root/manifests/* $RPM_BUILD_ROOT/%{_prefix}/lib/microshift/manifests/

%files
%{_prefix}/lib/microshift/manifests/**

%changelog