#!/bin/bash

echo "=== 停止并清理 Docker 服务 ==="
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi

echo "✅ Docker 正在运行"
echo ""

# 停止所有容器
echo "🛑 停止所有容器..."
docker-compose down

# 删除所有数据卷（可选，会删除数据库数据）
read -p "是否删除数据卷（包括数据库数据）？[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🗑️  删除数据卷..."
    docker-compose down -v
fi

echo ""
echo "✅ 清理完成"
echo ""
echo "重新启动请运行: ./start-docker.sh"
