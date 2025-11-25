# Docker 部署故障排查和修复

## 问题描述
访问 `http://localhost:3000` 时出现 502 错误

## 问题原因

### 1. Nginx 代理配置错误
**原配置：**
```nginx
location /api {
    proxy_pass http://leaf-api:8888;
}
```

**问题：** 这会将 `/api/xxx` 转发到 `http://leaf-api:8888/api/xxx`，但后端实际路径是 `/blog/xxx`

**修复后：**
```nginx
location /api {
    proxy_pass http://leaf-api:8888/blog;
}
```

### 2. 端口冲突
- 本地开发服务器占用了 3000 端口，导致 Docker 容器无法绑定
- 本地后端服务占用了 8888 端口

## 已修复的内容

### 1. Nginx 配置 (`blog-frontend/deploy/nginx/nginx.conf`)
- ✅ 修复了 API 代理路径：`/api` → `http://leaf-api:8888/blog`
- ✅ 添加了文件上传代理：`/files` → `http://leaf-api:8888/files`
- ✅ 增加了文件上传大小限制：`client_max_body_size 10M`

### 2. 创建了启动脚本 (`start-docker.sh`)
使用此脚本可以一键启动所有 Docker 服务

### 3. 停止了本地服务
- ✅ 停止了本地前端开发服务器（3000 端口）
- ✅ 停止了本地后端 API 服务（8888 端口）

## 启动步骤

### 方法1：使用启动脚本（推荐）

```bash
./start-docker.sh
```

### 方法2：手动启动

1. **停止本地服务**
   ```bash
   # 停止本地前端开发服务器
   pkill -f "node.*blog-frontend"

   # 停止本地后端服务
   pkill -f leaf-api
   ```

2. **启动 Docker 服务**
   ```bash
   # 停止并删除旧容器
   docker-compose down

   # 重新构建并启动
   docker-compose up -d --build
   ```

3. **查看服务状态**
   ```bash
   docker-compose ps
   ```

4. **查看日志（如果有问题）**
   ```bash
   # 查看所有服务日志
   docker-compose logs -f

   # 查看特定服务日志
   docker-compose logs -f blog-frontend
   docker-compose logs -f api
   ```

## 访问地址

- **博客前端**：http://localhost:3000
- **管理后台**：http://localhost:3001
- **API 后端**：http://localhost:8888

## 常见问题排查

### 1. 容器无法启动

**检查端口占用：**
```bash
lsof -i :3000  # 检查前端端口
lsof -i :8888  # 检查后端端口
lsof -i :3306  # 检查MySQL端口
lsof -i :6379  # 检查Redis端口
```

**停止占用端口的进程：**
```bash
kill -9 <PID>
```

### 2. 数据库连接失败

**检查 MySQL 容器状态：**
```bash
docker-compose ps mysql
docker-compose logs mysql
```

**进入 MySQL 容器：**
```bash
docker-compose exec mysql mysql -uroot -p123456
```

### 3. API 502 错误

**检查后端容器日志：**
```bash
docker-compose logs -f api
```

**检查后端健康状态：**
```bash
curl http://localhost:8888/blog/stats
```

### 4. 前端白屏或资源加载失败

**检查前端容器日志：**
```bash
docker-compose logs -f blog-frontend
```

**进入容器检查 nginx 配置：**
```bash
docker-compose exec blog-frontend cat /etc/nginx/conf.d/default.conf
```

### 5. 重新构建某个服务

```bash
# 重新构建前端
docker-compose up -d --build blog-frontend

# 重新构建后端
docker-compose up -d --build api
```

## 完全重置

如果遇到无法解决的问题，可以完全重置：

```bash
# 停止并删除所有容器、网络、卷
docker-compose down -v

# 清理 Docker 镜像缓存
docker system prune -af

# 重新构建和启动
docker-compose up -d --build
```

⚠️ **注意**：`-v` 参数会删除数据卷，包括数据库数据！

## 验证修复

访问 http://localhost:3000 应该能正常显示博客前端页面，并且能够：
1. 正常登录
2. 正常获取文章列表
3. 正常上传文件
4. 个人信息修改同步正常
