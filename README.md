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
| `-j` | Output JSON instead of plain text |
| `-s` | Run a script(requires -sl) on connection |
| `-sl` | Log the output of a TCP connection when using scripts |

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

Output JSON:
```
watchcode -j https://example.com
```

Run a script and log it:
```
watchcode -s script.wts -sl output.log tcp://example.com:80
```

## Scripts
Scripts will execute line by line, they send each line to the server, and log the responses with the `-sl` flag.
### Special commands
| command | behaviour |
|---------|-----------|
| `sleep <SEC>` | Sleeps for \<SEC\> seconds |
| `wait <TARGET>` | Waits until server sends a message containing \<TARGET\> |

### Example script
This script gets a HTTP response from example.com
```
GET / HTTP/1.1
Host: example.com
Connection: close

```
And yes, that last newline is necessary, it's equivalent to sending enter twice.

## Build and install
Requires [Vlang](https://github.com/vlang/v) to be installed
```sh
./make.vsh install
```

## Errors
| code | error |
|------|-------|
| 1 | Failed to change SIGINT handler |
| 2 | Failed to parse arguments correctly |
| 3 | Failed to create/clear logfile |
| 4 | GET request failed too many times |
| 5 | Failed to write to file |
| 6 | Failed to print summary(should basically never happen) |
| 7 | Invalid number in arguments |
| 8 | TCP connection close failure |
