### v0.4.2 (in development)

### v0.4.1 (2020-05-14)

- [feature] add custom field filters.
- [bugfix] sometimes if `index/1` is not defined in the admin module, the index page is empty.

### v0.4.0 (2020-05-13)

- [breaking] pass `conn` struct to all callback functions.
- [feature] introducing custom actions for single resources.
- [enhancement] fix typo in the resource form (thanks @axelclark).

### v0.3.2 (2020-05-12)

- [bugfix] Kaffy didn't compile with elixir < 1.10 due to the use of `Kernel.is_struct`. It is currently tested with elixir 1.7+
- [bugfix] Sometimes new records couldn't be created if they have `:map` fields.

### v0.3.1 (2020-05-12)

- [enhancement] A better way to support foreign key fields with a huge amount of records to select from.
- [enhancement] Retrieve the actual name of the association field from the association struct.

### v0.3.0 (2020-05-11)

- [feature] Added ability to delete resources.
- [feature] Added resource callbacks when creating, updating, and deleting resources.
- [bugfix] Don't try to decode map fields when they are empty.

### v0.2.1 (2020-05-10)

- [feature] Added support for embedded schemas.
- [feature] Added support for `:map` fields for json values.
- [enhancement] Use the json library configured for phoenix instead of hardcoding `Jason`.
- [bugfix] Don't crash when the schema has a `has_many` or `has_one` association.
- [bugfix] Don't crash when the schema has a map field or an embedded schema.

### v0.2.0 (2020-05-09)

- [enhancement] Kaffy now supports phoenix 1.4 and higher.
- [breaking] The `:otp_app` config is now required.
- [enhancement] Removed some deprecation warnings when compiling kaffy
- [enhancement] Massively simplified configurations. The only required configs now are `otp_app`, `ecto_repo`, and `router`.
- [feature] Kaffy will now auto-detect your schemas and admin modules if they're not set explicitly. See the README file for more.

### v0.1.2 (2020-05-08)

- [enhancement] Much improved UI.
- [enhancement] Some code cleanups.

### v0.1.1 (2020-05-07)

- [enhancement] Removed the dependency on `:jason`.
- [bugfix] Changed `plug :fetch_live_flash` to `plug :fetch_flash` for the default pipeline.
