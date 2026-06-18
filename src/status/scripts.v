module status

import sync
import time
import net

fn run_script(mut conn net.TcpConn, script_raw string, print_script bool) !string {
	shared lines := []string{}
  shared done := false
	eprintln('running script...')
	script := script_raw.split_into_lines()

	go fn [mut conn, shared lines, shared done, print_script] () {
		for {
			line_with_crlf := conn.read_line()
      if line_with_crlf.len == 0 { break }
      line := line_with_crlf.trim_right('\r\n')
      if line.len == 0 { continue }
			lock lines { lines << line }
      if print_script { eprintln(line) }
		}
    lock done { done = true }
	}()

	for cmd in script {
    if cmd.starts_with('#') { continue }
		if cmd.starts_with('wait for') {
			target := cmd.after('wait for ')
			if target.len == 0 { return error('Invalid target in script') }
			wait_for_string(target, shared lines, shared done)!
			continue
		} else if cmd.starts_with('sleep') {
			sleep_str := cmd.after('sleep ')
      if !sleep_str.is_int() {
        return error('Invalid script sleep command')
      }
      seconds := sleep_str.int()
			time.sleep(time.second * seconds)
			continue
		} else if cmd.starts_with('quit on') {
			target := cmd.after('quit on ')
			if target.len == 0 { return error('Invalid target in script') }
			wait_for_string(target, shared lines, shared done)!
			mut result := ''
      lock lines {
        result = lines.join_lines()
      }
      return result
		} else if cmd.starts_with('if ') {
      target_and_code := cmd.after('if ').split_nth(' ', 2)
      if target_and_code.len < 2 {
        return error('Invalid if syntax')
      }
      target := target_and_code[0]
      code := target_and_code[1]
      if target.len == 0 { return error('Invalid target in script') }
      lock lines {
        for line in lines {
          if line.contains(target) {
            eprintln('Found ${target}, running ${code}')
            break
          }
        }
      }
      run_script(mut conn, code, print_script)!
    }
		conn.write_string(cmd + '\r\n')!
	}
	eprintln('script done!')
	time.sleep(time.second)
  mut result := ''

  lock lines {
    result = lines.join_lines()
  }

  return result
}

fn wait_for_string(target string, shared lines []string, shared done bool) ! {
	for {
    lock lines {
      for line in lines {
        if line.contains(target) {
          eprintln('Found ${target}, continuing')
          return
        }
      }
    }
    lock done {
      if done {
        return error('connection closed before ${target} was found')
      }
    }
		time.sleep(time.millisecond * 50)
	}
}
