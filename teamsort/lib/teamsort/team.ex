defmodule Team do
  @derive Jason.Encoder
  @enforce_keys [:name, :players, :score]
  defstruct [:name, :players, :score]
end
