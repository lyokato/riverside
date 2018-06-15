defmodule Riverside.ExceptionGuard do

  require Logger

  def guard(log_header, error_resp, func) do
    try do
      func.()
    rescue
      err ->
        stacktrace = System.stacktrace() |> Exception.format_stacktrace()
        Logger.error "#{log_header} rescued error - #{inspect err}, stacktrace - #{stacktrace}"
        error_resp.()
    catch
      error_type, value when error_type in [:throw, :exit] ->
        stacktrace = System.stacktrace() |> Exception.format_stacktrace()
        Logger.error "#{log_header} caught error - #{inspect value}, stacktrace - #{stacktrace}"
        error_resp.()
    end
  end

end
