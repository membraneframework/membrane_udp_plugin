defmodule Membrane.Integration.TestingPipeline.Assertions do
  defmacro receive_message(
             message,
             timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout),
             failure_message \\ nil
           ) do
    import ExUnit.Assertions, only: [assert_receive: 1]

    quote do
      assert_receive {Membrane.Integration.TestingPipeline, unquote(message)},
                     unquote(timeout),
                     unquote(failure_message)
    end
  end
end
