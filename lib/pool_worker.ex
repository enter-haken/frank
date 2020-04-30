defmodule Frank.PoolWorker do
  use GenServer

  import Frank.Helper

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    Logger.info("init #{__MODULE__}")
    {:ok, nil}
  end

  def handle_call(
        {:add_metadata, %Frank.Git.Object{path: object_path} = object,
         %Frank.Git.Reference{
           path: path,
           name: name,
           raw_url: raw_url,
           api_url: api_url,
           client_url: client_url
         }},
        _from,
        state
      ) do
    client_url = Path.join([client_url, object_path])

    breadcrumb =
      Frank.Git.Link.get_breadcrumb(client_url)
      |> Enum.drop(3)

    command =
      "git -C #{path} log -n 1 --pretty=\"%h;%cr;%s\" remotes/origin/#{name} -- #{object_path}"

    [date, commit_message] =
      with {message, 0} <- command |> bash(),
           result_list <- message |> String.split(";", parts: 3) |> Enum.drop(1),
           true <- length(result_list) == 2 do
        result_list
      else
        _err ->
          # Logger.warn(inspect("#{object_path}: #{inspect(err)}"))
          ["unknown", "unknown"]
      end

    result = %Frank.Git.Object{
      object
      | raw_url: Path.join([raw_url, object_path]),
        api_url: Path.join([api_url, object_path]),
        client_url: client_url,
        breadcrumbs: breadcrumb,
        commit_message: commit_message |> String.trim(),
        relative_committer_date: date
    }

    {:reply, result, state}
  end
end
