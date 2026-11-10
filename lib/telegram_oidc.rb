# frozen_string_literal: true

require "base64"
require "digest"

module OmniAuth
  module Strategies
    class TelegramOidc < OpenIDConnect
      option :name, "telegram"

      # The parent validates issuer, audience, expiry and nonce. Telegram also
      # requires the signature to be checked against its published keys.
      def id_token_info
        return @telegram_verified_info if @telegram_verified_info

        keys = Discourse.cache.fetch("telegram-oidc-jwks", expires_in: 10.minutes) do
          connection = Faraday.new(request: { timeout: 10 }) do |f|
            f.use Faraday::Response::RaiseError
            f.adapter FinalDestination::FaradayAdapter
          end
          JSON.parse(connection.get("https://oauth.telegram.org/.well-known/jwks.json").body)
        end
        JWT.decode(access_token["id_token"], nil, true, algorithms: ["RS256"], jwks: keys)
        @telegram_verified_info = super
      end
    end
  end
end

class TelegramOidcAuthenticator < Auth::ManagedAuthenticator
  def name
    "telegram"
  end

  def display_name
    "Telegram"
  end

  def enabled?
    SiteSetting.telegram_oidc_enabled && SiteSetting.telegram_oidc_client_id.present? &&
      SiteSetting.telegram_oidc_client_secret.present?
  end

  def can_revoke?
    true
  end

  def can_connect_existing_user?
    true
  end

  def after_authenticate(auth_token, existing_account: nil)
    # Telegram supplies no email. Avoid storing access and ID tokens or phone data.
    auth_token[:credentials] = {}
    auth_token[:extra] = {}
    super
  end

  def register_middleware(omniauth)
    omniauth.provider OmniAuth::Strategies::TelegramOidc,
                      name: :telegram,
                      setup: lambda { |env|
                        opts = env["omniauth.strategy"].options
                        opts.deep_merge!(
                          client_id: SiteSetting.telegram_oidc_client_id,
                          client_secret: SiteSetting.telegram_oidc_client_secret,
                          discovery_document: {
                            "issuer" => "https://oauth.telegram.org",
                            "authorization_endpoint" => "https://oauth.telegram.org/auth",
                            "token_endpoint" => "https://oauth.telegram.org/token",
                          },
                          scope: "openid profile",
                          pkce: true,
                          pkce_options: {
                            code_verifier: -> { Base64.urlsafe_encode64(SecureRandom.random_bytes(32), padding: false) },
                            code_challenge: ->(verifier) { Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) },
                            code_challenge_method: "S256",
                          },
                        )
                        opts[:client_options][:connection_opts] = { request: { timeout: 10 } }
                        opts[:client_options][:connection_build] = lambda do |builder|
                          builder.request :url_encoded
                          builder.adapter FinalDestination::FaradayAdapter
                        end
                      }
  end
end
