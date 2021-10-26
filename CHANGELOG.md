# Change Log

## [2.0.0] - 2021/10/26

### CHANGED

- bumped up libraries riverside depends on. and made riverside work as well with them.
- removed metrics endpoints related prometheus features.

## [1.2.6] - 2020/05/26

### CHANGED

- removed some warnings

## [1.2.5] - 2020/05/26

### CHANGED

- fix typo in error tuple(https://github.com/lyokato/riverside/pull/55) thanks to bakkdoor

## [1.2.4] - 2020/04/12

### CHANGED

- idle timeout configuration for cowboy(https://github.com/lyokato/riverside/pull/54) thanks to Daniela Ivanova

## [1.2.3] - 2019/03/06

### CHANGED

- runtime port config(https://github.com/lyokato/riverside/pull/52)
- removed deprecation warnings(https://github.com/lyokato/riverside/pull/50) thanks to yurikoval
- dependency update: now requires plug_cowboy(2.0) and plug(1.7)

## [1.2.2] - 2019/02/22

### CHANGED

- update ExDoc dependency 0.15 -> 0.19

## [1.2.1] - 2019/02/22

### CHANGED

- merged 2 PRs from yurikoval
- (1) uuid -> elixir_uuid:  https://github.com/lyokato/riverside/pull/48
- (2) formatter support:  https://github.com/lyokato/riverside/pull/49

## [1.2.0] - 2018/08/12

### CHANGED

- updated version of libraries on which riverside depends.
- no longer use a ebus but a 'Registry'
