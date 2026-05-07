# ============================================================
#  Create Delight Remake v0.4.7.14  —  Minecraft Forge Server
#  Minecraft 1.20.1 / Forge 47.4.10 / Java 17
#
#  参考 itzg/minecraft-server 的设计理念：
#    - 首次运行自动安装 Forge
#    - /data 挂载卷保存世界存档、日志等可变数据
#    - 通过环境变量灵活调整 JVM 参数、服务器配置
# ============================================================

# ── 阶段 1：Forge 安装阶段（仅首次构建时下载依赖）────────────
FROM eclipse-temurin:17-jre-jammy AS forge-installer

WORKDIR /install

# 复制 Forge 安装包
COPY forge.jar forge.jar

# 执行安装（下载 libraries，生成 run.sh / unix_args.txt）
RUN java -jar forge.jar --installServer 2>&1 | tee forge-install.log \
    && echo "Forge installation complete." \
    && ls -lh


# ── 阶段 2：运行时镜像 ─────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy

# ---------- 镜像元数据 ----------
LABEL maintainer="Create Delight Remake" \
      org.opencontainers.image.title="Server-Create-Delight-Remake" \
      org.opencontainers.image.version="0.4.7.14" \
      org.opencontainers.image.description="Minecraft 1.20.1 Forge modpack server: Create Delight Remake" \
      org.opencontainers.image.base.name="eclipse-temurin:17-jre-jammy"

# ---------- 系统依赖 ----------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        tini \
    && rm -rf /var/lib/apt/lists/*

# ---------- 创建非 root 用户 ----------
RUN groupadd -r minecraft --gid=1000 \
    && useradd -r -g minecraft --uid=1000 --home-dir=/server --shell=/bin/bash minecraft \
    && mkdir -p /server /data \
    && chown -R minecraft:minecraft /server /data

# ---------- 工作目录：服务端只读资产层 ----------
WORKDIR /server

# 从安装阶段复制 Forge 运行时（libraries 等）
COPY --from=forge-installer --chown=minecraft:minecraft /install/libraries ./libraries
COPY --from=forge-installer --chown=minecraft:minecraft /install/run.sh ./run.sh
COPY --from=forge-installer --chown=minecraft:minecraft /install/unix_args.txt ./unix_args.txt 2>/dev/null || true

# 复制整合包静态资产（mods、config、defaultconfigs、KubeJS 等）
COPY --chown=minecraft:minecraft mods/           ./mods/
COPY --chown=minecraft:minecraft config/         ./config/
COPY --chown=minecraft:minecraft defaultconfigs/ ./defaultconfigs/
COPY --chown=minecraft:minecraft kubejs/         ./kubejs/

# 可选目录（不存在则跳过，通过 shell 处理）
COPY --chown=minecraft:minecraft schematics/     ./schematics/
COPY --chown=minecraft:minecraft ldlib/          ./ldlib/
COPY --chown=minecraft:minecraft tacz/           ./tacz/

# 服务器图标
COPY --chown=minecraft:minecraft server-icon.png ./server-icon.png

# 复制 Forge 安装包本体（容器内保留，供 libraries 更新用）
COPY --chown=minecraft:minecraft forge.jar ./forge.jar

# 复制启动入口脚本
COPY --chown=minecraft:minecraft entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ---------- 挂载点 ----------
# /data  →  可变数据：world存档、logs、banned-players.json、whitelist.json、ops.json、server.properties、eula.txt 等
VOLUME ["/data"]

# ---------- 端口 ----------
EXPOSE 25565/tcp
EXPOSE 25575/tcp

# ---------- 运行时用户 ----------
USER minecraft

# ---------- 健康检查 ----------
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD bash -c 'echo "" | timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/25565" 2>/dev/null && echo healthy || exit 1'

# ---------- 启动 ----------
# 使用 tini 作为 PID 1，保证信号正确传递（SIGTERM → 服务器优雅关闭）
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
