# /speckit.implement 指令最佳实践

## 指令概述

`/speckit.implement` 基于技术规范和任务清单，生成具体的代码实现。这是 spec-kit 工作流程的最后一步，将抽象的规范转化为可运行的代码。

## 基本用法

### 直接使用（常见方式）
```
@github/copilot /speckit.implement
```
**实际效果**：
- 基于当前的规范或任务文档生成代码
- 自动识别需要实现的功能模块
- 生成符合最佳实践的代码结构

### 带描述使用
```
@github/copilot /speckit.implement [具体功能或模块的实现]
```

## 使用场景

- 根据技术规范生成代码框架
- 实现特定功能模块的代码
- 基于任务清单生成对应的代码
- 创建符合规范的API接口实现

## 实际使用场景

### 基于规范文档实现

**操作步骤**：
1. 在技术规范文档中使用 `/speckit.implement`
2. Copilot 分析规范内容
3. 生成对应的代码实现

### 针对特定任务实现

在任务描述中使用，获得该任务的具体代码实现。

## 最佳实践

### 1. 在规范文档中直接使用

直接在技术规范中使用，获得完整的功能实现：
- 自动生成数据模型
- 创建API接口代码
- 实现业务逻辑

### 2. 分模块逐步实现

针对不同的功能模块分别使用，确保代码的模块化和可维护性。

## 真实案例示例

### 案例 1：用户认证系统实现

**输入**：在用户认证规范文档中执行 `/speckit.implement`

**输出示例**：
```markdown
# 用户认证系统代码实现

## 数据模型实现

### User Model (Prisma Schema)
```prisma
// prisma/schema.prisma

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  passwordHash  String
  firstName     String?
  lastName      String?
  emailVerified Boolean   @default(false)
  loginAttempts Int       @default(0)
  lockedUntil   DateTime?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  // 关联关系
  sessions     UserSession[]
  profile      UserProfile?

  @@map("users")
}

model UserSession {
  id           String   @id @default(cuid())
  userId       String
  refreshToken String   @unique
  expiresAt    DateTime
  createdAt    DateTime @default(now())
  ipAddress    String?
  userAgent    String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("user_sessions")
}

model UserProfile {
  id        String    @id @default(cuid())
  userId    String    @unique
  avatar    String?
  phone     String?
  birthday  DateTime?
  bio       String?
  updatedAt DateTime  @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("user_profiles")
}
```

## 后端API实现

### 认证控制器
```typescript
// src/controllers/auth.controller.ts

import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { sendVerificationEmail } from '../services/email.service';
import { AuthRequest } from '../types/auth.types';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET!;
const JWT_EXPIRES_IN = '1h';
const REFRESH_TOKEN_EXPIRES_IN = 30 * 24 * 60 * 60 * 1000; // 30 days

export class AuthController {
  // 用户注册
  async register(req: Request, res: Response) {
    try {
      const { email, password, firstName, lastName } = req.body;

      // 验证输入
      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: '邮箱和密码是必填项'
        });
      }

      // 检查用户是否已存在
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: '该邮箱已被注册'
        });
      }

      // 密码加密
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(password, saltRounds);

      // 创建用户
      const user = await prisma.user.create({
        data: {
          email,
          passwordHash,
          firstName,
          lastName
        },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          emailVerified: true,
          createdAt: true
        }
      });

      // 发送验证邮件
      await sendVerificationEmail(user.email, user.id);

      res.status(201).json({
        success: true,
        message: '注册成功，请检查邮箱完成验证',
        data: { user }
      });

    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: '注册失败，请稍后重试'
      });
    }
  }

  // 用户登录
  async login(req: Request, res: Response) {
    try {
      const { email, password, rememberMe } = req.body;
      const ipAddress = req.ip;
      const userAgent = req.get('User-Agent');

      // 查找用户
      const user = await prisma.user.findUnique({
        where: { email }
      });

      if (!user) {
        return res.status(401).json({
          success: false,
          message: '邮箱或密码错误'
        });
      }

      // 检查账户是否被锁定
      if (user.lockedUntil && user.lockedUntil > new Date()) {
        const remainingTime = Math.ceil(
          (user.lockedUntil.getTime() - Date.now()) / 1000 / 60
        );
        return res.status(423).json({
          success: false,
          message: `账户已锁定，请 ${remainingTime} 分钟后重试`
        });
      }

      // 验证密码
      const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

      if (!isPasswordValid) {
        // 增加登录失败计数
        const loginAttempts = user.loginAttempts + 1;
        const updateData: any = { loginAttempts };

        // 超过3次失败，锁定账户30分钟
        if (loginAttempts >= 3) {
          updateData.lockedUntil = new Date(Date.now() + 30 * 60 * 1000);
        }

        await prisma.user.update({
          where: { id: user.id },
          data: updateData
        });

        return res.status(401).json({
          success: false,
          message: '邮箱或密码错误'
        });
      }

      // 重置登录失败计数和锁定状态
      if (user.loginAttempts > 0 || user.lockedUntil) {
        await prisma.user.update({
          where: { id: user.id },
          data: {
            loginAttempts: 0,
            lockedUntil: null
          }
        });
      }

      // 生成 JWT token
      const accessToken = jwt.sign(
        { userId: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      // 生成 refresh token
      const refreshToken = jwt.sign(
        { userId: user.id, type: 'refresh' },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      // 保存 session
      await prisma.userSession.create({
        data: {
          userId: user.id,
          refreshToken,
          expiresAt: new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN),
          ipAddress,
          userAgent
        }
      });

      // 设置 refresh token cookie
      const cookieOptions = {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict' as const,
        maxAge: rememberMe ? REFRESH_TOKEN_EXPIRES_IN : undefined
      };

      res.cookie('refreshToken', refreshToken, cookieOptions);

      res.json({
        success: true,
        data: {
          accessToken,
          expiresIn: 3600, // 1 hour in seconds
          user: {
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            emailVerified: user.emailVerified
          }
        }
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: '登录失败，请稍后重试'
      });
    }
  }

  // 刷新 token
  async refreshToken(req: Request, res: Response) {
    try {
      const { refreshToken } = req.cookies;

      if (!refreshToken) {
        return res.status(401).json({
          success: false,
          message: '未找到刷新令牌'
        });
      }

      // 验证 refresh token
      const decoded = jwt.verify(refreshToken, JWT_SECRET) as any;
      
      if (decoded.type !== 'refresh') {
        return res.status(401).json({
          success: false,
          message: '无效的刷新令牌'
        });
      }

      // 查找 session
      const session = await prisma.userSession.findUnique({
        where: { refreshToken },
        include: { user: true }
      });

      if (!session || session.expiresAt < new Date()) {
        return res.status(401).json({
          success: false,
          message: '刷新令牌已过期'
        });
      }

      // 生成新的 access token
      const accessToken = jwt.sign(
        { userId: session.user.id, email: session.user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      res.json({
        success: true,
        data: {
          accessToken,
          expiresIn: 3600
        }
      });

    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(401).json({
        success: false,
        message: '刷新令牌无效'
      });
    }
  }

  // 用户登出
  async logout(req: AuthRequest, res: Response) {
    try {
      const { refreshToken } = req.cookies;

      if (refreshToken) {
        // 删除 session
        await prisma.userSession.deleteMany({
          where: { refreshToken }
        });
      }

      // 清除 cookie
      res.clearCookie('refreshToken');

      res.json({
        success: true,
        message: '登出成功'
      });

    } catch (error) {
      console.error('Logout error:', error);
      res.status(500).json({
        success: false,
        message: '登出失败'
      });
    }
  }
}
```

### 认证中间件
```typescript
// src/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../types/auth.types';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET!;

export async function authMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // 验证 JWT token
    const decoded = jwt.verify(token, JWT_SECRET) as any;

    // 查找用户
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        emailVerified: true
      }
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: '用户不存在'
      });
    }

    // 将用户信息添加到请求对象
    req.user = user;
    next();

  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({
        success: false,
        message: '令牌已过期'
      });
    }

    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(401).json({
        success: false,
        message: '无效的令牌'
      });
    }

    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: '认证验证失败'
    });
  }
}

// 可选认证中间件
export async function optionalAuthMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(); // 继续执行，但没有用户信息
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, JWT_SECRET) as any;

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        emailVerified: true
      }
    });

    if (user) {
      req.user = user;
    }

    next();

  } catch (error) {
    // 忽略认证错误，继续执行
    next();
  }
}
```

## 前端实现

### React 认证组件
```typescript
// src/components/auth/LoginForm.tsx

import React, { useState } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../ui/Button';
import { Input } from '../ui/Input';
import { Alert } from '../ui/Alert';

interface LoginFormData {
  email: string;
  password: string;
  rememberMe: boolean;
}

export const LoginForm: React.FC = () => {
  const [formData, setFormData] = useState<LoginFormData>({
    email: '',
    password: '',
    rememberMe: false
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const { login, isLoading, error } = useAuth();

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.email) {
      newErrors.email = '请输入邮箱地址';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = '请输入有效的邮箱地址';
    }

    if (!formData.password) {
      newErrors.password = '请输入密码';
    } else if (formData.password.length < 6) {
      newErrors.password = '密码至少6位字符';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    try {
      await login(formData);
    } catch (err) {
      // Error handled by useAuth hook
    }
  };

  const handleInputChange = (field: keyof LoginFormData) => (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const value = field === 'rememberMe' ? e.target.checked : e.target.value;
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // 清除相关错误
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  return (
    <div className="max-w-md mx-auto mt-8 p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold text-center mb-6">用户登录</h2>
      
      {error && (
        <Alert type="error" className="mb-4">
          {error}
        </Alert>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Input
            type="email"
            placeholder="邮箱地址"
            value={formData.email}
            onChange={handleInputChange('email')}
            error={errors.email}
            disabled={isLoading}
          />
        </div>

        <div>
          <Input
            type="password"
            placeholder="密码"
            value={formData.password}
            onChange={handleInputChange('password')}
            error={errors.password}
            disabled={isLoading}
          />
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id="rememberMe"
            checked={formData.rememberMe}
            onChange={handleInputChange('rememberMe')}
            disabled={isLoading}
            className="mr-2"
          />
          <label htmlFor="rememberMe" className="text-sm text-gray-600">
            记住我
          </label>
        </div>

        <Button
          type="submit"
          className="w-full"
          disabled={isLoading}
          loading={isLoading}
        >
          登录
        </Button>
      </form>

      <div className="mt-4 text-center">
        <a href="/forgot-password" className="text-sm text-blue-600 hover:underline">
          忘记密码？
        </a>
      </div>

      <div className="mt-2 text-center">
        <span className="text-sm text-gray-600">
          还没有账号？
          <a href="/register" className="text-blue-600 hover:underline ml-1">
            立即注册
          </a>
        </span>
      </div>
    </div>
  );
};
```

### 认证 Hook
```typescript
// src/hooks/useAuth.ts

import { useState, useCallback, useContext } from 'react';
import { AuthContext } from '../contexts/AuthContext';
import { authAPI } from '../services/auth.api';

interface LoginData {
  email: string;
  password: string;
  rememberMe?: boolean;
}

interface RegisterData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }

  const { user, setUser, setToken } = context;

  const login = useCallback(async (data: LoginData) => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await authAPI.login(data);
      
      if (response.success) {
        setToken(response.data.accessToken);
        setUser(response.data.user);
        
        // 存储到 localStorage
        localStorage.setItem('accessToken', response.data.accessToken);
        
        return response.data;
      } else {
        throw new Error(response.message);
      }
    } catch (err: any) {
      const message = err.response?.data?.message || err.message || '登录失败';
      setError(message);
      throw new Error(message);
    } finally {
      setIsLoading(false);
    }
  }, [setUser, setToken]);

  const register = useCallback(async (data: RegisterData) => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await authAPI.register(data);
      
      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message);
      }
    } catch (err: any) {
      const message = err.response?.data?.message || err.message || '注册失败';
      setError(message);
      throw new Error(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = useCallback(async () => {
    setIsLoading(true);

    try {
      await authAPI.logout();
    } catch (err) {
      console.error('Logout error:', err);
    } finally {
      setUser(null);
      setToken(null);
      localStorage.removeItem('accessToken');
      setIsLoading(false);
    }
  }, [setUser, setToken]);

  return {
    user,
    isAuthenticated: !!user,
    isLoading,
    error,
    login,
    register,
    logout
  };
};
```

## 测试实现

### API 测试
```typescript
// tests/auth.test.ts

import request from 'supertest';
import { app } from '../src/app';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

describe('Auth API', () => {
  beforeEach(async () => {
    // 清理测试数据
    await prisma.userSession.deleteMany();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'SecurePass123!',
        firstName: '张',
        lastName: '三'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.email).toBe(userData.email);
      expect(response.body.data.user.firstName).toBe(userData.firstName);
    });

    it('should reject duplicate email registration', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'SecurePass123!',
        firstName: '张',
        lastName: '三'
      };

      // 第一次注册
      await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      // 第二次注册相同邮箱
      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('已被注册');
    });
  });

  describe('POST /api/auth/login', () => {
    let testUser: any;

    beforeEach(async () => {
      // 创建测试用户
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'SecurePass123!',
          firstName: '张',
          lastName: '三'
        });

      testUser = response.body.data.user;
    });

    it('should login successfully with correct credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'SecurePass123!'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.user.email).toBe('test@example.com');
    });

    it('should reject login with wrong password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'WrongPassword'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('密码错误');
    });

    it('should lock account after 3 failed attempts', async () => {
      // 3次错误登录
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: 'test@example.com',
            password: 'WrongPassword'
          });
      }

      // 第4次尝试应该返回账户锁定
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'SecurePass123!'
        })
        .expect(423);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('账户已锁定');
    });
  });
});
```
```

### 案例 2：商品API实现

**输入**：在商品管理规范中执行 `/speckit.implement`

**输出示例**：
```markdown
# 商品管理API实现

## 数据模型
```prisma
model Product {
  id          String   @id @default(cuid())
  name        String
  description String?
  price       Decimal  @db.Decimal(10, 2)
  sku         String   @unique
  categoryId  String
  imageUrls   String[]
  isActive    Boolean  @default(true)
  stock       Int      @default(0)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  category Category @relation(fields: [categoryId], references: [id])
  
  @@map("products")
}
```

## API控制器实现
```typescript
export class ProductController {
  async createProduct(req: Request, res: Response) {
    // 商品创建逻辑
  }
  
  async getProducts(req: Request, res: Response) {
    // 商品列表查询
  }
  
  async searchProducts(req: Request, res: Response) {
    // 商品搜索实现
  }
}
```
```

## 输出格式说明

implement 指令生成的核心内容：

1. **数据模型** - 完整的数据库模型定义
2. **API实现** - 具体的控制器和路由代码
3. **业务逻辑** - 核心功能的实现代码
4. **前端组件** - 对应的React/Vue组件
5. **测试代码** - 单元测试和集成测试

## 使用技巧

1. **保持规范一致** - 生成的代码严格遵循技术规范
2. **最佳实践** - 自动应用编码最佳实践和设计模式
3. **完整实现** - 包含错误处理、验证、测试等完整功能
4. **可运行代码** - 生成的代码可以直接运行或只需少量调整
5. **文档齐全** - 包含必要的注释和使用说明

## 与其他指令配合

- 基于 `/speckit.specify` 的规范生成实现
- 根据 `/speckit.tasks` 的任务清单生成代码
- 结合 `/speckit.plan` 的开发计划实施
- 使用 `/speckit.clarify` 澄清实现细节