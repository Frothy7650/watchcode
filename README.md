# watchcode

Periodically checks a URL's HTTP status code and logs the response.

## Usage

```
watchcode [flags] <url>
```

## Flags

| Flag | Description |
|------|-------------|
| `-n` | Number of times to check the URL (default: infinite) |
| `-r` | Compact single-line output using carriage return |

## Examples

Check a URL 5 times:

```
watchcode -n 5 https://example.com
```

Monitor a URL indefinitely:

```
watchcode https://example.com
```

Compact single-line mode:

```
watchcode -r https://example.com
```

## Build and install

```sh
./make.vsh install
```
