Name:       workload-manifests
Version:    0.0.1
Release:    rh1
Summary:    Kubernetes Manifests for embedded APPs
License:    BSD
Source0:    workload-manifests.tar.gz
ExclusiveArch: x86_64

%description
Kubernetes Manifests for embedded APPs

# Since we don't recompile from source, disable the build_id checking
%global _missing_build_ids_terminate_build 0
%global _build_id_links none
%global debug_package %{nil}

# We are evil, we have no changelog !
%global source_date_epoch_from_changelog 0

%prep
cp %{S:0} workload-manifests.tar.gz

%build

%install
mkdir -p %{buildroot}/tmp/manifests/
tar -xzf workload-manifests.tar.gz -C %{buildroot}/tmp/manifests/
mkdir -p %{buildroot}/usr/lib/microshift/manifests
# Copy manifest files from /root/manifests
cp -pr %{buildroot}/tmp/manifests/* %{buildroot}/usr/lib/microshift/manifests/
rm -rf %{buildroot}/tmp/manifests/

%files
%attr(0755, root, root) /usr/lib/microshift/manifests/**

%post
# Set SELinux context for the files
restorecon -R /usr/lib/microshift/manifests/

%changelog


