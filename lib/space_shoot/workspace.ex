defmodule SpaceShoot.Workspace do
  @workspaces %{
    "repeat_loop" => %{
      "blocks" => %{
        "languageVersion" => 0,
        "blocks" => [
          %{
            "type" => "controls_repeat_ext",
            "x" => 20,
            "y" => 20,
            "inputs" => %{
              "TIMES" => %{
                "block" => %{
                  "type" => "math_number",
                  "fields" => %{"NUM" => 10}
                }
              }
            }
          }
        ]
      }
    },
    "conditional" => %{
      "blocks" => %{
        "languageVersion" => 0,
        "blocks" => [
          %{
            "type" => "controls_if",
            "x" => 20,
            "y" => 20,
            "inputs" => %{
              "IF0" => %{
                "block" => %{
                  "type" => "logic_compare",
                  "fields" => %{"OP" => "EQ"},
                  "inputs" => %{
                    "A" => %{
                      "block" => %{
                        "type" => "math_number",
                        "fields" => %{"NUM" => 1}
                      }
                    },
                    "B" => %{
                      "block" => %{
                        "type" => "math_number",
                        "fields" => %{"NUM" => 1}
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    },
    "math_example" => %{
      "blocks" => %{
        "languageVersion" => 0,
        "blocks" => [
          %{
            "type" => "math_arithmetic",
            "x" => 20,
            "y" => 20,
            "fields" => %{"OP" => "ADD"},
            "inputs" => %{
              "A" => %{
                "block" => %{
                  "type" => "math_number",
                  "fields" => %{"NUM" => 3}
                }
              },
              "B" => %{
                "block" => %{
                  "type" => "math_number",
                  "fields" => %{"NUM" => 7}
                }
              }
            }
          }
        ]
      }
    }
  }

  @workspace_labels %{
    "repeat_loop" => "Repeat Loop",
    "conditional" => "Conditional",
    "math_example" => "Math Example"
  }

  def list_workspaces do
    Enum.map(@workspace_labels, fn {id, label} -> {label, id} end)
  end

  def get_workspace(id), do: Map.fetch!(@workspaces, id)
end
