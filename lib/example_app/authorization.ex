defmodule ExampleApp.Authorization do
  # this is default for ExampeApp's authorization:
  # - no requieres roles (empty list)
  # - retrieve user roles via a helper function
  defstruct required: [], get_userroles: &ExampleApp.Authorization.Helper.get_userroles_fun/1
end

defimpl Plug.Authorization.Roles.Config, for: Skeleton.ExampleApp do
  # in more sophistacted apps the required roles could be
  # the result of some fancy calculation, but here it's just
  # what you specify when using 
  # `plug Plug.Authorization.Roles %ExampleApp.Authorization{ required: ["admin", "editor"] }
  def required(      opts ), do: opts.required
  def get_userroles( opts ), do: opts.get_userroles
end

defmodule ExampleApp.Authorization.Helper do
  # This extracts the userrole from session data.
  # In real world-apps you'll be asking your user 
  # database for this user's roles. Don't you?
  def get_userroles_fun( conn ) do
    user = Plug.Conn.get_session( conn, :user ) 
    case user do
      nil                   -> []
      %{ roles: userroles } -> userroles
      _                     -> throw( :invalid_user_session_format )
    end
  end
end

