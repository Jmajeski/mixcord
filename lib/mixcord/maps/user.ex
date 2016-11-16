defmodule Mixcord.Map.User do
  @moduledoc """
  Struct representing a Discord user.

  ## User vs. Member
  A `user` contains only general information about that user such as a `username` and an `avatar`.
  A `member` has everything that a `user` has, but also additional information on a per guild basis. This includes things like a `nickname` and a list of `roles`.
  """

  @Type id :: integer
  @Type username :: String.t
  @Type discriminator :: String.t
  @Type avatar :: String.t
  @Type bot :: boolean
  @Type mfa_enabled :: boolean
  @Type verified :: boolean
  @Type email :: String.t

  @Type t :: Map.t

  @doc """
  Represents a Discord User.

  * `:id` - *Integer*. User's id.
  * `:username` - *String*. User's username.
  * `:discriminator` - *String*. User's 4-digit discord-tag.
  * `:avatar` - *String*. User's avatar hash.
  * `:bot` - *Boolean*. Whether the user is a bot.
  * `:mfa_enabled` - *Boolean*. Whether the user has two factor enabled.
  * `:verified` - *Boolean*. Whether the email on the account has been verified.
  * `:email` - *String*. User's email.
  """
  @derive [Poison.Encoder]
  defstruct [
    :id,
    :username,
    :discriminator,
    :avatar,
    :bot,
    :mfa_enabled,
    :verified,
    :email,
  ]
end
