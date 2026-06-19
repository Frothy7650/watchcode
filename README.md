# watchcode

Periodically checks a server's status and logs the response.
Supports HTTP/s, TCP, and Minecraft (SRP).

## Usage

```
watchcode [flags] <url>
```

URL schemes: `http://`, `https://`, `tcp://`, `mc://`

## Flags

| Flag | Description |
|------|-------------|
| `-n` | Number of times to check the URL (default: infinite) |
| `-d` | Delay in seconds between each loop (default: 1) |
| `-t` | Number of times the check can fail (default: 3) |
| `-f` | Disable formatting (ANSI colors) |
| `-l` | Log stderr output to a file |
| `-s` | Run a script on connection |
| `-b` | Print HTTP response body |
| `-p` | Print script output line by line |
| `-so` | Write script output to a file |

## Examples

```
watchcode -n 5 https://example.com       # check 5 times
watchcode https://example.com             # monitor indefinitely
watchcode -d 2 https://example.com        # 2s delay between checks
watchcode -t 2 https://example.com        # exit after 2 failures
watchcode -f https://example.com          # disable colored output
watchcode -l watchcode.log https://example.com
watchcode -b https://example.com          # show response body
watchcode -s script.wts tcp://host:port   # run a script
watchcode -s script.wts -p tcp://host:port       # print script output
watchcode -s script.wts -so out.log tcp://host:port  # log script output
watchcode -s script.wts -l gen.log -so out.log tcp://host:port  # both logs
watchcode mc://server.example.com          # Minecraft server status
```

## Scripts

Scripts execute line by line. Each line that isn't a control command is sent verbatim (with `\r\n`) to the server.

### Control commands

| Command | Behaviour |
|---------|-----------|
| `# comment` | Comment line (skipped, not sent) |
| `sleep <SEC>` | Pause for `<SEC>` seconds |
| `wait for <TARGET>` | Wait until the server sends a line containing `<TARGET>` |
| `quit on <TARGET>` | Wait for `<TARGET>`, then stop the script and return collected lines |
| `if <TARGET> <CODE>` | If any received line contains `<TARGET>`, run `<CODE>` as a sub-script |

Multi-target matching (OR):
```
wait for ERROR||TIMEOUT
quit on 200 OK||301 Moved
```

### Example — HTTP request
```
GET / HTTP/1.1
Host: example.com
Connection: close

```

### Example — IRC
```
NICK checker
USER checker 0 * :A bot
wait for 376 checker :End of MOTD command
JOIN #checker
PRIVMSG #checker :Hello!
PING irc.frothy7650.org
quit on PONG irc.frothy7650.org :irc.frothy7650.org
```

## Build and install

Requires [Vlang](https://github.com/vlang/v) to be installed.

```sh
./make.vsh install
```

## Errors

| code | error |
|------|-------|
| 1 | Failed to change SIGINT handler |
| 2 | Failed to parse arguments |
| 4 | Request failed too many times |
| 6 | Failed to print summary |
| 7 | Invalid number in arguments |
| 8 | TCP connection close failure |
