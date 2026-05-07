# Create Delight Remake v0.4.7.14 — Docker 部署说明

## 快速开始

### 1. 构建镜像

```bash
cd Server-Create-Delight-Remake-v0.4.7.14
docker build -t create-delight-remake:0.4.7.14 .
```

> ⚠️ 首次构建时 Forge 安装器会从 Maven 下载约 200MB 依赖，请确保网络畅通。

### 2. 启动服务器

```bash
# 使用 docker-compose（推荐）
docker compose up -d

# 或直接 docker run
docker run -d \
  --name create-delight-remake \
  -e EULA=TRUE \
  -e MEMORY_INIT=4G \
  -e MEMORY_MAX=6G \
  -p 25565:25565 \
  -v "$(pwd)/data:/data" \
  create-delight-remake:0.4.7.14
```

### 3. 查看日志

```bash
docker compose logs -f
# 或
docker logs -f create-delight-remake
```

---

## 目录结构

```
/server/          ← 只读层（镜像内，mod 文件等）
  mods/
  config/
  defaultconfigs/
  kubejs/
  libraries/      ← Forge 依赖（首次构建时下载）
  run.sh          ← Forge 启动脚本

/data/            ← 挂载卷（宿主机 ./data 目录）
  world/          ← 游戏存档（持久化）
  logs/           ← 服务器日志
  crash-reports/
  eula.txt
  server.properties
  ops.json
  whitelist.json
  banned-*.json
```

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `EULA` | `FALSE` | **必须设为 `TRUE`** 才能启动 |
| `MEMORY_INIT` | `4G` | JVM 初始堆内存（-Xms） |
| `MEMORY_MAX` | `6G` | JVM 最大堆内存（-Xmx） |
| `JVM_ARGS` | *(空)* | 完整覆盖 JVM 参数（设置后忽略 MEMORY_*） |
| `JVM_OPTS` | *(空)* | 追加到默认 JVM 参数末尾 |
| `MOTD` | `Create Delight Remake` | 服务器列表描述 |
| `MAX_PLAYERS` | `20` | 最大玩家数 |
| `DIFFICULTY` | `normal` | 难度：peaceful/easy/normal/hard |
| `GAMEMODE` | `survival` | 默认游戏模式 |
| `ONLINE_MODE` | `true` | `false` 关闭正版验证 |
| `WHITE_LIST` | `false` | 是否开启白名单 |
| `PVP` | `true` | 是否允许 PVP |
| `LEVEL_NAME` | `world` | 存档名 |
| `LEVEL_SEED` | *(空)* | 世界种子，留空随机 |
| `VIEW_DISTANCE` | `10` | 视距（区块） |
| `RCON_ENABLED` | `false` | 是否启用 RCON |
| `RCON_PORT` | `25575` | RCON 端口 |
| `RCON_PASSWORD` | *(空)* | RCON 密码 |
| `TZ` | `Asia/Shanghai` | 容器时区 |

> 服务器第一次启动后会生成 `data/server.properties`，之后直接编辑该文件即可，环境变量中的服务器配置项将不再覆盖已有文件。

---

## 管理命令

```bash
# 进入服务器控制台
docker attach create-delight-remake
# （退出时按 Ctrl+P, Ctrl+Q，不要 Ctrl+C，那会停止服务器）

# 执行 MC 命令（不进入控制台）
docker exec create-delight-remake bash -c 'echo "say Hello" | rcon-cli'

# 优雅停止（等待存档）
docker compose stop
# 或
docker stop --time=60 create-delight-remake

# 备份存档
tar -czf "backup-$(date +%Y%m%d-%H%M%S).tar.gz" data/world
```

---

## 注意事项

1. **首次构建耗时**：Forge 安装阶段需要下载依赖，约需 5-10 分钟，取决于网络速度。
2. **内存要求**：该整合包有 296 个 Mod，建议宿主机至少有 8GB 可用内存（容器设置 4G~6G）。
3. **首次启动耗时**：Forge + KubeJS 第一次加载需要 3-10 分钟，请耐心等待日志出现 `Done`。
4. **存档位置**：所有存档和配置均在 `./data/` 目录，重建容器不会丢失数据。
5. **离线模式**：如需内网游玩（盗版/离线客户端），设置 `ONLINE_MODE=false`。

---

## 系统要求

| 项目 | 最低 | 推荐 |
|------|------|------|
| CPU | 4 核 | 6 核+ |
| 内存 | 6 GB | 10 GB+ |
| 磁盘 | 10 GB | 20 GB+ |
| Java | 17（镜像内置） | — |
| Docker | 20.10+ | 25+ |
