# Kaffy

Extremely simple yet powerful admin interface for phoenix applications

## Installation

#### Add `kaffy` as a dependency
```elixir
def deps do
  [
    {:kaffy, "~> 0.2.2"}
  ]
end
```

#### These are the minimum configurations required

```elixir
# in your router.ex
use Kaffy.Routes, scope: "/admin", pipe_through: [:some_plug, :authenticate]
# :scope defaults to "/admin"
# :pipe_through defaults to kaffy's [:kaffy_browser]

# in your endpoint.ex
plug Plug.Static,
  at: "/kaffy",
  from: :kaffy,
  gzip: false,
  only: ~w(css img js scss vendor)

# in your config/config.exs
config :kaffy,
  otp_app: :my_app,
  ecto_repo: Bloggy.Repo,
  router: BloggyWeb.Router
```


## What You Get

![Post list page](demos/post_index.png)

## Customizations

### Configurations

If you don't specify a `resources` option in your configs, Kaffy will try to auto-detect your schemas and your admin modules. Admin modules should be in the same namespace as their respective schemas in order for kaffy to detect them. For exmaple, if you have a schema `MyApp.Products.Product`, its admin module should be `MyApp.Products.ProductAdmin`.

Otherwise, if you'd like to explicitly specify your schemas and their admin modules, you can do like the following:

```elixir
# config.exs
config :kaffy,
  admin_title: "My Awesome App",
  ecto_repo: MyApp.Repo,
  router: MyAppWeb.Router,
  resources: [
    blog: [
      name: "My Blog", # a custom name for this context/section.
      schemas: [
        post: [schema: MyApp.Blog.Post, admin: MyApp.SomeModule.Anywhere.PostAdmin],
        comment: [schema: MyApp.Blog.Comment],
        tag: [schema: MyApp.Blog.Tag]
      ]
    ],
    inventory: [
      name: "Inventory",
      schemas: [
        category: [schema: MyApp.Products.Category, admin: MyApp.Products.CategoryAdmin],
        product: [schema: MyApp.Products.Product, admin: MyApp.Products.ProductAdmin]
      ]
    ]
  ]
```

The following admin module is what the screenshot above is showing:

### Index page

The `index/1` function takes a schema and must return a keyword list of fields and their options.

If the options are `nil`, Kaffy will use default values for that field.

If this function is not defined, Kaffy will return all fields with their respective values.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def index(_) do
    [
      title: nil,
      views: %{name: "Hits"},
      date: %{name: "Date Added", value: fn p -> p.inserted_at end},
      good: %{name: "Popular?", value: fn _ -> Enum.random(["Yes", "No"]) end}
    ]
  end
end
```

Result

![Customized index page](demos/post_index_custom.png)

Notice that the keyword list keys don't necessarily have to be schema fields as long as you provide a `:value` option.

If you need to change the order of the records, define `ordering/1`:

```elixir
defmodule MyApp.Blog.PostAdmin do
  def ordering(_schema) do
    # order posts based on views
    [desc: :views]
  end
end
```


### Show/edit page

Kaffy treats the show and edit pages as one.

To customize the fields shown in this page, define a `form_fields/1` function in your admin module.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def form_fields(_) do
    [
      title: nil,
      status: %{choices: [{"Publish", "publish"}, {"Pending", "pending"}]},
      body: %{type: :textarea, rows: 4},
      views: %{permission: :read},
      settings: %{label: "Post Settings"}
    ]
  end
end
```

The `form_fields/1` function takes a schema and should return a keyword list of fields and their options.

The keys of the list must correspond to the schema fields.

Options can be:

- `:label` - must be a string.
- `:type` - can be any ecto type in addition to `:file` and `:textarea`.
- `:rows` - an integer to indicate the number of rows for textarea fields.
- `:choices` - a keyword list of option and values to restrict the input values that this field can accept.
- `:permission` - can be either `:write` (field is editable) or `:read` (field is non-editable). It is `:write` by default.


Result

![Customized show/edit page](demos/post_form_custom.png)

Notice that:

- Even though the `status` field is of type `:string`, it is rendered as a `<select>` element with choices.
- The `views` field is rendered as "readonly" because it has the `:read` permission.
- `settigns` is an embedded schema. That's why it is rendered as such.

### Search and filtration

Kaffy provides very basic search capabilities.

Currently, only `:string` and `:text` fields are supported for search.

If you need to customize the list of fields to search against, define the `search_fields/1` function.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def search_fields(_schema) do
    [:title, :slug, :body]
  end
end
```

This function takes a schema and returns a list of schema fields that you want to search. 
All the fields must be of type `:string` or `:text`.

If this function is not defined, Kaffy will return all `:string` and `:text` fields by default.

Result

![Customized show/edit page](demos/post_search.png)

### Authorization

Kaffy supports basic authorization for individual schemas by defining `authorized?/2`.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def authorized?(_schema, conn) do
    MyApp.Blog.can_see_posts?(conn.assigns.user)
  end
end
```

`authorized?/2` takes a schema and a `Plug.Conn` struct and should return a boolean value.

If it returns `false`, the request is redirected to the dashboard with an unauthorized message.

Note that the resource is also removed from the resources list if `authorized?/2` returns false.

Result

![Authorization](demos/post_authorized.png)

### Changesets

Kaffy supports separate changesets for creating and updating schemas.

Just define `create_changeset/2` and `update_changeset/2`.

Both of them are passed the schema and the attributes.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def create_changeset(schema, attrs) do
    # do whatever you want, must return a changeset
    MyApp.Blog.Post.my_customized_changeset(schema, attrs)
  end

  def update_changeset(entry, attrs) do
    # do whatever you want, must return a changeset
    MyApp.Blog.Post.update_changeset(entry, attrs)
  end
end
```

If either function is not defined, Kaffy will try calling `Post.changeset/2`.

And if that is not defined, `Ecto.Changeset.change/2` will be called.

### Singular vs Plural

Some names do not follow the "add an s" rule. Sometimes you just need to change some terms to your liking.

This is why `singular_name/1` and `plural_name/1` are there.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def singular_name(_) do
    "Article"
  end

  def plural_name(_) do
    "Terms"
  end
end
```

Result

![Singular vs Plural](demos/singular_plural.png)

Notice the "Posts" above the "Terms". This is the context name and it can be changed in the `configs.exs` file. 
See the "Configurations" section above.

### Callbacks

Sometimes you need to execute certain actions when creating, updating, or deleting records.

Kaffy has your back.

There are a few callbacks that are called every time you create, update, or delete a record.

These callbacks are:

- `before_create/1`
- `before_update/1`
- `before_delete/1`
- `before_save/1`
- `after_save/1`
- `after_delete/1`
- `after_update/1`
- `after_create/1`

`before_*` functions are passed a changeset. `after_*` functions are passed the record itself. With the exception 
of `before_delete/1` and `after_delete/1` which are both passed the record itself.

`before_*` functions must return `{:ok, changeset}` to continue the flow normally.

To prevent the chain from continuing, return `{:error, changeset}` for `before_*` functions and `{:error, record, "Error msg"}` for `after_*` functions.

When creating a new record, the following functions are called in this order:

- `before_create/1`
- `before_save/1`
- inserting the record happens here.
- `after_save/1`
- `after_create/1`

When updating an existing record, the following functions are called in this order:

- `before_update/1`
- `before_save/1`
- updating the record happens here.
- `after_save/1`
- `after_update/1`

When deleting a record, the following functions are called in this order:

- `before_delete/1`
- deleting the record happens here.
- `after_delete/1`

It's important to know that all callbacks are run inside a transaction. So in case of failure, everything is rolled back even if the operation actually happened.

```elixir
defmodule MyApp.Blog.PostAdmin do
  def before_create(changeset) do
    case String.contains?(changeset.changes.title, "kaffy") do
      true ->
        {:ok, changeset}
      false ->
        changeset = Ecto.Changeset.add_error(changeset, :title, "must contain kaffy")
        {:error, changeset}
    end
  end

  def after_create(post) do
    {:error, post, "This will prevent posts from being created"}
  end

  def after_delete(post) do
    if post.settings.slug == "do-not-delete" do
      # Ops! deleted by accident!
      # since callbacks are run in a transactions, the deletion will be rolled back and the post will exist again.
      {:error, post, "Do not delete this post please!"}
    else
      # it's ok to delete this post.
      {:ok, post}
    end
  end
end
```

Result

![Before create callback](demos/callback_before_create.png)

![After create callback](demos/callback_after_create.png)


## Why another admin interface

Kaffy was created out of a need to have a minimum, flexible, and customizable admin interface 
without the need to touch the current codebase. It should work out of the box just by adding some
configs in your `config.exs` file (with the exception of adding a one liner to your `router.ex` file).

A few points that encouraged the creation of Kaffy:

- Taking contexts into account.
  - Supporting contexts makes the admin interface better organized.
- Can handle as many schemas as necessary.
  - Whether we have 1 schema or 1000 schemas, the admin interface should adapt well.
- Have a visually pleasant user interface.
  - This might be subjective.
- No generators or generated templates.
  - I believe the less files there are the better. This also means it's easier to upgrade for users when releasing new versions. This might mean some flexibility and customizations will be lost, but it's a trade-off.
- Existing schemas/contexts shouldn't have to be modified.
  - I shouldn't have to change my code in order to adapt to the package, the package should adapt to my code.
- Should be easy to use whether with a new project or with existing projects with a lot of schemas.
  - Adding kaffy should be as easy for existing projects as it is for new ones.
- Highly flexible and customizable.
  - Provide as many configurable options as possible.
- As few dependencies as possible.
  - Currently kaffy only depends on phoenix and ecto.
- Simple authorization.
  - I need to limit access for some admins to some schemas.
- Minimum assumptions.
  - Need to modify a schema's primary key? Need to hide a certain field? No problem.


