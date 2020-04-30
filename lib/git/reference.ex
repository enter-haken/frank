defmodule Frank.Git.Reference do
  require Logger

  import Frank.Helper

  @derive {Inspect,
           except: [
             :objects
           ]}

  @type reference_kind :: :branch | :tag
  @type t :: %__MODULE__{
          kind: reference_kind(),
          hash: String.t(),
          name: String.t(),
          repo_name: String.t(),
          path: String.t(),
          objects: [Frank.Git.Object],
          license: Frank.Git.License.t(),
          file_count: integer(),
          main_filetype: String.t(),
          raw_url: String.t(),
          api_url: String.t(),
          client_url: String.t()
        }

  defstruct kind: nil,
            hash: nil,
            name: nil,
            repo_name: nil,
            path: nil,
            objects: [],
            license: nil,
            file_count: nil,
            main_filetype: nil,
            raw_url: nil,
            api_url: nil,
            client_url: nil

  def from_lines(nil), do: nil

  def from_lines(lines, path) do
    lines
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      # remove tab
      |> String.split(~r(\s+))
      |> Enum.join(" ")
    end)
    |> Enum.map(fn line -> line |> from_string() end)
    |> Enum.filter(fn reference -> !is_nil(reference) end)
    |> Enum.map(fn reference ->
      reference
      |> get_path(path)
      |> get_repo_name(path)
      |> get_url()
      |> get_repo_object_list()
      |> get_main_extension()
      |> get_file_count()
      |> get_license()
    end)
  end

  def get_object(%Frank.Git.Reference{objects: objects}, search_path) do
    case objects
         |> Enum.find(fn %Frank.Git.Object{path: object_path} ->
           String.downcase(object_path) == String.downcase(search_path)
         end) do
      nil ->
        {:error, "not found"}

      object ->
        {:ok, object}
    end
  end

  def get_root_object_list(%Frank.Git.Reference{objects: objects}) do
    objects
    |> Enum.filter(fn %Frank.Git.Object{path: current_object_path} ->
      current_object_path
      |> Path.split()
      |> Kernel.length()
      |> Kernel.==(1)
    end)
  end

  def get_object_list(%Frank.Git.Reference{objects: objects}, %Frank.Git.Object{
        kind: :tree,
        path: object_path
      }) do
    objects
    |> Enum.filter(fn %Frank.Git.Object{path: current_object_path} ->
      if current_object_path |> String.contains?("/") |> Kernel.not() do
        false
      else
        current_object_path
        |> String.replace_prefix(object_path <> "/", "")
        |> Path.split()
        |> Kernel.length()
        |> Kernel.==(1)
      end
    end)
  end

  defp from_string(<<hash::binary-size(40)>> <> " HEAD") do
    %Frank.Git.Reference{
      kind: :branch,
      hash: hash,
      name: "HEAD"
    }
  end

  defp from_string(<<hash::binary-size(40)>> <> " refs/heads/" <> branch_name) do
    Logger.info("processing branch #{branch_name}")

    %Frank.Git.Reference{
      kind: :branch,
      hash: hash,
      name: branch_name
    }
  end

  defp from_string(<<hash::binary-size(40)>> <> " refs/tags/" <> branch_name) do
    Logger.info("processing tag #{branch_name}")

    %Frank.Git.Reference{
      kind: :tag,
      hash: hash,
      name: branch_name
    }
  end

  defp from_string(_), do: nil

  defp get_path(reference, path), do: %Frank.Git.Reference{reference | path: path}

  defp get_repo_name(reference, path),
    do: %Frank.Git.Reference{reference | repo_name: Path.basename(path)}

  defp get_repo_object_list(
         %Frank.Git.Reference{
           path: path,
           hash: hash,
           name: name
         } = reference
       ) do
    Logger.info("fetching object list for #{name} in path #{path}, hash #{hash}")

    objects =
      case "git -C #{path} ls-tree -tr #{hash}" |> bash() do
        {git_res, 0} ->
          git_res

        err ->
          Logger.warn(inspect(err))
          ""
      end
      |> Frank.Git.Object.from_lines()
      |> (fn lines ->
            Logger.info("found #{length(lines)} lines.")
            lines
          end).()
      |> Enum.map(fn object ->
        Task.async(fn ->
          :poolboy.transaction(
            :worker,
            fn pid -> GenServer.call(pid, {:add_metadata, object, reference}) end,
            60000
          )
        end)
      end)
      |> Enum.map(fn x -> Task.await(x, :infinity) end)
      |> Enum.sort(fn %Frank.Git.Object{kind: first_kind, name: _first_name},
                      %Frank.Git.Object{kind: second_kind, name: _second_name} ->
        # TODO: WIP
        if first_kind == second_kind do
          true
        else
          if first_kind == :tree do
            true
          else
            false
          end
        end
      end)

    %Frank.Git.Reference{reference | objects: objects}
  end

  defp get_file_count(%Frank.Git.Reference{objects: objects, name: name} = reference) do
    Logger.info("found #{length(objects)} git objects in branch #{name}.")
    %Frank.Git.Reference{reference | file_count: length(objects)}
  end

  defp get_main_extension(%Frank.Git.Reference{objects: []} = reference), do: reference

  defp get_main_extension(%Frank.Git.Reference{objects: objects} = reference) do
    sorted_extensions =
      objects
      |> Enum.map(fn %Frank.Git.Object{path: path} -> path |> Path.extname() end)
      |> Enum.sort()

    %{extension: extension} =
      sorted_extensions
      |> Enum.uniq()
      |> Enum.map(fn extension ->
        number_of_files =
          sorted_extensions
          |> Enum.filter(fn x -> x == extension end)
          |> Enum.count()

        %{extension: extension, count: number_of_files}
      end)
      |> Enum.sort(&(&1 >= &2))
      |> List.first()

    %Frank.Git.Reference{reference | main_filetype: extension}
  end

  defp get_license(reference) do
    with {:ok, object} <- get_object(reference, "LICENSE"),
         {:ok, %Frank.Git.Object{raw_content: raw_license_content}} <-
           Frank.Git.Object.get_content(object, reference) do
      %Frank.Git.Reference{
        reference
        | license: Frank.Git.License.get_license(raw_license_content)
      }
    else
      _ ->
        %Frank.Git.Reference{reference | license: Frank.Git.License.get_license()}
    end
  end

  defp get_url(%Frank.Git.Reference{path: path, name: name} = reference) do
    encoded_name =
      name
      |> URI.encode_www_form()

    raw_reference_url = "/raw/#{Path.basename(path)}/#{encoded_name}"
    api_reference_url = "/api/repos/#{Path.basename(path)}/references/#{encoded_name}"
    client_reference_url = "#/repos/#{Path.basename(path)}/#{encoded_name}"

    %Frank.Git.Reference{
      reference
      | raw_url: raw_reference_url,
        api_url: api_reference_url,
        client_url: client_reference_url
    }
  end
end
