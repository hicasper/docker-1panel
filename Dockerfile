FROM debian:bullseye-slim

# 设置时区
ENV TZ=Asia/Shanghai

# 安装所需的软件包并清理
RUN apt-get update && apt-get install -y \
    #wget \
    tar \
    unzip \
    curl \
    gnupg \
    ca-certificates \
    #openssh-server \
    apt-transport-https && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
       "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
       tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 创建 Docker 套接字的卷
VOLUME /var/run/docker.sock

# 复制必要的文件
COPY ./install.override.sh .

ARG PANELVER=$PANELVER

# 下载并安装 1Panel
RUN INSTALL_MODE="stable" && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "armhf" ]; then ARCH="armv7"; fi && \
    if [ "$ARCH" = "ppc64el" ]; then ARCH="ppc64le"; fi && \
    package_file_name="1panel-${PANELVER}-linux-${ARCH}.tar.gz" && \
    package_download_url="https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/${PANELVER}/release/${package_file_name}" && \
    echo "Downloading ${package_download_url}" && \
    curl -sSL -o ${package_file_name} "$package_download_url" && \
    tar zxvf ${package_file_name} --strip-components 1 && \
    rm /app/install.sh && \
    mv -f /app/install.override.sh /app/install.sh && \
    chmod +x /app/install.sh && \
    rm ${package_file_name} && \
    mv /app/1panel.service /app/1panel.service.bak && \
    bash /app/install.sh

# 启动
CMD ["/usr/local/bin/1panel"]