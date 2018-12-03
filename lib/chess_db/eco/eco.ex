defmodule ChessDb.Eco do
  @moduledoc """
  The ECO Context (Encyclopedia of Chess Openings)
  """

  # source: https://github.com/brittonf/scid-vs-variants
  # Warning! The french file differs from the english one!

  @external_resource Path.join(:code.priv_dir(:chess_db), "scid.eco")

  import Ecto.Query, warn: false
  import ChessDb.Common, only: [extract_moves: 1, play_moves: 1]

  require Logger

  alias ChessDb.Eco.{Category, SubCategory}
  alias ChessDb.{Repo, Zobrist, Common}

  # =================================================================
  # IMPORT ECO CODE
  # =================================================================

  def load_eco(file \\ @external_resource), do: lazy_load_eco(file)

  defp lazy_load_eco(file) do
    # Records can be split in multiple lines!

    chunk_fun = fn item, acc ->
      if String.ends_with?(item, "*\n"),
        do: {:cont, acc <> item, ""},
        else: {:cont, acc <> String.trim_trailing(item, "\n")}
    end

    after_fun = fn
      "" -> {:cont, ""}
      acc -> {:cont, acc, ""}
    end

    stream = file
    |> File.stream!()
    |> Stream.filter(fn line ->
      cond do
        String.starts_with?(line, "#") == true -> false
        line == "\n" -> false
        true -> true
      end
    end)
    |> Stream.chunk_while("", chunk_fun, after_fun)
    |> Stream.map(fn line ->
      [code, description, pgn] = String.split(line, "\"")

      code = String.trim_trailing(code, " ")

      pgn = pgn
      |> String.trim_trailing("*\n")
      |> String.trim(" ")

      zobrist_hash = if pgn == "" do
        fen = Common.initial_position()
        |> Chessfold.position_to_string

        Zobrist.fen_to_zobrist_hash(fen)
      else
        case ChessParser.load_string("[FakeKey: \"Fake Header\"]" <> pgn) do
          {:ok, trees} ->
            [{:tree, _tags, elems} | _rest] = trees

            elems
            |> extract_moves()
            |> play_moves()
            |> List.last
            |> Chessfold.position_to_string()
            |> Zobrist.fen_to_zobrist_hash()

          {:error, _reason} ->
            0
        end
      end

      %{
        code: code,
        description: description,
        pgn: pgn,
        zobrist_hash: zobrist_hash
      }
    end)

    stream
    |> Enum.to_list
    |> process_code()
  end

  defp process_code([]), do: {:ok, 0}
  defp process_code(eco_codes) do
    entries = do_process_code({eco_codes, nil, nil, 0, []})

    # insert_all is limited to 65535 parameters
    # ** (Postgrex.QueryError) postgresql protocol can not handle 82880 parameters, the maximum is 65535
    # => Chunk every... to stay in the limit!

    entries
    |> Enum.chunk_every(1_000)
    |> Enum.each(&Repo.insert_all(SubCategory, &1))

    {:ok, length(entries)}
  end

  defp do_process_code({[], _cat_code, _cat_id, _position, acc}), do: acc
  defp do_process_code({[%{code: code} = eco_code | tail], cat_code, cat_id, position, acc}) do
    regex = ~r/(?<volume>[A-E])(?<category_code>[0-9]{2})(?<sub_category_code>[a-z0-9]?)/

    case Regex.named_captures(regex, code) do
      %{"volume" => volume, "category_code" => category_code, "sub_category_code" => sub_category_code} ->
        now =
          NaiveDateTime.utc_now
          |> NaiveDateTime.truncate(:second)
        if volume <> category_code != cat_code do
          new_cat_code = volume <> category_code
          new_position = 0

          Logger.debug(fn -> "Loading category by volume : #{volume} and code : #{category_code}" end)

          new_cat_id = first_or_create_category(%{volume: volume, code: category_code}).id

          new_eco_code = %{eco_code | code: sub_category_code}
          |> Map.put(:category_id, new_cat_id)
          |> Map.put(:position, new_position)
          |> Map.put(:inserted_at, now)
          |> Map.put(:updated_at, now)

          new_acc = [new_eco_code | acc]
          do_process_code({tail, new_cat_code, new_cat_id, new_position + 1, new_acc})
        else
          new_eco_code = %{eco_code | code: sub_category_code}
          |> Map.put(:category_id, cat_id)
          |> Map.put(:position, position)
          |> Map.put(:inserted_at, now)
          |> Map.put(:updated_at, now)

          new_acc = [new_eco_code | acc]
          do_process_code({tail, cat_code, cat_id, position + 1, new_acc})
        end
      _ ->
        Logger.debug(fn -> "Could not process eco_code #{inspect eco_code}" end)
    end
  end

  # =================================================================
  # CATEGORIES
  # =================================================================

  def list_categories do
    from(c in Category, order_by: [:volume, :code])
    |> Repo.all()
  end

  def list_category_sub_categories(%Category{} = category) do
    SubCategory
    |> category_sub_categories_query(category)
    |> Repo.all
  end

  defp category_sub_categories_query(query, %Category{id: category_id}) do
    from(sc in query, where: sc.category_id == ^category_id)
  end

  def get_category(id) do
    Repo.get(Category, id)
  end

  def get_category!(id) do
    Repo.get!(Category, id)
  end

  def get_category_by(params) do
    Repo.get_by(Category, params)
  end

  def get_category_by!(params) do
    Repo.get_by!(Category, params)
  end

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def first_or_create_category(attrs \\ %{}) do
    case create_category(attrs) do
      {:ok, category} -> category
      {:error, _changeset} -> get_category_by(attrs)
    end
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category), do: Repo.delete(category)

  def change_category(%Category{} = category) do
    Category.changeset(category, %{})
  end

  # =================================================================
  # SUB CATEGORIES
  # =================================================================

  def list_sub_categories do
    Repo.all(SubCategory)
  end

  def get_sub_category(id) do
    Repo.get(SubCategory, id)
  end

  def get_sub_category!(id) do
    Repo.get!(SubCategory, id)
  end

  def get_sub_category_by(params) do
    Repo.get_by(SubCategory, params)
  end

  def get_sub_category_by!(params) do
    Repo.get_by!(SubCategory, params)
  end

  def create_sub_category(attrs \\ %{}) do
    %SubCategory{}
    |> SubCategory.changeset(attrs)
    |> Repo.insert()
  end

  def update_sub_category(%SubCategory{} = sub_category, attrs) do
    sub_category
    |> SubCategory.changeset(attrs)
    |> Repo.update()
  end

  def delete_sub_category(%SubCategory{} = sub_category), do: Repo.delete(sub_category)

  def change_sub_category(%SubCategory{} = sub_category) do
    SubCategory.changeset(sub_category, %{})
  end
end
