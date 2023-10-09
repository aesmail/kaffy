# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.10.2 (2023-10-09)

### Fixes
- Fix regression introduced in v0.10.1 which made Kaffy ignore all admin modules.

## v0.10.1 (2023-10-09)

### Fixes
- Fix a crash when Kaffy mistakenly treats erlang modules as Elixir modules (PR #300)

## v0.10.0 (2023-10-06)

### Fixes
- belongs_to fields didn't respect the `:readonly` option (PR #297).

## v0.10.0-rc.3 (2023-09-28)

### Fixes
- Fix regression when trying to save a resource with an array field.

### Added
- Support searching fields with `id`, `integer` and `decimal` types.

## v0.10.0-rc.2 (2023-09-10)

### Fixes
- Fix a crash when deleting resources from the resource page through the "Delete" button.

## v0.10.0-rc.1 (2023-09-09)

### Fixes
- Crash when updating records.
- Removes elixir and phoenix deprecation warnings [PR#288](https://github.com/aesmail/kaffy/pull/288)

### Added
- Support for filtering `{:array, :string}` fields [PR#285](https://github.com/aesmail/kaffy/pull/262)
- Per-context dashboard [PR#287](https://github.com/aesmail/kaffy/pull/287)

### Changed
- Minimum phoenix version is now 1.6. This means that the minimum Elixir version is now 1.12 (see support policy).

## v0.10.0-rc.0 (2023-09-02)

### Fixes
- Fix changeset errors [PR#262](https://github.com/aesmail/kaffy/pull/262)
- Preload resources before trying to convert resource to existing atom. [PR#266](https://github.com/aesmail/kaffy/pull/266)
- Include `many_to_many` fields in `fields_to_be_removed/1`.
- Fix array fields not being saved properly.
- Fix `:readonly` and `:editable` options for datetime fields.
- Default to `nil` for `belongs_to` fields.
- Fix issue with datetime fields sometimes being updated unexpectedly.

### Changed
- Minimum Elixir version is now 1.11.4.
- Add `phoenix_view` package to deps.
- Let specify the full 'path' for FontAwesome fonts [PR#186](https://github.com/aesmail/kaffy/pull/186)
- Lazy load default kaffy field value [PR#255](https://github.com/aesmail/kaffy/pull/255)
- Update phoenix html to address deprecated form_for [PR#260](https://github.com/aesmail/kaffy/pull/260)
- Use left_join when building search query [PR#273](https://github.com/aesmail/kaffy/pull/273)
- Remove the "- Kaffy" suffix from page titles.

### Added
-  Support hiding menu entries [PR#248](https://github.com/aesmail/kaffy/pull/248)
- Add support for composite primary keys [PR#270](https://github.com/aesmail/kaffy/pull/270)
- Index page description [PR#274](https://github.com/aesmail/kaffy/pull/274)
- Footer can be specified in config [PR#275](https://github.com/aesmail/kaffy/pull/275)
- Provide more flexibility for customizing the `admin_logo` and `admin_logo_mini` options.
- Add the ability to "bulk delete" resources from the index page.
- Hide save and delete buttons on the show page based on available actions.
- Add `Kaffy.Utils.auto_detect_resources/0` which returns the list of auto-detected resources (Kaffy's attempt at discovering the list of schema/admin modules).



## v0.9.4 (2022-10-31)

### Fixed

- Add missing "custom-select" classes to some `select` tags.
- Ensure that extension modules are loaded.
- Save enum fields with their cast values.

## v0.9.3 (2022-08-13)

### Fixed

- The `:readonly` option was ignored when defining `:choices` for a specific field in `form_fields` (#225)
- Fix generating forms for embeds and enums (#234)

### Added

- Added the option to disable creating new records (#188)
- A new `:bottom` option to display menu items at the bottom of the side menu (#237)
- A smarter inflector covering more plural cases (#233)
- Better documentation generation for ExDocs (#214)
- Allow list actions to have select inputs (#238)

## v0.9.2 (2022-08-03)

### Bug Fixes

- Display records from schemas which contain fields with names "context" and "resource".

## v0.9.1 (2022-07-11)

### Bug Fixes

- Clicking on the "Select all" checkbox and performing an action wasn't working properly (#129).
- A resource with a `{:array, _}` field type used to crash when rendering the form page (#130).
- Tidbit icons weren't shown properly.
- Schemas with `has_many` or `many_to_many` associations crashed when trying to save if the schema doesn't have a default `changeset/2` function.
- Support phoenix 1.6

## v0.9.0 (2020-07-02)

### Breaking change

- If you are defining your resources manually, you need to replace all `:schemas` keys with `:resources`.

### Bug Fixes

- `map` and JSON fields weren't being properly recognized and saved/updated (regression from v0.8.x).
- Searching a schema which has a `:string` virtual field produced a crash.
- "Next" page link was active even when there was no records to display on the next page.
- belongs_to fields were almost invisible on small screens.
- Schemas without a public `changeset/2` function were crashing due to parameters not being cast properly.
- Searching a resource with a search term that contained a special SQL character (% or _) returned invalid results.
- Multi-word contexts weren't being formatted properly.

### Enhancements

- Introducing extension modules to add custom html, css, and javascript.
- Custom form fields for specialized functionality.
- List actions now can have an intermediary step for more input from the user.
- Decimal values are displayed properly on the index page.
- Improved layout for mobile screens.
- First column on index page is the first field in your schema.
- Ability to override Kaffy's `insert`, `update`, and `delete` functions to customize how the function works.
- Moved scheduled tasks to their own modules and they have their own option in config.
- Improved alert message styles.
- Much improved pagination UI.
- Ability to customize the query Kaffy uses for the index and show pages.
- A more flexible and customizable way to define resource and admin modules.
- Added a `help_text` option to `form_fields` to display a helpful text next to the field.

### Contributors for v0.9.0

- Areski Belaid (@areski)
- Axel Clark (@axelclark)
- Adi Purnama (@adipurnama)
- Nicolas Resnikow (@nresni)
- Abdullah Esmail (@aesmail)

## v0.8.1 (2020-06-05)

### Bug Fixes

- The "Select all" checkbox didn't work properly (thanks @areski).
- Kaffy crashed when opening the page to select a record for the belogns_to association.

### Enhancements

- UI improvements on the index page (thanks @areski).
- Replace MDI icons with FontAwesome.

## v0.8.0 (2020-06-03)

### Breaking Changes

- removed `:permission` field option in favor of `:create` and `:update` options for more control and customization.

### New Features

- ability to add custom links to the side menu.
- ability to add add custom pages.
- ability to order records per column in the index page.

### Enhancements

- a placeholder value for :map textarea fields to indicate that JSON content is expected.
- enhanced "humanization" of field names in index page.
- improved checkbox form control UI (thanks @areski).
- new and improved design (thanks @areski).
- include checkboxes in index page to clearly indicate records are selectable.
- pagination, filtration, and searching are now bookmarkable with querystring parameters.
- `count` query result is now cached if the table has more than 100,000 records (thanks @areski).
- add option to hide the dashboard menu item.
- add option to change the root url to be something other than the dashboard.
- removed render warnings when running under phoenix 1.5.
- add a much improved date/time picker (thanks @areski).

## v0.7.1 (2020-05-23)

### Bug Fixes

- kaffy was ignoring the default/custom changeset functions when creating/updating records.

### Enhancements

- do not show the "Tasks" menu item if there are no tasks (thanks @areski).
- esthetic changes on the index page (thanks @areski).

## v0.7.0 (2020-05-22)

### New Features

- introducing simple scheduled tasks.

### Enhancements

- search across associations.
- improve how autodetected schema names are formatted.
- clicking on the upper left title goes to the website's root "/" (used to go to the dashboard page, which already has a link in the menu).
- fix a few typos in README (thanks @areski).

## v0.6.2 (2020-05-20)

### Bug Fixes

- multi-word CamelCase schemas weren't being saved properly.

### Enhancements

- by default, do not include autogenerated fields resource form page.
- order autodetected contexts/schemas alphabetically.

## v0.6.1 (2020-05-19)

### Bug Fixes

- sometimes the primary key field (id) is treated as an association.
- the popup for selecting a "belongs_to" record was not displaying any records.
- use `fn/0` instead of `fn/1` with `Ecto.Repo.transaction/2` to support ecto 2.x.

## v0.6.0 (2020-05-18)

### Breaking Changes

- always include the `:kaffy_browser` pipeline to display templates correctly. Please check the minimum configurations - section in the README for more information on how to upgrade.

### New Features

- support custom actions for a group of selected resources in index page.

### Bug Fixes

- resource index page table was displayed incorrectly when using a custom pipeline.
- all side menu resources are shown by default including sections that are not currently active.
- side menu does not scroll when there are too many contexts/schemas.
- side menu items all popup at the same time when viewed on small screens.

### Misc

- added a demo link to the hex package page.

## v0.5.1 (2020-05-17)

### Enhancements

- add a rich text editor option for form fields (`type: :richtext`).

### Bug Fixes

- dashboard widgets were displayed improperly on small screens.

## v0.5.0 (2020-05-16)

##### compatible with v0.4.x

### New Features

- introducing custom widgets in the dashboard.

## v0.4.1 (2020-05-14)

### New Features

- add custom field filters.

### Bug Fixes

- sometimes if `index/1` is not defined in the admin module, the index page is empty.

## v0.4.0 (2020-05-13)

### Breaking Changes

- pass `conn` struct to all callback functions.

### New Features

- introducing custom actions for single resources.

### Enhancements

- fix typo in the resource form (thanks @axelclark).

## v0.3.2 (2020-05-12)

### Bug Fixes

- Kaffy didn't compile with elixir < 1.10 due to the use of `Kernel.is_struct`. It is currently tested with elixir 1.7+
- Sometimes new records couldn't be created if they have `:map` fields.

## v0.3.1 (2020-05-12)

### Enhancements

- A better way to support foreign key fields with a huge amount of records to select from.
- Retrieve the actual name of the association field from the association struct.

## v0.3.0 (2020-05-11)

### New Features

- Added ability to delete resources.
- Added resource callbacks when creating, updating, and deleting resources.

### Bug Fixes

- Don't try to decode map fields when they are empty.

## v0.2.1 (2020-05-10)

### New Features

- Added support for embedded schemas.
- Added support for `:map` fields for json values.

### Enhancements

- Use the json library configured for phoenix instead of hardcoding `Jason`.

### Bug Fixes

- Don't crash when the schema has a `has_many` or `has_one` association.
- Don't crash when the schema has a map field or an embedded schema.

## v0.2.0 (2020-05-09)

### Breaking Changes

- The `:otp_app` config is now required.

### New Features

- Kaffy will now auto-detect your schemas and admin modules if they're not set explicitly. See the README file for more.

### Enhancements

- Kaffy now supports phoenix 1.4 and higher.
- Removed some deprecation warnings when compiling kaffy
- Massively simplified configurations. The only required configs now are `otp_app`, `ecto_repo`, and `router`.

## v0.1.2 (2020-05-08)

### Enhancements

- Much improved UI.
- Some code cleanups.

## v0.1.1 (2020-05-07)

### Enhancements

- Removed the dependency on `:jason`.

### Bug Fixes

- Changed `plug :fetch_live_flash` to `plug :fetch_flash` for the default pipeline.
