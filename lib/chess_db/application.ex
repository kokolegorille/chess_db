defmodule ChessDb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias ChessDb.Import.Workers.QueueWorker
  alias ChessDb.Import.Supervisors.ImportPipelineSupervisor
  alias ChessDb.Zobrist.Supervisors.ZobristSupervisor

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: ChessDb.Worker.start_link(arg)
      # {ChessDb.Worker, arg},

      {ChessDb.Repo, []},
      {QueueWorker, []},
      ImportPipelineSupervisor,
      ZobristSupervisor,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChessDb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
