module main

import os

#include <fcntl.h>

fn C.open(const_pathname &char, flags int, mode int) int

fn persist_stderr_to_disk(path_rel string) {
	path := os.abs_path(path_rel)
	os.mkdir_all(os.dir(path)) or { exit(1) }
	fd := C.open(path.str, C.O_CREAT | C.O_WRONLY | C.O_APPEND, 0o666)
	C.dup2(fd, C.STDERR_FILENO)
}

fn persist_stdout_to_disk(path_rel string) {
	path := os.abs_path(path_rel)
	os.mkdir_all(os.dir(path)) or { exit(1) }
	fd := C.open(path.str, C.O_CREAT | C.O_WRONLY | C.O_APPEND, 0o666)
	C.dup2(fd, C.STDOUT_FILENO)
}

fn redirect_stderr_to_stdout() {
	C.dup2(C.STDOUT_FILENO, C.STDERR_FILENO)
}

fn redirect_stdout_to_stderr() {
	C.dup2(C.STDERR_FILENO, C.STDOUT_FILENO)
}
