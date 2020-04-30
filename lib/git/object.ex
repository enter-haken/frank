defmodule Frank.Git.Object do
  import Frank.Helper

  @derive {Inspect,
           except: [
             :raw_content,
             :formatted_content,
             :commit_message
           ]}

  @type object_kind :: :blob | :tree
  @type t :: %__MODULE__{
          kind: object_kind(),
          hash: String.t(),
          path: String.t(),
          name: String.t(),
          commit_message: String.t(),
          relative_committer_date: String.t(),
          raw_url: String.t(),
          api_url: String.t(),
          client_url: String.t(),
          breadcrumbs: [Frank.Git.Link.t()],
          raw_content: String.t(),
          formatted_content: String.t()
        }

  # todo: breadcrumb
  defstruct kind: :blob,
            hash: nil,
            path: nil,
            name: nil,
            commit_message: nil,
            relative_committer_date: nil,
            raw_url: nil,
            api_url: nil,
            client_url: nil,
            breadcrumbs: nil,
            raw_content: nil,
            formatted_content: nil

  def from_string(
        <<_head::binary-size(7)>> <>
          <<kind::binary-size(4)>> <> " " <> <<hash::binary-size(40)>> <> " " <> path
      ) do
    %Frank.Git.Object{
      kind: String.to_atom(kind),
      hash: hash,
      path: path,
      name: Path.basename(path)
    }
  end

  def from_lines(nil), do: nil

  def from_lines(lines) do
    lines
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      # remove tab
      |> String.split(~r(\s+))
      |> Enum.join(" ")
    end)
    |> Enum.filter(fn line -> String.length(line) > 0 end)
    |> Enum.filter(fn line -> line |> String.contains?("commit") |> Kernel.not() end)
    |> Enum.map(fn line -> line |> Frank.Git.Object.from_string() end)
  end

  def get_content(%Frank.Git.Object{kind: :tree}, _reference), do: {:error, "is tree"}

  def get_content(
        %Frank.Git.Object{kind: :blob, hash: hash, name: name} = object,
        %Frank.Git.Reference{path: path} 
      ) do
    with {raw_content, 0} <- "git -C #{path} cat-file -p #{hash}" |> bash(),
         formatted_content <- get_formatted(raw_content |> String.trim(), name) do
      {:ok,
       %Frank.Git.Object{
         object
         | raw_content: raw_content |> String.trim(),
           formatted_content: formatted_content
       }}
    else
      {:error, err} ->
        {:error, err}
    end
  end

  defp get_formatted(raw_content, name) do
    cond do
      name |> String.downcase() |> String.ends_with?(".md") ->
        get_formatted_markdown(raw_content)

      name |> String.downcase() |> String.ends_with?(".markdown") ->
        get_formatted_markdown(raw_content)

      name |> String.downcase() |> String.ends_with?(".html") ->
        get_formatted_html(raw_content)

      # name |> String.downcase() |> String.ends_with?(".ex") ->
      #  get_formatted_elixir(raw_content)

      true ->
        nil
    end
  end

  # defp get_formatted_elixir(raw_content) do
  #  {:ok, ast} = Code.string_to_quoted(raw_content)
  #  inspect(ast, pretty: true)
  # end

  defp get_formatted_markdown(raw_content) do
    {:ok, html, _errors} = Earmark.as_html(raw_content)
    html
  end

  defp get_formatted_html(raw_content) do
    raw_content
    |> Floki.find("body")
    |> Floki.raw_html()
  end
end
