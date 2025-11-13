## [Unreleased]

## [0.2.1] - 2025-11-14

- Fixed errors when middleware stack may have been modified ([#18](https://github.com/speedshop/gvl_metrics_middleware/pull/18))

## [0.2.0] - 2025-10-30

- Add sampling support ([#7](https://github.com/speedshop/gvl_metrics_middleware/pull/7)). Set `config.sampling_rate = 0.1` to sample 10% of requests/jobs (defaults to 1%).
- Allow middleware configuration in initializers ([#8](https://github.com/speedshop/gvl_metrics_middleware/pull/8)). Configure the middleware in `config/initializers/gvl_metrics_middleware.rb` before Rails loads it.

## [0.1.0] - 2025-01-09

- Initial release
