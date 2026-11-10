# frozen_string_literal: true
# name: discourse-telegram-oidc
# about: Telegram OpenID Connect login for Discourse
# version: 0.1.0
# authors: Community

require_relative "../../discourse-openid-connect/lib/omniauth_open_id_connect"
require_relative "lib/telegram_oidc"

enabled_site_setting :telegram_oidc_enabled
register_svg_icon "fab-telegram"
auth_provider authenticator: TelegramOidcAuthenticator.new, icon: "fab-telegram"
