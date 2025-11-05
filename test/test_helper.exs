ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Mydia.Repo, :manual)

# Configure ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)
