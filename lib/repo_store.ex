defmodule Frank.RepoStore do
  use GenServer

  require Logger

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(%Frank.Git.Repo{name: name} = repo) do
    Logger.info("#{name} started")

    {:ok, repo}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(
        {:get, :branches},
        _from,
        %Frank.Git.Repo{branches: branches} = state
      ) do
    result =
      branches
      |> Enum.map(fn %Frank.Git.Reference{name: name, client_url: client_url} ->
        %Frank.Git.Link{title: name, url: client_url}
      end)

    {:reply, result, state}
  end

  def handle_call(
        {:get, :branches, branch_name, "/"},
        _from,
        %Frank.Git.Repo{branches: branches, name: repo_name} = state
      ) do
    result = get_root_list(branches, branch_name, repo_name)

    {:reply, result, state}
  end

  def handle_call(
        {:get, :head},
        _from,
        %Frank.Git.Repo{branches: branches, head: head, name: repo_name} = state
      ) do
    result = get_root_list(branches, head, repo_name)

    {:reply, result, state}
  end

  def handle_call(
        {:get, :branches, branch_name, url},
        _from,
        %Frank.Git.Repo{branches: branches} = state
      ) do
    result = get_object(branches, branch_name, url)

    {:reply, result, state}
  end

  def handle_call(
        {:get, :search, search_term},
        _from,
        %Frank.Git.Repo{branches: branches, head: head} = state
      ) do
    result =
      branches
      |> Enum.find(fn %Frank.Git.Reference{name: reference_name} ->
        reference_name == head
      end)
      |> Frank.Git.Grep.search(search_term, "README.md")

    {:reply, result, state}
  end

  def handle_call(
        {:get, :search, branch_name, search_term},
        _from,
        %Frank.Git.Repo{branches: branches} = state
      ) do
    result =
      branches
      |> Enum.find(fn %Frank.Git.Reference{name: reference_name} ->
        reference_name == branch_name
      end)
      |> Frank.Git.Grep.search(search_term)

    {:reply, result, state}
  end

  # client

  def get(repo_name) do
    repo_name
    |> call(:get)
  end

  def get_branch_object(repo_name, branch_name, url) do
    repo_name
    |> call({:get, :branches, branch_name, url})
  end

  def get_branches(repo_name) do
    repo_name
    |> call({:get, :branches})
  end

  def get_head(repo_name) do
    repo_name
    |> call({:get, :head})
  end

  def search(repo_name, branch_name, search_term) do
    repo_name
    |> call({:get, :search, branch_name, search_term})
  end

  def search(search_term) do
    Frank.RepoSupervisor.get_repo_names()
    |> Enum.map(fn repo_name ->
      repo_name
      |> call({:get, :search, search_term})
    end)
    |> List.flatten()
  end

  defp call(repo_name, params) do
    repo_name
    |> Frank.RepoSupervisor.get_pid_for()
    |> GenServer.call(params)
  end

  defp get_root_list(branches, branch_name, repo_name) do
    branch =
      branches
      |> Enum.find(fn %Frank.Git.Reference{name: reference_name} ->
        reference_name == branch_name
      end)

    root_list =
      branch
      |> Frank.Git.Reference.get_root_object_list()

    case root_list
         |> Enum.find(fn %Frank.Git.Object{name: name} ->
           String.downcase(name) == "readme.md" or String.downcase(name) == "readme.markdown"
         end) do
      nil ->
        %{
          object: %Frank.Git.Object{
            api_url: "/api/repos/#{repo_name}/references/#{branch_name}",
            breadcrumbs: [
              %Frank.Git.Link{title: "branch_name", url: "/#/repos/#{repo_name}/#{branch_name}"}
            ],
            client_url: "/#/repos/#{repo_name}/#{branch_name}",
            kind: :tree
          },
          directory: root_list
        }

      # %Frank.Git.Object{raw_content: raw_content, formatted_content: formatted_content} ->
      object ->
        {:ok, %Frank.Git.Object{raw_content: raw_content, formatted_content: formatted_content}} =
          object
          |> Frank.Git.Object.get_content(branch)

        %{
          object: %Frank.Git.Object{
            api_url: "/api/repos/#{repo_name}/references/#{branch_name}",
            breadcrumbs: [
              %Frank.Git.Link{title: branch_name, url: "/#/repos/#{repo_name}/#{branch_name}"}
            ],
            client_url: "/#/repos/#{repo_name}/#{branch_name}",
            kind: :tree,
            raw_content: raw_content,
            formatted_content: formatted_content
          },
          directory: root_list
        }
    end
  end

  defp get_object(branches, branch_name, url) do
    branch =
      branches
      |> Enum.find(fn %Frank.Git.Reference{name: reference_name} ->
        reference_name == branch_name
      end)

    case Frank.Git.Reference.get_object(branch, url) do
      {:ok, %Frank.Git.Object{kind: kind} = object} ->
        if kind == :blob do
          {:ok, object_with_content} =
            object
            |> Frank.Git.Object.get_content(branch)

          %{
            object: object_with_content,
            directory: nil
          }
        else
          %{
            object: object,
            directory: Frank.Git.Reference.get_object_list(branch, object)
          }
        end

      {:error, err} ->
        {:error, err}
    end
  end
end
