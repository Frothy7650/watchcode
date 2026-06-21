module status

import frothy7650.chalk
import time
import net

pub fn redis(url_const string, format bool) !Status {
  mut ok := true

  mut url := url_const

  if !url.contains(':') {
    url += ':6379'
  }

  mut conn := net.dial_tcp(url)!
  conn.write_string('PING\r\n')!
  line := conn.read_line()

  if line != '+PONG' {
    ok = false
  }

  msg := if ok { 'UP' } else { 'DOWN' }

  conn.close()!

  return Status{
    ok: ok
    msg: '${url} at ${time.now().hhmmss()}: ${if format { chalk.green(msg) } else { msg }}'
    output: line
  }
}
