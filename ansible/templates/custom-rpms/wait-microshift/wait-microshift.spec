Name:       wait-microshift
Version:    0.0.1
Release:    rh1
Summary:    Checks ETC files are modified and if so send a webhook to AAP 
License:    BSD
Source0:    wait-microshift.sh
ExclusiveArch: x86_64

%description
Checks ETC files are modified and if so send a webhook to AAP 

# Since we don't recompile from source, disable the build_id checking
%global _missing_build_ids_terminate_build 0
%global _build_id_links none
%global debug_package %{nil}

# We are evil, we have no changelog !
%global source_date_epoch_from_changelog 0

%prep
cp %{S:0} wait-microshift.sh

%build

%install
install -m 0755 -D wait-microshift.sh %{buildroot}/usr/bin/wait-microshift.sh

%files
%attr(0755, root, root) /usr/bin/wait-microshift.sh

%post
# Set SELinux context for the files
restorecon -R /usr/bin/wait-microshift.sh

%changelog