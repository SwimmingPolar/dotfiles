# docker run -d --privileged --volume /sys/fs/cgroup:/sys/fs/cgroup:ro my-custom-ubuntu
FROM robertdebock/ubuntu

RUN apt-get update && apt-get install -y vim sudo
RUN apt-get install -y dialog whiptail
RUN apt-get install -y apt-utils
RUN apt-get install -y snapd 
RUN apt-get install -y git curl wget
RUN apt-get install -y ripgrep unzip vim apt

RUN adduser --disabled-password --gecos '' swimmingpolar \
&& echo "swimmingpolar:rkskekfk1" | chpasswd

RUN echo 'swimmingpolar	ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/swimmingpolar

CMD ["/lib/systemd/systemd"]
