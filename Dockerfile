# --------- 构建阶段 ----------
FROM node:20-alpine AS build

# 先装 pnpm
RUN corepack enable
RUN corepack prepare pnpm@latest --activate

WORKDIR /app

# 若你在云构建时有代理，可在这里添加 ENV http_proxy/https_proxy

# 复制 pnpm 配置和 lockfile，单独 copy 优化缓存
COPY pnpm-lock.yaml ./
COPY package.json ./
# COPY pnpm-workspace.yaml .  # 如果用的是 monorepo, 否则可删去

# 安装依赖
RUN pnpm install --frozen-lockfile

# 再 copy 所有源代码
COPY . .

# 构建（scripts.build 会先 type-check、再 build-only）
RUN pnpm run build

# --------- 生产阶段 ----------
FROM nginx:alpine AS production

# 删除默认首页
RUN rm -rf /usr/share/nginx/html/*

# 将打包后的静态文件拷入 nginx 容器
COPY --from=build /app/dist /usr/share/nginx/html

# 可选：自定义 nginx 配置（可根据 SPA 需求定制，见下）
# COPY ./nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
