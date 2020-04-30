defmodule Frank.Git.License do
  require Logger

  @type t :: %__MODULE__{
          name: String.t()
        }

  defstruct name: nil

  def get_license(raw_license \\ "") do
    %__MODULE__{
      name: raw_license |> detect()
    }
  end

  defp detect(license) do
    cond do
      String.contains?(license, "MIT License") ->
        "MIT License"

      String.contains?(license, "Apache License") ->
        "Apache License"

      true ->
        Logger.warn("license is unknown.")
        #Logger.warn(license)
        "unknown"
    end
  end
end
