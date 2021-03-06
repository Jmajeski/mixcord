defmodule Mixcord.Shard do
  @moduledoc false

  @behaviour :websocket_client

  alias Mixcord.Shard.{Event, Payload}
  alias Mixcord.Constants
  alias Mixcord.Util
  require Logger

  def start_link(token, caller, shard_num) do
    :crypto.start
    :ssl.start
    # This makes the supervisor spawn a shard worker ever 5 seconds. This only occurs on ShardSupervisor start.
    # If an individual shard fails, it will be restarted immediately.
    # TODO: Queue reconnects/check this better
    if Util.num_shards > 1, do: Process.sleep(5000)
    :websocket_client.start_link(Util.gateway, __MODULE__, Payload.state_map(token, caller, shard_num, self))
  end

  def websocket_handle({:binary, payload}, _state, state) do
    payload = :erlang.binary_to_term(payload)
    new_state = Constants.atom_from_opcode(payload.op)
      |> Event.handle(payload, state)

    {:ok, %{new_state | seq: payload.s}}
  end

  def update_status(pid, {idle, game}) do
    status_json = Poison.encode!(%{game: %{name: game}, idle: idle})
    send(pid, {:status_update, status_json})
  end

  def websocket_info({:status_update, new_status_json}, _ws_req, state) do
    # TODO: Flesh this out - Idle time?
    :websocket_client.cast(self, {:binary, Payload.status_update_payload(new_status_json)})
    {:ok, state}
  end

  def websocket_info({:heartbeat, interval}, _ws_req, state) do
    now = Util.now()
    :websocket_client.cast(self, {:binary, Payload.heartbeat_payload(state.seq)})
    Event.heartbeat(self, interval)
    {:ok, %{state | last_heartbeat: now}}
  end

  def websocket_info(:identify, _ws_req, state) do
    :websocket_client.cast(self, {:binary, Payload.identity_payload(state)})
    {:ok, state}
  end

  def init(state) do
    {:once, state}
  end

  def onconnect(_ws_req, state) do
    Logger.debug "SHARD #{state.shard_num} CONNECTED"
    {:ok, state}
  end

  def ondisconnect(reason, state) do
    Logger.warn "WS DISCONNECTED BECAUSE: #{inspect reason}"
    Logger.debug "STATE ON CLOSE: #{inspect state}"
    if state.reconnect_attempts > 3 do
      {:close, reason, state}
    else
      :timer.sleep(5000)
      Logger.debug "RECONNECT ATTEMPT NUMBER #{state.reconnect_attempts + 1}"
      {:reconnect, %{state | reconnect_attempts: state.reconnect_attempts + 1}}
    end
  end

  def websocket_terminate(reason, _ws_req, _state) do
    #SO TRIGGERED I CANT GET END EVENT CODES
    Logger.debug "WS TERMINATED BECAUSE: #{inspect reason}"
    :ok
  end

end