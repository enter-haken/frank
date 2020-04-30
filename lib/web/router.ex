defmodule Frank.Web.Router do
  use Plug.Router

  import Frank.Web.Response

  plug(Plug.Logger)
  plug(Frank.Web.Plug.Bakery)
  plug(CORSPlug, origin: ["*"], methods: ["GET", "OPTIONS"])

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json, :multipart],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  #  get "/raw/:repo_name/:reference/*path" do
  #    raw_file_content =
  #      Frank.RepoStore.get_content_by_path(repo_name, path |> Path.join())
  #      |> Poison.encode!(pretty: true)
  #
  #    send_resp(conn, 200, "<pre><code>" <> raw_file_content <> "</code></pre>")
  #  end

  get "/api/repos" do
    response =
      Frank.RepoSupervisor.get_repo_names()
      |> Enum.map(fn name ->
        Frank.RepoStore.get(name)
      end)
      |> Enum.map(fn %Frank.Git.Repo{
                       name: repo_name,
                       head: head,
                       branches: branches,
                       client_url: url
                     } ->
        %Frank.Git.Reference{
          name: branch_name,
          license: %Frank.Git.License{name: license},
          main_filetype: main_filetype,
          file_count: file_count
        } =
          branches
          |> Enum.find(fn %Frank.Git.Reference{name: main_branch} ->
            main_branch == head
          end)

        %{
          name: repo_name,
          headBranch: branch_name,
          license: license,
          mainFiletype: main_filetype,
          fileCount: file_count,
          url: url
        }
      end)
      |> to_response()

    conn
    |> send_resp(200, response)
  end

  post "/api/search" do
    %Plug.Conn{params: %{"searchTerm" => search_term}} = conn

    result =
      Frank.RepoStore.search(search_term)
      |> Enum.map(&map_search_result/1)
      |> to_response()

    conn
    |> send_resp(200, result)
  end

  get "/api/repos/:repo_name" do
    %{object: object, directory: directory} = Frank.RepoStore.get_head(repo_name)

    conn
    |> send_resp(
      200,
      %{
        gitObject: object,
        directory: directory
      }
      |> to_response()
    )
  end

  get "/api/repos/:repo_name/branches" do
    result =
      Frank.RepoStore.get_branches(repo_name)
      |> to_response()

    conn
    |> send_resp(200, result)
  end

  get "/api/repos/:repo_name/branches/:branch_name" do
    %{object: object, directory: directory} =
      Frank.RepoStore.get_branch_object(repo_name, URI.decode(branch_name), "/")

    conn
    |> send_resp(200, %{gitObject: object, directory: directory} |> to_response())
  end

  post "/api/repos/:repo_name/branches/:branch_name/search" do
    %Plug.Conn{params: %{"searchTerm" => search_term}} = conn

    response =
      Frank.RepoStore.search(repo_name, URI.decode(branch_name), search_term)
      |> Enum.map(&map_search_result/1)
      |> to_response()

    conn
    |> send_resp(200, response)
  end

  get "/api/repos/:repo_name/branches/:branch_name/*path" do
    %{object: %Frank.Git.Object{kind: kind} = object, directory: directory} =
      Frank.RepoStore.get_branch_object(repo_name, URI.decode(branch_name), Path.join(path))

    if kind == :tree do
      conn
      |> send_resp(200, %{gitObject: object, directory: directory} |> to_response())
    else
      conn
      |> send_resp(200, %{gitObject: object, directory: nil} |> to_response())
    end
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp map_search_result(%Frank.Git.Grep{
         matches: matches,
         object: %Frank.Git.Object{
           client_url: client_url
         },
         reference: %Frank.Git.Reference{
           name: reference_name,
           repo_name: repo_name
         }
       }),
       do: %{
         link: %{
           url: client_url,
           title: Path.basename(client_url)
         },
         repoName: repo_name,
         referenceName: reference_name,
         matches:
           matches
           |> Enum.map(fn %Frank.Git.Grep.Match{
                            line_number: line_number,
                            raw_text: raw_text
                          } ->
             "#{line_number}: #{raw_text}"
           end)
       }
end
