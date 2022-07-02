defmodule Fixtures.TravelSchema do
  use Ecto.Schema

  defmodule Stay do
    use Ecto.Schema

    embedded_schema do
      field(:hotel_name, :string)
      field(:from, :date)
      field(:to, :date)
      field(:price, :decimal)
    end
  end

  defmodule Metadata do
    use Ecto.Schema

    embedded_schema do
      field(:travelforce_id, :integer)
    end
  end

  schema "travels" do
    field(:title, :string)
    field(:description, :string)
    field(:number_of_people, :integer)
    field(:requires_passport, :boolean)
    field(:travel_type, Ecto.Enum, values: [business: "business", leisure: "leisure", other: "undisclosed"])
    field(:start_time, :utc_datetime)
    field(:local_start_time, :naive_datetime)
    field(:end_date, :date)
    field(:age_of_travelers, {:array, :integer})
    field(:means_of_transport, {:array, Ecto.Enum}, values: [:train, :plane, :car, :bus, :ferry])
    embeds_many(:stays, Stay)
    embeds_one(:metadata, Metadata)
    timestamps()
  end
end
