# Docker 部署完成说明

## 已解决的问题

### 1. 后端数据库连接问题
**问题描述**: 后端容器尝试连接到 `127.0.0.1:3306`，但在 Docker 环境中应该连接到 `mysql:3306`

**解决方案**: 修改了 `config/config.go`，添加了环境变量支持
- 后端现在优先使用环境变量配置
- `docker-compose.yml` 设置的环境变量会覆盖 `config.yaml` 中的值
- 支持的环境变量:
  - `DB_HOST` - 数据库主机 (默认: mysql)
  - `DB_PORT` - 数据库端口 (默认: 3306)
  - `REDIS_HOST` - Redis主机 (默认: redis)
  - `REDIS_PORT` - Redis端口 (默认: 6379)

### 2. Nginx DNS 解析问题
**问题描述**: Nginx 在启动时无法解析 `leaf-api` 主机名，因为后端容器可能还未准备好

**解决方案**: 更新了 nginx 配置，使用 Docker 内部 DNS 解析器
- 添加了 `resolver 127.0.0.11` 指令
- 使用变量强制 nginx 在运行时解析主机名
- 修改了代理配置使用 rewrite 规则

### 3. Nginx 代理路径问题
**问题描述**: 使用变量的 proxy_pass 导致路径没有正确转发

**解决方案**:
- 博客前端: `/api/` → rewrite → `/blog/` → 后端
- 管理前端: `/api/` → `/api/` → 后端
- 使用 trailing slash 和正确的 proxy_pass 配置

### 4. MySQL 端口冲突
**问题描述**: 本地 MySQL 占用 3306 端口

**解决方案**: 修改 `docker-compose.yml`，将 MySQL 映射到主机的 3307 端口

## 当前配置

### Docker Compose 服务
- **mysql**: 端口 3307 (外部) → 3306 (内部)
- **redis**: 端口 6379
- **api**: 端口 8888 (后端 API)
- **blog-frontend**: 端口 3000 (博客前端)
- **admin-frontend**: 端口 3001 (管理后台)

### 访问地址
- 博客前端: http://localhost:3000
- 管理后台: http://localhost:3001
- 后端 API: http://localhost:8888

### 数据库连接信息
从主机连接到 Docker 中的 MySQL:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -p123456 leaf_admin
```

## 启动和停止

### 启动所有服务
```bash
./start-docker.sh
# 或
docker-compose up -d --build
```

### 停止所有服务
```bash
./stop-docker.sh
# 或
docker-compose down
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f api
docker-compose logs -f blog-frontend
docker-compose logs -f admin-frontend
```

### 查看服务状态
```bash
docker-compose ps
```

## 关键配置文件更改

### 1. config/config.go
添加了环境变量绑定:
```go
viper.AutomaticEnv()
viper.BindEnv("database.host", "DB_HOST")
viper.BindEnv("database.port", "DB_PORT")
viper.BindEnv("redis.host", "REDIS_HOST")
viper.BindEnv("redis.port", "REDIS_PORT")
```

### 2. blog-frontend/deploy/nginx/nginx.conf
```nginx
resolver 127.0.0.11 valid=30s ipv6=off;

location /api/ {
    set $backend_host leaf-api:8888;
    rewrite ^/api/(.*)$ /blog/$1 break;
    proxy_pass http://$backend_host;
    # ... 其他配置
}
```

### 3. web/deploy/nginx/nginx.conf
```nginx
resolver 127.0.0.11 valid=30s ipv6=off;

location /api/ {
    set $backend_host leaf-api:8888;
    proxy_pass http://$backend_host/api/;
    # ... 其他配置
}
```

### 4. docker-compose.yml
```yaml
mysql:
  ports:
    - "3307:3306"  # 避免与本地 MySQL 冲突

api:
  environment:
    - DB_HOST=mysql
    - DB_PORT=3306
    - REDIS_HOST=redis
    - REDIS_PORT=6379
```

## 验证部署

### 1. 检查所有容器运行状态
```bash
docker-compose ps
```
所有容器状态应为 `Up` 或 `healthy`

### 2. 测试后端 API
```bash
curl http://localhost:8888/blog/stats
```
应返回 JSON 数据

### 3. 测试前端页面
```bash
curl -I http://localhost:3000
curl -I http://localhost:3001
```
应返回 HTTP 200

### 4. 测试 Nginx 代理
```bash
curl http://localhost:3000/api/stats
```
应返回与直接访问后端相同的数据

## 下一步

现在 Docker 部署已完全正常工作，您可以:
1. 在博客前端 (http://localhost:3000) 测试用户注册、登录
2. 在管理后台 (http://localhost:3001) 管理内容
3. 测试个人信息修改功能，验证数据同步

**重要**: 确保测试个人信息修改功能 (头像、昵称、bio、skills、contacts) 是否在两个前端之间正确同步。
