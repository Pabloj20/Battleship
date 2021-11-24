defmodule BattleshipWeb.PlayerGameLive do
  use Phoenix.LiveView, layout: {BattleshipWeb.LayoutView, "live.html"}

  def new() do
    %{
      you: %{
        boats_left: [5, 4, 3, 3, 2],
        boats: [],
        shots: [],
        first_cell_selected: nil,
        boat_selected: nil
      },
      enemy: %{
        boats: [],
        shots: []
      },
      mode: :setting,
      submode: :basic
    }
  end

  def render(assigns) do
    BattleshipWeb.PageView.render("player_game_live.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, new())}
  end

  # - Events for setting state -------------------------

  def handle_event("boat_selected", %{"length" => boat_length}, socket) do
    new_socket = update(socket, :you, &(Map.put(&1, :boat_selected, String.to_integer(boat_length))))
    {:noreply, new_socket}
    # List.delete(socket.assigns.available_boats, String.to_integer(length)))}
  end

  def handle_event("cell_selected", %{"row" => row, "column" => column}, socket) do
    cell = {String.to_integer(row), String.to_integer(column)}
    first_cell = socket.assigns.you.first_cell_selected
    length_selection = socket.assigns.you.boat_selected
    cond do
      is_nil(first_cell) -> first_cell_selected(cell, socket)
      not is_nil(first_cell) ->
        cond do
          (not is_cell_valid?(first_cell)) || (not is_cell_valid?(cell)) -> {:reply, "One of the cells is out of margin"}
          (not is_it_a_boat?(first_cell, cell)) -> {:reply, "Cells selection is illegal"}
          not was_boat_selection_right?(first_cell, cell, length_selection) -> {:reply, "Your boat selection was not right"}
          true -> second_cell_selected(cell, socket)
        end
    end

    {:noreply, socket}
  end

  # - Events for game state --------------------------


  # - Private functions --------------------

  @doc """
  Function to check if requested cells can actually form a boat
  """
  @spec is_it_a_boat?( {}, {}) :: boolean
  defp is_it_a_boat?(cell1,celln), do: elem(cell1,0) == elem(celln,0) or elem(cell1,1) == elem(celln,1)


  @doc """
  Function to check if cell is inside grid
  """
  @spec is_cell_valid?({}) :: boolean

  def is_cell_valid?({x,y}), do: Enum.member?(0..9, x) && Enum.member?(0..9, y)

  @doc """
  Function to check if LEGAL cells are vertical or horizontal aligned
  """
  @spec cells_alignment( {}, {}) :: atom
  defp cells_alignment(cell1, celln) do
    cond do
      elem(cell1,0) == elem(celln, 0) -> :horizontal
      elem(cell1,1) == elem(celln, 1) -> :vertical
    end
  end

  @doc """
  Function to create a boat from cells WORKS ONLY FOR well defined wannabe boats
  """
  @spec create_boat( {}, {}) :: [{}]
  defp create_boat( cell1, celln) do
    case cells_alignment( cell1, celln) do
      :horizontal -> create_boat_horizontal( cell1, celln)
      :vertical   -> create_boat_vertical( cell1, celln )
    end
  end

  @doc """
  Function which creats horizontal boats invoked by create_boat
  """
  @spec create_boat_horizontal( {}, {}) :: [{}]
  defp create_boat_horizontal( cell1, celln) do
    x = elem( cell1, 0)
    n = distance_btw_cells( cell1, celln)
    y = [ elem( cell1, 1), elem( celln, 1) ]
        |> Enum.sort()
        |> Enum.at(0)
    for j <- y .. (y + n), do: {x,j}
  end

  @doc """
  Function which creats vertical boats invoked by create_boat
  """
  @spec create_boat_vertical( {}, {}) :: [{}]
  defp create_boat_vertical( cell1, celln) do
    y = elem( cell1, 1)
    n = distance_btw_cells( cell1, celln)
    x = [ elem( cell1, 0), elem( celln, 0) ]
        |> Enum.sort()
        |> Enum.at(0)
    for i <- x .. (x + y + n), do: {i,y}
  end

  @doc """
  Function to set the length of the future boat
  """
  @spec distance_btw_cells( {}, {}) :: integer
  defp distance_btw_cells(cell1, celln) do
    abs( elem( cell1, 0) - elem( celln, 0) ) + abs( elem( cell1, 1) - elem( celln, 1) )
  end

  @doc """
  Function to check if selected cells to set a boat are right
  """
  @spec was_boat_selection_right?({}, {}, integer) :: boolean
  def was_boat_selection_right?(cell1, celln, length_boat_selected), do: distance_btw_cells(cell1, celln) + 1 == length_boat_selected

  @doc """
  Function when is selected the first cell
  """
  defp first_cell_selected(cell, socket) do
    update(socket, :you, &(Map.put(&1, :first_cell_selected, cell)))
  end

  @doc """
  Function when is selected the second cell
  """
  defp second_cell_selected(cell, socket) do
    second_cell = cell
    is_it_a_boat?(socket.assigns.you.first_cell_selected, second_cell)
  end

end
