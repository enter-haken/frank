defmodule Frank.Application do
  @moduledoc false

  use Application

  defp poolboy_config, do:
  [
    {:name, {:local, :worker}},
    {:worker_module, Frank.PoolWorker},
    {:size, 300},
    {:max_overflow, 50}
  ]

  def start(_type, _args) do
    port = Application.get_env(:frank, :port)

    children = [
      :poolboy.child_spec(:worker, poolboy_config()),
      {Plug.Cowboy, scheme: :http, plug: Frank.Web.Router, options: [port: port, compress: true]},
      Frank.RepoSupervisor
    ]

    opts = [strategy: :one_for_one, name: Frank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
