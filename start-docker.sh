#!/bin/bash

echo "=== Leaf Blog Docker 启动脚本 ==="
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi

echo "✅ Docker 正在运行"
echo ""

# 停止并删除旧容器
echo "🛑 停止旧容器..."
docker-compose down

echo ""
echo "🏗️  构建并启动服务..."
echo ""

# 启动所有服务
docker-compose up -d --build

echo ""
echo "⏳ 等待服务启动..."
sleep 10

echo ""
echo "📊 检查服务状态..."
docker-compose ps

echo ""
echo "=== 服务已启动 ==="
echo ""
echo "📝 访问地址："
echo "  - 博客前端: http://localhost:3000"
echo "  - 管理后台: http://localhost:3001"
echo "  - API 后端: http://localhost:8888"
echo ""
echo "💾 数据库连接："
echo "  - Host: localhost"
echo "  - Port: 3307 (注意：使用3307而非3306，避免与本地MySQL冲突)"
echo "  - User: root"
echo "  - Password: 123456"
echo "  - Database: leaf_admin"
echo ""
echo "📋 查看日志："
echo "  docker-compose logs -f [服务名]"
echo ""
echo "  服务名："
echo "    - blog-frontend (博客前端)"
echo "    - admin-frontend (管理后台)"
echo "    - api (后端 API)"
echo "    - mysql (数据库)"
echo "    - redis (缓存)"
echo ""
echo "🛑 停止服务："
echo "  ./stop-docker.sh"
echo "  或"
echo "  docker-compose down"
echo ""
