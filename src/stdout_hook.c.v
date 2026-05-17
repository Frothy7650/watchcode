import os

#include <fcntl.h>

fn C.open(const_pathname &char, flags int, mode int) int

fn persist_stdout_to_disk(path string) {
	logpath := os.abs_path(path)
	os.mkdir_all(os.dir(logpath)) or { exit(1) }
	fd := C.open(logpath.str, C.O_CREAT | C.O_WRONLY | C.O_APPEND, 0o666)
	C.dup2(fd, C.STDOUT_FILENO)
}
