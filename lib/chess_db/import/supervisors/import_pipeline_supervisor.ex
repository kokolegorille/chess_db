defmodule ChessDb.Import.Supervisors.ImportPipelineSupervisor do
  use Supervisor

  alias ChessDb.Import.Pipeline.{
    Starter,
    GameStorage
  }

  @starter_name Starter
  @nbr_workers 15

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    game_storage_subscription = [
      subscribe_to: [{@starter_name, min_demand: 1, max_demand: 10}]
    ]

    # Create a number of consumer, all connected to the same producer
    game_storage_specs = 0..@nbr_workers |> Enum.map(fn i ->
      name = :"store_#{i}"
      Supervisor.child_spec({GameStorage, [name, game_storage_subscription]}, id: name)
    end)

    children = [worker(Starter, [], restart: :permanent)] ++ game_storage_specs

    Supervisor.init(
      children,
      strategy: :rest_for_one
    )
  end
end
