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
| `-d` | Delay(in seconds) inbetween each loop (default: 1) |
| `-t` | Number of times that the check can error (default: 3) |
| `-f` | Disable formatting |
| `-l` | Log to a file |

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

Set the delay manually:
```
watchcode -d 2 https://example.com
```

Set the acceptable error count manually:
```
watchcode -t 2 https://example.com
```

Disable formatting:
```
watchcode -f https://example.com
```

Log to a file:
```
watchcode -l watchcode.log https://example.com
```

## Build and install
Requires [Vlang](https://github.com/vlang/v) to be installed
```sh
./make.vsh install
```
