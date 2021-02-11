defmodule TeamsortWeb.Components.Teamsort do
  use Surface.LiveComponent

  alias Teamsort.Solver
  alias Teamsort.Player
  alias Teamsort.PlayerParser

  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.Label
  alias Surface.Components.Form

  data(players, :list, default: [])
  data(players_raw, :string, default: "")
  data(teams, :list, default: [])
  data(players_history, :list, default: [])

  def render(assigns) do
    ~H"""
    <section class="form">
      <Form for={{ :players }} submit="solve" change="change" opts={{ autocomplete: "off" }}>
        <div class="field">
          <Label class="label">Players</Label>
          <TextArea class="textarea has-text-light" rows="10" value={{ @players_raw }}></TextArea>
        </div>
        <div class="field">
          <div class="control">
            <button class="button id-primary">Make teams</button>
          </div>
        </div>
      </Form>

      <section class="section">
        <h1 class="title">Teams</h1>
        <div class="block"><button class="button" :on-click="shuffle">Shuffle</button></div>
        <div class="columns">
          <div class="column" :for={{ team <- @teams }} >
            <div class="box content">
            <h3 class="is-size-4">{{team.name}}</h3>
            <span class="block">Score: {{team.score}}</span>
            <ol>
              <li :for={{ player <- team.players }}>
                {{player.name}} {{player.rank_name }} {{player.team}} {{player.rank}}
              </li>
            </ol>
            </div>
          </div>
        </div>
      </section>
      <!--<pre>@teams = {{ #Jason.encode!(@teams, pretty: true) }}</pre>-->
      <pre>@history = {{ Jason.encode!(@players_history, pretty: true) }}</pre>
    </section>
    """
  end

  def handle_event("change", value, socket) do
    case parse_textarea(value["players"]) do
      {:ok, players, _rest, _, _, _} ->
        {:noreply,
         assign(socket,
           players: players,
           players_raw: List.first(value["players"])
         )}

      {:error, _something, _rest, _, _, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("shuffle", _value, socket) do
    shuffled =
      socket.assigns.players_raw |> String.split("\n") |> Enum.shuffle() |> Enum.join("\n")

    updated_socket = update(socket, :players_history, &[shuffled | &1])

    case parse_textarea([shuffled]) do
      {:ok, players, _rest, _, _, _} ->
        teams = Solver.solve(players)
        {:noreply, assign(updated_socket, players_raw: shuffled, teams: teams)}

      {:error, _something, _rest, _, _, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("solve", value, socket) do
    if List.first(value["players"]) do
      case parse_textarea(value["players"]) do
        {:ok, players, _rest, _, _, _} ->
          teams = Solver.solve(players)
          {:noreply, assign(socket, teams: teams)}

        {:error, _something, _rest, _, _, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @spec parse_textarea(any) :: {:error, String.t()} | {:ok, [Player]}
  def parse_textarea(value) do
    try do
      value
      |> List.first()
      |> PlayerParser.parse()
    catch
      x ->
        IO.puts(x)
        {:error, "Could not parse players. Got #{x}"}
    end
  end
end
