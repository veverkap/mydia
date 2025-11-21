# Preventing Access.get/3 Errors on Structs

## The Problem

Elixir structs don't implement the `Access` behavior by default, which means:

```elixir
# ❌ WRONG - These will crash with "no function clause matching in Access.get/3"
struct[:field]
get_in(struct, [:field])
struct[:nested][:field]

# ✅ CORRECT - Use dot notation
struct.field
struct.nested.field
```

## Common Scenarios Where This Happens

1. **Migrating from maps to structs** without updating access patterns
2. **Using `get_in/2` on nested structs** (works on maps, fails on structs)
3. **Pattern matching assumptions** from JSON/map data

## How to Find These Issues

### 1. Search for risky patterns

```bash
# Find get_in usage that might be on structs
grep -rn "get_in.*parsed_info\|get_in.*quality\|get_in.*match_result" lib/

# Find bracket notation on known struct fields
grep -rn "\.parsed_info\[" lib/
grep -rn "\.quality\[" lib/
grep -rn "\.match_result\[" lib/

# Find all get_in usage for manual review
grep -rn "get_in" lib/ --include="*.ex"
```

### 2. Use Dialyzer (already installed)

Dialyzer can catch many of these at compile time:

```bash
# Generate PLT (first time only)
./dev mix dialyzer --plt

# Run dialyzer
./dev mix dialyzer
```

Add to CI/CD:

```yaml
- name: Run Dialyzer
  run: ./dev mix dialyzer --halt-exit-status
```

### 3. Use Credo (already installed)

```bash
# Run credo checks
./dev mix credo --strict

# Add to precommit alias
mix precommit  # already runs credo
```

### 4. Write Tests

These errors will always crash at runtime if the code path is hit:

```elixir
test "processes file with parsed info" do
  # This will catch Access.get/3 errors
  result = process_media_file(file, file_info, config)
  assert {:ok, _} = result
end
```

## Prevention Strategies

### 1. **Use Proper Type Specs**

```elixir
@spec process_file(ParsedFileInfo.t()) :: :ok | {:error, term()}
def process_file(%ParsedFileInfo{} = parsed) do
  # Dialyzer will warn if you use bracket access here
  season = parsed.season  # ✅ Good
  # season = parsed[:season]  # ❌ Dialyzer warning
end
```

### 2. **Add @enforce_keys to Structs**

```elixir
defmodule MyStruct do
  @enforce_keys [:required_field]
  defstruct [:required_field, :optional_field]
end

# This will crash at struct creation if required_field is missing
# Better than crashing later with Access.get/3
```

### 3. **Implement Access Behavior (if needed)**

Only do this if you genuinely need bracket notation:

```elixir
defmodule MyStruct do
  @behaviour Access

  defstruct [:field1, :field2]

  @impl Access
  def fetch(%__MODULE__{} = struct, key) do
    Map.fetch(struct, key)
  end

  @impl Access
  def get_and_update(%__MODULE__{} = struct, key, fun) do
    Map.get_and_update(struct, key, fun)
  end

  @impl Access
  def pop(%__MODULE__{} = struct, key) do
    Map.pop(struct, key)
  end
end
```

**Note:** Usually not recommended - just use dot notation instead.

### 4. **Use Pattern Matching**

```elixir
# ✅ BEST - Explicit and safe
def process(%ParsedFileInfo{season: season, episodes: episodes}) do
  # work with season and episodes
end

# ❌ RISKY - Can hide struct access issues
def process(parsed_info) do
  season = get_in(parsed_info, [:season])  # Will crash if struct
end
```

### 5. **Code Review Checklist**

When reviewing PRs, look for:

- [ ] Any `get_in/2` calls on custom structs
- [ ] Bracket notation (`struct[:field]`) on non-Access structs
- [ ] Map functions (`Map.get/2`) used on structs (works but discouraged)
- [ ] New struct definitions without type specs

## Project-Specific Structs to Watch

These structs **do NOT** implement Access:

- `Mydia.Library.Structs.ParsedFileInfo`
- `Mydia.Library.Structs.Quality`
- `Mydia.Library.Structs.MatchResult`
- `Mydia.Indexers.Structs.SearchResult`
- `Mydia.Indexers.Structs.QualityInfo`

Always use dot notation when accessing their fields.

## Quick Reference

| Access Type            | Maps     | Structs    | Recommendation           |
| ---------------------- | -------- | ---------- | ------------------------ |
| `data[:key]`           | ✅ Works | ❌ Crashes | Use `.field` for structs |
| `data.field`           | ❌ Error | ✅ Works   | Always use for structs   |
| `get_in(data, [:key])` | ✅ Works | ❌ Crashes | Only for maps            |
| `Map.get(data, :key)`  | ✅ Works | ✅ Works\* | Discouraged for structs  |

\* Works but considered bad practice - use `.field` instead

## CI/CD Integration

Add these checks to your pipeline:

```bash
# In .github/workflows/ci.yml or similar
./dev mix compile --warnings-as-errors
./dev mix credo --strict
./dev mix dialyzer --halt-exit-status
./dev mix test
```

## Summary

1. **Always use dot notation for structs**: `struct.field`
2. **Run dialyzer regularly**: `./dev mix dialyzer`
3. **Use type specs** to help dialyzer catch issues
4. **Search for risky patterns** when refactoring maps to structs
5. **Test the code paths** - runtime will catch what static analysis misses
