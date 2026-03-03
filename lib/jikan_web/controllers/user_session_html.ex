defmodule JikanWeb.UserSessionHTML do
  use JikanWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:jikan, Jikan.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
