# Discourse Telegram OIDC 登录插件

为 Discourse 添加 Telegram 登录按钮，使用 Telegram 新版 OpenID Connect 授权码流程、PKCE 和 RS256 签名验证。插件依赖 Discourse 自带的 `discourse-openid-connect` 插件代码，不需要启用其通用 OIDC 登录。目标是包含该插件的当前 Discourse 版本；尚未在真实 Discourse 实例或 Telegram Bot 上完成端到端验证，部署前请先在测试站验证。

## 安装

1. 将整个 `discourse-telegram-oidc` 目录放在 Discourse 的 `plugins/` 目录下，与 `discourse-openid-connect` 同级。生产 Docker 安装通常需要将此目录发布到 Git 仓库，再按 Discourse 标准插件安装方法加入 `app.yml` 并重建容器。不要将密钥放进 Git。
2. 在 Telegram 的 @BotFather 中创建或选择机器人，打开 Login Widget，登记论坛地址和完整回调地址 `https://论坛域名/auth/telegram/callback`。如果论坛安装在子路径下，回调地址也须包含子路径。取得 Client ID 和 Client Secret。
3. 在 Discourse 管理后台的设置中填写 `telegram oidc client id` 和 `telegram oidc client secret`，启用 `telegram oidc enabled`。在 BotFather 保持 ID token 签名算法为 RS256。
4. 在测试站用全新 Telegram 账号完成登录与注册，再测试已有用户绑定、解绑和再次登录。Telegram 不提供邮箱；Discourse 注册流程会要求用户提供邮箱并按站点设置验证。

## 注意

- 该实现使用 Telegram 的稳定 `sub` 识别账号，不按用户名或邮箱自动匹配账号。
- 如果已有其他 OIDC 登录，本插件使用独立的 `telegram` provider，不修改通用 OIDC 设置。
- 在生产环境启用前，需验证当前 Discourse 版本中内置 OIDC 策略的接口、BotFather 回调设置和 Telegram 返回的 nonce。此代码未经独立安全审计。
- 升级 Discourse 后应在测试站重新验证登录。切换或删除插件可能影响已关联 Telegram 的用户登录；请保留其他登录方式。

参考：[Telegram 登录文档](https://core.telegram.org/bots/telegram-login)、[Discourse 认证方法](https://github.com/discourse/discourse/blob/main/docs/developer-guides/docs/03-code-internals/16-authentication-method.md)。
