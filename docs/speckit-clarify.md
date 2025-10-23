# /speckit.clarify 指令最佳实践

## 指令概述

`/speckit.clarify` 用于澄清和完善现有规范中的模糊点、歧义或遗漏部分。它帮助将不清晰的需求转化为明确、可执行的规范。

## 使用场景

- 澄清模糊的业务需求
- 补充缺失的技术细节
- 解决规范中的歧义
- 明确边界条件和异常处理
- 完善用户体验细节

## 最佳实践

### 1. 澄清模糊需求

当遇到不明确的需求时使用：

```
@github/copilot /speckit.clarify 用户权限管理功能中的"管理员可以管理用户"这个描述太模糊，需要明确：
- 管理员可以执行哪些具体操作？
- 对不同角色用户的管理权限是否不同？
- 是否有操作日志记录？
- 删除用户时数据如何处理？
```

### 2. 补充技术实现细节

对技术规范进行详细补充：

```
@github/copilot /speckit.clarify 文件上传功能需要补充以下细节：
- 支持的文件格式和大小限制
- 上传进度显示方式
- 断点续传如何实现
- 文件存储位置和命名规则
- 安全性检查（病毒扫描）
```

### 3. 解决业务逻辑歧义

明确复杂业务场景的处理方式：

```
@github/copilot /speckit.clarify 订单退款流程中存在歧义，需要明确：
- 部分退款时如何计算运费？
- 使用优惠券的订单退款如何处理？
- 退款时间超过7天的特殊情况？
- 商家拒绝退款的申诉流程？
```

## 真实案例示例

### 案例 1：支付系统澄清

**场景**：支付功能规范不够明确

**输入**：

```
@github/copilot /speckit.clarify 在线支付功能规范中"支持多种支付方式"过于笼统，需要澄清：
- 具体支持哪些支付方式？
- 每种支付方式的处理流程是否相同？
- 支付失败后的重试机制如何设计？
- 支付超时如何定义和处理？
- 支付过程中用户取消操作如何处理？
- 不同支付方式的手续费如何计算？
```

**输出示例**：

```markdown
# 在线支付功能澄清规范

## 支持的支付方式明细

### 1. 支付宝

- **接入方式**: 支付宝开放平台 SDK
- **支付场景**:
  - 手机网站支付（移动端）
  - 电脑网站支付（PC 端）
  - APP 支付（原生应用内）
- **处理流程**: 用户选择 → 跳转支付宝 → 支付确认 → 回调验证 → 订单更新
- **超时设置**: 15 分钟
- **手续费**: 0.6%

### 2. 微信支付

- **接入方式**: 微信支付商户平台 API
- **支付场景**:
  - JSAPI 支付（微信内 H5）
  - Native 支付（PC 扫码）
  - APP 支付（原生应用）
- **处理流程**: 用户选择 → 生成预支付订单 → 调起支付 → 异步回调 → 订单确认
- **超时设置**: 15 分钟
- **手续费**: 0.6%

### 3. 银行卡支付

- **接入方式**: 第三方支付网关（如易宝支付）
- **支持卡类**: 借记卡、信用卡（主要银行）
- **处理流程**: 用户选择 → 输入卡信息 → 银行验证 → 支付确认 → 结果返回
- **超时设置**: 5 分钟
- **手续费**: 借记卡 0.35%，信用卡 0.5%

## 支付流程统一处理

### 支付状态定义
```

PENDING - 支付创建，等待用户操作
PROCESSING - 支付处理中
SUCCESS - 支付成功
FAILED - 支付失败
CANCELLED - 用户取消
TIMEOUT - 支付超时

````

### 重试机制
- **自动重试**: 网络异常时自动重试3次，间隔2秒
- **手动重试**: 用户可手动重试支付，24小时内有效
- **失败处理**: 超过重试次数后，订单状态改为"支付失败"

### 超时处理
- **检测机制**: 每5分钟扫描超时订单
- **处理方式**:
  1. 调用支付平台查询接口确认状态
  2. 如确认未支付，订单状态改为"超时取消"
  3. 释放库存和优惠券
  4. 发送通知给用户

### 用户取消处理
- **取消时机**: 用户在支付页面点击取消或返回
- **处理逻辑**:
  1. 立即将订单状态改为"用户取消"
  2. 释放占用的库存
  3. 返还使用的优惠券
  4. 记录取消原因（用户主动取消）

## 异常情况处理

### 支付成功但回调失败
- **检测**: 定时任务查询支付平台订单状态
- **处理**: 发现支付成功但本地订单未更新时，手动触发回调处理
- **通知**: 向用户发送支付成功确认信息

### 重复支付
- **防重**: 基于订单号的幂等性控制
- **检测**: 同一订单多次支付成功时触发
- **处理**: 保留第一次支付，后续支付自动退款

### 部分退款
- **场景**: 订单包含多个商品，部分商品退货
- **计算逻辑**:
  - 商品金额按比例退款
  - 运费：订单金额>免运费门槛则不退运费，否则按比例退
  - 优惠券：不可恢复，退款金额为实付金额

## 技术实现细节

### 数据库设计
```sql
CREATE TABLE payment_orders (
  id VARCHAR(32) PRIMARY KEY,
  order_id VARCHAR(32) NOT NULL,
  payment_method VARCHAR(20) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'PENDING',
  third_party_order_id VARCHAR(64),
  created_at TIMESTAMP DEFAULT NOW(),
  paid_at TIMESTAMP NULL,
  expired_at TIMESTAMP NOT NULL
);
````

### 安全措施

- 所有支付请求使用 HTTPS
- 敏感信息使用 AES 加密存储
- 支付回调验证签名
- 实施支付风控规则（频率限制、异常检测）

```

### 案例 2：用户权限系统澄清

**场景**：权限管理功能需求不清晰

**输入**：
```

@github/copilot /speckit.clarify 用户权限管理系统中的角色和权限概念需要澄清：

- 角色和权限是什么关系？
- 是否支持动态权限分配？
- 权限的粒度如何控制？
- 如何处理权限继承？
- 权限变更是否需要审批流程？
- 如何记录权限操作日志？

````

**输出示例**：
```markdown
# 用户权限管理系统澄清规范

## 权限模型定义

### 基本概念
- **用户(User)**: 系统使用者
- **角色(Role)**: 权限的集合，如"管理员"、"编辑者"、"查看者"
- **权限(Permission)**: 具体的操作权限，如"创建文章"、"删除用户"
- **资源(Resource)**: 权限作用的对象，如"文章"、"用户"、"订单"

### 关系模型
````

用户 ←→ 角色 ←→ 权限 ←→ 资源
↓ ↓ ↓ ↓
多对多 多对多 多对多 一对多

````

## 权限粒度控制

### 1. 功能级权限
```json
{
  "module": "user_management",
  "permissions": [
    "user.create",      // 创建用户
    "user.read",        // 查看用户
    "user.update",      // 更新用户
    "user.delete",      // 删除用户
    "user.export"       // 导出用户
  ]
}
````

### 2. 数据级权限

```json
{
  "resource": "order",
  "scope": "department", // all, department, self
  "conditions": {
    "status": ["pending", "processing"],
    "amount": { "max": 10000 }
  }
}
```

### 3. 字段级权限

```json
{
  "resource": "user",
  "fields": {
    "email": "read",
    "phone": "read",
    "salary": "none", // 隐藏字段
    "password": "none"
  }
}
```

## 动态权限分配机制

### 角色权限配置

```javascript
// 角色定义
const roles = {
  super_admin: {
    name: "超级管理员",
    permissions: ["*"], // 所有权限
    inherits: [],
  },
  dept_manager: {
    name: "部门经理",
    permissions: ["user.read", "user.update", "order.read", "order.update"],
    inherits: ["employee"],
  },
  employee: {
    name: "普通员工",
    permissions: ["profile.read", "profile.update"],
    inherits: [],
  },
};
```

### 临时权限授权

```javascript
// 临时权限（有时效性）
const temporaryPermissions = {
  userId: "user-123",
  permissions: ["order.approve"],
  expiredAt: "2024-12-31T23:59:59Z",
  grantedBy: "admin-456",
  reason: "临时处理订单审批",
};
```

## 权限继承规则

### 继承关系

```
超级管理员
    ├── 部门经理
    │   ├── 主管
    │   └── 普通员工
    └── 系统管理员
        └── 运维人员
```

### 继承逻辑

1. **向上继承**: 子角色自动拥有父角色的所有权限
2. **权限累加**: 用户可拥有多个角色，权限取并集
3. **权限覆盖**: 显式拒绝权限可以覆盖继承的权限

```javascript
// 权限计算示例
function calculateUserPermissions(userId) {
  const userRoles = getUserRoles(userId);
  const inheritedPermissions = new Set();
  const deniedPermissions = new Set();

  // 收集所有角色权限
  userRoles.forEach((role) => {
    role.permissions.forEach((perm) => {
      if (perm.startsWith("!")) {
        deniedPermissions.add(perm.substring(1));
      } else {
        inheritedPermissions.add(perm);
      }
    });
  });

  // 移除被拒绝的权限
  deniedPermissions.forEach((perm) => {
    inheritedPermissions.delete(perm);
  });

  return Array.from(inheritedPermissions);
}
```

## 权限变更审批流程

### 审批级别定义

```json
{
  "approval_rules": {
    "role_assignment": {
      "super_admin": "none", // 无需审批
      "dept_manager": "admin", // 需要管理员审批
      "employee": "manager" // 需要经理审批
    },
    "permission_grant": {
      "high_risk": "two_level", // 两级审批
      "medium_risk": "manager", // 经理审批
      "low_risk": "auto" // 自动通过
    }
  }
}
```

### 审批流程

1. **申请提交**: 用户或管理员提交权限变更申请
2. **自动检查**: 系统检查是否符合自动审批条件
3. **人工审批**: 不符合自动条件的进入人工审批队列
4. **审批通知**: 审批结果通知申请人和相关人员
5. **权限生效**: 审批通过后权限立即生效

## 操作日志记录

### 日志内容

```json
{
  "id": "log-uuid",
  "timestamp": "2024-01-01T12:00:00Z",
  "operator": "admin-123",
  "action": "grant_permission",
  "target_user": "user-456",
  "details": {
    "role_added": "dept_manager",
    "permissions_granted": ["order.approve", "user.update"],
    "approval_id": "approval-789",
    "reason": "部门调整，增加管理权限"
  },
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}
```

### 日志查询接口

```javascript
// 查询权限操作日志
GET /api/admin/permission-logs?
  user_id=user-123&
  action=grant_permission&
  start_date=2024-01-01&
  end_date=2024-01-31&
  page=1&limit=20
```

## 实时权限检查

### 权限验证中间件

```javascript
function checkPermission(resource, action) {
  return async (req, res, next) => {
    const userId = req.user.id;
    const hasPermission = await verifyUserPermission(
      userId,
      `${resource}.${action}`
    );

    if (!hasPermission) {
      return res.status(403).json({
        error: "ACCESS_DENIED",
        message: "您没有执行此操作的权限",
      });
    }

    next();
  };
}

// 使用示例
app.delete(
  "/api/users/:id",
  authenticate,
  checkPermission("user", "delete"),
  deleteUserController
);
```

### 权限缓存策略

- **Redis 缓存**: 用户权限缓存 30 分钟
- **本地缓存**: 权限规则缓存 10 分钟
- **实时更新**: 权限变更时清除相关缓存
- **降级策略**: 缓存服务不可用时直接查询数据库

```

### 案例 3：搜索功能澄清

**场景**：搜索功能需求模糊

**输入**：
```

@github/copilot /speckit.clarify 商品搜索功能中"智能搜索"和"个性化推荐"的含义不明确，需要澄清：

- 智能搜索的具体算法是什么？
- 个性化推荐基于哪些数据？
- 搜索结果排序的优先级如何确定？
- 如何处理拼写错误和同义词？
- 搜索无结果时如何处理？
- 搜索性能要求是什么？

````

**输出示例**：
```markdown
# 商品搜索功能澄清规范

## 智能搜索算法详解

### 1. 搜索相关性算法
**算法模型**: TF-IDF + BM25 + 机器学习排序

**评分计算**:
```javascript
// 综合评分 = 文本相关性 * 0.4 + 商品质量 * 0.3 + 用户行为 * 0.3
const totalScore = (
  textRelevance * 0.4 +
  productQuality * 0.3 +
  userBehavior * 0.3
);
````

**文本相关性因子**:

- 标题完全匹配: 权重 1.0
- 标题部分匹配: 权重 0.8
- 关键词匹配: 权重 0.6
- 描述匹配: 权重 0.4
- 品牌匹配: 权重 0.7

### 2. 查询理解和处理

**拼写纠错**:

```javascript
// 基于编辑距离的拼写纠错
const suggestions = spellChecker.suggest(query, {
  maxDistance: 2, // 最大编辑距离
  minSimilarity: 0.7, // 最小相似度
  useFrequency: true, // 考虑词频
});

if (suggestions.length > 0 && originalResults.length < 3) {
  // 搜索结果少于3个时，提供拼写建议
  return {
    original: originalResults,
    suggestion: suggestions[0],
    correctedResults: searchWithCorrection(suggestions[0]),
  };
}
```

**同义词扩展**:

```json
{
  "synonyms": {
    "手机": ["mobile", "phone", "智能机"],
    "笔记本": ["laptop", "notebook", "电脑"],
    "T恤": ["t-shirt", "短袖", "体恤"]
  }
}
```

## 个性化推荐机制

### 推荐数据源

1. **用户行为数据**:

   - 浏览历史 (权重: 0.3)
   - 购买历史 (权重: 0.4)
   - 收藏商品 (权重: 0.2)
   - 搜索历史 (权重: 0.1)

2. **用户特征**:
   - 年龄段、性别
   - 地理位置
   - 购买力水平
   - 品牌偏好

### 个性化算法

```python
# 协同过滤 + 内容推荐混合算法
def personalized_search(user_id, query, base_results):
    # 获取用户画像
    user_profile = get_user_profile(user_id)

    # 计算用户对每个商品的偏好分数
    preference_scores = []
    for product in base_results:
        score = calculate_preference_score(user_profile, product)
        preference_scores.append(score)

    # 重新排序结果
    personalized_results = rank_by_preference(
        base_results,
        preference_scores
    )

    return personalized_results
```

## 搜索结果排序策略

### 排序优先级（默认）

1. **相关性匹配度** (40%)
2. **商品质量分** (25%)
   - 用户评分: 权重 0.6
   - 销量: 权重 0.4
3. **个性化分数** (20%)
4. **商业因素** (15%)
   - 推广商品: 加权 1.2
   - 库存状态: 有库存 +0.1

### 可选排序方式

```javascript
const sortOptions = {
  relevance: "相关性", // 默认排序
  price_asc: "价格从低到高",
  price_desc: "价格从高到低",
  sales: "销量优先",
  rating: "评分优先",
  newest: "最新上架",
};
```

## 无结果处理策略

### 零结果优化

1. **查询扩展**:

   - 移除修饰词（如"正品"、"包邮"）
   - 同义词替换
   - 分词后部分匹配

2. **推荐替代**:

```javascript
if (searchResults.length === 0) {
  const alternatives = await getAlternatives({
    category: extractCategory(query),
    priceRange: extractPriceRange(query),
    userHistory: getUserSearchHistory(userId),
  });

  return {
    results: [],
    message: `未找到"${query}"的相关商品`,
    alternatives: alternatives,
    suggestions: getPopularSearches(),
  };
}
```

3. **热门推荐**:
   - 同类目热销商品
   - 用户可能感兴趣的商品
   - 促销活动商品

## 搜索性能要求

### 响应时间标准

- **基础搜索**: < 200ms (95th percentile)
- **个性化搜索**: < 500ms (95th percentile)
- **复杂筛选**: < 800ms (95th percentile)

### 并发处理能力

- **QPS 目标**: 1000+ 查询/秒
- **峰值处理**: 3000+ 查询/秒（促销活动期间）

### 技术实现

```yaml
# Elasticsearch 集群配置
elasticsearch:
  cluster:
    nodes: 6
    shards: 12
    replicas: 2
  indices:
    products:
      settings:
        refresh_interval: "30s"
        number_of_shards: 12
        number_of_replicas: 2
```

### 缓存策略

```javascript
// 多级缓存架构
const cacheStrategy = {
  // L1: 本地缓存（热门查询）
  local: {
    ttl: 300, // 5分钟
    maxSize: 1000, // 最多1000个查询
  },

  // L2: Redis 缓存
  redis: {
    ttl: 1800, // 30分钟
    keyPrefix: "search:",
  },

  // L3: Elasticsearch 查询结果缓存
  elasticsearch: {
    requestCache: true,
    fieldDataCache: "40%",
  },
};
```

## 搜索分析和监控

### 关键指标

- **搜索成功率**: 有结果的搜索占比 > 85%
- **点击率**: 搜索结果点击率 > 60%
- **转化率**: 搜索到购买转化率 > 8%
- **零结果率**: 无结果搜索占比 < 15%

### 实时监控

```javascript
// 搜索质量监控
const searchMetrics = {
  queryCount: 0,
  zeroResultCount: 0,
  avgResponseTime: 0,
  topQueries: [],
  failedQueries: [],
};

// 定期报告
setInterval(() => {
  reportSearchMetrics(searchMetrics);
  resetMetrics();
}, 60000); // 每分钟上报
```

```

## 输出格式说明

clarify 指令通常会生成：

1. **概念澄清**：明确定义模糊的术语和概念
2. **详细规则**：补充具体的业务规则和约束条件
3. **技术细节**：完善技术实现的具体方案
4. **异常处理**：明确各种边界情况的处理方式
5. **性能指标**：量化的性能和质量要求

## 注意事项

1. **针对性强**：专门针对现有规范中的模糊点
2. **补充完整**：确保澄清后的规范没有歧义
3. **可执行性**：澄清后的内容应该可以直接指导开发
4. **考虑全面**：包含正常流程和异常情况
5. **量化标准**：尽可能提供可衡量的标准

## 与其他指令的配合

- 基于 `/speckit.specify` 生成的规范进行澄清
- 澄清后可使用 `/speckit.plan` 制定实施计划
- 结合 `/speckit.tasks` 分解具体开发任务
- 使用 `/speckit.implement` 开始具体实现
```
