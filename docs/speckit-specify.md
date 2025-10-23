# /speckit.specify 指令最佳实践

## 指令概述

`/speckit.specify` 是 spec-kit 中最核心的指令，用于创建详细的功能规范。它将抽象的需求转化为具体、可实施的技术规范文档。

## 使用场景

- 将用户需求转化为技术规范
- 定义 API 接口和数据结构
- 明确功能行为和边界条件
- 创建可测试的验收标准

## 最佳实践

### 1. 功能需求规范化

将模糊的业务需求转化为清晰的技术规范：

```
@github/copilot /speckit.specify 用户登录功能：
- 支持邮箱和手机号登录
- 密码强度验证
- 记住登录状态
- 登录失败3次锁定账户
- 支持忘记密码重置
```

### 2. API 接口定义

详细定义 API 的输入输出：

```
@github/copilot /speckit.specify 用户信息查询 API：
- 端点：GET /api/users/:id
- 需要 JWT 认证
- 返回用户基本信息（排除敏感数据）
- 支持字段过滤
- 包含错误处理和状态码
```

### 3. 复杂业务逻辑规范

对复杂的业务流程进行详细规范：

```
@github/copilot /speckit.specify 电商订单处理流程：
- 库存检查和预占
- 价格计算（含优惠券）
- 支付处理
- 订单状态流转
- 异常情况处理
- 通知机制
```

## 真实案例示例

### 案例 1：用户认证系统

**场景**：开发用户注册登录功能

**输入**：

```
@github/copilot /speckit.specify 用户认证系统规范：
- 用户注册（邮箱验证）
- 用户登录（多种方式）
- JWT Token 管理
- 密码安全策略
- 账户锁定机制
- 第三方登录集成
```

**输出示例**：

````markdown
# 用户认证系统技术规范

## 功能概述

实现完整的用户认证系统，包括注册、登录、Token 管理和安全控制。

## API 规范

### 1. 用户注册

**端点**: `POST /api/auth/register`

**请求体**:

```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!",
  "firstName": "张",
  "lastName": "三"
}
```
````

**响应**:

```json
{
  "success": true,
  "message": "注册成功，请检查邮箱验证",
  "data": {
    "userId": "uuid-string",
    "email": "user@example.com",
    "verificationSent": true
  }
}
```

### 2. 用户登录

**端点**: `POST /api/auth/login`

**请求体**:

```json
{
  "identifier": "user@example.com", // 邮箱或手机号
  "password": "SecurePass123!",
  "rememberMe": true
}
```

**响应**:

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt-token",
    "refreshToken": "refresh-token",
    "expiresIn": 3600,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "张三"
    }
  }
}
```

## 业务规则

### 密码策略

- 最小长度：8 位
- 必须包含：大写字母、小写字母、数字、特殊字符
- 不能与前 3 次密码相同
- 密码使用 bcrypt 加密存储

### 账户锁定

- 连续登录失败 3 次锁定账户
- 锁定时间：30 分钟
- 锁定期间提示剩余时间
- 管理员可手动解锁

### Token 管理

- Access Token 有效期：1 小时
- Refresh Token 有效期：30 天
- 支持 Token 刷新机制
- 登出时清除所有 Token

## 数据模型

### User 表

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email_verified BOOLEAN DEFAULT FALSE,
  login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## 错误处理

- 4001: 邮箱已存在
- 4002: 密码不符合要求
- 4003: 账户未验证
- 4004: 账户已锁定
- 4005: 凭据无效

```

### 案例 2：商品搜索功能

**场景**：电商平台商品搜索

**输入**：
```

@github/copilot /speckit.specify 电商商品搜索功能：

- 关键词搜索
- 分类筛选
- 价格区间筛选
- 品牌筛选
- 排序功能
- 分页显示
- 搜索建议
- 搜索历史

````

**输出示例**：
```markdown
# 商品搜索功能技术规范

## 功能概述
提供高性能的商品搜索功能，支持多维度筛选和智能推荐。

## API 规范

### 搜索商品
**端点**: `GET /api/products/search`

**查询参数**:
````

q: 搜索关键词
category: 商品分类 ID
price_min: 最低价格
price_max: 最高价格
brand: 品牌 ID 数组
sort: 排序方式 (price_asc, price_desc, sales, rating)
page: 页码 (默认 1)
limit: 每页数量 (默认 20，最大 100)

````

**响应**:
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": "product-id",
        "name": "商品名称",
        "price": 99.99,
        "originalPrice": 149.99,
        "image": "image-url",
        "rating": 4.5,
        "salesCount": 1000,
        "brand": "品牌名",
        "category": "分类名"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 500,
      "pages": 25
    },
    "filters": {
      "categories": [...],
      "brands": [...],
      "priceRange": {
        "min": 0,
        "max": 9999
      }
    }
  }
}
````

## 搜索算法

### 相关性评分

1. **关键词匹配** (40%)

   - 标题完全匹配：权重 1.0
   - 标题部分匹配：权重 0.8
   - 描述匹配：权重 0.6

2. **商品质量** (30%)

   - 评分：权重 0.5
   - 销量：权重 0.3
   - 库存状态：权重 0.2

3. **用户行为** (30%)
   - 点击率：权重 0.4
   - 转化率：权重 0.6

### 搜索建议

- 基于用户输入实时生成
- 包含热门搜索词
- 支持拼写纠错
- 最多显示 10 个建议

## 性能要求

- 搜索响应时间 < 200ms
- 支持并发搜索 1000 QPS
- 使用 Elasticsearch 作为搜索引擎
- 实施搜索结果缓存机制

```

### 案例 3：实时聊天系统

**场景**：开发实时聊天功能

**输入**：
```

@github/copilot /speckit.specify 实时聊天系统：

- 一对一聊天
- 群组聊天
- 消息类型支持（文本、图片、文件）
- 消息状态（已发送、已送达、已读）
- 在线状态显示
- 消息历史
- 消息推送
- 聊天室管理

````

**输出示例**：
```markdown
# 实时聊天系统技术规范

## 系统架构
- WebSocket 实时通信
- Redis 消息队列
- MongoDB 消息存储
- Socket.IO 客户端连接管理

## WebSocket 事件定义

### 客户端 → 服务器

#### 发送消息
```javascript
socket.emit('send_message', {
  chatId: 'chat-uuid',
  content: '消息内容',
  type: 'text', // text, image, file
  replyTo: 'message-id' // 可选，回复消息
});
````

#### 加入聊天室

```javascript
socket.emit("join_chat", {
  chatId: "chat-uuid",
});
```

### 服务器 → 客户端

#### 新消息通知

```javascript
socket.emit("new_message", {
  messageId: "msg-uuid",
  chatId: "chat-uuid",
  senderId: "user-uuid",
  senderName: "张三",
  content: "消息内容",
  type: "text",
  timestamp: "2024-01-01T12:00:00Z",
  replyTo: null,
});
```

#### 消息状态更新

```javascript
socket.emit("message_status", {
  messageId: "msg-uuid",
  status: "delivered", // sent, delivered, read
  userId: "user-uuid",
});
```

## 数据模型

### Chat 表

```sql
CREATE TABLE chats (
  id UUID PRIMARY KEY,
  type VARCHAR(20) NOT NULL, -- 'direct', 'group'
  name VARCHAR(255), -- 群组名称
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Message 表

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  chat_id UUID REFERENCES chats(id),
  sender_id UUID REFERENCES users(id),
  content TEXT NOT NULL,
  type VARCHAR(20) DEFAULT 'text',
  reply_to UUID REFERENCES messages(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 消息推送

- 使用 Firebase Cloud Messaging (FCM)
- 离线用户接收推送通知
- 推送内容包含发送者和消息预览
- 支持免打扰模式设置

## 性能优化

- 消息分页加载（每次 20 条）
- 图片消息压缩和缩略图
- 连接心跳检测机制
- 消息去重处理

```

## 输出格式说明

specify 指令通常会生成：

1. **功能概述**：简述功能目标和范围
2. **API 规范**：详细的接口定义
3. **数据模型**：数据库表结构和关系
4. **业务规则**：具体的业务逻辑和约束
5. **错误处理**：异常情况和错误码
6. **性能要求**：响应时间和并发要求

## 注意事项

1. **输入要具体**：提供明确的功能点和要求
2. **考虑边界情况**：包含异常处理和错误场景
3. **性能要求明确**：指定响应时间和并发量
4. **数据安全**：考虑数据验证和安全措施
5. **可测试性**：确保规范可以转化为测试用例

## 与其他指令的配合

- 先使用 `/speckit.constitution` 建立项目原则
- 使用 `/speckit.clarify` 澄清模糊的规范点
- 使用 `/speckit.plan` 制定实施计划
- 使用 `/speckit.tasks` 分解开发任务
```
