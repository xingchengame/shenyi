const express = require('express');
const fs = require('fs');
const path = require('path');
const nodemailer = require('nodemailer'); // 邮件发送依赖
const app = express();
const PORT = 3000;

// JSON文件存储目录
const JSON_DIR = path.join(__dirname, 'json');

// ========== 1. 基础配置 ==========
// 解析JSON请求体
app.use(express.json());
// 静态文件托管（前端页面）
app.use(express.static(__dirname));
// 跨域配置
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

// ========== 2. 邮箱配置（核心修复：删除无效文本） ==========
const emailConfig = {
    host: 'smtp.qq.com',
    port: 465,
    secure: true,
    auth: {
        user: '3675976715@qq.com', // 你的QQ邮箱
        pass: 'ilrhkwdcezaldbgb'   // 你的QQ邮箱授权码
    }
};

// 创建邮件发送器
const transporter = nodemailer.createTransport(emailConfig);

// 发送邮件函数（Promise封装，避免回调地狱）
async function sendEmail(toEmail, code) {
    try {
        await transporter.sendMail({
            from: '"沈忆世界ShenYiWorld" <3675976715@qq.com>',
            to: toEmail,
            subject: '注册验证码',
            text: `你现在正在注册沈忆世界账号

你的验证码为：${code}

验证码5分钟内有效
请勿将验证码泄露给他人

欢迎您的加入
缄默记忆唯一，世界曾存旧痕`
        });
        return true;
    } catch (error) {
        console.error(`❌ 发送邮件失败: ${error.message}`);
        return false;
    }
}

// ========== 3. 工具函数（读取/写入JSON文件） ==========
function init() {
    // 创建json目录（不存在则创建）
    if (!fs.existsSync(JSON_DIR)) {
        fs.mkdirSync(JSON_DIR, { recursive: true });
        console.log(`✅ 创建json目录: ${JSON_DIR}`);
    }

    // 默认文件列表
    const defaultFiles = [
        { name: 'user.json', content: [] },
        { name: 'verification.json', content: {} },
        { name: 'point.json', content: { users: {} } },
        { name: 'friends.json', content: { users: {} } },
        { name: 'apps.json', content: { users: {} } },
        { name: 'announcements.json', content: [{
            id: 1,
            title: "系统更新通知",
            content: "V1.0版本正式上线，新增找回密码和消息功能",
            time: "2025-11-21 10:00:00"
        }]},
        { name: 'friendRequests.json', content: {} }
    ];

    // 初始化文件
    defaultFiles.forEach(file => {
        const filePath = path.join(JSON_DIR, file.name);
        if (!fs.existsSync(filePath)) {
            fs.writeFileSync(filePath, JSON.stringify(file.content, null, 2), 'utf8');
            console.log(`✅ 初始化文件: ${filePath}`);
        } else if (file.name === 'user.json') {
            // 校验user.json格式
            try {
                const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                if (!Array.isArray(data)) {
                    fs.writeFileSync(filePath, JSON.stringify([], null, 2), 'utf8');
                    console.log(`✅ 修复user.json为数组格式`);
                }
            } catch (e) {
                fs.writeFileSync(filePath, JSON.stringify([], null, 2), 'utf8');
                console.log(`✅ 修复损坏的user.json`);
            }
        }
    });
}

function readJson(filename) {
    const filePath = path.join(JSON_DIR, filename);
    try {
        if (!fs.existsSync(filePath)) {
            console.error(`❌ 文件不存在: ${filePath}`);
            return filename === 'user.json' ? [] : {};
        }
        const data = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        console.error(`❌ 读取${filename}失败: ${e.message}`);
        return filename === 'user.json' ? [] : {};
    }
}

function writeJson(filename, data) {
    const filePath = path.join(JSON_DIR, filename);
    try {
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
        console.log(`✅ 写入${filename}成功`);
        return true;
    } catch (e) {
        console.error(`❌ 写入${filename}失败: ${e.message}`);
        return false;
    }
}

// ========== 4. 业务接口 ==========
// 登录接口
app.post('/api/login', (req, res) => {
    try {
        const { username, password } = req.body;
        
        if (!username || !password) {
            return res.json({
                success: false,
                message: '用户名和密码不能为空'
            });
        }

        const users = readJson('user.json');
        const matchedUser = users.find(user => 
            user.username === username && user.password === password
        );

        if (!matchedUser) {
            return res.json({
                success: false,
                message: '用户名或密码错误'
            });
        }

        res.json({
            success: true,
            message: '登录成功',
            data: {
                username: matchedUser.username,
                uid: matchedUser.uid,
                email: matchedUser.email
            }
        });
    } catch (e) {
        console.error(`❌ 登录接口异常: ${e.message}`);
        res.json({
            success: false,
            message: '服务器内部错误'
        });
    }
});

// 发送验证码接口
app.post('/api/send-verification', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.json({
                success: false,
                message: '请输入邮箱'
            });
        }

        // 邮箱格式验证
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.json({
                success: false,
                message: '请输入有效的邮箱地址'
            });
        }

        // 检查邮箱是否已注册
        const users = readJson('user.json');
        if (users.some(user => user.email.toLowerCase() === email.toLowerCase())) {
            return res.json({
                success: false,
                message: '该邮箱已注册'
            });
        }

        // 生成6位验证码
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const verificationData = readJson('verification.json');
        
        // 存储验证码（10分钟有效期）
        verificationData[email] = {
            code,
            expireTime: Date.now() + 10 * 60 * 1000
        };
        writeJson('verification.json', verificationData);
        
        // 发送邮件
        const sendResult = await sendEmail(email, code);
        if (!sendResult) {
            return res.json({
                success: false,
                message: '邮件发送失败，请稍后重试'
            });
        }

        console.log(`✅ 向${email}发送验证码: ${code}`);
        res.json({
            success: true,
            message: '验证码已发送，请注意查收'
        });
    } catch (e) {
        console.error(`❌ 发送验证码异常: ${e.message}`);
        res.json({
            success: false,
            message: '服务器内部错误'
        });
    }
});

// 注册接口
app.post('/api/register', (req, res) => {
    try {
        const { username, email, code, password } = req.body;
        
        if (!username || !email || !code || !password) {
            return res.json({
                success: false,
                message: '请填写完整信息'
            });
        }

        // 验证验证码
        const verificationData = readJson('verification.json');
        const verifyInfo = verificationData[email];
        if (!verifyInfo) {
            return res.json({
                success: false,
                message: '验证码不存在，请重新发送'
            });
        }
        if (verifyInfo.code !== code) {
            return res.json({
                success: false,
                message: '验证码错误'
            });
        }
        if (Date.now() > verifyInfo.expireTime) {
            return res.json({
                success: false,
                message: '验证码已过期'
            });
        }

        // 检查用户名/邮箱是否已存在
        const users = readJson('user.json');
        if (users.some(user => user.username === username)) {
            return res.json({
                success: false,
                message: '用户名已存在'
            });
        }
        if (users.some(user => user.email.toLowerCase() === email.toLowerCase())) {
            return res.json({
                success: false,
                message: '邮箱已注册'
            });
        }

        // 生成UID
        const uid = users.length > 0 
            ? (Math.max(...users.map(u => parseInt(u.uid))) + 1).toString()
            : '10001';

        // 创建新用户
        const newUser = {
            uid,
            username,
            email,
            password,
            createTime: new Date().toLocaleString()
        };
        users.push(newUser);
        writeJson('user.json', users);

        // 清空验证码
        delete verificationData[email];
        writeJson('verification.json', verificationData);

        res.json({
            success: true,
            message: '注册成功'
        });
    } catch (e) {
        console.error(`❌ 注册接口异常: ${e.message}`);
        res.json({
            success: false,
            message: '服务器内部错误'
        });
    }
});

// ========== 5. 启动服务 ==========
// 初始化文件
init();

// 启动服务器
app.listen(PORT, () => {
    console.log(`✅ Node.js服务已启动: http://localhost:${PORT}`);
    console.log(`✅ 邮箱配置完成，使用账号: 3675976715@qq.com`);
});