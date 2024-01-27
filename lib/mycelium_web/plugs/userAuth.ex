defmodule MyceliumWeb.UserAuth do
  @moduledoc """
    User auth plug to make queries against the connection
  """
  import Plug.Conn

  @salt "user_auth_salt"
  @doc """
    Init request using the plug with regards to auth and conn updates
  """
  def init(opts), do: opts

  @doc """
    Add the user token to the conn going forwards
  """
  def call(conn, _opts) do
    put_user_token(conn)
  end

  # This below can be a module on its own in order to have us manage the connection.
  # Above we can then import the module as a plug function
  # TODO: We can sign a key here against the salt to have avail for connection
  defp put_user_token(conn) do
    assign(conn, :user, %{ id:  UUID.uuid4() })
  end
end
