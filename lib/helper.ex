defmodule Frank.Helper do
  def bash(script), do: System.cmd("sh", ["-c", script])
end
