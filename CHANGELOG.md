### v0.2.1 (in deveopment)

### v0.2.0 (2020-05-09)

- Kaffy now supports phoenix 1.4 and higher.
- The `:otp_app` config is now required.
- Removed some deprecation warnings when compiling kaffy
- Massively simplified configurations. The only required configs now are `otp_app`, `ecto_repo`, and `router`.
- Kaffy will now auto-detect your schemas and admin modules if they're not set explicitly. See the README file for more.

### v0.1.2 (2020-05-08)

- Much improved UI.
- Some code cleanups.

### v0.1.1 (2020-05-07)

- Removed the dependency on `:jason`.
- Changed `plug :fetch_live_flash` to `plug :fetch_flash` for the default pipeline.
