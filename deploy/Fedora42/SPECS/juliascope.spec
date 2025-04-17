Name:		juliascope
Version:	1.0.0
Release:	1%{?dist}
License:	MIT
Summary:	CLI Domain Scanner written in Julia
URL:		https://github.com/mooofin/juliascope
Source0:	https://github.com/mooofin/JuliaScope/archive/refs/heads/main.zip
Requires:	julia
BuildArch:	noarch

%description
A CLI tool made using Julia with the power of multithreading to scan and find subdomains

%global debug_package %{nil}

%prep
%setup -n JuliaScope-main

#%build
# No build required as of version 1.0.0-1

%install

# bash script
install -D -m 0755 scripts/juliascope %{buildroot}/usr/bin/juliascope
install -D -m 0755 src/juliascope.jl %{buildroot}/usr/share/juliascope/src/juliascope.jl

%files
/usr/bin/juliascope
/usr/share/juliascope/src/juliascope.jl

%changelog
* Thu Apr 17 2025 mooofin <example@example.com> - 1.0.0-1
- Release 1.0.0
