defmodule Frank.Git.Repo do
  import Frank.Helper

  require Logger

  @derive {Inspect,
           except: [
             :branches,
             :tags
           ]}

  @type t :: %__MODULE__{
          name: String.t(),
          path: String.t(),
          tags: [Frank.Git.Reference.t()],
          branches: [Frank.Git.Reference.t()],
          raw_url: String.t(),
          api_url: String.t(),
          client_url: String.t(),
          head: String.t()
        }

  defstruct name: nil,
            path: nil,
            tags: nil,
            branches: nil,
            raw_url: nil,
            api_url: nil,
            client_url: nil,
            head: nil

  def get_repo(path) do
    Logger.info(path)

    path = Path.absname(path)
    name = Path.basename(path)
    head = get_head_branch_name(path)

    %Frank.Git.Repo{
      name: name,
      path: path,
      branches: get_branch_list(path),
      #      tags: get_tag_list(path),
      raw_url: "/raw/#{name}",
      api_url: "/api/repos/#{name}",
      client_url: "#/repos/#{name}/#{URI.encode_www_form(head)}",
      head: head
    }
  end

  defp get_head_branch_name(path) do
    {"refs/heads/" <> branch_name, 0} = "git -C #{path} symbolic-ref HEAD" |> bash()

    branch_name
    |> String.trim()
  end

  defp get_branch_list(path) do
    case "git -C #{path} ls-remote --heads" |> bash() do
      {git_res, 0} ->
        git_res

      _ ->
        nil
    end
    |> Frank.Git.Reference.from_lines(path)
  end

  #  defp get_tag_list(path) do
  #    case "git -C #{path} ls-remote --tags" |> bash() do
  #      {git_res, 0} ->
  #        git_res
  #
  #      _ ->
  #        nil
  #    end
  #    |> Frank.Git.Reference.from_lines(path)
  #  end
end
