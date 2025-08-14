# FROM scottyhardy/docker-wine:stable

FROM docker-wine

USER root
RUN apt update && apt install -y \
    locales \
    mesa-utils \
    procps \
    pev \
    sudo \
    vim \
    pulseaudio-utils \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -fr /tmp/*

ENV \
  LANG=zh_CN.UTF-8 \
  LC_ALL=zh_CN.UTF-8

# COPY --chown=user:group container_root/ /
COPY container_root/ /
COPY [A-Z]* /
COPY VERSION /VERSION.docker-wechat
COPY pulse-client.conf /etc/pulse/client.conf

# RUN chown user /home \
#   && localedef -i zh_CN -c -f UTF-8 zh_CN.UTF-8 \
#   && echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN useradd -m user && chown user /home \
  && localedef -i zh_CN -c -f UTF-8 zh_CN.UTF-8 \
  && echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER user

RUN bash -x /setup.sh

ENTRYPOINT [ "/entrypoint.sh" ]

#
# Huan(202004): VOLUME should be put to the END of the Dockerfile
#   because it will frezz the contents in the volume directory
#   which means the content in the directory will lost all changes after the VOLUME command
#
RUN mkdir -p "/home/user/WeChat Files" "/home/user/.wine/drive_c/users/user/Application Data" \
  && chown user:group "/home/user/WeChat Files" "/home/user/.wine/drive_c/users/user/Application Data"
  
VOLUME [\
  "/home/user/WeChat Files", \
  "/home/user/.wine/drive_c/users/user/Application Data" \
]
