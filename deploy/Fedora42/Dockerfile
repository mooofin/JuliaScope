FROM fedora:42

RUN dnf update -y
RUN dnf install qt6-qtwebengine-devel qt6-qtmultimedia-devel cmake wget mesa-libGL-devel rpmdevtools rpmlint -y

ADD SPECS /root/SPECS
ADD deploy /root

WORKDIR /root

VOLUME /opt/output

CMD ["bash", "./deploy"]
