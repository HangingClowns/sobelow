defmodule Sobelow.SQL.Stream do
  alias Sobelow.Utils
  use Sobelow.Finding

  def run(fun, filename) do
    {interp_vars, params, {fun_name, [{_, line_no}]}} = parse_sql_def(fun)
    severity = if String.ends_with?(filename, "_controller.ex"), do: false, else: :low

    Enum.each(interp_vars, fn var ->
      if Enum.member?(params, var) do
        print_finding(line_no, filename, fun, fun_name, var, severity || :high)
      else
        print_finding(line_no, filename, fun, fun_name, var, severity || :medium)
      end
    end)
  end

  ## stream(repo, sql, params \\ [], opts \\ [])
  def parse_sql_def(fun) do
    {params, {fun_name, line_no}} = Utils.get_fun_declaration(fun)

    pipefuns = Utils.get_pipe_funs(fun)
    |> Enum.map(fn {_, _, opts} -> Enum.at(opts, 1) end)
    |> Enum.flat_map(&Utils.get_aliased_funs_of_type(&1, :stream, :SQL))

    pipevars = pipefuns
    |> Enum.map(&Utils.extract_opts(&1, 0))
    |> List.flatten

    interp_vars = Utils.get_aliased_funs_of_type(fun, :stream, :SQL) -- pipefuns
    |> Enum.map(&Utils.extract_opts(&1, 1))
    |> List.flatten

    {interp_vars ++ pipevars, params, {fun_name, line_no}}
  end

  defp print_finding(line_no, con, fun, fun_name, var, severity) do
    {color, confidence} = case severity do
      :high -> {IO.ANSI.red(), "High"}
      :medium -> {IO.ANSI.yellow(), "Medium"}
      :low -> {IO.ANSI.green(), "Low"}
    end
    IO.puts color <> "SQL injection - #{confidence} Confidence" <> IO.ANSI.reset()
    IO.puts "File: #{con} - #{fun_name}:#{line_no}"
    IO.puts "Variable: #{var}"
    if Sobelow.get_env(:with_code), do: Utils.print_code(fun, var, :stream)
    IO.puts "\n-----------------------------------------------\n"
  end

  def get_details() do
    Sobelow.SQL.details()
  end
end