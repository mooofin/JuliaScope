FROM fedora:42

RUN dnf update -y
RUN dnf install julia wget rpmdevtools rpmlint -y

ADD SPECS /root/SPECS
ADD deploy /root

WORKDIR /root

VOLUME /opt/output

CMD ["bash", "./deploy"]
