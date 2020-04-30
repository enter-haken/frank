defmodule Frank.Git.Grep.Match do
  @type t :: %__MODULE__{
          line_number: integer(),
          raw_text: String.t()
        }

  defstruct line_number: nil,
            raw_text: nil
end

defmodule Frank.Git.Grep do
  import Frank.Helper

  require Logger

  @type t :: %__MODULE__{
          reference: Frank.Git.Reference.t(),
          object: Frank.Git.Object.t(),
          matches: [Frank.Git.Repo.Match.t()]
        }

  defstruct reference: nil,
            object: nil,
            matches: nil

  @doc """
  $ git grep -iIn compatible
  guides/https.md:78:To simplify configuration of TLS defaults Plug provides two preconfigured options: `cipher_suite: :strong` and `cipher_suite: :compatible`.
  guides/https.md:82:The `:compatible` profile additionally enables AES-CBC ciphers, as well as TLS versions 1.1 and 1.0. Use this configuration to allow connections from older clients, such as older PC or mobile operating systems. Note that RSA key exchange is not enabled by this configuration, due to known weaknesses, so to support clients that do not support ECDHE or DHE it is necessary specify the ciphers explicitly (see [below](#manual-configuration)).
  lib/plug/ssl.ex:75:  @compatible_tls_ciphers [
  lib/plug/ssl.ex:114:  options: `cipher_suite: :strong` and `cipher_suite: :compatible`. The Ciphers
  lib/plug/ssl.ex:127:  be fully compatible with older browsers and operating systems.
  lib/plug/ssl.ex:129:  The **Compatible** cipher suite supports tlsv1, tlsv1.1 and tlsv1.2. Ciphers were
  lib/plug/ssl.ex:231:      :compatible -> set_compatible_tls_defaults(options)
  lib/plug/ssl.ex:250:  defp set_compatible_tls_defaults(options) do
  lib/plug/ssl.ex:253:    |> Keyword.put_new(:ciphers, @compatible_tls_ciphers)
  test/plug/ssl_test.exs:37:    test "sets cipher suite to compatible" do
  test/plug/ssl_test.exs:38:      assert {:ok, opts} = configure(key: "abcdef", cert: "ghijkl", cipher_suite: :compatible)
  test/plug/ssl_test.exs:64:    test "sets cipher suite with overrides compatible" do
  test/plug/ssl_test.exs:69:                 cipher_suite: :compatible,

  """

  def search(
        %Frank.Git.Reference{path: reference_path, objects: objects, name: reference_name} =
          reference,
        search_term,
        pattern \\ nil
      ) do
    command =
      case pattern do
        nil ->
          "git -C #{reference_path} grep -iIn #{search_term} origin/#{reference_name}"

        limited_to_filename ->
          "git -C #{reference_path} grep -iIn #{search_term} origin/#{reference_name} -- #{
            limited_to_filename
          }"
      end

    case command |> bash() do
      {result, 0} ->
        result

      err ->
        Logger.warn(inspect(err))
        ""
    end
    |> String.split("\n")
    |> Enum.filter(fn x -> x != "" end)
    |> Enum.map(fn raw_match ->
      raw_match
      |> String.split(":", parts: 4)
    end)
    |> Enum.group_by(
      fn
        [_branch, file | _] ->
          file
      end,
      fn [
           _branch,
           _file | line_number_and_raw_text
         ] ->
        [line_number, raw_text] = line_number_and_raw_text

        cond do
          String.length(raw_text) > 200 ->
            {head, _tail} =
              raw_text
              |> String.split_at(200)

            [line_number, "#{head} ..."]

          true ->
            line_number_and_raw_text
        end
      end
    )
    |> Enum.to_list()
    |> Enum.map(fn {match_path, matches} ->
      object =
        case objects
             |> Enum.find(fn %Frank.Git.Object{path: object_path} ->
               object_path == match_path
             end)
             |> Frank.Git.Object.get_content(reference) do
          {:ok, object} ->
            object

          _ ->
            nil
        end

      %Frank.Git.Grep{
        reference: reference,
        object: object,
        matches:
          matches
          |> Enum.map(fn [line_number, raw_text] ->
            %Frank.Git.Grep.Match{
              line_number: String.to_integer(line_number),
              raw_text: raw_text |> String.trim()
            }
          end)
      }
    end)
  end
end
