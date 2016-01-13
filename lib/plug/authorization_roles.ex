defmodule Plug.Authorization.Roles do 

  @moduledoc """
  A plug to plug in routers or controllers that checks for user roles.

  Provides a protocol configuration framework caring about

  - where to retrieve required roles
  - where to retrieve the current user's roles (e.g. current session's roles)
  - returns a 403 upon mssing roles

  ## Usage

  In order to use this plug you have to configure it by implementing
  the protocol Plug.Authorization.Roles.Config

  That's a rather easy task as you just have to implementa these functions:
  - required
  - get_userroles

  **required** must return a list of strings (user roles names) and  **get_userroles** as must well

  # Example
  Call the plug, for example in a phoenix router pipeline:
  ```
  plug Plug.Authorization.Roles %ExampleApp.Authorization{ required: ["admin"] }
  ```
  
  or:
  ```
  plug Plug.Authorization.Roles %ExampleApp.Authorization{ 
    required: ["admin"], 
    get_userroles: fn conn -> do_something_with_conn() end
  }
  ```

  ```
  defmodule ExampleApp.Authorization do
    # this is default for ExampeApp's authorization:
    # - no requieres roles (empty list)
    # - retrieve user roles via a helper function
    defstruct required: [], get_userroles: &ExampleApp.Authorization.Helper.get_userroles_fun/1
  end

  defimpl Plug.Authorization.Roles.Config, for: ExampleApp.Authorization do
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
  ```

  """

  alias Plug.Authorization.Roles.Config

  def init do
    []
  end
  
  def init( opts ) do
    opts 
  end

  def call( conn, opts ) do
    roles_of_user  = Config.get_userroles( opts ).( conn )
    roles_required = Config.required( opts )
    
    { is_authorized, missing } = check_authorized( roles_of_user, roles_required )
    assert_authorized conn, is_authorized, missing
  end

  def check_authorized( roles_of_user, roles_required ) do
    missing = Set.difference(
      Enum.into( roles_required, HashSet.new ), 
      Enum.into( roles_of_user,  HashSet.new )
    ) |> Set.to_list
    is_authorized = length( missing ) == 0
    { is_authorized, missing }
  end

  def assert_authorized( conn, true, _ ) do
    conn
  end

  def assert_authorized( conn, false, missing ) do
    conn  
    |> Plug.Conn.send_resp( 403, "Access denied. Missing user roles " <> Enum.join( missing, ", ") )
    |> Plug.Conn.halt 
  end

end

