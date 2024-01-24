defmodule MyceliumWeb.UserAuth do
  @moduledoc """
    User auth plug to make queries against the connection
  """
  import Plug.Conn

  @salt "user_auth_salt"
  @doc """
    Initial data we want to add to have around when using the current assigns
  """
  def init(opts), do: opts

  @doc """
    Function call to capture on the user connection
    Here we can check the DB for the user details or id
  """
  def call(conn, _opts) do
    put_user_token(conn)
  end

  # The salt that we use to verify and sign the user details for the token
  def crypto_salt() do
    @salt
  end

  @doc """
    This below can be a module on its own in order to have us manage the connection.
    Above we can then import the module as a plug function
  """
  # TODO: this needs to be a constant id for the user (auth)
  defp put_user_token(conn) do
    # token = Phoenix.Token.sign(conn, crypto_salt(), %{ id: :rand.uniform() * 5 })
    # assign(conn, :user_token, token)
    assign(conn, :user, %{ id:  UUID.uuid4() })
  end
end
