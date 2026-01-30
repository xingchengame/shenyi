# init_codeup.py
import base64
import subprocess
import sys
import os

# ----------------- 配置 -----------------
ALIYUN_ORG_ID = "67a361cf556e6cdab537117a"
ALIYUN_REPO_MAPPING = {
    "zhenxun-bot-resources": "4957431",
    "zhenxun_bot_plugins_index": "4957418",
    "zhenxun_bot_plugins": "4957429",
    "zhenxun_docs": "4957426",
    "zhenxun_bot": "4957428",
}
RDC_access_token_encrypted = (
    "cHQtYXp0allnQWpub0FYZWpqZm1RWGtneHk0XzBlMmYzZTZmLWQwOWItNDE4Mi1iZWUx"
    "LTQ1ZTFkYjI0NGRlMg=="
)

TARGET_REPO = sys.argv[1] if len(sys.argv) > 1 else "zhenxun_bot"

# ----------------- 解密 RDC Token -----------------
RDC_token = base64.b64decode(RDC_access_token_encrypted).decode()

# ----------------- 构建正确 URL -----------------
repo_url = f"https://oauth2:{RDC_token}@codeup.aliyun.com/{ALIYUN_ORG_ID}/zhenxun-org/{TARGET_REPO}.git"

# ----------------- Git 初始化 & 拉取 -----------------
try:
    if not os.path.exists(".git"):
        print("未检测到 Git 仓库，正在初始化...")
        subprocess.run(["git", "init"], check=True)
        subprocess.run(["git", "remote", "add", "origin", repo_url], check=True)
        print(f"正在从阿里云 Codeup 拉取 {TARGET_REPO} ...")
        subprocess.run(["git", "pull", "origin", "main", "--allow-unrelated-histories"], check=True)
        print("仓库初始化完成。")
    else:
        print(".git 已存在，跳过初始化。")
except subprocess.CalledProcessError as e:
    print(f"❌ Git 操作失败: {e}")
    sys.exit(1)
