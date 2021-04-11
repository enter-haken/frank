defmodule Frank.RepoSupervisor do
  use Supervisor

  require Logger

  def start_link do
    Logger.info("#{__MODULE__} started.")
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      get_repos_from_root_path()
      |> Enum.map(fn path ->
        Frank.Git.Repo.get_repo(path)
      end)
      |> Enum.map(fn %Frank.Git.Repo{name: name} = repo ->
        Logger.info("starting Frank.RepoStore for repository  #{name}")
        Supervisor.child_spec({Frank.RepoStore, repo}, id: {Frank.RepoStore, name})
      end)

    Logger.debug("attempt to start: #{inspect(children, pretty: true)}")

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_repos_from_root_path() do
    root = Application.get_env(:frank, :repo_root)

    root
    |> File.ls!()
    |> Enum.map(fn x -> Path.join([root, x]) end)
  end

  def get_pid_for(repo_name) do
    {_, pid, _, _} =
      Supervisor.which_children(__MODULE__)
      |> Enum.find(fn {{Frank.RepoStore, id}, _, _, _} -> id == repo_name end)

    pid
  end

  def get_repo_names() do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {{Frank.RepoStore, repo_name}, _pid, :worker, _} ->
      repo_name
    end)
  end
end
