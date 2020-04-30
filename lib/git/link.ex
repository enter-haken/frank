defmodule Frank.Git.Link do
  @type t :: %__MODULE__{
          url: String.t(),
          title: String.t()
        }

  defstruct url: nil,
            title: nil

  def get_breadcrumb(url) do
    url 
    |> String.split("/", trim: true)
    |> Enum.scan("", fn part, acc -> Path.join(["/", acc, part]) end)
    |> Enum.map(fn x ->
      %Frank.Git.Link{
        url: x,
        title: Path.basename(x)
      }
    end)
  end
end
