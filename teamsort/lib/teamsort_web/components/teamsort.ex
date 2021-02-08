defmodule TeamsortWeb.Components.Teamsort do
  use Surface.LiveComponent

  alias Teamsort.Solver
  alias Teamsort.Player

  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Submit
  alias Surface.Components.Form.Field
  alias Surface.Components.Form

  data players, :list, default:  []
  data playersString, :string, default: ""
  data teams, :list, default:  []

  def render(assigns) do
    ~H"""
    <section class="form">
      <Form for={{ :players }} submit="solve" change="change" opts={{ autocomplete: "off" }}>
        <div class="field">
          <Label class="label">Players</Label>
          <TextArea class="textarea has-text-light" rows="10">
            {{ @playersString }}
          </TextArea>
        </div>
        <div class="field">
          <div class="control">
            <button class="button id-primary">Make teams</button>
          </div>
        </div>
      </Form>
      <section class="section">
        <h1 class="is-size-2">Teams</h1>
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
      <pre>@players = {{ Jason.encode!(@players, pretty: true) }}</pre>
    </section>
    """
  end

  def handle_event("change", value, socket) do
    case parse_textarea(value["players"]) do
      {:ok, players } ->
        {:noreply, assign(socket, players: players)}
      {:error, _err} ->
        {:noreply, assign(socket, playersString: List.first(value["players"]))}
    end
  end

  def handle_event("solve", value, socket) do
    if List.first(value["players"]) do
      case parse_textarea(value["players"]) do
        {:ok, players } ->
          teams = Solver.solve(players)
          {:noreply, assign(socket, teams: teams)}
        {:error, _err} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end


  @spec player_from_list([...]) :: %Teamsort.Player{
          name: String.t(),
          rank: integer(),
          rank_name: String.t(),
          team: integer()
        }

  def player_from_list(list) do
    try do
      case list do
        [name, rank_name, team, rank] ->
          %Player{name: name, rank: String.to_integer(rank), rank_name: rank_name, team: team}
        [name, rank_name, rank] ->
          %Player{name: name, rank: String.to_integer(rank), rank_name: rank_name}
        [name, rank] ->
          %Player{name: name, rank: String.to_integer(rank)}
        _ ->
          throw "Could not parse player: #{list}"
      end
    catch
      x -> throw "Error parsing player #{list}: #{x}"
    end
  end

  @spec parse_textarea(any) :: {:error, String.t()} | {:ok, [Player]}
  def parse_textarea(value) do
    try do
      {:ok, value
        |> List.first
        |> String.split("\n")
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&(String.split(&1, ",")))
        |> Enum.map(&player_from_list/1)
      }
    catch
      x -> IO.puts x; {:error, "Could not parse players. Got #{x}"}
    end

  end
end
