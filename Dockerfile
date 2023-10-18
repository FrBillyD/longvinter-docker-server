FROM debian:bookworm-slim

# Change repositories (add missing repos)
RUN printf "deb https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware"                    > /etc/apt/sources.list && \
    printf "deb https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware"           >> /etc/apt/sources.list && \
    printf "deb https://deb.debian.org/debian-security/ bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    printf "deb https://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware"         >> /etc/apt/sources.list

# Install necessary linux packages
RUN apt-get update && \
    apt install --no-install-recommends --no-install-suggests -y \
      git \
      git-lfs  \
      wget \
      ca-certificates \
      software-properties-common && \
    dpkg --add-architecture i386 && \
    apt update && \
    apt install --no-install-recommends --no-install-suggests -y \
      lib32gcc-s1 \
      steamcmd && \
    apt-get clean

# Steam user variables
ENV UID 1000
ENV USER steam
ENV HOME /home/$USER

# Create the steam user and data directory
RUN adduser --disabled-password --gecos '' -u $UID $USER && \
    mkdir -p /data

# Copy all necessary scripts
WORKDIR $HOME
COPY run.sh .

# Set scripts as executable and set ownership of home/data directories
RUN chmod +x run.sh && \
    chown -R $USER:$USER /home/$USER && \
    chown -R $USER:$USER /data

# Install the SteamCMD as the steam user
USER steam
WORKDIR $HOME
RUN mkdir -p steamcmd && cd steamcmd && \
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz

# Install the Steam SDK
WORKDIR $HOME/steamcmd
RUN ./steamcmd.sh +force_install_dir . +login anonymous +app_update 1007 +quit

# Link 64-bit binaries (this may not even be necessary?)
RUN mkdir -p $HOME/.steam/sdk64 && \
    ln -s $HOME/steamcmd/linux64/steamclient.so $HOME/.steam/sdk64/

WORKDIR $HOME
EXPOSE 7777 27016

ENTRYPOINT ["/bin/bash"]
CMD ["./run.sh"]
